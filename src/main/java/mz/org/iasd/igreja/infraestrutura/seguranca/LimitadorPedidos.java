package mz.org.iasd.igreja.infraestrutura.seguranca;

import java.time.Duration;
import java.util.OptionalLong;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

import jakarta.enterprise.context.ApplicationScoped;

/**
 * Limite de pedidos por chave (ex.: {@code login:ip:10.0.0.1}) em janelas fixas, em memória.
 * <p>
 * Protege os endpoints públicos (login, recuperação, renovação) contra força bruta e contra o gasto de CPU e
 * memória do Argon2. É por instância: com várias instâncias da API, o Nginx aplica também um limite global
 * ({@code docs/producao/nginx.conf.exemplo}).
 */
@ApplicationScoped
public class LimitadorPedidos {

    private static final int MAX_CHAVES = 200_000;

    private record Janela(long inicio, AtomicLong contagem) {
    }

    private final ConcurrentHashMap<String, Janela> janelas = new ConcurrentHashMap<>();
    private final AtomicLong pedidos = new AtomicLong();

    /** @return vazio se o pedido pode seguir; senão, os segundos até a janela acabar (header Retry-After) */
    public OptionalLong consumir(String chave, int maximo, Duration janela) {
        long agora = System.currentTimeMillis();
        long duracao = janela.toMillis();
        if (pedidos.incrementAndGet() % 1000 == 0 || janelas.size() > MAX_CHAVES) {
            limpar(agora, duracao);
        }
        Janela j = janelas.compute(chave, (k, actual) ->
                actual == null || agora - actual.inicio() >= duracao ? new Janela(agora, new AtomicLong()) : actual);
        if (j.contagem().incrementAndGet() <= maximo) {
            return OptionalLong.empty();
        }
        return OptionalLong.of(Math.max(1, (j.inicio() + duracao - agora + 999) / 1000));
    }

    private void limpar(long agora, long duracaoMaxima) {
        janelas.entrySet().removeIf(e -> agora - e.getValue().inicio() >= Math.max(duracaoMaxima, Duration.ofHours(1).toMillis()));
        if (janelas.size() > MAX_CHAVES) {
            janelas.clear();          // ataque com chaves sempre novas: recomeça (o Nginx limita por IP antes)
        }
    }
}
