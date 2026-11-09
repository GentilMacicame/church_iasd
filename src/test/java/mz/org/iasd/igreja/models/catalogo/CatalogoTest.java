package mz.org.iasd.igreja.models.catalogo;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import org.junit.jupiter.api.Test;

import mz.org.iasd.igreja.models.secretaria.Membro;
import mz.org.iasd.igreja.models.tesouraria.Transacao;

/** Catálogo lido dos models: filtros da listagem iguais aos do contrato. */
class CatalogoTest {

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
}
