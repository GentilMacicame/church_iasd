package mz.org.iasd.igreja;

import jakarta.ws.rs.ApplicationPath;
import jakarta.ws.rs.core.Application;

/** Raiz da API. Os caminhos de cada recurso começam por {@code /v1/...}, como no openapi.yaml. */
@ApplicationPath("/")
public class AplicacaoRest extends Application {
}
