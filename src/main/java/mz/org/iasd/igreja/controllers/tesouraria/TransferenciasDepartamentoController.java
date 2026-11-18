package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.tesouraria.TransferenciaDepartamento;

/**
 * V50 Saldo passado de um departamento para outro. Tabela {@code tesouraria.transferencia_departamento} · permissões {@code tesouraria.transferencia_departamento.*}. Rotas-padrão.
 */
@Path(Rotas.Tesouraria.TRANSFERENCIAS_DEPARTAMENTO)
@RequestScoped
public class TransferenciasDepartamentoController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(TransferenciaDepartamento.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
