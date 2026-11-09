package mz.org.iasd.igreja.comum;

import mz.org.iasd.igreja.infraestrutura.erros.ApiException;

/**
 * Tamanho da página nas listagens: {@code ?limite=50} (máx. 200). O cursor ({@code ?depois=}) é tratado em
 * {@code repositories.base.TabelaRepository.Cursor} (valor da ordenação + id).
 */
public final class Paginacao {

    public static final int LIMITE_POR_DEFEITO = 50;
    public static final int LIMITE_MAXIMO = 200;

    private Paginacao() {
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
}
