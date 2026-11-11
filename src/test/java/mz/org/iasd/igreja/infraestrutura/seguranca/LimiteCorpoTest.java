package mz.org.iasd.igreja.infraestrutura.seguranca;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.io.ByteArrayInputStream;

import org.junit.jupiter.api.Test;

import mz.org.iasd.igreja.infraestrutura.erros.ApiException;

/** Auditoria M6: corpo maior do que o máximo → 413, mesmo sem Content-Length. */
class LimiteCorpoTest {

    @Test
    void contaOsBytesLidos() throws Exception {
        try (var ok = new LimiteCorpo.Contado(new ByteArrayInputStream(new byte[10]), 10)) {
            assertEquals(10, ok.readAllBytes().length);
        }
        try (var grande = new LimiteCorpo.Contado(new ByteArrayInputStream(new byte[11]), 10)) {
            ApiException e = assertThrows(ApiException.class, grande::readAllBytes);
            assertEquals(413, e.estadoHttp());
        }
    }

    /** Só o carregamento de comprovativos tem o máximo maior (ficheiros.max.kb). */
    @Test
    void carregamentoDeComprovativos() {
        assertEquals(true, LimiteCorpo.carregamento("POST", "/v1/tesouraria/documentos/carregar"));
        assertEquals(true, LimiteCorpo.carregamento("POST", "v1/tesouraria/documentos/carregar/"));
        assertEquals(false, LimiteCorpo.carregamento("GET", "/v1/tesouraria/documentos/carregar"));
        assertEquals(false, LimiteCorpo.carregamento("POST", "/v1/tesouraria/transacoes"));
        assertEquals(false, LimiteCorpo.carregamento("POST", "/v1/tesouraria/documentos"));
    }
}
