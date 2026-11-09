package mz.org.iasd.igreja.services.tesouraria;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonObject;
import jakarta.json.JsonValue;

import mz.org.iasd.igreja.comum.FuncoesBd;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.repositories.base.Conversao;
import mz.org.iasd.igreja.controllers.base.Corpo;
import mz.org.iasd.igreja.repositories.base.TabelaRepository;
import mz.org.iasd.igreja.repositories.base.TabelaRepository.Valor;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.models.tesouraria.Transacao;
import mz.org.iasd.igreja.models.tesouraria.TransacaoLinha;
import mz.org.iasd.igreja.models.tesouraria.Recibo;

/**
 * Operações sobre transacções que não são um simples INSERT/UPDATE. Usado também pela Escola Sabatina
 * (ofertas do relatório do sábado). As regras — soma das linhas, fundos da Associação, mês fechado,
 * aprovação por outra pessoa — são verificadas pela base de dados.
 */
public final class TransacoesService {

    public static final Tabela TRANSACAO = Catalogo.de(Transacao.class);
    public static final Tabela LINHA = Catalogo.de(TransacaoLinha.class);
    public static final Tabela RECIBO = Catalogo.de(Recibo.class);

    private TransacoesService() {
    }

    /** F-TES-03: cabeçalho + linhas por fundo na mesma transacção (a soma é verificada no COMMIT). */
    public static JsonObject criar(Connection c, JsonObject corpo) throws SQLException {
        JsonArray linhas = Corpo.tem(corpo, "linhas") ? Corpo.lista(corpo.get("linhas"), "linhas") : JsonValue.EMPTY_JSON_ARRAY;
        JsonObject cab = TabelaRepository.criar(c, TRANSACAO, TabelaRepository.valoresDoCorpo(TRANSACAO, corpo, Set.of("linhas")));
        long id = cab.getJsonNumber("id").longValue();
        for (JsonValue v : linhas) {
            JsonObject linha = Corpo.objecto(v);
            if (linha.containsKey("transacaoId")) {
                throw ApiException.pedidoInvalido("As linhas não indicam a transacção", "transacaoId");
            }
            List<Valor> valores = new ArrayList<>(TabelaRepository.valoresDoCorpo(LINHA, linha, Set.of()));
            valores.add(Valor.campo(LINHA, "transacaoId", Long.toString(id)));
            TabelaRepository.criar(c, LINHA, valores);
        }
        return cab;
    }

    /** P-08 passo 2: {@code tesouraria.fn_aprovar_saida} (em nome próprio; quem regista não aprova). */
    public static JsonObject aprovar(Connection c, long id) throws SQLException {
        TabelaRepository.obterOu404(c, TRANSACAO, id);
        FuncoesBd.chamar(c, "SELECT tesouraria.fn_aprovar_saida(?::bigint)", id);
        return TabelaRepository.obterOu404(c, TRANSACAO, id);
    }

    /** Saídas sem aprovação são recusadas no COMMIT (trigger da soma e aprovação). */
    public static JsonObject confirmar(Connection c, long id) throws SQLException {
        return TabelaRepository.actualizar(c, TRANSACAO, id, List.of(Valor.campo(TRANSACAO, "estado", "CONFIRMADA")), null);
    }

    /** P-12: estorno = transacção do tipo contrário, ligada à original, com as suas linhas. Fica pendente. */
    public static JsonObject estornar(Connection c, long id, JsonObject corpo) throws SQLException {
        BigDecimal valor = Corpo.dinheiro(corpo, "valor");
        String motivo = Corpo.texto(corpo, "motivo");
        JsonArray linhas = Corpo.lista(corpo.get("linhas"), "linhas");
        JsonObject original = TabelaRepository.obterOu404(c, TRANSACAO, id);
        String tipo = switch (original.getString("tipo")) {
            case "ENTRADA" -> "SAIDA";
            case "SAIDA" -> "ENTRADA";
            default -> throw new ApiException(422, "regra_negocio", "Só se estornam entradas e saídas", null);
        };
        return criar(c, Json.createObjectBuilder()
                .add("tipo", tipo)
                .add("metodo", original.get("metodo"))
                .add("valorTotal", valor.setScale(2).toPlainString())
                .add("contaId", original.get("contaId"))
                .add("membroId", original.get("membroId"))
                .add("familiaId", original.get("familiaId"))
                .add("anonimo", original.get("anonimo"))
                .add("estornoTransacaoId", id)
                .add("descricao", "Estorno: " + motivo)
                .add("linhas", linhas)
                .build());
    }

    /** F-TES-05: recibo numerado por igreja e ano ({@code tesouraria.fn_proximo_recibo}). */
    public static JsonObject emitirRecibo(Connection c, long id) throws SQLException {
        TabelaRepository.obterOu404(c, TRANSACAO, id);
        try (PreparedStatement ps = c.prepareStatement(
                "INSERT INTO tesouraria.recibo (rec_tra_id, rec_igr_id, rec_ano, rec_numero) "
                        + "SELECT t.tra_id, t.tra_igr_id, a.ano, tesouraria.fn_proximo_recibo(t.tra_igr_id, a.ano) "
                        + "FROM tesouraria.transacao t, "
                        + "LATERAL (SELECT EXTRACT(YEAR FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::integer AS ano) a "
                        + "WHERE t.tra_id = ? RETURNING " + RECIBO.listaSelect())) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return Conversao.linha(RECIBO, rs);
            }
        }
    }

    /** Fundo de um tipo para uma igreja: o da própria igreja, depois o da sua Associação/Missão, depois o geral. */
    public static Optional<Long> fundoDoTipo(Connection c, long igreja, String tipo) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT f.fun_id FROM tesouraria.fundo f, organizacao.igreja i "
                        + "WHERE i.igr_id = ? AND f.fun_tipo = ?::nucleo.tipo_fundo_t AND f.fun_end_date IS NULL "
                        + "AND (f.fun_igr_id = i.igr_id OR (f.fun_igr_id IS NULL "
                        + "     AND (f.fun_destino_ent_id = i.igr_ent_id OR f.fun_destino_ent_id IS NULL))) "
                        + "ORDER BY (f.fun_igr_id IS NULL), (f.fun_destino_ent_id IS NULL), f.fun_id LIMIT 1")) {
            ps.setLong(1, igreja);
            ps.setString(2, tipo);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(rs.getLong(1)) : Optional.empty();
            }
        }
    }
}
