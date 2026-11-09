package mz.org.iasd.igreja.models.tesouraria;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Calendário de ofertas especiais definido pela Divisão/União/Associação.
 * <p>
 * Tabela {@code tesouraria.calendario_oferta} · rota {@code /v1/tesouraria/calendario-ofertas}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param entidadeId Referência a organizacao.entidade — obrigatório ao criar
 * @param data coluna {@code cof_data} — obrigatório ao criar
 * @param fundoId Referência a tesouraria.fundo — obrigatório ao criar
 * @param descricao coluna {@code cof_descricao} — obrigatório ao criar
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "calendario_oferta", prefixo = "cof", modulo = "tesouraria", recurso = "calendario-ofertas")
public record CalendarioOferta(
        @ColunaBd(value = "cof_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "cof_ent_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer entidadeId,
        @ColunaBd(value = "cof_data", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "cof_fun_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer fundoId,
        @ColunaBd(value = "cof_descricao", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String descricao,
        @ColunaBd(value = "cof_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "cof_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "cof_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "cof_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "cof_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "cof_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
