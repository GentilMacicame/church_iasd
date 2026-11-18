package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.tesouraria.Adiantamento;

/**
 * V50 Dinheiro adiantado a um responsável do departamento, que presta contas depois. Tabela {@code tesouraria.adiantamento} · permissões {@code tesouraria.adiantamento.*}. Rotas-padrão.
 */
@Path(Rotas.Tesouraria.ADIANTAMENTOS)
@RequestScoped
public class AdiantamentosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Adiantamento.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
