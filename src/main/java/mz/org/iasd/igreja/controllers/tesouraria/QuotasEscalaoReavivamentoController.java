package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.tesouraria.QuotaEscalaoReavivamento;

/**
 * V51 Quota do reavivamento fixada no ano para todos os adultos e/ou todas as crianças. Tabela
 * {@code tesouraria.quota_escalao_reavivamento} · permissões {@code tesouraria.quota_escalao_reavivamento.*}. Rotas-padrão.
 */
@Path(Rotas.Tesouraria.QUOTAS_ESCALAO_REAVIVAMENTO)
@RequestScoped
public class QuotasEscalaoReavivamentoController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(QuotaEscalaoReavivamento.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
