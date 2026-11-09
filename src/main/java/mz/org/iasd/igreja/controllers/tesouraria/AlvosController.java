package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.Alvo;

/**
 * Alvos de arrecadação por fundo.
 * Tabela {@code tesouraria.alvo} · permissões {@code tesouraria.alvo.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/alvos
 *   POST   /v1/tesouraria/alvos
 *   GET    /v1/tesouraria/alvos/{id}
 *   PATCH  /v1/tesouraria/alvos/{id}
 *   POST   /v1/tesouraria/alvos/{id}/terminar
 *   POST   /v1/tesouraria/alvos/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.ALVOS)
@RequestScoped
@Idempotente(opcional = true)
public class AlvosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Alvo.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
