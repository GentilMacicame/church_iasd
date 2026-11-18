package mz.org.iasd.igreja.models.escolasabatina;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Programas especiais da semana (semana de oração, da família, de evangelismo…), com alerta (V47).
 * <p>
 * Tabela {@code escola_sabatina.semana_especial} · rota {@code /v1/escola-sabatina/semanas-especiais}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param tipo ORACAO, FAMILIA, EVANGELISMO, JOVENS, MORDOMIA ou OUTRO — obrigatório ao criar
 * @param nome Ex.: Semana de Oração — obrigatório ao criar
 * @param dataInicio coluna {@code ese_data_inicio} — obrigatório ao criar
 * @param dataFim coluna {@code ese_data_fim} — obrigatório ao criar
 * @param observacoes coluna {@code ese_observacoes}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "escola_sabatina", nome = "semana_especial", prefixo = "ese", modulo = "escola-sabatina", recurso = "semanas-especiais", colunaIgreja = "ese_igr_id")
public record SemanaEspecial(
        @ColunaBd(value = "ese_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "ese_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "ese_tipo", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String tipo,
        @ColunaBd(value = "ese_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "ese_data_inicio", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate dataInicio,
        @ColunaBd(value = "ese_data_fim", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate dataFim,
        @ColunaBd(value = "ese_observacoes", tipo = Tipo.TEXTO)
        String observacoes,
        @ColunaBd(value = "ese_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "ese_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "ese_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "ese_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "ese_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "ese_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
