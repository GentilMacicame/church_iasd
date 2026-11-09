package mz.org.iasd.igreja.controllers.organizacao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.regex.Pattern;

import jakarta.enterprise.context.RequestScoped;
import jakarta.json.Json;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.Corpo;
import mz.org.iasd.igreja.repositories.base.TabelaRepository;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.models.tesouraria.Fundo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.organizacao.Entidade;

/**
 * Níveis da organização: Conferência Geral, Divisão, União, Associação, Missão.
 * Tabela {@code organizacao.entidade} · permissões {@code organizacao.entidade.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/organizacao/entidades
 *   POST   /v1/organizacao/entidades
 *   GET    /v1/organizacao/entidades/{id}
 *   PATCH  /v1/organizacao/entidades/{id}
 *   POST   /v1/organizacao/entidades/{id}/terminar
 *   POST   /v1/organizacao/entidades/{id}/reactivar
 *   POST   /v1/organizacao/entidades/{id}/fundos-padrao   {percentagemOfertaCombinada, sufixo?}
 *          tesouraria.fundo.criar · tesouraria.fn_criar_fundos_padrao → 201 com os fundos criados
 * </pre>
 */
@Path(Rotas.Organizacao.ENTIDADES)
@RequestScoped
public class EntidadesController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Entidade.class);
    private static final Tabela FUNDO = Catalogo.de(Fundo.class);
    private static final Pattern PERCENTAGEM = Pattern.compile("^\\d{1,3}(\\.\\d{1,2})?$");

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    /**
     * Cria os fundos-padrão de uma Associação/Missão (dízimo, ES missões, 13.º sábado, ES despesas, ofertas
     * missionárias, oferta combinada, orçamento local). A base decide a permissão e recusa códigos repetidos
     * (409: indique um {@code sufixo}).
     */
    @POST
    @Path(Rotas.Organizacao.ENTIDADES_FUNDOS_PADRAO)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response fundosPadrao(@PathParam("id") long id, String corpo) throws SQLException {
        JsonObject o = Corpo.objecto(Corpo.ler(corpo));
        String percentagem = Corpo.texto(o, "percentagemOfertaCombinada");
        if (!PERCENTAGEM.matcher(percentagem).matches()) {
            throw ApiException.pedidoInvalido("Indique um número entre 0 e 100, ex.: \"20.00\"", "percentagemOfertaCombinada");
        }
        String sufixo = Corpo.textoOpcional(o, "sufixo");
        Connection c = ligacao();
        TabelaRepository.obterOu404(c, TABELA, id);
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT tesouraria.fn_criar_fundos_padrao(?::integer, ?::numeric, ?)")) {
            ps.setLong(1, id);
            ps.setString(2, percentagem);
            ps.setString(3, sufixo == null ? "" : sufixo);
            ps.execute();
        }
        // os fundos desta transacção: criados agora (now() é o início da transacção) por este utilizador
        JsonArrayBuilder criados = Json.createArrayBuilder();
        try (PreparedStatement ps = c.prepareStatement("SELECT fun_id FROM tesouraria.fundo "
                + "WHERE fun_criado_em = now() AND fun_criado_por = nucleo.fn_usuario_sessao() ORDER BY fun_id");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                criados.add(TabelaRepository.obterOu404(c, FUNDO, rs.getLong(1)));
            }
        }
        return Response.status(Response.Status.CREATED).entity(criados.build()).build();
    }
}
