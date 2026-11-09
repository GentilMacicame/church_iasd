package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Saldo pré-calculado por conta e dia (mantido por triggers; não editar).
 * <p>
 * Tabela {@code tesouraria.saldo_diario_conta} · rota {@code /v1/tesouraria/saldos-diarios-conta}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param contaId Referência a tesouraria.conta_financeira — obrigatório ao criar
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param data coluna {@code sdc_data} — obrigatório ao criar
 * @param entradas coluna {@code sdc_entradas} — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param saidas coluna {@code sdc_saidas} — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "saldo_diario_conta", prefixo = "sdc", modulo = "tesouraria", recurso = "saldos-diarios-conta", soLeitura = true, colunaIgreja = "sdc_igr_id")
public record SaldoDiarioConta(
        @ColunaBd(value = "sdc_id", tipo = Tipo.BIGINT, escrita = false, naoNula = true)
        Long id,
        @ColunaBd(value = "sdc_cfi_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer contaId,
        @ColunaBd(value = "sdc_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "sdc_data", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "sdc_entradas", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal entradas,
        @ColunaBd(value = "sdc_saidas", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal saidas,
        @ColunaBd(value = "sdc_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "sdc_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "sdc_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "sdc_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "sdc_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "sdc_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
