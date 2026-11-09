package mz.org.iasd.igreja.crud;

import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObject;
import jakarta.json.JsonValue;

import mz.org.iasd.igreja.comum.Paginacao;
import mz.org.iasd.igreja.comum.Sql;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;

/**
 * Operações-padrão sobre qualquer tabela do catálogo: listar (com filtros e paginação por cursor), ler,
 * criar, alterar, terminar e reactivar. Não há DELETE. Não se verifica nenhuma permissão aqui: o
 * PostgreSQL decide (RLS e triggers) e os erros são traduzidos por {@code TradutorErrosSql}.
 *
 * Todos os valores do pedido vão como parâmetros ({@code ?::tipo}); só se concatenam nomes de colunas
 * e tabelas vindos do catálogo gerado.
 */
public final class TabelaRepository {

    /** Valor a gravar numa coluna (texto canónico + cast SQL). */
    public record Valor(String coluna, String valor, String cast) {
        public static Valor de(Coluna c, String valor) {
            return new Valor(c.coluna(), valor, c.tipo().sql(c.tipoEnum()));
        }

        /** Valor pelo nome do campo JSON (ex.: {@code Valor.campo(t, "estado", "CONFIRMADA")}). */
        public static Valor campo(Tabela t, String campo, String valor) {
            Coluna c = t.porCampo().get(campo);
            if (c == null) {
                throw new IllegalArgumentException("Campo " + campo + " não existe em " + t.nomeCompleto());
            }
            return de(c, valor);
        }
    }

    private static final Set<String> PARAMETROS_GERAIS = Set.of("limite", "depois", "ordem", "incluirTerminados",
            "desde", "ate", "q", "formato");
    private static final int MAX_FILHOS = 1000;

    private TabelaRepository() {
    }

    // ------------------------------------------------------------------ listar

    public static JsonObject listar(Connection c, Tabela t, Map<String, String> p) throws SQLException {
        int limite = Paginacao.limite(inteiro(p.get("limite"), "limite"));
        Ordem ordem = Ordem.de(t, p.get("ordem"));
        Cursor cursor = Cursor.de(p.get("depois"), ordem);

        Sql sql = new Sql("SELECT " + t.listaSelect() + ", " + ordem.coluna().coluna() + "::text, "
                + t.pk().coluna() + " FROM " + t.nomeCompleto() + " WHERE TRUE");
        if (!"true".equals(p.get("incluirTerminados"))) {
            sql.e("AND " + t.colEndDate() + " IS NULL");
        }
        Map<String, Coluna> filtros = t.filtrosIgualdade();
        if (t.colIgreja() != null && filtros.containsKey("igrejaId") && p.get("igrejaId") == null) {
            throw ApiException.pedidoInvalido("Indique a igreja (igrejaId)", "igrejaId");
        }
        for (Map.Entry<String, Coluna> f : filtros.entrySet()) {
            String v = p.get(f.getKey());
            if (v != null) {
                sql.e("AND " + f.getValue().coluna() + " = " + f.getValue().parametro(),
                        Conversao.paraParametro(f.getValue(), v));
            }
        }
        filtroDatas(t, p, sql);
        if ("membro".equals(t.nome()) && p.get("q") != null && !p.get("q").isBlank()) {
            sql.e("AND (mem_nome || ' ' || mem_apelido) ILIKE ?", "%" + escaparLike(p.get("q").trim()) + "%");
        }
        if (cursor != null) {
            String op = ordem.descendente() ? "<" : ">";
            if (ordem.coluna() == t.pk()) {
                sql.e("AND " + t.pk().coluna() + " " + op + " ?::bigint", cursor.id());
            } else {
                sql.e("AND (" + ordem.coluna().coluna() + ", " + t.pk().coluna() + ") " + op + " ("
                        + ordem.coluna().parametro() + ", ?::bigint)", cursor.valor(), cursor.id());
            }
        }
        String dir = ordem.descendente() ? " DESC" : "";
        sql.e("ORDER BY " + ordem.coluna().coluna() + dir + ", " + t.pk().coluna() + dir + " LIMIT ?::integer",
                Integer.toString(limite + 1));

        JsonArrayBuilder dados = Json.createArrayBuilder();
        int n = 0;
        String proximo = null;
        int extra = t.colunas().size();
        try (PreparedStatement ps = sql.preparar(c); ResultSet rs = ps.executeQuery()) {
            String ultimoValor = null;
            long ultimoId = 0;
            while (rs.next()) {
                if (n == limite) {
                    proximo = new Cursor(ordem.campo(), ultimoValor, Long.toString(ultimoId)).codificar();
                    break;
                }
                dados.add(Conversao.linha(t, rs));
                ultimoValor = rs.getString(extra + 1);
                ultimoId = rs.getLong(extra + 2);
                n++;
            }
        }
        return Json.createObjectBuilder().add("dados", dados)
                .add("proximo", proximo == null ? JsonValue.NULL : Json.createValue(proximo)).build();
    }

    private static void filtroDatas(Tabela t, Map<String, String> p, Sql sql) {
        String desde = p.get("desde");
        String ate = p.get("ate");
        if (desde == null && ate == null) {
            return;
        }
        Coluna col = t.colunaData().orElseThrow(
                () -> ApiException.pedidoInvalido("Este recurso não tem filtro por datas", desde != null ? "desde" : "ate"));
        boolean comHora = col.tipo() == Tipo.DATA_HORA;
        if (desde != null) {
            sql.e("AND " + col.coluna() + (comHora ? " >= ((?::date)::timestamp AT TIME ZONE 'Africa/Maputo')" : " >= ?::date"),
                    data(desde, "desde"));
        }
        if (ate != null) {
            sql.e("AND " + col.coluna() + (comHora ? " < ((?::date + 1)::timestamp AT TIME ZONE 'Africa/Maputo')" : " <= ?::date"),
                    data(ate, "ate"));
        }
    }

    // ------------------------------------------------------------------ ler

    public static Optional<JsonObject> obter(Connection c, Tabela t, long id) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("SELECT " + t.listaSelect() + " FROM " + t.nomeCompleto()
                + " WHERE " + t.pk().coluna() + " = ?")) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(Conversao.linha(t, rs)) : Optional.empty();
            }
        }
    }

    public static JsonObject obterOu404(Connection c, Tabela t, long id) throws SQLException {
        return obter(c, t, id).orElseThrow(ApiException::naoEncontrado);
    }

    /** Linhas activas de uma tabela-filho (rotas aninhadas, ex.: votos de uma reunião). */
    public static JsonArray filhos(Connection c, Tabela filho, String colunaPai, long idPai) throws SQLException {
        JsonArrayBuilder r = Json.createArrayBuilder();
        try (PreparedStatement ps = c.prepareStatement("SELECT " + filho.listaSelect() + " FROM " + filho.nomeCompleto()
                + " WHERE " + colunaPai + " = ? AND " + filho.colEndDate() + " IS NULL ORDER BY " + filho.pk().coluna()
                + " LIMIT " + MAX_FILHOS)) {
            ps.setLong(1, idPai);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    r.add(Conversao.linha(filho, rs));
                }
            }
        }
        return r.build();
    }

    // ------------------------------------------------------------------ criar e alterar

    /** Valores a gravar a partir do corpo JSON: campos desconhecidos → 400; campos só de leitura são ignorados. */
    public static List<Valor> valoresDoCorpo(Tabela t, JsonObject corpo, Set<String> camposIgnorados) {
        Map<String, Coluna> porCampo = t.porCampo();
        List<Valor> r = new ArrayList<>();
        for (Map.Entry<String, JsonValue> e : corpo.entrySet()) {
            if (camposIgnorados.contains(e.getKey())) {
                continue;
            }
            Coluna col = porCampo.get(e.getKey());
            if (col == null) {
                throw ApiException.pedidoInvalido("Campo desconhecido: " + e.getKey(), e.getKey());
            }
            if (col.escrita()) {
                r.add(Valor.de(col, Conversao.paraParametro(col, e.getValue())));
            }
        }
        return r;
    }

    public static JsonObject criar(Connection c, Tabela t, JsonObject corpo) throws SQLException {
        return criar(c, t, valoresDoCorpo(t, corpo, Set.of()));
    }

    /**
     * INSERT ... RETURNING. Os campos obrigatórios não são verificados aqui: alguns são preenchidos pelos
     * triggers (ex.: M.M. do relatório); a falta de um campo chega como 23502 → 400 campo_obrigatorio.
     */
    public static JsonObject criar(Connection c, Tabela t, List<Valor> valores) throws SQLException {
        StringBuilder colunas = new StringBuilder();
        StringBuilder parametros = new StringBuilder();
        List<Object> args = new ArrayList<>();
        for (Valor v : valores) {
            colunas.append(colunas.isEmpty() ? "" : ", ").append(v.coluna());
            parametros.append(parametros.isEmpty() ? "" : ", ").append("?::").append(v.cast());
            args.add(v.valor());
        }
        String sql = "INSERT INTO " + t.nomeCompleto()
                + (valores.isEmpty() ? " DEFAULT VALUES" : " (" + colunas + ") VALUES (" + parametros + ")")
                + " RETURNING " + t.listaSelect();
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < args.size(); i++) {
                ps.setObject(i + 1, args.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return Conversao.linha(t, rs);
            }
        }
    }

    public static JsonObject alterar(Connection c, Tabela t, long id, JsonObject corpo) throws SQLException {
        List<Valor> valores = valoresDoCorpo(t, corpo, Set.of());
        if (valores.isEmpty()) {
            throw ApiException.pedidoInvalido("Nenhum campo para alterar", null);
        }
        return actualizar(c, t, id, valores, null);
    }

    /**
     * UPDATE de uma linha. Sem linhas afectadas: 404 se não for visível, 403 se for visível mas a política
     * de alteração a recusar (o PostgreSQL ignora em silêncio as linhas que a RLS não deixa alterar).
     *
     * @param condicaoExtra condição fixa adicional (ex.: {@code end_date IS NULL}) ou {@code null}
     */
    public static JsonObject actualizar(Connection c, Tabela t, long id, List<Valor> valores, String condicaoExtra)
            throws SQLException {
        StringBuilder set = new StringBuilder();
        for (Valor v : valores) {
            set.append(set.isEmpty() ? "" : ", ").append(v.coluna()).append(" = ")
                    .append(v.valor() == null && v.cast() == null ? "NULL" : "?::" + v.cast());
        }
        String sql = "UPDATE " + t.nomeCompleto() + " SET " + set + " WHERE " + t.pk().coluna() + " = ?"
                + (condicaoExtra == null ? "" : " AND " + condicaoExtra) + " RETURNING " + t.listaSelect();
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            int i = 1;
            for (Valor v : valores) {
                if (!(v.valor() == null && v.cast() == null)) {
                    ps.setObject(i++, v.valor());
                }
            }
            ps.setLong(i, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Conversao.linha(t, rs);
                }
            }
        }
        obterOu404(c, t, id);
        throw new ApiException(403, "sem_permissao", "Sem permissão para alterar este registo", null);
    }

    // ------------------------------------------------------------------ terminar e reactivar

    public static JsonObject terminar(Connection c, Tabela t, long id) throws SQLException {
        return mudarFim(c, t, id, true);
    }

    public static JsonObject reactivar(Connection c, Tabela t, long id) throws SQLException {
        return mudarFim(c, t, id, false);
    }

    private static JsonObject mudarFim(Connection c, Tabela t, long id, boolean terminar) throws SQLException {
        String sql = "UPDATE " + t.nomeCompleto() + " SET " + t.colEndDate() + (terminar ? " = now()" : " = NULL")
                + " WHERE " + t.pk().coluna() + " = ? AND " + t.colEndDate() + (terminar ? " IS NULL" : " IS NOT NULL")
                + " RETURNING " + t.listaSelect();
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Conversao.linha(t, rs);
                }
            }
        }
        JsonObject actual = obterOu404(c, t, id);
        boolean terminado = !actual.isNull("endDate");
        if (terminar && terminado) {
            throw new ApiException(422, "regra_negocio", "O registo já está terminado", null);
        }
        if (!terminar && !terminado) {
            throw new ApiException(422, "regra_negocio", "O registo não está terminado", null);
        }
        throw new ApiException(403, "sem_permissao", "Sem permissão para " + (terminar ? "terminar" : "reactivar")
                + " este registo", null);
    }

    // ------------------------------------------------------------------ apoio

    private static Integer inteiro(String v, String campo) {
        if (v == null) {
            return null;
        }
        try {
            return Integer.valueOf(v);
        } catch (NumberFormatException e) {
            throw ApiException.pedidoInvalido("Tem de ser um número inteiro", campo);
        }
    }

    private static String data(String v, String campo) {
        try {
            return LocalDate.parse(v).toString();
        } catch (DateTimeParseException e) {
            throw ApiException.pedidoInvalido("Data inválida: use o formato AAAA-MM-DD", campo);
        }
    }

    static String escaparLike(String s) {
        return s.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }

    static boolean parametroGeral(String nome) {
        return PARAMETROS_GERAIS.contains(nome);
    }

    /** Ordenação pedida em {@code ?ordem=campo} ou {@code -campo}; só colunas NOT NULL (cursor fiável). */
    record Ordem(Coluna coluna, boolean descendente) {
        static Ordem de(Tabela t, String pedido) {
            if (pedido == null || pedido.isBlank()) {
                return new Ordem(t.pk(), false);
            }
            boolean desc = pedido.startsWith("-");
            String campo = desc ? pedido.substring(1) : pedido;
            Coluna c = t.porCampo().get(campo);
            if (c == null || !c.naoNula() || c.tipo() == Tipo.JSON) {
                throw ApiException.pedidoInvalido("Não é possível ordenar por " + campo, "ordem");
            }
            return new Ordem(c, desc);
        }

        String campo() {
            return (descendente ? "-" : "") + coluna.campo();
        }
    }

    /** Cursor opaco: ordenação, último valor e último id da página. */
    record Cursor(String ordem, String valor, String id) {
        String codificar() {
            String json = Json.createObjectBuilder().add("o", ordem)
                    .add("v", valor == null ? JsonValue.NULL : Json.createValue(valor)).add("id", id).build().toString();
            return Base64.getUrlEncoder().withoutPadding().encodeToString(json.getBytes(StandardCharsets.UTF_8));
        }

        static Cursor de(String texto, Ordem ordem) {
            if (texto == null || texto.isBlank()) {
                return null;
            }
            try {
                String json = new String(Base64.getUrlDecoder().decode(texto), StandardCharsets.UTF_8);
                JsonObject o = Json.createReader(new java.io.StringReader(json)).readObject();
                if (!ordem.campo().equals(o.getString("o"))) {
                    throw ApiException.pedidoInvalido("O cursor é de outra ordenação", "depois");
                }
                Long.parseLong(o.getString("id"));
                return new Cursor(o.getString("o"), o.isNull("v") ? null : o.getString("v"), o.getString("id"));
            } catch (ApiException e) {
                throw e;
            } catch (RuntimeException e) {
                throw ApiException.pedidoInvalido("Cursor de paginação inválido", "depois");
            }
        }
    }
}
