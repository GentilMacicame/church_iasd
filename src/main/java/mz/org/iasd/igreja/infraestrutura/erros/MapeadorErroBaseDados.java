package mz.org.iasd.igreja.infraestrutura.erros;

import java.util.logging.Level;
import java.util.logging.Logger;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

import mz.org.iasd.igreja.infraestrutura.bd.ContextoPedido;

@Provider
@ApplicationScoped
public class MapeadorErroBaseDados implements ExceptionMapper<ErroBaseDados> {

    private static final Logger LOG = Logger.getLogger(MapeadorErroBaseDados.class.getName());

    @Inject
    ContextoPedido contexto;

    @Inject
    CarregadorMensagensRestricoes mensagens;

    @Override
    public Response toResponse(ErroBaseDados e) {
        mensagens.garantir();
        TradutorErrosSql.Traducao t = TradutorErrosSql.traduzir(e.sql());
        if (t.estadoHttp() >= 500) {
            LOG.log(Level.SEVERE, "Erro da base de dados [pedido " + contexto.pedidoId() + "] SQLSTATE "
                    + e.sql().getSQLState(), e.sql());
        } else {
            LOG.log(Level.FINE, "Recusado pela base de dados [pedido {0}] {1}: {2}",
                    new Object[] {contexto.pedidoId(), e.sql().getSQLState(), t.mensagem()});
        }
        return Respostas.erro(t.estadoHttp(), t.codigo(), t.mensagem(), t.campo(), contexto.pedidoId());
    }
}
