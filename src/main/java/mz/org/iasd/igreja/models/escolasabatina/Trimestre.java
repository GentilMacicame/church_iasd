package mz.org.iasd.igreja.models.escolasabatina;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Trimestres da lição.
 * <p>
 * Tabela {@code escola_sabatina.trimestre} · rota {@code /v1/escola-sabatina/trimestres}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param ano coluna {@code etr_ano} — obrigatório ao criar
 * @param numero coluna {@code etr_numero} — obrigatório ao criar
 * @param temaLicao coluna {@code etr_tema_licao}
 * @param dataInicio coluna {@code etr_data_inicio} — obrigatório ao criar
 * @param dataFim coluna {@code etr_data_fim} — obrigatório ao criar
 * @param numSabados coluna {@code etr_num_sabados} — obrigatório ao criar
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "escola_sabatina", nome = "trimestre", prefixo = "etr", modulo = "escola-sabatina", recurso = "trimestres")
public record Trimestre(
        @ColunaBd(value = "etr_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "etr_ano", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer ano,
        @ColunaBd(value = "etr_numero", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer numero,
        @ColunaBd(value = "etr_tema_licao", tipo = Tipo.TEXTO)
        String temaLicao,
        @ColunaBd(value = "etr_data_inicio", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate dataInicio,
        @ColunaBd(value = "etr_data_fim", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate dataFim,
        @ColunaBd(value = "etr_num_sabados", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer numSabados,
        @ColunaBd(value = "etr_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "etr_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "etr_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "etr_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "etr_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "etr_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
