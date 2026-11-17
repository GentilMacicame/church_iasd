package mz.org.iasd.igreja.models.catalogo;

/**
 * Coluna de uma tabela, com o nome do campo JSON correspondente.
 *
 * @param coluna      nome completo, com prefixo (ex.: {@code mem_igr_id})
 * @param campo       nome no JSON (ex.: {@code igrejaId})
 * @param escrita     pode vir no corpo de criar/alterar (falso para id, campos-padrão e campos automáticos)
 * @param obrigatoria NOT NULL sem DEFAULT: tem de vir ao criar
 * @param naoNula     NOT NULL (pode ser usada para ordenar com paginação por cursor)
 * @param leitura     a API pode lê-la (falso nas colunas confidenciais só de escrita; ficam fora dos SELECT e do JSON)
 */
public record Coluna(String coluna, String campo, Tipo tipo, String tipoEnum, boolean escrita, boolean obrigatoria,
                     boolean naoNula, boolean leitura) {

    public Coluna(String coluna, String campo, Tipo tipo, String tipoEnum, boolean escrita, boolean obrigatoria, boolean naoNula) {
        this(coluna, campo, tipo, tipoEnum, escrita, obrigatoria, naoNula, true);
    }

    /** Expressão para o SELECT: enumerados e JSON lidos como texto. */
    public String expressaoLeitura() {
        return switch (tipo) {
            case ENUM, JSON -> coluna + "::text";
            default -> coluna;
        };
    }

    /** Parâmetro com cast explícito: os valores vão sempre como texto e o PostgreSQL converte. */
    public String parametro() {
        return "?::" + tipo.sql(tipoEnum);
    }

    /** Chave estrangeira (campo terminado em Id, inteiro, que não é a chave primária). */
    public boolean chaveEstrangeira() {
        return (tipo == Tipo.INT || tipo == Tipo.BIGINT) && campo.endsWith("Id") && coluna.endsWith("_id");
    }
}
