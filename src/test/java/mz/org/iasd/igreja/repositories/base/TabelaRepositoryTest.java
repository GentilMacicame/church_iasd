package mz.org.iasd.igreja.repositories.base;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

import jakarta.json.Json;
import jakarta.json.JsonValue;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Coluna;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.secretaria.Membro;
import mz.org.iasd.igreja.models.tesouraria.Transacao;

/** Operações-padrão: conversão JSON ⇄ parâmetros SQL e cursor da paginação. */
class TabelaRepositoryTest {

    @Test
    void conversaoDeEntrada() {
        Coluna dinheiro = new Coluna("tra_valor_total", "valorTotal", Tipo.DINHEIRO, null, true, true, true);
        assertEquals("650.00", Conversao.paraParametro(dinheiro, Json.createValue("650.00")));
        ApiException e = assertThrows(ApiException.class, () -> Conversao.paraParametro(dinheiro, Json.createValue(650)));
        assertEquals("valorTotal", e.campo());

        Coluna tipo = new Coluna("tra_tipo", "tipo", Tipo.ENUM, "tipo_transacao_t", true, true, true);
        assertEquals("SAIDA", Conversao.paraParametro(tipo, Json.createValue("SAIDA")));
        assertThrows(ApiException.class, () -> Conversao.paraParametro(tipo, Json.createValue("OUTRO")));

        Coluna data = new Coluna("mem_data_nascimento", "dataNascimento", Tipo.DATA, null, true, false, false);
        assertThrows(ApiException.class, () -> Conversao.paraParametro(data, Json.createValue("09/11/2026")));
        assertEquals("2026-11-09", Conversao.paraParametro(data, Json.createValue("2026-11-09")));

        Coluna id = new Coluna("mem_igr_id", "igrejaId", Tipo.INT, null, true, true, true);
        assertThrows(ApiException.class, () -> Conversao.paraParametro(id, Json.createValue("1")));
        assertNull(Conversao.paraParametro(id, JsonValue.NULL));
    }

    @Test
    void cursorComOrdenacao() {
        var ordem = TabelaRepository.Ordem.de(Catalogo.de(Transacao.class), "-dataHora");
        var cursor = new TabelaRepository.Cursor(ordem.campo(), "2026-11-09 10:00:00+02", "15");
        var lido = TabelaRepository.Cursor.de(cursor.codificar(), ordem);
        assertEquals("15", lido.id());
        assertEquals("2026-11-09 10:00:00+02", lido.valor());
        var outraOrdem = TabelaRepository.Ordem.de(Catalogo.de(Transacao.class), null);
        assertThrows(ApiException.class, () -> TabelaRepository.Cursor.de(cursor.codificar(), outraOrdem));
        assertThrows(ApiException.class, () -> TabelaRepository.Ordem.de(Catalogo.de(Membro.class), "dataNascimento"));
    }
}
