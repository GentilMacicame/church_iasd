package mz.org.iasd.igreja.controllers.secretaria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.secretaria.MovimentoMembro;

/**
 * Livro de membros: cada entrada e saída, com o voto que a autoriza.
 * Tabela {@code secretaria.movimento_membro} · permissões {@code secretaria.movimento_membro.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/secretaria/movimentos-membro
 *   POST   /v1/secretaria/movimentos-membro
 *   GET    /v1/secretaria/movimentos-membro/{id}
 *   PATCH  /v1/secretaria/movimentos-membro/{id}
 *   POST   /v1/secretaria/movimentos-membro/{id}/terminar
 *   POST   /v1/secretaria/movimentos-membro/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Secretaria.MOVIMENTOS_MEMBRO)
@RequestScoped
public class MovimentosMembroController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(MovimentoMembro.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
