package mz.org.iasd.igreja.infraestrutura.seguranca;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/** Endpoint acessível sem token de acesso (login, renovar, recuperar, redefinir). */
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.TYPE, ElementType.METHOD})
public @interface Publico {
}
