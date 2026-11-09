package mz.org.iasd.igreja.controllers.auth;

import java.sql.Connection;
import java.sql.SQLException;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.Optional;

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

import mz.org.iasd.igreja.infraestrutura.bd.ContextoPedido;
import mz.org.iasd.igreja.infraestrutura.bd.Transaccional;
import mz.org.iasd.igreja.infraestrutura.bd.UnidadeDeTrabalho;
import mz.org.iasd.igreja.config.Configuracao;
import mz.org.iasd.igreja.infraestrutura.erros.Respostas;
import mz.org.iasd.igreja.infraestrutura.mensagens.EnvioMensagens;
import mz.org.iasd.igreja.infraestrutura.seguranca.OrigemPedido;
import mz.org.iasd.igreja.infraestrutura.seguranca.Publico;
import mz.org.iasd.igreja.infraestrutura.seguranca.Segredos;
import mz.org.iasd.igreja.infraestrutura.seguranca.Senhas;
import mz.org.iasd.igreja.infraestrutura.seguranca.Tokens;
import mz.org.iasd.igreja.Rotas;
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
 */
@Path(Rotas.Auth.AUTH)
@RequestScoped
@Transaccional
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AuthController {

    static final String COOKIE = "renovacao";
    private static final String CAMINHO_COOKIE = "/v1/auth";
    private static final DateTimeFormatter HORA = DateTimeFormatter.ofPattern("HH:mm").withZone(ZoneId.of("Africa/Maputo"));

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

    @Context
    HttpServletRequest pedido;

    @POST
    @Path(Rotas.Auth.LOGIN)
    @Publico
    public Response login(@NotNull(message = "Corpo do pedido em falta") @Valid Pedidos.Login corpo) throws SQLException {
        Connection c = unidade.ligacao();
        String login = corpo.login().trim();

        OffsetDateTime bloqueado = AuthRepository.bloqueadoAte(c, login);
        if (bloqueado != null) {
            return erro401("Demasiadas tentativas falhadas. Tente de novo depois das " + HORA.format(bloqueado) + ".");
        }

        Optional<AuthRepository.Credenciais> cred = AuthRepository.credenciais(c, login);
        boolean certo;
        if (cred.isPresent()) {
            certo = Senhas.confere(corpo.senha(), cred.get().senhaHash()) && "ACTIVO".equals(cred.get().estado());
        } else {
            Senhas.gastarTempo(corpo.senha());
            certo = false;
        }
        if (!certo) {
            AuthRepository.loginFalhou(c, login);
            return erro401("Login ou senha errados");
        }

        String refresh = Segredos.tokenAleatorio();
        long sessao = AuthRepository.abrirSessao(c, cred.get().usuarioId(), Segredos.sha256(refresh),
                ip(), OrigemPedido.navegador(pedido));
        Tokens.TokenEmitido token = tokens.emitir(cred.get().usuarioId(), sessao);
        return Response.ok(new Pedidos.Token(token.token(), token.expiraEm())).cookie(cookie(refresh)).build();
    }

    @POST
    @Path(Rotas.Auth.RENOVAR)
    @Publico
    @Consumes(MediaType.WILDCARD)
    public Response renovar(@CookieParam(COOKIE) String refresh) throws SQLException {
        if (refresh == null || refresh.isBlank()) {
            return erro401("Sessão terminada. Entre de novo.");
        }
        String novo = Segredos.tokenAleatorio();
        AuthRepository.Renovacao r = AuthRepository.renovarSessao(unidade.ligacao(), Segredos.sha256(refresh),
                Segredos.sha256(novo), ip(), OrigemPedido.navegador(pedido));
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
    @Consumes(MediaType.WILDCARD)
    public Response sair(@CookieParam(COOKIE) String refresh) throws SQLException {
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
            throws SQLException {
        String codigo = Segredos.codigoSeisDigitos();
        AuthRepository.pedirRecuperacao(unidade.ligacao(), corpo.login().trim(),
                        Segredos.hmac(configuracao.codigoSegredo(), codigo))
                .ifPresent(r -> mensagens.enviarCodigoRecuperacao(r.telefone(), codigo));
        return Response.ok(Map.of()).build();
    }

    @POST
    @Path(Rotas.Auth.REDEFINIR)
    @Publico
    public Response redefinir(@NotNull(message = "Corpo do pedido em falta") @Valid Pedidos.Redefinir corpo)
            throws SQLException {
        String resultado = AuthRepository.redefinirSenha(unidade.ligacao(), corpo.login().trim(),
                Segredos.hmac(configuracao.codigoSegredo(), corpo.codigo()), Senhas.gerarHash(corpo.senha()));
        return switch (resultado) {
            case "OK" -> Response.ok(Map.of()).cookie(cookieApagado()).build();
            case "CODIGO_ERRADO" -> Respostas.erro(422, "regra_negocio", "Código errado", "codigo", contexto.pedidoId());
            default -> Respostas.erro(422, "regra_negocio",
                    "O código expirou ou já foi usado. Peça um código novo.", "codigo", contexto.pedidoId());
        };
    }

    private String ip() {
        return OrigemPedido.ip(pedido, configuracao.proxyConfiavel());
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
