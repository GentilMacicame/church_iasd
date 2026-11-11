package mz.org.iasd.igreja.controllers.base;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

import jakarta.inject.Inject;
import jakarta.json.JsonArray;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;

import mz.org.iasd.igreja.infraestrutura.bd.Transaccional;
import mz.org.iasd.igreja.infraestrutura.bd.UnidadeDeTrabalho;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.repositories.base.Relatorio;

/**
 * Base das classes de relatórios de cada módulo. Cada relatório é um método {@code @GET} explícito que
 * chama {@link #responder(Relatorio)}. Aceita {@code ?formato=json} (por defeito), {@code csv} ou {@code pdf}.
 */
@Transaccional
public abstract class BaseRelatoriosController {

    @Inject
    protected UnidadeDeTrabalho unidade;

    @Context
    protected UriInfo uri;

    protected Response responder(Relatorio relatorio) throws SQLException {
        Map<String, String> p = new HashMap<>();
        uri.getQueryParameters().forEach((k, v) -> {
            if (!v.isEmpty()) {
                p.put(k, v.get(0));
            }
        });
        Relatorio.Resultado r = relatorio.executar(unidade.ligacao(), p);
        JsonArray linhas = r.linhas();
        Response.ResponseBuilder resposta = switch (p.getOrDefault("formato", "json")) {
            case "json" -> Response.ok(linhas, MediaType.APPLICATION_JSON_TYPE);
            case "csv" -> Response.ok(Csv.de(linhas), "text/csv; charset=UTF-8")
                    .header("Content-Disposition", "attachment; filename=\"" + nomeFicheiro() + ".csv\"");
            case "pdf" -> Response.ok(Pdf.de(linhas, nomeFicheiro(), nomeIgreja(p.get("igrejaId")), filtros(p), r.truncado()), "application/pdf")
                    .header("Content-Disposition", "attachment; filename=\"" + nomeFicheiro() + ".pdf\"");
            default -> throw ApiException.pedidoInvalido("Formato inválido: use json, csv ou pdf", "formato");
        };
        if (r.truncado()) {
            // há mais linhas do que o máximo: o cliente avisa e pede um filtro (igrejaId, ano, trimestre)
            resposta.header("X-Relatorio-Truncado", "true").header("X-Relatorio-Limite", Relatorio.MAX_LINHAS);
        }
        return resposta.build();
    }

    /** Nome da igreja para o cabeçalho do PDF (só se o utilizador a puder ver: a RLS decide). */
    private String nomeIgreja(String igrejaId) throws SQLException {
        if (igrejaId == null || !igrejaId.matches("[0-9]{1,9}")) {
            return null;
        }
        try (PreparedStatement ps = unidade.ligacao().prepareStatement("SELECT nome FROM organizacao.vw_directorio_igrejas WHERE igr_id = ?")) {
            ps.setInt(1, Integer.parseInt(igrejaId));
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString(1) : null;
            }
        }
    }

    private static String filtros(Map<String, String> p) {
        StringBuilder sb = new StringBuilder();
        if (p.containsKey("ano")) {
            sb.append("Ano ").append(p.get("ano"));
        }
        if (p.containsKey("mes")) {
            sb.append(sb.isEmpty() ? "" : " · ").append("Mês ").append(p.get("mes"));
        }
        if (p.containsKey("trimestreId")) {
            sb.append(sb.isEmpty() ? "" : " · ").append("Trimestre ").append(p.get("trimestreId"));
        }
        return sb.toString();
    }

    private String nomeFicheiro() {
        String caminho = uri.getPath();
        return caminho.substring(caminho.lastIndexOf('/') + 1);
    }
}
