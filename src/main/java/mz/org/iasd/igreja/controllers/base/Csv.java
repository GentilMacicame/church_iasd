package mz.org.iasd.igreja.controllers.base;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import jakarta.json.JsonArray;
import jakarta.json.JsonObject;
import jakarta.json.JsonString;
import jakarta.json.JsonValue;

/** Relatórios em CSV (separador ";" e vírgula decimal, como o Excel em português). */
final class Csv {

    private Csv() {
    }

    static String de(JsonArray linhas) {
        Set<String> colunas = new LinkedHashSet<>();
        for (JsonValue v : linhas) {
            colunas.addAll(((JsonObject) v).keySet());
        }
        StringBuilder sb = new StringBuilder("﻿");          // BOM: o Excel abre com acentos
        sb.append(String.join(";", colunas)).append("\r\n");
        for (JsonValue v : linhas) {
            JsonObject o = (JsonObject) v;
            List<String> celulas = new ArrayList<>();
            for (String c : colunas) {
                celulas.add(celula(o.get(c)));
            }
            sb.append(String.join(";", celulas)).append("\r\n");
        }
        return sb.toString();
    }

    private static String celula(JsonValue v) {
        if (v == null || v.getValueType() == JsonValue.ValueType.NULL) {
            return "";
        }
        String s = v instanceof JsonString js ? js.getString() : v.toString();
        if (s.matches("^-?\\d+\\.\\d+$")) {
            s = s.replace('.', ',');
        } else if (!s.isEmpty() && "=+-@\t\r".indexOf(s.charAt(0)) >= 0 && !s.matches("^-?\\d+$")) {
            s = "'" + s;                  // texto que o Excel executaria como fórmula (=, +, -, @)
        }
        if (s.contains(";") || s.contains("\"") || s.contains("\n")) {
            s = "\"" + s.replace("\"", "\"\"") + "\"";
        }
        return s;
    }
}
