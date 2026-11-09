package mz.org.iasd.igreja.controllers.organizacao;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.organizacao.IgrejaDepartamento;

/**
 * Departamento a funcionar numa igreja.
 * Tabela {@code organizacao.igreja_departamento} · permissões {@code organizacao.igreja_departamento.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/organizacao/departamentos-igreja
 *   POST   /v1/organizacao/departamentos-igreja
 *   GET    /v1/organizacao/departamentos-igreja/{id}
 *   PATCH  /v1/organizacao/departamentos-igreja/{id}
 *   POST   /v1/organizacao/departamentos-igreja/{id}/terminar
 *   POST   /v1/organizacao/departamentos-igreja/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Organizacao.DEPARTAMENTOS_IGREJA)
@RequestScoped
public class DepartamentosIgrejaController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(IgrejaDepartamento.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
