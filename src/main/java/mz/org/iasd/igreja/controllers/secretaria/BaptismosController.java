package mz.org.iasd.igreja.controllers.secretaria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.secretaria.Baptismo;

/**
 * Baptismos e rebaptismos.
 * Tabela {@code secretaria.baptismo} · permissões {@code secretaria.baptismo.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/secretaria/baptismos
 *   POST   /v1/secretaria/baptismos
 *   GET    /v1/secretaria/baptismos/{id}
 *   PATCH  /v1/secretaria/baptismos/{id}
 *   POST   /v1/secretaria/baptismos/{id}/terminar
 *   POST   /v1/secretaria/baptismos/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Secretaria.BAPTISMOS)
@RequestScoped
public class BaptismosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Baptismo.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
