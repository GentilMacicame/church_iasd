package mz.org.iasd.igreja.models.tipos;

import mz.org.iasd.igreja.models.catalogo.TipoBd;

/**
 * Tipo {@code nucleo.tipo_movimento_t} da base de dados.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador. NÃO EDITAR À MÃO.
 */
@TipoBd("tipo_movimento_t")
public enum TipoMovimento {
    BAPTISMO,
    REBAPTISMO,
    PROFISSAO_FE,
    TRANSFERENCIA_ENTRADA,
    TRANSFERENCIA_SAIDA,
    FALECIMENTO,
    REMOCAO_DISCIPLINA,
    REMOCAO_PEDIDO,
    DESAPARECIDO
}
