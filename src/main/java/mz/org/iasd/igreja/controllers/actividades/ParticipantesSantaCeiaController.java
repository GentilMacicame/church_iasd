package mz.org.iasd.igreja.controllers.actividades;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.actividades.SantaCeiaParticipante;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;

/**
 * V52 Os membros que participaram na Santa Ceia, pelo nome (os visitantes ficam só em número). Tabela
 * {@code actividades.santa_ceia_participante} · permissões {@code actividades.santa_ceia_participante.*}. Rotas-padrão.
 */
@Path(Rotas.Actividades.PARTICIPANTES_SANTA_CEIA)
@RequestScoped
public class ParticipantesSantaCeiaController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(SantaCeiaParticipante.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
