package mz.org.iasd.igreja.config;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.event.Startup;
import jakarta.inject.Inject;

import org.eclipse.microprofile.config.inject.ConfigProperty;

import mz.org.iasd.igreja.infraestrutura.bd.ExecutorTransaccao;

/**
 * Configuração da API. Cada valor pode vir de uma variável de ambiente ({@code jwt.segredo} → {@code JWT_SEGREDO}).
 * <p>
 * Ambientes: o perfil {@code dev} ({@code MP_CONFIG_PROFILE=dev}) activa os valores {@code %dev.*} de
 * {@code META-INF/microprofile-config.properties} (segredos de desenvolvimento, mensagens na consola). Sem perfil
 * (produção) <b>não há segredos por defeito</b>: se faltarem, ou se forem os de desenvolvimento, a API não arranca.
 * A verificação corre no arranque.
 */
@ApplicationScoped
public class Configuracao {

    private static final Logger LOG = Logger.getLogger(Configuracao.class.getName());

    /** Valores públicos (estão no repositório): só aceites no perfil dev. */
    static final List<String> SEGREDOS_DE_DESENVOLVIMENTO = List.of(
            "desenvolvimento-mudar-este-segredo-com-pelo-menos-32-caracteres",
            "desenvolvimento-mudar-segredo-dos-codigos",
            "mudar-para-um-segredo-aleatorio-com-pelo-menos-32-caracteres",
            "mudar-para-outro-segredo-aleatorio",
            "mudar");

    @Inject
    @ConfigProperty(name = "mp.config.profile", defaultValue = "prod")
    String perfil;

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

    /** Cálculos de senha (Argon2id, 19 MiB cada) em simultâneo; os restantes esperam até 5 s. 0 = nº de CPUs. */
    @Inject
    @ConfigProperty(name = "senhas.concorrencia", defaultValue = "0")
    int senhasConcorrencia;

    /** Tempo máximo de cada instrução SQL (statement_timeout) e de espera por um bloqueio (lock_timeout). */
    @Inject
    @ConfigProperty(name = "bd.timeout.consulta.segundos", defaultValue = "30")
    int timeoutConsulta;

    @Inject
    @ConfigProperty(name = "bd.timeout.bloqueio.segundos", defaultValue = "5")
    int timeoutBloqueio;

    /** Fornecedor de SMS (mensagens.modo=http). */
    @Inject
    @ConfigProperty(name = "sms.url")
    java.util.Optional<String> smsUrl;

    @Inject
    @ConfigProperty(name = "sms.token")
    java.util.Optional<String> smsToken;

    @Inject
    @ConfigProperty(name = "sms.remetente", defaultValue = "IASD")
    String smsRemetente;

    /** Tamanho máximo do corpo de um pedido. */
    @Inject
    @ConfigProperty(name = "pedido.max.kb", defaultValue = "2048")
    int pedidoMaxKb;

    /** Pasta onde se guardam os comprovativos carregados (FICHEIROS_PASTA). Sem ela, carregar ficheiros dá 503. */
    @Inject
    @ConfigProperty(name = "ficheiros.pasta")
    java.util.Optional<String> ficheirosPasta;

    /** Tamanho máximo de um comprovativo (KB). */
    @Inject
    @ConfigProperty(name = "ficheiros.max.kb", defaultValue = "5120")
    int ficheirosMaxKb;

    /** Força a verificação (e a falha) no arranque, não no primeiro pedido. */
    void arrancar(@Observes Startup arranque) {
        LOG.info(() -> "Ambiente: " + (desenvolvimento() ? "desenvolvimento (perfil dev)" : "produção"));
    }

    @PostConstruct
    void verificar() {
        List<String> erros = new ArrayList<>();
        if (jwtSegredo.getBytes(StandardCharsets.UTF_8).length < 32) {
            erros.add("JWT_SEGREDO tem de ter pelo menos 32 caracteres");
        }
        if (codigoSegredo.getBytes(StandardCharsets.UTF_8).length < 16) {
            erros.add("CODIGO_SEGREDO tem de ter pelo menos 16 caracteres");
        }
        if (!desenvolvimento()) {
            if (SEGREDOS_DE_DESENVOLVIMENTO.contains(jwtSegredo)) {
                erros.add("JWT_SEGREDO é o valor de desenvolvimento (público): defina um segredo aleatório");
            }
            if (SEGREDOS_DE_DESENVOLVIMENTO.contains(codigoSegredo)) {
                erros.add("CODIGO_SEGREDO é o valor de desenvolvimento (público): defina um segredo aleatório");
            }
            if ("consola".equals(mensagensModo)) {
                erros.add("MENSAGENS_MODO=consola escreve os códigos de recuperação no log: só no perfil dev");
            }
            if (!cookieSeguro) {
                erros.add("COOKIE_SEGURO=false só no perfil dev (o cookie de renovação tem de exigir HTTPS)");
            }
        }
        if (!java.util.Set.of("desligado", "consola", "http").contains(mensagensModo)) {
            erros.add("MENSAGENS_MODO tem de ser desligado, consola ou http");
        }
        if ("http".equals(mensagensModo) && (smsUrl.isEmpty() || smsToken.isEmpty())) {
            erros.add("MENSAGENS_MODO=http precisa de SMS_URL e SMS_TOKEN (fornecedor de SMS)");
        }
        if (timeoutConsulta < 1 || timeoutBloqueio < 1 || pedidoMaxKb < 1) {
            erros.add("BD_TIMEOUT_* e PEDIDO_MAX_KB têm de ser positivos");
        }
        if (!erros.isEmpty()) {
            throw new IllegalStateException("Configuração inválida: " + String.join("; ", erros));
        }
        ExecutorTransaccao.definirTimeouts(timeoutConsulta * 1000, timeoutBloqueio * 1000);
    }

    public boolean desenvolvimento() {
        return "dev".equals(perfil);
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

    public String smsUrl() {
        return smsUrl.orElse("");
    }

    public String smsToken() {
        return smsToken.orElse("");
    }

    public String smsRemetente() {
        return smsRemetente;
    }

    public boolean proxyConfiavel() {
        return proxyConfiavel;
    }

    public int senhasConcorrencia() {
        return senhasConcorrencia > 0 ? senhasConcorrencia : Math.max(2, Runtime.getRuntime().availableProcessors());
    }

    public long pedidoMaxBytes() {
        return pedidoMaxKb * 1024L;
    }

    public java.util.Optional<java.nio.file.Path> ficheirosPasta() {
        return ficheirosPasta.filter(x -> !x.isBlank()).map(java.nio.file.Path::of);
    }

    public long ficheirosMaxBytes() {
        return ficheirosMaxKb * 1024L;
    }
}
