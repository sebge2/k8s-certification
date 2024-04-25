package be.sgerard.k8s.crd.model.resource;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.util.List;

@Getter
@Setter
@ToString
public class BackupSpec {

    private List<String> namespaces;

}
