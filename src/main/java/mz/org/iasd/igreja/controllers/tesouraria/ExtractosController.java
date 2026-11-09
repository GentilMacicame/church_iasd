package mz.org.iasd.igreja.controllers.tesouraria;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.regex.Pattern;

import jakarta.enterprise.context.RequestScoped;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.Corpo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.TabelaRepository;
import mz.org.iasd.igreja.crud.TabelaRepository.Valor;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.ExtratoLinha;

/**
 * F-TES-14 Reconciliação: linhas do extracto bancário / M-Pesa ligadas aos movimentos (processo P-10).
 * Por reconciliar: relatório {@code GET /v1/tesouraria/extractos-por-reconciliar}.
 * Tabela {@code tesouraria.extrato_linha}.
 *
 * <pre>
 *   GET    /v1/tesouraria/extractos
 *   POST   /v1/tesouraria/extractos
 *   POST   /v1/tesouraria/extractos/importar          {contaId, csv}  → {importadas, repetidas}
 *   GET    /v1/tesouraria/extractos/{id}
 *   PATCH  /v1/tesouraria/extractos/{id}
 *   POST   /v1/tesouraria/extractos/{id}/terminar
 *   POST   /v1/tesouraria/extractos/{id}/reactivar
 *   POST   /v1/tesouraria/extractos/{id}/reconciliar  {transacaoId}
 * </pre>
 */
@Path(Rotas.Tesouraria.EXTRACTOS)
@RequestScoped
@Idempotente(opcional = true)
public class ExtractosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(ExtratoLinha.class);
    private static final DateTimeFormatter DATA_PT = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final Pattern VALOR = Pattern.compile("^-?\\d{1,14}(\\.\\d{1,2})?$");

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    /**
     * CSV {@code data;descricao;referencia;valor} (datas AAAA-MM-DD ou DD/MM/AAAA; valores "1 500,50" ou
     * "1500.50"; primeira linha de títulos opcional). Linhas já importadas são ignoradas (índice único).
     */
    @POST
    @Path(Rotas.Tesouraria.EXTRACTOS_IMPORTAR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response importar(String corpo) throws SQLException {
        JsonObject o = Corpo.objecto(Corpo.ler(corpo));
        long conta = Corpo.inteiro(o, "contaId");
        String[] linhas = Corpo.texto(o, "csv").split("\\R");
        int importadas = 0;
        int repetidas = 0;
        Connection c = ligacao();
        try (PreparedStatement ps = c.prepareStatement(
                "INSERT INTO tesouraria.extrato_linha (ext_cfi_id, ext_data, ext_descricao, ext_referencia, ext_valor) "
                        + "VALUES (?, ?::date, ?, ?, ?::numeric) "
                        + "ON CONFLICT (ext_cfi_id, ext_data, ext_referencia, ext_valor) WHERE ext_end_date IS NULL DO NOTHING")) {
            for (int i = 0; i < linhas.length; i++) {
                String linha = linhas[i].strip();
                if (linha.isEmpty() || (i == 0 && linha.toLowerCase().startsWith("data"))) {
                    continue;
                }
                String[] p = linha.split(";", -1);
                if (p.length != 4) {
                    throw ApiException.pedidoInvalido("Linha " + (i + 1)
                            + ": são precisas 4 colunas (data;descricao;referencia;valor)", "csv");
                }
                ps.setLong(1, conta);
                ps.setString(2, data(p[0].strip(), i + 1).toString());
                ps.setString(3, vazioNulo(p[1]));
                ps.setString(4, vazioNulo(p[2]));
                ps.setString(5, valor(p[3], i + 1));
                if (ps.executeUpdate() == 1) {
                    importadas++;
                } else {
                    repetidas++;
                }
            }
        }
        return ok(Json.createObjectBuilder().add("importadas", importadas).add("repetidas", repetidas).build());
    }

    @POST
    @Path(Rotas.Tesouraria.EXTRACTOS_RECONCILIAR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response reconciliar(@PathParam("id") long id, String corpo) throws SQLException {
        long transacao = Corpo.inteiro(Corpo.objecto(Corpo.ler(corpo)), "transacaoId");
        return ok(TabelaRepository.actualizar(ligacao(), TABELA, id,
                List.of(Valor.campo(TABELA, "transacaoId", Long.toString(transacao))), null));
    }

    public static LocalDate data(String s, int linha) {
        try {
            return s.contains("/") ? LocalDate.parse(s, DATA_PT) : LocalDate.parse(s);
        } catch (DateTimeParseException e) {
            throw ApiException.pedidoInvalido("Linha " + linha + ": data inválida (" + s + ")", "csv");
        }
    }

    public static String valor(String s, int linha) {
        String v = s.strip().replace(" ", "").replace("\u00a0", "");
        if (v.contains(",")) {
            v = v.replace(".", "").replace(",", ".");
        }
        if (!VALOR.matcher(v).matches()) {
            throw ApiException.pedidoInvalido("Linha " + linha + ": valor inválido (" + s.strip() + ")", "csv");
        }
        return v;
    }

    private static String vazioNulo(String s) {
        return s == null || s.isBlank() ? null : s.strip();
    }
}
