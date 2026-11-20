package mz.org.iasd.igreja.controllers.nucleo;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.nucleo.FluxoEtapa;

/**
 * V54 Etapas de cada fluxo de aprovação, pela ordem em que se decidem: quem decide (perfil, permissão ou órgão que vota
 * em reunião) e o que faz. Tabela {@code nucleo.fluxo_etapa} · permissões {@code nucleo.fluxo_etapa.*} (a igreja copia-se
 * do fluxo). Rotas-padrão.
 */
@Path(Rotas.Nucleo.ETAPAS_FLUXO)
@RequestScoped
public class EtapasFluxoController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(FluxoEtapa.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
