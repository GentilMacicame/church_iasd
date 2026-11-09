package mz.org.iasd.igreja.infraestrutura.erros;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

import mz.org.iasd.igreja.infraestrutura.bd.ContextoPedido;

@Provider
@ApplicationScoped
public class MapeadorApiException implements ExceptionMapper<ApiException> {

    @Inject
    ContextoPedido contexto;

    @Override
    public Response toResponse(ApiException e) {
        return Respostas.erro(e.estadoHttp(), e.codigo(), e.getMessage(), e.campo(), contexto.pedidoId());
    }
}
