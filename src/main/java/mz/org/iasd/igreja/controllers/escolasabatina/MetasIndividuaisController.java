package mz.org.iasd.igreja.controllers.escolasabatina;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.escolasabatina.MetaIndividual;

/**
 * F-ES (V47) Meta de oferta missionária de cada aluno no trimestre; a da classe é a soma (calculada pela base de dados). Tabela {@code escola_sabatina.meta_individual} · permissões {@code escola_sabatina.meta_individual.*}. Rotas-padrão.
 */
@Path(Rotas.EscolaSabatina.METAS_INDIVIDUAIS)
@RequestScoped
public class MetasIndividuaisController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(MetaIndividual.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
