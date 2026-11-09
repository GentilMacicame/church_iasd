package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.MpesaCallbackLog;

/**
 * Tudo o que a API M-Pesa envia, em bruto (callbacks repetidos são ignorados).
 * Tabela {@code tesouraria.mpesa_callback_log} · permissões {@code tesouraria.mpesa_callback_log.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/mpesa-callbacks
 *   POST   /v1/tesouraria/mpesa-callbacks
 *   GET    /v1/tesouraria/mpesa-callbacks/{id}
 *   PATCH  /v1/tesouraria/mpesa-callbacks/{id}
 *   POST   /v1/tesouraria/mpesa-callbacks/{id}/terminar
 *   POST   /v1/tesouraria/mpesa-callbacks/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.MPESA_CALLBACKS)
@RequestScoped
@Idempotente(opcional = true)
public class MpesaCallbacksController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(MpesaCallbackLog.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
