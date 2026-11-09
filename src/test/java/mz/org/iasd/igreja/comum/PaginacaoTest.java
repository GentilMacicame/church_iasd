package mz.org.iasd.igreja.comum;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;

import org.junit.jupiter.api.Test;

import mz.org.iasd.igreja.infraestrutura.erros.ApiException;

class PaginacaoTest {

    @Test
    void cursorIdaEVolta() {
        assertEquals(12345L, Paginacao.descodificar(Paginacao.codificar(12345L)));
        assertNull(Paginacao.descodificar(null));
        assertNull(Paginacao.descodificar(""));
    }

    @Test
    void cursorInvalidoDa400() {
        ApiException e = assertThrows(ApiException.class, () -> Paginacao.descodificar("lixo!!"));
        assertEquals(400, e.estadoHttp());
        assertEquals("depois", e.campo());
    }

    @Test
    void limites() {
        assertEquals(50, Paginacao.limite(null));
        assertEquals(200, Paginacao.limite(200));
        assertThrows(ApiException.class, () -> Paginacao.limite(0));
        assertThrows(ApiException.class, () -> Paginacao.limite(201));
    }

    @Test
    void paginaComSeguinte() {
        Paginacao.Pagina<Integer> p = Paginacao.pagina(List.of(1, 2, 3), 2, Integer::longValue);
        assertEquals(List.of(1, 2), p.dados());
        assertEquals(2L, Paginacao.descodificar(p.proximo()));
    }

    @Test
    void ultimaPagina() {
        Paginacao.Pagina<Integer> p = Paginacao.pagina(List.of(1, 2), 2, Integer::longValue);
        assertEquals(List.of(1, 2), p.dados());
        assertNull(p.proximo());
    }

    @Test
    void dinheiro() {
        assertEquals("650.00", Dinheiro.paraJson(new java.math.BigDecimal("650")));
        assertEquals(new java.math.BigDecimal("1500.50"), Dinheiro.deJson("1500.5", "valor"));
        assertThrows(ApiException.class, () -> Dinheiro.deJson("1 500,50", "valor"));
        assertThrows(ApiException.class, () -> Dinheiro.deJson("1.234", "valor"));
    }
}
