package mz.org.iasd.igreja.controllers.secretaria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.secretaria.Consentimento;

/**
 * Consentimentos para tratamento de dados (menores: dado pelo encarregado).
 * Tabela {@code secretaria.consentimento} · permissões {@code secretaria.consentimento.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/secretaria/consentimentos
 *   POST   /v1/secretaria/consentimentos
 *   GET    /v1/secretaria/consentimentos/{id}
 *   PATCH  /v1/secretaria/consentimentos/{id}
 *   POST   /v1/secretaria/consentimentos/{id}/terminar
 *   POST   /v1/secretaria/consentimentos/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Secretaria.CONSENTIMENTOS)
@RequestScoped
public class ConsentimentosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Consentimento.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
