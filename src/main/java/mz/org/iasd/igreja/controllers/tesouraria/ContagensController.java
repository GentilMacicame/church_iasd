package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.ContagemNumerario;

/**
 * Contagem do dinheiro de um culto (tesoureiro e diácono: dois contadores).
 * Tabela {@code tesouraria.contagem_numerario} · permissões {@code tesouraria.contagem_numerario.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/contagens
 *   POST   /v1/tesouraria/contagens
 *   GET    /v1/tesouraria/contagens/{id}
 *   PATCH  /v1/tesouraria/contagens/{id}
 *   POST   /v1/tesouraria/contagens/{id}/terminar
 *   POST   /v1/tesouraria/contagens/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.CONTAGENS)
@RequestScoped
@Idempotente(opcional = true)
public class ContagensController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(ContagemNumerario.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
