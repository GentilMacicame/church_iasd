package mz.org.iasd.igreja.models.tipos;

import mz.org.iasd.igreja.models.catalogo.TipoBd;

/**
 * Tipo {@code nucleo.estado_ponto_t} da base de dados.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador. NÃO EDITAR À MÃO.
 */
@TipoBd("estado_ponto_t")
public enum EstadoPonto {
    PENDENTE,
    APROVADO,
    REJEITADO,
    ADIADO,
    INFORMATIVO
}
