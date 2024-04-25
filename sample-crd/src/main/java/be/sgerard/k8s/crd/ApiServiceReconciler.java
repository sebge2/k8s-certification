package be.sgerard.k8s.crd;

import be.sgerard.k8s.crd.model.resource.Backup;
import be.sgerard.k8s.crd.model.resource.BackupList;
import io.kubernetes.client.extended.controller.reconciler.Reconciler;
import io.kubernetes.client.extended.controller.reconciler.Request;
import io.kubernetes.client.extended.controller.reconciler.Result;
import io.kubernetes.client.informer.SharedIndexInformer;
import io.kubernetes.client.util.generic.GenericKubernetesApi;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.util.Optional;

@RequiredArgsConstructor
@Slf4j
public class ApiServiceReconciler implements Reconciler {

    private final SharedIndexInformer<Backup> sharedInformer;
    private final GenericKubernetesApi<Backup, BackupList> api;

    @Override
    public Result reconcile(Request request) {
        final String key = Optional.ofNullable(request.getNamespace()).map("%s/"::formatted).orElse("") + request.getName();

        final Backup backup = sharedInformer.getIndexer().getByKey(key);

        if (backup != null) {
            log.info("Created/Updated resource: " + key + " " + backup);
            // TODO do something
        } else {
            log.info("The resource has been deleted: " + key);
            // TODO do something
        }

        return new Result(false);
    }


}
