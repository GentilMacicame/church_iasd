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

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.repositories.base.TabelaRepository;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.FechoPeriodo;

/**
 * F-TES-13 Fecho mensal (processo P-10): criar um fecho bloqueia os movimentos do mês; reabrir é terminar
 * o fecho (fica no histórico). Tabela {@code tesouraria.fecho_periodo}.
 *
 * <pre>
 *   GET    /v1/tesouraria/fechos?igrejaId=
 *   POST   /v1/tesouraria/fechos                  fechar o mês (P-10 passo 2)
 *   GET    /v1/tesouraria/fechos/{id}
 *   PATCH  /v1/tesouraria/fechos/{id}
 *   POST   /v1/tesouraria/fechos/{id}/terminar
 *   POST   /v1/tesouraria/fechos/{id}/reactivar
 *   POST   /v1/tesouraria/fechos/{id}/reabrir     tesouraria.fecho_periodo.terminar (passo 3)
 * </pre>
 */
@Path(Rotas.Tesouraria.FECHOS)
@RequestScoped
@Idempotente(opcional = true)
public class FechosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(FechoPeriodo.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    @POST
    @Path(Rotas.Tesouraria.FECHOS_REABRIR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response reabrir(@PathParam("id") long id) throws SQLException {
        return ok(TabelaRepository.terminar(ligacao(), TABELA, id));
    }
}
