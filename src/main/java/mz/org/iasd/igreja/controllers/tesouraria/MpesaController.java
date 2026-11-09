package mz.org.iasd.igreja.controllers.tesouraria;

import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.json.JsonObject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.PagamentoMpesa;

/**
 * F-PAG-01/02 Pagamentos M-Pesa (processo P-11). A integração com a Vodacom é da Fase 4: iniciar um
 * pagamento e receber a resposta respondem 501 por enquanto; a consulta dos registos já funciona.
 * Tabela {@code tesouraria.pagamento_mpesa}.
 *
 * <pre>
 *   GET    /v1/tesouraria/mpesa
 *   POST   /v1/tesouraria/mpesa                  iniciar pagamento   501 (Fase 4)
 *   POST   /v1/tesouraria/mpesa/callback         resposta da Vodacom 501 (Fase 4)
 *   GET    /v1/tesouraria/mpesa/{id}
 *   PATCH  /v1/tesouraria/mpesa/{id}
 *   POST   /v1/tesouraria/mpesa/{id}/terminar
 *   POST   /v1/tesouraria/mpesa/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.MPESA)
@RequestScoped
public class MpesaController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(PagamentoMpesa.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    @Override
    @Idempotente
    public Response criar(String corpo) throws SQLException {
        return super.criar(corpo);
    }

    @Override
    protected JsonObject criarRegisto(JsonObject corpo) {
        throw naoDisponivel("O pagamento por M-Pesa");
    }

    @POST
    @Path(Rotas.Tesouraria.MPESA_CALLBACK)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response callback(String corpo) {
        throw naoDisponivel("A recepção das respostas da Vodacom M-Pesa");
    }
}
