package mz.org.iasd.igreja.controllers.escolasabatina;

import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.crud.BaseRelatoriosController;
import mz.org.iasd.igreja.crud.Relatorio;
import mz.org.iasd.igreja.Rotas;

/**
 * F-ES-07/08 Pontuação, classificação, painel e relatórios da Escola Sabatina
 * ({@code escola_sabatina.relatorio_sabado.ler}). Aceitam {@code ?igrejaId=} e {@code ?formato=json|csv}.
 *
 * <pre>
 *   GET /v1/escola-sabatina/classificacao          ?trimestreId=
 *   GET /v1/escola-sabatina/painel                 ?trimestreId=
 *   GET /v1/escola-sabatina/evolucao               ?trimestreId=
 *   GET /v1/escola-sabatina/relatorios-em-falta
 *   GET /v1/escola-sabatina/conferencia-ofertas
 *   GET /v1/escola-sabatina/relatorio-associacao   ?trimestreId=  (igrejaId → a sua Associação)
 *   GET /v1/escola-sabatina/resumo-classes         ?trimestreId=  escola_sabatina.classe_trimestre.ler
 *   GET /v1/escola-sabatina/visitantes-a-anonimizar               escola_sabatina.visitante.ler
 * </pre>
 */
@Path(Rotas.EscolaSabatina.RELATORIOS)
@RequestScoped
public class RelatoriosEscolaSabatinaController extends BaseRelatoriosController {

    public static final Relatorio CLASSIFICACAO = Relatorio.porIgreja("escola_sabatina.vw_classificacao",
            "ect_igr_id = ?", "lugar").comTrimestre("ect_etr_id");
    public static final Relatorio PAINEL = Relatorio.porIgreja("escola_sabatina.vw_painel",
            "igr_id = ?", "ano DESC, trimestre DESC").comTrimestre("etr_id");
    public static final Relatorio EVOLUCAO = Relatorio.porIgreja("escola_sabatina.vw_evolucao_sabado",
            "ect_igr_id = ?", "sabado, classe").comTrimestre("ect_etr_id");
    public static final Relatorio RELATORIOS_EM_FALTA = Relatorio.porIgreja("escola_sabatina.vw_relatorios_em_falta",
            "ect_igr_id = ?", "data, classe");
    public static final Relatorio CONFERENCIA_OFERTAS = Relatorio.porIgreja("escola_sabatina.vw_conferencia_ofertas",
            "ers_igr_id = ?", "data DESC, classe");
    public static final Relatorio RELATORIO_ASSOCIACAO = Relatorio.porIgreja("escola_sabatina.vw_relatorio_associacao",
            "ent_id = (SELECT igr_ent_id FROM organizacao.igreja WHERE igr_id = ?)", "divisao").comTrimestre("etr_id");
    public static final Relatorio RESUMO_CLASSES = Relatorio.porIgreja("escola_sabatina.vw_resumo_classe",
            "ect_igr_id = ?", "classe, ect_id").comTrimestre("ect_etr_id");
    public static final Relatorio VISITANTES_A_ANONIMIZAR = Relatorio.porIgreja("escola_sabatina.vw_visitantes_a_anonimizar",
            "ers_igr_id = ?", "data_visita, evi_id");

    /** Pontuação de 0 a 100 e lugar de cada classe, com a diferença para a média. */
    @GET
    @Path(Rotas.EscolaSabatina.CLASSIFICACAO)
    public Response classificacao() throws SQLException {
        return responder(CLASSIFICACAO);
    }

    /** Totais do trimestre por igreja. */
    @GET
    @Path(Rotas.EscolaSabatina.PAINEL)
    public Response painel() throws SQLException {
        return responder(PAINEL);
    }

    @GET
    @Path(Rotas.EscolaSabatina.EVOLUCAO)
    public Response evolucao() throws SQLException {
        return responder(EVOLUCAO);
    }

    /** Sábados passados sem relatório, por classe. */
    @GET
    @Path(Rotas.EscolaSabatina.RELATORIOS_EM_FALTA)
    public Response relatoriosEmFalta() throws SQLException {
        return responder(RELATORIOS_EM_FALTA);
    }

    /** Ofertas do relatório comparadas com o lançado na tesouraria. */
    @GET
    @Path(Rotas.EscolaSabatina.CONFERENCIA_OFERTAS)
    public Response conferenciaOfertas() throws SQLException {
        return responder(CONFERENCIA_OFERTAS);
    }

    /** Relatório trimestral consolidado por Associação/Missão e por divisão. */
    @GET
    @Path(Rotas.EscolaSabatina.RELATORIO_ASSOCIACAO)
    public Response relatorioAssociacao() throws SQLException {
        return responder(RELATORIO_ASSOCIACAO);
    }

    /** Resumo de cada classe no trimestre: presença, estudo diário, ofertas, visitantes, baptismos e alvos. */
    @GET
    @Path(Rotas.EscolaSabatina.RESUMO_CLASSES)
    public Response resumoClasses() throws SQLException {
        return responder(RESUMO_CLASSES);
    }

    /**
     * Visitantes com mais de 12 meses que não se tornaram membros. A tarefa diária
     * {@code escola_sabatina.fn_anonimizar_visitantes} apaga-lhes o nome e o telefone.
     */
    @GET
    @Path(Rotas.EscolaSabatina.VISITANTES_A_ANONIMIZAR)
    public Response visitantesAAnonimizar() throws SQLException {
        return responder(VISITANTES_A_ANONIMIZAR);
    }
}
