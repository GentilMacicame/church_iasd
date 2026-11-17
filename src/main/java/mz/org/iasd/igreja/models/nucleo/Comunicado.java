package mz.org.iasd.igreja.models.nucleo;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoComunicado;

/**
 * Comunicados e anúncios: de uma igreja, do distrito pastoral ou da Associação/Missão (V37).
 * <p>
 * Tabela {@code nucleo.comunicado} · rota {@code /v1/nucleo/comunicados}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Publicado por esta igreja (para os seus membros)
 * @param distritoId Publicado pelo distrito pastoral (para as igrejas do distrito)
 * @param entidadeId Publicado pela Associação/Missão (para as suas igrejas)
 * @param titulo coluna {@code cmc_titulo} — obrigatório ao criar
 * @param conteudo coluna {@code cmc_conteudo} — obrigatório ao criar
 * @param publico MEMBROS (todos os membros) ou LIDERANCA (só quem tem perfil nas igrejas)
 * @param publicarEm A partir de quando aparece
 * @param validoAte Deixa de aparecer depois desta data (vazio = sem fim)
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "nucleo", nome = "comunicado", prefixo = "cmc", modulo = "nucleo", recurso = "comunicados")
public record Comunicado(
        @ColunaBd(value = "cmc_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "cmc_igr_id", tipo = Tipo.INT)
        Integer igrejaId,
        @ColunaBd(value = "cmc_dst_id", tipo = Tipo.INT)
        Integer distritoId,
        @ColunaBd(value = "cmc_ent_id", tipo = Tipo.INT)
        Integer entidadeId,
        @ColunaBd(value = "cmc_titulo", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String titulo,
        @ColunaBd(value = "cmc_conteudo", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String conteudo,
        @ColunaBd(value = "cmc_publico", tipo = Tipo.TEXTO, naoNula = true)
        String publico,
        @ColunaBd(value = "cmc_publicar_em", tipo = Tipo.DATA_HORA, naoNula = true)
        OffsetDateTime publicarEm,
        @ColunaBd(value = "cmc_valido_ate", tipo = Tipo.DATA_HORA)
        OffsetDateTime validoAte,
        @ColunaBd(value = "cmc_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoComunicado estado,
        @ColunaBd(value = "cmc_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "cmc_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "cmc_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "cmc_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "cmc_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
