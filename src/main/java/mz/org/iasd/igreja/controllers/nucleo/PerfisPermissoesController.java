package mz.org.iasd.igreja.controllers.nucleo;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.nucleo.PerfilPermissao;

/**
 * Que permissões cada perfil tem.
 * Tabela {@code nucleo.perfil_permissao} · permissões {@code nucleo.perfil_permissao.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/nucleo/perfis-permissoes
 *   POST   /v1/nucleo/perfis-permissoes
 *   GET    /v1/nucleo/perfis-permissoes/{id}
 *   PATCH  /v1/nucleo/perfis-permissoes/{id}
 *   POST   /v1/nucleo/perfis-permissoes/{id}/terminar
 *   POST   /v1/nucleo/perfis-permissoes/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Nucleo.PERFIS_PERMISSOES)
@RequestScoped
public class PerfisPermissoesController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(PerfilPermissao.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
