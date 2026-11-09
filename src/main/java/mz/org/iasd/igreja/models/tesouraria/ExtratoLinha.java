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
 * Linhas do extracto bancário/M-Pesa para reconciliação.
 * <p>
 * Tabela {@code tesouraria.extrato_linha} · rota {@code /v1/tesouraria/extractos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param contaId Referência a tesouraria.conta_financeira — obrigatório ao criar
 * @param data coluna {@code ext_data} — obrigatório ao criar
 * @param descricao coluna {@code ext_descricao}
 * @param referencia coluna {@code ext_referencia}
 * @param valor coluna {@code ext_valor} — obrigatório ao criar, dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param transacaoId Referência a tesouraria.transacao
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "extrato_linha", prefixo = "ext", modulo = "tesouraria", recurso = "extractos")
public record ExtratoLinha(
        @ColunaBd(value = "ext_id", tipo = Tipo.BIGINT, escrita = false, naoNula = true)
        Long id,
        @ColunaBd(value = "ext_cfi_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer contaId,
        @ColunaBd(value = "ext_data", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "ext_descricao", tipo = Tipo.TEXTO)
        String descricao,
        @ColunaBd(value = "ext_referencia", tipo = Tipo.TEXTO)
        String referencia,
        @ColunaBd(value = "ext_valor", tipo = Tipo.DINHEIRO, obrigatoria = true, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valor,
        @ColunaBd(value = "ext_tra_id", tipo = Tipo.BIGINT)
        Long transacaoId,
        @ColunaBd(value = "ext_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "ext_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "ext_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "ext_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "ext_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "ext_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
