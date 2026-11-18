package mz.org.iasd.igreja.models.actividades;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Item da programação do dia: horas, actividade e responsável (membro, família, departamento ou texto) (V44).
 * <p>
 * Tabela {@code actividades.programa_item} · rota {@code /v1/actividades/itens-programa}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param programaDiaId Referência a actividades.programa_dia — obrigatório ao criar
 * @param programaParteId Referência a actividades.programa_parte — obrigatório ao criar
 * @param ordem coluna {@code pit_ordem}
 * @param horaInicio Hora (hh:mm)
 * @param horaFim Hora (hh:mm)
 * @param actividade Ex.: Hino inicial (H.A 509) — obrigatório ao criar
 * @param responsavelMembroId Responsável (membro)
 * @param responsavelFamiliaId Responsável (família)
 * @param responsavelDepartamentoIgrejaId Responsável (departamento, ex.: Mulher Adventista)
 * @param responsavelTexto Responsável escrito (ex.: Todos, Diáconos, Monitores, um visitante)
 * @param escala Função da escala que preenche o responsável (ex.: PREGADOR, TRADUTOR, FAMILIA_ES)
 * @param destaque Linha em destaque na folha (ex.: Sermão principal)
 * @param escalaColunaId Coluna da escala da Escola Sabatina ou da JA que preenche o responsável (V45)
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "actividades", nome = "programa_item", prefixo = "pit", modulo = "actividades", recurso = "itens-programa")
public record ProgramaItem(
        @ColunaBd(value = "pit_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "pit_pgd_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer programaDiaId,
        @ColunaBd(value = "pit_ppa_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer programaParteId,
        @ColunaBd(value = "pit_ordem", tipo = Tipo.INT, naoNula = true)
        Integer ordem,
        @ColunaBd(value = "pit_hora_inicio", tipo = Tipo.TEXTO)
        String horaInicio,
        @ColunaBd(value = "pit_hora_fim", tipo = Tipo.TEXTO)
        String horaFim,
        @ColunaBd(value = "pit_actividade", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String actividade,
        @ColunaBd(value = "pit_responsavel_mem_id", tipo = Tipo.INT)
        Integer responsavelMembroId,
        @ColunaBd(value = "pit_responsavel_fam_id", tipo = Tipo.INT)
        Integer responsavelFamiliaId,
        @ColunaBd(value = "pit_responsavel_ide_id", tipo = Tipo.INT)
        Integer responsavelDepartamentoIgrejaId,
        @ColunaBd(value = "pit_responsavel_texto", tipo = Tipo.TEXTO)
        String responsavelTexto,
        @ColunaBd(value = "pit_escala", tipo = Tipo.TEXTO)
        String escala,
        @ColunaBd(value = "pit_destaque", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean destaque,
        @ColunaBd(value = "pit_ecn_id", tipo = Tipo.INT)
        Integer escalaColunaId,
        @ColunaBd(value = "pit_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "pit_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "pit_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "pit_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "pit_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "pit_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
