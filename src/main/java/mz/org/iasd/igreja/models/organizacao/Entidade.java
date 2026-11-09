package mz.org.iasd.igreja.models.organizacao;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;
import mz.org.iasd.igreja.models.tipos.TipoEntidade;

/**
 * Níveis da organização: Conferência Geral, Divisão, União, Associação, Missão.
 * <p>
 * Tabela {@code organizacao.entidade} · rota {@code /v1/organizacao/entidades}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param paiEntidadeId Referência a organizacao.entidade
 * @param tipo coluna {@code ent_tipo} — obrigatório ao criar
 * @param nome coluna {@code ent_nome} — obrigatório ao criar
 * @param sigla coluna {@code ent_sigla}
 * @param dataCriacao coluna {@code ent_data_criacao}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "organizacao", nome = "entidade", prefixo = "ent", modulo = "organizacao", recurso = "entidades")
public record Entidade(
        @ColunaBd(value = "ent_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "ent_pai_ent_id", tipo = Tipo.INT)
        Integer paiEntidadeId,
        @ColunaBd(value = "ent_tipo", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        TipoEntidade tipo,
        @ColunaBd(value = "ent_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "ent_sigla", tipo = Tipo.TEXTO)
        String sigla,
        @ColunaBd(value = "ent_data_criacao", tipo = Tipo.DATA)
        LocalDate dataCriacao,
        @ColunaBd(value = "ent_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "ent_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "ent_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "ent_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "ent_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "ent_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
