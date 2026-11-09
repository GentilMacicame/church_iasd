package mz.org.iasd.igreja.infraestrutura.erros;

/**
 * Erro decidido pela própria API (formato do pedido, autenticação, registo não encontrado).
 * Regras de negócio e permissões NÃO passam por aqui: vêm da base de dados ({@link ErroBaseDados}).
 */
public class ApiException extends RuntimeException {

    private final int estadoHttp;
    private final String codigo;
    private final String campo;

    public ApiException(int estadoHttp, String codigo, String mensagem, String campo) {
        super(mensagem);
        this.estadoHttp = estadoHttp;
        this.codigo = codigo;
        this.campo = campo;
    }

    public static ApiException pedidoInvalido(String mensagem, String campo) {
        return new ApiException(400, "pedido_invalido", mensagem, campo);
    }

    public static ApiException naoAutenticado(String mensagem) {
        return new ApiException(401, "nao_autenticado", mensagem, null);
    }

    /** Registo que não existe ou que o utilizador não pode ver (nunca 403: não revela que existe). */
    public static ApiException naoEncontrado() {
        return new ApiException(404, "nao_encontrado", "Registo não encontrado", null);
    }

    public int estadoHttp() {
        return estadoHttp;
    }

    public String codigo() {
        return codigo;
    }

    public String campo() {
        return campo;
    }
}
