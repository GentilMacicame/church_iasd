package mz.org.iasd.igreja.controllers.comunicacao;

import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.crud.BaseRelatoriosController;
import mz.org.iasd.igreja.crud.Relatorio;

/**
 * F-COM Relatórios da comunicação. Aceitam {@code ?igrejaId=} e {@code ?formato=json|csv}.
 *
 * <pre>
 *   GET /v1/comunicacao/notificacoes-a-enviar   fila pendente com hora já passada   comunicacao.notificacao.ler
 * </pre>
 */
@Path(Rotas.Comunicacao.RELATORIOS)
@RequestScoped
public class RelatoriosComunicacaoController extends BaseRelatoriosController {

    public static final Relatorio NOTIFICACOES_A_ENVIAR = Relatorio.porIgreja("comunicacao.vw_notificacoes_a_enviar",
            "ntf_igr_id = ?", "ntf_agendada_para, ntf_id");

    /** O que o envio de mensagens (Fase 4) ainda tem por enviar. */
    @GET
    @Path(Rotas.Comunicacao.NOTIFICACOES_A_ENVIAR)
    public Response notificacoesAEnviar() throws SQLException {
        return responder(NOTIFICACOES_A_ENVIAR);
    }
}
