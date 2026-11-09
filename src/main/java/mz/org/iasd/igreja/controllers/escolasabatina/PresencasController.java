package mz.org.iasd.igreja.controllers.escolasabatina;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.escolasabatina.Presenca;

/**
 * Chamada nominal (opcional); actualiza M.P. e E.D. do relatório.
 * Tabela {@code escola_sabatina.presenca} · permissões {@code escola_sabatina.presenca.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/escola-sabatina/presencas
 *   POST   /v1/escola-sabatina/presencas
 *   GET    /v1/escola-sabatina/presencas/{id}
 *   PATCH  /v1/escola-sabatina/presencas/{id}
 *   POST   /v1/escola-sabatina/presencas/{id}/terminar
 *   POST   /v1/escola-sabatina/presencas/{id}/reactivar
 * </pre>
 */
@Path(Rotas.EscolaSabatina.PRESENCAS)
@RequestScoped
public class PresencasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Presenca.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
