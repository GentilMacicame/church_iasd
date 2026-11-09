package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Pedido e resposta da API M-Pesa.
 * <p>
 * Tabela {@code tesouraria.pagamento_mpesa} · rota {@code /v1/tesouraria/mpesa}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param transacaoId Referência a tesouraria.transacao — obrigatório ao criar
 * @param direccao coluna {@code pmp_direccao}
 * @param msisdn coluna {@code pmp_msisdn} — obrigatório ao criar
 * @param valor coluna {@code pmp_valor} — obrigatório ao criar, dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param taxa coluna {@code pmp_taxa} — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param transactionReference coluna {@code pmp_transaction_reference} — obrigatório ao criar
 * @param thirdPartyReference coluna {@code pmp_third_party_reference} — obrigatório ao criar
 * @param serviceProviderCode coluna {@code pmp_service_provider_code} — obrigatório ao criar
 * @param responseCode coluna {@code pmp_response_code}
 * @param responseDesc coluna {@code pmp_response_desc}
 * @param mpesaTransactionId coluna {@code pmp_mpesa_transaction_id}
 * @param conversationId coluna {@code pmp_conversation_id}
 * @param pedidoEm coluna {@code pmp_pedido_em}
 * @param respondidoEm coluna {@code pmp_respondido_em}
 * @param ultimaConsultaEm coluna {@code pmp_ultima_consulta_em}
 * @param tentativasConsulta coluna {@code pmp_tentativas_consulta}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "pagamento_mpesa", prefixo = "pmp", modulo = "tesouraria", recurso = "mpesa")
public record PagamentoMpesa(
        @ColunaBd(value = "pmp_id", tipo = Tipo.BIGINT, escrita = false, naoNula = true)
        Long id,
        @ColunaBd(value = "pmp_tra_id", tipo = Tipo.BIGINT, obrigatoria = true, naoNula = true)
        Long transacaoId,
        @ColunaBd(value = "pmp_direccao", tipo = Tipo.TEXTO, naoNula = true)
        String direccao,
        @ColunaBd(value = "pmp_msisdn", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String msisdn,
        @ColunaBd(value = "pmp_valor", tipo = Tipo.DINHEIRO, obrigatoria = true, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valor,
        @ColunaBd(value = "pmp_taxa", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal taxa,
        @ColunaBd(value = "pmp_transaction_reference", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String transactionReference,
        @ColunaBd(value = "pmp_third_party_reference", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String thirdPartyReference,
        @ColunaBd(value = "pmp_service_provider_code", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String serviceProviderCode,
        @ColunaBd(value = "pmp_response_code", tipo = Tipo.TEXTO)
        String responseCode,
        @ColunaBd(value = "pmp_response_desc", tipo = Tipo.TEXTO)
        String responseDesc,
        @ColunaBd(value = "pmp_mpesa_transaction_id", tipo = Tipo.TEXTO)
        String mpesaTransactionId,
        @ColunaBd(value = "pmp_conversation_id", tipo = Tipo.TEXTO)
        String conversationId,
        @ColunaBd(value = "pmp_pedido_em", tipo = Tipo.DATA_HORA, naoNula = true)
        OffsetDateTime pedidoEm,
        @ColunaBd(value = "pmp_respondido_em", tipo = Tipo.DATA_HORA)
        OffsetDateTime respondidoEm,
        @ColunaBd(value = "pmp_ultima_consulta_em", tipo = Tipo.DATA_HORA)
        OffsetDateTime ultimaConsultaEm,
        @ColunaBd(value = "pmp_tentativas_consulta", tipo = Tipo.INT, naoNula = true)
        Integer tentativasConsulta,
        @ColunaBd(value = "pmp_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "pmp_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "pmp_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "pmp_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "pmp_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "pmp_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
