package mz.org.iasd.igreja.controllers.actividades;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.actividades.Escala;

/**
 * Escalas de serviço (pregador, diáconos, recepção, ...).
 * Tabela {@code actividades.escala} · permissões {@code actividades.escala.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/actividades/escalas
 *   POST   /v1/actividades/escalas
 *   GET    /v1/actividades/escalas/{id}
 *   PATCH  /v1/actividades/escalas/{id}
 *   POST   /v1/actividades/escalas/{id}/terminar
 *   POST   /v1/actividades/escalas/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Actividades.ESCALAS)
@RequestScoped
public class EscalasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Escala.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
