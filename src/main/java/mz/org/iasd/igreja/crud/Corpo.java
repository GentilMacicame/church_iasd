package mz.org.iasd.igreja.crud;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.regex.Pattern;

import jakarta.json.JsonArray;
import jakarta.json.JsonNumber;
import jakarta.json.JsonObject;
import jakarta.json.JsonString;
import jakarta.json.JsonValue;

import mz.org.iasd.igreja.infraestrutura.erros.ApiException;

/** Leitura dos campos dos corpos das acções (validação de formato, 400 com o campo). */
public final class Corpo {

    private static final Pattern DINHEIRO = Pattern.compile("^\\d{1,14}(\\.\\d{1,2})?$");

    private Corpo() {
    }

    /** Corpo do pedido em texto → JSON ({@code null} se vier vazio). JSON mal formado → 400. */
    public static JsonValue ler(String texto) {
        if (texto == null || texto.isBlank()) {
            return JsonValue.NULL;
        }
        try (var leitor = jakarta.json.Json.createReader(new java.io.StringReader(texto))) {
            return leitor.readValue();
        } catch (jakarta.json.JsonException e) {
            throw ApiException.pedidoInvalido("JSON mal formado", null);
        }
    }

    public static JsonObject objecto(JsonValue v) {
        if (v instanceof JsonObject o) {
            return o;
        }
        throw ApiException.pedidoInvalido("O corpo do pedido tem de ser um objecto JSON", null);
    }

    public static JsonArray lista(JsonValue v, String campo) {
        if (v instanceof JsonArray a) {
            return a;
        }
        throw ApiException.pedidoInvalido("Tem de ser uma lista", campo);
    }

    public static boolean tem(JsonObject o, String campo) {
        return o.containsKey(campo) && !o.isNull(campo);
    }

    public static long inteiro(JsonObject o, String campo) {
        if (tem(o, campo) && o.get(campo) instanceof JsonNumber n && n.isIntegral()) {
            return n.longValueExact();
        }
        throw falta(o, campo, "Tem de ser um número inteiro");
    }

    public static Long inteiroOpcional(JsonObject o, String campo) {
        return tem(o, campo) ? inteiro(o, campo) : null;
    }

    public static String texto(JsonObject o, String campo) {
        if (tem(o, campo) && o.get(campo) instanceof JsonString s && !s.getString().isBlank()) {
            return s.getString();
        }
        throw falta(o, campo, "Tem de ser texto");
    }

    public static String textoOpcional(JsonObject o, String campo) {
        return tem(o, campo) ? texto(o, campo) : null;
    }

    public static boolean booleano(JsonObject o, String campo) {
        if (tem(o, campo) && (o.get(campo) == JsonValue.TRUE || o.get(campo) == JsonValue.FALSE)) {
            return o.get(campo) == JsonValue.TRUE;
        }
        throw falta(o, campo, "Tem de ser true ou false");
    }

    public static LocalDate data(JsonObject o, String campo) {
        try {
            return LocalDate.parse(texto(o, campo));
        } catch (DateTimeParseException e) {
            throw ApiException.pedidoInvalido("Data inválida: use o formato AAAA-MM-DD", campo);
        }
    }

    /** Dinheiro positivo ou zero, em texto com até 2 casas ("650.00"). */
    public static BigDecimal dinheiro(JsonObject o, String campo) {
        String s = texto(o, campo);
        if (!DINHEIRO.matcher(s).matches()) {
            throw ApiException.pedidoInvalido("Valor em dinheiro inválido: use o formato 1500.50", campo);
        }
        return new BigDecimal(s);
    }

    public static BigDecimal dinheiroOpcional(JsonObject o, String campo) {
        return tem(o, campo) ? dinheiro(o, campo) : null;
    }

    private static ApiException falta(JsonObject o, String campo, String formato) {
        return tem(o, campo)
                ? ApiException.pedidoInvalido(formato, campo)
                : new ApiException(400, "campo_obrigatorio", "Falta preencher: " + campo, campo);
    }
}
