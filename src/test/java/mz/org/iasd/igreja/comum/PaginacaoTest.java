package mz.org.iasd.igreja.comum;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

import mz.org.iasd.igreja.infraestrutura.erros.ApiException;

class PaginacaoTest {

    @Test
    void limites() {
        assertEquals(50, Paginacao.limite(null));
        assertEquals(200, Paginacao.limite(200));
        assertThrows(ApiException.class, () -> Paginacao.limite(0));
        assertThrows(ApiException.class, () -> Paginacao.limite(201));
    }

    @Test
    void dinheiro() {
        assertEquals("650.00", Dinheiro.paraJson(new java.math.BigDecimal("650")));
        assertEquals(new java.math.BigDecimal("1500.50"), Dinheiro.deJson("1500.5", "valor"));
        assertThrows(ApiException.class, () -> Dinheiro.deJson("1 500,50", "valor"));
        assertThrows(ApiException.class, () -> Dinheiro.deJson("1.234", "valor"));
    }
}
