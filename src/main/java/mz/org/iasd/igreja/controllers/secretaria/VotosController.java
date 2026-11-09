package mz.org.iasd.igreja.controllers.secretaria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.secretaria.Voto;

/**
 * Votos registados em acta (admissões, transferências, remoções, eleições, finanças).
 * Tabela {@code secretaria.voto} · permissões {@code secretaria.voto.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/secretaria/votos
 *   POST   /v1/secretaria/votos
 *   GET    /v1/secretaria/votos/{id}
 *   PATCH  /v1/secretaria/votos/{id}
 *   POST   /v1/secretaria/votos/{id}/terminar
 *   POST   /v1/secretaria/votos/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Secretaria.VOTOS)
@RequestScoped
public class VotosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Voto.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
