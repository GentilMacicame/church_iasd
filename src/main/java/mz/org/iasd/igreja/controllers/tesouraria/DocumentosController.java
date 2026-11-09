package mz.org.iasd.igreja.controllers.tesouraria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.infraestrutura.bd.Idempotente;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.tesouraria.Documento;

/**
 * Comprovativos (facturas, talões, prints M-Pesa).
 * Tabela {@code tesouraria.documento} · permissões {@code tesouraria.documento.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/tesouraria/documentos
 *   POST   /v1/tesouraria/documentos
 *   GET    /v1/tesouraria/documentos/{id}
 *   PATCH  /v1/tesouraria/documentos/{id}
 *   POST   /v1/tesouraria/documentos/{id}/terminar
 *   POST   /v1/tesouraria/documentos/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Tesouraria.DOCUMENTOS)
@RequestScoped
@Idempotente(opcional = true)
public class DocumentosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Documento.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
