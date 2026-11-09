package mz.org.iasd.igreja.models.tesouraria;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Recibos numerados por igreja e ano.
 * <p>
 * Tabela {@code tesouraria.recibo} · rota {@code /v1/tesouraria/recibos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param transacaoId Referência a tesouraria.transacao — obrigatório ao criar
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param ano coluna {@code rec_ano} — obrigatório ao criar
 * @param numero coluna {@code rec_numero} — obrigatório ao criar
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "recibo", prefixo = "rec", modulo = "tesouraria", recurso = "recibos", colunaIgreja = "rec_igr_id")
public record Recibo(
        @ColunaBd(value = "rec_id", tipo = Tipo.BIGINT, escrita = false, naoNula = true)
        Long id,
        @ColunaBd(value = "rec_tra_id", tipo = Tipo.BIGINT, obrigatoria = true, naoNula = true)
        Long transacaoId,
        @ColunaBd(value = "rec_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "rec_ano", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer ano,
        @ColunaBd(value = "rec_numero", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer numero,
        @ColunaBd(value = "rec_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "rec_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "rec_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "rec_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "rec_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "rec_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
