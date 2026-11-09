package mz.org.iasd.igreja.controllers.organizacao;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.organizacao.Departamento;

/**
 * Departamentos e ministérios (Manual da Igreja).
 * Tabela {@code organizacao.departamento} · permissões {@code organizacao.departamento.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/organizacao/departamentos
 *   POST   /v1/organizacao/departamentos
 *   GET    /v1/organizacao/departamentos/{id}
 *   PATCH  /v1/organizacao/departamentos/{id}
 *   POST   /v1/organizacao/departamentos/{id}/terminar
 *   POST   /v1/organizacao/departamentos/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Organizacao.DEPARTAMENTOS)
@RequestScoped
public class DepartamentosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Departamento.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
