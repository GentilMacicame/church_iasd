package mz.org.iasd.igreja.controllers.base;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;

import jakarta.json.Json;
import jakarta.json.JsonArray;

import org.junit.jupiter.api.Test;

class PdfTest {

    @Test
    void nomesTecnicosFicamEmPortugues() {
        assertEquals("Relatório mensal", Pdf.humano("relatorio-mensal"));
        assertEquals("Total contado", Pdf.humano("totalContado"));
        assertEquals("Profissões de fé", Pdf.humano("profissoesDeFe"));
        assertEquals("Variação", Pdf.humano("variacao"));
        assertEquals("Transferências saída", Pdf.humano("transferenciasSaida"));
    }

    @Test
    void dinheiroDatasEBooleanos() {
        assertEquals("1 500,50", Pdf.dinheiro("1500.50"));
        assertEquals("-150,00", Pdf.dinheiro("-150.00"));
        assertEquals("0,00", Pdf.dinheiro("0.00"));
        assertEquals("05/10/2010", Pdf.texto(Json.createValue("2010-10-05")));
        assertEquals("Sim", Pdf.texto(jakarta.json.JsonValue.TRUE));
        assertEquals("A terminar", Pdf.texto(Json.createValue("A_TERMINAR")));
        assertEquals("Activo", Pdf.texto(Json.createValue("ACTIVO")));
        assertEquals("BIM", Pdf.texto(Json.createValue("BIM")));
        assertEquals("—", Pdf.texto(jakarta.json.JsonValue.NULL));
    }

    @Test
    void geraUmPdfComAsLinhas() {
        JsonArray linhas = Json.createArrayBuilder()
                .add(Json.createObjectBuilder().add("id", 1).add("igrejaId", 1).add("ano", 2026).add("mes", 11).add("baptismos", 2).add("totalContado", "12500.00"))
                .add(Json.createObjectBuilder().add("id", 2).add("igrejaId", 1).add("ano", 2026).add("mes", 10).add("baptismos", 0).add("totalContado", "980.00"))
                .build();
        byte[] pdf = Pdf.de(linhas, "relatorio-mensal", "Igreja Central", "Ano 2026", false);
        assertTrue(new String(pdf, 0, 5, StandardCharsets.ISO_8859_1).startsWith("%PDF-"));
        assertTrue(pdf.length > 1000);
        byte[] vazio = Pdf.de(Json.createArrayBuilder().build(), "censuras-activas", null, "", false);
        assertTrue(new String(vazio, 0, 5, StandardCharsets.ISO_8859_1).startsWith("%PDF-"));
    }
}
