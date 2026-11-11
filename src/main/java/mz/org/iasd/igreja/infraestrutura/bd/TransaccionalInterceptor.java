package mz.org.iasd.igreja.infraestrutura.bd;

import java.io.StringReader;
import java.sql.SQLException;
import java.util.Optional;
import java.util.UUID;

import javax.sql.DataSource;

import jakarta.annotation.Priority;
import jakarta.annotation.Resource;
import jakarta.enterprise.concurrent.ManagedExecutorService;
import jakarta.inject.Inject;
import jakarta.interceptor.AroundInvoke;
import jakarta.interceptor.Interceptor;
import jakarta.interceptor.InvocationContext;
import jakarta.json.Json;
import jakarta.json.JsonValue;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.infraestrutura.erros.ErroBaseDados;

/**
 * Unidade de trabalho de cada pedido: abre a transacção com o utilizador identificado
 * (via {@link ExecutorTransaccao}), trata o {@code Idempotency-Key} ({@link Idempotente}) e faz COMMIT
 * ou ROLLBACK.
 * Implementado uma só vez; os recursos só anotam a classe com {@link Transaccional}.
 *
 * Nota: para repetir a transacção em caso de conflito (40001/40P01) o método do recurso é
 * invocado de novo ({@code proceed()} várias vezes, suportado pelo Weld do Open Liberty).
 */
@Transaccional
@Interceptor
@Priority(Interceptor.Priority.APPLICATION)
public class TransaccionalInterceptor {

    static final String HEADER_IDEMPOTENCIA = "Idempotency-Key";

    @Resource(lookup = "jdbc/igreja")
    DataSource fonte;

    @Inject
    UnidadeDeTrabalho unidade;

    @Inject
    ContextoPedido contexto;

    @Inject
    HttpServletRequest pedido;

    /** Termina as transacções de leitura (COMMIT e devolução da ligação) depois de a resposta seguir. */
    @Resource
    ManagedExecutorService terminarLeituras;

    @AroundInvoke
    public Object executar(InvocationContext ctx) throws Exception {
        String metodo = pedido.getMethod();
        String caminho = pedido.getRequestURI();
        UUID chave = chave(ctx, metodo);
        String hashPedido = chave == null ? null : hashPedido(ctx);
        ExecutorTransaccao.Trabalho<Object> trabalho = ligacao -> {
                unidade.definir(ligacao);
                try {
                    if (chave != null) {
                        Optional<IdempotenciaRepository.RespostaGuardada> guardada =
                                IdempotenciaRepository.obter(ligacao, chave);
                        if (guardada.isPresent()) {
                            return repetir(guardada.get(), metodo, caminho, hashPedido);
                        }
                    }
                    Object resultado = ctx.proceed();
                    if (chave != null && resultado instanceof Response resposta) {
                        String json = resposta.hasEntity()
                                ? mz.org.iasd.igreja.config.Json.JSONB.toJson(resposta.getEntity())
                                : null;
                        IdempotenciaRepository.guardar(ligacao, chave, metodo, caminho, resposta.getStatus(), json,
                                hashPedido);
                    }
                    return resultado;
                } finally {
                    unidade.limpar();
                }
            };
        try {
            // GET só lê: o COMMIT não precisa de atrasar a resposta (uma ida e volta a menos à base)
            return "GET".equals(metodo) && chave == null
                    ? ExecutorTransaccao.executarLeitura(fonte, contexto.usuarioId(), contexto.sessaoId(), trabalho, terminarLeituras)
                    : ExecutorTransaccao.executar(fonte, contexto.usuarioId(), contexto.sessaoId(), trabalho);
        } catch (SQLException e) {
            throw new ErroBaseDados(e);
        }
    }

    /** Método com @Idempotente → obrigatória; classe com @Idempotente(opcional = true) → usada se vier (só POST). */
    private UUID chave(InvocationContext ctx, String metodo) {
        Idempotente doMetodo = ctx.getMethod().getAnnotation(Idempotente.class);
        if (doMetodo != null && !doMetodo.opcional()) {
            return chaveIdempotencia();
        }
        Idempotente daClasse = ctx.getTarget() == null ? null : ctx.getTarget().getClass().getAnnotation(Idempotente.class);
        if ("POST".equals(metodo) && (doMetodo != null || daClasse != null) && pedido.getHeader(HEADER_IDEMPOTENCIA) != null) {
            return chaveIdempotencia();
        }
        return null;
    }

    private UUID chaveIdempotencia() {
        String valor = pedido.getHeader(HEADER_IDEMPOTENCIA);
        if (valor == null || valor.isBlank()) {
            throw ApiException.pedidoInvalido("Falta o header Idempotency-Key (UUID)", HEADER_IDEMPOTENCIA);
        }
        try {
            return UUID.fromString(valor.trim());
        } catch (IllegalArgumentException e) {
            throw ApiException.pedidoInvalido("O header Idempotency-Key tem de ser um UUID", HEADER_IDEMPOTENCIA);
        }
    }

    /** SHA-256 dos parâmetros do método (caminho e corpo): a mesma chave com outro pedido é recusada. */
    static String hashPedido(InvocationContext ctx) {
        return mz.org.iasd.igreja.infraestrutura.seguranca.Segredos.sha256(java.util.Arrays.deepToString(ctx.getParameters()));
    }

    private static Response repetir(IdempotenciaRepository.RespostaGuardada guardada, String metodo, String caminho,
                                    String hashPedido) {
        if (!guardada.metodo().equals(metodo) || !guardada.caminho().equals(caminho)
                || (guardada.pedidoHash() != null && !guardada.pedidoHash().equals(hashPedido))) {
            throw new ApiException(422, "regra_negocio",
                    "Esta Idempotency-Key já foi usada noutro pedido; gere uma chave nova", HEADER_IDEMPOTENCIA);
        }
        Response.ResponseBuilder r = Response.status(guardada.estadoHttp()).header("Idempotency-Replayed", "true");
        if (guardada.respostaJson() != null) {
            JsonValue corpo = Json.createReader(new StringReader(guardada.respostaJson())).readValue();
            r.entity(corpo).type(MediaType.APPLICATION_JSON_TYPE);
        }
        return r.build();
    }
}
