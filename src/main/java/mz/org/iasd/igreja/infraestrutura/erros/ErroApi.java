package mz.org.iasd.igreja.infraestrutura.erros;

/**
 * Corpo de todas as respostas de erro (schema {@code Erro} do contrato).
 * A {@code mensagem} está sempre em português, pronta a mostrar ao utilizador.
 */
public record ErroApi(String erro, String mensagem, String campo, String pedidoId) {
}
