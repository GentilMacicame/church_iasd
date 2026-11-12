package mz.org.iasd.igreja.controllers.secretaria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.secretaria.Mandato;

/**
 * Mandatos da igreja (V31): o período (com a duração) em que servem os oficiais eleitos; dentro de cada mandato os
 * oficiais estão no conselho da igreja ou na direcção ({@code oficial.ofi_orgao}).
 * Tabela {@code secretaria.mandato} · permissões {@code secretaria.mandato.ler|criar|alterar|terminar}.
 * As regras (mandatos da mesma igreja não se sobrepõem; os oficiais seguem as datas do mandato) estão nos triggers.
 *
 * <pre>
 *   GET    /v1/secretaria/mandatos?igrejaId=
 *   POST   /v1/secretaria/mandatos
 *   GET    /v1/secretaria/mandatos/{id}
 *   PATCH  /v1/secretaria/mandatos/{id}
 *   POST   /v1/secretaria/mandatos/{id}/terminar
 *   POST   /v1/secretaria/mandatos/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Secretaria.MANDATOS)
@RequestScoped
public class MandatosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Mandato.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
