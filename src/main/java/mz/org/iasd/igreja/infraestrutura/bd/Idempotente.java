package mz.org.iasd.igreja.infraestrutura.bd;

import java.lang.annotation.ElementType;
import java.lang.annotation.Inherited;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Header {@code Idempotency-Key} (UUID) nos POST: o mesmo pedido repetido nas 24 horas seguintes devolve a
 * resposta guardada, sem criar nada de novo. A resposta é guardada na mesma transacção do trabalho.
 *
 * <ul>
 *   <li>num método: o header é obrigatório (POST que cria dinheiro). O método devolve {@code Response};</li>
 *   <li>numa classe com {@code opcional = true}: nos POST dessa classe, o header é usado se vier.</li>
 * </ul>
 */
@Inherited
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD, ElementType.TYPE})
public @interface Idempotente {

    /** {@code true}: usar a chave se vier, sem a exigir. */
    boolean opcional() default false;
}
