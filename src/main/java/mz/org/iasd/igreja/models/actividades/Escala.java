package mz.org.iasd.igreja.models.actividades;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoEscala;
import mz.org.iasd.igreja.models.tipos.FuncaoEscala;

/**
 * Escalas de serviço (pregador, diáconos, recepção, ...).
 * <p>
 * Tabela {@code actividades.escala} · rota {@code /v1/actividades/escalas}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param data coluna {@code esc_data} — obrigatório ao criar
 * @param funcao coluna {@code esc_funcao} — obrigatório ao criar
 * @param membroId Referência a secretaria.membro — obrigatório ao criar
 * @param actividadeId Referência a actividades.actividade
 * @param substitutoMembroId Referência a secretaria.membro
 * @param observacoes coluna {@code esc_observacoes}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "actividades", nome = "escala", prefixo = "esc", modulo = "actividades", recurso = "escalas", colunaIgreja = "esc_igr_id")
public record Escala(
        @ColunaBd(value = "esc_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "esc_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "esc_data", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "esc_funcao", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        FuncaoEscala funcao,
        @ColunaBd(value = "esc_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "esc_act_id", tipo = Tipo.INT)
        Integer actividadeId,
        @ColunaBd(value = "esc_substituto_mem_id", tipo = Tipo.INT)
        Integer substitutoMembroId,
        @ColunaBd(value = "esc_observacoes", tipo = Tipo.TEXTO)
        String observacoes,
        @ColunaBd(value = "esc_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoEscala estado,
        @ColunaBd(value = "esc_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "esc_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "esc_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "esc_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "esc_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
