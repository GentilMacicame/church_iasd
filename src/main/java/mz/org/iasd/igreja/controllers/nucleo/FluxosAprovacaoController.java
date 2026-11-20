package mz.org.iasd.igreja.controllers.nucleo;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.nucleo.FluxoAprovacao;

/**
 * V54 Fluxos de aprovação: que etapas segue cada natureza de processo (despesa, saída, contagem, orçamento, admissão e
 * remoção de membros), a partir de que valor. Tabela {@code nucleo.fluxo_aprovacao} · permissões
 * {@code nucleo.fluxo_aprovacao.*}. Os fluxos de uma igreja configuram-se com a permissão nela; os modelos comuns
 * ({@code igrejaId} vazio) só na Associação. Todos os lêem. Rotas-padrão.
 */
@Path(Rotas.Nucleo.FLUXOS_APROVACAO)
@RequestScoped
public class FluxosAprovacaoController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(FluxoAprovacao.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
