package mz.org.iasd.igreja.models.nucleo;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoAprovacao;
import mz.org.iasd.igreja.models.tipos.ProcessoAprovacao;

/**
 * Processos de aprovação em curso e concluídos: o objecto (despesa, saída, contagem, orçamento ou membro), o fluxo e a etapa em que está (V54).
 * <p>
 * Tabela {@code nucleo.aprovacao} · rota {@code /v1/nucleo/aprovacoes}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param fluxoAprovacaoId Referência a nucleo.fluxo_aprovacao — obrigatório ao criar
 * @param processo coluna {@code apv_processo} — obrigatório ao criar
 * @param assunto coluna {@code apv_assunto} — obrigatório ao criar
 * @param valor coluna {@code apv_valor} — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param despesaId Referência a tesouraria.despesa
 * @param transacaoId Referência a tesouraria.transacao
 * @param contagemId Referência a tesouraria.contagem_numerario
 * @param orcamentoId Referência a tesouraria.orcamento
 * @param membroId Membro a admitir ou remover
 * @param pedidoPorUsuarioId Quem pediu (não decide as etapas com outra_pessoa)
 * @param etapa Ordem da etapa actual (a próxima a decidir)
 * @param concluidoEm coluna {@code apv_concluido_em}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "nucleo", nome = "aprovacao", prefixo = "apv", modulo = "nucleo", recurso = "aprovacoes", soLeitura = true)
public record Aprovacao(
        @ColunaBd(value = "apv_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "apv_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "apv_fap_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer fluxoAprovacaoId,
        @ColunaBd(value = "apv_processo", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        ProcessoAprovacao processo,
        @ColunaBd(value = "apv_assunto", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String assunto,
        @ColunaBd(value = "apv_valor", tipo = Tipo.DINHEIRO)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valor,
        @ColunaBd(value = "apv_des_id", tipo = Tipo.INT)
        Integer despesaId,
        @ColunaBd(value = "apv_tra_id", tipo = Tipo.BIGINT)
        Long transacaoId,
        @ColunaBd(value = "apv_cnu_id", tipo = Tipo.INT)
        Integer contagemId,
        @ColunaBd(value = "apv_orc_id", tipo = Tipo.INT)
        Integer orcamentoId,
        @ColunaBd(value = "apv_mem_id", tipo = Tipo.INT)
        Integer membroId,
        @ColunaBd(value = "apv_pedido_por_usu_id", tipo = Tipo.INT)
        Integer pedidoPorUsuarioId,
        @ColunaBd(value = "apv_etapa", tipo = Tipo.INT, naoNula = true)
        Integer etapa,
        @ColunaBd(value = "apv_concluido_em", tipo = Tipo.DATA_HORA)
        OffsetDateTime concluidoEm,
        @ColunaBd(value = "apv_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoAprovacao estado,
        @ColunaBd(value = "apv_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "apv_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "apv_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "apv_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "apv_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
