package mz.org.iasd.igreja.controllers.organizacao;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.organizacao.DistritoAdministrativo;

/**
 * Distritos administrativos de cada província (e distritos municipais da Cidade de Maputo). Comum a todas as igrejas: só a Associação/Missão altera (V23, V26).
 * Tabela {@code organizacao.distrito_administrativo} · permissões {@code organizacao.distrito_administrativo.criar|alterar|terminar (ler: qualquer utilizador)}.
 *
 * <pre>
 *   GET    /v1/organizacao/distritos-administrativos
 *   POST   /v1/organizacao/distritos-administrativos
 *   GET    /v1/organizacao/distritos-administrativos/{id}
 *   PATCH  /v1/organizacao/distritos-administrativos/{id}
 *   POST   /v1/organizacao/distritos-administrativos/{id}/terminar
 *   POST   /v1/organizacao/distritos-administrativos/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Organizacao.DISTRITOS_ADMINISTRATIVOS)
@RequestScoped
public class DistritosAdministrativosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(DistritoAdministrativo.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
