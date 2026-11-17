package mz.org.iasd.igreja.repositories.tesouraria;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.time.OffsetDateTime;

import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObject;
import jakarta.json.JsonObjectBuilder;

/**
 * V36 Consultas de apoio ao lançamento de contribuições e às metas anuais (funções SECURITY INVOKER: cada um só vê
 * os movimentos e alvos que pode ler). Dinheiro em texto com 2 casas.
 */
public final class ContribuicoesRepository {

    private ContribuicoesRepository() {
    }

    /** Dízimos do mesmo mês já lançados em nome da família do membro (ou dos membros da família). Só aviso. */
    public static JsonArray sobrepostas(Connection c, Integer membro, Integer familia, LocalDate data) throws SQLException {
        JsonArrayBuilder r = Json.createArrayBuilder();
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT tra_id, data_hora, quem, dizimo, recibo FROM tesouraria.fn_contribuicoes_sobrepostas(?, ?, ?)")) {
            inteiro(ps, 1, membro);
            inteiro(ps, 2, familia);
            ps.setDate(3, Date.valueOf(data));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    JsonObjectBuilder o = Json.createObjectBuilder().add("transacaoId", rs.getLong(1))
                            .add("dataHora", rs.getObject(2, OffsetDateTime.class).toString())
                            .add("quem", rs.getString(3)).add("dizimo", dinheiro(rs.getBigDecimal(4)));
                    String recibo = rs.getString(5);
                    if (recibo == null) {
                        o.addNull("recibo");
                    } else {
                        o.add("recibo", recibo);
                    }
                    r.add(o);
                }
            }
        }
        return r.build();
    }

    /** A meta sugerida para o ano: o alvo do ano anterior + 5% (null se não houver). */
    public static JsonObject alvoSugerido(Connection c, int igreja, int fundo, int ano) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("SELECT tesouraria.fn_alvo_sugerido(?, ?, ?)")) {
            ps.setInt(1, igreja);
            ps.setInt(2, fundo);
            ps.setInt(3, ano);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                BigDecimal v = rs.getBigDecimal(1);
                JsonObjectBuilder o = Json.createObjectBuilder();
                return (v == null ? o.addNull("valor") : o.add("valor", dinheiro(v))).build();
            }
        }
    }

    private static void inteiro(PreparedStatement ps, int i, Integer v) throws SQLException {
        if (v == null) {
            ps.setNull(i, Types.INTEGER);
        } else {
            ps.setInt(i, v);
        }
    }

    private static String dinheiro(BigDecimal v) {
        return v.setScale(2, java.math.RoundingMode.HALF_UP).toPlainString();
    }
}
