package mz.org.iasd.igreja.models.tipos;

import mz.org.iasd.igreja.models.catalogo.TipoBd;

/**
 * Tipo {@code nucleo.processo_aprovacao_t} da base de dados.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador. NÃO EDITAR À MÃO.
 */
@TipoBd("processo_aprovacao_t")
public enum ProcessoAprovacao {
    DESPESA,
    SAIDA,
    CONTAGEM,
    ORCAMENTO,
    ADMISSAO_MEMBRO,
    REMOCAO_MEMBRO
}
