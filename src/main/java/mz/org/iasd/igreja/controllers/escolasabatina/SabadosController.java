package mz.org.iasd.igreja.controllers.escolasabatina;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.escolasabatina.Sabado;

/**
 * Sábados de cada trimestre.
 * Tabela {@code escola_sabatina.sabado} · permissões {@code escola_sabatina.sabado.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/escola-sabatina/sabados
 *   POST   /v1/escola-sabatina/sabados
 *   GET    /v1/escola-sabatina/sabados/{id}
 *   PATCH  /v1/escola-sabatina/sabados/{id}
 *   POST   /v1/escola-sabatina/sabados/{id}/terminar
 *   POST   /v1/escola-sabatina/sabados/{id}/reactivar
 * </pre>
 */
@Path(Rotas.EscolaSabatina.SABADOS)
@RequestScoped
public class SabadosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Sabado.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
