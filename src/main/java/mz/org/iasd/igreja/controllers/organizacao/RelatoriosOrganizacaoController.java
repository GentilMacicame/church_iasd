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
 *   GET /v1/organizacao/painel-igrejas       ?igrejaId= ?entidadeId= ?distritoId=   painel geral (V30)
 *   GET /v1/organizacao/painel-igrejas-mensal ?igrejaId= ?entidadeId= ?distritoId=  últimos 12 meses (V30)
 * </pre>
 *
 * O painel geral não precisa de igrejaId: cada utilizador recebe só as igrejas a que tem acesso (vistas
 * security_invoker; o pastor do distrito vê as do seu distrito, a Associação as suas, o super-administrador todas).
 */
@Path(Rotas.Organizacao.RELATORIOS)
@RequestScoped
public class RelatoriosOrganizacaoController extends BaseRelatoriosController {

    /** Nome, tipo, Associação e localização de cada igreja: para escolher o destino de uma transferência. */
    public static final Relatorio DIRECTORIO_IGREJAS = Relatorio.porIgreja("organizacao.vw_directorio_igrejas", null, "nome, igr_id")
            .comFiltro("entidadeId", "igr_ent_id");

    /** V30: membros, transferências, dizimistas e situação financeira por igreja visível ao utilizador. */
    public static final Relatorio PAINEL_IGREJAS = Relatorio.porIgreja("organizacao.vw_painel_igrejas", "igr_id = ?", "nome, igr_id")
            .comFiltro("entidadeId", "entidade_id").comFiltro("distritoId", "distrito_pastoral_id");

    /** V30: os últimos 12 meses de cada igreja visível (entradas, saídas, dízimos, dizimistas, admissões, transferências). */
    public static final Relatorio PAINEL_IGREJAS_MENSAL = Relatorio.porIgreja("organizacao.vw_painel_igrejas_mensal", "igr_id = ?", "ano, mes, nome, igr_id")
            .comFiltro("entidadeId", "entidade_id").comFiltro("distritoId", "distrito_pastoral_id");

    @GET
    @Path(Rotas.Organizacao.PAINEL_IGREJAS)
    public Response painelIgrejas() throws SQLException {
        return responder(PAINEL_IGREJAS);
    }

    @GET
    @Path(Rotas.Organizacao.PAINEL_IGREJAS_MENSAL)
    public Response painelIgrejasMensal() throws SQLException {
        return responder(PAINEL_IGREJAS_MENSAL);
    }

    @GET
    @Path(Rotas.Organizacao.DIRECTORIO_IGREJAS)
    public Response directorioIgrejas() throws SQLException {
        return responder(DIRECTORIO_IGREJAS);
    }
}
