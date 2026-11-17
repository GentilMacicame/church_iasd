package mz.org.iasd.igreja.controllers.nucleo;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.nucleo.Comunicado;

/**
 * Comunicados e anúncios (V37): da igreja, do distrito pastoral ou da Associação. Quem publica e quem lê decide a base de dados (nucleo.fn_comunicado_emissor / fn_comunicado_para_mim).
 * Rotas-padrão: listar, ler, criar, alterar, terminar, reactivar.
 */
@Path(Rotas.Nucleo.COMUNICADOS)
@RequestScoped
public class ComunicadosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Comunicado.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
