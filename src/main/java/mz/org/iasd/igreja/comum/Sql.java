package mz.org.iasd.igreja.comum;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * Montagem de consultas com filtros opcionais. Só se concatenam fragmentos de SQL fixos,
 * escritos no código; os valores vindos do pedido vão SEMPRE como parâmetros ({@code ?}).
 */
public final class Sql {

    private final StringBuilder texto;
    private final List<Object> parametros = new ArrayList<>();

    public Sql(String inicio) {
        this.texto = new StringBuilder(inicio);
    }

    /** Acrescenta um fragmento fixo com os seus parâmetros. */
    public Sql e(String fragmento, Object... valores) {
        texto.append(' ').append(fragmento);
        parametros.addAll(List.of(valores));
        return this;
    }

    /** Acrescenta o fragmento só se o valor não for nulo. */
    public Sql seDado(Object valor, String fragmento) {
        if (valor != null) {
            e(fragmento, valor);
        }
        return this;
    }

    public PreparedStatement preparar(Connection ligacao) throws SQLException {
        PreparedStatement ps = ligacao.prepareStatement(texto.toString());
        for (int i = 0; i < parametros.size(); i++) {
            ps.setObject(i + 1, parametros.get(i));
        }
        return ps;
    }

    @Override
    public String toString() {
        return texto.toString();
    }
}
