package mz.org.iasd.igreja.crud;

/** Tipo de uma coluna, do ponto de vista do JSON e da conversão para SQL. */
public enum Tipo {
    INT("integer"),
    BIGINT("bigint"),
    TEXTO("text"),
    /** DECIMAL(12..16,2): em JSON é texto com 2 casas ("650.00"). */
    DINHEIRO("numeric"),
    /** Outros DECIMAL (coordenadas, quantidades, pesos): texto sem casas fixas. */
    DECIMAL("numeric"),
    DATA("date"),
    DATA_HORA("timestamptz"),
    BOOLEANO("boolean"),
    JSON("jsonb"),
    /** Tipo enumerado do schema nucleo (o nome está em {@link Coluna#tipoEnum()}). */
    ENUM(null);

    private final String sql;

    Tipo(String sql) {
        this.sql = sql;
    }

    /** Tipo SQL para o cast do parâmetro ({@code ?::tipo}). */
    public String sql(String tipoEnum) {
        return this == ENUM ? "nucleo." + tipoEnum : sql;
    }
}
