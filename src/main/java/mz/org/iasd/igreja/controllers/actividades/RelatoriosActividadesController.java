package mz.org.iasd.igreja.controllers.actividades;

import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.crud.BaseRelatoriosController;
import mz.org.iasd.igreja.crud.Relatorio;
import mz.org.iasd.igreja.Rotas;

/**
 * F-ACT-03 Relatórios das actividades. Aceitam {@code ?igrejaId=} e {@code ?formato=json|csv}.
 *
 * <pre>
 *   GET /v1/actividades/escalas-proximas     escalas dos próximos 30 dias   actividades.escala.ler
 * </pre>
 */
@Path(Rotas.Actividades.RELATORIOS)
@RequestScoped
public class RelatoriosActividadesController extends BaseRelatoriosController {

    public static final Relatorio ESCALAS_PROXIMAS = Relatorio.porIgreja("actividades.vw_escala_proximas",
            "esc_igr_id = ?", "esc_data, esc_funcao");

    @GET
    @Path(Rotas.Actividades.ESCALAS_PROXIMAS)
    public Response escalasProximas() throws SQLException {
        return responder(ESCALAS_PROXIMAS);
    }
}
