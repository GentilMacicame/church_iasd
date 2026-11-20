package mz.org.iasd.igreja.controllers.nucleo;

import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import jakarta.enterprise.context.RequestScoped;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseLeituraController;
import mz.org.iasd.igreja.controllers.base.Corpo;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.nucleo.Aprovacao;

/**
 * V54 Processos de aprovação (despesas, saídas, contagens, orçamentos, admissão e remoção de membros). Só leitura: os
 * processos iniciam-se sozinhos na base de dados. A decisão de cada etapa:
 *
 * <pre>
 *   POST /v1/nucleo/aprovacoes/{id}/decidir   {aprovar?, votoId?, motivo?, valor?}   nucleo.fn_aprovacao_decidir
 * </pre>
 *
 * Quem decide cada etapa (perfil, permissão ou o órgão, pelo voto), a ordem e a segregação decide-as a base de dados.
 * Para o acompanhamento (etapa em curso, quem decide, se o utilizador pode) ver os relatórios
 * {@code acompanhamento-aprovacoes} e {@code etapas-aprovacao}.
 */
@Path(Rotas.Nucleo.APROVACOES)
@RequestScoped
public class AprovacoesController extends BaseLeituraController {

    private static final Tabela TABELA = Catalogo.de(Aprovacao.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    /** Decide a etapa em curso; devolve o estado do processo depois da decisão (EM_CURSO, APROVADO ou REJEITADO). */
    @POST
    @Path(Rotas.Nucleo.APROVACOES_DECIDIR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response decidir(@PathParam("id") long id, String corpo) throws SQLException {
        JsonObject o = Corpo.objecto(Corpo.ler(corpo));
        Boolean aprovar = Corpo.tem(o, "aprovar") ? Corpo.booleano(o, "aprovar") : null;
        Long voto = Corpo.inteiroOpcional(o, "votoId");
        String motivo = Corpo.textoOpcional(o, "motivo");
        BigDecimal valor = Corpo.dinheiroOpcional(o, "valor");
        try (PreparedStatement ps = ligacao().prepareStatement(
                "SELECT nucleo.fn_aprovacao_decidir(?::integer, ?::boolean, ?::integer, ?::text, ?::numeric)::text")) {
            ps.setLong(1, id);
            if (aprovar == null) {
                ps.setNull(2, Types.BOOLEAN);
            } else {
                ps.setBoolean(2, aprovar);
            }
            if (voto == null) {
                ps.setNull(3, Types.INTEGER);
            } else {
                ps.setLong(3, voto);
            }
            ps.setString(4, motivo);
            ps.setBigDecimal(5, valor);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return ok(Json.createObjectBuilder().add("estado", rs.getString(1)).build());
            }
        }
    }
}
