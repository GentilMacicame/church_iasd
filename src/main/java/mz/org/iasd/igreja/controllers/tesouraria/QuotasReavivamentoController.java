package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.tesouraria.QuotaReavivamento;

/**
 * V49 Quota do reavivamento de uma pessoa no ano, ajustada à mão (as outras repartem o alvo da igreja). Tabela
 * {@code tesouraria.quota_reavivamento} · permissões {@code tesouraria.quota_reavivamento.*}. Rotas-padrão.
 */
@Path(Rotas.Tesouraria.QUOTAS_REAVIVAMENTO)
@RequestScoped
public class QuotasReavivamentoController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(QuotaReavivamento.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
