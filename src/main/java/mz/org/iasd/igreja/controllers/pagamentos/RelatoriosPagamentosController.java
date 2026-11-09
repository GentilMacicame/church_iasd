package mz.org.iasd.igreja.controllers.pagamentos;

import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.crud.BaseRelatoriosController;
import mz.org.iasd.igreja.crud.Relatorio;

/**
 * F-PAG Relatórios dos pagamentos electrónicos. Aceitam {@code ?igrejaId=} e {@code ?formato=json|csv}.
 *
 * <pre>
 *   GET /v1/pagamentos/mpesa-pendentes   pedidos M-Pesa sem resposta há mais de 5 minutos   pagamentos.pagamento_mpesa.ler
 * </pre>
 */
@Path(Rotas.Pagamentos.RELATORIOS)
@RequestScoped
public class RelatoriosPagamentosController extends BaseRelatoriosController {

    public static final Relatorio MPESA_PENDENTES = Relatorio.porIgreja("pagamentos.vw_mpesa_pendentes",
            "pmp_tra_id IN (SELECT tra_id FROM tesouraria.transacao WHERE tra_igr_id = ?)", "pmp_pedido_em, pmp_id");

    /** Pedidos a consultar na Vodacom (P-11): a resposta não chegou. */
    @GET
    @Path(Rotas.Pagamentos.MPESA_PENDENTES)
    public Response mpesaPendentes() throws SQLException {
        return responder(MPESA_PENDENTES);
    }
}
