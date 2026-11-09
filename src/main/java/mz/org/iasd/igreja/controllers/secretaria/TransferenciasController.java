package mz.org.iasd.igreja.controllers.secretaria;

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

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.Corpo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.repositories.base.TabelaRepository;
import mz.org.iasd.igreja.repositories.base.TabelaRepository.Valor;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.secretaria.TransferenciaMembro;

/**
 * F-SEC-06 Transferências (processo P-02). As regras — carta só a membro activo e sem censura, voto em
 * 2.ª leitura, validade de 6 meses, saída/entrada no livro de membros — estão nos triggers.
 * Tabela {@code secretaria.transferencia_membro}.
 *
 * <pre>
 *   GET    /v1/secretaria/transferencias
 *   POST   /v1/secretaria/transferencias                    pedido (P-02 passo 1)
 *   GET    /v1/secretaria/transferencias/{id}
 *   PATCH  /v1/secretaria/transferencias/{id}
 *   POST   /v1/secretaria/transferencias/{id}/terminar
 *   POST   /v1/secretaria/transferencias/{id}/reactivar
 *   POST   /v1/secretaria/transferencias/{id}/emitir-carta  {votoId, data}  …emitir_carta (passo 3)
 *   POST   /v1/secretaria/transferencias/{id}/concluir      {votoId, data}  …aceitar (passo 5)
 *   POST   /v1/secretaria/transferencias/{id}/recusar       {motivo}
 * </pre>
 */
@Path(Rotas.Secretaria.TRANSFERENCIAS)
@RequestScoped
public class TransferenciasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(TransferenciaMembro.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    @POST
    @Path(Rotas.Secretaria.TRANSFERENCIAS_EMITIR_CARTA)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response emitirCarta(@PathParam("id") long id, String corpo) throws SQLException {
        JsonObject o = Corpo.objecto(Corpo.ler(corpo));
        return mudar(id,
                Valor.campo(TABELA, "estado", "CARTA_EMITIDA"),
                Valor.campo(TABELA, "origemVotoId", Long.toString(Corpo.inteiro(o, "votoId"))),
                Valor.campo(TABELA, "cartaEmitidaEm", Corpo.data(o, "data").toString()));
    }

    @POST
    @Path(Rotas.Secretaria.TRANSFERENCIAS_CONCLUIR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response concluir(@PathParam("id") long id, String corpo) throws SQLException {
        JsonObject o = Corpo.objecto(Corpo.ler(corpo));
        return mudar(id,
                Valor.campo(TABELA, "estado", "CONCLUIDA"),
                Valor.campo(TABELA, "destinoVotoId", Long.toString(Corpo.inteiro(o, "votoId"))),
                Valor.campo(TABELA, "aceiteEm", Corpo.data(o, "data").toString()));
    }

    @POST
    @Path(Rotas.Secretaria.TRANSFERENCIAS_RECUSAR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response recusar(@PathParam("id") long id, String corpo) throws SQLException {
        JsonObject o = Corpo.objecto(Corpo.ler(corpo));
        return mudar(id,
                Valor.campo(TABELA, "estado", "RECUSADA"),
                Valor.campo(TABELA, "observacoes", Corpo.texto(o, "motivo")));
    }

    private Response mudar(long id, Valor... valores) throws SQLException {
        return ok(TabelaRepository.actualizar(ligacao(), TABELA, id, List.of(valores), null));
    }
}
