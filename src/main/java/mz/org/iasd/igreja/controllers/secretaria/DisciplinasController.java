package mz.org.iasd.igreja.controllers.secretaria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.secretaria.Disciplina;

/**
 * Censuras (1 a 12 meses): sem cargos nem carta de transferência durante a censura.
 * Tabela {@code secretaria.disciplina} · permissões {@code secretaria.disciplina.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/secretaria/disciplinas
 *   POST   /v1/secretaria/disciplinas
 *   GET    /v1/secretaria/disciplinas/{id}
 *   PATCH  /v1/secretaria/disciplinas/{id}
 *   POST   /v1/secretaria/disciplinas/{id}/terminar
 *   POST   /v1/secretaria/disciplinas/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Secretaria.DISCIPLINAS)
@RequestScoped
public class DisciplinasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Disciplina.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
