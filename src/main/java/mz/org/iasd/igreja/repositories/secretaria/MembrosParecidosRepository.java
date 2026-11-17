package mz.org.iasd.igreja.repositories.secretaria;

import java.sql.Array;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObjectBuilder;

/**
 * F-SEC-01 (V33) Registos de membros parecidos com os dados de um registo novo ou em edição (possíveis
 * duplicados). A função {@code nucleo.fn_membros_parecidos} é SECURITY INVOKER: cada utilizador só compara com os
 * membros que pode ver (RLS). Só avisa; quem regista decide.
 */
public final class MembrosParecidosRepository {

    private MembrosParecidosRepository() {
    }

    public record Pedido(String nome, String apelido, Date dataNascimento, String naturalidade,
                         String numeroIdentificacao, Integer excluirId) {
    }

    public static JsonArray procurar(Connection c, Pedido p) throws SQLException {
        String sql = "SELECT mem_id, mem_igr_id, nome, data_nascimento, naturalidade, numero_identificacao, estado::text, "
                + "pontos, motivos FROM nucleo.fn_membros_parecidos(?, ?, ?, ?, ?, ?)";
        JsonArrayBuilder r = Json.createArrayBuilder();
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, p.nome());
            ps.setString(2, p.apelido());
            ps.setDate(3, p.dataNascimento());
            ps.setString(4, p.naturalidade());
            ps.setString(5, p.numeroIdentificacao());
            if (p.excluirId() == null) {
                ps.setNull(6, Types.INTEGER);
            } else {
                ps.setInt(6, p.excluirId());
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    JsonObjectBuilder o = Json.createObjectBuilder()
                            .add("membroId", rs.getInt(1))
                            .add("igrejaId", rs.getInt(2))
                            .add("nome", rs.getString(3));
                    Date nasc = rs.getDate(4);
                    if (nasc == null) {
                        o.addNull("dataNascimento");
                    } else {
                        o.add("dataNascimento", nasc.toLocalDate().toString());
                    }
                    texto(o, "naturalidade", rs.getString(5));
                    texto(o, "numeroIdentificacao", rs.getString(6));
                    o.add("estado", rs.getString(7)).add("pontos", rs.getInt(8));
                    JsonArrayBuilder motivos = Json.createArrayBuilder();
                    Array a = rs.getArray(9);
                    if (a != null) {
                        for (Object m : (Object[]) a.getArray()) {
                            motivos.add(String.valueOf(m));
                        }
                    }
                    r.add(o.add("motivos", motivos));
                }
            }
        }
        return r.build();
    }

    private static void texto(JsonObjectBuilder o, String campo, String valor) {
        if (valor == null) {
            o.addNull(campo);
        } else {
            o.add(campo, valor);
        }
    }
}
