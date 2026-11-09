package mz.org.iasd.igreja.controllers.secretaria;

import java.sql.SQLException;
import java.util.List;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.TabelaRepository;
import mz.org.iasd.igreja.crud.TabelaRepository.Valor;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.secretaria.Membro;

/**
 * F-SEC-01 Registo de membros. Membros, interessados e visitantes regulares; o estado só muda por
 * movimento no livro de membros (MovimentosMembroController). Filtro extra: {@code ?q=} procura por nome.
 * Tabela {@code secretaria.membro} · permissões {@code secretaria.membro.*}.
 *
 * <pre>
 *   GET    /v1/secretaria/membros?igrejaId=&amp;q=
 *   POST   /v1/secretaria/membros
 *   GET    /v1/secretaria/membros/{id}
 *   PATCH  /v1/secretaria/membros/{id}
 *   POST   /v1/secretaria/membros/{id}/terminar
 *   POST   /v1/secretaria/membros/{id}/reactivar
 *   POST   /v1/secretaria/membros/{id}/validar       secretaria.membro.validar (P-01 passo 2)
 * </pre>
 */
@Path(Rotas.Secretaria.MEMBROS)
@RequestScoped
public class MembrosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Membro.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    /** Aprova o registo: o trigger exige secretaria.membro.validar e regista quem validou e quando. */
    @POST
    @Path(Rotas.Secretaria.MEMBROS_VALIDAR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response validar(@PathParam("id") long id) throws SQLException {
        return ok(TabelaRepository.actualizar(ligacao(), TABELA, id,
                List.of(Valor.campo(TABELA, "validacao", "APROVADO")), null));
    }
}
