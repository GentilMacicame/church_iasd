package mz.org.iasd.igreja.models.tesouraria;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Quem participou na contagem do numerário e com que função (tesoureiro, Escola Sabatina, diácono, ancião) (V42).
 * <p>
 * Tabela {@code tesouraria.contagem_participante} · rota {@code /v1/tesouraria/participantes-contagem}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param contagemId Referência a tesouraria.contagem_numerario — obrigatório ao criar
 * @param membroId Referência a secretaria.membro — obrigatório ao criar
 * @param funcao TESOUREIRO, ESCOLA_SABATINA, DIACONO, ANCIAO ou OUTRO — obrigatório ao criar
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "contagem_participante", prefixo = "cpa", modulo = "tesouraria", recurso = "participantes-contagem")
public record ContagemParticipante(
        @ColunaBd(value = "cpa_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "cpa_cnu_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer contagemId,
        @ColunaBd(value = "cpa_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "cpa_funcao", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String funcao,
        @ColunaBd(value = "cpa_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "cpa_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "cpa_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "cpa_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "cpa_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "cpa_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
