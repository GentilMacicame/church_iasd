package mz.org.iasd.igreja.infraestrutura.seguranca;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.Duration;

import org.junit.jupiter.api.Test;

/** Auditoria H2: limite de pedidos por chave. */
class LimitadorPedidosTest {

    @Test
    void recusaDepoisDoMaximoEPorChave() {
        LimitadorPedidos l = new LimitadorPedidos();
        for (int i = 0; i < 3; i++) {
            assertTrue(l.consumir("login:ip:1", 3, Duration.ofMinutes(5)).isEmpty());
        }
        var espera = l.consumir("login:ip:1", 3, Duration.ofMinutes(5));
        assertTrue(espera.isPresent() && espera.getAsLong() > 0 && espera.getAsLong() <= 300);
        assertTrue(l.consumir("login:ip:2", 3, Duration.ofMinutes(5)).isEmpty(), "outra chave não é afectada");
    }

    @Test
    void novaJanelaRecomeca() throws InterruptedException {
        LimitadorPedidos l = new LimitadorPedidos();
        assertTrue(l.consumir("x", 1, Duration.ofMillis(50)).isEmpty());
        assertTrue(l.consumir("x", 1, Duration.ofMillis(50)).isPresent());
        Thread.sleep(80);
        assertTrue(l.consumir("x", 1, Duration.ofMillis(50)).isEmpty());
    }
}
