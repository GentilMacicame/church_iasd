package mz.org.iasd.igreja.controllers.escolasabatina;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.escolasabatina.Trimestre;

/**
 * Trimestres da lição.
 * Tabela {@code escola_sabatina.trimestre} · permissões {@code escola_sabatina.trimestre.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/escola-sabatina/trimestres
 *   POST   /v1/escola-sabatina/trimestres
 *   GET    /v1/escola-sabatina/trimestres/{id}
 *   PATCH  /v1/escola-sabatina/trimestres/{id}
 *   POST   /v1/escola-sabatina/trimestres/{id}/terminar
 *   POST   /v1/escola-sabatina/trimestres/{id}/reactivar
 * </pre>
 */
@Path(Rotas.EscolaSabatina.TRIMESTRES)
@RequestScoped
public class TrimestresController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Trimestre.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
