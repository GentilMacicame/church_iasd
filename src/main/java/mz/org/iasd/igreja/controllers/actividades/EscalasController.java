package mz.org.iasd.igreja.controllers.actividades;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.actividades.Escala;

/**
 * F-ACT-03 Escalas de serviço: quem faz o quê em cada data (pregador, tradutor, acompanhantes, diáconos, ...).
 * Numa escala elaborada por plano ({@link PlanosEscalaController}) cada linha tem {@code escalaDiaId}: a data e a
 * igreja vêm do dia (a base preenche-as). Quem substitui ({@code substitutoMembroId}) recebe o lembrete por SMS
 * à quarta e à sexta ({@code actividades.fn_lembretes_escala}).
 * Tabela {@code actividades.escala} · permissões {@code actividades.escala.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/actividades/escalas
 *   POST   /v1/actividades/escalas
 *   GET    /v1/actividades/escalas/{id}
 *   PATCH  /v1/actividades/escalas/{id}
 *   POST   /v1/actividades/escalas/{id}/terminar
 *   POST   /v1/actividades/escalas/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Actividades.ESCALAS)
@RequestScoped
public class EscalasController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Escala.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
