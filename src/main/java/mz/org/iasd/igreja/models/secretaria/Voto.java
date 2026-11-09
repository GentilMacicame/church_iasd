package mz.org.iasd.igreja.models.secretaria;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.ResultadoVoto;
import mz.org.iasd.igreja.models.tipos.TipoVoto;

/**
 * Votos registados em acta (admissões, transferências, remoções, eleições, finanças).
 * <p>
 * Tabela {@code secretaria.voto} · rota {@code /v1/secretaria/votos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param reuniaoId Referência a secretaria.reuniao — obrigatório ao criar
 * @param numero Número do voto na acta, ex.: 2026-015 — obrigatório ao criar
 * @param tipo coluna {@code vot_tipo} — obrigatório ao criar
 * @param assunto coluna {@code vot_assunto} — obrigatório ao criar
 * @param texto coluna {@code vot_texto}
 * @param leitura 1 = primeira leitura, 2 = votação na semana seguinte
 * @param aFavor coluna {@code vot_a_favor}
 * @param contra coluna {@code vot_contra}
 * @param abstencoes coluna {@code vot_abstencoes}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "secretaria", nome = "voto", prefixo = "vot", modulo = "secretaria", recurso = "votos")
public record Voto(
        @ColunaBd(value = "vot_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "vot_reu_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer reuniaoId,
        @ColunaBd(value = "vot_numero", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String numero,
        @ColunaBd(value = "vot_tipo", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        TipoVoto tipo,
        @ColunaBd(value = "vot_assunto", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String assunto,
        @ColunaBd(value = "vot_texto", tipo = Tipo.TEXTO)
        String texto,
        @ColunaBd(value = "vot_leitura", tipo = Tipo.INT, naoNula = true)
        Integer leitura,
        @ColunaBd(value = "vot_a_favor", tipo = Tipo.INT)
        Integer aFavor,
        @ColunaBd(value = "vot_contra", tipo = Tipo.INT)
        Integer contra,
        @ColunaBd(value = "vot_abstencoes", tipo = Tipo.INT)
        Integer abstencoes,
        @ColunaBd(value = "vot_estado", tipo = Tipo.ENUM, naoNula = true)
        ResultadoVoto estado,
        @ColunaBd(value = "vot_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "vot_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "vot_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "vot_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "vot_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
