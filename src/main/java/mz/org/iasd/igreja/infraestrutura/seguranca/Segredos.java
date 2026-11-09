package mz.org.iasd.igreja.infraestrutura.seguranca;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.InvalidKeyException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/** Tokens aleatórios e hashes. Na base de dados só se guardam hashes, nunca os tokens ou códigos. */
public final class Segredos {

    private static final SecureRandom ALEATORIO = new SecureRandom();

    private Segredos() {
    }

    /** Token de renovação: 256 bits aleatórios em base64url. */
    public static String tokenAleatorio() {
        byte[] b = new byte[32];
        ALEATORIO.nextBytes(b);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(b);
    }

    /** Código de recuperação de 6 dígitos. */
    public static String codigoSeisDigitos() {
        return String.format("%06d", ALEATORIO.nextInt(1_000_000));
    }

    /** Hash do token de renovação (alta entropia: SHA-256 chega). */
    public static String sha256(String valor) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(valor.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    /**
     * Hash do código de recuperação. Um código de 6 dígitos tem pouca entropia: usa-se HMAC com um
     * segredo do servidor para que uma fuga da base de dados não permita descobrir os códigos.
     */
    public static String hmac(String segredo, String valor) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(segredo.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return HexFormat.of().formatHex(mac.doFinal(valor.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException | InvalidKeyException e) {
            throw new IllegalStateException(e);
        }
    }
}
