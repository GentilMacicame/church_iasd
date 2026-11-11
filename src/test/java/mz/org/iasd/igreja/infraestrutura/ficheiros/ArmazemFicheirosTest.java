package mz.org.iasd.igreja.infraestrutura.ficheiros;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Comprovativos: o tipo pelos primeiros bytes, chaves geradas por nós e nada fora da pasta. */
class ArmazemFicheirosTest {

    @TempDir
    Path pasta;

    @Test
    void reconheceOTipoPelosPrimeirosBytes() {
        assertEquals(Optional.of(ArmazemFicheiros.Tipo.JPG), ArmazemFicheiros.tipo(new byte[] {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, 0}));
        assertEquals(Optional.of(ArmazemFicheiros.Tipo.PNG), ArmazemFicheiros.tipo(new byte[] {(byte) 0x89, 'P', 'N', 'G', 13, 10, 26, 10}));
        assertEquals(Optional.of(ArmazemFicheiros.Tipo.WEBP), ArmazemFicheiros.tipo("RIFF\0\0\0\0WEBPVP8 ".getBytes(StandardCharsets.ISO_8859_1)));
        assertEquals(Optional.of(ArmazemFicheiros.Tipo.PDF), ArmazemFicheiros.tipo("%PDF-1.7".getBytes(StandardCharsets.US_ASCII)));
        // um HTML ou executável com o nome .jpg não passa
        assertEquals(Optional.empty(), ArmazemFicheiros.tipo("<html><script>".getBytes(StandardCharsets.US_ASCII)));
        assertEquals(Optional.empty(), ArmazemFicheiros.tipo("MZ".getBytes(StandardCharsets.US_ASCII)));
        assertEquals(Optional.empty(), ArmazemFicheiros.tipo(new byte[0]));
    }

    @Test
    void guardaELeComChavesGeradas() throws Exception {
        var a = new ArmazemFicheiros(pasta);
        String chave = ArmazemFicheiros.novaChave(ArmazemFicheiros.Tipo.PDF);
        assertTrue(chave.matches("\\d{4}/\\d{2}/[0-9a-f-]{36}\\.pdf"), chave);
        byte[] dados = "%PDF-1.4 ...".getBytes(StandardCharsets.US_ASCII);
        a.guardar(chave, dados);
        assertArrayEquals(dados, a.ler(chave).orElseThrow());
        assertEquals(ArmazemFicheiros.Tipo.PDF, ArmazemFicheiros.Tipo.daChave(chave));
        // não ficam temporários
        try (var s = Files.walk(pasta)) {
            assertEquals(1, s.filter(Files::isRegularFile).count());
        }
        assertEquals(Optional.of(chave), ArmazemFicheiros.chaveDoUrl(ArmazemFicheiros.PREFIXO + chave));
    }

    @Test
    void recusaChavesForjadas() {
        var a = new ArmazemFicheiros(pasta);
        for (String url : new String[] {"armazem:../../etc/passwd", "armazem:2026/11/../../x.pdf", "https://exemplo/x.pdf",
                "armazem:2026/11/nao-e-uuid.pdf", "armazem:/etc/passwd", null}) {
            assertEquals(Optional.empty(), ArmazemFicheiros.chaveDoUrl(url), String.valueOf(url));
        }
        assertThrows(IllegalArgumentException.class, () -> a.ler("../segredo.pdf"));
        assertThrows(IllegalArgumentException.class, () -> a.guardar("../segredo.pdf", new byte[1]));
    }
}
