package mz.org.iasd.igreja.controllers.nucleo;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.nucleo.ComunicadoIgreja;

/**
 * Igrejas a que se dirige um comunicado do distrito ou da Associação (V37); sem linhas, todas as do emissor.
 * Rotas-padrão: listar, ler, criar, alterar, terminar, reactivar.
 */
@Path(Rotas.Nucleo.COMUNICADOS_IGREJAS)
@RequestScoped
public class ComunicadosIgrejasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(ComunicadoIgreja.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
