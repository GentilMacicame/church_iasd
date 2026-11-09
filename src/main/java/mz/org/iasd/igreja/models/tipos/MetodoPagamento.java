package mz.org.iasd.igreja.models.tipos;

import mz.org.iasd.igreja.models.catalogo.TipoBd;

/**
 * Tipo {@code nucleo.metodo_pagamento_t} da base de dados.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador. NÃO EDITAR À MÃO.
 */
@TipoBd("metodo_pagamento_t")
public enum MetodoPagamento {
    MPESA,
    EMOLA,
    BANCO,
    NUMERARIO
}
