package mz.org.iasd.igreja.models.catalogo;

import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Procura das tabelas pelo caminho do recurso. */
public final class Catalogo {

    private static final Map<String, Tabela> POR_CAMINHO = CatalogoGerado.TABELAS.stream()
            .collect(Collectors.toMap(t -> chave(t.modulo(), t.recurso()), Function.identity()));

    private static final Map<String, Tabela> POR_NOME = CatalogoGerado.TABELAS.stream()
            .collect(Collectors.toMap(Tabela::nome, Function.identity()));

    private Catalogo() {
    }

    public static Optional<Tabela> tabela(String modulo, String recurso) {
        return Optional.ofNullable(POR_CAMINHO.get(chave(modulo, recurso)));
    }

    /** Pelo model (ex.: {@code Catalogo.de(Membro.class)}). */
    public static Tabela de(Class<? extends Record> modelo) {
        TabelaBd t = modelo.getAnnotation(TabelaBd.class);
        if (t == null) {
            throw new IllegalArgumentException(modelo.getName() + " não tem @TabelaBd");
        }
        return porNome(t.nome());
    }

    /** Pelo nome da tabela na base de dados (ex.: {@code transacao}). */
    public static Tabela porNome(String nome) {
        Tabela t = POR_NOME.get(nome);
        if (t == null) {
            throw new IllegalArgumentException("Tabela desconhecida no catálogo: " + nome);
        }
        return t;
    }

    private static String chave(String modulo, String recurso) {
        return modulo + "/" + recurso;
    }
}
