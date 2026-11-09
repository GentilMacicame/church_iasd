package mz.org.iasd.igreja.models.organizacao;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Distritos pastorais de uma Associação/Missão.
 * <p>
 * Tabela {@code organizacao.distrito} · rota {@code /v1/organizacao/distritos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param entidadeId Referência a organizacao.entidade — obrigatório ao criar
 * @param nome coluna {@code dst_nome} — obrigatório ao criar
 * @param pastorUsuarioId Pastor distrital
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "organizacao", nome = "distrito", prefixo = "dst", modulo = "organizacao", recurso = "distritos")
public record Distrito(
        @ColunaBd(value = "dst_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "dst_ent_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer entidadeId,
        @ColunaBd(value = "dst_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "dst_pastor_usu_id", tipo = Tipo.INT)
        Integer pastorUsuarioId,
        @ColunaBd(value = "dst_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "dst_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "dst_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "dst_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "dst_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "dst_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
