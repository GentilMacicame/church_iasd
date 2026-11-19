package mz.org.iasd.igreja.controllers.secretaria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.secretaria.VotoMembro;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;

/**
 * V53 As pessoas a que o voto se refere: o livro de membros só aceita o voto da própria pessoa. Tabela
 * {@code secretaria.voto_membro} · permissões {@code secretaria.voto_membro.*}. Rotas-padrão.
 */
@Path(Rotas.Secretaria.PESSOAS_VOTO)
@RequestScoped
public class PessoasVotoController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(VotoMembro.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
