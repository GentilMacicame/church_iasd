package mz.org.iasd.igreja.controllers.eu;

import java.sql.SQLException;

import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

import mz.org.iasd.igreja.infraestrutura.bd.Transaccional;
import mz.org.iasd.igreja.infraestrutura.bd.UnidadeDeTrabalho;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.repositories.eu.EuRepository;

/**
 * F-NUC-05 As minhas permissões. O frontend usa {@code permissoes[igrejaId]} para mostrar menus e
 * botões ({@code pode('tesouraria.transacao.aprovar', igrejaId)}). Esconder botões é UX, não segurança.
 */
@Path(Rotas.Eu.EU)
@RequestScoped
@Transaccional
@Produces(MediaType.APPLICATION_JSON)
public class EuController {

    @Inject
    UnidadeDeTrabalho unidade;

    @GET
    public EuRepository.Eu eu() throws SQLException {
        return EuRepository.carregar(unidade.ligacao())
                .orElseThrow(() -> ApiException.naoAutenticado("Utilizador inactivo. Entre de novo."));
    }
}
