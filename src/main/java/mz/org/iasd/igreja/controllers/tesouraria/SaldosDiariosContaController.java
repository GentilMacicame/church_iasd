package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseLeituraController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.SaldoDiarioConta;

/**
 * Saldo pré-calculado por conta e dia (mantido por triggers; não editar). Escrita só pelo sistema (triggers): apenas leitura.
 * Tabela {@code tesouraria.saldo_diario_conta} · permissões {@code tesouraria.saldo_diario_conta.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/saldos-diarios-conta
 *   GET    /v1/tesouraria/saldos-diarios-conta/{id}
 * </pre>
 */
@Path(Rotas.Tesouraria.SALDOS_DIARIOS_CONTA)
@RequestScoped
public class SaldosDiariosContaController extends BaseLeituraController {

    private static final Tabela TABELA = Catalogo.de(SaldoDiarioConta.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
