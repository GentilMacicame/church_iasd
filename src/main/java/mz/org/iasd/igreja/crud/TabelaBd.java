package mz.org.iasd.igreja.crud;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Liga um model ({@code record} em {@code models/<modulo>/}) à tabela da base de dados e ao recurso REST
 * {@code /v1/<modulo>/<recurso>}.
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface TabelaBd {

    /** Schema (ex.: {@code secretaria}). */
    String schema();

    /** Nome da tabela (ex.: {@code membro}). */
    String nome();

    /** Prefixo de 3 letras das colunas (ex.: {@code mem}). */
    String prefixo();

    /** Módulo no caminho da API (ex.: {@code escola-sabatina}). */
    String modulo();

    /** Recurso no caminho da API (ex.: {@code membros}). */
    String recurso();

    /** Escrita só pelo sistema (saldos, auditoria): sem POST, PATCH nem terminar. */
    boolean soLeitura() default false;

    /** Coluna de igreja directa; nas listagens o filtro {@code igrejaId} é obrigatório. Vazio = não tem. */
    String colunaIgreja() default "";
}
