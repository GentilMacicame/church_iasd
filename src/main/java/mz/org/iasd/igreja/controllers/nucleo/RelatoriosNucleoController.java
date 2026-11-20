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
 * F-COM Relatórios do núcleo: a fila de mensagens e o acompanhamento das aprovações (V54). Aceitam {@code ?igrejaId=} e
 * {@code ?formato=json|csv}.
 *
 * <pre>
 *   GET /v1/nucleo/notificacoes-a-enviar       fila pendente com hora já passada                  nucleo.notificacao.ler
 *   GET /v1/nucleo/acompanhamento-aprovacoes   processos: etapa em curso, quem decide, se pode     ler o objecto do processo
 *   GET /v1/nucleo/etapas-aprovacao            etapas de um processo (?aprovacaoId=)                ler o processo
 * </pre>
 */
@Path(Rotas.Nucleo.RELATORIOS)
@RequestScoped
public class RelatoriosNucleoController extends BaseRelatoriosController {

    public static final Relatorio NOTIFICACOES_A_ENVIAR = Relatorio.porIgreja("nucleo.vw_notificacoes_a_enviar",
            "ntf_igr_id = ?", "ntf_agendada_para, ntf_id");

    public static final Relatorio ACOMPANHAMENTO_APROVACOES = Relatorio.porIgreja("nucleo.vw_aprovacoes", "igreja_id = ?",
            "estado <> 'EM_CURSO', criado_em DESC, id DESC")
            .comFiltro("despesaId", "despesa_id").comFiltro("transacaoId", "transacao_id").comFiltro("contagemId", "contagem_id")
            .comFiltro("orcamentoId", "orcamento_id").comFiltro("membroId", "membro_id");

    public static final Relatorio ETAPAS_APROVACAO = Relatorio.porIgreja("nucleo.vw_aprovacao_etapas", null, "aprovacao_id, ordem")
            .comFiltro("aprovacaoId", "aprovacao_id");

    /** V54 O que está por aprovar ou conferir (e o já decidido): etapa em curso, quem decide e se o utilizador pode decidir. */
    @GET
    @Path(Rotas.Nucleo.ACOMPANHAMENTO_APROVACOES)
    public Response acompanhamentoAprovacoes() throws SQLException {
        return responder(ACOMPANHAMENTO_APROVACOES);
    }

    /** V54 As etapas de um processo: decididas (quem, quando, voto), a em curso e as pendentes. */
    @GET
    @Path(Rotas.Nucleo.ETAPAS_APROVACAO)
    public Response etapasAprovacao() throws SQLException {
        return responder(ETAPAS_APROVACAO);
    }

    /** O que o envio de mensagens (Fase 4) ainda tem por enviar. */
    @GET
    @Path(Rotas.Nucleo.NOTIFICACOES_A_ENVIAR)
    public Response notificacoesAEnviar() throws SQLException {
        return responder(NOTIFICACOES_A_ENVIAR);
    }
}
