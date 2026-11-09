package mz.org.iasd.igreja.crud;

import java.lang.reflect.RecordComponent;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Lê os models anotados ({@link TabelaBd}, {@link ColunaBd}, {@link TipoBd}) e constrói o catálogo que as
 * operações-padrão usam. Assim os {@code record} de {@code models/} são a descrição única de cada tabela:
 * campos, tipos, obrigatórios.
 */
public final class LeitorModelos {

    private LeitorModelos() {
    }

    public static Tabela tabela(Class<? extends Record> modelo) {
        TabelaBd t = modelo.getAnnotation(TabelaBd.class);
        if (t == null) {
            throw new IllegalStateException(modelo.getName() + " não tem @TabelaBd");
        }
        List<Coluna> colunas = new ArrayList<>();
        for (RecordComponent rc : modelo.getRecordComponents()) {
            ColunaBd c = rc.getAnnotation(ColunaBd.class);
            if (c == null) {
                throw new IllegalStateException(modelo.getName() + "." + rc.getName() + " não tem @ColunaBd");
            }
            String tipoEnum = null;
            if (c.tipo() == Tipo.ENUM) {
                TipoBd tb = rc.getType().getAnnotation(TipoBd.class);
                if (tb == null) {
                    throw new IllegalStateException(modelo.getName() + "." + rc.getName() + ": o tipo não tem @TipoBd");
                }
                tipoEnum = tb.value();
            }
            colunas.add(new Coluna(c.value(), rc.getName(), c.tipo(), tipoEnum, c.escrita(), c.obrigatoria(), c.naoNula()));
        }
        return new Tabela(t.modulo(), t.recurso(), t.schema(), t.nome(), t.prefixo(), t.soLeitura(),
                t.colunaIgreja().isEmpty() ? null : t.colunaIgreja(), List.copyOf(colunas));
    }

    /** Nome do tipo na base → valores, pela ordem do {@code enum}. */
    public static Map<String, List<String>> enums(List<Class<? extends Enum<?>>> tipos) {
        Map<String, List<String>> r = new LinkedHashMap<>();
        for (Class<? extends Enum<?>> e : tipos) {
            TipoBd tb = e.getAnnotation(TipoBd.class);
            if (tb == null) {
                throw new IllegalStateException(e.getName() + " não tem @TipoBd");
            }
            r.put(tb.value(), Arrays.stream(e.getEnumConstants()).map(Enum::name).toList());
        }
        return Map.copyOf(r);
    }
}
