package mz.org.iasd.igreja.services.escolasabatina;

import java.math.BigDecimal;
import java.sql.Array;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObject;
import jakarta.json.JsonValue;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.Corpo;
import mz.org.iasd.igreja.repositories.base.TabelaRepository;
import mz.org.iasd.igreja.repositories.base.TabelaRepository.Valor;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.services.tesouraria.TransacoesService;
import mz.org.iasd.igreja.controllers.escolasabatina.RelatoriosSabadoController;
import mz.org.iasd.igreja.models.escolasabatina.Visitante;
import mz.org.iasd.igreja.models.escolasabatina.RelatorioSabado;

/** Operações do relatório do sábado (processo P-05) usadas por {@link RelatoriosSabadoController}. */
public final class RelatoriosSabadoService {

    public static final Tabela RELATORIO = Catalogo.de(RelatorioSabado.class);
    public static final Tabela VISITANTE = Catalogo.de(Visitante.class);

    private RelatoriosSabadoService() {
    }

    /** F-ES-05: grava a chamada de uma vez; o trigger recalcula M.P. e E.D. uma só vez. */
    public static JsonObject gravarPresencas(Connection c, long id, JsonArray lista) throws SQLException {
        TabelaRepository.obterOu404(c, RELATORIO, id);
        List<Long> membros = new ArrayList<>();
        List<Boolean> presentes = new ArrayList<>();
        List<Boolean> estudaram = new ArrayList<>();
        Set<Long> vistos = new HashSet<>();
        for (JsonValue v : lista) {
            JsonObject o = Corpo.objecto(v);
            long membro = Corpo.inteiro(o, "membroId");
            if (!vistos.add(membro)) {
                throw ApiException.pedidoInvalido("O membro " + membro + " aparece duas vezes na chamada", "membroId");
            }
            membros.add(membro);
            presentes.add(Corpo.booleano(o, "presente"));
            estudaram.add(Corpo.tem(o, "estudouLicao") && Corpo.booleano(o, "estudouLicao"));
        }
        if (!membros.isEmpty()) {
            Array m = c.createArrayOf("bigint", membros.toArray());
            Array p = c.createArrayOf("boolean", presentes.toArray());
            Array e = c.createArrayOf("boolean", estudaram.toArray());
            try (PreparedStatement ps = c.prepareStatement(
                    "INSERT INTO escola_sabatina.presenca (epr_ers_id, epr_mem_id, epr_presente, epr_estudou_licao) "
                            + "SELECT ?, x.m, x.p, x.e FROM unnest(?::bigint[], ?::boolean[], ?::boolean[]) AS x(m, p, e) "
                            + "ON CONFLICT (epr_ers_id, epr_mem_id) WHERE epr_end_date IS NULL "
                            + "DO UPDATE SET epr_presente = EXCLUDED.epr_presente, epr_estudou_licao = EXCLUDED.epr_estudou_licao")) {
                ps.setLong(1, id);
                ps.setArray(2, m);
                ps.setArray(3, p);
                ps.setArray(4, e);
                ps.executeUpdate();
            } finally {
                m.free();
                p.free();
                e.free();
            }
        }
        return TabelaRepository.obterOu404(c, RELATORIO, id);
    }

    /**
     * P-05 passo 5: as três ofertas (uma linha por fundo: ES missões, 13.º sábado, despesas; categoria R3)
     * como entrada confirmada, ligada ao relatório por {@code escola_sabatina.fn_ligar_ofertas}.
     */
    public static JsonObject lancarOfertas(Connection c, long id, JsonObject o) throws SQLException {
        long conta = Corpo.inteiro(o, "contaId");
        BigDecimal missoes = Corpo.dinheiro(o, "missoes");
        BigDecimal treze = Corpo.dinheiro(o, "decimoTerceiro");
        BigDecimal despesas = Corpo.dinheiro(o, "despesas");
        Long contagem = Corpo.inteiroOpcional(o, "contagemId");
        BigDecimal total = missoes.add(treze).add(despesas);
        if (total.signum() == 0) {
            throw new ApiException(422, "regra_negocio", "Não há ofertas para lançar", null);
        }

        JsonObject relatorio = TabelaRepository.obterOu404(c, RELATORIO, id);
        long igreja = relatorio.getJsonNumber("igrejaId").longValue();
        String tipoConta = texto(c, "SELECT cfi_tipo::text FROM tesouraria.conta_financeira WHERE cfi_id = ? AND cfi_end_date IS NULL", conta)
                .orElseThrow(() -> new ApiException(422, "referencia_invalida", "Conta não encontrada", "contaId"));
        long categoria = numero(c, "SELECT cat_id FROM tesouraria.categoria WHERE cat_codigo = 'R3' AND cat_end_date IS NULL")
                .orElseThrow(() -> new ApiException(422, "regra_negocio",
                        "Falta a categoria R3 (Ofertas da Escola Sabatina) no plano de contas", null));

        JsonArrayBuilder linhas = Json.createArrayBuilder();
        linha(c, linhas, igreja, "ES_MISSOES", categoria, missoes);
        linha(c, linhas, igreja, "ES_13_SABADO", categoria, treze);
        linha(c, linhas, igreja, "ES_DESPESAS", categoria, despesas);

        var cab = Json.createObjectBuilder()
                .add("tipo", "ENTRADA")
                .add("metodo", "CAIXA".equals(tipoConta) ? "NUMERARIO" : tipoConta)
                .add("valorTotal", total.setScale(2).toPlainString())
                .add("contaId", conta)
                .add("descricao", "Ofertas da Escola Sabatina (relatório " + id + ")")
                .add("estado", "CONFIRMADA")
                .add("linhas", linhas);
        if (contagem != null) {
            cab.add("contagemId", contagem);
        }
        JsonObject transacao = TransacoesService.criar(c, cab.build());
        try (PreparedStatement ps = c.prepareStatement("SELECT escola_sabatina.fn_ligar_ofertas(?::integer, ?::bigint)")) {
            ps.setLong(1, id);
            ps.setLong(2, transacao.getJsonNumber("id").longValue());
            ps.execute();
        }
        return transacao;
    }

    /** Fechar ({@code FECHADO}) ou reabrir ({@code ABERTO}); as permissões e condições estão no trigger. */
    public static JsonObject mudarEstado(Connection c, long id, String estado) throws SQLException {
        return TabelaRepository.actualizar(c, RELATORIO, id, List.of(Valor.campo(RELATORIO, "estado", estado)), null);
    }

    private static void linha(Connection c, JsonArrayBuilder linhas, long igreja, String tipoFundo, long categoria,
                              BigDecimal valor) throws SQLException {
        if (valor.signum() == 0) {
            return;
        }
        long fundo = TransacoesService.fundoDoTipo(c, igreja, tipoFundo).orElseThrow(() -> new ApiException(422,
                "regra_negocio", "Não existe nenhum fundo " + tipoFundo + " configurado para esta igreja", null));
        linhas.add(Json.createObjectBuilder().add("fundoId", fundo).add("categoriaId", categoria)
                .add("valor", valor.setScale(2).toPlainString()));
    }

    private static Optional<String> texto(Connection c, String sql, long arg) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, arg);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.ofNullable(rs.getString(1)) : Optional.empty();
            }
        }
    }

    private static Optional<Long> numero(Connection c, String sql) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            return rs.next() ? Optional.of(rs.getLong(1)) : Optional.empty();
        }
    }
}
