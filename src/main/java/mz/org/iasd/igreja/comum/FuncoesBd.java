package mz.org.iasd.igreja.comum;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

/** Chamada a uma função da base de dados com argumentos inteiros (ex.: {@code tesouraria.fn_confirmar_remessa}). */
public final class FuncoesBd {

    private FuncoesBd() {
    }

    public static void chamar(Connection c, String sql, long... args) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < args.length; i++) {
                ps.setLong(i + 1, args[i]);
            }
            ps.execute();
        }
    }
}
