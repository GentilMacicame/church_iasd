package mz.org.iasd.igreja.repositories.tesouraria;

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
 * V50 Extractos num período: por departamento (% , saldo inicial, doações, despesas, transferências, estornos,
 * adiantamentos, saldo final) e por fundo (saldo inicial, entradas, saídas, saldo final). As funções são SECURITY
 * INVOKER: cada um só soma os movimentos que pode ver.
 */
public final class ExtractosRepository {

    private ExtractosRepository() {
    }

    public static JsonArray departamentos(Connection c, int igreja, LocalDate inicio, LocalDate fim) throws SQLException {
        return consultar(c, "SELECT * FROM tesouraria.fn_extracto_departamentos(?, ?, ?)", igreja, inicio, fim);
    }

    public static JsonArray fundos(Connection c, int igreja, LocalDate inicio, LocalDate fim) throws SQLException {
        return consultar(c, "SELECT * FROM tesouraria.fn_extracto_fundos(?, ?, ?)", igreja, inicio, fim);
    }

    private static JsonArray consultar(Connection c, String sql, int igreja, LocalDate inicio, LocalDate fim) throws SQLException {
        JsonArrayBuilder r = Json.createArrayBuilder();
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, igreja);
            ps.setDate(2, Date.valueOf(inicio));
            ps.setDate(3, Date.valueOf(fim));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    r.add(Conversao.linhaVista(rs));
                }
            }
        }
        return r.build();
    }
}
