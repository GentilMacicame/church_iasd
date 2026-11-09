package mz.org.iasd.igreja.controllers.actividades;

import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.controllers.base.BaseRelatoriosController;
import mz.org.iasd.igreja.repositories.base.Relatorio;
import mz.org.iasd.igreja.Rotas;

/**
 * F-ACT-03 Relatórios das actividades. Aceitam {@code ?igrejaId=} e {@code ?formato=json|csv}.
 *
 * <pre>
 *   GET /v1/actividades/escalas-proximas     escalas dos próximos 30 dias   actividades.escala.ler
 *   GET /v1/actividades/escala-grelha        ?planoId=   a escala como no papel: um dia por linha, uma coluna
 *                                            por função   actividades.escala_plano.ler (ou membro: publicada)
 * </pre>
 */
@Path(Rotas.Actividades.RELATORIOS)
@RequestScoped
public class RelatoriosActividadesController extends BaseRelatoriosController {

    public static final Relatorio ESCALAS_PROXIMAS = Relatorio.porIgreja("actividades.vw_escala_proximas",
            "esc_igr_id = ?", "esc_data, esc_funcao");
    public static final Relatorio ESCALA_GRELHA = Relatorio.porIgreja("actividades.vw_escala_grelha",
            "igreja_id = ?", "plano_id, data").comFiltro("planoId", "plano_id");

    @GET
    @Path(Rotas.Actividades.ESCALAS_PROXIMAS)
    public Response escalasProximas() throws SQLException {
        return responder(ESCALAS_PROXIMAS);
    }

    /** A escala para imprimir ou afixar (JSON ou CSV): pregador, tradutor, acompanhantes, coral, departamento. */
    @GET
    @Path(Rotas.Actividades.ESCALA_GRELHA)
    public Response escalaGrelha() throws SQLException {
        return responder(ESCALA_GRELHA);
    }
}
