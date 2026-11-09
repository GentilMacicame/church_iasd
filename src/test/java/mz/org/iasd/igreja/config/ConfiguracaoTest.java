package mz.org.iasd.igreja.config;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

/** Auditoria C1/H1: fora do perfil dev, a API não arranca com segredos públicos nem mensagens na consola. */
class ConfiguracaoTest {

    private static Configuracao config(String perfil, String jwt, String codigo, String mensagens, boolean cookieSeguro) {
        Configuracao c = new Configuracao();
        c.perfil = perfil;
        c.jwtSegredo = jwt;
        c.codigoSegredo = codigo;
        c.mensagensModo = mensagens;
        c.cookieSeguro = cookieSeguro;
        c.timeoutConsulta = 30;
        c.timeoutBloqueio = 5;
        c.pedidoMaxKb = 2048;
        c.smsUrl = java.util.Optional.empty();
        c.smsToken = java.util.Optional.empty();
        c.smsRemetente = "IASD";
        return c;
    }

    private static final String JWT_DEV = "desenvolvimento-mudar-este-segredo-com-pelo-menos-32-caracteres";
    private static final String COD_DEV = "desenvolvimento-mudar-segredo-dos-codigos";
    private static final String JWT_BOM = "Zt8q2v6RkXw1mP9sYb4nLc7hJd3fGa5eUo0iTyQr";
    private static final String COD_BOM = "c9Vh2kLm4Np6Qr8sTu";

    @Test
    void producaoRecusaSegredosDeDesenvolvimento() {
        IllegalStateException e = assertThrows(IllegalStateException.class,
                () -> config("prod", JWT_DEV, COD_BOM, "desligado", true).verificar());
        assertTrue(e.getMessage().contains("JWT_SEGREDO"));
        assertThrows(IllegalStateException.class, () -> config("prod", JWT_BOM, COD_DEV, "desligado", true).verificar());
    }

    @Test
    void producaoRecusaMensagensNaConsolaECookieSemHttps() {
        assertThrows(IllegalStateException.class, () -> config("prod", JWT_BOM, COD_BOM, "consola", true).verificar());
        assertThrows(IllegalStateException.class, () -> config("prod", JWT_BOM, COD_BOM, "desligado", false).verificar());
    }

    @Test
    void segredoCurtoRecusadoEmQualquerAmbiente() {
        assertThrows(IllegalStateException.class, () -> config("dev", "curto", COD_BOM, "consola", true).verificar());
    }

    @Test
    void devAceitaOsValoresDeDesenvolvimento() {
        assertDoesNotThrow(() -> config("dev", JWT_DEV, COD_DEV, "consola", false).verificar());
        assertDoesNotThrow(() -> config("prod", JWT_BOM, COD_BOM, "desligado", true).verificar());
    }

    @Test
    void smsPorHttpPrecisaDoFornecedor() {
        assertThrows(IllegalStateException.class, () -> config("prod", JWT_BOM, COD_BOM, "http", true).verificar());
        Configuracao c = config("prod", JWT_BOM, COD_BOM, "http", true);
        c.smsUrl = java.util.Optional.of("https://sms.exemplo/enviar");
        c.smsToken = java.util.Optional.of("token");
        assertDoesNotThrow(c::verificar);
        assertThrows(IllegalStateException.class, () -> config("prod", JWT_BOM, COD_BOM, "pombo-correio", true).verificar());
    }
}
