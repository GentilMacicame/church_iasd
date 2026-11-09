package mz.org.iasd.igreja.controllers.nucleo;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseLeituraController;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.nucleo.LogAuditoria;

/**
 * Histórico de alterações (só os campos que mudaram); particionado por mês. Escrita só pelo sistema (triggers): apenas leitura.
 * Tabela {@code nucleo.log_auditoria} · permissões {@code nucleo.log_auditoria.ler|criar|alterar|terminar}.
 *
 * <pre>
 *   GET    /v1/nucleo/auditoria
 *   GET    /v1/nucleo/auditoria/{id}
 * </pre>
 */
@Path(Rotas.Nucleo.AUDITORIA)
@RequestScoped
public class AuditoriaController extends BaseLeituraController {

    private static final Tabela TABELA = Catalogo.de(LogAuditoria.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }
}
