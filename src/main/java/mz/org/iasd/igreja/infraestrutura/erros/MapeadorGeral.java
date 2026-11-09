package mz.org.iasd.igreja.infraestrutura.erros;

import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.json.bind.JsonbException;
import jakarta.ws.rs.ProcessingException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

import mz.org.iasd.igreja.infraestrutura.bd.ContextoPedido;

/**
 * Tudo o que não tem mapeador próprio: erros do JAX-RS (rota inexistente, JSON mal formado, ...)
 * e erros inesperados. Nunca devolve stack traces nem SQL ao cliente.
 */
@Provider
@ApplicationScoped
public class MapeadorGeral implements ExceptionMapper<Throwable> {

    private static final Logger LOG = Logger.getLogger(MapeadorGeral.class.getName());

    @Inject
    ContextoPedido contexto;

    @Inject
    MapeadorErroBaseDados mapeadorBd;

    @Override
    public Response toResponse(Throwable e) {
        String pedidoId = contexto.pedidoId();
        if (e instanceof WebApplicationException w) {
            int estado = w.getResponse().getStatus();
            return switch (estado) {
                case 401 -> Respostas.erro(401, "nao_autenticado", "Sessão em falta ou expirada", null, pedidoId);
                case 404 -> Respostas.erro(404, "nao_encontrado", "Endereço não encontrado", null, pedidoId);
                case 405 -> Respostas.erro(405, "pedido_invalido", "Método não permitido neste endereço", null, pedidoId);
                case 406, 415 -> Respostas.erro(estado, "pedido_invalido", "Use JSON (application/json)", null, pedidoId);
                case 413 -> Respostas.erro(413, "pedido_demasiado_grande", "O pedido é demasiado grande", null, pedidoId);
                default -> estado < 500
                        ? Respostas.erro(estado, "pedido_invalido", "Pedido mal formado", null, pedidoId)
                        : interno(e, pedidoId);
            };
        }
        // uma ApiException em qualquer ponto da cadeia decide a resposta (ex.: 413 lançado ao ler o corpo,
        // que o leitor de JSON embrulha numa ProcessingException)
        for (Throwable x = e; x != null && x.getCause() != x; x = x.getCause()) {
            if (x instanceof ApiException a) {
                return Respostas.erro(a.estadoHttp(), a.codigo(), a.getMessage(), a.campo(), pedidoId);
            }
        }
        for (Throwable x = e; x != null; x = x.getCause()) {
            if (x instanceof JsonbException || x instanceof ProcessingException) {
                return Respostas.erro(400, "pedido_invalido", "JSON mal formado ou com tipos errados", null, pedidoId);
            }
            if (x instanceof SQLException sql) {
                return mapeadorBd.toResponse(new ErroBaseDados(sql));
            }
            if (x instanceof ApiException a) {
                return Respostas.erro(a.estadoHttp(), a.codigo(), a.getMessage(), a.campo(), pedidoId);
            }
            if (x.getCause() == x) {
                break;
            }
        }
        return interno(e, pedidoId);
    }

    private static Response interno(Throwable e, String pedidoId) {
        LOG.log(Level.SEVERE, "Erro inesperado [pedido " + pedidoId + "]", e);
        return Respostas.erro(500, "erro_interno", "Erro interno. Se persistir, contacte o suporte.", null, pedidoId);
    }
}
