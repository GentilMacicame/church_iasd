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
        // vindo do Nginx ou de outro serviço: o mesmo id em todos os logs (só UUIDs, para não injectar texto no log)
        String recebido = pedido.getHeaderString(HEADER);
        if (recebido != null && recebido.matches("[0-9a-fA-F-]{36}")) {
            contexto.definirPedidoId(recebido.toLowerCase());
        }
    }

    @Override
    public void filter(ContainerRequestContext pedido, ContainerResponseContext resposta) {
        resposta.getHeaders().putSingle(HEADER, contexto.pedidoId());
    }
}
