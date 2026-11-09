package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.Categoria;

/**
 * Plano de contas: categorias de receita e despesa.
 * Tabela {@code tesouraria.categoria} · permissões {@code tesouraria.categoria.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/categorias
 *   POST   /v1/tesouraria/categorias
 *   GET    /v1/tesouraria/categorias/{id}
 *   PATCH  /v1/tesouraria/categorias/{id}
 *   POST   /v1/tesouraria/categorias/{id}/terminar
 *   POST   /v1/tesouraria/categorias/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.CATEGORIAS)
@RequestScoped
@Idempotente(opcional = true)
public class CategoriasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Categoria.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
