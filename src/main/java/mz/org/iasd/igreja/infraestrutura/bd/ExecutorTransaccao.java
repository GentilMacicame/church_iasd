package mz.org.iasd.igreja.infraestrutura.bd;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.sql.DataSource;

import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.infraestrutura.erros.TradutorErrosSql;

/**
 * O único sítio onde se abre uma transacção (CLAUDE.md, regra 4):
 *
 * <pre>
 *   BEGIN;
 *   SELECT set_config('app.usuario_id', $1, true);   -- true = só nesta transacção (PgBouncer)
 *   -- ... trabalho ...
 *   COMMIT;
 * </pre>
 *
 * Em conflito entre pedidos simultâneos (40001 / 40P01) repete a transacção inteira até 3 vezes.
 * Cada transacção tem tempo máximo por instrução ({@code statement_timeout}) e por bloqueio
 * ({@code lock_timeout}), para uma consulta lenta não prender ligações do pool sem limite.
 * Com o id da sessão do token, confirma na mesma ida à base que a sessão continua activa
 * ({@code nucleo.fn_sessao_activa}, V16): logout, senha redefinida ou utilizador inactivo → 401.
 * Classe sem dependências do servidor, para ser usada também nos testes de integração.
 */
public final class ExecutorTransaccao {

    public static final int TENTATIVAS = 3;
    private static final Logger LOG = Logger.getLogger(ExecutorTransaccao.class.getName());
    private static volatile String timeoutConsultaMs = "30000";
    private static volatile String timeoutBloqueioMs = "5000";

    @FunctionalInterface
    public interface Trabalho<T> {
        T executar(Connection ligacao) throws Exception;
    }

    private ExecutorTransaccao() {
    }

    /**
     * @param usuarioId utilizador autenticado; {@code null} só nos endpoints públicos (login, recuperação),
     *                  que usam funções SECURITY DEFINER próprias para isso
     */
    /** Definido no arranque a partir da configuração (bd.timeout.*). */
    public static void definirTimeouts(int consultaMs, int bloqueioMs) {
        timeoutConsultaMs = Integer.toString(consultaMs);
        timeoutBloqueioMs = Integer.toString(bloqueioMs);
    }

    public static <T> T executar(DataSource fonte, Integer usuarioId, Trabalho<T> trabalho) throws Exception {
        return executar(fonte, usuarioId, null, trabalho);
    }

    /**
     * @param sessaoId sessão do token de acesso ({@code sid}); se vier, a sessão tem de estar activa
     */
    public static <T> T executar(DataSource fonte, Integer usuarioId, Long sessaoId, Trabalho<T> trabalho)
            throws Exception {
        for (int tentativa = 1; ; tentativa++) {
            try (Connection ligacao = fonte.getConnection()) {
                ligacao.setAutoCommit(false);
                try {
                    identificar(ligacao, usuarioId, sessaoId);
                    T resultado = trabalho.executar(ligacao);
                    ligacao.commit();          // os triggers DEFERRABLE (ex.: soma das linhas) correm aqui
                    return resultado;
                } catch (Exception e) {
                    desfazer(ligacao);
                    SQLException sql = TradutorErrosSql.encontrar(e);
                    if (sql != null && TradutorErrosSql.repetivel(sql) && tentativa < TENTATIVAS) {
                        LOG.log(Level.INFO, "Conflito entre transacções ({0}); tentativa {1} de {2}",
                                new Object[] {sql.getSQLState(), tentativa + 1, TENTATIVAS});
                        continue;
                    }
                    throw e;
                } catch (Error e) {
                    desfazer(ligacao);
                    throw e;
                }
            }
        }
    }

    /**
     * Pedido só de leitura (GET): igual a {@link #executar(DataSource, Integer, Long, Trabalho)} até ao fim do trabalho
     * (utilizador identificado na transacção, RLS, repetição em conflito), mas o COMMIT e a devolução da ligação ao
     * pool fazem-se em {@code depois}, sem o pedido esperar: poupa uma ida e volta à base (com a base longe, ~0,5 s
     * por pedido). Uma leitura não tem nada a confirmar: o COMMIT só termina a transacção. Se {@code depois} recusar
     * a tarefa, faz-se tudo aqui, como numa escrita.
     */
    public static <T> T executarLeitura(DataSource fonte, Integer usuarioId, Long sessaoId, Trabalho<T> trabalho,
            java.util.concurrent.Executor depois) throws Exception {
        for (int tentativa = 1; ; tentativa++) {
            Connection ligacao = fonte.getConnection();
            boolean entregue = false;
            try {
                ligacao.setAutoCommit(false);
                identificar(ligacao, usuarioId, sessaoId);
                T resultado = trabalho.executar(ligacao);
                try {
                    depois.execute(() -> terminar(ligacao));
                    entregue = true;
                } catch (java.util.concurrent.RejectedExecutionException e) {
                    ligacao.commit();
                }
                return resultado;
            } catch (Exception e) {
                desfazer(ligacao);
                SQLException sql = TradutorErrosSql.encontrar(e);
                if (sql != null && TradutorErrosSql.repetivel(sql) && tentativa < TENTATIVAS) {
                    continue;
                }
                throw e;
            } catch (Error e) {
                desfazer(ligacao);
                throw e;
            } finally {
                if (!entregue) {
                    fechar(ligacao);
                }
            }
        }
    }

    /** COMMIT da leitura e devolução da ligação ao pool (fora do pedido). */
    private static void terminar(Connection ligacao) {
        try {
            ligacao.commit();
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Falha ao terminar uma transacção de leitura", e);
            desfazer(ligacao);
        } finally {
            fechar(ligacao);
        }
    }

    private static void fechar(Connection ligacao) {
        try {
            ligacao.close();
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Falha ao devolver a ligação ao pool", e);
        }
    }

    static void identificar(Connection ligacao, Integer usuarioId, Long sessaoId) throws SQLException {
        String sql = "SELECT set_config('statement_timeout', ?, true), set_config('lock_timeout', ?, true)"
                + (usuarioId == null ? "" : ", set_config('app.usuario_id', ?, true)")
                + (usuarioId == null || sessaoId == null ? "" : ", nucleo.fn_sessao_activa(?::integer, ?::bigint)");
        try (PreparedStatement ps = ligacao.prepareStatement(sql)) {
            ps.setString(1, timeoutConsultaMs);
            ps.setString(2, timeoutBloqueioMs);
            if (usuarioId != null) {
                ps.setString(3, usuarioId.toString());
                if (sessaoId != null) {
                    ps.setInt(4, usuarioId);
                    ps.setLong(5, sessaoId);
                }
            }
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                if (usuarioId != null && sessaoId != null && !rs.getBoolean(4)) {
                    throw new ApiException(401, "nao_autenticado", "Sessão terminada. Entre de novo.", null);
                }
            }
        }
    }

    private static void desfazer(Connection ligacao) {
        try {
            ligacao.rollback();
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Falha ao desfazer a transacção", e);
        }
    }
}
