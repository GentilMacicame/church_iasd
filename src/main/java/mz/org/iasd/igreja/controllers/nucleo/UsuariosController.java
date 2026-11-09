package mz.org.iasd.igreja.controllers.nucleo;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import jakarta.enterprise.context.RequestScoped;
import jakarta.json.JsonObject;
import jakarta.ws.rs.Path;

import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.controllers.base.BaseTabelaController;
import mz.org.iasd.igreja.repositories.base.TabelaRepository;
import mz.org.iasd.igreja.repositories.base.TabelaRepository.Valor;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.infraestrutura.seguranca.Segredos;
import mz.org.iasd.igreja.infraestrutura.seguranca.Senhas;
import mz.org.iasd.igreja.Rotas;
import mz.org.iasd.igreja.models.nucleo.Usuario;

/**
 * F-NUC-03 Gestão de utilizadores (processo P-13). A senha nunca é exposta nem recebida aqui: o
 * utilizador é criado com uma senha aleatória que ninguém conhece e define a sua em
 * {@code POST /v1/auth/recuperar} + {@code /v1/auth/redefinir}.
 * Só um super-administrador cria outro; só se gerem utilizadores das igrejas que se administram (triggers).
 *
 * <pre>
 *   GET    /v1/nucleo/usuarios
 *   POST   /v1/nucleo/usuarios
 *   GET    /v1/nucleo/usuarios/{id}
 *   PATCH  /v1/nucleo/usuarios/{id}
 *   POST   /v1/nucleo/usuarios/{id}/terminar
 *   POST   /v1/nucleo/usuarios/{id}/reactivar
 * </pre>
 */
@Path(Rotas.Nucleo.USUARIOS)
@RequestScoped
public class UsuariosController extends BaseTabelaController {

    private static final Tabela TABELA = Catalogo.de(Usuario.class);

    @Override
    protected Tabela tabela() {
        return TABELA;
    }

    @Override
    protected JsonObject criarRegisto(JsonObject corpo) throws SQLException {
        List<Valor> valores = new ArrayList<>(TabelaRepository.valoresDoCorpo(TABELA, corpo, Set.of()));
        valores.add(new Valor("usu_senha_hash", Senhas.gerarHash(Segredos.tokenAleatorio()), "text"));
        return TabelaRepository.criar(ligacao(), TABELA, valores);
    }
}
