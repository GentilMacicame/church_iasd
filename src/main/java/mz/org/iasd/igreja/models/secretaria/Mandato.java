package mz.org.iasd.igreja.models.secretaria;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Mandatos da igreja: o período (com a duração) em que servem os oficiais eleitos (V31).
 * <p>
 * Tabela {@code secretaria.mandato} · rota {@code /v1/secretaria/mandatos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param nome Ex.: Mandato 2026–2027 — obrigatório ao criar
 * @param dataInicio coluna {@code mdt_data_inicio} — obrigatório ao criar
 * @param dataFim Último dia do mandato — obrigatório ao criar
 * @param votoId Voto da igreja que elegeu os oficiais deste mandato
 * @param observacoes coluna {@code mdt_observacoes}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "secretaria", nome = "mandato", prefixo = "mdt", modulo = "secretaria", recurso = "mandatos", colunaIgreja = "mdt_igr_id")
public record Mandato(
        @ColunaBd(value = "mdt_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "mdt_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "mdt_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "mdt_data_inicio", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate dataInicio,
        @ColunaBd(value = "mdt_data_fim", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate dataFim,
        @ColunaBd(value = "mdt_vot_id", tipo = Tipo.INT)
        Integer votoId,
        @ColunaBd(value = "mdt_observacoes", tipo = Tipo.TEXTO)
        String observacoes,
        @ColunaBd(value = "mdt_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "mdt_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "mdt_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "mdt_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "mdt_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "mdt_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
