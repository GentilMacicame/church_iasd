package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.PagamentoBancario;

/**
 * Detalhe de pagamentos por banco.
 * Tabela {@code tesouraria.pagamento_bancario} · permissões {@code tesouraria.pagamento_bancario.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/bancarios
 *   POST   /v1/tesouraria/bancarios
 *   GET    /v1/tesouraria/bancarios/{id}
 *   PATCH  /v1/tesouraria/bancarios/{id}
 *   POST   /v1/tesouraria/bancarios/{id}/terminar
 *   POST   /v1/tesouraria/bancarios/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.BANCARIOS)
@RequestScoped
@Idempotente(opcional = true)
public class BancariosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(PagamentoBancario.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
