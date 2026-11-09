package mz.org.iasd.igreja.comum;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.List;

import mz.org.iasd.igreja.infraestrutura.erros.ApiException;

/**
 * Paginação por cursor: {@code ?limite=50&depois=<cursor>} (máx. 200). Resposta {@code { dados, proximo }}.
 * O cursor é opaco para o cliente; internamente é o último id da página.
 */
public final class Paginacao {

    public static final int LIMITE_POR_DEFEITO = 50;
    public static final int LIMITE_MAXIMO = 200;

    private Paginacao() {
    }

    /** Uma página de resultados, no formato do contrato. */
    public record Pagina<T>(List<T> dados, String proximo) {
    }

    public static int limite(Integer pedido) {
        if (pedido == null) {
            return LIMITE_POR_DEFEITO;
        }
        if (pedido < 1 || pedido > LIMITE_MAXIMO) {
            throw ApiException.pedidoInvalido("O limite tem de estar entre 1 e " + LIMITE_MAXIMO, "limite");
        }
        return pedido;
    }

    public static String codificar(long ultimoId) {
        return Base64.getUrlEncoder().withoutPadding()
                .encodeToString(("id:" + ultimoId).getBytes(StandardCharsets.UTF_8));
    }

    /** @return o id a partir do qual continuar, ou {@code null} na primeira página */
    public static Long descodificar(String cursor) {
        if (cursor == null || cursor.isBlank()) {
            return null;
        }
        try {
            String texto = new String(Base64.getUrlDecoder().decode(cursor), StandardCharsets.UTF_8);
            if (!texto.startsWith("id:")) {
                throw new IllegalArgumentException();
            }
            return Long.parseLong(texto.substring(3));
        } catch (IllegalArgumentException e) {
            throw ApiException.pedidoInvalido("Cursor de paginação inválido", "depois");
        }
    }

    /**
     * Fecha a página: a consulta deve ter pedido {@code limite + 1} linhas; se vierem mais do que
     * {@code limite}, há página seguinte.
     */
    public static <T> Pagina<T> pagina(List<T> linhas, int limite, java.util.function.ToLongFunction<T> id) {
        if (linhas.size() <= limite) {
            return new Pagina<>(linhas, null);
        }
        List<T> dados = List.copyOf(linhas.subList(0, limite));
        return new Pagina<>(dados, codificar(id.applyAsLong(dados.get(dados.size() - 1))));
    }
}
