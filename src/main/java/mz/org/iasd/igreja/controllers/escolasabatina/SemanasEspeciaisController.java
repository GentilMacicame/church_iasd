package mz.org.iasd.igreja.controllers.escolasabatina;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.escolasabatina.SemanaEspecial;

/**
 * F-ES (V47) Programas especiais da semana (semana de oração, da família, de evangelismo…), para os alertas. Tabela {@code escola_sabatina.semana_especial} · permissões {@code escola_sabatina.semana_especial.*}. Rotas-padrão.
 */
@Path(Rotas.EscolaSabatina.SEMANAS_ESPECIAIS)
@RequestScoped
public class SemanasEspeciaisController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(SemanaEspecial.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
