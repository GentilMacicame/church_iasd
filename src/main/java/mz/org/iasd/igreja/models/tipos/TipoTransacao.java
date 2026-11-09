package mz.org.iasd.igreja.models.tipos;

import mz.org.iasd.igreja.models.catalogo.TipoBd;

/**
 * Tipo {@code nucleo.tipo_transacao_t} da base de dados.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador. NÃO EDITAR À MÃO.
 */
@TipoBd("tipo_transacao_t")
public enum TipoTransacao {
    ENTRADA,
    SAIDA,
    TRANSFERENCIA
}
