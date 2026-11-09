package mz.org.iasd.igreja.controllers.tesouraria;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.json.Json;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.crud.Corpo;
import mz.org.iasd.igreja.infraestrutura.bd.Transaccional;
import mz.org.iasd.igreja.infraestrutura.bd.UnidadeDeTrabalho;

/**
 * F-TES-10 Recalcular os saldos pré-calculados de uma igreja a partir dos movimentos confirmados (auditoria, ou
 * depois de uma importação). Os saldos antigos são terminados, não apagados.
 *
 * <pre>
 *   POST /v1/tesouraria/recalcular-saldos   {igrejaId}   tesouraria.fecho_periodo.criar
 *        tesouraria.fn_recalcular_saldos → {igrejaId, contas, fundos} (linhas de saldo diário recalculadas)
 * </pre>
 */
@Path(Rotas.Tesouraria.RECALCULAR_SALDOS)
@RequestScoped
@Transaccional
public class SaldosController {

    @Inject
    UnidadeDeTrabalho unidade;

    @POST
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response recalcular(String corpo) throws SQLException {
        long igreja = Corpo.inteiro(Corpo.objecto(Corpo.ler(corpo)), "igrejaId");
        Connection c = unidade.ligacao();
        try (PreparedStatement ps = c.prepareStatement("SELECT tesouraria.fn_recalcular_saldos(?::integer)")) {
            ps.setLong(1, igreja);
            ps.execute();
        }
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT (SELECT count(*) FROM tesouraria.saldo_diario_conta WHERE sdc_igr_id = ? AND sdc_end_date IS NULL),"
                        + " (SELECT count(*) FROM tesouraria.saldo_diario_fundo WHERE sdf_igr_id = ? AND sdf_end_date IS NULL)")) {
            ps.setLong(1, igreja);
            ps.setLong(2, igreja);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return Response.ok(Json.createObjectBuilder()
                        .add("igrejaId", igreja).add("contas", rs.getLong(1)).add("fundos", rs.getLong(2)).build())
                        .build();
            }
        }
    }
}
