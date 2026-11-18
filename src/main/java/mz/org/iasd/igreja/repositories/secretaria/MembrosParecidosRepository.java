package mz.org.iasd.igreja.repositories.secretaria;

import java.sql.Array;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.HashMap;
import java.util.Map;

import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObject;
import jakarta.json.JsonObjectBuilder;

/**
 * F-SEC-01 (V33) Registos de membros parecidos com os dados de um registo novo ou em edição (possíveis
 * duplicados). A função {@code nucleo.fn_membros_parecidos} é SECURITY INVOKER: cada utilizador só compara com os
 * membros que pode ver (RLS). Só avisa; quem regista decide.
 *
 * <p>V43: junta {@code nucleo.fn_membro_existente} (todas as igrejas): o mesmo membro já registado — mesmo documento,
 * ou mesmo nome e data de nascimento — vem com {@code existe = true} (a base de dados recusa registá-lo outra vez).
 * Dos que estão em igrejas que o utilizador não vê, só o nome e a igreja ({@code membroId} nulo).
 */
public final class MembrosParecidosRepository {

    private MembrosParecidosRepository() {
    }

    public record Pedido(String nome, String apelido, Date dataNascimento, String naturalidade,
                         String numeroIdentificacao, Integer excluirId, String telefone) {

        /** Sem telemóvel (como antes da V45). */
        public Pedido(String nome, String apelido, Date dataNascimento, String naturalidade, String numeroIdentificacao, Integer excluirId) {
            this(nome, apelido, dataNascimento, naturalidade, numeroIdentificacao, excluirId, null);
        }
    }

    public static JsonArray procurar(Connection c, Pedido p) throws SQLException {
        // o mesmo membro já registado (em qualquer igreja): id visível → igreja e motivo; não visível → só nome e igreja
        Map<Integer, String[]> existentes = new HashMap<>();
        JsonArrayBuilder deFora = Json.createArrayBuilder();
        String sqlExiste = "SELECT mem_id, igr_id, igreja, nome, motivo, visivel FROM nucleo.fn_membro_existente(?, ?, ?, ?, ?)";
        try (PreparedStatement ps = c.prepareStatement(sqlExiste)) {
            ps.setString(1, p.nome());
            ps.setString(2, p.apelido());
            ps.setDate(3, p.dataNascimento());
            ps.setString(4, p.numeroIdentificacao());
            excluir(ps, 5, p.excluirId());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    if (rs.getBoolean(6)) {
                        existentes.put(rs.getInt(1), new String[] {rs.getString(3), rs.getString(5)});
                    } else {
                        deFora.add(Json.createObjectBuilder().addNull("membroId").add("igrejaId", rs.getInt(2))
                                .add("igreja", rs.getString(3)).add("nome", rs.getString(4)).add("pontos", 100)
                                .add("existe", true).add("motivos", Json.createArrayBuilder().add(rs.getString(5))));
                    }
                }
            }
        }
        String sql = "SELECT mem_id, mem_igr_id, nome, data_nascimento, naturalidade, numero_identificacao, estado::text, "
                + "pontos, motivos FROM nucleo.fn_membros_parecidos(?, ?, ?, ?, ?, ?, ?)";
        JsonArrayBuilder r = Json.createArrayBuilder();
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, p.nome());
            ps.setString(2, p.apelido());
            ps.setDate(3, p.dataNascimento());
            ps.setString(4, p.naturalidade());
            ps.setString(5, p.numeroIdentificacao());
            excluir(ps, 6, p.excluirId());
            ps.setString(7, p.telefone());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String[] existe = existentes.remove(rs.getInt(1));
                    JsonObjectBuilder o = Json.createObjectBuilder()
                            .add("membroId", rs.getInt(1))
                            .add("existe", existe != null)
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
                    if (existe != null) {
                        o.add("igreja", existe[0]);
                    }
                    r.add(o.add("motivos", motivos));
                }
            }
        }
        // o mesmo membro, visível, que a lista dos parecidos não trouxe (limite de 10): acrescenta-se com o essencial
        if (!existentes.isEmpty()) {
            String sqlUm = "SELECT mem_igr_id, mem_nome || ' ' || mem_apelido, mem_data_nascimento, mem_estado::text "
                    + "FROM secretaria.membro WHERE mem_id = ?";
            try (PreparedStatement ps = c.prepareStatement(sqlUm)) {
                for (Map.Entry<Integer, String[]> e : existentes.entrySet()) {
                    ps.setInt(1, e.getKey());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            JsonObjectBuilder o = Json.createObjectBuilder().add("membroId", e.getKey())
                                    .add("igrejaId", rs.getInt(1)).add("igreja", e.getValue()[0]).add("nome", rs.getString(2))
                                    .add("estado", rs.getString(4)).add("pontos", 100).add("existe", true)
                                    .add("motivos", Json.createArrayBuilder().add(e.getValue()[1]));
                            Date nasc = rs.getDate(3);
                            if (nasc != null) {
                                o.add("dataNascimento", nasc.toLocalDate().toString());
                            }
                            r.add(o);
                        }
                    }
                }
            }
        }
        for (JsonObject o : deFora.build().getValuesAs(JsonObject.class)) {
            r.add(o);
        }
        return r.build();
    }

    private static void excluir(PreparedStatement ps, int i, Integer id) throws SQLException {
        if (id == null) {
            ps.setNull(i, Types.INTEGER);
        } else {
            ps.setInt(i, id);
        }
    }

    private static void texto(JsonObjectBuilder o, String campo, String valor) {
        if (valor == null) {
            o.addNull(campo);
        } else {
            o.add(campo, valor);
        }
    }
}
