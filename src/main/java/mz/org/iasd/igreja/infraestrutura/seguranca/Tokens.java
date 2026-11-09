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

    /** @return o id do utilizador, ou {@code null} se o token for inválido ou estiver expirado */
    public Integer verificar(String token) {
        try {
            DecodedJWT jwt = verificador.verify(token);
            return Integer.valueOf(jwt.getSubject());
        } catch (JWTVerificationException | NumberFormatException e) {
            return null;
        }
    }
}
