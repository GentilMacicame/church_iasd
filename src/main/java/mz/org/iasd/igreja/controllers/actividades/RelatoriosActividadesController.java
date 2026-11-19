package mz.org.iasd.igreja.controllers.actividades;

import java.sql.SQLException;
import java.time.OffsetDateTime;
import java.time.format.DateTimeParseException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.controllers.base.BaseRelatoriosController;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.repositories.actividades.ConflitosRepository;
import mz.org.iasd.igreja.repositories.base.Relatorio;
import mz.org.iasd.igreja.Rotas;

/**
 * F-ACT-03 Relatórios das actividades. Aceitam {@code ?igrejaId=} e {@code ?formato=json|csv}.
 *
 * <pre>
 *   GET /v1/actividades/escalas-proximas     escalas dos próximos 30 dias   actividades.escala.ler
 *   GET /v1/actividades/escala-grelha        ?planoId=   a escala como no papel: um dia por linha, uma coluna
 *                                            por função   actividades.escala_plano.ler (ou membro: publicada)
 *   GET /v1/actividades/programa             ?ano=&amp;mes=   programa anual com previsto e executado (V34)
 *   GET /v1/actividades/conflitos            ?igrejaId=&amp;inicio=&amp;fim=&amp;excluirId=   conflitos e datas livres (V34)
 * </pre>
 */
@Path(Rotas.Actividades.RELATORIOS)
@RequestScoped
public class RelatoriosActividadesController extends BaseRelatoriosController {

    public static final Relatorio ESCALAS_PROXIMAS = Relatorio.porIgreja("actividades.vw_escala_proximas",
            "esc_igr_id = ?", "esc_data, esc_funcao");
    public static final Relatorio ESCALA_GRELHA = Relatorio.porIgreja("actividades.vw_escala_grelha",
            "igreja_id = ?", "plano_id, data").comFiltro("planoId", "plano_id");
    public static final Relatorio SANTA_CEIA = Relatorio.porIgreja("actividades.vw_santa_ceia", "igreja_id = ?", "data DESC, igreja")
            .comAnoMes("ano", null);
    public static final Relatorio SANTA_CEIA_PARTICIPACAO = Relatorio.porIgreja("actividades.vw_santa_ceia_participacao", "igreja_id = ?",
            "faltas DESC, membro").comAnoMes("ano", null);
    public static final Relatorio PROGRAMA = Relatorio.porIgreja("actividades.vw_actividades_execucao",
            "igreja_id = ?", "data_inicio, nome").comAnoMes("ano", "mes");

    @GET
    @Path(Rotas.Actividades.ESCALAS_PROXIMAS)
    public Response escalasProximas() throws SQLException {
        return responder(ESCALAS_PROXIMAS);
    }

    /** A escala para imprimir ou afixar (JSON ou CSV): pregador, tradutor, acompanhantes, coral, departamento. */
    @GET
    @Path(Rotas.Actividades.ESCALA_GRELHA)
    public Response escalaGrelha() throws SQLException {
        return responder(ESCALA_GRELHA);
    }

    /** V39: as celebrações da Santa Ceia (?igrejaId=, ?ano=) com os participantes. */
    @GET
    @Path(Rotas.Actividades.SANTA_CEIA_HISTORICO)
    public Response santaCeiaHistorico() throws SQLException {
        return responder(SANTA_CEIA);
    }

    /** V52: a participação de cada membro na Santa Ceia (?igrejaId=, ?ano=): celebrações, participações, faltas e a última. */
    @GET
    @Path(Rotas.Actividades.SANTA_CEIA_PARTICIPACAO)
    public Response santaCeiaParticipacao() throws SQLException {
        return responder(SANTA_CEIA_PARTICIPACAO);
    }

    /** V34: o programa anual (?ano=, ?mes=) com o previsto e o executado de cada actividade. */
    @GET
    @Path(Rotas.Actividades.PROGRAMA)
    public Response programa() throws SQLException {
        return responder(PROGRAMA);
    }

    /** V34: actividades que se sobrepõem ao horário e os dias seguintes livres. Só informa; não bloqueia. */
    @GET
    @Path(Rotas.Actividades.CONFLITOS)
    @Produces(MediaType.APPLICATION_JSON)
    public Response conflitos(@QueryParam("igrejaId") String igrejaId, @QueryParam("inicio") String inicio,
                              @QueryParam("fim") String fim, @QueryParam("excluirId") String excluirId) throws SQLException {
        int igreja = inteiro(igrejaId, "igrejaId", true);
        OffsetDateTime de = dataHora(inicio, "inicio", true);
        OffsetDateTime ate = dataHora(fim, "fim", false);
        if (ate != null && ate.isBefore(de)) {
            throw ApiException.pedidoInvalido("O fim não pode ser antes do início", "fim");
        }
        Integer excluir = excluirId == null || excluirId.isBlank() ? null : inteiro(excluirId, "excluirId", true);
        return Response.ok(ConflitosRepository.procurar(unidade.ligacao(), igreja, de, ate, excluir)).build();
    }

    private static int inteiro(String v, String campo, boolean obrigatorio) {
        if (v == null || v.isBlank()) {
            if (obrigatorio) {
                throw ApiException.pedidoInvalido("Campo obrigatório", campo);
            }
            return 0;
        }
        try {
            return Integer.parseInt(v.trim());
        } catch (NumberFormatException e) {
            throw ApiException.pedidoInvalido("Tem de ser um número inteiro", campo);
        }
    }

    private static OffsetDateTime dataHora(String v, String campo, boolean obrigatorio) {
        if (v == null || v.isBlank()) {
            if (obrigatorio) {
                throw ApiException.pedidoInvalido("Campo obrigatório", campo);
            }
            return null;
        }
        try {
            return OffsetDateTime.parse(v.trim());
        } catch (DateTimeParseException e) {
            throw ApiException.pedidoInvalido("Data e hora inválidas (ISO 8601 com fuso, ex.: 2026-12-05T09:00:00+02:00)", campo);
        }
    }
}
