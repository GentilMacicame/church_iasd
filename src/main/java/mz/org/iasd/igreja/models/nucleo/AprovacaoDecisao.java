package mz.org.iasd.igreja.models.nucleo;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Decisões de cada etapa de um processo de aprovação: quem decidiu, quando, com que voto (V54).
 * <p>
 * Tabela {@code nucleo.aprovacao_decisao} · rota {@code /v1/nucleo/decisoes-aprovacao}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param aprovacaoId Referência a nucleo.aprovacao — obrigatório ao criar
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param fluxoEtapaId Referência a nucleo.fluxo_etapa — obrigatório ao criar
 * @param etapa coluna {@code apd_etapa} — obrigatório ao criar
 * @param aprovado coluna {@code apd_aprovado} — obrigatório ao criar
 * @param usuarioId Quem decidiu ou registou a decisão do órgão — obrigatório ao criar
 * @param votoId Voto do órgão (etapas ORGAO)
 * @param motivo coluna {@code apd_motivo}
 * @param valor Valor aprovado, quando a etapa o reduz — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "nucleo", nome = "aprovacao_decisao", prefixo = "apd", modulo = "nucleo", recurso = "decisoes-aprovacao", soLeitura = true)
public record AprovacaoDecisao(
        @ColunaBd(value = "apd_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "apd_apv_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer aprovacaoId,
        @ColunaBd(value = "apd_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "apd_fae_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer fluxoEtapaId,
        @ColunaBd(value = "apd_etapa", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer etapa,
        @ColunaBd(value = "apd_aprovado", tipo = Tipo.BOOLEANO, obrigatoria = true, naoNula = true)
        Boolean aprovado,
        @ColunaBd(value = "apd_usu_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer usuarioId,
        @ColunaBd(value = "apd_vot_id", tipo = Tipo.INT)
        Integer votoId,
        @ColunaBd(value = "apd_motivo", tipo = Tipo.TEXTO)
        String motivo,
        @ColunaBd(value = "apd_valor", tipo = Tipo.DINHEIRO)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valor,
        @ColunaBd(value = "apd_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "apd_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "apd_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "apd_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "apd_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "apd_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
