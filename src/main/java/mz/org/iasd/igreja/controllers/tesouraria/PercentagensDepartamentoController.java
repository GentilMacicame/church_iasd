package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.tesouraria.PercentagemDepartamento;

/**
 * V50 Parte de cada departamento no ano (reparte a doação distribuída). Tabela {@code tesouraria.percentagem_departamento} · permissões {@code tesouraria.percentagem_departamento.*}. Rotas-padrão.
 */
@Path(Rotas.Tesouraria.PERCENTAGENS_DEPARTAMENTO)
@RequestScoped
public class PercentagensDepartamentoController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(PercentagemDepartamento.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
