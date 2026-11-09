package mz.org.iasd.igreja.models.tesouraria;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoOrcamento;

/**
 * Orçamento anual da igreja local (aprovado pela igreja).
 * <p>
 * Tabela {@code tesouraria.orcamento} · rota {@code /v1/tesouraria/orcamentos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param departamentoIgrejaId Referência a organizacao.igreja_departamento
 * @param ano coluna {@code orc_ano} — obrigatório ao criar
 * @param votoId Voto da igreja que aprovou o orçamento
 * @param observacoes coluna {@code orc_observacoes}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "orcamento", prefixo = "orc", modulo = "tesouraria", recurso = "orcamentos", colunaIgreja = "orc_igr_id")
public record Orcamento(
        @ColunaBd(value = "orc_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "orc_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "orc_ide_id", tipo = Tipo.INT)
        Integer departamentoIgrejaId,
        @ColunaBd(value = "orc_ano", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer ano,
        @ColunaBd(value = "orc_vot_id", tipo = Tipo.INT)
        Integer votoId,
        @ColunaBd(value = "orc_observacoes", tipo = Tipo.TEXTO)
        String observacoes,
        @ColunaBd(value = "orc_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoOrcamento estado,
        @ColunaBd(value = "orc_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "orc_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "orc_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "orc_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "orc_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
