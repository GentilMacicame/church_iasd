package mz.org.iasd.igreja.controllers.tesouraria;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.time.LocalDate;

import org.junit.jupiter.api.Test;

import mz.org.iasd.igreja.infraestrutura.erros.ApiException;

/** Leitura das linhas do extracto (CSV) em POST /v1/tesouraria/extractos/importar. */
class ExtractosControllerTest {

    @Test
    void datas() {
        assertEquals(LocalDate.of(2026, 11, 9), ExtractosController.data("09/11/2026", 1));
        assertEquals(LocalDate.of(2026, 11, 9), ExtractosController.data("2026-11-09", 1));
        assertThrows(ApiException.class, () -> ExtractosController.data("9 de Novembro", 3));
    }

    @Test
    void valores() {
        assertEquals("1500.50", ExtractosController.valor("1 500,50", 1));
        assertEquals("-200.00", ExtractosController.valor("-200,00", 1));
        assertEquals("1500.5", ExtractosController.valor("1500.5", 1));
        ApiException e = assertThrows(ApiException.class, () -> ExtractosController.valor("abc", 2));
        assertEquals("csv", e.campo());
    }
}
