package mz.org.iasd.igreja.controllers.actividades;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.actividades.EscalaColuna;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;

/**
 * F-ACT (V45) Colunas da escala da Escola Sabatina e da JA, como cada igreja as organiza (nome, ordem, membro ou
 * família). Tabela {@code actividades.escala_coluna} · permissões {@code actividades.escala_coluna.*}. Rotas-padrão.
 */
@Path(Rotas.Actividades.COLUNAS_ESCALA)
@RequestScoped
public class ColunasEscalaController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(EscalaColuna.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
