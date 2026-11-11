package mz.org.iasd.igreja.controllers.secretaria;

import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.controllers.base.BaseRelatoriosController;
import mz.org.iasd.igreja.repositories.base.Relatorio;
import mz.org.iasd.igreja.Rotas;

/**
 * F-SEC-10 Relatórios da secretaria. Todos aceitam {@code ?igrejaId=} e {@code ?formato=json|csv}.
 *
 * <pre>
 *   GET /v1/secretaria/relatorio-mensal       ?ano=&amp;mes=   secretaria.movimento_membro.ler
 *   GET /v1/secretaria/cartas-pendentes                     secretaria.transferencia_membro.ler
 *   GET /v1/secretaria/censuras-activas                     secretaria.disciplina.ler
 *   GET /v1/secretaria/mandatos-a-terminar                  secretaria.oficial.ler
 *   GET /v1/secretaria/menores-pendentes                    secretaria.membro.ler
 *   GET /v1/secretaria/familias-resumo                      secretaria.familia.ler
 *   GET /v1/secretaria/membros-basico                       secretaria.membro.ler
 *   GET /v1/secretaria/conselho                             secretaria.oficial.ler
 * </pre>
 */
@Path(Rotas.Secretaria.RELATORIOS)
@RequestScoped
public class RelatoriosSecretariaController extends BaseRelatoriosController {

    public static final Relatorio RELATORIO_MENSAL = Relatorio.porIgreja("secretaria.vw_relatorio_mensal_membros",
            "igr_id = ?", "ano DESC, mes DESC").comAnoMes("ano", "mes");
    public static final Relatorio CARTAS_PENDENTES = Relatorio.porIgreja("secretaria.vw_cartas_pendentes",
            "(tme_origem_igr_id = ? OR tme_destino_igr_id = ?)", "tme_carta_emitida_em");
    public static final Relatorio CENSURAS_ACTIVAS = Relatorio.porIgreja("secretaria.vw_censuras_activas",
            "mem_igr_id = ?", "dsc_data_fim");
    public static final Relatorio MANDATOS_A_TERMINAR = Relatorio.porIgreja("secretaria.vw_mandatos_a_terminar",
            "ofi_igr_id = ?", "fim_previsto");
    public static final Relatorio MENORES_PENDENTES = Relatorio.porIgreja("secretaria.vw_menores_pendentes",
            "mem_igr_id = ?", "mem_apelido, mem_nome");
    public static final Relatorio FAMILIAS_RESUMO = Relatorio.porIgreja("secretaria.vw_familia_resumo",
            "fam_igr_id = ?", "fam_nome");
    public static final Relatorio MEMBROS_BASICO = Relatorio.porIgreja("secretaria.vw_membro_basico",
            "mem_igr_id = ?", "mem_apelido, mem_nome, mem_id");
    public static final Relatorio CONSELHO = Relatorio.porIgreja("secretaria.vw_conselho",
            "ofi_igr_id = ?", "do_conselho DESC, cargo, membro");

    /** Relatório mensal à Associação: entradas e saídas do livro de membros por tipo. */
    @GET
    @Path(Rotas.Secretaria.RELATORIO_MENSAL)
    public Response relatorioMensal() throws SQLException {
        return responder(RELATORIO_MENSAL);
    }

    /** Cartas emitidas ainda por concluir (válidas 6 meses). */
    @GET
    @Path(Rotas.Secretaria.CARTAS_PENDENTES)
    public Response cartasPendentes() throws SQLException {
        return responder(CARTAS_PENDENTES);
    }

    @GET
    @Path(Rotas.Secretaria.CENSURAS_ACTIVAS)
    public Response censurasActivas() throws SQLException {
        return responder(CENSURAS_ACTIVAS);
    }

    /** Conselho da igreja: oficiais, cargo, contacto e estado do mandato (F-SEC-07). */
    @GET
    @Path(Rotas.Secretaria.CONSELHO)
    public Response conselho() throws SQLException {
        return responder(CONSELHO);
    }

    /** Mandatos que terminam nos próximos 60 dias (para a comissão de nomeações). */
    @GET
    @Path(Rotas.Secretaria.MANDATOS_A_TERMINAR)
    public Response mandatosATerminar() throws SQLException {
        return responder(MANDATOS_A_TERMINAR);
    }

    /** Menores sem encarregado ou sem consentimento registado. */
    @GET
    @Path(Rotas.Secretaria.MENORES_PENDENTES)
    public Response menoresPendentes() throws SQLException {
        return responder(MENORES_PENDENTES);
    }

    @GET
    @Path(Rotas.Secretaria.FAMILIAS_RESUMO)
    public Response familiasResumo() throws SQLException {
        return responder(FAMILIAS_RESUMO);
    }

    /** Lista leve de membros (nome, sexo, estado) para listas de escolha e de chamada. */
    @GET
    @Path(Rotas.Secretaria.MEMBROS_BASICO)
    public Response membrosBasico() throws SQLException {
        return responder(MEMBROS_BASICO);
    }
}
