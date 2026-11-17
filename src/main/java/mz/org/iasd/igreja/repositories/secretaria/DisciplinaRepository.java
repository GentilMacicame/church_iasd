package mz.org.iasd.igreja.repositories.secretaria;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * V41 O motivo de uma censura: lido só pela função da base, que confirma a permissão e regista a consulta em
 * {@code nucleo.acesso_confidencial}. Não existe ou não é visível → SQLSTATE P0002 (a API responde 404).
 */
public final class DisciplinaRepository {

    private DisciplinaRepository() {
    }

    public static String motivo(Connection c, long id) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("SELECT secretaria.fn_disciplina_motivo(?::integer)")) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getString(1);
            }
        }
    }
}
