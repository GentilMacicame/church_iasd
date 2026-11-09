package mz.org.iasd.igreja.infraestrutura.mensagens;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import org.junit.jupiter.api.Test;

/** Números dos contactos (escritos de muitas formas) → formato internacional para o fornecedor de SMS. */
class EnvioMensagensTest {

    @Test
    void telefonesMocambicanos() {
        assertEquals("+258841110000", EnvioMensagens.normalizarTelefone("84 111 0000"));
        assertEquals("+258841110000", EnvioMensagens.normalizarTelefone("841110000"));
        assertEquals("+258871110000", EnvioMensagens.normalizarTelefone("+258 87 111 0000"));
        assertEquals("+258821110000", EnvioMensagens.normalizarTelefone("00258821110000"));
    }

    @Test
    void invalidos() {
        assertNull(EnvioMensagens.normalizarTelefone("21 123 456"));        // fixo
        assertNull(EnvioMensagens.normalizarTelefone("+27 82 111 0000"));   // África do Sul
        assertNull(EnvioMensagens.normalizarTelefone("abc"));
        assertNull(EnvioMensagens.normalizarTelefone(null));
    }
}
