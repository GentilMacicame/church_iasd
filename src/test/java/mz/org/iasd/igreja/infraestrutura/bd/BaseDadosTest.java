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
import jakarta.json.JsonValue;

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
import mz.org.iasd.igreja.infraestrutura.erros.MensagensRestricoes;
import mz.org.iasd.igreja.infraestrutura.erros.TradutorErrosSql;
import mz.org.iasd.igreja.controllers.escolasabatina.RelatoriosEscolaSabatinaController;
import mz.org.iasd.igreja.services.escolasabatina.RelatoriosSabadoService;
import mz.org.iasd.igreja.repositories.eu.EuRepository;
import mz.org.iasd.igreja.controllers.tesouraria.RelatoriosTesourariaController;
import mz.org.iasd.igreja.controllers.secretaria.RelatoriosSecretariaController;
import mz.org.iasd.igreja.controllers.organizacao.RelatoriosOrganizacaoController;
import mz.org.iasd.igreja.services.tesouraria.DocumentosService;
import mz.org.iasd.igreja.services.tesouraria.TransacoesService;
import mz.org.iasd.igreja.infraestrutura.ficheiros.ArmazemFicheiros;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.repositories.base.TabelaRepository;
import mz.org.iasd.igreja.infraestrutura.seguranca.Segredos;
import mz.org.iasd.igreja.infraestrutura.seguranca.Senhas;
import mz.org.iasd.igreja.infraestrutura.tarefas.TarefasAgendadas;
import mz.org.iasd.igreja.models.organizacao.Igreja;
import mz.org.iasd.igreja.models.tesouraria.TransacaoLinha;
import mz.org.iasd.igreja.models.escolasabatina.RelatorioSabado;
import mz.org.iasd.igreja.models.secretaria.Membro;
import mz.org.iasd.igreja.models.actividades.Escala;
import mz.org.iasd.igreja.models.actividades.EscalaPlano;
import mz.org.iasd.igreja.models.secretaria.Familia;
import mz.org.iasd.igreja.models.secretaria.Mandato;
import mz.org.iasd.igreja.models.secretaria.Oficial;
import mz.org.iasd.igreja.models.secretaria.Reuniao;
import mz.org.iasd.igreja.models.secretaria.ReuniaoPonto;
import mz.org.iasd.igreja.models.secretaria.ReuniaoPresenca;

/**
 * Fase 0 contra PostgreSQL real (migrações V1–V17), sempre como {@code api_igreja} (nunca o dono):
 * unidade de trabalho com set_config, permissões dos 13 perfis, tradução de erros, sessões,
 * recuperação de senha, idempotência e paginação.
 *
 * <p>Onde corre (por esta ordem):
 * <ol>
 *   <li>{@code BD_TESTE_URL} (ex.: {@code jdbc:postgresql://localhost:5432/postgres}), com
 *       {@code BD_TESTE_UTILIZADOR} (super-utilizador, por defeito postgres) e {@code BD_TESTE_SENHA};</li>
 *   <li>o servidor do {@code .env} (BD_SERVIDOR, BD_PORTA, BD_ADMIN_UTILIZADOR, BD_ADMIN_SENHA), se responder;</li>
 *   <li>com Docker: um PostgreSQL 16 descartável (Testcontainers);</li>
 *   <li>sem nenhum, os testes são ignorados.</li>
 * </ol>
 * Num servidor existente é criada (e recriada) a base {@code <BD_NOME_TESTE>_api} (nome do {@code .env} ou do
 * ambiente) e o papel de login
 * {@code api_igreja_teste}; as outras bases não são tocadas.
 */
class BaseDadosTest {

    static String baseTeste;
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
        String donoExterno = System.getenv().getOrDefault("BD_TESTE_UTILIZADOR", "postgres");
        String senhaExterna = System.getenv("BD_TESTE_SENHA");
        if (externo == null || externo.isBlank()) {
            // sem BD_TESTE_URL: o servidor e o administrador do .env, se responderem
            Map<String, String> env = lerEnv(Path.of(".env"));
            // só o servidor do PC: os testes criam e apagam bases (num servidor remoto, só com BD_TESTE_URL explícito)
            boolean local = java.util.Set.of("localhost", "127.0.0.1", "::1")
                    .contains(env.getOrDefault("BD_SERVIDOR", "localhost"));
            if (local && env.containsKey("BD_ADMIN_UTILIZADOR")) {
                String candidato = "jdbc:postgresql://" + env.getOrDefault("BD_SERVIDOR", "localhost") + ":"
                        + env.getOrDefault("BD_PORTA", "5432") + "/postgres";
                try (Connection teste = DriverManager.getConnection(candidato, env.get("BD_ADMIN_UTILIZADOR"),
                        env.get("BD_ADMIN_SENHA"))) {
                    externo = candidato;
                    donoExterno = env.get("BD_ADMIN_UTILIZADOR");
                    senhaExterna = env.get("BD_ADMIN_SENHA");
                } catch (SQLException e) {
                    System.out.println("BaseDadosTest: o servidor do .env (" + candidato + ") não respondeu: "
                            + e.getMessage() + " — a tentar o Docker");
                }
            }
        }
        if (externo != null && !externo.isBlank()) {
            dono = donoExterno;
            senhaDono = senhaExterna;
            // o nome vem do .env (ou do ambiente), nunca do código; esta base é apagada e criada de novo
            String nomeTeste = System.getenv().getOrDefault("BD_NOME_TESTE", lerEnv(Path.of(".env")).get("BD_NOME_TESTE"));
            assumeTrue(nomeTeste != null && nomeTeste.matches("[A-Za-z_][A-Za-z0-9_]*"),
                    "Defina BD_NOME_TESTE no .env (só letras, números e _) para os testes de integração");
            baseTeste = nomeTeste + "_api";
            try (Connection admin = DriverManager.getConnection(externo, dono, senhaDono);
                 Statement st = admin.createStatement()) {
                st.execute("DROP DATABASE IF EXISTS " + baseTeste + " WITH (FORCE)");
                st.execute("CREATE DATABASE " + baseTeste);
            }
            url = externo.replaceFirst("/[^/?]+(\\?.*)?$", "/" + baseTeste + "$1");
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
                    + "escola_sabatina, tesouraria, public");

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

        // logo a seguir é um segundo separador do mesmo navegador (V16): CONCORRENTE, nada terminado
        assertEquals("CONCORRENTE", renovar(t1, Segredos.tokenAleatorio()).resultado());
        // passado mais de 10 s, o token antigo a voltar é roubo
        try (Connection dono = ligarComoDono(); Statement st = dono.createStatement()) {
            // a sessão já está terminada (protegida pelo trigger-padrão): só o dono, só aqui, para simular o tempo
            st.execute("ALTER TABLE nucleo.sessao DISABLE TRIGGER trg_ses_00_padrao");
            st.execute("UPDATE nucleo.sessao SET ses_usado_em = now() - INTERVAL '1 minute' WHERE ses_refresh_hash = '"
                    + Segredos.sha256(t1) + "'");
            st.execute("ALTER TABLE nucleo.sessao ENABLE TRIGGER trg_ses_00_padrao");
        }
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
            IdempotenciaRepository.guardar(c, chave, "POST", "/v1/tesouraria/transacoes", 201, "{\"id\": 10}", "hash-a");
            return null;
        });
        var guardada = ExecutorTransaccao.executar(api, tesoureiro, c -> IdempotenciaRepository.obter(c, chave));
        assertEquals(201, guardada.orElseThrow().estadoHttp());
        assertEquals("/v1/tesouraria/transacoes", guardada.get().caminho());
        assertEquals("hash-a", guardada.get().pedidoHash());

        int outro = criarUsuarioComDono("idem@teste.mz", null, "TESOUREIRO");
        assertTrue(ExecutorTransaccao.executar(api, outro, c -> IdempotenciaRepository.obter(c, chave)).isEmpty());

        // a mesma chave duas vezes pelo mesmo utilizador → 23505 → 409 duplicado
        SQLException e = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, tesoureiro, c -> {
            IdempotenciaRepository.guardar(c, chave, "POST", "/v1/tesouraria/transacoes", 201, null, null);
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
        // o tesoureiro vê as famílias (secretaria.familia.ler) mas não as altera → 403
        ApiException naoAltera = assertThrows(ApiException.class, () -> ExecutorTransaccao.executar(api, tesoureiro,
                c -> TabelaRepository.alterar(c, familia, id, Json.createObjectBuilder().add("nome", "X").build())));
        assertEquals(403, naoAltera.estadoHttp());
        // o director da ES nem as vê → 404 (não revela que existe)
        int directorEs = criarUsuarioComDono("director.es.crud@teste.mz", null, "DIRECTOR_ES");
        ApiException naoVe = assertThrows(ApiException.class, () -> ExecutorTransaccao.executar(api, directorEs,
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

        // V29: a recusa por CHECK chega com a frase escrita na base (lida como a API a lê, com o papel da API)
        var frases = ExecutorTransaccao.executar(api, null, c -> {
            Map<String, String> m = new java.util.HashMap<>();
            try (PreparedStatement ps = c.prepareStatement("SELECT nome, mensagem FROM nucleo.fn_mensagens_restricoes()");
                 java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    m.put(rs.getString(1), rs.getString(2));
                }
            }
            return m;
        });
        MensagensRestricoes.definir(frases);
        try {
            SQLException demais = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, directorEs,
                    c -> TabelaRepository.actualizar(c, Catalogo.de(RelatorioSabado.class), ers,
                            List.of(TabelaRepository.Valor.campo(Catalogo.de(RelatorioSabado.class), "membrosPresentes", "11")), null)));
            TradutorErrosSql.Traducao t = TradutorErrosSql.traduzir(demais);
            assertEquals(422, t.estadoHttp());
            assertEquals("validacao", t.codigo());
            assertTrue(t.mensagem().startsWith("Os números do relatório não batem"), t.mensagem());
        } finally {
            MensagensRestricoes.definir(Map.of());
        }

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

    // ------------------------------------------------------------------ V31: mandatos, conselho e direcção

    @Test
    void mandatoComOficiaisNoConselhoENaDireccao() throws Exception {
        int secretario = criarUsuarioComDono("secretario.v31@teste.mz", "+258840000311", "SECRETARIO");
        int membro;
        int cargoConselho;
        try (Connection dono = ligarComoDono()) {
            membro = inserir(dono, "INSERT INTO secretaria.membro (mem_igr_id, mem_nome, mem_apelido, mem_estado) VALUES ("
                    + igrejaCentral + ", 'Rute', 'Mandato', 'ACTIVO') RETURNING mem_id");
            cargoConselho = inserir(dono, "SELECT car_id FROM organizacao.cargo WHERE car_conselho ORDER BY car_id LIMIT 1");
        }
        var mandato = Catalogo.de(Mandato.class);
        var oficial = Catalogo.de(Oficial.class);

        // autorizado: o secretário cria o mandato e elege o oficial dentro dele (datas e órgão vêm sozinhos)
        JsonObject mdt = ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.criar(c, mandato, Json.createObjectBuilder()
                .add("igrejaId", igrejaCentral).add("nome", "Mandato 2033–2034").add("dataInicio", "2033-01-01").add("dataFim", "2034-12-31").build()));
        long mdtId = mdt.getJsonNumber("id").longValue();
        JsonObject ofi = ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.criar(c, oficial, Json.createObjectBuilder()
                .add("membroId", membro).add("cargoId", cargoConselho).add("igrejaId", igrejaCentral).add("mandatoId", mdtId).build()));
        assertEquals("2033-01-01", ofi.getString("dataInicio"));
        assertEquals("2034-12-31", ofi.getString("fimPrevisto"));
        assertEquals("CONSELHO", ofi.getString("orgao"));
        JsonArray conselho = ExecutorTransaccao.executar(api, secretario, c -> RelatoriosSecretariaController.CONSELHO.consultar(c,
                Map.of("igrejaId", String.valueOf(igrejaCentral))));
        assertTrue(conselho.stream().map(JsonValue::asJsonObject)
                .anyMatch(o -> o.getInt("membroId") == membro && o.getInt("mandatoId") == mdtId && "CONSELHO".equals(o.getString("orgao"))), conselho.toString());

        // um mandato que se sobrepõe: 422 com a frase da base
        SQLException sobreposto = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.criar(c, mandato,
                Json.createObjectBuilder().add("igrejaId", igrejaCentral).add("nome", "Mandato sobreposto").add("dataInicio", "2034-06-01").add("dataFim", "2035-05-31").build())));
        assertEquals(422, TradutorErrosSql.traduzir(sobreposto).estadoHttp());

        // não autorizado: o tesoureiro não cria mandatos (403)
        SQLException semPermissao = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, tesoureiro, c -> TabelaRepository.criar(c, mandato,
                Json.createObjectBuilder().add("igrejaId", igrejaCentral).add("nome", "Mandato do tesoureiro").add("dataInicio", "2040-01-01").add("dataFim", "2040-12-31").build())));
        assertEquals(403, TradutorErrosSql.traduzir(semPermissao).estadoHttp());
    }

    // ------------------------------------------------------------------ V30: painel geral das igrejas

    @Test
    void painelGeralSoComAsIgrejasDoDistritoDoPastor() throws Exception {
        int pastor;
        int semPerfil;
        int igrejaDoDistrito;
        try (Connection dono = ligarComoDono()) {
            pastor = inserir(dono, "INSERT INTO nucleo.usuario (usu_nome, usu_email, usu_senha_hash) "
                    + "VALUES ('Pastor do distrito', 'pastor.distrito@teste.mz', 'x') RETURNING usu_id");
            semPerfil = inserir(dono, "INSERT INTO nucleo.usuario (usu_nome, usu_email, usu_senha_hash) "
                    + "VALUES ('Sem perfil', 'sem.perfil.painel@teste.mz', 'x') RETURNING usu_id");
            // na outra Missão, para não mudar o número de igrejas da Associação de Teste (paginacaoPorCursor)
            int outraMissao = inserir(dono, "SELECT ent_id FROM organizacao.entidade WHERE ent_nome = 'Outra Missão'");
            int distrito = inserir(dono, "INSERT INTO organizacao.distrito (dst_ent_id, dst_nome, dst_pastor_usu_id) VALUES ("
                    + outraMissao + ", 'Distrito Norte', " + pastor + ") RETURNING dst_id");
            igrejaDoDistrito = inserir(dono, "INSERT INTO organizacao.igreja (igr_ent_id, igr_nome, igr_dst_id) VALUES ("
                    + outraMissao + ", 'Igreja do Distrito Norte', " + distrito + ") RETURNING igr_id");
            inserir(dono, "INSERT INTO secretaria.membro (mem_igr_id, mem_nome, mem_apelido, mem_estado) VALUES ("
                    + igrejaDoDistrito + ", 'Ana', 'Norte', 'ACTIVO') RETURNING mem_id");
        }

        // autorizado: o pastor do distrito vê só as igrejas do seu distrito, com os membros e a tesouraria
        JsonArray doPastor = ExecutorTransaccao.executar(api, pastor,
                c -> RelatoriosOrganizacaoController.PAINEL_IGREJAS.consultar(c, Map.of()));
        assertEquals(1, doPastor.size(), doPastor.toString());
        JsonObject linha = doPastor.getJsonObject(0);
        assertEquals(igrejaDoDistrito, linha.getInt("id"));
        assertEquals("Distrito Norte", linha.getString("distritoPastoral"));
        assertTrue(linha.getBoolean("veMembros"));
        assertTrue(linha.getBoolean("veTesouraria"));
        assertEquals(1, linha.getInt("membrosActivos"));
        JsonArray mensal = ExecutorTransaccao.executar(api, pastor,
                c -> RelatoriosOrganizacaoController.PAINEL_IGREJAS_MENSAL.consultar(c, Map.of()));
        assertEquals(12, mensal.size(), "12 meses da única igreja do distrito");

        // não autorizado: sem perfil, não vê nenhuma igreja
        assertEquals(0, ExecutorTransaccao.executar(api, semPerfil,
                c -> RelatoriosOrganizacaoController.PAINEL_IGREJAS.consultar(c, Map.of())).size());
        // o tesoureiro da Igreja Central não vê a igreja do distrito
        JsonArray doTesoureiro = ExecutorTransaccao.executar(api, tesoureiro,
                c -> RelatoriosOrganizacaoController.PAINEL_IGREJAS.consultar(c, Map.of()));
        assertTrue(doTesoureiro.stream().map(JsonValue::asJsonObject).noneMatch(o -> o.getInt("id") == igrejaDoDistrito), doTesoureiro.toString());
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

    // ------------------------------------------------------------------ V16: correcções da auditoria

    @Test
    void hashDaSenhaNaoFicaNoLogDeAuditoria() throws Exception {
        int usuario = criarUsuarioComDono("log.senha.v16@teste.mz", "+258840000161", "SECRETARIO");
        String codigo = "123456";
        ExecutorTransaccao.executar(api, null, c -> AuthRepository.pedirRecuperacao(c, "log.senha.v16@teste.mz",
                Segredos.sha256(codigo)));
        String r = ExecutorTransaccao.executar(api, null, c -> AuthRepository.redefinirSenha(c, "log.senha.v16@teste.mz",
                Segredos.sha256(codigo), Senhas.gerarHash("senha-nova-v16")));
        assertEquals("OK", r);
        try (Connection dono = ligarComoDono()) {
            assertEquals(0, contar(dono, "SELECT count(*) FROM nucleo.log_auditoria WHERE lau_tabela = 'nucleo.usuario' "
                    + "AND lau_registo_id = " + usuario + " AND (coalesce(lau_dados_antes::text, '') || lau_dados_depois::text) LIKE '%$argon2%'"));
            assertTrue(contar(dono, "SELECT count(*) FROM nucleo.log_auditoria WHERE lau_tabela = 'nucleo.usuario' "
                    + "AND lau_registo_id = " + usuario + " AND lau_dados_depois ->> 'usu_senha_hash' = '(alterada)'") >= 1);
        }
    }

    @Test
    void tokenDeSessaoTerminadaDeixaDeServir() throws Exception {
        long sessao = ExecutorTransaccao.executar(api, null,
                c -> AuthRepository.abrirSessao(c, tesoureiro, Segredos.sha256("refresh-v16-a"), null, null));
        assertEquals(1, (int) ExecutorTransaccao.executar(api, tesoureiro, sessao, c -> 1));
        ExecutorTransaccao.executar(api, tesoureiro, c -> {
            AuthRepository.terminarSessao(c, Segredos.sha256("refresh-v16-a"));
            return null;
        });
        ApiException e = assertThrows(ApiException.class, () -> ExecutorTransaccao.executar(api, tesoureiro, sessao, c -> 1));
        assertEquals(401, e.estadoHttp());
    }

    @Test
    void renovacaoSimultaneaNaoTerminaAsSessoes() throws Exception {
        ExecutorTransaccao.executar(api, null,
                c -> AuthRepository.abrirSessao(c, tesoureiro, Segredos.sha256("refresh-v16-b"), null, null));
        assertEquals("OK", renovar("refresh-v16-b", "refresh-v16-c").resultado());
        // o mesmo token logo a seguir (outro separador do mesmo navegador): CONCORRENTE, não REUTILIZADA
        assertEquals("CONCORRENTE", renovar("refresh-v16-b", "refresh-v16-x").resultado());
        assertEquals("OK", renovar("refresh-v16-c", "refresh-v16-d").resultado(), "a sessão nova continua válida");
    }

    @Test
    void loginNaoDistingueMaiusculasNoEmail() throws Exception {
        var cred = ExecutorTransaccao.executar(api, null, c -> AuthRepository.credenciais(c, "TESOUREIRO@Teste.MZ"));
        assertEquals(tesoureiro, cred.orElseThrow().usuarioId());
    }

    @Test
    void pesquisaDeMembrosPorNome() throws Exception {
        ExecutorTransaccao.executar(api, tesoureiro, c -> TabelaRepository.listar(c, Catalogo.de(Membro.class),
                Map.of("igrejaId", Integer.toString(igrejaCentral), "q", "silva")));
    }

    // ------------------------------------------------------------------ V17: escalas e lembretes por SMS

    @Test
    void escalaElaboradaPublicadaComLembreteEnviado() throws Exception {
        int secretario = criarUsuarioComDono("sec.escala.v17@teste.mz", "+258840000171", "SECRETARIO");
        int elisa;
        try (Connection dono = ligarComoDono()) {
            elisa = inserir(dono, "INSERT INTO secretaria.membro (mem_igr_id, mem_nome, mem_apelido) VALUES ("
                    + igrejaCentral + ", 'Elisa', 'Fumo') RETURNING mem_id");
            inserir(dono, "INSERT INTO secretaria.contacto (cto_mem_id, cto_tipo, cto_valor, cto_principal) VALUES ("
                    + elisa + ", 'TELEFONE', '84 111 0000', true) RETURNING cto_id");
            inserir(dono, "INSERT INTO secretaria.consentimento (cns_mem_id, cns_tipo, cns_concedido) VALUES ("
                    + elisa + ", 'CONTACTO_SMS', true) RETURNING cns_id");
        }
        JsonObject corpoPlano = Json.createObjectBuilder().add("igrejaId", igrejaCentral).add("titulo", "Escala de Pregação")
                .add("dataInicio", "2026-10-01").add("dataFim", "2026-12-31").build();

        // o tesoureiro não elabora escalas → 403
        SQLException recusa = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, tesoureiro,
                c -> TabelaRepository.criar(c, Catalogo.de(EscalaPlano.class), corpoPlano)));
        assertEquals(403, TradutorErrosSql.traduzir(recusa).estadoHttp());

        long plano = ExecutorTransaccao.executar(api, secretario,
                c -> TabelaRepository.criar(c, Catalogo.de(EscalaPlano.class), corpoPlano)).getJsonNumber("id").longValue();
        int sabados = ExecutorTransaccao.executar(api, secretario, c -> {
            try (Statement st = c.createStatement();
                 ResultSet rs = st.executeQuery("SELECT actividades.fn_gerar_dias_escala(" + plano + ")")) {
                rs.next();
                return rs.getInt(1);
            }
        });
        assertEquals(13, sabados);
        long dia = ExecutorTransaccao.executar(api, secretario, c -> contar(c,
                "SELECT eds_id FROM actividades.escala_dia WHERE eds_epl_id = " + plano + " AND eds_data = '2026-10-17'"));

        // a pessoa escalada no dia: a data e a igreja vêm do dia
        JsonObject escala = ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.criar(c,
                Catalogo.de(Escala.class), Json.createObjectBuilder().add("escalaDiaId", dia)
                        .add("funcao", "PREGADOR").add("membroId", elisa).build()));
        assertEquals("2026-10-17", escala.getString("data"));
        assertEquals(igrejaCentral, escala.getInt("igrejaId"));

        // por publicar: sem lembretes; publicada: um lembrete na quarta, sem repetir
        assertEquals(0, lembretes("2026-10-14 10:00+02"));
        ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.alterar(c, Catalogo.de(EscalaPlano.class), plano,
                Json.createObjectBuilder().add("publicada", true).build()));
        assertEquals(1, lembretes("2026-10-14 10:00+02"));
        assertEquals(0, lembretes("2026-10-14 11:00+02"));

        // a tarefa de envio manda-o ao fornecedor (aqui: uma lista) e marca-o ENVIADA
        List<String> enviados = new java.util.ArrayList<>();
        TarefasAgendadas.enviarFila(api, (destino, texto) -> enviados.add(destino + " " + texto), null);
        assertTrue(enviados.stream().anyMatch(s -> s.startsWith("84 111 0000 ") && s.contains("pregador(a)")), enviados.toString());
        try (Connection dono = ligarComoDono()) {
            assertEquals(1, contar(dono, "SELECT count(*) FROM nucleo.notificacao WHERE ntf_mem_id = " + elisa
                    + " AND ntf_estado = 'ENVIADA'"));
        }
    }

    private static int lembretes(String agora) throws Exception {
        return ExecutorTransaccao.executar(api, null, c -> {
            try (PreparedStatement ps = c.prepareStatement("SELECT actividades.fn_lembretes_escala(?::timestamptz)")) {
                ps.setString(1, agora);
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    return rs.getInt(1);
                }
            }
        });
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

    /** NOME=valor do .env (linhas vazias e comentários ignorados). */
    static Map<String, String> lerEnv(Path ficheiro) throws java.io.IOException {
        Map<String, String> r = new java.util.HashMap<>();
        if (!Files.isRegularFile(ficheiro)) {
            return r;
        }
        for (String linha : Files.readAllLines(ficheiro, StandardCharsets.UTF_8)) {
            linha = linha.strip();
            int igual = linha.indexOf('=');
            if (linha.isEmpty() || linha.startsWith("#") || igual < 1) {
                continue;
            }
            r.put(linha.substring(0, igual).strip(), linha.substring(igual + 1).strip());
        }
        return r;
    }

    // ------------------------------------------------------------------ V22: conselho e actas

    @Test
    void conselhoPresencasEPontosDaAgendaComPerfis() throws Exception {
        int secretario = criarUsuarioComDono("secretario.v22@teste.mz", "+258840000221", "SECRETARIO");
        int membro;
        int cargo;
        try (Connection dono = ligarComoDono()) {
            membro = inserir(dono, "INSERT INTO secretaria.membro (mem_igr_id, mem_nome, mem_apelido, mem_estado) VALUES ("
                    + igrejaCentral + ", 'Paulo', 'Conselho', 'ACTIVO') RETURNING mem_id");
            cargo = inserir(dono, "SELECT car_id FROM organizacao.cargo WHERE car_nome = 'Secretário(a) da igreja'");
        }
        var oficial = Catalogo.de(Oficial.class);
        var reuniao = Catalogo.de(Reuniao.class);
        var presenca = Catalogo.de(ReuniaoPresenca.class);
        var ponto = Catalogo.de(ReuniaoPonto.class);

        // o secretário elege o oficial: o fim previsto do mandato sai da duração definida na igreja
        JsonObject ofi = ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.criar(c, oficial, Json.createObjectBuilder()
                .add("membroId", membro).add("cargoId", cargo).add("igrejaId", igrejaCentral).add("dataInicio", "2026-01-01").build()));
        assertFalse(ofi.isNull("fimPrevisto"));
        JsonArray conselho = ExecutorTransaccao.executar(api, secretario, c -> RelatoriosSecretariaController.CONSELHO.consultar(c,
                Map.of("igrejaId", String.valueOf(igrejaCentral))));
        assertTrue(conselho.stream().map(JsonValue::asJsonObject).anyMatch(o -> o.getInt("membroId") == membro && o.getBoolean("doConselho")));

        // reunião com presença e ponto da agenda votado
        JsonObject reu = ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.criar(c, reuniao, Json.createObjectBuilder()
                .add("igrejaId", igrejaCentral).add("tipo", "JUNTA_DIRECTIVA").add("data", "2026-11-08T15:00:00+02:00")
                .add("numero", "V22-01").add("secretarioMembroId", membro).build()));
        long reuId = reu.getJsonNumber("id").longValue();
        ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.criar(c, presenca, Json.createObjectBuilder()
                .add("reuniaoId", reuId).add("membroId", membro).add("presente", true).add("funcao", "Secretário(a) da igreja").build()));
        JsonObject pt = ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.criar(c, ponto, Json.createObjectBuilder()
                .add("reuniaoId", reuId).add("ordem", 1).add("assunto", "Pintura da fachada").add("votado", true)
                .add("aFavor", 8).add("contra", 1).add("deliberacao", "Aprovada").add("estado", "APROVADO").build()));
        assertEquals("APROVADO", pt.getString("estado"));

        // o tesoureiro não regista presenças (403) nem vê os pontos (404 ao alterar)
        SQLException e = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, tesoureiro, c -> TabelaRepository.criar(c, presenca,
                Json.createObjectBuilder().add("reuniaoId", reuId).add("membroId", membro).build())));
        assertEquals(403, TradutorErrosSql.traduzir(e).estadoHttp());
        long ptId = pt.getJsonNumber("id").longValue();
        ApiException naoVe = assertThrows(ApiException.class, () -> ExecutorTransaccao.executar(api, tesoureiro,
                c -> TabelaRepository.alterar(c, ponto, ptId, Json.createObjectBuilder().add("assunto", "X").build())));
        assertEquals(404, naoVe.estadoHttp());

        // acta aprovada: os pontos já não se alteram (422 com a mensagem da base de dados)
        ExecutorTransaccao.executar(api, secretario, c -> TabelaRepository.alterar(c, reuniao, reuId,
                Json.createObjectBuilder().add("estado", "ACTA_APROVADA").build()));
        SQLException fechada = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, secretario,
                c -> TabelaRepository.criar(c, ponto, Json.createObjectBuilder().add("reuniaoId", reuId).add("assunto", "Tarde").build())));
        assertEquals(422, TradutorErrosSql.traduzir(fechada).estadoHttp());
    }

    /**
     * V27 (P-02): a igreja de destino vê a transferência com o nome do membro (que a RLS ainda lhe esconde na tabela);
     * quem não lê transferências não a vê; o directório de igrejas mostra todas as igrejas a quem tem sessão.
     */
    @Test
    void transferenciaVistaPelasDuasIgrejasEDirectorio() throws Exception {
        int secBairro = criarUsuarioComDono("secretario.bairro.v27@teste.mz", null, "SECRETARIO");
        int membro;
        try (Connection dono = ligarComoDono(); Statement st = dono.createStatement()) {
            st.execute("UPDATE nucleo.usuario_igreja SET uig_igr_id = " + igrejaBairro + " WHERE uig_usu_id = " + secBairro);
            membro = inserir(dono, "INSERT INTO secretaria.membro (mem_igr_id, mem_nome, mem_apelido, mem_estado) VALUES ("
                    + igrejaCentral + ", 'Rosa', 'Mudanca', 'ACTIVO') RETURNING mem_id");
            inserir(dono, "INSERT INTO secretaria.transferencia_membro (tme_mem_id, tme_origem_igr_id, tme_destino_igr_id, tme_data_pedido) "
                    + "VALUES (" + membro + ", " + igrejaCentral + ", " + igrejaBairro + ", DATE '2026-11-01') RETURNING tme_id");
        }
        // o secretário da igreja de destino vê quem vai receber...
        JsonArray destino = ExecutorTransaccao.executar(api, secBairro, c -> RelatoriosSecretariaController.TRANSFERENCIAS_RESUMO.consultar(c,
                Map.of("igrejaId", String.valueOf(igrejaBairro))));
        assertTrue(destino.stream().map(JsonValue::asJsonObject).anyMatch(o -> o.getInt("membroId") == membro
                && "Rosa Mudanca".equals(o.getString("membro")) && "Igreja Central".equals(o.getString("origem"))), destino.toString());
        // ...mas a ficha do membro continua invisível (404)
        ApiException naoVe = assertThrows(ApiException.class, () -> ExecutorTransaccao.executar(api, secBairro,
                c -> TabelaRepository.alterar(c, Catalogo.de(Membro.class), membro, Json.createObjectBuilder().add("nome", "X").build())));
        assertEquals(404, naoVe.estadoHttp());
        // o tesoureiro da igreja de origem não lê transferências: não vê nada
        JsonArray tes = ExecutorTransaccao.executar(api, tesoureiro, c -> RelatoriosSecretariaController.TRANSFERENCIAS_RESUMO.consultar(c,
                Map.of("igrejaId", String.valueOf(igrejaCentral))));
        assertEquals(0, tes.size());
        // directório: com sessão vê também as igrejas de outra Missão; sem utilizador, nada
        JsonArray dir = ExecutorTransaccao.executar(api, tesoureiro, c -> RelatoriosOrganizacaoController.DIRECTORIO_IGREJAS.consultar(c, Map.of()));
        assertTrue(dir.stream().map(JsonValue::asJsonObject).anyMatch(o -> o.getInt("id") == igrejaOutraAssociacao), dir.toString());
        JsonArray anonimo = ExecutorTransaccao.executar(api, null, c -> RelatoriosOrganizacaoController.DIRECTORIO_IGREJAS.consultar(c, Map.of()));
        assertEquals(0, anonimo.size());
    }

    /** P-06: comprovativo com ficheiro (talão / print M-Pesa) junto ao movimento; quem vê o ficheiro decide-o a RLS. */
    @Test
    void comprovativoComFicheiroComPerfis() throws Exception {
        Tesouraria tes = prepararTesouraria();
        int secretario = criarUsuarioComDono("secretario.doc@teste.mz", null, "SECRETARIO");
        Path pasta = Files.createTempDirectory("comprovativos");
        ArmazemFicheiros armazem = new ArmazemFicheiros(pasta);
        JsonObject saida = Json.createObjectBuilder()
                .add("tipo", "SAIDA").add("metodo", "BANCO").add("valorTotal", "50.00").add("contaId", tes.conta())
                .add("descricao", "Talão do banco")
                .add("linhas", Json.createArrayBuilder().add(Json.createObjectBuilder()
                        .add("fundoId", tes.fundoLocal()).add("categoriaId", tes.categoriaLuz()).add("valor", "50.00")))
                .build();
        long tra = ExecutorTransaccao.executar(api, tesoureiro, c -> TransacoesService.criar(c, saida)).getJsonNumber("id").longValue();
        byte[] jpg = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 1, 2, 3, 4};

        // o tesoureiro junta a fotografia do talão: fica a linha e o ficheiro, com o nome limpo
        JsonObject doc = ExecutorTransaccao.executar(api, tesoureiro, c -> DocumentosService.carregar(c, armazem, tra, null,
                "COMPROVATIVO", "C:\\Fotos\\talão 0045.jpeg", jpg));
        assertEquals("talão 0045.jpg", doc.getString("nomeFicheiro"));
        assertTrue(doc.getString("url").startsWith(ArmazemFicheiros.PREFIXO));
        long docId = doc.getJsonNumber("id").longValue();
        var f = ExecutorTransaccao.executar(api, tesoureiro, c -> DocumentosService.ficheiro(c, armazem, docId));
        assertEquals("image/jpeg", f.tipo().mime);
        assertEquals(jpg.length, f.dados().length);

        // um ficheiro que não é fotografia nem PDF → 400
        ApiException tipo = assertThrows(ApiException.class, () -> ExecutorTransaccao.executar(api, tesoureiro,
                c -> DocumentosService.carregar(c, armazem, tra, null, null, "x.exe", "MZ...".getBytes(StandardCharsets.UTF_8))));
        assertEquals(400, tipo.estadoHttp());

        // o secretário não junta comprovativos (403) nem vê o ficheiro (404); e não ficou ficheiro órfão
        long ficheirosAntes;
        try (Stream<Path> s = Files.walk(pasta)) {
            ficheirosAntes = s.filter(Files::isRegularFile).count();
        }
        SQLException semPermissao = assertThrows(SQLException.class, () -> ExecutorTransaccao.executar(api, secretario,
                c -> DocumentosService.carregar(c, armazem, tra, null, null, "talao.jpg", jpg)));
        assertEquals(403, TradutorErrosSql.traduzir(semPermissao).estadoHttp());
        try (Stream<Path> s = Files.walk(pasta)) {
            assertEquals(ficheirosAntes, s.filter(Files::isRegularFile).count());
        }
        ApiException naoVe = assertThrows(ApiException.class, () -> ExecutorTransaccao.executar(api, secretario,
                c -> DocumentosService.ficheiro(c, armazem, docId)));
        assertEquals(404, naoVe.estadoHttp());

        // um documento criado à mão com um url forjado não serve ficheiros fora da pasta → 404
        JsonObject forjado = ExecutorTransaccao.executar(api, tesoureiro, c -> TabelaRepository.criar(c, DocumentosService.DOCUMENTO,
                Json.createObjectBuilder().add("transacaoId", tra).add("tipo", "OUTRO").add("nomeFicheiro", "x")
                        .add("url", ArmazemFicheiros.PREFIXO + "../../etc/passwd").build()));
        ApiException fora = assertThrows(ApiException.class, () -> ExecutorTransaccao.executar(api, tesoureiro,
                c -> DocumentosService.ficheiro(c, armazem, forjado.getJsonNumber("id").longValue())));
        assertEquals(404, fora.estadoHttp());
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
