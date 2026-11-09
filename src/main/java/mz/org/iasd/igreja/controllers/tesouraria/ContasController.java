package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.ContaFinanceira;

/**
 * Contas onde o dinheiro está (M-Pesa, banco, caixa).
 * Tabela {@code tesouraria.conta_financeira} · permissões {@code tesouraria.conta_financeira.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/contas
 *   POST   /v1/tesouraria/contas
 *   GET    /v1/tesouraria/contas/{id}
 *   PATCH  /v1/tesouraria/contas/{id}
 *   POST   /v1/tesouraria/contas/{id}/terminar
 *   POST   /v1/tesouraria/contas/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.CONTAS)
@RequestScoped
@Idempotente(opcional = true)
public class ContasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(ContaFinanceira.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
