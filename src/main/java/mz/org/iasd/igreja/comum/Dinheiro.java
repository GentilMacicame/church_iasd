package mz.org.iasd.igreja.comum;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.regex.Pattern;

import mz.org.iasd.igreja.infraestrutura.erros.ApiException;

/** Dinheiro em JSON é sempre texto com 2 casas decimais ("650.00"), nunca number/float. */
public final class Dinheiro {

    private static final Pattern FORMATO = Pattern.compile("^-?\\d{1,14}(\\.\\d{1,2})?$");

    private Dinheiro() {
    }

    public static String paraJson(BigDecimal valor) {
        return valor == null ? null : valor.setScale(2, RoundingMode.UNNECESSARY).toPlainString();
    }

    public static BigDecimal deJson(String texto, String campo) {
        if (texto == null) {
            return null;
        }
        if (!FORMATO.matcher(texto).matches()) {
            throw ApiException.pedidoInvalido("Valor em dinheiro inválido: use o formato 1500.50", campo);
        }
        return new BigDecimal(texto).setScale(2, RoundingMode.UNNECESSARY);
    }
}
