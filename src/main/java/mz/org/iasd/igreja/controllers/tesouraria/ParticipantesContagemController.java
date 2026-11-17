package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.ContagemParticipante;

/**
 * F-TES (V42) Quem participou na contagem do numerário e com que função (tesoureiro, Escola Sabatina, diácono,
 * ancião, outro), além dos dois contadores. O membro tem de ser da igreja da contagem (regra da base de dados).
 * Tabela {@code tesouraria.contagem_participante} · permissões {@code tesouraria.contagem_participante.*}. Rotas-padrão.
 */
@Path(Rotas.Tesouraria.PARTICIPANTES_CONTAGEM)
@RequestScoped
public class ParticipantesContagemController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(ContagemParticipante.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
