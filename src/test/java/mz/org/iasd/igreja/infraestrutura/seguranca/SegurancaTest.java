package mz.org.iasd.igreja.infraestrutura.seguranca;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class SegurancaTest {

    private static final String SEGREDO = "um-segredo-de-teste-com-mais-de-32-caracteres";

    @Test
    void senhaArgon2id() {
        String hash = Senhas.gerarHash("segredo123");
        assertTrue(hash.startsWith("$argon2id$"));
        assertTrue(Senhas.confere("segredo123", hash));
        assertFalse(Senhas.confere("errada", hash));
        assertFalse(Senhas.confere("segredo123", "lixo"));
        assertFalse(Senhas.confere(null, hash));
    }

    @Test
    void tokenDeAcesso() {
        Tokens tokens = new Tokens(SEGREDO, "igreja-api", 15);
        Tokens.TokenEmitido t = tokens.emitir(42, 7L);
        assertEquals(42, tokens.verificar(t.token()));
        assertNull(tokens.verificar(t.token() + "x"));
        assertNull(new Tokens(SEGREDO + "-outro", "igreja-api", 15).verificar(t.token()));
        assertNull(new Tokens(SEGREDO, "outro-emissor", 15).verificar(t.token()));
    }

    @Test
    void tokenExpirado() {
        Tokens tokens = new Tokens(SEGREDO, "igreja-api", -5);   // expirou há 5 minutos (> tolerância de 30 s)
        assertNull(tokens.verificar(tokens.emitir(1, 1L).token()));
    }

    @Test
    void segredosAleatorios() {
        assertNotEquals(Segredos.tokenAleatorio(), Segredos.tokenAleatorio());
        assertTrue(Segredos.codigoSeisDigitos().matches("\\d{6}"));
        assertEquals(64, Segredos.sha256("x").length());
        assertNotEquals(Segredos.hmac("a-segredo-1234567", "123456"), Segredos.hmac("b-segredo-1234567", "123456"));
    }
}
