package mz.org.iasd.igreja.crud;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;

import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonArrayBuilder;

import mz.org.iasd.igreja.comum.Sql;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;

/**
 * Um relatório ({@code x-vista} no contrato) lido de uma vista {@code security_invoker}: cada utilizador só
 * vê as linhas das igrejas a que tem acesso (RLS das tabelas por baixo).
 *
 * @param vista        nome completo da vista
 * @param filtroIgreja expressão para {@code ?igrejaId} com um ou dois {@code ?} (null = sem esse filtro)
 * @param colAno       coluna para {@code ?ano} (ou null)
 * @param colMes       coluna para {@code ?mes} (ou null)
 * @param colTrimestre coluna para {@code ?trimestreId} (ou null)
 * @param ordem        ORDER BY fixo
 */
public record Relatorio(String vista, String filtroIgreja, String colAno, String colMes, String colTrimestre,
                        String ordem) {

    private static final int MAX_LINHAS = 5000;

    public static Relatorio porIgreja(String vista, String filtroIgreja, String ordem) {
        return new Relatorio(vista, filtroIgreja, null, null, null, ordem);
    }

    public Relatorio comAnoMes(String ano, String mes) {
        return new Relatorio(vista, filtroIgreja, ano, mes, colTrimestre, ordem);
    }

    public Relatorio comTrimestre(String trimestre) {
        return new Relatorio(vista, filtroIgreja, colAno, colMes, trimestre, ordem);
    }

    public JsonArray consultar(Connection c, Map<String, String> p) throws SQLException {
        Sql sql = new Sql("SELECT * FROM " + vista + " WHERE TRUE");
        String igreja = p.get("igrejaId");
        if (igreja != null && filtroIgreja != null) {
            String id = inteiro(igreja, "igrejaId");
            Object[] args = filtroIgreja.chars().filter(ch -> ch == '?').mapToObj(x -> id).toArray();
            sql.e("AND " + filtroIgreja.replace("?", "?::integer"), args);
        }
        filtro(sql, colAno, p.get("ano"), "ano");
        filtro(sql, colMes, p.get("mes"), "mes");
        filtro(sql, colTrimestre, p.get("trimestreId"), "trimestreId");
        sql.e("ORDER BY " + ordem + " LIMIT " + MAX_LINHAS);

        JsonArrayBuilder r = Json.createArrayBuilder();
        try (PreparedStatement ps = sql.preparar(c); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                r.add(Conversao.linhaVista(rs));
            }
        }
        return r.build();
    }

    private static void filtro(Sql sql, String coluna, String valor, String nome) {
        if (valor == null) {
            return;
        }
        if (coluna == null) {
            throw ApiException.pedidoInvalido("Este relatório não tem o filtro " + nome, nome);
        }
        sql.e("AND " + coluna + " = ?::integer", inteiro(valor, nome));
    }

    private static String inteiro(String v, String campo) {
        try {
            return Long.toString(Long.parseLong(v));
        } catch (NumberFormatException e) {
            throw ApiException.pedidoInvalido("Tem de ser um número inteiro", campo);
        }
    }
}
