package be.sgerard.k8s.crd;

import be.sgerard.k8s.crd.model.resource.Backup;
import be.sgerard.k8s.crd.model.resource.BackupList;
import io.kubernetes.client.informer.SharedIndexInformer;
import io.kubernetes.client.informer.SharedInformerFactory;
import io.kubernetes.client.openapi.ApiClient;
import io.kubernetes.client.openapi.Configuration;
import io.kubernetes.client.util.ClientBuilder;
import io.kubernetes.client.util.generic.GenericKubernetesApi;

import io.kubernetes.client.extended.controller.Controller;
import io.kubernetes.client.extended.controller.ControllerManager;
import io.kubernetes.client.extended.controller.builder.ControllerBuilder;
import io.kubernetes.client.extended.leaderelection.LeaderElectionConfig;
import io.kubernetes.client.extended.leaderelection.LeaderElector;
import io.kubernetes.client.extended.leaderelection.resourcelock.EndpointsLock;
import lombok.extern.slf4j.Slf4j;

import java.io.IOException;
import java.time.Duration;
import java.util.UUID;

/**
 * Based on:
 * <ul>
 * <li><a href="https://github.com/SantoshGoudar/apiservice-ex/"></a> with <a href="https://medium.com/@santoshgoudarm/kubernetes-crd-and-custom-controller-development-using-java-1570c6fcb110"></a></li>
 * <li><a href="https://github.com/kubernetes-client/java/wiki/3.-Code-Examples"></a></li>
 * <li><a href="https://github.com/kubernetes-client/java/blob/9409d1a/examples/examples-release-17/src/main/java/io/kubernetes/client/examples/ControllerExample.java"></a></li>
 * <li><a href="https://github.com/kubernetes-client/java/blob/9409d1a814fbf368d953f79af20cd64415548c62/examples/examples-release-17/src/main/java/io/kubernetes/client/examples/LeaderElectionExample.java"></a></li>
 * </ul>
 */
@Slf4j
public class Application {

    private static boolean stopRunning = false;

    public static void main(String[] args) throws IOException {
        log.info("Starting operator on {}:{}.", System.getenv("KUBERNETES_SERVICE_HOST"), System.getenv("KUBERNETES_SERVICE_PORT"));

        final ApiClient apiClient = ClientBuilder.cluster().build();
        Configuration.setDefaultApiClient(apiClient);

        final SharedInformerFactory sharedInformerFactory = new SharedInformerFactory(apiClient);

        final GenericKubernetesApi<Backup, BackupList> api = new GenericKubernetesApi<>(Backup.class, BackupList.class, "sgerard.be", "v1", "backups", apiClient);

        final SharedIndexInformer<Backup> sharedIndexInformer = sharedInformerFactory.sharedIndexInformerFor(api, Backup.class, 0);
        Controller apiServiceController = ControllerBuilder.defaultBuilder(sharedInformerFactory)
                .withReconciler(new ApiServiceReconciler(sharedIndexInformer, api)) // required, set the actual reconciler
                .withName("Api service controller") // optional, set name for controller
                .withWorkerCount(10) // optional, set worker thread count
                .withReadyFunc(sharedIndexInformer::hasSynced) // optional, only starts controller when the cache has synced up
                .withReadyTimeout(Duration.ofSeconds(1200))// optional, if controller cannot sync before this time out application will exit
                .watch(workQueue -> ControllerBuilder.controllerWatchBuilder(Backup.class, workQueue).build())
                .build();

        String lockHolderIdentityName = UUID.randomUUID().toString(); // Anything unique
        EndpointsLock lock = new EndpointsLock("default", "apiservice-ex", lockHolderIdentityName);

        LeaderElectionConfig leaderElectionConfig = new LeaderElectionConfig(lock, Duration.ofMillis(10000), Duration.ofMillis(8000), Duration.ofMillis(2000));

        while (!stopRunning) {
            acquireLeaseAndRun(leaderElectionConfig, sharedInformerFactory, apiServiceController);
        }
    }

    private static void acquireLeaseAndRun(LeaderElectionConfig leaderElectionConfig, SharedInformerFactory sharedInformerFactory, Controller apiServiceController) {
        ControllerManager manager = ControllerBuilder
                .controllerManagerBuilder(sharedInformerFactory)
                .addController(apiServiceController)
                .build();

        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.println("Application shutting down");
            manager.shutdown();
            stopRunning = true;
        }));
        try (LeaderElector leaderElector = new LeaderElector(leaderElectionConfig)) {
            leaderElector.run(getStartFunction(manager), getStopFunction(manager));
        }
    }

    private static Runnable getStartFunction(ControllerManager controllerManager) {
        return () -> {
            System.out.println("I'm the leader now and start processing events");
            controllerManager.run();
        };
    }

    private static Runnable getStopFunction(ControllerManager controllerManager) {
        return () -> {
            System.out.println("i lost the leadership and stop processing now");
            controllerManager.shutdown();
        };
    }
}
