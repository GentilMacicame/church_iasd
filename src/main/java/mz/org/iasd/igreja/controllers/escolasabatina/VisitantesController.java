package mz.org.iasd.igreja.controllers.escolasabatina;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.escolasabatina.Visitante;

/**
 * Visitantes com contacto para seguimento.
 * Tabela {@code escola_sabatina.visitante} · permissões {@code escola_sabatina.visitante.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/escola-sabatina/visitantes
 *   POST   /v1/escola-sabatina/visitantes
 *   GET    /v1/escola-sabatina/visitantes/{id}
 *   PATCH  /v1/escola-sabatina/visitantes/{id}
 *   POST   /v1/escola-sabatina/visitantes/{id}/terminar
 *   POST   /v1/escola-sabatina/visitantes/{id}/reactivar
 * </pre>
 */
@Path(Rotas.EscolaSabatina.VISITANTES)
@RequestScoped
public class VisitantesController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Visitante.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
