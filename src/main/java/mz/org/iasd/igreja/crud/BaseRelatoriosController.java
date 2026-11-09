package mz.org.iasd.igreja.crud;

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

/**
 * Base das classes de relatórios de cada módulo. Cada relatório é um método {@code @GET} explícito que
 * chama {@link #responder(Relatorio)}. Aceita {@code ?formato=json} (por defeito) ou {@code csv}.
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
        JsonArray linhas = relatorio.consultar(unidade.ligacao(), p);
        return switch (p.getOrDefault("formato", "json")) {
            case "json" -> Response.ok(linhas, MediaType.APPLICATION_JSON_TYPE).build();
            case "csv" -> Response.ok(Csv.de(linhas), "text/csv; charset=UTF-8")
                    .header("Content-Disposition", "attachment; filename=\"" + nomeFicheiro() + ".csv\"").build();
            case "pdf" -> throw new ApiException(501, "nao_disponivel", "Exportação em PDF ainda não disponível", "formato");
            default -> throw ApiException.pedidoInvalido("Formato inválido: use json ou csv", "formato");
        };
    }

    private String nomeFicheiro() {
        String caminho = uri.getPath();
        return caminho.substring(caminho.lastIndexOf('/') + 1);
    }
}
