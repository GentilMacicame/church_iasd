package mz.org.iasd.igreja.models.secretaria;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Presenças nas reuniões: quem esteve e quem faltou (com a justificação).
 * <p>
 * Tabela {@code secretaria.reuniao_presenca} · rota {@code /v1/secretaria/presencas-reuniao}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param reuniaoId Referência a secretaria.reuniao — obrigatório ao criar
 * @param membroId Referência a secretaria.membro — obrigatório ao criar
 * @param presente coluna {@code rpr_presente}
 * @param funcao Cargo com que participou (fica no histórico)
 * @param justificacao Motivo da ausência
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "secretaria", nome = "reuniao_presenca", prefixo = "rpr", modulo = "secretaria", recurso = "presencas-reuniao")
public record ReuniaoPresenca(
        @ColunaBd(value = "rpr_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "rpr_reu_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer reuniaoId,
        @ColunaBd(value = "rpr_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "rpr_presente", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean presente,
        @ColunaBd(value = "rpr_funcao", tipo = Tipo.TEXTO)
        String funcao,
        @ColunaBd(value = "rpr_justificacao", tipo = Tipo.TEXTO)
        String justificacao,
        @ColunaBd(value = "rpr_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "rpr_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "rpr_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "rpr_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "rpr_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "rpr_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
