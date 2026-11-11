package mz.org.iasd.igreja.models.secretaria;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoPonto;

/**
 * Pontos da agenda de uma reunião: assunto, discussão, votação e deliberação.
 * <p>
 * Tabela {@code secretaria.reuniao_ponto} · rota {@code /v1/secretaria/pontos-agenda}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param reuniaoId Referência a secretaria.reuniao — obrigatório ao criar
 * @param ordem coluna {@code rpt_ordem}
 * @param assunto coluna {@code rpt_assunto} — obrigatório ao criar
 * @param detalhes coluna {@code rpt_detalhes}
 * @param discutido coluna {@code rpt_discutido}
 * @param votado coluna {@code rpt_votado}
 * @param aFavor coluna {@code rpt_a_favor}
 * @param contra coluna {@code rpt_contra}
 * @param abstencoes coluna {@code rpt_abstencoes}
 * @param votoId Voto formal da acta (admissões, transferências, ...) ligado a este ponto
 * @param deliberacao Decisão ou deliberação tomada
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "secretaria", nome = "reuniao_ponto", prefixo = "rpt", modulo = "secretaria", recurso = "pontos-agenda")
public record ReuniaoPonto(
        @ColunaBd(value = "rpt_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "rpt_reu_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer reuniaoId,
        @ColunaBd(value = "rpt_ordem", tipo = Tipo.INT, naoNula = true)
        Integer ordem,
        @ColunaBd(value = "rpt_assunto", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String assunto,
        @ColunaBd(value = "rpt_detalhes", tipo = Tipo.TEXTO)
        String detalhes,
        @ColunaBd(value = "rpt_discutido", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean discutido,
        @ColunaBd(value = "rpt_votado", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean votado,
        @ColunaBd(value = "rpt_a_favor", tipo = Tipo.INT)
        Integer aFavor,
        @ColunaBd(value = "rpt_contra", tipo = Tipo.INT)
        Integer contra,
        @ColunaBd(value = "rpt_abstencoes", tipo = Tipo.INT)
        Integer abstencoes,
        @ColunaBd(value = "rpt_vot_id", tipo = Tipo.INT)
        Integer votoId,
        @ColunaBd(value = "rpt_deliberacao", tipo = Tipo.TEXTO)
        String deliberacao,
        @ColunaBd(value = "rpt_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoPonto estado,
        @ColunaBd(value = "rpt_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "rpt_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "rpt_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "rpt_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "rpt_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
