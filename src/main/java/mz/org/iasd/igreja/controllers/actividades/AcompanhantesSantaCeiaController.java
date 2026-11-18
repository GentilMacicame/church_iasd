package mz.org.iasd.igreja.controllers.actividades;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.actividades.SantaCeiaAcompanhante;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;

/**
 * V51 Quem acompanha o oficiante na Santa Ceia (os diáconos e as diaconisas), membros da mesma igreja. Tabela
 * {@code actividades.santa_ceia_acompanhante} · permissões {@code actividades.santa_ceia_acompanhante.*}. Rotas-padrão.
 */
@Path(Rotas.Actividades.ACOMPANHANTES_SANTA_CEIA)
@RequestScoped
public class AcompanhantesSantaCeiaController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(SantaCeiaAcompanhante.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
