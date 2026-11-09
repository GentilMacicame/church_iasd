package mz.org.iasd.igreja.infraestrutura.bd;

import jakarta.annotation.Priority;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.PreMatching;
import jakarta.ws.rs.ext.Provider;

/** Devolve o identificador do pedido no header {@code X-Pedido-Id} (o mesmo que vai em {@code pedidoId} dos erros). */
@Provider
@PreMatching
@Priority(1)
@ApplicationScoped
public class FiltroPedido implements ContainerRequestFilter, ContainerResponseFilter {

    static final String HEADER = "X-Pedido-Id";

    @Inject
    ContextoPedido contexto;

    @Override
    public void filter(ContainerRequestContext pedido) {
        contexto.pedidoId();   // gerado ao criar o contexto do pedido
    }

    @Override
    public void filter(ContainerRequestContext pedido, ContainerResponseContext resposta) {
        resposta.getHeaders().putSingle(HEADER, contexto.pedidoId());
    }
}
