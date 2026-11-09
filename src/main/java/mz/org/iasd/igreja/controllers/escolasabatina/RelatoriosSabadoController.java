package mz.org.iasd.igreja.controllers.escolasabatina;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import jakarta.enterprise.context.RequestScoped;
import jakarta.json.JsonObject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.controllers.base.Corpo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.repositories.base.TabelaRepository;
import mz.org.iasd.igreja.repositories.base.TabelaRepository.Valor;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.services.escolasabatina.RelatoriosSabadoService;

/**
 * F-ES-04/05/06 Relatório de cada classe em cada sábado (processo P-05). As regras — sábado do trimestre,
 * presentes ≤ matriculados, fechar só com as ofertas confirmadas nos fundos certos, relatório fechado não
 * muda — estão nos triggers. Tabela {@code escola_sabatina.relatorio_sabado}.
 *
 * <pre>
 *   GET    /v1/escola-sabatina/relatorios-sabado?igrejaId=
 *   POST   /v1/escola-sabatina/relatorios-sabado                 abrir (P-05 passo 2)
 *   GET    /v1/escola-sabatina/relatorios-sabado/{id}
 *   PATCH  /v1/escola-sabatina/relatorios-sabado/{id}            números e ofertas (passo 4)
 *   POST   /v1/escola-sabatina/relatorios-sabado/{id}/terminar
 *   POST   /v1/escola-sabatina/relatorios-sabado/{id}/reactivar
 *   PUT    /v1/escola-sabatina/relatorios-sabado/{id}/presencas  chamada inteira (passo 3)
 *   GET    /v1/escola-sabatina/relatorios-sabado/{id}/visitantes
 *   POST   /v1/escola-sabatina/relatorios-sabado/{id}/visitantes
 *   POST   /v1/escola-sabatina/relatorios-sabado/{id}/ofertas    tesoureiro lança as ofertas (passo 5)  Idempotency-Key
 *   POST   /v1/escola-sabatina/relatorios-sabado/{id}/fechar     …relatorio_sabado.fechar (passo 6)
 *   POST   /v1/escola-sabatina/relatorios-sabado/{id}/reabrir    …relatorio_sabado.reabrir
 * </pre>
 */
@Path(Rotas.EscolaSabatina.RELATORIOS_SABADO)
@RequestScoped
public class RelatoriosSabadoController extends BaseTabelaController {

    @Override
    protected Tabela tabela() {
        return RelatoriosSabadoService.RELATORIO;
    }

    @PUT
    @Path(Rotas.EscolaSabatina.RELATORIOS_SABADO_PRESENCAS)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response presencas(@PathParam("id") long id, String corpo) throws SQLException {
        return ok(RelatoriosSabadoService.gravarPresencas(ligacao(), id, Corpo.lista(Corpo.ler(corpo), null)));
    }

    @GET
    @Path(Rotas.EscolaSabatina.RELATORIOS_SABADO_VISITANTES)
    @Produces(MediaType.APPLICATION_JSON)
    public Response visitantes(@PathParam("id") long id) throws SQLException {
        TabelaRepository.obterOu404(ligacao(), tabela(), id);
        return ok(TabelaRepository.filhos(ligacao(), RelatoriosSabadoService.VISITANTE, "evi_ers_id", id));
    }

    @POST
    @Path(Rotas.EscolaSabatina.RELATORIOS_SABADO_VISITANTES)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response criarVisitante(@PathParam("id") long id, String corpo) throws SQLException {
        TabelaRepository.obterOu404(ligacao(), tabela(), id);
        Tabela visitante = RelatoriosSabadoService.VISITANTE;
        List<Valor> valores = new ArrayList<>(TabelaRepository.valoresDoCorpo(visitante,
                Corpo.objecto(Corpo.ler(corpo)), Set.of("relatorioId")));
        valores.add(Valor.campo(visitante, "relatorioId", Long.toString(id)));
        JsonObject criado = TabelaRepository.criar(ligacao(), visitante, valores);
        return criado(criado, uri.getBaseUriBuilder().path("v1/escola-sabatina/visitantes")
                .path(criado.get("id").toString()).build());
    }

    @POST
    @Path(Rotas.EscolaSabatina.RELATORIOS_SABADO_OFERTAS)
    @Idempotente
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response ofertas(@PathParam("id") long id, String corpo) throws SQLException {
        return ok(RelatoriosSabadoService.lancarOfertas(ligacao(), id, Corpo.objecto(Corpo.ler(corpo))));
    }

    @POST
    @Path(Rotas.EscolaSabatina.RELATORIOS_SABADO_FECHAR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response fechar(@PathParam("id") long id) throws SQLException {
        return ok(RelatoriosSabadoService.mudarEstado(ligacao(), id, "FECHADO"));
    }

    @POST
    @Path(Rotas.EscolaSabatina.RELATORIOS_SABADO_REABRIR)
    @Consumes(MediaType.WILDCARD)
    @Produces(MediaType.APPLICATION_JSON)
    public Response reabrir(@PathParam("id") long id) throws SQLException {
        return ok(RelatoriosSabadoService.mudarEstado(ligacao(), id, "ABERTO"));
    }
}
