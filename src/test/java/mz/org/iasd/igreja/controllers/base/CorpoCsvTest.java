package mz.org.iasd.igreja.controllers.base;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

import jakarta.json.Json;
import jakarta.json.JsonValue;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;

/** Leitura do corpo do pedido e exportação CSV dos controllers-base. */
class CorpoCsvTest {

    @Test
    void corpoDoPedido() {
        assertEquals(JsonValue.NULL, Corpo.ler(""));
        assertThrows(ApiException.class, () -> Corpo.ler("{nome"));
        assertThrows(ApiException.class, () -> Corpo.objecto(Json.createArrayBuilder().build()));
        ApiException falta = assertThrows(ApiException.class, () -> Corpo.inteiro(Json.createObjectBuilder().build(), "votoId"));
        assertEquals("campo_obrigatorio", falta.codigo());
    }

    /** Auditoria M5: texto que o Excel executaria como fórmula é neutralizado; números negativos não. */
    @Test
    void csvSemFormulas() {
        var linhas = Json.createArrayBuilder()
                .add(Json.createObjectBuilder().add("nome", "=HYPERLINK(\"http://x\")").add("valor", "-200.50").add("n", "-3"))
                .add(Json.createObjectBuilder().add("nome", "@SUM(A1)").add("valor", "10.00").add("n", "4"))
                .build();
        String csv = Csv.de(linhas);
        assertTrue(csv.contains("\"'=HYPERLINK(\"\"http://x\"\")\""), csv);
        assertTrue(csv.contains("'@SUM(A1)"), csv);
        assertTrue(csv.contains(";-200,50;-3"), csv);
    }
}
