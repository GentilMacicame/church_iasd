package mz.org.iasd.igreja.infraestrutura.bd;

import java.util.UUID;

import jakarta.enterprise.context.RequestScoped;

/** Dados do pedido HTTP em curso: identificador para os logs e utilizador autenticado. */
@RequestScoped
public class ContextoPedido {

    private String pedidoId = UUID.randomUUID().toString();
    private Integer usuarioId;
    private Long sessaoId;

    public String pedidoId() {
        return pedidoId;
    }

    public void definirPedidoId(String pedidoId) {
        this.pedidoId = pedidoId;
    }

    /** @return o utilizador autenticado, ou {@code null} nos endpoints públicos */
    public Integer usuarioId() {
        return usuarioId;
    }

    public void definirUsuario(Integer usuarioId) {
        this.usuarioId = usuarioId;
    }

    /** @return a sessão de login do token de acesso ({@code sid}), ou {@code null} nos endpoints públicos */
    public Long sessaoId() {
        return sessaoId;
    }

    public void definirSessao(Long sessaoId) {
        this.sessaoId = sessaoId;
    }
}
