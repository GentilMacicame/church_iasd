package mz.org.iasd.igreja.crud;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

import jakarta.json.Json;
import jakarta.json.JsonValue;

import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.models.tesouraria.Transacao;
import mz.org.iasd.igreja.models.secretaria.Membro;

/** Motor das operações-padrão: conversão JSON ⇄ SQL, filtros e cursor. */
class CrudTest {

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
    void filtrosDaListagemComoNoContrato() {
        Tabela membro = Catalogo.de(Membro.class);
        assertEquals("mem_igr_id", membro.filtrosIgualdade().get("igrejaId").coluna());
        assertEquals("mem_fam_id", membro.filtrosIgualdade().get("familiaId").coluna());
        assertEquals("mem_estado", membro.filtrosIgualdade().get("estado").coluna());
        assertEquals("mem_sexo", membro.filtrosIgualdade().get("sexo").coluna());
        assertNull(membro.filtrosIgualdade().get("criadoPor"));
        assertEquals("tra_data_hora", Catalogo.de(Transacao.class).colunaData().orElseThrow().coluna());
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

    @Test
    void corpoDoPedido() {
        assertEquals(JsonValue.NULL, Corpo.ler(""));
        assertThrows(ApiException.class, () -> Corpo.ler("{nome"));
        assertThrows(ApiException.class, () -> Corpo.objecto(Json.createArrayBuilder().build()));
        ApiException falta = assertThrows(ApiException.class, () -> Corpo.inteiro(Json.createObjectBuilder().build(), "votoId"));
        assertEquals("campo_obrigatorio", falta.codigo());
    }
}
