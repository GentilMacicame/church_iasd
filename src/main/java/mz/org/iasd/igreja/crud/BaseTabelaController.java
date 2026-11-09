package mz.org.iasd.igreja.crud;

import java.sql.SQLException;

import jakarta.json.JsonObject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import mz.org.iasd.igreja.Rotas;

/**
 * Base dos recursos de uma tabela que os utilizadores escrevem. Além das rotas de {@link BaseLeituraController}:
 *
 * <pre>
 *   POST  /                criar                      → 201 + Location
 *   PATCH /{id}            alterar (só os campos enviados)
 *   POST  /{id}/terminar   terminar (preenche endDate; nada se apaga)
 *   POST  /{id}/reactivar  reactivar (limpa endDate)
 * </pre>
 *
 * Para mudar a forma de criar (ex.: transacção com linhas), a subclasse reescreve {@link #criarRegisto}.
 * Para exigir {@code Idempotency-Key}, reescreve {@link #criar} só com a anotação {@code @Idempotente}
 * (as anotações JAX-RS são herdadas).
 */
public abstract class BaseTabelaController extends BaseLeituraController {

    @POST
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response criar(String corpo) throws SQLException {
        return criado(criarRegisto(Corpo.objecto(Corpo.ler(corpo))));
    }

    /** Criação por defeito: INSERT com os campos do corpo. */
    protected JsonObject criarRegisto(JsonObject corpo) throws SQLException {
        return TabelaRepository.criar(ligacao(), tabela(), corpo);
    }

    @PATCH
    @Path(Rotas.Comum.ID)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response alterar(@PathParam("id") long id, String corpo) throws SQLException {
        return ok(TabelaRepository.alterar(ligacao(), tabela(), id, Corpo.objecto(Corpo.ler(corpo))));
    }

    @POST
    @Path(Rotas.Comum.TERMINAR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response terminar(@PathParam("id") long id) throws SQLException {
        return ok(TabelaRepository.terminar(ligacao(), tabela(), id));
    }

    @POST
    @Path(Rotas.Comum.REACTIVAR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response reactivar(@PathParam("id") long id) throws SQLException {
        return ok(TabelaRepository.reactivar(ligacao(), tabela(), id));
    }
}
