package mz.org.iasd.igreja.infraestrutura.saude;

import java.sql.Connection;

import javax.sql.DataSource;

import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Readiness;

import jakarta.annotation.Resource;
import jakarta.enterprise.context.ApplicationScoped;

/**
 * {@code GET /health/ready}: a API só recebe tráfego se conseguir falar com a base de dados (2 s).
 * O balanceador (Nginx) e a monitorização usam este endereço; {@code /health/live} diz se o processo responde.
 */
@Readiness
@ApplicationScoped
public class SaudeBaseDados implements HealthCheck {

    @Resource(lookup = "jdbc/igreja")
    DataSource fonte;

    @Override
    public HealthCheckResponse call() {
        try (Connection c = fonte.getConnection()) {
            return c.isValid(2)
                    ? HealthCheckResponse.up("base-de-dados")
                    : HealthCheckResponse.named("base-de-dados").down().withData("erro", "ligação inválida").build();
        } catch (Exception e) {
            return HealthCheckResponse.named("base-de-dados").down().withData("erro", e.getClass().getSimpleName()).build();
        }
    }
}
