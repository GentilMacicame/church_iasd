package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.OrcamentoLinha;

/**
 * Valor previsto por categoria.
 * Tabela {@code tesouraria.orcamento_linha} · permissões {@code tesouraria.orcamento_linha.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/linhas-orcamento
 *   POST   /v1/tesouraria/linhas-orcamento
 *   GET    /v1/tesouraria/linhas-orcamento/{id}
 *   PATCH  /v1/tesouraria/linhas-orcamento/{id}
 *   POST   /v1/tesouraria/linhas-orcamento/{id}/terminar
 *   POST   /v1/tesouraria/linhas-orcamento/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.LINHAS_ORCAMENTO)
@RequestScoped
@Idempotente(opcional = true)
public class LinhasOrcamentoController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(OrcamentoLinha.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
