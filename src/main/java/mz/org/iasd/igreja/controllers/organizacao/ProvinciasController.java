package mz.org.iasd.igreja.controllers.organizacao;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.organizacao.Provincia;

/**
 * Províncias de Moçambique (e a Cidade de Maputo). Comum a todas as igrejas: só a Associação/Missão altera (V23, V26).
 * Tabela {@code organizacao.provincia} · permissões {@code organizacao.provincia.criar|alterar|terminar (ler: qualquer utilizador)}.
 *
 * <pre>
 *   GET    /v1/organizacao/provincias
 *   POST   /v1/organizacao/provincias
 *   GET    /v1/organizacao/provincias/{id}
 *   PATCH  /v1/organizacao/provincias/{id}
 *   POST   /v1/organizacao/provincias/{id}/terminar
 *   POST   /v1/organizacao/provincias/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Organizacao.PROVINCIAS)
@RequestScoped
public class ProvinciasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Provincia.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
