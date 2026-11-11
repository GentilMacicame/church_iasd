package mz.org.iasd.igreja.controllers.tesouraria;

import java.nio.charset.StandardCharsets;
import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.config.Configuracao;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.infraestrutura.ficheiros.ArmazemFicheiros;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.services.tesouraria.DocumentosService;

/**
 * Comprovativos (facturas, talões, prints M-Pesa).
 * Tabela {@code tesouraria.documento} · permissões {@code tesouraria.documento.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/documentos
 *   POST   /v1/tesouraria/documentos
 *   POST   /v1/tesouraria/documentos/carregar?transacaoId=|despesaId=&amp;tipo=&amp;nome=   corpo: o ficheiro (JPG, PNG, WebP, PDF)
 *   GET    /v1/tesouraria/documentos/{id}
 *   GET    /v1/tesouraria/documentos/{id}/ficheiro
 *   PATCH  /v1/tesouraria/documentos/{id}
 *   POST   /v1/tesouraria/documentos/{id}/terminar
 *   POST   /v1/tesouraria/documentos/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.DOCUMENTOS)
@RequestScoped
@Idempotente(opcional = true)
public class DocumentosController extends BaseTabelaController {

    private static final Tabela TABELA = DocumentosService.DOCUMENTO;

    @Inject
    Configuracao configuracao;

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    /** O ficheiro vem no corpo, tal e qual (o tipo é verificado pelos primeiros bytes, não pelo Content-Type). */
    @POST
    @Path(Rotas.Tesouraria.DOCUMENTOS_CARREGAR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response carregar(@QueryParam("transacaoId") Long transacaoId, @QueryParam("despesaId") Long despesaId,
            @QueryParam("tipo") String tipo, @QueryParam("nome") String nome, byte[] corpo) throws SQLException {
        // byte[] e não InputStream: a transacção pode repetir-se (40001) e o corpo tem de poder ser lido outra vez
        var doc = DocumentosService.carregar(ligacao(), armazem(), transacaoId, despesaId, tipo, nome, corpo);
        return criado(doc, uri.getBaseUriBuilder().path(Rotas.Tesouraria.DOCUMENTOS).path(doc.get("id").toString()).build());
    }

    @GET
    @Path(Rotas.Tesouraria.DOCUMENTOS_FICHEIRO)
    @Produces(MediaType.WILDCARD)
    public Response ficheiro(@PathParam("id") long id) throws SQLException {
        var f = DocumentosService.ficheiro(ligacao(), armazem(), id);
        // nome em ASCII no filename e completo em filename* (RFC 6266); nosniff para o navegador não adivinhar o tipo
        String ascii = f.nome().replaceAll("[^A-Za-z0-9._ -]", "_");
        String utf8 = java.net.URLEncoder.encode(f.nome(), StandardCharsets.UTF_8).replace("+", "%20");
        return Response.ok(f.dados(), f.tipo().mime)
                .header("Content-Disposition", "inline; filename=\"" + ascii + "\"; filename*=UTF-8''" + utf8)
                .header("X-Content-Type-Options", "nosniff")
                .header("Cache-Control", "private, max-age=3600")
                .build();
    }

    private ArmazemFicheiros armazem() {
        return new ArmazemFicheiros(configuracao.ficheirosPasta().orElseThrow(() -> new ApiException(503, "sem_armazenamento",
                "O servidor ainda não tem onde guardar os comprovativos (FICHEIROS_PASTA). Fale com o administrador.", null)));
    }
}
