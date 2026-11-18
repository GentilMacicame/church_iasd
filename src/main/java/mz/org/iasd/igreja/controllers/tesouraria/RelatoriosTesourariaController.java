package mz.org.iasd.igreja.controllers.tesouraria;

import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.controllers.base.BaseRelatoriosController;
import mz.org.iasd.igreja.controllers.base.Parametros;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.repositories.base.Relatorio;
import mz.org.iasd.igreja.repositories.tesouraria.ContribuicoesRepository;
import mz.org.iasd.igreja.repositories.tesouraria.ExtractosRepository;
import mz.org.iasd.igreja.Rotas;

/**
 * F-TES-10/11/12/15 Saldos e relatórios da tesouraria. Aceitam {@code ?igrejaId=} e {@code ?formato=json|csv}.
 * As contribuições e o extracto anual mostram ao membro sem perfil só os seus próprios dados (RLS).
 *
 * <pre>
 *   GET /v1/tesouraria/saldos-contas                         tesouraria.conta_financeira.ler
 *   GET /v1/tesouraria/saldos-fundos                         tesouraria.saldo_diario_fundo.ler
 *   GET /v1/tesouraria/remessas-devidas      ?ano=&amp;mes=      tesouraria.saldo_diario_fundo.ler
 *   GET /v1/tesouraria/execucao-orcamento    ?ano=           tesouraria.orcamento.ler
 *   GET /v1/tesouraria/contribuicoes      ?ano=&amp;mes=      tesouraria.transacao.ler (ou o próprio membro)
 *   GET /v1/tesouraria/extracto-anual        ?ano=           tesouraria.transacao.ler (ou o próprio membro)
 *   GET /v1/tesouraria/progresso-alvos                       tesouraria.alvo.ler
 *   GET /v1/tesouraria/conferencia-contagens                 tesouraria.contagem_numerario.ler
 *   GET /v1/tesouraria/despesas-por-pagar                    tesouraria.despesa.ler
 *   GET /v1/tesouraria/extractos-por-reconciliar             tesouraria.extrato_linha.ler
 *   GET /v1/tesouraria/mpesa-pendentes                       tesouraria.pagamento_mpesa.ler
 * </pre>
 */
@Path(Rotas.Tesouraria.RELATORIOS)
@RequestScoped
public class RelatoriosTesourariaController extends BaseRelatoriosController {

    public static final Relatorio SALDOS_CONTAS = Relatorio.porIgreja("tesouraria.vw_saldo_conta", "cfi_igr_id = ?", "cfi_nome");
    public static final Relatorio SALDOS_FUNDOS = Relatorio.porIgreja("tesouraria.vw_saldo_fundo", "igr_id = ?", "fun_codigo");
    public static final Relatorio REMESSAS_DEVIDAS = Relatorio.porIgreja("tesouraria.vw_remessa_devida",
            "igr_id = ?", "ano DESC, mes DESC, fun_id").comAnoMes("ano", "mes");
    public static final Relatorio EXECUCAO_ORCAMENTO = Relatorio.porIgreja("tesouraria.vw_execucao_orcamento",
            "orc_igr_id = ?", "orc_ano DESC, cat_codigo").comAnoMes("orc_ano", null);
    public static final Relatorio CONTRIBUICOES = Relatorio.porIgreja("tesouraria.vw_contribuicoes_membro",
            "tra_igr_id = ?", "tra_data_hora DESC").comAnoMes("periodo_ano", "periodo_mes");
    public static final Relatorio EXTRACTO_ANUAL = Relatorio.porIgreja("tesouraria.vw_extracto_anual",
            "tra_igr_id = ?", "ano DESC, fundo").comAnoMes("ano", null);
    public static final Relatorio PROGRESSO_ALVOS = Relatorio.porIgreja("tesouraria.vw_progresso_alvo", "alv_igr_id = ?", "alv_id");
    /** V49: reavivamento por pessoa (o alvo da igreja repartido, com quota ajustável). */
    public static final Relatorio REAVIVAMENTO_PESSOAS = Relatorio.porIgreja("tesouraria.vw_reavivamento_pessoas",
            "igreja_id = ?", "nome, apelido, membro_id").comAnoMes("ano", null);
    public static final Relatorio FUNDO_MENSAL = Relatorio.porIgreja("tesouraria.vw_fundo_mensal", "igreja_id = ?", "fundo, ano, mes")
            .comAnoMes("ano", "mes").comFiltro("fundoId", "fundo_id");
    public static final Relatorio CONFERENCIA_CONTAGENS = Relatorio.porIgreja("tesouraria.vw_contagem_conferencia",
            "cnu_igr_id = ?", "cnu_data DESC");
    public static final Relatorio DESPESAS_POR_PAGAR = Relatorio.porIgreja("tesouraria.vw_despesas_por_pagar",
            "des_igr_id = ?", "des_aprovado_em");
    public static final Relatorio EXTRACTOS_POR_RECONCILIAR = Relatorio.porIgreja("tesouraria.vw_extrato_por_reconciliar",
            "ext_cfi_id IN (SELECT cfi_id FROM tesouraria.conta_financeira WHERE cfi_igr_id = ?)", "ext_data, ext_id");
    public static final Relatorio MPESA_PENDENTES = Relatorio.porIgreja("tesouraria.vw_mpesa_pendentes",
            "pmp_tra_id IN (SELECT tra_id FROM tesouraria.transacao WHERE tra_igr_id = ?)", "pmp_pedido_em, pmp_id");

    @GET
    @Path(Rotas.Tesouraria.SALDOS_CONTAS)
    public Response saldosContas() throws SQLException {
        return responder(SALDOS_CONTAS);
    }

    @GET
    @Path(Rotas.Tesouraria.SALDOS_FUNDOS)
    public Response saldosFundos() throws SQLException {
        return responder(SALDOS_FUNDOS);
    }

    /** Quanto se deve à Associação/Missão por mês e fundo (P-09 passo 1). */
    @GET
    @Path(Rotas.Tesouraria.REMESSAS_DEVIDAS)
    public Response remessasDevidas() throws SQLException {
        return responder(REMESSAS_DEVIDAS);
    }

    @GET
    @Path(Rotas.Tesouraria.EXECUCAO_ORCAMENTO)
    public Response execucaoOrcamento() throws SQLException {
        return responder(EXECUCAO_ORCAMENTO);
    }

    @GET
    @Path(Rotas.Tesouraria.CONTRIBUICOES)
    public Response contribuicoes() throws SQLException {
        return responder(CONTRIBUICOES);
    }

    /** Declaração anual de contribuições por membro e fundo. */
    @GET
    @Path(Rotas.Tesouraria.EXTRACTO_ANUAL)
    public Response extractoAnual() throws SQLException {
        return responder(EXTRACTO_ANUAL);
    }

    @GET
    @Path(Rotas.Tesouraria.PROGRESSO_ALVOS)
    public Response progressoAlvos() throws SQLException {
        return responder(PROGRESSO_ALVOS);
    }

    /** Reavivamento por pessoa no ano: quota, contribuído e falta (V49). */
    @GET
    @Path(Rotas.Tesouraria.REAVIVAMENTO_PESSOAS)
    public Response reavivamentoPessoas() throws SQLException {
        return responder(REAVIVAMENTO_PESSOAS);
    }

    /** Diferença entre o contado e o lançado (P-06 passo 4). */
    @GET
    @Path(Rotas.Tesouraria.CONFERENCIA_CONTAGENS)
    public Response conferenciaContagens() throws SQLException {
        return responder(CONFERENCIA_CONTAGENS);
    }

    @GET
    @Path(Rotas.Tesouraria.DESPESAS_POR_PAGAR)
    public Response despesasPorPagar() throws SQLException {
        return responder(DESPESAS_POR_PAGAR);
    }

    @GET
    @Path(Rotas.Tesouraria.EXTRACTOS_POR_RECONCILIAR)
    public Response extractosPorReconciliar() throws SQLException {
        return responder(EXTRACTOS_POR_RECONCILIAR);
    }

    /** Pedidos M-Pesa a consultar na Vodacom (P-11): a resposta não chegou há mais de 5 minutos. */
    @GET
    @Path(Rotas.Tesouraria.MPESA_PENDENTES)
    public Response mpesaPendentes() throws SQLException {
        return responder(MPESA_PENDENTES);
    }

    /** V36: o arrecadado por fundo, mês a mês (ex.: obra de reavivamento: registo mensal e acumulado no ano). */
    @GET
    @Path(Rotas.Tesouraria.FUNDO_MENSAL)
    public Response fundoMensal() throws SQLException {
        return responder(FUNDO_MENSAL);
    }

    /** V50: extracto por departamento num período (mês, trimestre, semestre ou ano). */
    @GET
    @Path(Rotas.Tesouraria.EXTRACTO_DEPARTAMENTOS)
    @Produces(MediaType.APPLICATION_JSON)
    public Response extractoDepartamentos(@QueryParam("igrejaId") String igrejaId, @QueryParam("inicio") String inicio,
                                          @QueryParam("fim") String fim) throws SQLException {
        java.time.LocalDate de = Parametros.data(inicio, "inicio", true), ate = Parametros.data(fim, "fim", true);
        periodoValido(de, ate);
        return Response.ok(ExtractosRepository.departamentos(unidade.ligacao(), Parametros.inteiro(igrejaId, "igrejaId", true), de, ate)).build();
    }

    /** V50: extracto por fundo num período. */
    @GET
    @Path(Rotas.Tesouraria.EXTRACTO_FUNDOS)
    @Produces(MediaType.APPLICATION_JSON)
    public Response extractoFundos(@QueryParam("igrejaId") String igrejaId, @QueryParam("inicio") String inicio,
                                   @QueryParam("fim") String fim) throws SQLException {
        java.time.LocalDate de = Parametros.data(inicio, "inicio", true), ate = Parametros.data(fim, "fim", true);
        periodoValido(de, ate);
        return Response.ok(ExtractosRepository.fundos(unidade.ligacao(), Parametros.inteiro(igrejaId, "igrejaId", true), de, ate)).build();
    }

    private static void periodoValido(java.time.LocalDate de, java.time.LocalDate ate) {
        if (ate.isBefore(de)) {
            throw ApiException.pedidoInvalido("O fim não pode ser antes do início", "fim");
        }
        if (de.plusYears(1).isBefore(ate)) {
            throw ApiException.pedidoInvalido("Escolha um período até um ano", "fim");
        }
    }

    /** V36: a meta sugerida para o ano (alvo do ano anterior + 5%); quem tem a permissão pode ajustar ao gravar o alvo. */
    @GET
    @Path(Rotas.Tesouraria.ALVO_SUGERIDO)
    @Produces(MediaType.APPLICATION_JSON)
    public Response alvoSugerido(@QueryParam("igrejaId") String igrejaId, @QueryParam("fundoId") String fundoId,
                                 @QueryParam("ano") String ano) throws SQLException {
        return Response.ok(ContribuicoesRepository.alvoSugerido(unidade.ligacao(), Parametros.inteiro(igrejaId, "igrejaId", true),
                Parametros.inteiro(fundoId, "fundoId", true), Parametros.inteiro(ano, "ano", true))).build();
    }

    /** V36: dízimos do mesmo mês já lançados em nome da família do membro (ou dos membros da família). Só aviso. */
    @GET
    @Path(Rotas.Tesouraria.CONTRIBUICOES_SOBREPOSTAS)
    @Produces(MediaType.APPLICATION_JSON)
    public Response contribuicoesSobrepostas(@QueryParam("membroId") String membroId, @QueryParam("familiaId") String familiaId,
                                             @QueryParam("data") String data) throws SQLException {
        Integer membro = Parametros.inteiro(membroId, "membroId", false);
        Integer familia = Parametros.inteiro(familiaId, "familiaId", false);
        if ((membro == null) == (familia == null)) {
            throw ApiException.pedidoInvalido("Indique o membro ou a família", "membroId");
        }
        return Response.ok(ContribuicoesRepository.sobrepostas(unidade.ligacao(), membro, familia,
                Parametros.data(data, "data", true))).build();
    }
}
