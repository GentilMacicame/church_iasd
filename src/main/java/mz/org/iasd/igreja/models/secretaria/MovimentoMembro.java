package mz.org.iasd.igreja.models.secretaria;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;
import mz.org.iasd.igreja.models.tipos.TipoMovimento;

/**
 * Livro de membros: cada entrada e saída, com o voto que a autoriza.
 * <p>
 * Tabela {@code secretaria.movimento_membro} · rota {@code /v1/secretaria/movimentos-membro}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param membroId Referência a secretaria.membro — obrigatório ao criar
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param tipo coluna {@code mmb_tipo} — obrigatório ao criar
 * @param data coluna {@code mmb_data} — obrigatório ao criar
 * @param votoId Obrigatório excepto falecimento
 * @param transferenciaId Referência a secretaria.transferencia_membro
 * @param observacoes coluna {@code mmb_observacoes}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "secretaria", nome = "movimento_membro", prefixo = "mmb", modulo = "secretaria", recurso = "movimentos-membro", colunaIgreja = "mmb_igr_id")
public record MovimentoMembro(
        @ColunaBd(value = "mmb_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "mmb_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "mmb_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "mmb_tipo", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        TipoMovimento tipo,
        @ColunaBd(value = "mmb_data", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "mmb_vot_id", tipo = Tipo.INT)
        Integer votoId,
        @ColunaBd(value = "mmb_tme_id", tipo = Tipo.INT)
        Integer transferenciaId,
        @ColunaBd(value = "mmb_observacoes", tipo = Tipo.TEXTO)
        String observacoes,
        @ColunaBd(value = "mmb_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "mmb_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "mmb_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "mmb_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "mmb_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "mmb_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
