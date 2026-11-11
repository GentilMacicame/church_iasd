package mz.org.iasd.igreja.controllers.secretaria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.secretaria.ReuniaoPresenca;

/**
 * F-SEC-07 Presenças nas reuniões: quem esteve e quem faltou (com a justificação). Acta aprovada fica fechada
 * (trigger {@code fn_reuniao_acta_aberta}).
 * Tabela {@code secretaria.reuniao_presenca} · permissões {@code secretaria.reuniao_presenca.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/secretaria/presencas-reuniao
 *   POST   /v1/secretaria/presencas-reuniao
 *   GET    /v1/secretaria/presencas-reuniao/{id}
 *   PATCH  /v1/secretaria/presencas-reuniao/{id}
 *   POST   /v1/secretaria/presencas-reuniao/{id}/terminar
 *   POST   /v1/secretaria/presencas-reuniao/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Secretaria.PRESENCAS_REUNIAO)
@RequestScoped
public class PresencasReuniaoController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(ReuniaoPresenca.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
