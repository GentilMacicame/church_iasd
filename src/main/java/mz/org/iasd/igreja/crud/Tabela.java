package mz.org.iasd.igreja.crud;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Uma tabela exposta como recurso REST ({@code /v1/<modulo>/<recurso>}).
 *
 * @param soLeitura  escrita só pelo sistema (saldos, auditoria): sem POST/PATCH/terminar
 * @param colIgreja  coluna de igreja directa; nas listagens o filtro {@code igrejaId} é obrigatório
 */
public record Tabela(String modulo, String recurso, String schema, String nome, String prefixo, boolean soLeitura,
                     String colIgreja, List<Coluna> colunas) {

    public String nomeCompleto() {
        return schema + "." + nome;
    }

    public Coluna pk() {
        return colunas.get(0);
    }

    public String colEndDate() {
        return prefixo + "_end_date";
    }

    public Map<String, Coluna> porCampo() {
        return colunas.stream().collect(Collectors.toMap(Coluna::campo, c -> c, (a, b) -> a, LinkedHashMap::new));
    }

    public Optional<Coluna> coluna(String nomeColuna) {
        return colunas.stream().filter(c -> c.coluna().equals(nomeColuna)).findFirst();
    }

    public String listaSelect() {
        return colunas.stream().map(Coluna::expressaoLeitura).collect(Collectors.joining(", "));
    }

    /** Coluna usada nos filtros {@code desde}/{@code ate} (como no gerador do contrato). */
    public Optional<Coluna> colunaData() {
        for (String sufixo : List.of("data", "data_hora", "data_inicio")) {
            Optional<Coluna> c = coluna(prefixo + "_" + sufixo);
            if (c.isPresent()) {
                return c;
            }
        }
        return Optional.empty();
    }

    /**
     * Filtros de igualdade aceites na listagem, pelo nome do parâmetro: chaves estrangeiras e enumerados
     * (como no contrato). A coluna de igreja directa é o parâmetro {@code igrejaId}.
     */
    public Map<String, Coluna> filtrosIgualdade() {
        Map<String, Coluna> r = new LinkedHashMap<>();
        for (Coluna c : colunas.subList(1, colunas.size())) {
            if (c.coluna().equals(colIgreja)) {
                r.put("igrejaId", c);
            } else if (c.chaveEstrangeira() && !c.coluna().endsWith("_criado_por") && !c.coluna().endsWith("_modificado_por")) {
                r.put(c.campo(), c);
            } else if (c.tipo() == Tipo.ENUM) {
                r.put(c.campo(), c);
            }
        }
        return r;
    }
}
