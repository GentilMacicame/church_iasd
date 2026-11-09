package mz.org.iasd.igreja.controllers.secretaria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.secretaria.Familia;

/**
 * Agregados familiares.
 * Tabela {@code secretaria.familia} · permissões {@code secretaria.familia.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/secretaria/familias
 *   POST   /v1/secretaria/familias
 *   GET    /v1/secretaria/familias/{id}
 *   PATCH  /v1/secretaria/familias/{id}
 *   POST   /v1/secretaria/familias/{id}/terminar
 *   POST   /v1/secretaria/familias/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Secretaria.FAMILIAS)
@RequestScoped
public class FamiliasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Familia.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
