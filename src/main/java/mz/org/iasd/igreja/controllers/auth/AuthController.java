package mz.org.iasd.igreja.controllers.auth;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.Optional;
import java.util.OptionalLong;

import javax.sql.DataSource;

import jakarta.annotation.Resource;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.CookieParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.NewCookie;
import jakarta.ws.rs.core.Response;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.config.Configuracao;
import mz.org.iasd.igreja.infraestrutura.bd.ContextoPedido;
import mz.org.iasd.igreja.infraestrutura.bd.ExecutorTransaccao;
import mz.org.iasd.igreja.infraestrutura.bd.Transaccional;
import mz.org.iasd.igreja.infraestrutura.bd.UnidadeDeTrabalho;
import mz.org.iasd.igreja.infraestrutura.erros.Respostas;
import mz.org.iasd.igreja.infraestrutura.mensagens.EnvioMensagens;
import mz.org.iasd.igreja.infraestrutura.seguranca.ControloSenhas;
import mz.org.iasd.igreja.infraestrutura.seguranca.LimitadorPedidos;
import mz.org.iasd.igreja.infraestrutura.seguranca.OrigemPedido;
import mz.org.iasd.igreja.infraestrutura.seguranca.Publico;
import mz.org.iasd.igreja.infraestrutura.seguranca.Segredos;
import mz.org.iasd.igreja.infraestrutura.seguranca.Senhas;
import mz.org.iasd.igreja.infraestrutura.seguranca.Tokens;
import mz.org.iasd.igreja.models.auth.Pedidos;
import mz.org.iasd.igreja.repositories.auth.AuthRepository;

/**
 * F-NUC-01 Autenticação e F-NUC-02 Recuperação de senha.
 *
 * Token de acesso JWT (15 min) no corpo da resposta; token de renovação (30 dias) num cookie
 * {@code HttpOnly; Secure; SameSite=Strict}, trocado em cada renovação. Na base de dados só fica o hash.
 *
 * As recusas que têm de ficar gravadas (falha de login, código errado, token reutilizado) são devolvidas
 * como resposta — não como excepção — para a transacção fazer COMMIT.
 *
 * Protecções (auditoria H2/H4): limite de pedidos por IP e por login (429 + Retry-After); o cálculo da senha
 * (Argon2id) corre fora de qualquer transacção, sem prender uma ligação do pool, e com um número máximo
 * de cálculos em simultâneo ({@link ControloSenhas}).
 */
@Path(Rotas.Auth.AUTH)
@RequestScoped
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AuthController {

    static final String COOKIE = "renovacao";
    private static final String CAMINHO_COOKIE = "/v1/auth";
    private static final DateTimeFormatter HORA = DateTimeFormatter.ofPattern("HH:mm").withZone(ZoneId.of("Africa/Maputo"));

    @Resource(lookup = "jdbc/igreja")
    DataSource fonte;

    @Inject
    UnidadeDeTrabalho unidade;

    @Inject
    ContextoPedido contexto;

    @Inject
    Configuracao configuracao;

    @Inject
    Tokens tokens;

    @Inject
    EnvioMensagens mensagens;

    @Inject
    LimitadorPedidos limitador;

    @Inject
    ControloSenhas controloSenhas;

    @Context
    HttpServletRequest pedido;

    /** Leitura antes de verificar a senha (transacção curta). */
    private record Leitura(OffsetDateTime bloqueadoAte, Optional<AuthRepository.Credenciais> credenciais) {
    }

    @POST
    @Path(Rotas.Auth.LOGIN)
    @Publico
    public Response login(@NotNull(message = "Corpo do pedido em falta") @Valid Pedidos.Login corpo) throws Exception {
        String login = corpo.login().trim();
        Optional<Response> limite = limitar("login", login, 10, 30, Duration.ofMinutes(5));
        if (limite.isPresent()) {
            return limite.get();
        }

        Leitura l = ExecutorTransaccao.executar(fonte, null,
                c -> new Leitura(AuthRepository.bloqueadoAte(c, login), AuthRepository.credenciais(c, login)));
        if (l.bloqueadoAte() != null) {
            return erro401("Demasiadas tentativas falhadas. Tente de novo depois das " + HORA.format(l.bloqueadoAte()) + ".");
        }

        boolean certo = controloSenhas.executar(() -> {
            if (l.credenciais().isEmpty()) {
                Senhas.gastarTempo(corpo.senha());       // a mesma demora, exista ou não o login
                return false;
            }
            AuthRepository.Credenciais cred = l.credenciais().get();
            return Senhas.confere(corpo.senha(), cred.senhaHash()) && "ACTIVO".equals(cred.estado());
        });

        if (!certo) {
            ExecutorTransaccao.executar(fonte, null, c -> {
                AuthRepository.loginFalhou(c, login);
                return null;
            });
            return erro401("Login ou senha errados");
        }

        int usuario = l.credenciais().get().usuarioId();
        String refresh = Segredos.tokenAleatorio();
        long sessao = ExecutorTransaccao.executar(fonte, null, c -> AuthRepository.abrirSessao(c, usuario,
                Segredos.sha256(refresh), ip(), OrigemPedido.navegador(pedido)));
        Tokens.TokenEmitido token = tokens.emitir(usuario, sessao);
        return Response.ok(new Pedidos.Token(token.token(), token.expiraEm())).cookie(cookie(refresh)).build();
    }

    @POST
    @Path(Rotas.Auth.RENOVAR)
    @Publico
    @Transaccional
    @Consumes(MediaType.WILDCARD)
    public Response renovar(@CookieParam(COOKIE) String refresh) throws Exception {
        Optional<Response> limite = limitar("renovar", null, 0, 120, Duration.ofMinutes(5));
        if (limite.isPresent()) {
            return limite.get();
        }
        if (refresh == null || refresh.isBlank()) {
            return erro401("Sessão terminada. Entre de novo.");
        }
        String novo = Segredos.tokenAleatorio();
        AuthRepository.Renovacao r = AuthRepository.renovarSessao(unidade.ligacao(), Segredos.sha256(refresh),
                Segredos.sha256(novo), ip(), OrigemPedido.navegador(pedido));
        if ("CONCORRENTE".equals(r.resultado())) {
            // outro pedido deste navegador acabou de renovar (e recebeu o cookie novo): não apagar o cookie
            return Respostas.erro(409, "tentar_novamente", "A sessão acabou de ser renovada. Tente de novo.", null,
                    contexto.pedidoId());
        }
        if (!"OK".equals(r.resultado())) {
            String mensagem = "REUTILIZADA".equals(r.resultado())
                    ? "Por segurança, todas as suas sessões foram terminadas. Entre de novo."
                    : "Sessão terminada. Entre de novo.";
            return Response.fromResponse(erro401(mensagem)).cookie(cookieApagado()).build();
        }
        Tokens.TokenEmitido token = tokens.emitir(r.usuarioId(), r.sessaoId());
        return Response.ok(new Pedidos.Token(token.token(), token.expiraEm())).cookie(cookie(novo)).build();
    }

    @POST
    @Path(Rotas.Auth.SAIR)
    @Transaccional
    @Consumes(MediaType.WILDCARD)
    public Response sair(@CookieParam(COOKIE) String refresh) throws Exception {
        if (refresh != null && !refresh.isBlank()) {
            AuthRepository.terminarSessao(unidade.ligacao(), Segredos.sha256(refresh));
        }
        return Response.ok(Map.of()).cookie(cookieApagado()).build();
    }

    /** Resposta igual exista ou não o login (não revela quem tem conta). */
    @POST
    @Path(Rotas.Auth.RECUPERAR)
    @Publico
    public Response recuperar(@NotNull(message = "Corpo do pedido em falta") @Valid Pedidos.Recuperar corpo)
            throws Exception {
        String login = corpo.login().trim();
        Optional<Response> limite = limitar("recuperar", login, 3, 10, Duration.ofHours(1));
        if (limite.isPresent()) {
            return limite.get();
        }
        String codigo = Segredos.codigoSeisDigitos();
        Optional<AuthRepository.Recuperacao> pedido = ExecutorTransaccao.executar(fonte, null,
                c -> AuthRepository.pedirRecuperacao(c, login, Segredos.hmac(configuracao.codigoSegredo(), codigo)));
        // o SMS sai depois do COMMIT, sem prender uma ligação à base durante a chamada ao fornecedor
        pedido.ifPresent(r -> mensagens.enviarCodigoRecuperacao(r.telefone(), codigo));
        return Response.ok(Map.of()).build();
    }

    @POST
    @Path(Rotas.Auth.REDEFINIR)
    @Publico
    public Response redefinir(@NotNull(message = "Corpo do pedido em falta") @Valid Pedidos.Redefinir corpo)
            throws Exception {
        String login = corpo.login().trim();
        Optional<Response> limite = limitar("redefinir", login, 10, 20, Duration.ofMinutes(15));
        if (limite.isPresent()) {
            return limite.get();
        }
        String novaSenha = controloSenhas.executar(() -> Senhas.gerarHash(corpo.senha()));     // fora da transacção
        String resultado = ExecutorTransaccao.executar(fonte, null, c -> AuthRepository.redefinirSenha(c, login,
                Segredos.hmac(configuracao.codigoSegredo(), corpo.codigo()), novaSenha));
        return switch (resultado) {
            case "OK" -> Response.ok(Map.of()).cookie(cookieApagado()).build();
            case "CODIGO_ERRADO" -> Respostas.erro(422, "regra_negocio", "Código errado", "codigo", contexto.pedidoId());
            default -> Respostas.erro(422, "regra_negocio",
                    "O código expirou ou já foi usado. Peça um código novo.", "codigo", contexto.pedidoId());
        };
    }

    /**
     * Limite por IP e, se houver, por login. Os contadores são por instância da API; o Nginx limita
     * também por IP à entrada.
     */
    private Optional<Response> limitar(String accao, String login, int porLogin, int porIp, Duration janela) {
        OptionalLong espera = limitador.consumir(accao + ":ip:" + ip(), porIp, janela);
        if (espera.isEmpty() && login != null && porLogin > 0) {
            espera = limitador.consumir(accao + ":login:" + login.toLowerCase(), porLogin, janela);
        }
        if (espera.isEmpty()) {
            return Optional.empty();
        }
        return Optional.of(Response.fromResponse(Respostas.erro(429, "demasiados_pedidos",
                        "Demasiados pedidos. Tente de novo dentro de " + espera.getAsLong() + " segundos.", null,
                        contexto.pedidoId()))
                .header("Retry-After", espera.getAsLong()).build());
    }

    private String ip() {
        String ip = OrigemPedido.ip(pedido, configuracao.proxyConfiavel());
        return ip == null ? "desconhecido" : ip;
    }

    private Response erro401(String mensagem) {
        return Respostas.erro(401, "nao_autenticado", mensagem, null, contexto.pedidoId());
    }

    private NewCookie cookie(String valor) {
        return new NewCookie.Builder(COOKIE)
                .value(valor)
                .path(CAMINHO_COOKIE)
                .httpOnly(true)
                .secure(configuracao.cookieSeguro())
                .sameSite(NewCookie.SameSite.STRICT)
                .maxAge(configuracao.refreshDias() * 24 * 60 * 60)
                .build();
    }

    private NewCookie cookieApagado() {
        return new NewCookie.Builder(COOKIE)
                .value("")
                .path(CAMINHO_COOKIE)
                .httpOnly(true)
                .secure(configuracao.cookieSeguro())
                .sameSite(NewCookie.SameSite.STRICT)
                .maxAge(0)
                .build();
    }
}
