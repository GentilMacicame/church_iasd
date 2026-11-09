package mz.org.iasd.igreja.infraestrutura.erros;

import java.sql.SQLException;

/** Erro devolvido pelo PostgreSQL (regra, permissão, restrição). Traduzido por {@link TradutorErrosSql}. */
public class ErroBaseDados extends RuntimeException {

    public ErroBaseDados(SQLException causa) {
        super(causa.getMessage(), causa);
    }

    public SQLException sql() {
        return (SQLException) getCause();
    }
}
