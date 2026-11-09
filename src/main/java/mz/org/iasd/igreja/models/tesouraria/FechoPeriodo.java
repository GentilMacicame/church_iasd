package mz.org.iasd.igreja.models.tesouraria;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Meses fechados: movimentos bloqueados (reabrir = preencher end_date).
 * <p>
 * Tabela {@code tesouraria.fecho_periodo} · rota {@code /v1/tesouraria/fechos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param ano coluna {@code fpe_ano} — obrigatório ao criar
 * @param mes coluna {@code fpe_mes} — obrigatório ao criar
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "fecho_periodo", prefixo = "fpe", modulo = "tesouraria", recurso = "fechos", colunaIgreja = "fpe_igr_id")
public record FechoPeriodo(
        @ColunaBd(value = "fpe_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "fpe_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "fpe_ano", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer ano,
        @ColunaBd(value = "fpe_mes", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer mes,
        @ColunaBd(value = "fpe_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "fpe_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "fpe_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "fpe_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "fpe_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "fpe_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
