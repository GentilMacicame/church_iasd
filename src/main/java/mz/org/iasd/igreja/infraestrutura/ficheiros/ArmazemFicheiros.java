package mz.org.iasd.igreja.infraestrutura.ficheiros;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * Ficheiros dos comprovativos (fotografias de talões, prints M-Pesa, PDF) numa pasta do servidor
 * ({@code FICHEIROS_PASTA}). A especificação prevê armazenamento compatível com S3; esta classe é o único sítio que
 * sabe onde os bytes ficam, por isso trocar para S3 mexe só aqui.
 * <p>
 * Segurança: quem pode ver um ficheiro decide-o a base de dados (a linha de {@code tesouraria.documento} tem de ser
 * visível pela RLS antes de se ler o ficheiro). Aqui só se garante que a chave foi gerada por nós (formato fixo,
 * sem {@code ..}) e que o tipo do ficheiro é o que os primeiros bytes dizem, não o que o cliente declara.
 */
public final class ArmazemFicheiros {

    /** Prefixo de {@code doc_url} para ficheiros guardados aqui. */
    public static final String PREFIXO = "armazem:";
    private static final Pattern CHAVE = Pattern.compile("^\\d{4}/\\d{2}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\.(jpg|png|webp|pdf)$");

    /** Tipos aceites, reconhecidos pelos primeiros bytes. */
    public enum Tipo {
        JPG("image/jpeg"), PNG("image/png"), WEBP("image/webp"), PDF("application/pdf");

        public final String mime;

        Tipo(String mime) {
            this.mime = mime;
        }

        public String extensao() {
            return name().toLowerCase();
        }

        public static Tipo daChave(String chave) {
            return valueOf(chave.substring(chave.lastIndexOf('.') + 1).toUpperCase());
        }
    }

    private final Path raiz;

    public ArmazemFicheiros(Path raiz) {
        this.raiz = raiz.toAbsolutePath().normalize();
    }

    /** O tipo do ficheiro pelos primeiros bytes (assinatura); vazio se não for fotografia nem PDF. */
    public static Optional<Tipo> tipo(byte[] d) {
        if (d.length >= 3 && (d[0] & 0xFF) == 0xFF && (d[1] & 0xFF) == 0xD8 && (d[2] & 0xFF) == 0xFF) {
            return Optional.of(Tipo.JPG);
        }
        if (d.length >= 8 && (d[0] & 0xFF) == 0x89 && d[1] == 'P' && d[2] == 'N' && d[3] == 'G') {
            return Optional.of(Tipo.PNG);
        }
        if (d.length >= 12 && d[0] == 'R' && d[1] == 'I' && d[2] == 'F' && d[3] == 'F' && d[8] == 'W' && d[9] == 'E' && d[10] == 'B' && d[11] == 'P') {
            return Optional.of(Tipo.WEBP);
        }
        if (d.length >= 5 && d[0] == '%' && d[1] == 'P' && d[2] == 'D' && d[3] == 'F' && d[4] == '-') {
            return Optional.of(Tipo.PDF);
        }
        return Optional.empty();
    }

    /** Chave nova, por ano e mês: {@code 2026/11/<uuid>.jpg}. */
    public static String novaChave(Tipo tipo) {
        LocalDate hoje = LocalDate.now();
        return String.format("%04d/%02d/%s.%s", hoje.getYear(), hoje.getMonthValue(), UUID.randomUUID(), tipo.extensao());
    }

    /** A chave de um {@code doc_url} deste armazém, se for válida. */
    public static Optional<String> chaveDoUrl(String url) {
        if (url == null || !url.startsWith(PREFIXO)) {
            return Optional.empty();
        }
        String chave = url.substring(PREFIXO.length());
        return CHAVE.matcher(chave).matches() ? Optional.of(chave) : Optional.empty();
    }

    /** Escreve o ficheiro (primeiro num temporário na mesma pasta, depois move: nunca fica meio escrito). */
    public void guardar(String chave, byte[] dados) {
        Path destino = caminho(chave);
        try {
            Files.createDirectories(destino.getParent());
            Path tmp = Files.createTempFile(destino.getParent(), ".carregar-", ".tmp");
            try {
                Files.write(tmp, dados);
                Files.move(tmp, destino, StandardCopyOption.ATOMIC_MOVE);
            } finally {
                Files.deleteIfExists(tmp);
            }
        } catch (IOException e) {
            throw new UncheckedIOException("Não foi possível guardar o ficheiro " + chave, e);
        }
    }

    /** Os bytes do ficheiro; vazio se não existir. */
    public Optional<byte[]> ler(String chave) {
        Path p = caminho(chave);
        try {
            return Files.isRegularFile(p) ? Optional.of(Files.readAllBytes(p)) : Optional.empty();
        } catch (IOException e) {
            throw new UncheckedIOException("Não foi possível ler o ficheiro " + chave, e);
        }
    }

    private Path caminho(String chave) {
        if (!CHAVE.matcher(chave).matches()) {
            throw new IllegalArgumentException("Chave de ficheiro inválida");
        }
        Path p = raiz.resolve(chave).normalize();
        if (!p.startsWith(raiz)) {
            throw new IllegalArgumentException("Chave de ficheiro inválida");
        }
        return p;
    }
}
