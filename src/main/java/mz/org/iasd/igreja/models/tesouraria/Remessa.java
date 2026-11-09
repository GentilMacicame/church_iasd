package mz.org.iasd.igreja.models.tesouraria;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRemessa;

/**
 * Remessas mensais à Associação/Missão.
 * <p>
 * Tabela {@code tesouraria.remessa} · rota {@code /v1/tesouraria/remessas}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param entidadeId Referência a organizacao.entidade — obrigatório ao criar
 * @param ano coluna {@code rem_ano} — obrigatório ao criar
 * @param mes coluna {@code rem_mes} — obrigatório ao criar
 * @param transacaoId Referência a tesouraria.transacao
 * @param enviadaEm coluna {@code rem_enviada_em}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "remessa", prefixo = "rem", modulo = "tesouraria", recurso = "remessas", colunaIgreja = "rem_igr_id")
public record Remessa(
        @ColunaBd(value = "rem_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "rem_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "rem_ent_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer entidadeId,
        @ColunaBd(value = "rem_ano", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer ano,
        @ColunaBd(value = "rem_mes", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer mes,
        @ColunaBd(value = "rem_tra_id", tipo = Tipo.BIGINT)
        Long transacaoId,
        @ColunaBd(value = "rem_enviada_em", tipo = Tipo.DATA)
        LocalDate enviadaEm,
        @ColunaBd(value = "rem_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRemessa estado,
        @ColunaBd(value = "rem_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "rem_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "rem_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "rem_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "rem_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
