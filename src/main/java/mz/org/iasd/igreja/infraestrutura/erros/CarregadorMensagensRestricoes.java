package mz.org.iasd.igreja.infraestrutura.erros;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.sql.DataSource;

import jakarta.annotation.Resource;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.event.Startup;

import mz.org.iasd.igreja.infraestrutura.bd.ExecutorTransaccao;

/**
 * Lê as frases das restrições ({@code nucleo.fn_mensagens_restricoes()}, V29) no arranque e de novo, no máximo de
 * 30 em 30 minutos, quando há um erro a traduzir (apanha migrações novas sem reiniciar). Se a base não responder,
 * o tradutor usa as mensagens genéricas e tenta outra vez depois de um minuto.
 */
@ApplicationScoped
public class CarregadorMensagensRestricoes {

    private static final Logger LOG = Logger.getLogger(CarregadorMensagensRestricoes.class.getName());
    private static final long RELER_MS = 30 * 60_000L;
    private static final long REPETIR_FALHA_MS = 60_000L;

    @Resource(lookup = "jdbc/igreja")
    DataSource fonte;

    private volatile long ultimaTentativa = 0;

    void arrancar(@Observes Startup arranque) {
        carregar();
    }

    /** Chamado antes de traduzir um erro: relê se as frases estiverem velhas (ou se nunca se leram). */
    public void garantir() {
        long agora = System.currentTimeMillis();
        long espera = MensagensRestricoes.idade() == Long.MAX_VALUE ? REPETIR_FALHA_MS : RELER_MS;
        if (MensagensRestricoes.idade() > RELER_MS && agora - ultimaTentativa > espera) {
            carregar();
        }
    }

    synchronized void carregar() {
        ultimaTentativa = System.currentTimeMillis();
        if (fonte == null) {
            return;
        }
        try {
            Map<String, String> lidas = ExecutorTransaccao.executar(fonte, null, c -> {
                Map<String, String> m = new HashMap<>();
                try (PreparedStatement ps = c.prepareStatement("SELECT nome, mensagem FROM nucleo.fn_mensagens_restricoes()");
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        m.put(rs.getString(1), rs.getString(2));
                    }
                }
                return m;
            });
            MensagensRestricoes.definir(lidas);
            LOG.fine(() -> "Mensagens das restrições: " + lidas.size());
        } catch (Exception e) {
            LOG.log(Level.WARNING, "Não foi possível ler as mensagens das restrições (fica a mensagem genérica): {0}",
                    e.getMessage());
        }
    }
}
