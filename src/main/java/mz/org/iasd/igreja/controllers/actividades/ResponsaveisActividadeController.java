package mz.org.iasd.igreja.controllers.actividades;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.actividades.ActividadeResponsavel;

/**
 * F-ACT (V34) Outros responsáveis de uma actividade, além do principal, e a função de cada um. A base de dados
 * exige que o membro seja da igreja da actividade.
 * Tabela {@code actividades.actividade_responsavel} · permissões {@code actividades.actividade_responsavel.*}.
 *
 * <pre>
 *   GET    /v1/actividades/responsaveis-actividade?actividadeId=
 *   POST   /v1/actividades/responsaveis-actividade
 *   GET    /v1/actividades/responsaveis-actividade/{id}
 *   PATCH  /v1/actividades/responsaveis-actividade/{id}
 *   POST   /v1/actividades/responsaveis-actividade/{id}/terminar
 *   POST   /v1/actividades/responsaveis-actividade/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Actividades.RESPONSAVEIS_ACTIVIDADE)
@RequestScoped
public class ResponsaveisActividadeController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(ActividadeResponsavel.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
