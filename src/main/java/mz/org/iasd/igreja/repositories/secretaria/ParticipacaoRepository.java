package mz.org.iasd.igreja.repositories.secretaria;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObjectBuilder;

/**
 * V36 Participação dos membros: a última presença na Escola Sabatina ou contribuição (dele ou da família) e se é
 * inactivo (ACTIVO no livro sem participação nos últimos meses). A função da base só responde a quem lê os membros
 * da igreja e não devolve valores.
 */
public final class ParticipacaoRepository {

    private ParticipacaoRepository() {
    }

    public static JsonArray procurar(Connection c, int igreja, int meses) throws SQLException {
        JsonArrayBuilder r = Json.createArrayBuilder();
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT mem_id, ultima_participacao, inactivo FROM secretaria.fn_participacao_membros(?, ?)")) {
            ps.setInt(1, igreja);
            ps.setInt(2, meses);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    JsonObjectBuilder o = Json.createObjectBuilder().add("membroId", rs.getInt(1));
                    Date d = rs.getDate(2);
                    if (d == null) {
                        o.addNull("ultimaParticipacao");
                    } else {
                        o.add("ultimaParticipacao", d.toLocalDate().toString());
                    }
                    r.add(o.add("inactivo", rs.getBoolean(3)));
                }
            }
        }
        return r.build();
    }
}
