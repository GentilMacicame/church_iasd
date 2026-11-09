package mz.org.iasd.igreja.infraestrutura.tarefas;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.function.BiConsumer;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.sql.DataSource;

import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.metrics.MetricRegistry;
import org.eclipse.microprofile.metrics.Tag;

import jakarta.annotation.PreDestroy;
import jakarta.annotation.Resource;
import jakarta.enterprise.concurrent.ManagedScheduledExecutorService;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.event.Startup;
import jakarta.inject.Inject;

import mz.org.iasd.igreja.infraestrutura.bd.ExecutorTransaccao;
import mz.org.iasd.igreja.infraestrutura.mensagens.EnvioMensagens;

/**
 * Tarefas de manutenção que a base de dados pede para correrem periodicamente (Jakarta Concurrency).
 * Cada uma chama uma função SECURITY DEFINER da base, que decide o que fazer; a API só a agenda.
 *
 * <pre>
 *   diária   nucleo.fn_criar_particoes_log(3)         partições mensais do log de auditoria (3 meses à frente)
 *   diária   nucleo.fn_idempotencia_limpar()          termina as Idempotency-Key com mais de 24 horas
 *   diária   escola_sabatina.fn_anonimizar_visitantes() visitantes com mais de 12 meses ficam sem nome nem telefone
 *   diária   nucleo.fn_limpar_sessoes()               termina sessões, códigos e bloqueios de login expirados (V16)
 *   horária  actividades.fn_lembretes_escala()        à quarta e à sexta põe na fila os SMS de quem está escalado
 *                                                     para sábado (envio às 18:00; sem repetir) (V17)
 *   1 min    envio da fila de SMS                     nucleo.fn_notificacoes_reservar → fornecedor de SMS →
 *                                                     fn_notificacao_resultado (só com MENSAGENS_MODO consola/http)
 * </pre>
 *
 * Métricas ({@code /metrics}): {@code sms_enviados_total}, {@code sms_falhados_total}, e por tarefa
 * {@code tarefas_execucoes_total} e {@code tarefas_falhas_total}, e
 * {@code tarefas_ultimo_sucesso_segundos} (hora da última execução bem-sucedida). A monitorização deve alertar
 * quando {@code tarefas_falhas_total} sobe ou o último sucesso tem mais de 26 horas.
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

    /** Tarefa: identificador (métricas), nome para o log e a função da base que a faz (devolve um número). */
    public record Tarefa(String id, String nome, String sql) {
    }

    public static final List<Tarefa> DIARIAS = List.of(
            new Tarefa("particoes_log", "partições do log de auditoria", "SELECT nucleo.fn_criar_particoes_log(3)"),
            new Tarefa("idempotencia", "limpeza das chaves de idempotência", "SELECT nucleo.fn_idempotencia_limpar()"),
            new Tarefa("visitantes", "anonimização dos visitantes", "SELECT escola_sabatina.fn_anonimizar_visitantes()"),
            new Tarefa("sessoes", "limpeza de sessões e bloqueios", "SELECT nucleo.fn_limpar_sessoes()"));

    public static final List<Tarefa> HORARIAS = List.of(
            new Tarefa("lembretes_escala", "lembretes de escala", "SELECT actividades.fn_lembretes_escala()"));

    private static final int SMS_POR_RONDA = 50;

    @Resource(lookup = "jdbc/igreja")
    DataSource fonte;

    @Resource
    ManagedScheduledExecutorService agendador;

    @Inject
    @ConfigProperty(name = "tarefas.activas", defaultValue = "true")
    boolean activas;

    @Inject
    MetricRegistry metricas;

    @Inject
    EnvioMensagens envio;

    private final Map<String, AtomicLong> ultimoSucesso = new ConcurrentHashMap<>();

    private final List<ScheduledFuture<?>> agendadas = new ArrayList<>();

    void arrancar(@Observes Startup arranque) {
        if (!activas) {
            LOG.info("Tarefas agendadas desligadas (tarefas.activas=false)");
            return;
        }
        for (Tarefa t : DIARIAS) {
            agendar(t, DIA_MINUTOS);
        }
        for (Tarefa t : HORARIAS) {
            agendar(t, 60);
        }
        if (envio.activo()) {
            agendadas.add(agendador.scheduleWithFixedDelay(() -> enviarFila(fonte, envio::enviarSms, metricas),
                    PRIMEIRA_EXECUCAO_MINUTOS, 1, TimeUnit.MINUTES));
        } else {
            LOG.info("Envio de SMS desligado (MENSAGENS_MODO=desligado): os lembretes ficam na fila");
        }
        LOG.info(() -> "Tarefas agendadas: " + DIARIAS.size() + " diárias, " + HORARIAS.size() + " horárias"
                + (envio.activo() ? ", envio de SMS a cada minuto" : ""));
    }

    private void agendar(Tarefa t, long periodoMinutos) {
        Tag tag = new Tag("tarefa", t.id());
        AtomicLong sucesso = ultimoSucesso.computeIfAbsent(t.id(), k -> new AtomicLong());
        metricas.gauge("tarefas_ultimo_sucesso_segundos", sucesso, AtomicLong::get, tag);
        agendadas.add(agendador.scheduleAtFixedRate(() -> {
            metricas.counter("tarefas_execucoes_total", tag).inc();
            if (correr(fonte, t) == null) {
                metricas.counter("tarefas_falhas_total", tag).inc();
            } else {
                sucesso.set(System.currentTimeMillis() / 1000);
            }
        }, PRIMEIRA_EXECUCAO_MINUTOS, periodoMinutos, TimeUnit.MINUTES));
    }

    /**
     * Envia uma ronda da fila de SMS: reserva (transacção curta), envia cada um fora de qualquer transacção e
     * regista o resultado (outra transacção curta). Uma falha volta à fila com o motivo; nunca lança excepção.
     * Devolve quantos foram enviados, ou -1 se não conseguiu falar com a base.
     */
    public static int enviarFila(DataSource fonte, BiConsumer<String, String> enviar, MetricRegistry metricas) {
        List<String[]> reservadas;
        try {
            reservadas = ExecutorTransaccao.executar(fonte, null, c -> {
                List<String[]> r = new ArrayList<>();
                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT id, destino, mensagem FROM nucleo.fn_notificacoes_reservar(" + SMS_POR_RONDA + ")");
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        r.add(new String[] {rs.getString(1), rs.getString(2), rs.getString(3)});
                    }
                }
                return r;
            });
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Envio de SMS: não foi possível ler a fila", e);
            return -1;
        }
        int enviados = 0;
        for (String[] n : reservadas) {
            String erro = null;
            try {
                enviar.accept(n[1], n[2]);
                enviados++;
            } catch (RuntimeException e) {
                erro = e.getMessage() == null ? e.getClass().getSimpleName() : e.getMessage();
            }
            if (metricas != null) {
                metricas.counter(erro == null ? "sms_enviados_total" : "sms_falhados_total").inc();
            }
            final String motivo = erro;
            try {
                ExecutorTransaccao.executar(fonte, null, c -> {
                    try (PreparedStatement ps = c.prepareStatement(
                            "SELECT nucleo.fn_notificacao_resultado(?::bigint, ?, ?)")) {
                        ps.setLong(1, Long.parseLong(n[0]));
                        ps.setBoolean(2, motivo == null);
                        ps.setString(3, motivo);
                        ps.execute();
                    }
                    return null;
                });
            } catch (Exception e) {
                // a reserva expira em 10 minutos e a mensagem volta à fila
                LOG.log(Level.SEVERE, "Envio de SMS: resultado da notificação " + n[0] + " não registado", e);
            }
        }
        if (!reservadas.isEmpty()) {
            int total = enviados;
            LOG.info(() -> "SMS: " + total + " enviados de " + reservadas.size());
        }
        return enviados;
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
            LOG.log(Level.SEVERE, "Tarefa \"" + t.nome() + "\" falhou", e);
            return null;
        }
    }
}
