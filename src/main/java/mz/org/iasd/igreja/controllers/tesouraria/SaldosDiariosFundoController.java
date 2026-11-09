package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseLeituraController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.SaldoDiarioFundo;

/**
 * Totais pré-calculados por igreja, fundo, moeda e dia (mantido por triggers; não editar). Escrita só pelo sistema (triggers): apenas leitura.
 * Tabela {@code tesouraria.saldo_diario_fundo} · permissões {@code tesouraria.saldo_diario_fundo.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/saldos-diarios-fundo
 *   GET    /v1/tesouraria/saldos-diarios-fundo/{id}
 * </pre>
 */
@Path(Rotas.Tesouraria.SALDOS_DIARIOS_FUNDO)
@RequestScoped
public class SaldosDiariosFundoController extends BaseLeituraController {

    private static final Tabela TABELA = Catalogo.de(SaldoDiarioFundo.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
