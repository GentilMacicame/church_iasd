package mz.org.iasd.igreja.infraestrutura.seguranca;

import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;

import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import mz.org.iasd.igreja.config.Configuracao;
import mz.org.iasd.igreja.infraestrutura.erros.ApiException;

/**
 * Limita os cálculos Argon2id em simultâneo (cada um usa 19 MiB e CPU). Muitos logins ao mesmo tempo
 * esperam até 5 segundos; depois disso a resposta é 503 (tentar de novo), em vez de esgotar a memória.
 * Nunca é chamado com uma ligação à base aberta.
 */
@ApplicationScoped
public class ControloSenhas {

    @Inject
    Configuracao configuracao;

    private Semaphore vagas;

    @PostConstruct
    void iniciar() {
        vagas = new Semaphore(configuracao.senhasConcorrencia(), true);
    }

    public <T> T executar(Supplier<T> calculo) {
        boolean entrou = false;
        try {
            entrou = vagas.tryAcquire(5, TimeUnit.SECONDS);
            if (!entrou) {
                throw new ApiException(503, "tentar_novamente", "O sistema está ocupado. Tente de novo dentro de momentos.", null);
            }
            return calculo.get();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ApiException(503, "tentar_novamente", "O sistema está ocupado. Tente de novo dentro de momentos.", null);
        } finally {
            if (entrou) {
                vagas.release();
            }
        }
    }
}
