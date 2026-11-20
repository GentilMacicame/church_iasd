package mz.org.iasd.igreja.controllers.nucleo;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseLeituraController;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.nucleo.AprovacaoDecisao;

/**
 * V54 Decisões de cada etapa de um processo de aprovação (quem, quando, com que voto). Só leitura: escreve-as
 * {@code nucleo.fn_aprovacao_decidir}. Lê-as quem vê o processo.
 */
@Path(Rotas.Nucleo.DECISOES_APROVACAO)
@RequestScoped
public class DecisoesAprovacaoController extends BaseLeituraController {

    private static final Tabela TABELA = Catalogo.de(AprovacaoDecisao.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
