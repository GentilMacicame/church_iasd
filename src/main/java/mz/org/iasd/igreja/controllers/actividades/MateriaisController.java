package mz.org.iasd.igreja.controllers.actividades;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.actividades.Material;

/**
 * Material necessário para uma actividade.
 * Tabela {@code actividades.material} · permissões {@code actividades.material.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/actividades/materiais
 *   POST   /v1/actividades/materiais
 *   GET    /v1/actividades/materiais/{id}
 *   PATCH  /v1/actividades/materiais/{id}
 *   POST   /v1/actividades/materiais/{id}/terminar
 *   POST   /v1/actividades/materiais/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Actividades.MATERIAIS)
@RequestScoped
public class MateriaisController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Material.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
