package mz.org.iasd.igreja.repositories.eu;

import java.sql.Array;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.TreeMap;
import java.util.TreeSet;

/** Dados de {@code GET /v1/eu}. Tudo lido com as permissões do próprio utilizador (RLS). */
public final class EuRepository {

    public record Usuario(int id, String nome, Integer membroId) {
    }

    public record Igreja(int id, String nome, List<String> perfis) {
    }

    public record Eu(Usuario usuario, List<Igreja> igrejas, Map<String, List<String>> permissoes) {
    }

    private EuRepository() {
    }

    public static Optional<Eu> carregar(Connection c) throws SQLException {
        Optional<Usuario> usuario = usuario(c);
        if (usuario.isEmpty()) {
            return Optional.empty();
        }
        Map<Integer, TreeSet<String>> permissoes = permissoes(c);
        Map<Integer, TreeSet<String>> perfis = perfis(c);

        TreeSet<Integer> ids = new TreeSet<>(permissoes.keySet());
        ids.addAll(perfis.keySet());
        Map<Integer, String> nomes = nomesIgrejas(c, ids);

        List<Igreja> igrejas = new ArrayList<>();
        for (Integer id : ids) {
            igrejas.add(new Igreja(id, nomes.getOrDefault(id, "Igreja " + id),
                    List.copyOf(perfis.getOrDefault(id, new TreeSet<>()))));
        }
        Map<String, List<String>> porIgreja = new LinkedHashMap<>();
        permissoes.forEach((igr, codigos) -> porIgreja.put(igr.toString(), List.copyOf(codigos)));
        return Optional.of(new Eu(usuario.get(), igrejas, porIgreja));
    }

    static Optional<Usuario> usuario(Connection c) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT usu_id, usu_nome, usu_mem_id FROM nucleo.usuario "
                        + "WHERE usu_id = nucleo.fn_usuario_sessao() AND usu_end_date IS NULL AND usu_estado = 'ACTIVO'");
             ResultSet rs = ps.executeQuery()) {
            return rs.next()
                    ? Optional.of(new Usuario(rs.getInt(1), rs.getString(2), rs.getObject(3, Integer.class)))
                    : Optional.empty();
        }
    }

    public static Map<Integer, TreeSet<String>> permissoes(Connection c) throws SQLException {
        Map<Integer, TreeSet<String>> r = new TreeMap<>();
        try (PreparedStatement ps = c.prepareStatement("SELECT igr_id, codigo FROM nucleo.fn_minhas_permissoes()");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                r.computeIfAbsent(rs.getInt(1), k -> new TreeSet<>()).add(rs.getString(2));
            }
        }
        return r;
    }

    /**
     * Perfis atribuídos por igreja. Cada utilizador vê os seus próprios perfis pela política
     * {@code pol_uig_proprio} (migração V15), mesmo sem {@code nucleo.usuario_igreja.ler}.
     */
    static Map<Integer, TreeSet<String>> perfis(Connection c) throws SQLException {
        Map<Integer, TreeSet<String>> r = new TreeMap<>();
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT u.uig_igr_id, p.per_nome FROM nucleo.usuario_igreja u "
                        + "JOIN nucleo.perfil p ON p.per_id = u.uig_per_id "
                        + "WHERE u.uig_usu_id = nucleo.fn_usuario_sessao() AND u.uig_end_date IS NULL "
                        + "AND u.uig_estado = 'ACTIVO'");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                r.computeIfAbsent(rs.getInt(1), k -> new TreeSet<>()).add(rs.getString(2));
            }
        }
        return r;
    }

    static Map<Integer, String> nomesIgrejas(Connection c, Collection<Integer> ids) throws SQLException {
        Map<Integer, String> r = new TreeMap<>();
        if (ids.isEmpty()) {
            return r;
        }
        Array array = c.createArrayOf("integer", ids.toArray(new Integer[0]));
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT igr_id, igr_nome FROM organizacao.igreja WHERE igr_id = ANY (?)")) {
            ps.setArray(1, array);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    r.put(rs.getInt(1), rs.getString(2));
                }
            }
        } finally {
            array.free();
        }
        return r;
    }
}
