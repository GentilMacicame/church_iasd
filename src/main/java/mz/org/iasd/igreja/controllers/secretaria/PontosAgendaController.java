package mz.org.iasd.igreja.controllers.secretaria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.secretaria.ReuniaoPonto;

/**
 * F-SEC-08 Pontos da agenda de uma reunião: assunto, discussão, votação e deliberação. Acta aprovada fica fechada
 * (trigger {@code fn_reuniao_acta_aberta}); votos só num ponto submetido a votação ({@code chk_rpt_votacao}).
 * Tabela {@code secretaria.reuniao_ponto} · permissões {@code secretaria.reuniao_ponto.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/secretaria/pontos-agenda
 *   POST   /v1/secretaria/pontos-agenda
 *   GET    /v1/secretaria/pontos-agenda/{id}
 *   PATCH  /v1/secretaria/pontos-agenda/{id}
 *   POST   /v1/secretaria/pontos-agenda/{id}/terminar
 *   POST   /v1/secretaria/pontos-agenda/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Secretaria.PONTOS_AGENDA)
@RequestScoped
public class PontosAgendaController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(ReuniaoPonto.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
