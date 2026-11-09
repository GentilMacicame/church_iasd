package mz.org.iasd.igreja.infraestrutura.mensagens;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.logging.Logger;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.json.Json;

import mz.org.iasd.igreja.config.Configuracao;

/**
 * Envio de SMS (F-COM-01): lembretes de escala, código de recuperação de senha e o resto da fila
 * {@code nucleo.notificacao}.
 * <ul>
 *   <li>{@code mensagens.modo=desligado} — não envia (a fila espera);</li>
 *   <li>{@code consola} — escreve a mensagem no log (só no perfil dev);</li>
 *   <li>{@code http} — envia ao fornecedor de SMS: {@code POST SMS_URL} com
 *       {@code {"para": "+2588…", "mensagem": "…", "remetente": SMS_REMETENTE}} e {@code Authorization: Bearer SMS_TOKEN}.
 *       Resposta 2xx = enviado. Adaptar {@link #pedidoHttp} ao formato do fornecedor escolhido.</li>
 * </ul>
 */
@ApplicationScoped
public class EnvioMensagens {

    private static final Logger LOG = Logger.getLogger(EnvioMensagens.class.getName());
    private static final HttpClient HTTP = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();

    @Inject
    Configuracao configuracao;

    /** Há envio configurado (consola ou fornecedor)? Sem ele a fila não é processada. */
    public boolean activo() {
        return "consola".equals(configuracao.mensagensModo()) || "http".equals(configuracao.mensagensModo());
    }

    /**
     * Envia um SMS. Lança {@link FalhaEnvio} se o fornecedor recusar ou não responder (a fila tenta de novo).
     */
    public void enviarSms(String destino, String texto) {
        String numero = normalizarTelefone(destino);
        if (numero == null) {
            throw new FalhaEnvio("Número de telefone inválido: " + mascarar(destino == null ? "" : destino));
        }
        switch (configuracao.mensagensModo()) {
            case "consola" -> LOG.info("[mensagens.modo=consola] SMS para " + numero + ": " + texto);
            case "http" -> pedidoHttp(numero, texto);
            default -> throw new FalhaEnvio("Envio de SMS desligado (MENSAGENS_MODO=desligado)");
        }
    }

    public void enviarCodigoRecuperacao(String telefone, String codigo) {
        if (telefone == null || telefone.isBlank()) {
            LOG.warning("Recuperação de senha pedida por um utilizador sem telefone: código não enviado");
            return;
        }
        try {
            enviarSms(telefone, "Igreja: o seu código para redefinir a senha é " + codigo + ". Válido 15 minutos.");
        } catch (FalhaEnvio e) {
            LOG.warning("Código de recuperação para " + mascarar(telefone) + " não enviado: " + e.getMessage());
        }
    }

    private void pedidoHttp(String numero, String texto) {
        String corpo = Json.createObjectBuilder().add("para", numero).add("mensagem", texto)
                .add("remetente", configuracao.smsRemetente()).build().toString();
        HttpRequest pedido = HttpRequest.newBuilder(URI.create(configuracao.smsUrl()))
                .timeout(Duration.ofSeconds(15))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + configuracao.smsToken())
                .POST(HttpRequest.BodyPublishers.ofString(corpo))
                .build();
        try {
            HttpResponse<String> r = HTTP.send(pedido, HttpResponse.BodyHandlers.ofString());
            if (r.statusCode() / 100 != 2) {
                throw new FalhaEnvio("Fornecedor de SMS respondeu " + r.statusCode() + ": "
                        + r.body().substring(0, Math.min(r.body().length(), 200)));
            }
        } catch (java.io.IOException e) {
            throw new FalhaEnvio("Fornecedor de SMS indisponível: " + e.getMessage());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FalhaEnvio("Envio interrompido");
        }
    }

    /**
     * Número em formato internacional de Moçambique: "84 111 0000", "841110000", "+258 84 111 0000" →
     * "+258841110000". Devolve null se não for um telemóvel moçambicano válido (82–87, 9 dígitos).
     */
    public static String normalizarTelefone(String telefone) {
        if (telefone == null) {
            return null;
        }
        String digitos = telefone.replaceAll("[^0-9]", "");
        if (digitos.startsWith("00258")) {
            digitos = digitos.substring(2);
        }
        if (digitos.length() == 9) {
            digitos = "258" + digitos;
        }
        return digitos.matches("2588[2-7]\\d{7}") ? "+" + digitos : null;
    }

    static String mascarar(String telefone) {
        int n = telefone.length();
        return n <= 4 ? "****" : "*".repeat(n - 4) + telefone.substring(n - 4);
    }

    /** O SMS não saiu (fornecedor recusou, indisponível ou número inválido). */
    public static class FalhaEnvio extends RuntimeException {
        public FalhaEnvio(String mensagem) {
            super(mensagem);
        }
    }
}
