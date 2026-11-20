package mz.org.iasd.igreja.models.nucleo;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.AccaoEtapa;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;
import mz.org.iasd.igreja.models.tipos.ResponsavelEtapa;
import mz.org.iasd.igreja.models.tipos.TipoReuniao;

/**
 * Etapas de um fluxo de aprovação, pela ordem em que se decidem: quem decide (perfil, permissão ou órgão que vota) e o que faz (V54).
 * <p>
 * Tabela {@code nucleo.fluxo_etapa} · rota {@code /v1/nucleo/etapas-fluxo}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param fluxoAprovacaoId Referência a nucleo.fluxo_aprovacao — obrigatório ao criar
 * @param igrejaId Copiado do fluxo
 * @param ordem 1 = a primeira a decidir — obrigatório ao criar
 * @param nome coluna {@code fae_nome} — obrigatório ao criar
 * @param accao coluna {@code fae_accao}
 * @param responsavel PERFIL (quem tem esse perfil na igreja), PERMISSAO (quem tem essa permissão) ou ORGAO (o órgão vota em reunião) — obrigatório ao criar
 * @param perfilId Perfil que decide (responsavel = PERFIL)
 * @param permissaoId Permissão de quem decide (responsavel = PERMISSAO)
 * @param orgao Órgão que vota (responsavel = ORGAO): o voto tem de ser de uma reunião deste tipo
 * @param outraPessoa Quem pediu e quem já decidiu outra etapa não decide esta
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "nucleo", nome = "fluxo_etapa", prefixo = "fae", modulo = "nucleo", recurso = "etapas-fluxo")
public record FluxoEtapa(
        @ColunaBd(value = "fae_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "fae_fap_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer fluxoAprovacaoId,
        @ColunaBd(value = "fae_igr_id", tipo = Tipo.INT)
        Integer igrejaId,
        @ColunaBd(value = "fae_ordem", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer ordem,
        @ColunaBd(value = "fae_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "fae_accao", tipo = Tipo.ENUM, naoNula = true)
        AccaoEtapa accao,
        @ColunaBd(value = "fae_responsavel", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        ResponsavelEtapa responsavel,
        @ColunaBd(value = "fae_per_id", tipo = Tipo.INT)
        Integer perfilId,
        @ColunaBd(value = "fae_prm_id", tipo = Tipo.INT)
        Integer permissaoId,
        @ColunaBd(value = "fae_orgao", tipo = Tipo.ENUM)
        TipoReuniao orgao,
        @ColunaBd(value = "fae_outra_pessoa", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean outraPessoa,
        @ColunaBd(value = "fae_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "fae_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "fae_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "fae_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "fae_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "fae_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
