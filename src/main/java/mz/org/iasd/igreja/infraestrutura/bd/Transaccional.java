package mz.org.iasd.igreja.infraestrutura.bd;

import java.lang.annotation.ElementType;
import java.lang.annotation.Inherited;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import jakarta.interceptor.InterceptorBinding;

/**
 * Cada método anotado (ou cada método da classe anotada) corre numa transacção própria,
 * com o utilizador do pedido identificado na base de dados. Ver {@link TransaccionalInterceptor}.
 */
@Inherited
@InterceptorBinding
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.TYPE, ElementType.METHOD})
public @interface Transaccional {
}
