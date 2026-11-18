package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Quota do reavivamento fixada para todos os adultos e/ou todas as crianças no ano (V51).
 * <p>
 * Tabela {@code tesouraria.quota_escalao_reavivamento} · rota {@code /v1/tesouraria/quotas-escalao-reavivamento}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param ano coluna {@code rqe_ano} — obrigatório ao criar
 * @param quotaAdulto Vazio = automático (reparte o resto do alvo) — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param quotaCrianca Vazio = automático (reparte o resto do alvo) — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "quota_escalao_reavivamento", prefixo = "rqe", modulo = "tesouraria", recurso = "quotas-escalao-reavivamento", colunaIgreja = "rqe_igr_id")
public record QuotaEscalaoReavivamento(
        @ColunaBd(value = "rqe_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "rqe_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "rqe_ano", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer ano,
        @ColunaBd(value = "rqe_quota_adulto", tipo = Tipo.DINHEIRO)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal quotaAdulto,
        @ColunaBd(value = "rqe_quota_crianca", tipo = Tipo.DINHEIRO)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal quotaCrianca,
        @ColunaBd(value = "rqe_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "rqe_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "rqe_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "rqe_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "rqe_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "rqe_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
