package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.Fundo;

/**
 * Fundos: da Associação (dízimo, ofertas missionárias, 13º sábado) ou locais.
 * Tabela {@code tesouraria.fundo} · permissões {@code tesouraria.fundo.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/fundos
 *   POST   /v1/tesouraria/fundos
 *   GET    /v1/tesouraria/fundos/{id}
 *   PATCH  /v1/tesouraria/fundos/{id}
 *   POST   /v1/tesouraria/fundos/{id}/terminar
 *   POST   /v1/tesouraria/fundos/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.FUNDOS)
@RequestScoped
@Idempotente(opcional = true)
public class FundosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Fundo.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
