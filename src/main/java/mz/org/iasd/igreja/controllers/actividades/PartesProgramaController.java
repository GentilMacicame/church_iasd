package mz.org.iasd.igreja.controllers.actividades;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.actividades.ProgramaParte;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;

/**
 * F-ACT (V44) Programação do dia: partes da programação do dia (Escola Sabatina, Transição, Culto Divino, JA) e o apresentador.
 * Tabela {@code actividades.programa_parte} · permissões {@code actividades.programa_parte.*}. Rotas-padrão.
 */
@Path(Rotas.Actividades.PARTES_PROGRAMA)
@RequestScoped
public class PartesProgramaController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(ProgramaParte.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
