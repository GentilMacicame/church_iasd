package mz.org.iasd.igreja.infraestrutura.erros;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import jakarta.validation.Path;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

import mz.org.iasd.igreja.infraestrutura.bd.ContextoPedido;

/** Validação de formato (Bean Validation) → 400 pedido_invalido, com o campo para o formulário. */
@Provider
@ApplicationScoped
public class MapeadorValidacao implements ExceptionMapper<ConstraintViolationException> {

    @Inject
    ContextoPedido contexto;

    @Override
    public Response toResponse(ConstraintViolationException e) {
        ConstraintViolation<?> v = e.getConstraintViolations().stream().findFirst().orElse(null);
        if (v == null) {
            return Respostas.erro(400, "pedido_invalido", "Pedido inválido", null, contexto.pedidoId());
        }
        String campo = null;
        for (Path.Node no : v.getPropertyPath()) {
            campo = no.getName();
        }
        if (campo != null && campo.startsWith("arg")) {
            campo = null;     // corpo do pedido em falta
        }
        return Respostas.erro(400, "pedido_invalido", v.getMessage(), campo, contexto.pedidoId());
    }
}
