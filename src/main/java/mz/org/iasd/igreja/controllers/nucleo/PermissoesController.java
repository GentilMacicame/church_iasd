package mz.org.iasd.igreja.controllers.nucleo;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.nucleo.Permissao;

/**
 * Permissões elementares (ex.: transacao.aprovar).
 * Tabela {@code nucleo.permissao} · permissões {@code nucleo.permissao.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/nucleo/permissoes
 *   POST   /v1/nucleo/permissoes
 *   GET    /v1/nucleo/permissoes/{id}
 *   PATCH  /v1/nucleo/permissoes/{id}
 *   POST   /v1/nucleo/permissoes/{id}/terminar
 *   POST   /v1/nucleo/permissoes/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Nucleo.PERMISSOES)
@RequestScoped
public class PermissoesController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Permissao.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
