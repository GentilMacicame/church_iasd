package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;
import mz.org.iasd.igreja.models.tipos.TipoFundo;

/**
 * Fundos: da Associação (dízimo, ofertas missionárias, 13º sábado) ou locais.
 * <p>
 * Tabela {@code tesouraria.fundo} · rota {@code /v1/tesouraria/fundos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId NULL = fundo geral
 * @param codigo coluna {@code fun_codigo} — obrigatório ao criar
 * @param nome coluna {@code fun_nome} — obrigatório ao criar
 * @param tipo coluna {@code fun_tipo} — obrigatório ao criar
 * @param restrito Fundo local que só pode ser gasto no seu fim
 * @param percentagemRemessa 100 = fundo da Associação, a igreja não o pode usar
 * @param destinoEntidadeId Referência a organizacao.entidade
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "fundo", prefixo = "fun", modulo = "tesouraria", recurso = "fundos")
public record Fundo(
        @ColunaBd(value = "fun_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "fun_igr_id", tipo = Tipo.INT)
        Integer igrejaId,
        @ColunaBd(value = "fun_codigo", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String codigo,
        @ColunaBd(value = "fun_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "fun_tipo", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        TipoFundo tipo,
        @ColunaBd(value = "fun_restrito", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean restrito,
        @ColunaBd(value = "fun_percentagem_remessa", tipo = Tipo.DECIMAL, naoNula = true)
        BigDecimal percentagemRemessa,
        @ColunaBd(value = "fun_destino_ent_id", tipo = Tipo.INT)
        Integer destinoEntidadeId,
        @ColunaBd(value = "fun_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "fun_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "fun_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "fun_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "fun_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "fun_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
