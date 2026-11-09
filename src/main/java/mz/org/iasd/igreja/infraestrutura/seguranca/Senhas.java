package mz.org.iasd.igreja.infraestrutura.seguranca;

import com.password4j.Argon2Function;
import com.password4j.BcryptFunction;
import com.password4j.Password;
import com.password4j.types.Argon2;

/**
 * Senhas com Argon2id (parâmetros recomendados pela OWASP: 19 MiB, 2 iterações, paralelismo 1).
 * Aceita também hashes bcrypt antigos na verificação.
 */
public final class Senhas {

    private static final Argon2Function ARGON2ID = Argon2Function.getInstance(19_456, 2, 1, 32, Argon2.ID, 19);

    /** Hash usado quando o login não existe, para a resposta demorar o mesmo tempo. */
    private static final String HASH_FICTICIO = gerarHash("senha-ficticia-para-igualar-o-tempo");

    private Senhas() {
    }

    public static String gerarHash(String senha) {
        return Password.hash(senha).addRandomSalt(16).with(ARGON2ID).getResult();
    }

    public static boolean confere(String senha, String hash) {
        if (senha == null || hash == null) {
            return false;
        }
        try {
            if (hash.startsWith("$argon2")) {
                return Password.check(senha, hash).with(Argon2Function.getInstanceFromHash(hash));
            }
            if (hash.startsWith("$2")) {
                return Password.check(senha, hash).with(BcryptFunction.getInstanceFromHash(hash));
            }
        } catch (RuntimeException e) {
            return false;    // hash corrompido ou num formato desconhecido
        }
        return false;
    }

    /** Gasta o mesmo tempo de uma verificação real (login inexistente). */
    public static void gastarTempo(String senha) {
        confere(senha == null ? "" : senha, HASH_FICTICIO);
    }
}
