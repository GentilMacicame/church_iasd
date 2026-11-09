package mz.org.iasd.igreja.infraestrutura.erros;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.SQLException;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.api.Test;

class TradutorErrosSqlTest {

    @ParameterizedTest
    @CsvSource({
            "42501, 403, sem_permissao",
            "P0001, 422, regra_negocio",
            "23514, 422, validacao",
            "23505, 409, duplicado",
            "23503, 422, referencia_invalida",
            "23502, 400, campo_obrigatorio",
            "40001, 503, tentar_novamente",
            "40P01, 503, tentar_novamente",
            "XX000, 500, erro_interno"
    })
    void tabelaDoContrato(String sqlstate, int http, String codigo) {
        TradutorErrosSql.Traducao t = TradutorErrosSql.traduzir(new SQLException("x", sqlstate));
        assertEquals(http, t.estadoHttp());
        assertEquals(codigo, t.codigo());
    }

    @Test
    void mensagemDaRegraPassaTalEQual() {
        TradutorErrosSql.Traducao t = TradutorErrosSql.traduzir(
                new SQLException("Só se aprova uma saída pendente", "P0001"));
        assertEquals("Só se aprova uma saída pendente", t.mensagem());
    }

    @Test
    void mensagensDePermissaoEmPortugues() {
        assertEquals("Sem permissão para gravar este registo nesta igreja",
                TradutorErrosSql.mensagemPermissao("new row violates row-level security policy for table \"familia\""));
        assertEquals("Sem permissão para esta operação",
                TradutorErrosSql.mensagemPermissao("permission denied for table membro"));
        assertEquals("Sem permissão: Aprovar uma saída de dinheiro",
                TradutorErrosSql.mensagemPermissao("Sem permissão: Aprovar uma saída de dinheiro"));
    }

    @Test
    void campoAPartirDaRestricao() {
        assertEquals("igrejaId", TradutorErrosSql.campoDaRestricao("fk_mem_igr_id"));
        assertEquals("email", TradutorErrosSql.campoDaRestricao("uq_usu_email"));
        assertEquals("membroId", TradutorErrosSql.campoDaRestricao("uq_usu_mem_id"));
        assertNull(TradutorErrosSql.campoDaRestricao("uq_vot_reu_id_numero"));   // várias colunas
        assertNull(TradutorErrosSql.campoDaRestricao("chk_tra_quem_regista_nao_aprova"));
        assertNull(TradutorErrosSql.campoDaRestricao(null));
    }

    @Test
    void encontraSqlNaCadeiaDeCausas() {
        SQLException sql = new SQLException("x", "40001");
        assertSame(sql, TradutorErrosSql.encontrar(new RuntimeException(new IllegalStateException(sql))));
        assertTrue(TradutorErrosSql.repetivel(sql));
        assertFalse(TradutorErrosSql.repetivel(new SQLException("x", "P0001")));
    }
}
