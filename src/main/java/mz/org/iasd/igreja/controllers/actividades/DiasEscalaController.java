package mz.org.iasd.igreja.controllers.actividades;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.actividades.EscalaDia;

/**
 * F-ACT-03 Dias (cultos) de uma escala: grupo coral, departamento responsável ou um evento especial que
 * substitui a escala nesse dia (ex.: Simpósio, 13.º sábado — sem lembretes). A data tem de estar no período
 * da escala; mudar a data muda também a das pessoas escaladas nesse dia.
 * Tabela {@code actividades.escala_dia} · permissões {@code actividades.escala_dia.*}.
 *
 * <pre>
 *   GET    /v1/actividades/dias-escala?escalaPlanoId=
 *   POST   /v1/actividades/dias-escala
 *   GET    /v1/actividades/dias-escala/{id}
 *   PATCH  /v1/actividades/dias-escala/{id}
 *   POST   /v1/actividades/dias-escala/{id}/terminar
 *   POST   /v1/actividades/dias-escala/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Actividades.DIAS_ESCALA)
@RequestScoped
public class DiasEscalaController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(EscalaDia.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
