package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.Recibo;

/**
 * Recibos numerados por igreja e ano.
 * Tabela {@code tesouraria.recibo} · permissões {@code tesouraria.recibo.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/recibos
 *   POST   /v1/tesouraria/recibos
 *   GET    /v1/tesouraria/recibos/{id}
 *   PATCH  /v1/tesouraria/recibos/{id}
 *   POST   /v1/tesouraria/recibos/{id}/terminar
 *   POST   /v1/tesouraria/recibos/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.RECIBOS)
@RequestScoped
@Idempotente(opcional = true)
public class RecibosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Recibo.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
