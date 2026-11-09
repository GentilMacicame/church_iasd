package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Totais pré-calculados por igreja, fundo, moeda e dia (mantido por triggers; não editar).
 * <p>
 * Tabela {@code tesouraria.saldo_diario_fundo} · rota {@code /v1/tesouraria/saldos-diarios-fundo}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param fundoId Referência a tesouraria.fundo — obrigatório ao criar
 * @param moeda coluna {@code sdf_moeda} — obrigatório ao criar
 * @param data coluna {@code sdf_data} — obrigatório ao criar
 * @param entradas Entradas que não são estornos — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param saidas Saídas que não são estornos — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param estornosEntradas Saídas que estornam entradas — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param estornosSaidas Entradas que estornam saídas — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "saldo_diario_fundo", prefixo = "sdf", modulo = "tesouraria", recurso = "saldos-diarios-fundo", soLeitura = true, colunaIgreja = "sdf_igr_id")
public record SaldoDiarioFundo(
        @ColunaBd(value = "sdf_id", tipo = Tipo.BIGINT, escrita = false, naoNula = true)
        Long id,
        @ColunaBd(value = "sdf_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "sdf_fun_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer fundoId,
        @ColunaBd(value = "sdf_moeda", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String moeda,
        @ColunaBd(value = "sdf_data", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "sdf_entradas", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal entradas,
        @ColunaBd(value = "sdf_saidas", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal saidas,
        @ColunaBd(value = "sdf_estornos_entradas", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal estornosEntradas,
        @ColunaBd(value = "sdf_estornos_saidas", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal estornosSaidas,
        @ColunaBd(value = "sdf_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "sdf_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "sdf_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "sdf_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "sdf_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "sdf_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
