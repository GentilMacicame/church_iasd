package mz.org.iasd.igreja.controllers.nucleo;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.nucleo.Perfil;

/**
 * Perfis de acesso (Admin, Secretário, Tesoureiro, ...).
 * Tabela {@code nucleo.perfil} · permissões {@code nucleo.perfil.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/nucleo/perfis
 *   POST   /v1/nucleo/perfis
 *   GET    /v1/nucleo/perfis/{id}
 *   PATCH  /v1/nucleo/perfis/{id}
 *   POST   /v1/nucleo/perfis/{id}/terminar
 *   POST   /v1/nucleo/perfis/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Nucleo.PERFIS)
@RequestScoped
public class PerfisController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Perfil.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
