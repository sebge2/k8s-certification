package be.sgerard.k8s.crd;

import be.sgerard.k8s.crd.model.resource.Backup;
import be.sgerard.k8s.crd.model.resource.BackupList;
import io.kubernetes.client.custom.V1Patch;
import io.kubernetes.client.extended.controller.reconciler.Reconciler;
import io.kubernetes.client.extended.controller.reconciler.Request;
import io.kubernetes.client.extended.controller.reconciler.Result;
import io.kubernetes.client.informer.SharedIndexInformer;
import io.kubernetes.client.util.generic.GenericKubernetesApi;
import io.kubernetes.client.util.generic.KubernetesApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.util.Optional;

@RequiredArgsConstructor
@Slf4j
public class ApiServiceReconciler implements Reconciler {

    public static final String FINALIZER = "backups.sgerard.be";
    public static final String PATCH_TYPE = "application/json-patch+json";

    private final SharedIndexInformer<Backup> sharedInformer;
    private final GenericKubernetesApi<Backup, BackupList> api;

    @Override
    public Result reconcile(Request request) {
        final String key = Optional.ofNullable(request.getNamespace()).map("%s/"::formatted).orElse("") + request.getName();

        Optional
                .ofNullable(sharedInformer.getIndexer().getByKey(key))
                .ifPresent(this::handleNewBackup);

        return new Result(false);
    }

    private void handleNewBackup(Backup backup) {
        log.info("Created/Updated resource: %s/%s".formatted(backup.getMetadata().getNamespace(), backup.getMetadata().getName()));

        if (isDeleted(backup)) {
            removeFinalizer(backup);
        } else if (!isFinalizerPresent(backup)) {
            addFinalizer(backup);
        } else {
            // TODO
        }
    }

    private boolean isDeleted(Backup backup) {
        return backup.getMetadata().getDeletionTimestamp() != null;
    }

    private boolean isFinalizerPresent(Backup backup) {
        return Optional.ofNullable(backup.getMetadata().getFinalizers())
                .map(finalizers -> finalizers.contains(FINALIZER))
                .orElse(false);
    }

    private void addFinalizer(Backup backup) {
        final V1Patch patch = new V1Patch("[{\"op\": \"replace\", \"path\": \"/metadata/finalizers\", \"value\":[\"backups.sgerard.be\"]}]");

        final KubernetesApiResponse<Backup> response = patch(backup, patch);

        if (!response.isSuccess()) {
            log.error("Error while adding finalizer to %s/%s. Status %s.".formatted(backup.getMetadata().getNamespace(), backup.getMetadata().getName(), response.getStatus()));
        } else {
            log.debug("The finalizer has been added to %s/%s.".formatted(backup.getMetadata().getNamespace(), backup.getMetadata().getName()));
        }
    }

    private void removeFinalizer(Backup backup) {
        final V1Patch patch = new V1Patch("[{\"op\": \"remove\", \"path\": \"/metadata/finalizers\", \"value\":[\"backups.sgerard.be\"]}]");

        final KubernetesApiResponse<Backup> response = patch(backup, patch);

        if (!response.isSuccess()) {
            log.error("Error while removing finalizer to %s/%s.".formatted(backup.getMetadata().getNamespace(), backup.getMetadata().getName()));
        } else {
            log.debug("The finalizer has been removed from: %s/%s. Status %s.".formatted(backup.getMetadata().getNamespace(), backup.getMetadata().getName(), response.getStatus()));
        }
    }

    private KubernetesApiResponse<Backup> patch(Backup backup, V1Patch patch) {
        if (backup.getMetadata().getNamespace() != null) {
            return api.patch(backup.getMetadata().getNamespace(), backup.getMetadata().getName(), PATCH_TYPE, patch);
        } else {
            return api.patch(backup.getMetadata().getName(), PATCH_TYPE, patch);
        }
    }
}
