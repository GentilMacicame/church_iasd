package mz.org.iasd.igreja.controllers.organizacao;

import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseRelatoriosController;
import mz.org.iasd.igreja.repositories.base.Relatorio;

/**
 * Relatórios da organização.
 *
 * <pre>
 *   GET /v1/organizacao/directorio-igrejas   ?entidadeId=   qualquer utilizador com sessão (V27)
 * </pre>
 */
@Path(Rotas.Organizacao.RELATORIOS)
@RequestScoped
public class RelatoriosOrganizacaoController extends BaseRelatoriosController {

    /** Nome, tipo, Associação e localização de cada igreja: para escolher o destino de uma transferência. */
    public static final Relatorio DIRECTORIO_IGREJAS = Relatorio.porIgreja("organizacao.vw_directorio_igrejas", null, "nome, igr_id")
            .comFiltro("entidadeId", "igr_ent_id");

    @GET
    @Path(Rotas.Organizacao.DIRECTORIO_IGREJAS)
    public Response directorioIgrejas() throws SQLException {
        return responder(DIRECTORIO_IGREJAS);
    }
}
