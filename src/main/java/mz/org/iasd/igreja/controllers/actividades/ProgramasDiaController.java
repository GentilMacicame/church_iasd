package mz.org.iasd.igreja.controllers.actividades;

import java.sql.Connection;
import java.sql.Date;
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
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.controllers.base.Corpo;
import mz.org.iasd.igreja.models.actividades.ProgramaDia;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.repositories.base.TabelaRepository;

/**
 * F-ACT (V44) Programação do dia: a folha do sábado (Escola Sabatina, Transição, Culto Divino, JA) com as horas, as
 * actividades e os responsáveis. Tabela {@code actividades.programa_dia} · permissões {@code actividades.programa_dia.*}.
 * As partes e os itens têm as suas rotas ({@link PartesProgramaController}, {@link ItensProgramaController}).
 * <pre>
 *   rotas-padrão
 *   POST /v1/actividades/programas-dia/preparar            {igrejaId, data, origemId?} → programação   201
 *   POST /v1/actividades/programas-dia/{id}/preencher-escala                         → {mudaram}
 * </pre>
 * Preparar cria do modelo (ou copia o dia {@code origemId}) e preenche pela escala desse dia; as regras e as permissões
 * são da base de dados ({@code actividades.fn_programa_preparar}, {@code fn_programa_preencher}).
 */
@Path(Rotas.Actividades.PROGRAMAS_DIA)
@RequestScoped
public class ProgramasDiaController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(ProgramaDia.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    @POST
    @Path(Rotas.Actividades.PROGRAMAS_DIA_PREPARAR)
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response preparar(String corpo) throws SQLException {
        JsonObject o = Corpo.objecto(Corpo.ler(corpo));
        long igreja = Corpo.inteiro(o, "igrejaId");
        Date data = Date.valueOf(Corpo.data(o, "data"));
        Long origem = Corpo.inteiroOpcional(o, "origemId");
        Connection c = ligacao();
        long id;
        try (PreparedStatement ps = c.prepareStatement("SELECT actividades.fn_programa_preparar(?::integer, ?, ?::integer)")) {
            ps.setLong(1, igreja);
            ps.setDate(2, data);
            if (origem == null) {
                ps.setNull(3, Types.INTEGER);
            } else {
                ps.setLong(3, origem);
            }
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                id = rs.getLong(1);
            }
        }
        return Response.status(Response.Status.CREATED).entity(TabelaRepository.obterOu404(c, TABELA, id)).build();
    }

    @POST
    @Path(Rotas.Actividades.PROGRAMAS_DIA_PREENCHER)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response preencherEscala(@PathParam("id") long id) throws SQLException {
        Connection c = ligacao();
        TabelaRepository.obterOu404(c, TABELA, id);
        try (PreparedStatement ps = c.prepareStatement("SELECT actividades.fn_programa_preencher(?::integer)")) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return Response.ok(Json.createObjectBuilder().add("mudaram", rs.getInt(1)).build()).build();
            }
        }
    }
}
