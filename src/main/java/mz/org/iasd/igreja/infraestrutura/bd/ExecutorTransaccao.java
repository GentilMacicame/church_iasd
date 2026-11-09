package mz.org.iasd.igreja.infraestrutura.bd;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.sql.DataSource;

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
 * Classe sem dependências do servidor, para ser usada também nos testes de integração.
 */
public final class ExecutorTransaccao {

    public static final int TENTATIVAS = 3;
    private static final Logger LOG = Logger.getLogger(ExecutorTransaccao.class.getName());

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
    public static <T> T executar(DataSource fonte, Integer usuarioId, Trabalho<T> trabalho) throws Exception {
        for (int tentativa = 1; ; tentativa++) {
            try (Connection ligacao = fonte.getConnection()) {
                ligacao.setAutoCommit(false);
                try {
                    identificar(ligacao, usuarioId);
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

    static void identificar(Connection ligacao, Integer usuarioId) throws SQLException {
        if (usuarioId == null) {
            return;
        }
        try (PreparedStatement ps = ligacao.prepareStatement("SELECT set_config('app.usuario_id', ?, true)")) {
            ps.setString(1, usuarioId.toString());
            ps.execute();
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
