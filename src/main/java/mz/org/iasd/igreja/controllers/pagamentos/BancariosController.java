package mz.org.iasd.igreja.controllers.pagamentos;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.pagamentos.PagamentoBancario;

/**
 * Detalhe de pagamentos por banco.
 * Tabela {@code pagamentos.pagamento_bancario} · permissões {@code pagamentos.pagamento_bancario.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/pagamentos/bancarios
 *   POST   /v1/pagamentos/bancarios
 *   GET    /v1/pagamentos/bancarios/{id}
 *   PATCH  /v1/pagamentos/bancarios/{id}
 *   POST   /v1/pagamentos/bancarios/{id}/terminar
 *   POST   /v1/pagamentos/bancarios/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Pagamentos.BANCARIOS)
@RequestScoped
@Idempotente(opcional = true)
public class BancariosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(PagamentoBancario.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
