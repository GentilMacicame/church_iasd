package mz.org.iasd.igreja.controllers.pagamentos;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.pagamentos.MpesaCallbackLog;

/**
 * Tudo o que a API M-Pesa envia, em bruto (callbacks repetidos são ignorados).
 * Tabela {@code pagamentos.mpesa_callback_log} · permissões {@code pagamentos.mpesa_callback_log.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/pagamentos/mpesa-callbacks
 *   POST   /v1/pagamentos/mpesa-callbacks
 *   GET    /v1/pagamentos/mpesa-callbacks/{id}
 *   PATCH  /v1/pagamentos/mpesa-callbacks/{id}
 *   POST   /v1/pagamentos/mpesa-callbacks/{id}/terminar
 *   POST   /v1/pagamentos/mpesa-callbacks/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Pagamentos.MPESA_CALLBACKS)
@RequestScoped
@Idempotente(opcional = true)
public class MpesaCallbacksController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(MpesaCallbackLog.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
