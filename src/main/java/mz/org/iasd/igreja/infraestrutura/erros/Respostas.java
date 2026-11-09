package mz.org.iasd.igreja.infraestrutura.erros;

import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

/** Construção das respostas de erro no formato do contrato. */
public final class Respostas {

    private Respostas() {
    }

    public static Response erro(int estadoHttp, String codigo, String mensagem, String campo, String pedidoId) {
        return Response.status(estadoHttp)
                .type(MediaType.APPLICATION_JSON_TYPE)
                .entity(new ErroApi(codigo, mensagem, campo, pedidoId))
                .build();
    }
}
