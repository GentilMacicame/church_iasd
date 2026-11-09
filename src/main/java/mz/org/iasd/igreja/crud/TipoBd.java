package mz.org.iasd.igreja.crud;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/** Liga um {@code enum} Java ao tipo enumerado do PostgreSQL (schema {@code nucleo}). */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface TipoBd {

    /** Nome do tipo na base de dados (ex.: {@code estado_membro_t}). */
    String value();
}
