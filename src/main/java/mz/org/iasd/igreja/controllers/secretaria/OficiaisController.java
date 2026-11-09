package mz.org.iasd.igreja.controllers.secretaria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.secretaria.Oficial;

/**
 * Eleições e mandatos: quem ocupou que cargo e quando.
 * Tabela {@code secretaria.oficial} · permissões {@code secretaria.oficial.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/secretaria/oficiais
 *   POST   /v1/secretaria/oficiais
 *   GET    /v1/secretaria/oficiais/{id}
 *   PATCH  /v1/secretaria/oficiais/{id}
 *   POST   /v1/secretaria/oficiais/{id}/terminar
 *   POST   /v1/secretaria/oficiais/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Secretaria.OFICIAIS)
@RequestScoped
public class OficiaisController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Oficial.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
