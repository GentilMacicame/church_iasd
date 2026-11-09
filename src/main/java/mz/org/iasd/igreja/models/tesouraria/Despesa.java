package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoDespesa;

/**
 * Requisições de despesa (quem pede não aprova).
 * <p>
 * Tabela {@code tesouraria.despesa} · rota {@code /v1/tesouraria/despesas}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param departamentoIgrejaId Referência a organizacao.igreja_departamento
 * @param actividadeId Referência a actividades.actividade
 * @param categoriaId Referência a tesouraria.categoria — obrigatório ao criar
 * @param fundoId Referência a tesouraria.fundo — obrigatório ao criar
 * @param descricao coluna {@code des_descricao} — obrigatório ao criar
 * @param fornecedor coluna {@code des_fornecedor}
 * @param valorSolicitado coluna {@code des_valor_solicitado} — obrigatório ao criar, dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param valorAprovado coluna {@code des_valor_aprovado} — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param solicitadoPorUsuarioId Referência a nucleo.usuario — obrigatório ao criar
 * @param aprovadoPorUsuarioId Referência a nucleo.usuario (preenchido pela base de dados)
 * @param votoId Voto da junta, quando o valor o exige
 * @param aprovadoEm (preenchido pela base de dados)
 * @param motivoRejeicao coluna {@code des_motivo_rejeicao}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "despesa", prefixo = "des", modulo = "tesouraria", recurso = "despesas", colunaIgreja = "des_igr_id")
public record Despesa(
        @ColunaBd(value = "des_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "des_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "des_ide_id", tipo = Tipo.INT)
        Integer departamentoIgrejaId,
        @ColunaBd(value = "des_act_id", tipo = Tipo.INT)
        Integer actividadeId,
        @ColunaBd(value = "des_cat_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer categoriaId,
        @ColunaBd(value = "des_fun_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer fundoId,
        @ColunaBd(value = "des_descricao", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String descricao,
        @ColunaBd(value = "des_fornecedor", tipo = Tipo.TEXTO)
        String fornecedor,
        @ColunaBd(value = "des_valor_solicitado", tipo = Tipo.DINHEIRO, obrigatoria = true, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valorSolicitado,
        @ColunaBd(value = "des_valor_aprovado", tipo = Tipo.DINHEIRO)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valorAprovado,
        @ColunaBd(value = "des_solicitado_por_usu_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer solicitadoPorUsuarioId,
        @ColunaBd(value = "des_aprovado_por_usu_id", tipo = Tipo.INT, escrita = false)
        Integer aprovadoPorUsuarioId,
        @ColunaBd(value = "des_vot_id", tipo = Tipo.INT)
        Integer votoId,
        @ColunaBd(value = "des_aprovado_em", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime aprovadoEm,
        @ColunaBd(value = "des_motivo_rejeicao", tipo = Tipo.TEXTO)
        String motivoRejeicao,
        @ColunaBd(value = "des_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoDespesa estado,
        @ColunaBd(value = "des_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "des_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "des_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "des_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "des_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
