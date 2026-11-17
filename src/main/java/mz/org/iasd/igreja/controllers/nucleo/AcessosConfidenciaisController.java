package mz.org.iasd.igreja.controllers.nucleo;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseLeituraController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.nucleo.AcessoConfidencial;

/**
 * V41 Consultas a dados confidenciais (quem, quando, que registo). Só leitura: escreve-as a base de dados (ex.:
 * secretaria.fn_disciplina_motivo). Lêem-nas o pastor e a administração da Associação.
 */
@Path(Rotas.Nucleo.ACESSOS_CONFIDENCIAIS)
@RequestScoped
public class AcessosConfidenciaisController extends BaseLeituraController {

    private static final Tabela TABELA = Catalogo.de(AcessoConfidencial.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
