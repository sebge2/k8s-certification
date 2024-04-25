package be.sgerard.k8s.crd.model.resource;

import io.kubernetes.client.common.KubernetesListObject;
import io.kubernetes.client.openapi.models.V1ListMeta;
import lombok.Getter;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
public class BackupList implements KubernetesListObject {

    private String apiVersion;
    private List<Backup> items = new ArrayList<>();
    private String kind;
    private V1ListMeta metadata;

}
