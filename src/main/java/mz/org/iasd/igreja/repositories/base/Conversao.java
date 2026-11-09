package mz.org.iasd.igreja.repositories.base;

import java.io.StringReader;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.regex.Pattern;

import jakarta.json.Json;
import jakarta.json.JsonNumber;
import jakarta.json.JsonObject;
import jakarta.json.JsonObjectBuilder;
import jakarta.json.JsonString;
import jakarta.json.JsonValue;

import mz.org.iasd.igreja.comum.Nomes;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.models.catalogo.CatalogoGerado;
import mz.org.iasd.igreja.models.catalogo.Coluna;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.catalogo.Tipo;

/**
 * Conversão entre JSON e colunas. Na entrada valida só o FORMATO (dá 400 com o campo certo) e devolve o
 * valor como texto canónico, que vai como parâmetro com cast explícito ({@code ?::tipo}). Regras de negócio
 * ficam para a base de dados.
 */
public final class Conversao {

    private static final Pattern DINHEIRO = Pattern.compile("^-?\\d{1,14}(\\.\\d{1,2})?$");
    private static final Pattern DECIMAL = Pattern.compile("^-?\\d+(\\.\\d+)?$");

    private Conversao() {
    }

    // ------------------------------------------------------------------ entrada (JSON → parâmetro)

    /** @return o valor como texto para o parâmetro SQL, ou {@code null} para NULL */
    public static String paraParametro(Coluna c, JsonValue v) {
        if (v == null || v.getValueType() == JsonValue.ValueType.NULL) {
            return null;
        }
        try {
            return switch (c.tipo()) {
                case INT, BIGINT -> inteiro(c, v);
                case TEXTO -> texto(c, v);
                case DINHEIRO -> numeroTexto(c, v, DINHEIRO, "Valor em dinheiro inválido: use o formato 1500.50");
                case DECIMAL -> numeroTexto(c, v, DECIMAL, "Número inválido: use ponto decimal (ex.: -25.9653)");
                case DATA -> LocalDate.parse(texto(c, v)).toString();
                case DATA_HORA -> OffsetDateTime.parse(texto(c, v)).toString();
                case BOOLEANO -> booleano(c, v);
                case JSON -> v.toString();
                case ENUM -> enumerado(c, texto(c, v));
            };
        } catch (DateTimeParseException e) {
            throw ApiException.pedidoInvalido(c.tipo() == Tipo.DATA
                    ? "Data inválida: use o formato AAAA-MM-DD"
                    : "Data e hora inválidas: use ISO 8601 com fuso (ex.: 2026-11-09T10:00:00+02:00)", c.campo());
        }
    }

    /** Valor de um parâmetro de consulta (?campo=valor) para a coluna. */
    public static String paraParametro(Coluna c, String texto) {
        if (texto == null) {
            return null;
        }
        JsonValue v = switch (c.tipo()) {
            case INT, BIGINT -> {
                try {
                    yield Json.createValue(Long.parseLong(texto));
                } catch (NumberFormatException e) {
                    throw ApiException.pedidoInvalido("Tem de ser um número inteiro", c.campo());
                }
            }
            case BOOLEANO -> Boolean.parseBoolean(texto) ? JsonValue.TRUE : JsonValue.FALSE;
            default -> Json.createValue(texto);
        };
        return paraParametro(c, v);
    }

    private static String inteiro(Coluna c, JsonValue v) {
        if (v instanceof JsonNumber n && n.isIntegral()) {
            return Long.toString(n.longValueExact());
        }
        throw ApiException.pedidoInvalido("Tem de ser um número inteiro", c.campo());
    }

    private static String texto(Coluna c, JsonValue v) {
        if (v instanceof JsonString s) {
            return s.getString();
        }
        throw ApiException.pedidoInvalido("Tem de ser texto", c.campo());
    }

    private static String numeroTexto(Coluna c, JsonValue v, Pattern formato, String mensagem) {
        String s = texto(c, v);
        if (!formato.matcher(s).matches()) {
            throw ApiException.pedidoInvalido(mensagem, c.campo());
        }
        return s;
    }

    private static String booleano(Coluna c, JsonValue v) {
        if (v == JsonValue.TRUE || v == JsonValue.FALSE) {
            return Boolean.toString(v == JsonValue.TRUE);
        }
        throw ApiException.pedidoInvalido("Tem de ser true ou false", c.campo());
    }

    private static String enumerado(Coluna c, String valor) {
        List<String> valores = CatalogoGerado.ENUMS.get(c.tipoEnum());
        if (valores != null && !valores.contains(valor)) {
            throw ApiException.pedidoInvalido("Valor inválido. Use: " + String.join(", ", valores), c.campo());
        }
        return valor;
    }

    // ------------------------------------------------------------------ saída (linha → JSON)

    /** Uma linha de uma tabela do catálogo, com os campos pela ordem do contrato. */
    public static JsonObject linha(Tabela t, ResultSet rs) throws SQLException {
        JsonObjectBuilder o = Json.createObjectBuilder();
        int i = 1;
        for (Coluna c : t.colunas()) {
            o.add(c.campo(), valor(c.tipo(), rs, i++));
        }
        return o.build();
    }

    static JsonValue valor(Tipo tipo, ResultSet rs, int i) throws SQLException {
        return switch (tipo) {
            case INT, BIGINT -> {
                long n = rs.getLong(i);
                yield rs.wasNull() ? JsonValue.NULL : Json.createValue(n);
            }
            case DINHEIRO -> {
                BigDecimal d = rs.getBigDecimal(i);
                yield d == null ? JsonValue.NULL : Json.createValue(d.setScale(2, RoundingMode.HALF_UP).toPlainString());
            }
            case DECIMAL -> {
                BigDecimal d = rs.getBigDecimal(i);
                yield d == null ? JsonValue.NULL : Json.createValue(d.toPlainString());
            }
            case DATA -> {
                LocalDate d = rs.getObject(i, LocalDate.class);
                yield d == null ? JsonValue.NULL : Json.createValue(d.toString());
            }
            case DATA_HORA -> {
                OffsetDateTime d;
                try {
                    d = rs.getObject(i, OffsetDateTime.class);
                } catch (SQLException semFuso) {          // timestamp sem fuso (só em vistas)
                    String s = rs.getString(i);
                    yield s == null ? JsonValue.NULL : Json.createValue(s);
                }
                yield d == null ? JsonValue.NULL : Json.createValue(d.toString());
            }
            case BOOLEANO -> {
                boolean b = rs.getBoolean(i);
                yield rs.wasNull() ? JsonValue.NULL : (b ? JsonValue.TRUE : JsonValue.FALSE);
            }
            case JSON -> {
                String s = rs.getString(i);
                yield s == null ? JsonValue.NULL : Json.createReader(new StringReader(s)).readValue();
            }
            case TEXTO, ENUM -> {
                String s = rs.getString(i);
                yield s == null ? JsonValue.NULL : Json.createValue(s);
            }
        };
    }

    /**
     * Uma linha de uma vista (relatórios): nomes das colunas convertidos para camelCase e tipos deduzidos
     * do resultado. Valores DECIMAL saem como texto (dinheiro e percentagens nunca como float).
     */
    public static JsonObject linhaVista(ResultSet rs) throws SQLException {
        ResultSetMetaData md = rs.getMetaData();
        JsonObjectBuilder o = Json.createObjectBuilder();
        for (int i = 1; i <= md.getColumnCount(); i++) {
            Tipo tipo = switch (md.getColumnType(i)) {
                case Types.INTEGER, Types.SMALLINT, Types.BIGINT, Types.TINYINT -> Tipo.BIGINT;
                case Types.NUMERIC, Types.DECIMAL, Types.DOUBLE, Types.REAL, Types.FLOAT -> Tipo.DECIMAL;
                case Types.DATE -> Tipo.DATA;
                case Types.TIMESTAMP, Types.TIMESTAMP_WITH_TIMEZONE -> Tipo.DATA_HORA;
                case Types.BOOLEAN, Types.BIT -> Tipo.BOOLEANO;
                default -> Tipo.TEXTO;
            };
            o.add(Nomes.campo(md.getColumnLabel(i)), valor(tipo, rs, i));
        }
        return o.build();
    }
}
