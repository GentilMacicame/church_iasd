package mz.org.iasd.igreja.models.tipos;

import mz.org.iasd.igreja.crud.TipoBd;

/**
 * Tipo {@code nucleo.estado_reuniao_t} da base de dados.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador. NÃO EDITAR À MÃO.
 */
@TipoBd("estado_reuniao_t")
public enum EstadoReuniao {
    CONVOCADA,
    REALIZADA,
    ACTA_APROVADA,
    CANCELADA
}
