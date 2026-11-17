package mz.org.iasd.igreja.controllers.base;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;

import mz.org.iasd.igreja.infraestrutura.erros.ApiException;

/** Leitura dos parâmetros de consulta ({@code ?x=}) das rotas próprias, com o erro 400 no campo certo. */
public final class Parametros {

    private Parametros() {
    }

    /** Inteiro; vazio → null (ou 400 "Campo obrigatório" se for obrigatório). */
    public static Integer inteiro(String v, String campo, boolean obrigatorio) {
        if (v == null || v.isBlank()) {
            if (obrigatorio) {
                throw ApiException.pedidoInvalido("Campo obrigatório", campo);
            }
            return null;
        }
        try {
            return Integer.valueOf(v.trim());
        } catch (NumberFormatException e) {
            throw ApiException.pedidoInvalido("Tem de ser um número inteiro", campo);
        }
    }

    /** Data aaaa-mm-dd; vazio → null (ou 400 se for obrigatória). */
    public static LocalDate data(String v, String campo, boolean obrigatorio) {
        if (v == null || v.isBlank()) {
            if (obrigatorio) {
                throw ApiException.pedidoInvalido("Campo obrigatório", campo);
            }
            return null;
        }
        try {
            return LocalDate.parse(v.trim());
        } catch (DateTimeParseException e) {
            throw ApiException.pedidoInvalido("Data inválida (aaaa-mm-dd)", campo);
        }
    }
}
