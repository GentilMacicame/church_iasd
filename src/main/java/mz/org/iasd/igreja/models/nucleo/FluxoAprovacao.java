package mz.org.iasd.igreja.models.nucleo;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;
import mz.org.iasd.igreja.models.tipos.ProcessoAprovacao;

/**
 * Fluxos de aprovação: que etapas segue cada natureza de processo (despesa, saída, contagem, orçamento, admissão e remoção de membros), a partir de que valor (V54).
 * <p>
 * Tabela {@code nucleo.fluxo_aprovacao} · rota {@code /v1/nucleo/fluxos-aprovacao}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Igreja a que o fluxo se aplica; vazio = modelo da Associação/Missão para todas as igrejas sem fluxo próprio
 * @param processo coluna {@code fap_processo} — obrigatório ao criar
 * @param nome coluna {@code fap_nome} — obrigatório ao criar
 * @param valorMinimo O fluxo aplica-se a partir deste valor (o de maior valor mínimo que não passe o valor do processo) — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param descricao coluna {@code fap_descricao}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "nucleo", nome = "fluxo_aprovacao", prefixo = "fap", modulo = "nucleo", recurso = "fluxos-aprovacao")
public record FluxoAprovacao(
        @ColunaBd(value = "fap_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "fap_igr_id", tipo = Tipo.INT)
        Integer igrejaId,
        @ColunaBd(value = "fap_processo", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        ProcessoAprovacao processo,
        @ColunaBd(value = "fap_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "fap_valor_minimo", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valorMinimo,
        @ColunaBd(value = "fap_descricao", tipo = Tipo.TEXTO)
        String descricao,
        @ColunaBd(value = "fap_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "fap_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "fap_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "fap_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "fap_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "fap_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
