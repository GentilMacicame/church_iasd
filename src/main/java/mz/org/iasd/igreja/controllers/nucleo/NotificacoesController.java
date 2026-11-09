package mz.org.iasd.igreja.controllers.nucleo;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.nucleo.Notificacao;

/**
 * Fila de SMS, WhatsApp e e-mail a enviar.
 * Tabela {@code nucleo.notificacao} · permissões {@code nucleo.notificacao.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/nucleo/notificacoes
 *   POST   /v1/nucleo/notificacoes
 *   GET    /v1/nucleo/notificacoes/{id}
 *   PATCH  /v1/nucleo/notificacoes/{id}
 *   POST   /v1/nucleo/notificacoes/{id}/terminar
 *   POST   /v1/nucleo/notificacoes/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Nucleo.NOTIFICACOES)
@RequestScoped
public class NotificacoesController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Notificacao.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
