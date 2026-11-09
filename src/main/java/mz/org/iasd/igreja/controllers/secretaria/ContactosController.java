package mz.org.iasd.igreja.controllers.secretaria;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.crud.Catalogo;
import mz.org.iasd.igreja.crud.BaseTabelaController;
import mz.org.iasd.igreja.crud.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.secretaria.Contacto;

/**
 * Telefones, e-mails e WhatsApp de membros ou igrejas.
 * Tabela {@code secretaria.contacto} · permissões {@code secretaria.contacto.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/secretaria/contactos
 *   POST   /v1/secretaria/contactos
 *   GET    /v1/secretaria/contactos/{id}
 *   PATCH  /v1/secretaria/contactos/{id}
 *   POST   /v1/secretaria/contactos/{id}/terminar
 *   POST   /v1/secretaria/contactos/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Secretaria.CONTACTOS)
@RequestScoped
public class ContactosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Contacto.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
