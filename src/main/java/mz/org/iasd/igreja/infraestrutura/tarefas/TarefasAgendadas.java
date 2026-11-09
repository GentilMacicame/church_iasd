package mz.org.iasd.igreja.infraestrutura.tarefas;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.sql.DataSource;

import org.eclipse.microprofile.config.inject.ConfigProperty;

import jakarta.annotation.PreDestroy;
import jakarta.annotation.Resource;
import jakarta.enterprise.concurrent.ManagedScheduledExecutorService;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.event.Startup;
import jakarta.inject.Inject;

import mz.org.iasd.igreja.infraestrutura.bd.ExecutorTransaccao;

/**
 * Tarefas de manutenção que a base de dados pede para correrem periodicamente (Jakarta Concurrency).
 * Cada uma chama uma função SECURITY DEFINER da base, que decide o que fazer; a API só a agenda.
 *
 * <pre>
 *   diária   nucleo.fn_criar_particoes_log(3)         partições mensais do log de auditoria (3 meses à frente)
 *   diária   nucleo.fn_idempotencia_limpar()          termina as Idempotency-Key com mais de 24 horas
 *   diária   escola_sabatina.fn_anonimizar_visitantes() visitantes com mais de 12 meses ficam sem nome nem telefone
 * </pre>
 *
 * Correm sem utilizador na sessão ({@code app.usuario_id} vazio). A primeira execução é 2 minutos depois do
 * arranque. Desligam-se com {@code TAREFAS_ACTIVAS=false} (ex.: quando houver várias instâncias da API e
 * só uma as deva correr; as funções são idempotentes, por isso correr duas vezes não faz mal).
 */
@ApplicationScoped
public class TarefasAgendadas {

    private static final Logger LOG = Logger.getLogger(TarefasAgendadas.class.getName());
    private static final long PRIMEIRA_EXECUCAO_MINUTOS = 2;
    private static final long DIA_MINUTOS = 24 * 60;

    /** Tarefa: nome para o log e a função da base que a faz (devolve um número). */
    public record Tarefa(String nome, String sql) {
    }

    public static final List<Tarefa> DIARIAS = List.of(
            new Tarefa("partições do log de auditoria", "SELECT nucleo.fn_criar_particoes_log(3)"),
            new Tarefa("limpeza das chaves de idempotência", "SELECT nucleo.fn_idempotencia_limpar()"),
            new Tarefa("anonimização dos visitantes", "SELECT escola_sabatina.fn_anonimizar_visitantes()"));

    @Resource(lookup = "jdbc/igreja")
    DataSource fonte;

    @Resource
    ManagedScheduledExecutorService agendador;

    @Inject
    @ConfigProperty(name = "tarefas.activas", defaultValue = "true")
    boolean activas;

    private final List<ScheduledFuture<?>> agendadas = new ArrayList<>();

    void arrancar(@Observes Startup arranque) {
        if (!activas) {
            LOG.info("Tarefas agendadas desligadas (tarefas.activas=false)");
            return;
        }
        for (Tarefa t : DIARIAS) {
            agendadas.add(agendador.scheduleAtFixedRate(() -> correr(fonte, t), PRIMEIRA_EXECUCAO_MINUTOS,
                    DIA_MINUTOS, TimeUnit.MINUTES));
        }
        LOG.info(() -> "Tarefas agendadas: " + DIARIAS.size() + " diárias");
    }

    @PreDestroy
    void parar() {
        agendadas.forEach(f -> f.cancel(false));
    }

    /**
     * Corre uma tarefa numa transacção própria. Nunca lança excepção: uma falha não pode cancelar as
     * execuções seguintes. Devolve o número devolvido pela função, ou {@code null} se falhou.
     */
    public static Integer correr(DataSource fonte, Tarefa t) {
        try {
            Integer n = ExecutorTransaccao.executar(fonte, null, c -> {
                try (PreparedStatement ps = c.prepareStatement(t.sql()); ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    return rs.getInt(1);
                }
            });
            LOG.info(() -> "Tarefa \"" + t.nome() + "\": " + n);
            return n;
        } catch (Exception e) {
            LOG.log(Level.WARNING, "Tarefa \"" + t.nome() + "\" falhou", e);
            return null;
        }
    }
}
