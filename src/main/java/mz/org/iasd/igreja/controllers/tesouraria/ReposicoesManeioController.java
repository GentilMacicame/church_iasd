package mz.org.iasd.igreja.controllers.tesouraria;

import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.OffsetDateTime;

import jakarta.enterprise.context.RequestScoped;
import jakarta.json.JsonObject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.controllers.base.Corpo;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.tesouraria.ReposicaoManeio;
import mz.org.iasd.igreja.repositories.base.TabelaRepository;

/**
 * V56 Reposição mensal do fundo de maneio. Tabela {@code tesouraria.reposicao_maneio} · permissões
 * {@code tesouraria.reposicao_maneio.*}. Pede-se o que foi gasto (a base de dados calcula e recusa mais do que isso, ou
 * nada se o fundo não foi usado); o Conselho da Igreja aprova (processo MANEIO, em /v1/nucleo/aprovacoes); depois:
 *
 * <pre>
 *   POST /v1/tesouraria/reposicoes-maneio/{id}/repor   {contaOrigemId, dataHora?}   tesouraria.fn_repor_maneio
 * </pre>
 */
@Path(Rotas.Tesouraria.REPOSICOES_MANEIO)
@RequestScoped
public class ReposicoesManeioController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(ReposicaoManeio.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    /** Transferência da conta de origem para o fundo de maneio, pelo valor aprovado; devolve a reposição. */
    @POST
    @Path(Rotas.Tesouraria.REPOSICOES_MANEIO_REPOR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    @Idempotente
    public Response repor(@PathParam("id") long id, String corpo) throws SQLException {
        JsonObject o = Corpo.objecto(Corpo.ler(corpo));
        long origem = Corpo.inteiro(o, "contaOrigemId");
        String dataHora = Corpo.textoOpcional(o, "dataHora");
        OffsetDateTime quando;
        try {
            quando = dataHora == null ? null : OffsetDateTime.parse(dataHora);
        } catch (java.time.format.DateTimeParseException e) {
            throw ApiException.pedidoInvalido("Data e hora inválidas (ISO 8601, com fuso)", "dataHora");
        }
        try (PreparedStatement ps = ligacao().prepareStatement(
                "SELECT tesouraria.fn_repor_maneio(?::integer, ?::integer, COALESCE(?::timestamptz, now()))")) {
            ps.setLong(1, id);
            ps.setLong(2, origem);
            ps.setObject(3, quando);
            ps.execute();
        }
        return ok(TabelaRepository.obterOu404(ligacao(), TABELA, id));
    }
}
