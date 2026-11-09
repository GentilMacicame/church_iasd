package mz.org.iasd.igreja.models.tipos;

import mz.org.iasd.igreja.crud.TipoBd;

/**
 * Tipo {@code nucleo.tipo_reuniao_t} da base de dados.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador. NÃO EDITAR À MÃO.
 */
@TipoBd("tipo_reuniao_t")
public enum TipoReuniao {
    JUNTA_DIRECTIVA,
    REUNIAO_REGULAR,
    ASSEMBLEIA_ADMINISTRATIVA,
    COMISSAO_NOMEACOES,
    CONSELHO_ES
}
