package mz.org.iasd.igreja.repositories.organizacao;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;

import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonArrayBuilder;

import mz.org.iasd.igreja.repositories.base.Conversao;

/**
 * V38 Dashboard por período: uma linha por igreja visível ao utilizador (membros, activos, inactivos, dízimos,
 * ofertas, reavivamento, contribuintes, entradas e perdas de membros). A função da base é SECURITY INVOKER.
 */
public final class PainelRepository {

    private PainelRepository() {
    }

    public static JsonArray periodo(Connection c, LocalDate inicio, LocalDate fim, Integer entidade, Integer distrito)
            throws SQLException {
        String sql = "SELECT * FROM organizacao.fn_painel_periodo(?, ?) p WHERE (?::int IS NULL OR p.entidade_id = ?::int) "
                + "AND (?::int IS NULL OR p.distrito_pastoral_id = ?::int)";
        JsonArrayBuilder r = Json.createArrayBuilder();
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(inicio));
            ps.setDate(2, Date.valueOf(fim));
            ps.setObject(3, entidade);
            ps.setObject(4, entidade);
            ps.setObject(5, distrito);
            ps.setObject(6, distrito);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    r.add(Conversao.linhaVista(rs));
                }
            }
        }
        return r.build();
    }
}
