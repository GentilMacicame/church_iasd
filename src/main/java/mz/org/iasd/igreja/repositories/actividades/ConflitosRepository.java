package mz.org.iasd.igreja.repositories.actividades;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.OffsetDateTime;

import jakarta.json.Json;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObject;
import jakarta.json.JsonObjectBuilder;

/**
 * F-ACT (V34) Conflitos de calendário: as actividades da igreja que se sobrepõem a um horário e os dias seguintes
 * livres, à mesma hora. As funções da base são SECURITY INVOKER (cada um só vê as actividades que pode ler).
 */
public final class ConflitosRepository {

    private ConflitosRepository() {
    }

    public static JsonObject procurar(Connection c, int igreja, OffsetDateTime inicio, OffsetDateTime fim, Integer excluir)
            throws SQLException {
        JsonArrayBuilder conflitos = Json.createArrayBuilder();
        try (PreparedStatement ps = c.prepareStatement("SELECT act_id, nome, departamento, data_inicio, data_fim, local "
                + "FROM actividades.fn_conflitos_actividade(?, ?, ?, ?)")) {
            parametros(ps, igreja, inicio, fim, excluir);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    JsonObjectBuilder o = Json.createObjectBuilder().add("actividadeId", rs.getInt(1))
                            .add("nome", rs.getString(2)).add("departamento", rs.getString(3));
                    dataHora(o, "dataInicio", rs.getObject(4, OffsetDateTime.class));
                    dataHora(o, "dataFim", rs.getObject(5, OffsetDateTime.class));
                    String local = rs.getString(6);
                    if (local == null) {
                        o.addNull("local");
                    } else {
                        o.add("local", local);
                    }
                    conflitos.add(o);
                }
            }
        }
        JsonArrayBuilder alternativas = Json.createArrayBuilder();
        try (PreparedStatement ps = c.prepareStatement("SELECT data_inicio, data_fim FROM actividades.fn_datas_alternativas(?, ?, ?, ?)")) {
            parametros(ps, igreja, inicio, fim, excluir);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    JsonObjectBuilder o = Json.createObjectBuilder();
                    dataHora(o, "dataInicio", rs.getObject(1, OffsetDateTime.class));
                    dataHora(o, "dataFim", rs.getObject(2, OffsetDateTime.class));
                    alternativas.add(o);
                }
            }
        }
        return Json.createObjectBuilder().add("conflitos", conflitos).add("alternativas", alternativas).build();
    }

    private static void parametros(PreparedStatement ps, int igreja, OffsetDateTime inicio, OffsetDateTime fim, Integer excluir)
            throws SQLException {
        ps.setInt(1, igreja);
        ps.setObject(2, inicio, Types.TIMESTAMP_WITH_TIMEZONE);
        if (fim == null) {
            ps.setNull(3, Types.TIMESTAMP_WITH_TIMEZONE);
        } else {
            ps.setObject(3, fim, Types.TIMESTAMP_WITH_TIMEZONE);
        }
        if (excluir == null) {
            ps.setNull(4, Types.INTEGER);
        } else {
            ps.setInt(4, excluir);
        }
    }

    private static void dataHora(JsonObjectBuilder o, String campo, OffsetDateTime v) {
        if (v == null) {
            o.addNull(campo);
        } else {
            o.add(campo, v.toString());
        }
    }
}
