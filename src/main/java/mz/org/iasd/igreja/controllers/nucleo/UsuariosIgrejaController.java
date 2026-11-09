package mz.org.iasd.igreja.controllers.nucleo;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.nucleo.UsuarioIgreja;

/**
 * Perfil de cada utilizador em cada igreja (base da segurança por igreja).
 * Tabela {@code nucleo.usuario_igreja} · permissões {@code nucleo.usuario_igreja.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/nucleo/usuarios-igreja
 *   POST   /v1/nucleo/usuarios-igreja
 *   GET    /v1/nucleo/usuarios-igreja/{id}
 *   PATCH  /v1/nucleo/usuarios-igreja/{id}
 *   POST   /v1/nucleo/usuarios-igreja/{id}/terminar
 *   POST   /v1/nucleo/usuarios-igreja/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Nucleo.USUARIOS_IGREJA)
@RequestScoped
public class UsuariosIgrejaController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(UsuarioIgreja.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
