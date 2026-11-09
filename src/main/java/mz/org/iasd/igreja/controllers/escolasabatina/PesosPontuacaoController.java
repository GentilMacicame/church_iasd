package mz.org.iasd.igreja.controllers.escolasabatina;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.escolasabatina.PontuacaoConfig;

/**
 * Pesos da pontuação (sem trimestre = pesos por defeito).
 * Tabela {@code escola_sabatina.pontuacao_config} · permissões {@code escola_sabatina.pontuacao_config.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/escola-sabatina/pesos-pontuacao
 *   POST   /v1/escola-sabatina/pesos-pontuacao
 *   GET    /v1/escola-sabatina/pesos-pontuacao/{id}
 *   PATCH  /v1/escola-sabatina/pesos-pontuacao/{id}
 *   POST   /v1/escola-sabatina/pesos-pontuacao/{id}/terminar
 *   POST   /v1/escola-sabatina/pesos-pontuacao/{id}/reactivar
 * </pre>
 */
@Path(Rotas.EscolaSabatina.PESOS_PONTUACAO)
@RequestScoped
public class PesosPontuacaoController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(PontuacaoConfig.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
