package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.CalendarioOferta;

/**
 * Calendário de ofertas especiais definido pela Divisão/União/Associação.
 * Tabela {@code tesouraria.calendario_oferta} · permissões {@code tesouraria.calendario_oferta.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/calendario-ofertas
 *   POST   /v1/tesouraria/calendario-ofertas
 *   GET    /v1/tesouraria/calendario-ofertas/{id}
 *   PATCH  /v1/tesouraria/calendario-ofertas/{id}
 *   POST   /v1/tesouraria/calendario-ofertas/{id}/terminar
 *   POST   /v1/tesouraria/calendario-ofertas/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.CALENDARIO_OFERTAS)
@RequestScoped
@Idempotente(opcional = true)
public class CalendarioOfertasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(CalendarioOferta.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
