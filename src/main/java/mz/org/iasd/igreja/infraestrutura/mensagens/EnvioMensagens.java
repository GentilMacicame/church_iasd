package mz.org.iasd.igreja.infraestrutura.mensagens;

import java.util.logging.Logger;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import mz.org.iasd.igreja.config.Configuracao;

/**
 * Envio de SMS / WhatsApp. A integração real com os fornecedores é da Fase 4 (F-COM-01);
 * até lá, com {@code mensagens.modo=consola} a mensagem é escrita no log (só em desenvolvimento).
 */
@ApplicationScoped
public class EnvioMensagens {

    private static final Logger LOG = Logger.getLogger(EnvioMensagens.class.getName());

    @Inject
    Configuracao configuracao;

    public void enviarCodigoRecuperacao(String telefone, String codigo) {
        if (telefone == null || telefone.isBlank()) {
            LOG.warning("Recuperação de senha pedida por um utilizador sem telefone: código não enviado");
            return;
        }
        String texto = "Igreja: o seu código para redefinir a senha é " + codigo + ". Válido 15 minutos.";
        if ("consola".equals(configuracao.mensagensModo())) {
            LOG.info("[mensagens.modo=consola] SMS para " + telefone + ": " + texto);
        } else {
            LOG.warning("Envio de SMS ainda não implementado (Fase 4): código para " + mascarar(telefone) + " não enviado");
        }
    }

    static String mascarar(String telefone) {
        int n = telefone.length();
        return n <= 4 ? "****" : "*".repeat(n - 4) + telefone.substring(n - 4);
    }
}
