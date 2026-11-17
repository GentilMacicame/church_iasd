package mz.org.iasd.igreja.controllers.actividades;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.actividades.SantaCeia;

/**
 * F-ACT (V39) Santa Ceia: agendamento (data, hora, local, responsável) e, depois de realizada, os participantes
 * (homens, mulheres, visitantes). As regras (uma por dia, realizada só depois do dia, números) são da base de dados.
 * Tabela {@code actividades.santa_ceia} · permissões {@code actividades.santa_ceia.*}. Rotas-padrão.
 */
@Path(Rotas.Actividades.SANTAS_CEIAS)
@RequestScoped
public class SantasCeiasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(SantaCeia.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
