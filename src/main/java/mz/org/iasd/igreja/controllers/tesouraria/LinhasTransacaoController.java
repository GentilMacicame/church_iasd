package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.TransacaoLinha;

/**
 * Divisão do valor por fundo e categoria (soma = valor_total).
 * Tabela {@code tesouraria.transacao_linha} · permissões {@code tesouraria.transacao_linha.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/linhas-transacao
 *   POST   /v1/tesouraria/linhas-transacao
 *   GET    /v1/tesouraria/linhas-transacao/{id}
 *   PATCH  /v1/tesouraria/linhas-transacao/{id}
 *   POST   /v1/tesouraria/linhas-transacao/{id}/terminar
 *   POST   /v1/tesouraria/linhas-transacao/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.LINHAS_TRANSACAO)
@RequestScoped
@Idempotente(opcional = true)
public class LinhasTransacaoController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(TransacaoLinha.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
