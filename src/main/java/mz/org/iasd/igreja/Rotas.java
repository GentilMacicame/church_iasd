package mz.org.iasd.igreja;

/**
 * <b>Todas as rotas da API, num só ficheiro.</b>
 * <p>
 * Cada classe {@code *Controller} usa estas constantes no {@code @Path}: a classe com o caminho-base
 * ({@code @Path(Rotas.Secretaria.MEMBROS)}) e cada método com o sub-caminho
 * ({@code @Path(Rotas.Secretaria.MEMBROS_VALIDAR)}). Para mudar um endereço, muda-se aqui.
 * <p>
 * Os recursos de tabela herdam as rotas-padrão de {@link Comum}: {@code GET /}, {@code POST /},
 * {@code GET /{id}}, {@code PATCH /{id}}, {@code POST /{id}/terminar}, {@code POST /{id}/reactivar}.
 * <p>
 * As rotas têm de ser exactamente as de {@code api/openapi.yaml}: o {@code ContratoTest} confirma-o e
 * escreve a lista completa (método, caminho, classe, permissão) em {@code docs/ROTAS.md}.
 * Documentação interactiva: {@code http://localhost:9080/openapi/ui}.
 */
public final class Rotas {

    private Rotas() {
    }

    /** Rotas-padrão, herdadas por todos os recursos de tabela (crud/BaseLeituraController, crud/BaseTabelaController). */
    public static final class Comum {

        private Comum() {
        }

        /**
         * <pre>
         * GET …/{id}  (BaseLeituraController.obter)
         * PATCH …/{id}  (BaseTabelaController.alterar)
         * </pre>
         */
        public static final String ID = "{id: \\d+}";

        /** POST …/{id}/terminar  (BaseTabelaController.terminar) */
        public static final String TERMINAR = "{id: \\d+}/terminar";

        /** POST …/{id}/reactivar  (BaseTabelaController.reactivar) */
        public static final String REACTIVAR = "{id: \\d+}/reactivar";
    }

    /** Autenticação: login, renovar, sair, recuperar senha. */
    public static final class Auth {

        private Auth() {
        }

        /** AuthController */
        public static final String AUTH = "/v1/auth";

        /** POST /v1/auth/login  (AuthController.login) */
        public static final String LOGIN = "/login";

        /** POST /v1/auth/renovar  (AuthController.renovar) */
        public static final String RENOVAR = "/renovar";

        /** POST /v1/auth/sair  (AuthController.sair) */
        public static final String SAIR = "/sair";

        /** POST /v1/auth/recuperar  (AuthController.recuperar) */
        public static final String RECUPERAR = "/recuperar";

        /** POST /v1/auth/redefinir  (AuthController.redefinir) */
        public static final String REDEFINIR = "/redefinir";
    }

    /** O utilizador autenticado e as suas permissões. */
    public static final class Eu {

        private Eu() {
        }

        /** EuController */
        public static final String EU = "/v1/eu";
    }

    /** Núcleo: utilizadores, perfis, permissões, auditoria. */
    public static final class Nucleo {

        private Nucleo() {
        }

        /** AuditoriaController · rotas-padrão: listar, ler */
        public static final String AUDITORIA = "/v1/nucleo/auditoria";

        /** PerfisPermissoesController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String PERFIS_PERMISSOES = "/v1/nucleo/perfis-permissoes";

        /** PerfisController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String PERFIS = "/v1/nucleo/perfis";

        /** PermissoesController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String PERMISSOES = "/v1/nucleo/permissoes";

        /** UsuariosEntidadeController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String USUARIOS_ENTIDADE = "/v1/nucleo/usuarios-entidade";

        /** UsuariosIgrejaController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String USUARIOS_IGREJA = "/v1/nucleo/usuarios-igreja";

        /** UsuariosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String USUARIOS = "/v1/nucleo/usuarios";
    }

    /** Organização: Associações/Missões, distritos, igrejas. */
    public static final class Organizacao {

        private Organizacao() {
        }

        /** CargosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String CARGOS = "/v1/organizacao/cargos";

        /** DepartamentosIgrejaController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String DEPARTAMENTOS_IGREJA = "/v1/organizacao/departamentos-igreja";

        /** DepartamentosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String DEPARTAMENTOS = "/v1/organizacao/departamentos";

        /** DistritosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String DISTRITOS = "/v1/organizacao/distritos";

        /** EntidadesController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String ENTIDADES = "/v1/organizacao/entidades";

        /** POST /v1/organizacao/entidades/{id}/fundos-padrao  (EntidadesController.fundosPadrao) */
        public static final String ENTIDADES_FUNDOS_PADRAO = "{id: \\d+}/fundos-padrao";

        /** IgrejasController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String IGREJAS = "/v1/organizacao/igrejas";
    }

    /** Secretaria: livro de membros (F-SEC). */
    public static final class Secretaria {

        private Secretaria() {
        }

        /** BaptismosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String BAPTISMOS = "/v1/secretaria/baptismos";

        /** ConsentimentosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String CONSENTIMENTOS = "/v1/secretaria/consentimentos";

        /** ContactosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String CONTACTOS = "/v1/secretaria/contactos";

        /** DisciplinasController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String DISCIPLINAS = "/v1/secretaria/disciplinas";

        /** FamiliasController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String FAMILIAS = "/v1/secretaria/familias";

        /** MembrosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String MEMBROS = "/v1/secretaria/membros";

        /** POST /v1/secretaria/membros/{id}/validar  (MembrosController.validar) */
        public static final String MEMBROS_VALIDAR = "{id: \\d+}/validar";

        /** MovimentosMembroController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String MOVIMENTOS_MEMBRO = "/v1/secretaria/movimentos-membro";

        /** OficiaisController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String OFICIAIS = "/v1/secretaria/oficiais";

        /** RelatoriosSecretariaController */
        public static final String RELATORIOS = "/v1/secretaria";

        /** GET /v1/secretaria/relatorio-mensal  (RelatoriosSecretariaController.relatorioMensal) */
        public static final String RELATORIO_MENSAL = "relatorio-mensal";

        /** GET /v1/secretaria/cartas-pendentes  (RelatoriosSecretariaController.cartasPendentes) */
        public static final String CARTAS_PENDENTES = "cartas-pendentes";

        /** GET /v1/secretaria/censuras-activas  (RelatoriosSecretariaController.censurasActivas) */
        public static final String CENSURAS_ACTIVAS = "censuras-activas";

        /** GET /v1/secretaria/mandatos-a-terminar  (RelatoriosSecretariaController.mandatosATerminar) */
        public static final String MANDATOS_A_TERMINAR = "mandatos-a-terminar";

        /** GET /v1/secretaria/menores-pendentes  (RelatoriosSecretariaController.menoresPendentes) */
        public static final String MENORES_PENDENTES = "menores-pendentes";

        /** GET /v1/secretaria/familias-resumo  (RelatoriosSecretariaController.familiasResumo) */
        public static final String FAMILIAS_RESUMO = "familias-resumo";

        /** GET /v1/secretaria/membros-basico  (RelatoriosSecretariaController.membrosBasico) */
        public static final String MEMBROS_BASICO = "membros-basico";

        /** ReunioesController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String REUNIOES = "/v1/secretaria/reunioes";

        /**
         * <pre>
         * GET /v1/secretaria/reunioes/{id}/votos  (ReunioesController.votos)
         * POST /v1/secretaria/reunioes/{id}/votos  (ReunioesController.criarVoto)
         * </pre>
         */
        public static final String REUNIOES_VOTOS = "{id: \\d+}/votos";

        /** TransferenciasController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String TRANSFERENCIAS = "/v1/secretaria/transferencias";

        /** POST /v1/secretaria/transferencias/{id}/emitir-carta  (TransferenciasController.emitirCarta) */
        public static final String TRANSFERENCIAS_EMITIR_CARTA = "{id: \\d+}/emitir-carta";

        /** POST /v1/secretaria/transferencias/{id}/concluir  (TransferenciasController.concluir) */
        public static final String TRANSFERENCIAS_CONCLUIR = "{id: \\d+}/concluir";

        /** POST /v1/secretaria/transferencias/{id}/recusar  (TransferenciasController.recusar) */
        public static final String TRANSFERENCIAS_RECUSAR = "{id: \\d+}/recusar";

        /** VotosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String VOTOS = "/v1/secretaria/votos";
    }

    /** Escola Sabatina (F-ES). */
    public static final class EscolaSabatina {

        private EscolaSabatina() {
        }

        /** ClassesController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String CLASSES = "/v1/escola-sabatina/classes";

        /** ClassesTrimestreController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String CLASSES_TRIMESTRE = "/v1/escola-sabatina/classes-trimestre";

        /** MatriculasController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String MATRICULAS = "/v1/escola-sabatina/matriculas";

        /** PesosPontuacaoController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String PESOS_PONTUACAO = "/v1/escola-sabatina/pesos-pontuacao";

        /** PresencasController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String PRESENCAS = "/v1/escola-sabatina/presencas";

        /** RelatoriosEscolaSabatinaController */
        public static final String RELATORIOS = "/v1/escola-sabatina";

        /** GET /v1/escola-sabatina/classificacao  (RelatoriosEscolaSabatinaController.classificacao) */
        public static final String CLASSIFICACAO = "classificacao";

        /** GET /v1/escola-sabatina/painel  (RelatoriosEscolaSabatinaController.painel) */
        public static final String PAINEL = "painel";

        /** GET /v1/escola-sabatina/evolucao  (RelatoriosEscolaSabatinaController.evolucao) */
        public static final String EVOLUCAO = "evolucao";

        /** GET /v1/escola-sabatina/relatorios-em-falta  (RelatoriosEscolaSabatinaController.relatoriosEmFalta) */
        public static final String RELATORIOS_EM_FALTA = "relatorios-em-falta";

        /** GET /v1/escola-sabatina/conferencia-ofertas  (RelatoriosEscolaSabatinaController.conferenciaOfertas) */
        public static final String CONFERENCIA_OFERTAS = "conferencia-ofertas";

        /** GET /v1/escola-sabatina/relatorio-associacao  (RelatoriosEscolaSabatinaController.relatorioAssociacao) */
        public static final String RELATORIO_ASSOCIACAO = "relatorio-associacao";

        /** GET /v1/escola-sabatina/resumo-classes  (RelatoriosEscolaSabatinaController.resumoClasses) */
        public static final String RESUMO_CLASSES = "resumo-classes";

        /** GET /v1/escola-sabatina/visitantes-a-anonimizar  (RelatoriosEscolaSabatinaController.visitantesAAnonimizar) */
        public static final String VISITANTES_A_ANONIMIZAR = "visitantes-a-anonimizar";

        /** RelatoriosSabadoController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String RELATORIOS_SABADO = "/v1/escola-sabatina/relatorios-sabado";

        /** PUT /v1/escola-sabatina/relatorios-sabado/{id}/presencas  (RelatoriosSabadoController.presencas) */
        public static final String RELATORIOS_SABADO_PRESENCAS = "{id: \\d+}/presencas";

        /**
         * <pre>
         * GET /v1/escola-sabatina/relatorios-sabado/{id}/visitantes  (RelatoriosSabadoController.visitantes)
         * POST /v1/escola-sabatina/relatorios-sabado/{id}/visitantes  (RelatoriosSabadoController.criarVisitante)
         * </pre>
         */
        public static final String RELATORIOS_SABADO_VISITANTES = "{id: \\d+}/visitantes";

        /** POST /v1/escola-sabatina/relatorios-sabado/{id}/ofertas  (RelatoriosSabadoController.ofertas) */
        public static final String RELATORIOS_SABADO_OFERTAS = "{id: \\d+}/ofertas";

        /** POST /v1/escola-sabatina/relatorios-sabado/{id}/fechar  (RelatoriosSabadoController.fechar) */
        public static final String RELATORIOS_SABADO_FECHAR = "{id: \\d+}/fechar";

        /** POST /v1/escola-sabatina/relatorios-sabado/{id}/reabrir  (RelatoriosSabadoController.reabrir) */
        public static final String RELATORIOS_SABADO_REABRIR = "{id: \\d+}/reabrir";

        /** SabadosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String SABADOS = "/v1/escola-sabatina/sabados";

        /** TrimestresController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String TRIMESTRES = "/v1/escola-sabatina/trimestres";

        /** VisitantesController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String VISITANTES = "/v1/escola-sabatina/visitantes";
    }

    /** Tesouraria (F-TES). */
    public static final class Tesouraria {

        private Tesouraria() {
        }

        /** AlvosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String ALVOS = "/v1/tesouraria/alvos";

        /** CalendarioOfertasController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String CALENDARIO_OFERTAS = "/v1/tesouraria/calendario-ofertas";

        /** CategoriasController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String CATEGORIAS = "/v1/tesouraria/categorias";

        /** ContagensController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String CONTAGENS = "/v1/tesouraria/contagens";

        /** ContasController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String CONTAS = "/v1/tesouraria/contas";

        /** DespesasController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String DESPESAS = "/v1/tesouraria/despesas";

        /** POST /v1/tesouraria/despesas/{id}/decidir  (DespesasController.decidir) */
        public static final String DESPESAS_DECIDIR = "{id: \\d+}/decidir";

        /** DocumentosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String DOCUMENTOS = "/v1/tesouraria/documentos";

        /** ExtractosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String EXTRACTOS = "/v1/tesouraria/extractos";

        /** POST /v1/tesouraria/extractos/importar  (ExtractosController.importar) */
        public static final String EXTRACTOS_IMPORTAR = "importar";

        /** POST /v1/tesouraria/extractos/{id}/reconciliar  (ExtractosController.reconciliar) */
        public static final String EXTRACTOS_RECONCILIAR = "{id: \\d+}/reconciliar";

        /** FechosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String FECHOS = "/v1/tesouraria/fechos";

        /** POST /v1/tesouraria/fechos/{id}/reabrir  (FechosController.reabrir) */
        public static final String FECHOS_REABRIR = "{id: \\d+}/reabrir";

        /** FundosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String FUNDOS = "/v1/tesouraria/fundos";

        /** LinhasOrcamentoController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String LINHAS_ORCAMENTO = "/v1/tesouraria/linhas-orcamento";

        /** LinhasRemessaController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String LINHAS_REMESSA = "/v1/tesouraria/linhas-remessa";

        /** LinhasTransacaoController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String LINHAS_TRANSACAO = "/v1/tesouraria/linhas-transacao";

        /** OrcamentosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String ORCAMENTOS = "/v1/tesouraria/orcamentos";

        /** POST /v1/tesouraria/orcamentos/{id}/aprovar  (OrcamentosController.aprovar) */
        public static final String ORCAMENTOS_APROVAR = "{id: \\d+}/aprovar";

        /** RecibosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String RECIBOS = "/v1/tesouraria/recibos";

        /** RelatoriosTesourariaController */
        public static final String RELATORIOS = "/v1/tesouraria";

        /** GET /v1/tesouraria/saldos-contas  (RelatoriosTesourariaController.saldosContas) */
        public static final String SALDOS_CONTAS = "saldos-contas";

        /** GET /v1/tesouraria/saldos-fundos  (RelatoriosTesourariaController.saldosFundos) */
        public static final String SALDOS_FUNDOS = "saldos-fundos";

        /** GET /v1/tesouraria/remessas-devidas  (RelatoriosTesourariaController.remessasDevidas) */
        public static final String REMESSAS_DEVIDAS = "remessas-devidas";

        /** GET /v1/tesouraria/execucao-orcamento  (RelatoriosTesourariaController.execucaoOrcamento) */
        public static final String EXECUCAO_ORCAMENTO = "execucao-orcamento";

        /** GET /v1/tesouraria/contribuicoes  (RelatoriosTesourariaController.contribuicoes) */
        public static final String CONTRIBUICOES = "contribuicoes";

        /** GET /v1/tesouraria/extracto-anual  (RelatoriosTesourariaController.extractoAnual) */
        public static final String EXTRACTO_ANUAL = "extracto-anual";

        /** GET /v1/tesouraria/progresso-alvos  (RelatoriosTesourariaController.progressoAlvos) */
        public static final String PROGRESSO_ALVOS = "progresso-alvos";

        /** GET /v1/tesouraria/conferencia-contagens  (RelatoriosTesourariaController.conferenciaContagens) */
        public static final String CONFERENCIA_CONTAGENS = "conferencia-contagens";

        /** GET /v1/tesouraria/despesas-por-pagar  (RelatoriosTesourariaController.despesasPorPagar) */
        public static final String DESPESAS_POR_PAGAR = "despesas-por-pagar";

        /** GET /v1/tesouraria/extractos-por-reconciliar  (RelatoriosTesourariaController.extractosPorReconciliar) */
        public static final String EXTRACTOS_POR_RECONCILIAR = "extractos-por-reconciliar";

        /** POST /v1/tesouraria/recalcular-saldos  (SaldosController.recalcular) */
        public static final String RECALCULAR_SALDOS = "/v1/tesouraria/recalcular-saldos";

        /** RemessasController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String REMESSAS = "/v1/tesouraria/remessas";

        /** POST /v1/tesouraria/remessas/{id}/enviar  (RemessasController.enviar) */
        public static final String REMESSAS_ENVIAR = "{id: \\d+}/enviar";

        /** POST /v1/tesouraria/remessas/{id}/confirmar  (RemessasController.confirmar) */
        public static final String REMESSAS_CONFIRMAR = "{id: \\d+}/confirmar";

        /** SaldosDiariosContaController · rotas-padrão: listar, ler */
        public static final String SALDOS_DIARIOS_CONTA = "/v1/tesouraria/saldos-diarios-conta";

        /** SaldosDiariosFundoController · rotas-padrão: listar, ler */
        public static final String SALDOS_DIARIOS_FUNDO = "/v1/tesouraria/saldos-diarios-fundo";

        /** TransacoesController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String TRANSACOES = "/v1/tesouraria/transacoes";

        /** GET /v1/tesouraria/transacoes/{id}/linhas  (TransacoesController.linhas) */
        public static final String TRANSACOES_LINHAS = "{id: \\d+}/linhas";

        /** POST /v1/tesouraria/transacoes/{id}/aprovar  (TransacoesController.aprovar) */
        public static final String TRANSACOES_APROVAR = "{id: \\d+}/aprovar";

        /** POST /v1/tesouraria/transacoes/{id}/confirmar  (TransacoesController.confirmar) */
        public static final String TRANSACOES_CONFIRMAR = "{id: \\d+}/confirmar";

        /** POST /v1/tesouraria/transacoes/{id}/estornar  (TransacoesController.estornar) */
        public static final String TRANSACOES_ESTORNAR = "{id: \\d+}/estornar";

        /** POST /v1/tesouraria/transacoes/{id}/recibo  (TransacoesController.recibo) */
        public static final String TRANSACOES_RECIBO = "{id: \\d+}/recibo";
    }

    /** Actividades e departamentos. */
    public static final class Actividades {

        private Actividades() {
        }

        /** ActividadesController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String ACTIVIDADES = "/v1/actividades/actividades";

        /** EscalasController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String ESCALAS = "/v1/actividades/escalas";

        /** MateriaisController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String MATERIAIS = "/v1/actividades/materiais";

        /** RelatoriosActividadesController */
        public static final String RELATORIOS = "/v1/actividades";

        /** GET /v1/actividades/escalas-proximas  (RelatoriosActividadesController.escalasProximas) */
        public static final String ESCALAS_PROXIMAS = "escalas-proximas";
    }

    /** Pagamentos M-Pesa (F-PAG). */
    public static final class Pagamentos {

        private Pagamentos() {
        }

        /** BancariosController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String BANCARIOS = "/v1/pagamentos/bancarios";

        /** MpesaCallbacksController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String MPESA_CALLBACKS = "/v1/pagamentos/mpesa-callbacks";

        /** MpesaController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String MPESA = "/v1/pagamentos/mpesa";

        /** POST /v1/pagamentos/mpesa/callback  (MpesaController.callback) */
        public static final String MPESA_CALLBACK = "callback";

        /** RelatoriosPagamentosController */
        public static final String RELATORIOS = "/v1/pagamentos";

        /** GET /v1/pagamentos/mpesa-pendentes  (RelatoriosPagamentosController.mpesaPendentes) */
        public static final String MPESA_PENDENTES = "mpesa-pendentes";
    }

    /** Comunicação: mensagens e notificações (F-COM). */
    public static final class Comunicacao {

        private Comunicacao() {
        }

        /** NotificacoesController · rotas-padrão: listar, ler, criar, alterar, terminar, reactivar */
        public static final String NOTIFICACOES = "/v1/comunicacao/notificacoes";

        /** RelatoriosComunicacaoController */
        public static final String RELATORIOS = "/v1/comunicacao";

        /** GET /v1/comunicacao/notificacoes-a-enviar  (RelatoriosComunicacaoController.notificacoesAEnviar) */
        public static final String NOTIFICACOES_A_ENVIAR = "notificacoes-a-enviar";
    }
}
