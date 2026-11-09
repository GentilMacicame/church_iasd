package mz.org.iasd.igreja.infraestrutura.bd;

import java.sql.Connection;

import jakarta.enterprise.context.RequestScoped;

/**
 * Ligação à base de dados do pedido em curso, já dentro da transacção e com o utilizador
 * identificado ({@code app.usuario_id}). É aberta e fechada por {@link TransaccionalInterceptor};
 * os recursos limitam-se a pedi-la com {@link #ligacao()}.
 */
@RequestScoped
public class UnidadeDeTrabalho {

    private Connection ligacao;

    public Connection ligacao() {
        if (ligacao == null) {
            throw new IllegalStateException(
                    "Sem transacção aberta: anote o recurso com @Transaccional (nunca abrir ligações à mão)");
        }
        return ligacao;
    }

    void definir(Connection ligacao) {
        this.ligacao = ligacao;
    }

    void limpar() {
        this.ligacao = null;
    }
}
