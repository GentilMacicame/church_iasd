package mz.org.iasd.igreja.infraestrutura.seguranca;

import jakarta.servlet.http.HttpServletRequest;

/** IP e navegador de quem faz o pedido (guardados na sessão de login). */
public final class OrigemPedido {

    private OrigemPedido() {
    }

    /** Atrás do Nginx ({@code proxy.confiavel=true}) usa o primeiro endereço de X-Forwarded-For. */
    public static String ip(HttpServletRequest pedido, boolean proxyConfiavel) {
        String ip = pedido.getRemoteAddr();
        if (proxyConfiavel) {
            String encaminhado = pedido.getHeader("X-Forwarded-For");
            if (encaminhado != null && !encaminhado.isBlank()) {
                ip = encaminhado.split(",")[0].trim();
            }
        }
        if (ip == null) {
            return null;
        }
        int zona = ip.indexOf('%');            // IPv6 com zona (fe80::1%eth0) não é aceite pelo tipo inet
        ip = zona >= 0 ? ip.substring(0, zona) : ip;
        return ip.matches("[0-9a-fA-F:.]{2,45}") ? ip : null;
    }

    public static String navegador(HttpServletRequest pedido) {
        String ua = pedido.getHeader("User-Agent");
        return ua == null ? null : ua.substring(0, Math.min(ua.length(), 255));
    }
}
