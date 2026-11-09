package mz.org.iasd.igreja.infraestrutura.seguranca;

import java.lang.reflect.Method;

import jakarta.annotation.Priority;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.ResourceInfo;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.ext.Provider;

import mz.org.iasd.igreja.infraestrutura.bd.ContextoPedido;
import mz.org.iasd.igreja.infraestrutura.erros.Respostas;

/**
 * Valida o token de acesso ({@code Authorization: Bearer ...}) e guarda o utilizador no contexto
 * do pedido. Quem pode fazer o quê NÃO se decide aqui: decide a base de dados (RLS e triggers),
 * com o utilizador identificado por {@code set_config('app.usuario_id', ..., true)}.
 */
@Provider
@Priority(Priorities.AUTHENTICATION)
@ApplicationScoped
public class FiltroAutenticacao implements ContainerRequestFilter {

    @Context
    ResourceInfo recurso;

    @Inject
    ContextoPedido contexto;

    @Inject
    Tokens tokens;

    @Override
    public void filter(ContainerRequestContext pedido) {
        if (ePublico()) {
            return;
        }
        String cabecalho = pedido.getHeaderString(HttpHeaders.AUTHORIZATION);
        Tokens.Identidade identidade = null;
        if (cabecalho != null && cabecalho.regionMatches(true, 0, "Bearer ", 0, 7)) {
            identidade = tokens.verificar(cabecalho.substring(7).trim());
        }
        if (identidade == null) {
            pedido.abortWith(Respostas.erro(401, "nao_autenticado",
                    "Sessão em falta ou expirada. Entre de novo.", null, contexto.pedidoId()));
            return;
        }
        contexto.definirUsuario(identidade.usuarioId());
        contexto.definirSessao(identidade.sessaoId());
    }

    private boolean ePublico() {
        Method metodo = recurso.getResourceMethod();
        Class<?> classe = recurso.getResourceClass();
        return (metodo != null && metodo.isAnnotationPresent(Publico.class))
                || (classe != null && classe.isAnnotationPresent(Publico.class));
    }
}
