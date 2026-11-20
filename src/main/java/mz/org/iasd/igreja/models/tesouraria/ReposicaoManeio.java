package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Reposição mensal do fundo de maneio: repõe-se só o gasto (o valor definido menos o saldo), aprovada pelo Conselho da Igreja; depois de aprovada, uma transferência repõe o dinheiro (V56).
 * <p>
 * Tabela {@code tesouraria.reposicao_maneio} · rota {@code /v1/tesouraria/reposicoes-maneio}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param contaId A conta do fundo de maneio — obrigatório ao criar
 * @param ano coluna {@code rpm_ano} — obrigatório ao criar
 * @param mes coluna {@code rpm_mes} — obrigatório ao criar
 * @param valorFundo O valor definido do fundo, quando se pediu (preenchido pela base de dados) — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param saldo Saldo do fundo quando se pediu (preenchido pela base de dados) — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param gasto O que se gastou: valor do fundo menos o saldo; é o máximo a repor (preenchido pela base de dados) — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param valor Valor a repor (até ao gasto) — obrigatório ao criar, dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param observacoes coluna {@code rpm_observacoes}
 * @param transacaoId Transferência que repôs o dinheiro (tesouraria.fn_repor_maneio)
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "reposicao_maneio", prefixo = "rpm", modulo = "tesouraria", recurso = "reposicoes-maneio", colunaIgreja = "rpm_igr_id")
public record ReposicaoManeio(
        @ColunaBd(value = "rpm_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "rpm_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "rpm_cfi_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer contaId,
        @ColunaBd(value = "rpm_ano", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer ano,
        @ColunaBd(value = "rpm_mes", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer mes,
        @ColunaBd(value = "rpm_valor_fundo", tipo = Tipo.DINHEIRO)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valorFundo,
        @ColunaBd(value = "rpm_saldo", tipo = Tipo.DINHEIRO)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal saldo,
        @ColunaBd(value = "rpm_gasto", tipo = Tipo.DINHEIRO)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal gasto,
        @ColunaBd(value = "rpm_valor", tipo = Tipo.DINHEIRO, obrigatoria = true, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valor,
        @ColunaBd(value = "rpm_observacoes", tipo = Tipo.TEXTO)
        String observacoes,
        @ColunaBd(value = "rpm_tra_id", tipo = Tipo.BIGINT)
        Long transacaoId,
        @ColunaBd(value = "rpm_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "rpm_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "rpm_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "rpm_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "rpm_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "rpm_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
