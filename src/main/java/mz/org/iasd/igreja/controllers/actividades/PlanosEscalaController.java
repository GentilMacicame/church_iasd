package mz.org.iasd.igreja.controllers.actividades;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import jakarta.json.JsonValue;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.Corpo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.repositories.base.TabelaRepository;
import mz.org.iasd.igreja.models.actividades.EscalaPlano;

/**
 * F-ACT-03 Elaboração da escala da igreja (ex.: escala de pregação do trimestre): o período, quem assina
 * (ancião e secretário) e se está publicada. Os dias estão em {@link DiasEscalaController}, as pessoas em
 * {@link EscalasController}; a escala completa, como no papel, em {@code GET /v1/actividades/escala-grelha}.
 * Só a escala publicada ({@code publicada: true}) é vista pelos membros e gera lembretes por SMS.
 * Tabela {@code actividades.escala_plano} · permissões {@code actividades.escala_plano.*}.
 *
 * <pre>
 *   GET    /v1/actividades/planos-escala?igrejaId=
 *   POST   /v1/actividades/planos-escala
 *   GET    /v1/actividades/planos-escala/{id}
 *   PATCH  /v1/actividades/planos-escala/{id}                 (publicar: {"publicada": true})
 *   POST   /v1/actividades/planos-escala/{id}/terminar
 *   POST   /v1/actividades/planos-escala/{id}/reactivar
 *   POST   /v1/actividades/planos-escala/{id}/gerar-dias      {diaSemana?}  → {criados}   actividades.escala_dia.criar
 * </pre>
 */
@Path(Rotas.Actividades.PLANOS_ESCALA)
@RequestScoped
public class PlanosEscalaController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(EscalaPlano.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    /** Cria um dia para cada sábado (ou o dia da semana indicado) do período que ainda não o tenha. */
    @POST
    @Path(Rotas.Actividades.PLANOS_ESCALA_GERAR_DIAS)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response gerarDias(@PathParam("id") long id, String corpo) throws SQLException {
        JsonValue lido = Corpo.ler(corpo);
        JsonObject o = lido == JsonValue.NULL ? JsonValue.EMPTY_JSON_OBJECT : Corpo.objecto(lido);
        Long diaSemana = Corpo.inteiroOpcional(o, "diaSemana");
        Connection c = ligacao();
        TabelaRepository.obterOu404(c, TABELA, id);
        try (PreparedStatement ps = c.prepareStatement("SELECT actividades.fn_gerar_dias_escala(?::integer, ?::integer)")) {
            ps.setLong(1, id);
            ps.setLong(2, diaSemana == null ? 6 : diaSemana);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return Response.status(Response.Status.CREATED)
                        .entity(Json.createObjectBuilder().add("criados", rs.getInt(1)).build()).build();
            }
        }
    }
}
