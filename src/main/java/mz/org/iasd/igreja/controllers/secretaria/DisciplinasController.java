package mz.org.iasd.igreja.controllers.secretaria;

import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.json.Json;
import jakarta.json.JsonObjectBuilder;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.repositories.secretaria.DisciplinaRepository;
import mz.org.iasd.igreja.models.secretaria.Disciplina;

/**
 * Censuras (1 a 12 meses): sem cargos nem carta de transferência durante a censura.
 * Tabela {@code secretaria.disciplina} · permissões {@code secretaria.disciplina.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/secretaria/disciplinas
 *   POST   /v1/secretaria/disciplinas
 *   GET    /v1/secretaria/disciplinas/{id}
 *   PATCH  /v1/secretaria/disciplinas/{id}
 *   POST   /v1/secretaria/disciplinas/{id}/terminar
 *   POST   /v1/secretaria/disciplinas/{id}/reactivar
 *   GET    /v1/secretaria/disciplinas/{id}/motivo      o motivo (confidencial; a consulta fica registada, V41)
 * </pre>
 * O motivo é só de escrita nas outras rotas: grava-se no POST/PATCH, mas não vem nas respostas.
 */
@Path(Rotas.Secretaria.DISCIPLINAS)
@RequestScoped
public class DisciplinasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Disciplina.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    /** V41: o motivo da censura. A base de dados confirma a permissão e regista quem o consultou e quando. */
    @GET
    @Path(Rotas.Secretaria.DISCIPLINAS_MOTIVO)
    @Produces(MediaType.APPLICATION_JSON)
    public Response motivo(@PathParam("id") long id) throws SQLException {
        String m = DisciplinaRepository.motivo(ligacao(), id);
        JsonObjectBuilder o = Json.createObjectBuilder();
        return Response.ok((m == null ? o.addNull("motivo") : o.add("motivo", m)).build()).build();
    }
}
