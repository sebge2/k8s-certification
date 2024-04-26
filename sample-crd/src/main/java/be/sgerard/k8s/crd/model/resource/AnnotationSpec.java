package be.sgerard.k8s.crd.model.resource;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.util.Map;

@Getter
@Setter
@ToString
public class AnnotationSpec {

    private Map<String, String> annotations;

}
