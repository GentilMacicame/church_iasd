package mz.org.iasd.igreja.models.tipos;

import mz.org.iasd.igreja.models.catalogo.TipoBd;

/**
 * Tipo {@code nucleo.estado_transferencia_t} da base de dados.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador. NÃO EDITAR À MÃO.
 */
@TipoBd("estado_transferencia_t")
public enum EstadoTransferencia {
    PEDIDA,
    CARTA_EMITIDA,
    CONCLUIDA,
    RECUSADA,
    EXPIRADA
}
