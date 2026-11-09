package mz.org.iasd.igreja.infraestrutura.seguranca;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import java.lang.reflect.Proxy;
import java.util.Map;

import org.junit.jupiter.api.Test;

import jakarta.servlet.http.HttpServletRequest;

/** Auditoria L1: atrás do proxy conta o último endereço de X-Forwarded-For (o que o Nginx acrescentou). */
class OrigemPedidoTest {

    private static HttpServletRequest pedido(String remoto, Map<String, String> headers) {
        return (HttpServletRequest) Proxy.newProxyInstance(OrigemPedidoTest.class.getClassLoader(),
                new Class<?>[] {HttpServletRequest.class}, (proxy, metodo, args) -> switch (metodo.getName()) {
                    case "getRemoteAddr" -> remoto;
                    case "getHeader" -> headers.get((String) args[0]);
                    default -> null;
                });
    }

    @Test
    void ultimoEnderecoDoProxy() {
        HttpServletRequest p = pedido("10.0.0.2", Map.of("X-Forwarded-For", "1.2.3.4, 41.220.1.9"));
        assertEquals("41.220.1.9", OrigemPedido.ip(p, true));
        assertEquals("10.0.0.2", OrigemPedido.ip(p, false), "sem proxy confiável o header é ignorado");
    }

    @Test
    void valorInventadoNaoPassa() {
        assertNull(OrigemPedido.ip(pedido("10.0.0.2", Map.of("X-Forwarded-For", "<script>")), true));
    }
}
