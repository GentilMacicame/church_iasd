package mz.org.iasd.igreja.controllers.tesouraria;

import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
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
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.services.tesouraria.TransacoesService;
import mz.org.iasd.igreja.models.tesouraria.Orcamento;

/**
 * F-TES-11 Orçamento anual da igreja local, aprovado por voto da igreja.
 * Tabela {@code tesouraria.orcamento}; linhas em LinhasOrcamentoController.
 *
 * <pre>
 *   GET    /v1/tesouraria/orcamentos?igrejaId=
 *   POST   /v1/tesouraria/orcamentos
 *   GET    /v1/tesouraria/orcamentos/{id}
 *   PATCH  /v1/tesouraria/orcamentos/{id}
 *   POST   /v1/tesouraria/orcamentos/{id}/terminar
 *   POST   /v1/tesouraria/orcamentos/{id}/reactivar
 *   POST   /v1/tesouraria/orcamentos/{id}/aprovar   {votoId}   tesouraria.orcamento.aprovar
 * </pre>
 */
@Path(Rotas.Tesouraria.ORCAMENTOS)
@RequestScoped
@Idempotente(opcional = true)
public class OrcamentosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Orcamento.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    @POST
    @Path(Rotas.Tesouraria.ORCAMENTOS_APROVAR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response aprovar(@PathParam("id") long id, String corpo) throws SQLException {
        long voto = Corpo.inteiro(Corpo.objecto(Corpo.ler(corpo)), "votoId");
        TabelaRepository.obterOu404(ligacao(), TABELA, id);
        TransacoesService.funcao(ligacao(), "SELECT tesouraria.fn_aprovar_orcamento(?::integer, ?::integer)", id, voto);
        return ok(TabelaRepository.obterOu404(ligacao(), TABELA, id));
    }
}
