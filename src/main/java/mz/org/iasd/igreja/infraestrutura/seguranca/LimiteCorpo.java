package mz.org.iasd.igreja.infraestrutura.seguranca;

import java.io.FilterInputStream;
import java.io.IOException;
import java.io.InputStream;

import jakarta.annotation.Priority;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.PreMatching;
import jakarta.ws.rs.ext.Provider;

import mz.org.iasd.igreja.config.Configuracao;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;

/**
 * Tamanho máximo do corpo de cada pedido ({@code pedido.max.kb}, 2 MB por defeito): acima disso, 413.
 * Verifica o Content-Length e conta também os bytes lidos (pedidos sem Content-Length).
 */
@Provider
@PreMatching
@Priority(Priorities.AUTHENTICATION - 100)
@ApplicationScoped
public class LimiteCorpo implements ContainerRequestFilter {

    @Inject
    Configuracao configuracao;

    @Override
    public void filter(ContainerRequestContext pedido) {
        long maximo = configuracao.pedidoMaxBytes();
        if (pedido.getLength() > maximo) {
            throw demasiadoGrande();
        }
        if (pedido.hasEntity()) {
            pedido.setEntityStream(new Contado(pedido.getEntityStream(), maximo));
        }
    }

    static ApiException demasiadoGrande() {
        return new ApiException(413, "pedido_demasiado_grande", "O pedido é demasiado grande", null);
    }

    /** Lança 413 quando se lê mais do que o máximo. */
    static final class Contado extends FilterInputStream {

        private final long maximo;
        private long lidos;

        Contado(InputStream origem, long maximo) {
            super(origem);
            this.maximo = maximo;
        }

        @Override
        public int read() throws IOException {
            int b = super.read();
            if (b >= 0) {
                contar(1);
            }
            return b;
        }

        @Override
        public int read(byte[] destino, int inicio, int tamanho) throws IOException {
            int n = super.read(destino, inicio, tamanho);
            if (n > 0) {
                contar(n);
            }
            return n;
        }

        private void contar(int n) {
            lidos += n;
            if (lidos > maximo) {
                throw demasiadoGrande();
            }
        }
    }
}
