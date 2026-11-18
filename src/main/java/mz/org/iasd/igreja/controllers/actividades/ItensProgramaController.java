package mz.org.iasd.igreja.controllers.actividades;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.actividades.ProgramaItem;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;

/**
 * F-ACT (V44) Programação do dia: itens da programação do dia: horas, actividade, responsável e destaque.
 * Tabela {@code actividades.programa_item} · permissões {@code actividades.programa_item.*}. Rotas-padrão.
 */
@Path(Rotas.Actividades.ITENS_PROGRAMA)
@RequestScoped
public class ItensProgramaController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(ProgramaItem.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
