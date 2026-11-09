package mz.org.iasd.igreja.controllers.escolasabatina;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.escolasabatina.Matricula;

/**
 * Inscrição nas classes (histórico); membros e não membros.
 * Tabela {@code escola_sabatina.matricula} · permissões {@code escola_sabatina.matricula.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/escola-sabatina/matriculas
 *   POST   /v1/escola-sabatina/matriculas
 *   GET    /v1/escola-sabatina/matriculas/{id}
 *   PATCH  /v1/escola-sabatina/matriculas/{id}
 *   POST   /v1/escola-sabatina/matriculas/{id}/terminar
 *   POST   /v1/escola-sabatina/matriculas/{id}/reactivar
 * </pre>
 */
@Path(Rotas.EscolaSabatina.MATRICULAS)
@RequestScoped
public class MatriculasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Matricula.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
