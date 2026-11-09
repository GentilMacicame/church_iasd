package mz.org.iasd.igreja.infraestrutura.bd;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Optional;
import java.util.UUID;

/** Header {@code Idempotency-Key}: nucleo.fn_idempotencia_obter / fn_idempotencia_guardar (V14). */
public final class IdempotenciaRepository {

    public record RespostaGuardada(String metodo, String caminho, int estadoHttp, String respostaJson) {
    }

    private IdempotenciaRepository() {
    }

    public static Optional<RespostaGuardada> obter(Connection c, UUID chave) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT metodo, caminho, estado_http, resposta::text FROM nucleo.fn_idempotencia_obter(?)")) {
            ps.setObject(1, chave);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(new RespostaGuardada(rs.getString(1), rs.getString(2), rs.getInt(3), rs.getString(4)));
            }
        }
    }

    public static void guardar(Connection c, UUID chave, String metodo, String caminho, int estadoHttp,
                               String respostaJson) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT nucleo.fn_idempotencia_guardar(?, ?, ?, ?, ?::jsonb)")) {
            ps.setObject(1, chave);
            ps.setString(2, metodo);
            ps.setString(3, caminho);
            ps.setInt(4, estadoHttp);
            ps.setString(5, respostaJson);
            ps.execute();
        }
    }
}
