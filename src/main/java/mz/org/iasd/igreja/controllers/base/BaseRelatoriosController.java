package mz.org.iasd.igreja.controllers.base;

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
        Relatorio.Resultado r = relatorio.executar(unidade.ligacao(), p);
        JsonArray linhas = r.linhas();
        Response.ResponseBuilder resposta = switch (p.getOrDefault("formato", "json")) {
            case "json" -> Response.ok(linhas, MediaType.APPLICATION_JSON_TYPE);
            case "csv" -> Response.ok(Csv.de(linhas), "text/csv; charset=UTF-8")
                    .header("Content-Disposition", "attachment; filename=\"" + nomeFicheiro() + ".csv\"");
            case "pdf" -> throw new ApiException(501, "nao_disponivel", "Exportação em PDF ainda não disponível", "formato");
            default -> throw ApiException.pedidoInvalido("Formato inválido: use json ou csv", "formato");
        };
        if (r.truncado()) {
            // há mais linhas do que o máximo: o cliente avisa e pede um filtro (igrejaId, ano, trimestre)
            resposta.header("X-Relatorio-Truncado", "true").header("X-Relatorio-Limite", Relatorio.MAX_LINHAS);
        }
        return resposta.build();
    }

    private String nomeFicheiro() {
        String caminho = uri.getPath();
        return caminho.substring(caminho.lastIndexOf('/') + 1);
    }
}
