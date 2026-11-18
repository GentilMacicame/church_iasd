package mz.org.iasd.igreja.models.actividades;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Coluna da escala da Escola Sabatina ou da JA, como cada igreja a organiza (ex.: Apresentador, Carta missionária) (V45).
 * <p>
 * Tabela {@code actividades.escala_coluna} · rota {@code /v1/actividades/colunas-escala}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param tipo ESCOLA_SABATINA ou JA — obrigatório ao criar
 * @param ordem coluna {@code ecn_ordem}
 * @param nome Ex.: Apresentador, Oração, Carta missionária — obrigatório ao criar
 * @param responsavel Quem se escala nesta coluna: MEMBRO ou FAMILIA
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "actividades", nome = "escala_coluna", prefixo = "ecn", modulo = "actividades", recurso = "colunas-escala", colunaIgreja = "ecn_igr_id")
public record EscalaColuna(
        @ColunaBd(value = "ecn_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "ecn_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "ecn_tipo", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String tipo,
        @ColunaBd(value = "ecn_ordem", tipo = Tipo.INT, naoNula = true)
        Integer ordem,
        @ColunaBd(value = "ecn_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "ecn_responsavel", tipo = Tipo.TEXTO, naoNula = true)
        String responsavel,
        @ColunaBd(value = "ecn_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "ecn_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "ecn_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "ecn_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "ecn_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "ecn_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
