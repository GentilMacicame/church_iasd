package mz.org.iasd.igreja.models.actividades;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Parte da programação do dia (ex.: Programação da Escola Sabatina, Transição, Culto Divino, JA) e o apresentador (V44).
 * <p>
 * Tabela {@code actividades.programa_parte} · rota {@code /v1/actividades/partes-programa}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param programaDiaId Referência a actividades.programa_dia — obrigatório ao criar
 * @param ordem coluna {@code ppa_ordem}
 * @param titulo Ex.: Programação do Culto Divino — obrigatório ao criar
 * @param rotulo Cabeçalho da coluna do apresentador (ex.: Apresentador, Transição)
 * @param apresentadorMembroId Apresentador (membro)
 * @param apresentadorFamiliaId Apresentador (família, ex.: Família Magaia)
 * @param apresentadorTexto Apresentador escrito (visitante, grupo)
 * @param escala Função da escala que preenche o apresentador (ex.: APRESENTADOR_CULTO, FAMILIA_ES)
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "actividades", nome = "programa_parte", prefixo = "ppa", modulo = "actividades", recurso = "partes-programa")
public record ProgramaParte(
        @ColunaBd(value = "ppa_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "ppa_pgd_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer programaDiaId,
        @ColunaBd(value = "ppa_ordem", tipo = Tipo.INT, naoNula = true)
        Integer ordem,
        @ColunaBd(value = "ppa_titulo", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String titulo,
        @ColunaBd(value = "ppa_rotulo", tipo = Tipo.TEXTO, naoNula = true)
        String rotulo,
        @ColunaBd(value = "ppa_apresentador_mem_id", tipo = Tipo.INT)
        Integer apresentadorMembroId,
        @ColunaBd(value = "ppa_apresentador_fam_id", tipo = Tipo.INT)
        Integer apresentadorFamiliaId,
        @ColunaBd(value = "ppa_apresentador_texto", tipo = Tipo.TEXTO)
        String apresentadorTexto,
        @ColunaBd(value = "ppa_escala", tipo = Tipo.TEXTO)
        String escala,
        @ColunaBd(value = "ppa_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "ppa_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "ppa_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "ppa_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "ppa_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "ppa_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
