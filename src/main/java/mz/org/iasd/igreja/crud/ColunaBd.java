package mz.org.iasd.igreja.crud;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Liga um campo de um model à coluna da tabela. O nome do campo é o nome no JSON
 * ({@code mem_igr_id} → {@code igrejaId}).
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.RECORD_COMPONENT)
public @interface ColunaBd {

    /** Nome completo da coluna, com prefixo (ex.: {@code mem_igr_id}). */
    String value();

    /** Tipo, para a conversão JSON ⇄ SQL. */
    Tipo tipo();

    /** Pode vir no corpo de criar/alterar (falso para id, campos-padrão e campos preenchidos pela base). */
    boolean escrita() default true;

    /** NOT NULL sem DEFAULT: tem de vir ao criar. */
    boolean obrigatoria() default false;

    /** NOT NULL (pode ser usada para ordenar com paginação por cursor). */
    boolean naoNula() default false;
}
