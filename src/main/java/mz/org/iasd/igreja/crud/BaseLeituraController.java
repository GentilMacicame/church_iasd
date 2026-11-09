package mz.org.iasd.igreja.crud;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

import jakarta.inject.Inject;
import jakarta.json.JsonObject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;

import mz.org.iasd.igreja.infraestrutura.bd.Transaccional;
import mz.org.iasd.igreja.infraestrutura.bd.UnidadeDeTrabalho;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.Rotas;

/**
 * Base dos recursos de uma tabela. Rotas herdadas (relativas ao {@code @Path} da subclasse):
 *
 * <pre>
 *   GET  /            listar  (filtros do contrato, ?limite, ?depois, ?ordem, ?incluirTerminados)
 *   GET  /{id}        ler     (404 se não existe ou não é visível para o utilizador)
 * </pre>
 *
 * A subclasse é um recurso JAX-RS ({@code @Path} + {@code @RequestScoped}) e indica a tabela em {@link #tabela()}.
 * Corre sempre numa transacção com o utilizador identificado ({@link Transaccional}).
 */
@Transaccional
public abstract class BaseLeituraController {

    @Inject
    protected UnidadeDeTrabalho unidade;

    @Context
    protected UriInfo uri;

    /** Tabela do catálogo servida por este recurso. */
    protected abstract Tabela tabela();

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response listar() throws SQLException {
        return Response.ok(TabelaRepository.listar(ligacao(), tabela(), parametros())).build();
    }

    @GET
    @Path(Rotas.Comum.ID)
    @Produces(MediaType.APPLICATION_JSON)
    public Response obter(@PathParam("id") long id) throws SQLException {
        return Response.ok(TabelaRepository.obterOu404(ligacao(), tabela(), id)).build();
    }

    // ------------------------------------------------------------------ apoio às subclasses

    protected Connection ligacao() {
        return unidade.ligacao();
    }

    /** Parâmetros da query (primeiro valor de cada um). */
    protected Map<String, String> parametros() {
        Map<String, String> p = new HashMap<>();
        uri.getQueryParameters().forEach((k, v) -> {
            if (!v.isEmpty()) {
                p.put(k, v.get(0));
            }
        });
        return p;
    }

    /** 201 Created com o header Location do registo criado nesta colecção. */
    protected Response criado(JsonObject registo) {
        return criado(registo, uri.getAbsolutePathBuilder().path(registo.get("id").toString()).build());
    }

    protected Response criado(JsonObject registo, java.net.URI local) {
        return Response.created(local).entity(registo).type(MediaType.APPLICATION_JSON_TYPE).build();
    }

    protected static Response ok(Object corpo) {
        return Response.ok(corpo).type(MediaType.APPLICATION_JSON_TYPE).build();
    }

    protected static ApiException naoDisponivel(String funcionalidade) {
        return new ApiException(501, "nao_disponivel", funcionalidade + " ainda não está disponível (Fase 4)", null);
    }
}
