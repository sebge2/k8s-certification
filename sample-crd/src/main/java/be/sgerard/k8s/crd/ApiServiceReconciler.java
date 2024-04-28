package be.sgerard.k8s.crd;

import be.sgerard.k8s.crd.model.resource.Annotation;
import be.sgerard.k8s.crd.model.resource.AnnotationList;
import io.kubernetes.client.custom.V1Patch;
import io.kubernetes.client.extended.controller.reconciler.Reconciler;
import io.kubernetes.client.extended.controller.reconciler.Request;
import io.kubernetes.client.extended.controller.reconciler.Result;
import io.kubernetes.client.informer.SharedIndexInformer;
import io.kubernetes.client.openapi.ApiException;
import io.kubernetes.client.openapi.apis.AppsV1Api;
import io.kubernetes.client.openapi.models.V1Deployment;
import io.kubernetes.client.openapi.models.V1ObjectMeta;
import io.kubernetes.client.util.generic.GenericKubernetesApi;
import io.kubernetes.client.util.generic.KubernetesApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static java.util.Collections.emptyList;

@RequiredArgsConstructor
@Slf4j
public class ApiServiceReconciler implements Reconciler {

    public static final String FINALIZER = "annotations.sgerard.be";
    public static final String PATCH_TYPE = "application/json-patch+json";

    private final SharedIndexInformer<Annotation> sharedInformer;
    private final AppsV1Api appsV1Api;
    private final GenericKubernetesApi<Annotation, AnnotationList> api;

    @Override
    public Result reconcile(Request request) {
        final String key = Optional.ofNullable(request.getNamespace()).map("%s/"::formatted).orElse("") + request.getName();

        Optional
                .ofNullable(sharedInformer.getIndexer().getByKey(key))
                .ifPresent(this::handleNewAnnotation);

        return new Result(false);
    }

    private void handleNewAnnotation(Annotation annotation) {
        log.info("Created/Updated resource: %s/%s".formatted(annotation.getMetadata().getNamespace(), annotation.getMetadata().getName()));

        log.info(annotation.toString());

        if (isDeleted(annotation)) {
            // TODO do something, remove labels?
            removeFinalizer(annotation);
        } else if (!isFinalizerPresent(annotation)) {
            addFinalizer(annotation);
            annotateDeployments(annotation);
        } else {
            annotateDeployments(annotation);
        }
    }

    private void annotateDeployments(Annotation annotation) {
        final String namespace = Optional.ofNullable(annotation.getMetadata().getNamespace()).orElse("default");

        listDeployments(namespace)
                .forEach(item -> updateDeployment(item, namespace, annotation));
    }

    private boolean isDeleted(Annotation annotation) {
        return annotation.getMetadata().getDeletionTimestamp() != null;
    }

    private boolean isFinalizerPresent(Annotation annotation) {
        return Optional.ofNullable(annotation.getMetadata().getFinalizers())
                .map(finalizers -> finalizers.contains(FINALIZER))
                .orElse(false);
    }

    private void addFinalizer(Annotation annotation) {
        final V1Patch patch = createPatch(true);

        final KubernetesApiResponse<Annotation> response = patch(annotation, patch);

        if (!response.isSuccess()) {
            log.error("Error while adding finalizer to %s/%s. Status %s.".formatted(annotation.getMetadata().getNamespace(), annotation.getMetadata().getName(), response.getStatus()));
        } else {
            log.debug("The finalizer has been added to %s/%s.".formatted(annotation.getMetadata().getNamespace(), annotation.getMetadata().getName()));
        }
    }

    private void removeFinalizer(Annotation annotation) {
        final V1Patch patch = createPatch(false);

        final KubernetesApiResponse<Annotation> response = patch(annotation, patch);

        if (!response.isSuccess()) {
            log.error("Error while removing finalizer to %s/%s.".formatted(annotation.getMetadata().getNamespace(), annotation.getMetadata().getName()));
        } else {
            log.debug("The finalizer has been removed from: %s/%s. Status %s.".formatted(annotation.getMetadata().getNamespace(), annotation.getMetadata().getName(), response.getStatus()));
        }
    }

    private KubernetesApiResponse<Annotation> patch(Annotation annotation, V1Patch patch) {
        if (annotation.getMetadata().getNamespace() != null) {
            return api.patch(annotation.getMetadata().getNamespace(), annotation.getMetadata().getName(), PATCH_TYPE, patch);
        } else {
            return api.patch(annotation.getMetadata().getName(), PATCH_TYPE, patch);
        }
    }

    private V1Patch createPatch(boolean add) {
        final String operator = add ? "replace" : "remove";

        return new V1Patch("[{\"op\": \"%s\", \"path\": \"/metadata/finalizers\", \"value\":[\"%s\"]}]".formatted(operator, FINALIZER));
    }

    private List<V1Deployment> listDeployments(String namespace) {
        try {
            return appsV1Api.listNamespacedDeployment(namespace)
                    .execute()
                    .getItems();
        } catch (ApiException e) {
            log.error("Error while listing deployments in namespace %s.".formatted(namespace), e);

            return emptyList();
        }
    }

    private void updateDeployment(V1Deployment deployment, String namespace, Annotation annotation) {
        final Map<String, String> deploymentAnnotations = Optional.ofNullable(deployment.getMetadata())
                .map(V1ObjectMeta::getAnnotations)
                .orElseGet(HashMap::new);

        deploymentAnnotations.putAll(annotation.getSpec().getAnnotations());

        log.info("Update deployment %s/%s, annotations %s.".formatted(namespace, deployment.getMetadata().getName(), deploymentAnnotations));

        deployment.getMetadata().setAnnotations(deploymentAnnotations);

        updateDeployment(deployment, namespace);
    }

    private void updateDeployment(V1Deployment item, String namespace) {
        try {
            appsV1Api.replaceNamespacedDeployment(item.getMetadata().getName(), namespace, item)
                    .execute();
        } catch (ApiException e) {
            log.error("Error while updating deployment %s/%s.".formatted(namespace, item.getMetadata().getName()), e);
        }
    }
}
