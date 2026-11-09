package mz.org.iasd.igreja.controllers.organizacao;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.organizacao.Igreja;

/**
 * Igrejas organizadas, grupos organizados e grupos/filiais.
 * Tabela {@code organizacao.igreja} · permissões {@code organizacao.igreja.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/organizacao/igrejas
 *   POST   /v1/organizacao/igrejas
 *   GET    /v1/organizacao/igrejas/{id}
 *   PATCH  /v1/organizacao/igrejas/{id}
 *   POST   /v1/organizacao/igrejas/{id}/terminar
 *   POST   /v1/organizacao/igrejas/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Organizacao.IGREJAS)
@RequestScoped
public class IgrejasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Igreja.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
