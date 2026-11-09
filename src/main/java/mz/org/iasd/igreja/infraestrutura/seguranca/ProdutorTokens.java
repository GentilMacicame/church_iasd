package mz.org.iasd.igreja.infraestrutura.seguranca;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import mz.org.iasd.igreja.config.Configuracao;

@ApplicationScoped
public class ProdutorTokens {

    @Inject
    Configuracao configuracao;

    @Produces
    @Singleton   // sem proxy (Tokens é final); uma instância para toda a aplicação
    Tokens tokens() {
        return new Tokens(configuracao.jwtSegredo(), configuracao.jwtEmissor(), configuracao.acessoMinutos());
    }
}
