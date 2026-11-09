package mz.org.iasd.igreja.models.tesouraria;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;
import mz.org.iasd.igreja.models.tipos.TipoCategoria;

/**
 * Plano de contas: categorias de receita e despesa.
 * <p>
 * Tabela {@code tesouraria.categoria} · rota {@code /v1/tesouraria/categorias}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param paiCategoriaId Referência a tesouraria.categoria
 * @param codigo coluna {@code cat_codigo} — obrigatório ao criar
 * @param nome coluna {@code cat_nome} — obrigatório ao criar
 * @param tipo coluna {@code cat_tipo} — obrigatório ao criar
 * @param eRemessa Categoria usada para enviar fundos à Associação
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "categoria", prefixo = "cat", modulo = "tesouraria", recurso = "categorias")
public record Categoria(
        @ColunaBd(value = "cat_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "cat_pai_cat_id", tipo = Tipo.INT)
        Integer paiCategoriaId,
        @ColunaBd(value = "cat_codigo", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String codigo,
        @ColunaBd(value = "cat_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "cat_tipo", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        TipoCategoria tipo,
        @ColunaBd(value = "cat_e_remessa", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean eRemessa,
        @ColunaBd(value = "cat_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "cat_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "cat_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "cat_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "cat_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "cat_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
