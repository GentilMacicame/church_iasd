package mz.org.iasd.igreja.controllers.escolasabatina;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.escolasabatina.ClasseTrimestre;

/**
 * Classe num trimestre: professor e alvos (ACTIVO/INACTIVO = Activo/Desactivado da planilha).
 * Tabela {@code escola_sabatina.classe_trimestre} · permissões {@code escola_sabatina.classe_trimestre.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/escola-sabatina/classes-trimestre
 *   POST   /v1/escola-sabatina/classes-trimestre
 *   GET    /v1/escola-sabatina/classes-trimestre/{id}
 *   PATCH  /v1/escola-sabatina/classes-trimestre/{id}
 *   POST   /v1/escola-sabatina/classes-trimestre/{id}/terminar
 *   POST   /v1/escola-sabatina/classes-trimestre/{id}/reactivar
 * </pre>
 */
@Path(Rotas.EscolaSabatina.CLASSES_TRIMESTRE)
@RequestScoped
public class ClassesTrimestreController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(ClasseTrimestre.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
