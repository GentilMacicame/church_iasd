package mz.org.iasd.igreja.controllers.nucleo;

import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseRelatoriosController;
import mz.org.iasd.igreja.repositories.base.Relatorio;

/**
 * F-COM Relatórios do núcleo: a fila de mensagens. Aceitam {@code ?igrejaId=} e {@code ?formato=json|csv}.
 *
 * <pre>
 *   GET /v1/nucleo/notificacoes-a-enviar   fila pendente com hora já passada   nucleo.notificacao.ler
 * </pre>
 */
@Path(Rotas.Nucleo.RELATORIOS)
@RequestScoped
public class RelatoriosNucleoController extends BaseRelatoriosController {

    public static final Relatorio NOTIFICACOES_A_ENVIAR = Relatorio.porIgreja("nucleo.vw_notificacoes_a_enviar",
            "ntf_igr_id = ?", "ntf_agendada_para, ntf_id");

    /** O que o envio de mensagens (Fase 4) ainda tem por enviar. */
    @GET
    @Path(Rotas.Nucleo.NOTIFICACOES_A_ENVIAR)
    public Response notificacoesAEnviar() throws SQLException {
        return responder(NOTIFICACOES_A_ENVIAR);
    }
}
