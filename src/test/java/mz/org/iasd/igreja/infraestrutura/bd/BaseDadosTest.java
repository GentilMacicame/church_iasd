package mz.org.iasd.igreja.infraestrutura.bd;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;
import java.util.UUID;
import java.util.stream.Stream;

import javax.sql.DataSource;

import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonObject;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.postgresql.ds.PGSimpleDataSource;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.containers.PostgreSQLContainer;

import mz.org.iasd.igreja.repositories.auth.AuthRepository;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.infraestrutura.erros.TradutorErrosSql;
import mz.org.iasd.igreja.controllers.escolasabatina.RelatoriosEscolaSabatinaController;
import mz.org.iasd.igreja.services.escolasabatina.RelatoriosSabadoService;
import mz.org.iasd.igreja.repositories.eu.EuRepository;
import mz.org.iasd.igreja.controllers.tesouraria.RelatoriosTesourariaController;
import mz.org.iasd.igreja.services.tesouraria.TransacoesService;
import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.TabelaRepository;
import mz.org.iasd.igreja.infraestrutura.seguranca.Segredos;
import mz.org.iasd.igreja.infraestrutura.seguranca.Senhas;
import mz.org.iasd.igreja.infraestrutura.tarefas.TarefasAgendadas;
import mz.org.iasd.igreja.models.organizacao.Igreja;
import mz.org.iasd.igreja.models.tesouraria.TransacaoLinha;
import mz.org.iasd.igreja.models.escolasabatina.RelatorioSabado;
import mz.org.iasd.igreja.models.secretaria.Membro;
import mz.org.iasd.igreja.models.secretaria.Familia;

/**
 * Fase 0 contra PostgreSQL real (migrações V1–V15), sempre como {@code api_igreja} (nunca o dono):
 * unidade de trabalho com set_config, permissões dos 13 perfis, tradução de erros, sessões,
 * recuperação de senha, idempotência e paginação.
 *
 * <p>Onde corre:
 * <ul>
 *   <li>com Docker: num PostgreSQL 16 descartável (Testcontainers);</li>
 *   <li>sem Docker: num servidor existente, se definir {@code BD_TESTE_URL} (ex.:
 *       {@code jdbc:postgresql://localhost:5432/postgres}), {@code BD_TESTE_UTILIZADOR} (super-utilizador,
 *       por defeito postgres) e {@code BD_TESTE_SENHA}. É criada (e recriada) a base {@code igreja_teste_api}
 *       e o papel de login {@code api_igreja_teste};</li>
 *   <li>sem nenhum dos dois, os testes são ignorados.</li>
 * </ul>
 */
class BaseDadosTest {

    static final String BASE_TESTE = "igreja_teste_api";
    static final String PAPEL_API = "api_igreja_teste";

    static PostgreSQLContainer<?> contentor;
    static String url;
    static String dono;
    static String senhaDono;

    static DataSource api;
    static int entidade;
    static int igrejaCentral;
    static int igrejaBairro;
    static int igrejaOutraAssociacao;
    static int tesoureiro;

    @BeforeAll
    static void preparar() throws Exception {
        Path pasta = Path.of(System.getProperty("migracoes.dir", "database/migrations"));
        assumeTrue(Files.isDirectory(pasta), "Pasta das migrações não encontrada: " + pasta.toAbsolutePath()
                + " (defina -Dmigracoes.dir=...)");

        String externo = System.getenv("BD_TESTE_URL");
        if (externo != null && !externo.isBlank()) {
            dono = System.getenv().getOrDefault("BD_TESTE_UTILIZADOR", "postgres");
            senhaDono = System.getenv("BD_TESTE_SENHA");
            try (Connection admin = DriverManager.getConnection(externo, dono, senhaDono);
                 Statement st = admin.createStatement()) {
                st.execute("DROP DATABASE IF EXISTS " + BASE_TESTE + " WITH (FORCE)");
                st.execute("CREATE DATABASE " + BASE_TESTE);
            }
            url = externo.replaceFirst("/[^/?]+(\\?.*)?$", "/" + BASE_TESTE + "$1");
        } else {
            assumeTrue(DockerClientFactory.instance().isDockerAvailable(),
                    "Sem Docker nem BD_TESTE_URL: testes de integração ignorados");
            contentor = new PostgreSQLContainer<>("postgres:16").withEnv("TZ", "Africa/Maputo");
            contentor.start();
            url = contentor.getJdbcUrl();
            dono = contentor.getUsername();
            senhaDono = contentor.getPassword();
        }

        try (Connection dono = ligarComoDono(); Statement st = dono.createStatement()) {
            for (Path f : migracoes(pasta)) {
                st.execute(Files.readString(f, StandardCharsets.UTF_8));
            }
            // papel próprio dos testes (não mexe no api_igreja de um servidor existente)
            st.execute("DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '" + PAPEL_API + "') THEN "
                    + "CREATE ROLE " + PAPEL_API + " LOGIN PASSWORD 'teste' IN ROLE app_igreja; END IF; END $$");
            st.execute("ALTER ROLE " + PAPEL_API + " SET search_path = nucleo, organizacao, secretaria, actividades, "
                    + "escola_sabatina, tesouraria, pagamentos, comunicacao, public");

            entidade = inserir(dono, "INSERT INTO organizacao.entidade (ent_tipo, ent_nome, ent_sigla) "
                    + "VALUES ('ASSOCIACAO', 'Associação de Teste', 'AT') RETURNING ent_id");
            int outra = inserir(dono, "INSERT INTO organizacao.entidade (ent_tipo, ent_nome) "
                    + "VALUES ('MISSAO', 'Outra Missão') RETURNING ent_id");
            igrejaCentral = inserir(dono, "INSERT INTO organizacao.igreja (igr_ent_id, igr_nome) VALUES (" + entidade
                    + ", 'Igreja Central') RETURNING igr_id");
            igrejaBairro = inserir(dono, "INSERT INTO organizacao.igreja (igr_ent_id, igr_nome) VALUES (" + entidade
                    + ", 'Igreja do Bairro') RETURNING igr_id");
            igrejaOutraAssociacao = inserir(dono, "INSERT INTO organizacao.igreja (igr_ent_id, igr_nome) VALUES ("
                    + outra + ", 'Igreja Longe') RETURNING igr_id");
            tesoureiro = criarUsuario(dono, "tesoureiro@teste.mz", "+258840000001", "TESOUREIRO");
        }

        PGSimpleDataSource ds = new PGSimpleDataSource();
        ds.setURL(url);
        ds.setUser(PAPEL_API);
        ds.setPassword("teste");
        api = ds;
    }

    @AfterAll
    static void terminar() {
        if (contentor != null) {
            contentor.stop();
        }
    }

    private static Connection ligarComoDono() throws SQLException {
        return DriverManager.getConnection(url, dono, senhaDono);
    }

    // ------------------------------------------------------------------ unidade de trabalho e RLS

    @Test
    void semUtilizadorIdentificadoNaoDevolveLinhas() throws Exception {
        long n = ExecutorTransaccao.executar(api, null, c -> contar(c, "SELECT count(*) FROM organizacao.igreja"));
        assertEquals(0, n);
    }

    @Test
    void oUtilizadorSoValeDentroDaTransaccao() throws Exception {
        String depois = ExecutorTransaccao.executar(api, tesoureiro, c -> {
            c.commit();   // fim da transacção: set_config(..., true) deixa de valer
            try (Statement st = c.createStatement();
                 ResultSet rs = st.executeQuery("SELECT current_setting('app.usuario_id', true)")) {
                rs.next();
                return rs.getString(1);
            }
        });
        assertTrue(depois == null || depois.isEmpty());
    }

    @Test
    void tesoureiroSoVeASuaIgreja() throws Exception {
        var igreja = Catalogo.de(Igreja.class);
        var pagina = ExecutorTransaccao.executar(api, tesoureiro, c -> TabelaRepository.listar(c, igreja, Map.of()));
        assertEquals(List.of(igrejaCentral), ids(pagina.getJsonArray("dados")));
        // existe mas não é visível → a API responde 404
        assertTrue(ExecutorTransaccao.executar(api, tesoureiro,
                c -> TabelaRepository.obter(c, igreja, igrejaBairro)).isEmpty());
    }

    @Test
    void paginacaoPorCursor() throws Exception {
        int admin = criarUsuarioComDono("admin.assoc@teste.mz", null, "ADMIN_ASSOCIACAO");
        var igreja = Catalogo.de(Igreja.class);
        var p1 = ExecutorTransaccao.executar(api, admin,
                c -> TabelaRepository.listar(c, igreja, Map.of("limite", "1")));
        assertEquals(1, p1.getJsonArray("dados").size());
        assertFalse(p1.isNull("proximo"));
        var p2 = ExecutorTransaccao.executar(api, admin, c -> TabelaRepository.listar(c, igreja,
                Map.of("limite", "1", "depois", p1.getString("proximo"))));
        assertEquals(List.of(igrejaBairro), ids(p2.getJsonArray("dados")));
        assertTrue(p2.isNull("proximo"));   // a igreja da outra Missão não é visível

        // ordenação descendente pelo nome, também com cursor ("Igreja do Bairro" > "Igreja Central")
        var d1 = ExecutorTransaccao.executar(api, admin, c -> TabelaRepository.listar(c, igreja,
                Map.of("limite", "1", "ordem", "-nome")));
        assertEquals(List.of(igrejaBairro), ids(d1.getJsonArray("dados")));
        var d2 = ExecutorTransaccao.executar(api, admin, c -> TabelaRepository.listar(c, igreja,
                Map.of("limite", "1", "ordem", "-nome", "depois", d1.getString("proximo"))));
        assertEquals(List.of(igrejaCentral), ids(d2.getJsonArray("dados")));
    }

    // ------------------------------------------------------------------ permissões dos 13 perfis

    @ParameterizedTest
    @ValueSource(strings = {"ADMIN", "PASTOR", "ANCIAO", "SECRETARIO", "TESOUREIRO", "DIRECTOR_ES", "SECRETARIO_ES",
            "DIRECTOR_DEPARTAMENTO", "MEMBRO", "ADMIN_ASSOCIACAO", "TESOUREIRO_ASSOCIACAO", "SECRETARIO_ASSOCIACAO",
            "INTEGRACAO"})
    void cadaPerfilTemExactamenteAsSuasPermissoes(String perfil) throws Exception {
        int usu = criarUsuarioComDono(perfil.toLowerCase() + "@perfis.mz", null, perfil);
        Map<Integer, TreeSet<String>> minhas = ExecutorTransaccao.executar(api, usu, EuRepository::permissoes);
        TreeSet<String> esperadas = permissoesDoPerfil(perfil);

        assertEquals(esperadas, minhas.getOrDefault(igrejaCentral, new TreeSet<>()), "permissões de " + perfil);
        assertFalse(minhas.containsKey(igrejaOutraAssociacao), perfil + " não pode ter nada noutra Missão");
        if ("MEMBRO".equals(perfil)) {
            assertTrue(minhas.isEmpty());
        }
    }

    // ------------------------------------------------------------------ tradução de erros

    @Test
    void regraDeNegocioDevolve422ComAMensagemDaBase() {
        SQLException e = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, tesoureiro,
                c -> contar(c, "SELECT count(*) FROM (SELECT tesouraria.fn_aprovar_saida(999999)) x")));
        TradutorErrosSql.Traducao t = TradutorErrosSql.traduzir(e);
        assertEquals(422, t.estadoHttp());
        assertEquals("regra_negocio", t.codigo());
        assertEquals("Só se aprova uma saída pendente", t.mensagem());
    }

    @Test
    void escritaNoutraAreaDevolve403() {
        SQLException e = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, tesoureiro, c -> {
            try (PreparedStatement ps = c.prepareStatement(
                    "INSERT INTO secretaria.familia (fam_igr_id, fam_nome) VALUES (?, 'Família X')")) {
                ps.setInt(1, igrejaCentral);
                return ps.executeUpdate();
            }
        }));
        TradutorErrosSql.Traducao t = TradutorErrosSql.traduzir(e);
        assertEquals(403, t.estadoHttp());
        assertEquals("sem_permissao", t.codigo());
        assertEquals("Sem permissão para gravar este registo nesta igreja", t.mensagem());
    }

    // ------------------------------------------------------------------ autenticação e sessões

    @Test
    void loginERotacaoDoTokenDeRenovacao() throws Exception {
        int usu = criarUsuarioComDono("sessoes@teste.mz", null, "SECRETARIO", "senha-forte-1");

        var cred = ExecutorTransaccao.executar(api, null, c -> AuthRepository.credenciais(c, "sessoes@teste.mz"));
        assertTrue(cred.isPresent());
        assertTrue(Senhas.confere("senha-forte-1", cred.get().senhaHash()));

        String t1 = Segredos.tokenAleatorio();
        ExecutorTransaccao.executar(api, null, c -> AuthRepository.abrirSessao(c, usu, Segredos.sha256(t1), "10.0.0.1", "teste"));

        String t2 = Segredos.tokenAleatorio();
        var r1 = renovar(t1, t2);
        assertEquals("OK", r1.resultado());
        assertEquals(usu, r1.usuarioId());

        var reutilizado = renovar(t1, Segredos.tokenAleatorio());
        assertEquals("REUTILIZADA", reutilizado.resultado());
        // a reutilização terminou todas as sessões, incluindo a de t2
        assertEquals("EXPIRADA", renovar(t2, Segredos.tokenAleatorio()).resultado());
        assertEquals("INVALIDA", renovar("nao-existe", Segredos.tokenAleatorio()).resultado());
    }

    @Test
    void dezFalhasBloqueiamOLogin() throws Exception {
        String login = "bloqueio@teste.mz";
        for (int i = 0; i < 10; i++) {
            ExecutorTransaccao.executar(api, null, c -> {
                AuthRepository.loginFalhou(c, login);
                return null;
            });
        }
        assertNotNull(ExecutorTransaccao.executar(api, null, c -> AuthRepository.bloqueadoAte(c, login)));
        assertNull(ExecutorTransaccao.executar(api, null, c -> AuthRepository.bloqueadoAte(c, "outro@teste.mz")));
    }

    @Test
    void recuperacaoDeSenha() throws Exception {
        criarUsuarioComDono("recuperar@teste.mz", "+258840000099", "MEMBRO", "senha-antiga");
        String segredo = "segredo-dos-codigos-de-teste";
        String codigo = "123456";

        var pedido = ExecutorTransaccao.executar(api, null,
                c -> AuthRepository.pedirRecuperacao(c, "recuperar@teste.mz", Segredos.hmac(segredo, codigo)));
        assertEquals("+258840000099", pedido.orElseThrow().telefone());
        assertTrue(ExecutorTransaccao.executar(api, null,
                c -> AuthRepository.pedirRecuperacao(c, "ninguem@teste.mz", Segredos.hmac(segredo, codigo))).isEmpty());

        String novaHash = Senhas.gerarHash("senha-nova-123");
        assertEquals("CODIGO_ERRADO", ExecutorTransaccao.executar(api, null,
                c -> AuthRepository.redefinirSenha(c, "recuperar@teste.mz", Segredos.hmac(segredo, "000000"), novaHash)));
        assertEquals("OK", ExecutorTransaccao.executar(api, null,
                c -> AuthRepository.redefinirSenha(c, "recuperar@teste.mz", Segredos.hmac(segredo, codigo), novaHash)));
        assertEquals("EXPIRADO", ExecutorTransaccao.executar(api, null,
                c -> AuthRepository.redefinirSenha(c, "recuperar@teste.mz", Segredos.hmac(segredo, codigo), novaHash)));

        var cred = ExecutorTransaccao.executar(api, null, c -> AuthRepository.credenciais(c, "recuperar@teste.mz"));
        assertTrue(Senhas.confere("senha-nova-123", cred.orElseThrow().senhaHash()));
    }

    // ------------------------------------------------------------------ idempotência e /v1/eu

    @Test
    void idempotencyKeyGuardaARespostaPorUtilizador() throws Exception {
        UUID chave = UUID.randomUUID();
        ExecutorTransaccao.executar(api, tesoureiro, c -> {
            IdempotenciaRepository.guardar(c, chave, "POST", "/v1/tesouraria/transacoes", 201, "{\"id\": 10}");
            return null;
        });
        var guardada = ExecutorTransaccao.executar(api, tesoureiro, c -> IdempotenciaRepository.obter(c, chave));
        assertEquals(201, guardada.orElseThrow().estadoHttp());
        assertEquals("/v1/tesouraria/transacoes", guardada.get().caminho());

        int outro = criarUsuarioComDono("idem@teste.mz", null, "TESOUREIRO");
        assertTrue(ExecutorTransaccao.executar(api, outro, c -> IdempotenciaRepository.obter(c, chave)).isEmpty());

        // a mesma chave duas vezes pelo mesmo utilizador → 23505 → 409 duplicado
        SQLException e = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, tesoureiro, c -> {
            IdempotenciaRepository.guardar(c, chave, "POST", "/v1/tesouraria/transacoes", 201, null);
            return null;
        }));
        assertEquals(409, TradutorErrosSql.traduzir(e).estadoHttp());
    }

    @Test
    void euDevolveOUtilizadorEAsIgrejas() throws Exception {
        EuRepository.Eu eu = ExecutorTransaccao.executar(api, tesoureiro, EuRepository::carregar).orElseThrow();
        assertEquals(tesoureiro, eu.usuario().id());
        assertEquals(1, eu.igrejas().size());
        assertEquals("Igreja Central", eu.igrejas().get(0).nome());
        assertTrue(eu.permissoes().get(Integer.toString(igrejaCentral)).contains("tesouraria.transacao.criar"));
        assertFalse(eu.permissoes().get(Integer.toString(igrejaCentral)).contains("tesouraria.transacao.aprovar"));
    }

    // ------------------------------------------------------------------ recursos genéricos

    @Test
    void criarAlterarTerminarComPerfis() throws Exception {
        int secretario = criarUsuarioComDono("secretario.crud@teste.mz", null, "SECRETARIO");
        var familia = Catalogo.de(Familia.class);
        JsonObject corpo = Json.createObjectBuilder().add("igrejaId", igrejaCentral).add("nome", "Familia Macuacua").build();

        JsonObject criada = ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.criar(c, familia, corpo));
        long id = criada.getJsonNumber("id").longValue();
        assertEquals("Familia Macuacua", criada.getString("nome"));
        assertEquals(secretario, criada.getInt("criadoPor"));            // preenchido pelo trigger
        assertTrue(criada.isNull("endDate"));

        // o tesoureiro não cria famílias (RLS) → 403
        SQLException e = assertThrows(SQLException.class,
                () -> ExecutorTransaccao.executar(api, tesoureiro, c -> TabelaRepository.criar(c, familia, corpo)));
        assertEquals(403, TradutorErrosSql.traduzir(e).estadoHttp());
        // ... nem a vê → 404
        ApiException naoVe = assertThrows(ApiException.class, () -> ExecutorTransaccao.executar(api, tesoureiro,
                c -> TabelaRepository.alterar(c, familia, id, Json.createObjectBuilder().add("nome", "X").build())));
        assertEquals(404, naoVe.estadoHttp());

        JsonObject alterada = ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.alterar(c, familia, id,
                Json.createObjectBuilder().add("morada", "Bairro Central").add("id", 999).build()));
        assertEquals("Bairro Central", alterada.getString("morada"));
        assertEquals(id, alterada.getJsonNumber("id").longValue());       // campos só de leitura são ignorados

        ApiException desconhecido = assertThrows(ApiException.class, () -> ExecutorTransaccao.executar(api, secretario,
                c -> TabelaRepository.alterar(c, familia, id, Json.createObjectBuilder().add("cor", "azul").build())));
        assertEquals("cor", desconhecido.campo());

        JsonObject terminada = ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.terminar(c, familia, id));
        assertFalse(terminada.isNull("endDate"));
        ApiException outraVez = assertThrows(ApiException.class,
                () -> ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.terminar(c, familia, id)));
        assertEquals(422, outraVez.estadoHttp());
        JsonObject reactivada = ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.reactivar(c, familia, id));
        assertTrue(reactivada.isNull("endDate"));
    }

    @Test
    void listagemDeTabelaPorIgrejaExigeIgrejaId() {
        ApiException e = assertThrows(ApiException.class, () -> ExecutorTransaccao.executar(api, tesoureiro,
                c -> TabelaRepository.listar(c, Catalogo.de(Membro.class), Map.of())));
        assertEquals("igrejaId", e.campo());
    }

    @Test
    void campoObrigatorioEmFaltaDa400() throws Exception {
        int secretario = criarUsuarioComDono("secretario.obrig@teste.mz", null, "SECRETARIO");
        SQLException e = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, secretario,
                c -> TabelaRepository.criar(c, Catalogo.de(Membro.class),
                        Json.createObjectBuilder().add("igrejaId", igrejaCentral).add("nome", "Ana").build())));
        TradutorErrosSql.Traducao t = TradutorErrosSql.traduzir(e);
        assertEquals(400, t.estadoHttp());
        assertEquals("apelido", t.campo());
    }

    /** P-08 Saída avulsa: o tesoureiro regista e não aprova; o ancião aprova; só então se confirma. */
    @Test
    void processoSaidaAvulsa() throws Exception {
        Tesouraria tes = prepararTesouraria();
        int anciao = criarUsuarioComDono("anciao.p08@teste.mz", null, "ANCIAO");
        JsonObject saida = Json.createObjectBuilder()
                .add("tipo", "SAIDA").add("metodo", "NUMERARIO").add("valorTotal", "100.00").add("contaId", tes.conta())
                .add("descricao", "Conta da luz")
                .add("linhas", Json.createArrayBuilder().add(Json.createObjectBuilder()
                        .add("fundoId", tes.fundoLocal()).add("categoriaId", tes.categoriaLuz()).add("valor", "100.00")))
                .build();
        JsonObject tra = ExecutorTransaccao.executar(api, tesoureiro, c -> TransacoesService.criar(c, saida));
        long id = tra.getJsonNumber("id").longValue();
        assertEquals("PENDENTE", tra.getString("estado"));
        assertEquals("100.00", tra.getString("valorTotal"));

        // confirmar sem aprovação → 422 (verificado no COMMIT)
        SQLException semAprovacao = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, tesoureiro,
                c -> TransacoesService.confirmar(c, id)));
        assertEquals(422, TradutorErrosSql.traduzir(semAprovacao).estadoHttp());
        // o tesoureiro não aprova → 403
        SQLException tesoureiroAprova = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, tesoureiro,
                c -> TransacoesService.aprovar(c, id)));
        assertEquals(403, TradutorErrosSql.traduzir(tesoureiroAprova).estadoHttp());

        var aprovada = ExecutorTransaccao.executar(api, anciao, c -> TransacoesService.aprovar(c, id));
        assertEquals(anciao, aprovada.getInt("aprovadoPorUsuarioId"));
        var confirmada = ExecutorTransaccao.executar(api, tesoureiro,
                c -> TransacoesService.confirmar(c, id));
        assertEquals("CONFIRMADA", confirmada.getString("estado"));

        JsonArray linhas = ExecutorTransaccao.executar(api, tesoureiro,
                c -> TabelaRepository.filhos(c, Catalogo.de(TransacaoLinha.class), "tli_tra_id", id));
        assertEquals("100.00", linhas.getJsonObject(0).getString("valor"));
        JsonArray saldos = ExecutorTransaccao.executar(api, tesoureiro, c -> RelatoriosTesourariaController.SALDOS_CONTAS.consultar(c,
                Map.of("igrejaId", Integer.toString(igrejaCentral))));
        assertTrue(saldos.getJsonObject(0).containsKey("saldo"));
    }

    @Test
    void somaDasLinhasDiferenteDoTotalDa422() throws Exception {
        Tesouraria tes = prepararTesouraria();
        JsonObject errada = Json.createObjectBuilder()
                .add("tipo", "ENTRADA").add("metodo", "NUMERARIO").add("valorTotal", "50.00").add("contaId", tes.conta())
                .add("linhas", Json.createArrayBuilder().add(Json.createObjectBuilder()
                        .add("fundoId", tes.fundoLocal()).add("categoriaId", tes.categoriaLuz()).add("valor", "40.00")))
                .build();
        SQLException e = assertThrows(SQLException.class,
                () -> ExecutorTransaccao.executar(api, tesoureiro, c -> TransacoesService.criar(c, errada)));
        TradutorErrosSql.Traducao t = TradutorErrosSql.traduzir(e);
        assertEquals(422, t.estadoHttp());
        assertTrue(t.mensagem().contains("soma das linhas"), t.mensagem());
    }

    /** P-05 Relatório do sábado: abrir, chamada, ofertas lançadas pelo tesoureiro, fechar. */
    @Test
    void processoRelatorioDoSabado() throws Exception {
        Tesouraria tes = prepararTesouraria();
        int directorEs = criarUsuarioComDono("director.es@teste.mz", null, "DIRECTOR_ES");
        long classeTrimestre;
        long sabado;
        long membro;
        try (Connection dono = ligarComoDono()) {
            long trimestre = inserir(dono, "INSERT INTO escola_sabatina.trimestre (etr_ano, etr_numero, etr_data_inicio, "
                    + "etr_data_fim, etr_num_sabados) VALUES (2026, 4, '2026-10-03', '2026-12-26', 13) RETURNING etr_id");
            sabado = inserir(dono, "INSERT INTO escola_sabatina.sabado (esa_etr_id, esa_numero, esa_data) VALUES ("
                    + trimestre + ", 1, '2026-10-03') RETURNING esa_id");
            long classe = inserir(dono, "INSERT INTO escola_sabatina.classe (ecl_igr_id, ecl_nome) VALUES ("
                    + igrejaCentral + ", 'Classe Esperanca') RETURNING ecl_id");
            classeTrimestre = inserir(dono, "INSERT INTO escola_sabatina.classe_trimestre (ect_ecl_id, ect_etr_id) VALUES ("
                    + classe + ", " + trimestre + ") RETURNING ect_id");
            membro = inserir(dono, "INSERT INTO secretaria.membro (mem_igr_id, mem_nome, mem_apelido) VALUES ("
                    + igrejaCentral + ", 'Joao', 'Sitoe') RETURNING mem_id");
        }
        final long ect = classeTrimestre;
        final long esa = sabado;
        JsonObject rel = ExecutorTransaccao.executar(api, directorEs, c -> TabelaRepository.criar(c,
                Catalogo.de(RelatorioSabado.class), Json.createObjectBuilder()
                        .add("classeTrimestreId", ect).add("sabadoId", esa)
                        .add("membrosMatriculados", 10).add("membrosPresentes", 0)
                        .add("oferta", "150.00").add("oferta13Sabado", "0.00").add("ofertaDespesas", "50.00").build()));
        long ers = rel.getJsonNumber("id").longValue();
        assertEquals(igrejaCentral, rel.getInt("igrejaId"));                // copiado pelo trigger

        var chamada = Json.createArrayBuilder().add(Json.createObjectBuilder()
                .add("membroId", membro).add("presente", true).add("estudouLicao", true)).build();
        var depoisChamada = ExecutorTransaccao.executar(api, directorEs,
                c -> RelatoriosSabadoService.gravarPresencas(c, ers, chamada));
        assertEquals(1, depoisChamada.getInt("membrosPresentes"));

        // fechar antes de lançar as ofertas → 422
        SQLException cedo = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, directorEs,
                c -> RelatoriosSabadoService.mudarEstado(c, ers, "FECHADO")));
        assertEquals(422, TradutorErrosSql.traduzir(cedo).estadoHttp());

        JsonObject ofertas = Json.createObjectBuilder().add("contaId", tes.conta()).add("missoes", "150.00")
                .add("decimoTerceiro", "0.00").add("despesas", "50.00").build();
        var tra = ExecutorTransaccao.executar(api, tesoureiro,
                c -> RelatoriosSabadoService.lancarOfertas(c, ers, ofertas));
        assertEquals("200.00", tra.getString("valorTotal"));

        var fechado = ExecutorTransaccao.executar(api, directorEs,
                c -> RelatoriosSabadoService.mudarEstado(c, ers, "FECHADO"));
        assertEquals("FECHADO", fechado.getString("estado"));

        JsonArray conferencia = ExecutorTransaccao.executar(api, directorEs, c -> RelatoriosEscolaSabatinaController.CONFERENCIA_OFERTAS.consultar(c, Map.of()));
        assertEquals("Conferido", conferencia.getJsonObject(0).getString("situacao"));
    }

    // ------------------------------------------------------------------ apoio

    record Tesouraria(long conta, long fundoLocal, long categoriaLuz) {
    }

    // ------------------------------------------------------------------ V15: perfis próprios e manutenção

    @Test
    void cadaUtilizadorVeOsSeusPerfisMasNaoOsDosOutros() throws Exception {
        int secretario = criarUsuarioComDono("secretario.v15@teste.mz", "+258840000151", "SECRETARIO");
        long meus = ExecutorTransaccao.executar(api, tesoureiro, c -> contar(c,
                "SELECT count(*) FROM nucleo.usuario_igreja WHERE uig_usu_id = " + tesoureiro));
        long doOutro = ExecutorTransaccao.executar(api, tesoureiro, c -> contar(c,
                "SELECT count(*) FROM nucleo.usuario_igreja WHERE uig_usu_id = " + secretario));
        assertEquals(1, meus);
        assertEquals(0, doOutro);
        EuRepository.Eu eu = ExecutorTransaccao.executar(api, tesoureiro, EuRepository::carregar).orElseThrow();
        assertEquals(List.of("TESOUREIRO"), eu.igrejas().get(0).perfis());
    }

    @Test
    void tarefasAgendadasCorremComOPapelDaApiSemUtilizador() {
        for (TarefasAgendadas.Tarefa t : TarefasAgendadas.DIARIAS) {
            assertNotNull(TarefasAgendadas.correr(api, t), t.nome());
        }
    }

    @Test
    void visitanteAntigoEAnonimizadoSemFicarNoLog() throws Exception {
        int visitante;
        try (Connection dono = ligarComoDono()) {
            int trimestre = inserir(dono, "INSERT INTO escola_sabatina.trimestre (etr_ano, etr_numero, etr_data_inicio, "
                    + "etr_data_fim, etr_num_sabados) VALUES (2024, 1, '2024-01-06', '2024-03-30', 13) RETURNING etr_id");
            int sabado = inserir(dono, "INSERT INTO escola_sabatina.sabado (esa_etr_id, esa_numero, esa_data) VALUES ("
                    + trimestre + ", 1, '2024-01-06') RETURNING esa_id");
            int classe = inserir(dono, "INSERT INTO escola_sabatina.classe (ecl_igr_id, ecl_nome) VALUES (" + igrejaCentral
                    + ", 'Classe V15') RETURNING ecl_id");
            int ect = inserir(dono, "INSERT INTO escola_sabatina.classe_trimestre (ect_ecl_id, ect_etr_id) VALUES ("
                    + classe + ", " + trimestre + ") RETURNING ect_id");
            int ers = inserir(dono, "INSERT INTO escola_sabatina.relatorio_sabado (ers_ect_id, ers_esa_id, "
                    + "ers_membros_matriculados, ers_membros_presentes) VALUES (" + ect + ", " + sabado + ", 5, 3) RETURNING ers_id");
            visitante = inserir(dono, "INSERT INTO escola_sabatina.visitante (evi_ers_id, evi_nome, evi_telefone) VALUES ("
                    + ers + ", 'Visitante Antigo V15', '+258849999999') RETURNING evi_id");
        }
        Integer n = TarefasAgendadas.correr(api, TarefasAgendadas.DIARIAS.get(2));
        assertNotNull(n);
        assertTrue(n >= 1);
        try (Connection dono = ligarComoDono()) {
            assertEquals(1, contar(dono, "SELECT count(*) FROM escola_sabatina.visitante WHERE evi_id = " + visitante
                    + " AND evi_nome = 'Anonimizado' AND evi_telefone IS NULL AND evi_anonimizado_em IS NOT NULL"));
            assertEquals(0, contar(dono, "SELECT count(*) FROM nucleo.log_auditoria "
                    + "WHERE coalesce(lau_dados_antes::text, '') LIKE '%Visitante Antigo V15%'"));
        }
    }

    @Test
    void fundosPadraoSoComPermissao() throws Exception {
        int admin = criarUsuarioComDono("admin.assoc.v15@teste.mz", "+258840000152", "ADMIN_ASSOCIACAO");
        int secretario = criarUsuarioComDono("secretario2.v15@teste.mz", "+258840000153", "SECRETARIO");
        long criados = ExecutorTransaccao.executar(api, admin, c -> {
            try (Statement st = c.createStatement()) {
                st.execute("SELECT tesouraria.fn_criar_fundos_padrao(" + entidade + ", 20, 'V15')");
            }
            return contar(c, "SELECT count(*) FROM tesouraria.fundo WHERE fun_criado_em = now() "
                    + "AND fun_criado_por = nucleo.fn_usuario_sessao()");
        });
        assertEquals(7, criados);
        SQLException e = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, secretario, c -> {
            try (Statement st = c.createStatement()) {
                return st.execute("SELECT tesouraria.fn_criar_fundos_padrao(" + entidade + ", 20, 'V15B')");
            }
        }));
        assertEquals(403, TradutorErrosSql.traduzir(e).estadoHttp());
    }

    @Test
    void recalcularSaldosSoComPermissao() throws Exception {
        prepararTesouraria();
        int secretario = criarUsuarioComDono("secretario3.v15@teste.mz", "+258840000154", "SECRETARIO");
        ExecutorTransaccao.executar(api, tesoureiro, c -> {
            try (Statement st = c.createStatement()) {
                return st.execute("SELECT tesouraria.fn_recalcular_saldos(" + igrejaCentral + ")");
            }
        });
        SQLException e = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, secretario, c -> {
            try (Statement st = c.createStatement()) {
                return st.execute("SELECT tesouraria.fn_recalcular_saldos(" + igrejaCentral + ")");
            }
        }));
        assertEquals(403, TradutorErrosSql.traduzir(e).estadoHttp());
    }

    private static Tesouraria tesouraria;

    /** Conta de caixa na Igreja Central e fundos-padrão da Associação (uma vez por execução). */
    private static synchronized Tesouraria prepararTesouraria() throws SQLException {
        if (tesouraria == null) {
            try (Connection dono = ligarComoDono()) {
                try (Statement st = dono.createStatement()) {
                    st.execute("SELECT tesouraria.fn_criar_fundos_padrao(" + entidade + ", 0)");
                }
                long conta = inserir(dono, "INSERT INTO tesouraria.conta_financeira (cfi_igr_id, cfi_tipo, cfi_nome, "
                        + "cfi_data_saldo_inicial) VALUES (" + igrejaCentral + ", 'CAIXA', 'Caixa', '2026-01-01') RETURNING cfi_id");
                long fundo = inserir(dono, "SELECT fun_id FROM tesouraria.fundo WHERE fun_codigo = 'OLOC'");
                long categoria = inserir(dono, "SELECT cat_id FROM tesouraria.categoria WHERE cat_codigo = 'D2'");
                tesouraria = new Tesouraria(conta, fundo, categoria);
            }
        }
        return tesouraria;
    }

    private static List<Integer> ids(JsonArray dados) {
        return dados.stream().map(v -> ((JsonObject) v).getInt("id")).toList();
    }

    private static AuthRepository.Renovacao renovar(String actual, String novo) throws Exception {
        return ExecutorTransaccao.executar(api, null,
                c -> AuthRepository.renovarSessao(c, Segredos.sha256(actual), Segredos.sha256(novo), null, null));
    }

    private static List<Path> migracoes(Path pasta) throws Exception {
        try (Stream<Path> s = Files.list(pasta)) {
            return s.filter(p -> p.getFileName().toString().matches("V\\d+__.*\\.sql"))
                    .sorted(Comparator.comparingInt(p -> Integer.parseInt(p.getFileName().toString().replaceAll("^V(\\d+)__.*", "$1"))))
                    .toList();
        }
    }

    private static int criarUsuarioComDono(String email, String telefone, String perfil) throws SQLException {
        return criarUsuarioComDono(email, telefone, perfil, "senha-de-teste");
    }

    private static int criarUsuarioComDono(String email, String telefone, String perfil, String senha) throws SQLException {
        try (Connection dono = ligarComoDono()) {
            return criarUsuario(dono, email, telefone, perfil, senha);
        }
    }

    private static int criarUsuario(Connection dono, String email, String telefone, String perfil) throws SQLException {
        return criarUsuario(dono, email, telefone, perfil, "senha-de-teste");
    }

    /** Perfil de igreja → na Igreja Central; perfil de Associação → na Associação de Teste. */
    private static int criarUsuario(Connection dono, String email, String telefone, String perfil, String senha)
            throws SQLException {
        int usu;
        try (PreparedStatement ps = dono.prepareStatement("INSERT INTO nucleo.usuario (usu_nome, usu_email, usu_telefone, "
                + "usu_senha_hash) VALUES (?, ?, ?, ?) RETURNING usu_id")) {
            ps.setString(1, "Teste " + perfil);
            ps.setString(2, email);
            ps.setString(3, telefone);
            ps.setString(4, Senhas.gerarHash(senha));
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                usu = rs.getInt(1);
            }
        }
        String sql = "SELECT per_ambito FROM nucleo.perfil WHERE per_nome = ?";
        String ambito;
        try (PreparedStatement ps = dono.prepareStatement(sql)) {
            ps.setString(1, perfil);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                ambito = rs.getString(1);
            }
        }
        String atribuir = "IGREJA".equals(ambito)
                ? "INSERT INTO nucleo.usuario_igreja (uig_usu_id, uig_igr_id, uig_per_id) SELECT ?, ?, per_id FROM nucleo.perfil WHERE per_nome = ?"
                : "INSERT INTO nucleo.usuario_entidade (uen_usu_id, uen_ent_id, uen_per_id) SELECT ?, ?, per_id FROM nucleo.perfil WHERE per_nome = ?";
        try (PreparedStatement ps = dono.prepareStatement(atribuir)) {
            ps.setInt(1, usu);
            ps.setInt(2, "IGREJA".equals(ambito) ? igrejaCentral : entidade);
            ps.setString(3, perfil);
            ps.executeUpdate();
        }
        return usu;
    }

    private static TreeSet<String> permissoesDoPerfil(String perfil) throws SQLException {
        TreeSet<String> r = new TreeSet<>();
        try (Connection dono = ligarComoDono();
             PreparedStatement ps = dono.prepareStatement("SELECT pm.prm_codigo FROM nucleo.perfil_permissao pp "
                     + "JOIN nucleo.perfil pf ON pf.per_id = pp.ppe_per_id JOIN nucleo.permissao pm ON pm.prm_id = pp.ppe_prm_id "
                     + "WHERE pf.per_nome = ? AND pp.ppe_end_date IS NULL")) {
            ps.setString(1, perfil);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    r.add(rs.getString(1));
                }
            }
        }
        return r;
    }

    private static int inserir(Connection c, String sql) throws SQLException {
        try (Statement st = c.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            return rs.getInt(1);
        }
    }

    private static long contar(Connection c, String sql) throws SQLException {
        try (Statement st = c.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            return rs.getLong(1);
        }
    }
}
