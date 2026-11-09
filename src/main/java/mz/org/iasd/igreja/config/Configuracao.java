package mz.org.iasd.igreja.config;

import java.nio.charset.StandardCharsets;

import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Configuração da API. Cada valor pode vir de uma variável de ambiente
 * ({@code jwt.segredo} → {@code JWT_SEGREDO}); os valores por defeito estão em
 * {@code META-INF/microprofile-config.properties} e servem só para desenvolvimento.
 */
@ApplicationScoped
public class Configuracao {

    @Inject
    @ConfigProperty(name = "jwt.segredo")
    String jwtSegredo;

    @Inject
    @ConfigProperty(name = "jwt.emissor", defaultValue = "igreja-api")
    String jwtEmissor;

    @Inject
    @ConfigProperty(name = "jwt.acesso.minutos", defaultValue = "15")
    int acessoMinutos;

    @Inject
    @ConfigProperty(name = "refresh.dias", defaultValue = "30")
    int refreshDias;

    @Inject
    @ConfigProperty(name = "cookie.seguro", defaultValue = "true")
    boolean cookieSeguro;

    @Inject
    @ConfigProperty(name = "codigo.segredo")
    String codigoSegredo;

    @Inject
    @ConfigProperty(name = "mensagens.modo", defaultValue = "desligado")
    String mensagensModo;

    @Inject
    @ConfigProperty(name = "proxy.confiavel", defaultValue = "false")
    boolean proxyConfiavel;

    @PostConstruct
    void verificar() {
        if (jwtSegredo.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("JWT_SEGREDO tem de ter pelo menos 32 caracteres");
        }
        if (codigoSegredo.getBytes(StandardCharsets.UTF_8).length < 16) {
            throw new IllegalStateException("CODIGO_SEGREDO tem de ter pelo menos 16 caracteres");
        }
    }

    public String jwtSegredo() {
        return jwtSegredo;
    }

    public String jwtEmissor() {
        return jwtEmissor;
    }

    public int acessoMinutos() {
        return acessoMinutos;
    }

    public int refreshDias() {
        return refreshDias;
    }

    public boolean cookieSeguro() {
        return cookieSeguro;
    }

    public String codigoSegredo() {
        return codigoSegredo;
    }

    public String mensagensModo() {
        return mensagensModo;
    }

    public boolean proxyConfiavel() {
        return proxyConfiavel;
    }
}
