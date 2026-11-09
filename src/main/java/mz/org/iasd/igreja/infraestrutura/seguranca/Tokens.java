package mz.org.iasd.igreja.infraestrutura.seguranca;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTVerifier;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;

/** Token de acesso JWT (HS256), válido 15 minutos por defeito. */
public final class Tokens {

    public record TokenEmitido(String token, OffsetDateTime expiraEm) {
    }

    /** Quem é e de que sessão de login veio o token (a API confirma na base que a sessão continua activa). */
    public record Identidade(int usuarioId, Long sessaoId) {
    }

    private final Algorithm algoritmo;
    private final JWTVerifier verificador;
    private final String emissor;
    private final int minutos;

    public Tokens(String segredo, String emissor, int minutos) {
        this.algoritmo = Algorithm.HMAC256(segredo);
        this.emissor = emissor;
        this.minutos = minutos;
        this.verificador = JWT.require(algoritmo).withIssuer(emissor).acceptLeeway(30).build();
    }

    public TokenEmitido emitir(int usuarioId, long sessaoId) {
        Instant agora = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        Instant expira = agora.plus(minutos, ChronoUnit.MINUTES);
        String token = JWT.create()
                .withIssuer(emissor)
                .withSubject(Integer.toString(usuarioId))
                .withClaim("sid", sessaoId)
                .withJWTId(UUID.randomUUID().toString())
                .withIssuedAt(agora)
                .withExpiresAt(expira)
                .sign(algoritmo);
        return new TokenEmitido(token, OffsetDateTime.ofInstant(expira, ZoneOffset.UTC));
    }

    /** @return quem é e a sessão, ou {@code null} se o token for inválido ou estiver expirado */
    public Identidade verificar(String token) {
        try {
            DecodedJWT jwt = verificador.verify(token);
            Long sessao = jwt.getClaim("sid").isMissing() || jwt.getClaim("sid").isNull() ? null : jwt.getClaim("sid").asLong();
            if (sessao == null) {
                return null;                       // todos os tokens emitidos têm sid
            }
            return new Identidade(Integer.parseInt(jwt.getSubject()), sessao);
        } catch (JWTVerificationException | NumberFormatException e) {
            return null;
        }
    }
}
