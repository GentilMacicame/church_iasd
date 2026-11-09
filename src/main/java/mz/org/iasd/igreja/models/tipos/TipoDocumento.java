package mz.org.iasd.igreja.models.tipos;

import mz.org.iasd.igreja.models.catalogo.TipoBd;

/**
 * Tipo {@code nucleo.tipo_documento_t} da base de dados.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador. NÃO EDITAR À MÃO.
 */
@TipoBd("tipo_documento_t")
public enum TipoDocumento {
    FACTURA,
    RECIBO,
    COMPROVATIVO,
    EXTRACTO,
    OUTRO
}
