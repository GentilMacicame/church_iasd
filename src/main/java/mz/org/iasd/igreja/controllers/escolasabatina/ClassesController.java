package mz.org.iasd.igreja.controllers.escolasabatina;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.escolasabatina.Classe;

/**
 * Classes / unidades de acção, por divisão da Escola Sabatina.
 * Tabela {@code escola_sabatina.classe} · permissões {@code escola_sabatina.classe.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/escola-sabatina/classes
 *   POST   /v1/escola-sabatina/classes
 *   GET    /v1/escola-sabatina/classes/{id}
 *   PATCH  /v1/escola-sabatina/classes/{id}
 *   POST   /v1/escola-sabatina/classes/{id}/terminar
 *   POST   /v1/escola-sabatina/classes/{id}/reactivar
 * </pre>
 */
@Path(Rotas.EscolaSabatina.CLASSES)
@RequestScoped
public class ClassesController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Classe.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
