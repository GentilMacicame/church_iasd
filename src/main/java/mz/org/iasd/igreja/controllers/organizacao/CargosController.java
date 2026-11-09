package mz.org.iasd.igreja.controllers.organizacao;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.organizacao.Cargo;

/**
 * Cargos da igreja (Ancião, Secretário, Tesoureiro, Director da ES, ...).
 * Tabela {@code organizacao.cargo} · permissões {@code organizacao.cargo.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/organizacao/cargos
 *   POST   /v1/organizacao/cargos
 *   GET    /v1/organizacao/cargos/{id}
 *   PATCH  /v1/organizacao/cargos/{id}
 *   POST   /v1/organizacao/cargos/{id}/terminar
 *   POST   /v1/organizacao/cargos/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Organizacao.CARGOS)
@RequestScoped
public class CargosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Cargo.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
