package mz.org.iasd.igreja.controllers.nucleo;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.nucleo.UsuarioEntidade;

/**
 * Perfil de um utilizador numa Associação/Missão inteira (vale para todas as igrejas abaixo dela).
 * Tabela {@code nucleo.usuario_entidade} · permissões {@code nucleo.usuario_entidade.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/nucleo/usuarios-entidade
 *   POST   /v1/nucleo/usuarios-entidade
 *   GET    /v1/nucleo/usuarios-entidade/{id}
 *   PATCH  /v1/nucleo/usuarios-entidade/{id}
 *   POST   /v1/nucleo/usuarios-entidade/{id}/terminar
 *   POST   /v1/nucleo/usuarios-entidade/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Nucleo.USUARIOS_ENTIDADE)
@RequestScoped
public class UsuariosEntidadeController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(UsuarioEntidade.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
