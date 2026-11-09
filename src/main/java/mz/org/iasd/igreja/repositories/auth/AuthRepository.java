package mz.org.iasd.igreja.repositories.auth;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.OffsetDateTime;
import java.util.Optional;

/**
 * Chamadas às funções de login e sessões da base de dados (V2 e V14). A API nunca lê as tabelas
 * de sessões nem a coluna da senha directamente.
 */
public final class AuthRepository {

    public record Credenciais(int usuarioId, String senhaHash, String estado) {
    }

    public record Renovacao(String resultado, Integer usuarioId, Long sessaoId) {
    }

    public record Recuperacao(int usuarioId, String telefone) {
    }

    private AuthRepository() {
    }

    public static OffsetDateTime bloqueadoAte(Connection c, String login) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("SELECT nucleo.fn_login_bloqueado_ate(?)")) {
            ps.setString(1, login);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getObject(1, OffsetDateTime.class);
            }
        }
    }

    public static Optional<Credenciais> credenciais(Connection c, String login) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT usu_id, senha_hash, estado::text FROM nucleo.fn_credenciais(?)")) {
            ps.setString(1, login);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next()
                        ? Optional.of(new Credenciais(rs.getInt(1), rs.getString(2), rs.getString(3)))
                        : Optional.empty();
            }
        }
    }

    public static void loginFalhou(Connection c, String login) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("SELECT nucleo.fn_login_falhou(?)")) {
            ps.setString(1, login);
            ps.execute();
        }
    }

    public static long abrirSessao(Connection c, int usuarioId, String refreshHash, String ip, String navegador)
            throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("SELECT nucleo.fn_abrir_sessao(?, ?, ?::inet, ?)")) {
            ps.setInt(1, usuarioId);
            ps.setString(2, refreshHash);
            ps.setString(3, ip);
            ps.setString(4, navegador);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getLong(1);
            }
        }
    }

    public static Renovacao renovarSessao(Connection c, String refreshHash, String novoHash, String ip, String navegador)
            throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT resultado, utilizador, sessao_id FROM nucleo.fn_renovar_sessao(?, ?, ?::inet, ?)")) {
            ps.setString(1, refreshHash);
            ps.setString(2, novoHash);
            ps.setString(3, ip);
            ps.setString(4, navegador);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return new Renovacao(rs.getString(1), rs.getObject(2, Integer.class), rs.getObject(3, Long.class));
            }
        }
    }

    public static void terminarSessao(Connection c, String refreshHash) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("SELECT nucleo.fn_terminar_sessao(?)")) {
            ps.setString(1, refreshHash);
            ps.execute();
        }
    }

    public static Optional<Recuperacao> pedirRecuperacao(Connection c, String login, String codigoHash)
            throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT utilizador, telefone FROM nucleo.fn_pedir_recuperacao(?, ?)")) {
            ps.setString(1, login);
            ps.setString(2, codigoHash);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(new Recuperacao(rs.getInt(1), rs.getString(2))) : Optional.empty();
            }
        }
    }

    /** @return OK, CODIGO_ERRADO ou EXPIRADO */
    public static String redefinirSenha(Connection c, String login, String codigoHash, String novaSenhaHash)
            throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("SELECT nucleo.fn_redefinir_senha(?, ?, ?)")) {
            ps.setString(1, login);
            ps.setString(2, codigoHash);
            ps.setString(3, novaSenhaHash);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getString(1);
            }
        }
    }
}
