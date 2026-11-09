package mz.org.iasd.igreja.controllers.tesouraria;

import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.json.JsonObject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.controllers.base.Corpo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.repositories.base.TabelaRepository;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.services.tesouraria.TransacoesService;

/**
 * F-TES-03/07/08 Movimentos: entradas, saídas e transferências (processos P-06, P-08, P-12).
 * Tabela {@code tesouraria.transacao}; linhas por fundo em {@code tesouraria.transacao_linha}.
 *
 * <pre>
 *   GET    /v1/tesouraria/transacoes?igrejaId=&amp;desde=&amp;ate=&amp;ordem=-dataHora
 *   POST   /v1/tesouraria/transacoes               cabeçalho + linhas   Idempotency-Key obrigatório
 *   GET    /v1/tesouraria/transacoes/{id}
 *   PATCH  /v1/tesouraria/transacoes/{id}
 *   POST   /v1/tesouraria/transacoes/{id}/terminar
 *   POST   /v1/tesouraria/transacoes/{id}/reactivar
 *   GET    /v1/tesouraria/transacoes/{id}/linhas
 *   POST   /v1/tesouraria/transacoes/{id}/aprovar   tesouraria.transacao.aprovar (fn_aprovar_saida)
 *   POST   /v1/tesouraria/transacoes/{id}/confirmar
 *   POST   /v1/tesouraria/transacoes/{id}/estornar  {valor, motivo, linhas}   Idempotency-Key obrigatório
 *   POST   /v1/tesouraria/transacoes/{id}/recibo    Idempotency-Key obrigatório
 * </pre>
 */
@Path(Rotas.Tesouraria.TRANSACOES)
@RequestScoped
public class TransacoesController extends BaseTabelaController {

    @Override
    protected Tabela tabela() {
        return TransacoesService.TRANSACAO;
    }

    @Override
    @Idempotente
    public Response criar(String corpo) throws SQLException {
        return super.criar(corpo);
    }

    @Override
    protected JsonObject criarRegisto(JsonObject corpo) throws SQLException {
        return TransacoesService.criar(ligacao(), corpo);
    }

    @GET
    @Path(Rotas.Tesouraria.TRANSACOES_LINHAS)
    @Produces(MediaType.APPLICATION_JSON)
    public Response linhas(@PathParam("id") long id) throws SQLException {
        TabelaRepository.obterOu404(ligacao(), tabela(), id);
        return ok(TabelaRepository.filhos(ligacao(), TransacoesService.LINHA, "tli_tra_id", id));
    }

    /** P-08 passo 2: aprovação em nome próprio; quem regista não aprova (base de dados). */
    @POST
    @Path(Rotas.Tesouraria.TRANSACOES_APROVAR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response aprovar(@PathParam("id") long id) throws SQLException {
        return ok(TransacoesService.aprovar(ligacao(), id));
    }

    /** Saídas sem aprovação são recusadas no COMMIT. */
    @POST
    @Path(Rotas.Tesouraria.TRANSACOES_CONFIRMAR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response confirmar(@PathParam("id") long id) throws SQLException {
        return ok(TransacoesService.confirmar(ligacao(), id));
    }

    @POST
    @Path(Rotas.Tesouraria.TRANSACOES_ESTORNAR)
    @Idempotente
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response estornar(@PathParam("id") long id, String corpo) throws SQLException {
        JsonObject estorno = TransacoesService.estornar(ligacao(), id, Corpo.objecto(Corpo.ler(corpo)));
        return criado(estorno, uri.getBaseUriBuilder().path("v1/tesouraria/transacoes").path(estorno.get("id").toString()).build());
    }

    @POST
    @Path(Rotas.Tesouraria.TRANSACOES_RECIBO)
    @Idempotente
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response recibo(@PathParam("id") long id) throws SQLException {
        JsonObject recibo = TransacoesService.emitirRecibo(ligacao(), id);
        return criado(recibo, uri.getBaseUriBuilder().path("v1/tesouraria/recibos").path(recibo.get("id").toString()).build());
    }
}
