package mz.org.iasd.igreja.models.secretaria;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;
import mz.org.iasd.igreja.models.tipos.TipoConsentimento;

/**
 * Consentimentos para tratamento de dados (menores: dado pelo encarregado).
 * <p>
 * Tabela {@code secretaria.consentimento} · rota {@code /v1/secretaria/consentimentos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param membroId Referência a secretaria.membro — obrigatório ao criar
 * @param tipo coluna {@code cns_tipo} — obrigatório ao criar
 * @param concedido coluna {@code cns_concedido} — obrigatório ao criar
 * @param data coluna {@code cns_data}
 * @param concedidoPorMembroId Referência a secretaria.membro
 * @param observacoes coluna {@code cns_observacoes}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "secretaria", nome = "consentimento", prefixo = "cns", modulo = "secretaria", recurso = "consentimentos")
public record Consentimento(
        @ColunaBd(value = "cns_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "cns_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "cns_tipo", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        TipoConsentimento tipo,
        @ColunaBd(value = "cns_concedido", tipo = Tipo.BOOLEANO, obrigatoria = true, naoNula = true)
        Boolean concedido,
        @ColunaBd(value = "cns_data", tipo = Tipo.DATA, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "cns_concedido_por_mem_id", tipo = Tipo.INT)
        Integer concedidoPorMembroId,
        @ColunaBd(value = "cns_observacoes", tipo = Tipo.TEXTO)
        String observacoes,
        @ColunaBd(value = "cns_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "cns_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "cns_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "cns_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "cns_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "cns_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
