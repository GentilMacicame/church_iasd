package mz.org.iasd.igreja.models.tipos;

import mz.org.iasd.igreja.models.catalogo.TipoBd;

/**
 * Tipo {@code nucleo.tipo_consentimento_t} da base de dados.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador. NÃO EDITAR À MÃO.
 */
@TipoBd("tipo_consentimento_t")
public enum TipoConsentimento {
    DADOS_PESSOAIS,
    FOTOGRAFIAS,
    CONTACTO_SMS,
    CONTACTO_WHATSAPP,
    CONTACTO_EMAIL
}
