package mz.org.iasd.igreja.controllers.actividades;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.actividades.Actividade;

/**
 * Actividades e eventos dos departamentos.
 * Tabela {@code actividades.actividade} · permissões {@code actividades.actividade.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/actividades/actividades
 *   POST   /v1/actividades/actividades
 *   GET    /v1/actividades/actividades/{id}
 *   PATCH  /v1/actividades/actividades/{id}
 *   POST   /v1/actividades/actividades/{id}/terminar
 *   POST   /v1/actividades/actividades/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Actividades.ACTIVIDADES)
@RequestScoped
public class ActividadesController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Actividade.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
