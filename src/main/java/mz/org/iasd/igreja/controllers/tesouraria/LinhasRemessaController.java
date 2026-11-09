package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.RemessaLinha;

/**
 * Valor remetido por fundo.
 * Tabela {@code tesouraria.remessa_linha} · permissões {@code tesouraria.remessa_linha.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/linhas-remessa
 *   POST   /v1/tesouraria/linhas-remessa
 *   GET    /v1/tesouraria/linhas-remessa/{id}
 *   PATCH  /v1/tesouraria/linhas-remessa/{id}
 *   POST   /v1/tesouraria/linhas-remessa/{id}/terminar
 *   POST   /v1/tesouraria/linhas-remessa/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.LINHAS_REMESSA)
@RequestScoped
@Idempotente(opcional = true)
public class LinhasRemessaController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(RemessaLinha.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
