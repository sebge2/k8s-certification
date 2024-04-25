package be.sgerard.k8s.crd.model.resource;

import io.kubernetes.client.common.KubernetesObject;
import io.kubernetes.client.openapi.models.V1ObjectMeta;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
public class Backup implements KubernetesObject {

    private String apiVersion;
    private String kind;
    private V1ObjectMeta metadata;
    private BackupSpec spec;

}
