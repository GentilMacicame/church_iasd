package mz.org.iasd.igreja.models.actividades;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Programação do dia (ex.: sábado): as partes e os itens com horas e responsáveis, para imprimir (V44).
 * <p>
 * Tabela {@code actividades.programa_dia} · rota {@code /v1/actividades/programas-dia}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param data coluna {@code pgd_data} — obrigatório ao criar
 * @param titulo Título da folha; por defeito, a data por extenso
 * @param observacoes Nota no fim da folha (ex.: passível de ajustes e simplificação)
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "actividades", nome = "programa_dia", prefixo = "pgd", modulo = "actividades", recurso = "programas-dia", colunaIgreja = "pgd_igr_id")
public record ProgramaDia(
        @ColunaBd(value = "pgd_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "pgd_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "pgd_data", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "pgd_titulo", tipo = Tipo.TEXTO)
        String titulo,
        @ColunaBd(value = "pgd_observacoes", tipo = Tipo.TEXTO)
        String observacoes,
        @ColunaBd(value = "pgd_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "pgd_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "pgd_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "pgd_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "pgd_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "pgd_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
