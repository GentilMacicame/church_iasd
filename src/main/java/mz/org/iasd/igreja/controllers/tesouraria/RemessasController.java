package mz.org.iasd.igreja.controllers.tesouraria;

import java.sql.SQLException;
import java.util.List;

import jakarta.enterprise.context.RequestScoped;
import jakarta.json.JsonObject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.Corpo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.TabelaRepository;
import mz.org.iasd.igreja.crud.TabelaRepository.Valor;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.services.tesouraria.TransacoesService;
import mz.org.iasd.igreja.models.tesouraria.Remessa;

/**
 * F-TES-10 Remessas mensais à Associação/Missão (processo P-09). Valor devido: relatório
 * {@code GET /v1/tesouraria/remessas-devidas}. Tabela {@code tesouraria.remessa}.
 *
 * <pre>
 *   GET    /v1/tesouraria/remessas?igrejaId=
 *   POST   /v1/tesouraria/remessas                  Idempotency-Key obrigatório
 *   GET    /v1/tesouraria/remessas/{id}
 *   PATCH  /v1/tesouraria/remessas/{id}
 *   POST   /v1/tesouraria/remessas/{id}/terminar
 *   POST   /v1/tesouraria/remessas/{id}/reactivar
 *   POST   /v1/tesouraria/remessas/{id}/enviar      {transacaoId, data}   (P-09 passo 3)
 *   POST   /v1/tesouraria/remessas/{id}/confirmar   tesouraria.remessa.confirmar — Associação (passo 4)
 * </pre>
 */
@Path(Rotas.Tesouraria.REMESSAS)
@RequestScoped
public class RemessasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Remessa.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    @Override
    @Idempotente
    public Response criar(String corpo) throws SQLException {
        return super.criar(corpo);
    }

    @POST
    @Path(Rotas.Tesouraria.REMESSAS_ENVIAR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response enviar(@PathParam("id") long id, String corpo) throws SQLException {
        JsonObject o = Corpo.objecto(Corpo.ler(corpo));
        return ok(TabelaRepository.actualizar(ligacao(), TABELA, id, List.of(
                Valor.campo(TABELA, "estado", "ENVIADA"),
                Valor.campo(TABELA, "transacaoId", Long.toString(Corpo.inteiro(o, "transacaoId"))),
                Valor.campo(TABELA, "enviadaEm", Corpo.data(o, "data").toString())), null));
    }

    @POST
    @Path(Rotas.Tesouraria.REMESSAS_CONFIRMAR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response confirmar(@PathParam("id") long id) throws SQLException {
        TabelaRepository.obterOu404(ligacao(), TABELA, id);
        TransacoesService.funcao(ligacao(), "SELECT tesouraria.fn_confirmar_remessa(?::integer)", id);
        return ok(TabelaRepository.obterOu404(ligacao(), TABELA, id));
    }
}
