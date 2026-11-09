package mz.org.iasd.igreja.controllers.comunicacao;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.comunicacao.Notificacao;

/**
 * Fila de SMS, WhatsApp e e-mail a enviar.
 * Tabela {@code comunicacao.notificacao} · permissões {@code comunicacao.notificacao.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/comunicacao/notificacoes
 *   POST   /v1/comunicacao/notificacoes
 *   GET    /v1/comunicacao/notificacoes/{id}
 *   PATCH  /v1/comunicacao/notificacoes/{id}
 *   POST   /v1/comunicacao/notificacoes/{id}/terminar
 *   POST   /v1/comunicacao/notificacoes/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Comunicacao.NOTIFICACOES)
@RequestScoped
public class NotificacoesController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Notificacao.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
