package mz.org.iasd.igreja.controllers.organizacao;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.organizacao.Distrito;

/**
 * Distritos pastorais de uma Associação/Missão.
 * Tabela {@code organizacao.distrito} · permissões {@code organizacao.distrito.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/organizacao/distritos
 *   POST   /v1/organizacao/distritos
 *   GET    /v1/organizacao/distritos/{id}
 *   PATCH  /v1/organizacao/distritos/{id}
 *   POST   /v1/organizacao/distritos/{id}/terminar
 *   POST   /v1/organizacao/distritos/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Organizacao.DISTRITOS)
@RequestScoped
public class DistritosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Distrito.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
