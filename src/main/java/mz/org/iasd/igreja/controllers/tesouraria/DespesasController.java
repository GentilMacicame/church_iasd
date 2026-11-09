package mz.org.iasd.igreja.controllers.tesouraria;

import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.SQLException;

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
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.Despesa;

/**
 * F-TES-06 Requisições de despesa (processo P-07): quem pede não aprova.
 * Tabela {@code tesouraria.despesa}.
 *
 * <pre>
 *   GET    /v1/tesouraria/despesas?igrejaId=
 *   POST   /v1/tesouraria/despesas                 pedido (P-07 passo 1)
 *   GET    /v1/tesouraria/despesas/{id}
 *   PATCH  /v1/tesouraria/despesas/{id}
 *   POST   /v1/tesouraria/despesas/{id}/terminar
 *   POST   /v1/tesouraria/despesas/{id}/reactivar
 *   POST   /v1/tesouraria/despesas/{id}/decidir    {aprovar, valor?, motivo?}  tesouraria.despesa.aprovar
 * </pre>
 */
@Path(Rotas.Tesouraria.DESPESAS)
@RequestScoped
@Idempotente(opcional = true)
public class DespesasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Despesa.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    /** P-07 passo 2: {@code tesouraria.fn_decidir_despesa} — aprovar (podendo reduzir o valor) ou rejeitar. */
    @POST
    @Path(Rotas.Tesouraria.DESPESAS_DECIDIR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response decidir(@PathParam("id") long id, String corpo) throws SQLException {
        JsonObject o = Corpo.objecto(Corpo.ler(corpo));
        boolean aprovar = Corpo.booleano(o, "aprovar");
        BigDecimal valor = Corpo.dinheiroOpcional(o, "valor");
        String motivo = Corpo.textoOpcional(o, "motivo");
        TabelaRepository.obterOu404(ligacao(), TABELA, id);
        try (PreparedStatement ps = ligacao().prepareStatement(
                "SELECT tesouraria.fn_decidir_despesa(?::integer, ?::boolean, ?::numeric, ?::text)")) {
            ps.setLong(1, id);
            ps.setBoolean(2, aprovar);
            ps.setBigDecimal(3, valor);
            ps.setString(4, motivo);
            ps.execute();
        }
        return ok(TabelaRepository.obterOu404(ligacao(), TABELA, id));
    }
}
