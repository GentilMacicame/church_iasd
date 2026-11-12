package mz.org.iasd.igreja.infraestrutura.erros;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Frases em português das restrições da base de dados (V29: {@code COMMENT ON CONSTRAINT / INDEX}, lidas por
 * {@code nucleo.fn_mensagens_restricoes()}). Com elas, "Valor não permitido (chk_ers_numeros)" passa a ser a
 * explicação escrita na própria base. Formato do comentário: {@code "[campoJson] Mensagem"} (campo opcional).
 * Sem frase para uma restrição, o tradutor usa a mensagem genérica.
 */
public final class MensagensRestricoes {

    public record Mensagem(String texto, String campo) {
    }

    private static final Pattern COM_CAMPO = Pattern.compile("^\\[(\\w+)]\\s*(.+)$", Pattern.DOTALL);
    /** CHECK padrão de todas as tabelas: {@code <pfx>_end_date >= <pfx>_criado_em}. */
    private static final Pattern END_DATE = Pattern.compile("^chk_[a-z]{3}_end_date$");
    private static final Mensagem FIM_ANTES_DA_CRIACAO =
            new Mensagem("A data de fim não pode ser anterior à criação do registo.", null);

    private static volatile Map<String, Mensagem> frases = Map.of();
    private static volatile long carregadoEm = 0;

    private MensagensRestricoes() {
    }

    /** Substitui as frases (nome da restrição → comentário). */
    public static void definir(Map<String, String> comentarios) {
        Map<String, Mensagem> m = new ConcurrentHashMap<>();
        comentarios.forEach((nome, comentario) -> {
            Mensagem x = interpretar(comentario);
            if (nome != null && x != null) {
                m.put(nome, x);
            }
        });
        frases = Map.copyOf(m);
        carregadoEm = System.currentTimeMillis();
    }

    /** Há quanto tempo (ms) se leram as frases; {@code Long.MAX_VALUE} se nunca. */
    public static long idade() {
        return carregadoEm == 0 ? Long.MAX_VALUE : System.currentTimeMillis() - carregadoEm;
    }

    public static Mensagem de(String restricao) {
        if (restricao == null) {
            return null;
        }
        Mensagem m = frases.get(restricao);
        if (m == null && END_DATE.matcher(restricao).matches()) {
            return FIM_ANTES_DA_CRIACAO;
        }
        return m;
    }

    static Mensagem interpretar(String comentario) {
        if (comentario == null || comentario.isBlank()) {
            return null;
        }
        String c = comentario.strip();
        Matcher m = COM_CAMPO.matcher(c);
        return m.matches() ? new Mensagem(m.group(2).strip(), m.group(1)) : new Mensagem(c, null);
    }
}
