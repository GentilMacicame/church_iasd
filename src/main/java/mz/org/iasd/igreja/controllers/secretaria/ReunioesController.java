package mz.org.iasd.igreja.controllers.secretaria;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

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

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.Corpo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.TabelaRepository;
import mz.org.iasd.igreja.crud.TabelaRepository.Valor;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.secretaria.Reuniao;
import mz.org.iasd.igreja.models.secretaria.Voto;

/**
 * F-SEC-04 Reuniões e votos. Tabela {@code secretaria.reuniao}; votos em {@code secretaria.voto}.
 *
 * <pre>
 *   GET    /v1/secretaria/reunioes?igrejaId=
 *   POST   /v1/secretaria/reunioes
 *   GET    /v1/secretaria/reunioes/{id}
 *   PATCH  /v1/secretaria/reunioes/{id}
 *   POST   /v1/secretaria/reunioes/{id}/terminar
 *   POST   /v1/secretaria/reunioes/{id}/reactivar
 *   GET    /v1/secretaria/reunioes/{id}/votos     secretaria.voto.ler
 *   POST   /v1/secretaria/reunioes/{id}/votos     secretaria.voto.criar
 * </pre>
 */
@Path(Rotas.Secretaria.REUNIOES)
@RequestScoped
public class ReunioesController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Reuniao.class);
    private static final Tabela VOTO = Catalogo.de(Voto.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    @GET
    @Path(Rotas.Secretaria.REUNIOES_VOTOS)
    @Produces(MediaType.APPLICATION_JSON)
    public Response votos(@PathParam("id") long id) throws SQLException {
        TabelaRepository.obterOu404(ligacao(), TABELA, id);
        return ok(TabelaRepository.filhos(ligacao(), VOTO, "vot_reu_id", id));
    }

    @POST
    @Path(Rotas.Secretaria.REUNIOES_VOTOS)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response criarVoto(@PathParam("id") long id, String corpo) throws SQLException {
        TabelaRepository.obterOu404(ligacao(), TABELA, id);
        JsonObject o = Corpo.objecto(Corpo.ler(corpo));
        List<Valor> valores = new ArrayList<>(TabelaRepository.valoresDoCorpo(VOTO, o, Set.of("reuniaoId")));
        valores.add(Valor.campo(VOTO, "reuniaoId", Long.toString(id)));
        JsonObject voto = TabelaRepository.criar(ligacao(), VOTO, valores);
        return criado(voto, uri.getBaseUriBuilder().path("v1/secretaria/votos").path(voto.get("id").toString()).build());
    }
}
