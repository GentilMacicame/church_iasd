package mz.org.iasd.igreja.comum;

import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Conversão coluna da base de dados ⇄ campo JSON, igual à do gerador do contrato
 * ({@code database/gerador/gen_openapi.py}, função {@code campo}).
 *
 * <pre>
 *   mem_data_nascimento   → dataNascimento
 *   mem_igr_id            → igrejaId
 *   ect_professor_mem_id  → professorMembroId
 *   act_ide_id            → departamentoIgrejaId
 * </pre>
 */
public final class Nomes {

    /** Prefixo de 3 letras → nome da tabela (de {@code defs.py}). */
    public static final Map<String, String> TABELA_POR_PREFIXO = Map.ofEntries(
            Map.entry("per", "perfil"), Map.entry("prm", "permissao"), Map.entry("ppe", "perfil_permissao"),
            Map.entry("usu", "usuario"), Map.entry("uig", "usuario_igreja"), Map.entry("uen", "usuario_entidade"),
            Map.entry("lau", "log_auditoria"), Map.entry("ent", "entidade"), Map.entry("dst", "distrito"),
            Map.entry("igr", "igreja"), Map.entry("dep", "departamento"), Map.entry("ide", "igreja_departamento"),
            Map.entry("car", "cargo"), Map.entry("fam", "familia"), Map.entry("mem", "membro"),
            Map.entry("cto", "contacto"), Map.entry("cns", "consentimento"), Map.entry("reu", "reuniao"),
            Map.entry("vot", "voto"), Map.entry("mmb", "movimento_membro"), Map.entry("tme", "transferencia_membro"),
            Map.entry("dsc", "disciplina"), Map.entry("ofi", "oficial"), Map.entry("bap", "baptismo"),
            Map.entry("act", "actividade"), Map.entry("mat", "material"), Map.entry("esc", "escala"),
            Map.entry("etr", "trimestre"), Map.entry("esa", "sabado"), Map.entry("ecl", "classe"),
            Map.entry("ect", "classe_trimestre"), Map.entry("ema", "matricula"), Map.entry("ers", "relatorio_sabado"),
            Map.entry("epr", "presenca"), Map.entry("evi", "visitante"), Map.entry("epc", "pontuacao_config"),
            Map.entry("cfi", "conta_financeira"), Map.entry("fun", "fundo"), Map.entry("cof", "calendario_oferta"),
            Map.entry("cat", "categoria"), Map.entry("alv", "alvo"), Map.entry("orc", "orcamento"),
            Map.entry("orl", "orcamento_linha"), Map.entry("des", "despesa"), Map.entry("cnu", "contagem_numerario"),
            Map.entry("tra", "transacao"), Map.entry("tli", "transacao_linha"), Map.entry("sdc", "saldo_diario_conta"),
            Map.entry("sdf", "saldo_diario_fundo"), Map.entry("rec", "recibo"), Map.entry("doc", "documento"),
            Map.entry("rem", "remessa"), Map.entry("rml", "remessa_linha"), Map.entry("fpe", "fecho_periodo"),
            Map.entry("ext", "extrato_linha"), Map.entry("pmp", "pagamento_mpesa"), Map.entry("mcl", "mpesa_callback_log"),
            Map.entry("pba", "pagamento_bancario"), Map.entry("ntf", "notificacao"),
            // tabelas do sistema (V14)
            Map.entry("ses", "sessao"), Map.entry("rsn", "recuperacao_senha"), Map.entry("blq", "bloqueio_login"),
            Map.entry("pid", "pedido_idempotente"));

    /** Nomes curtos de entidades (ALIAS do gerador). */
    private static final Map<String, String> ALIAS = Map.of(
            "contagem_numerario", "contagem", "conta_financeira", "conta", "relatorio_sabado", "relatorio",
            "transferencia_membro", "transferencia", "movimento_membro", "movimento",
            "igreja_departamento", "departamentoIgreja", "pagamento_mpesa", "pagamentoMpesa",
            "log_auditoria", "log", "pontuacao_config", "pesosPontuacao");

    private static final Pattern CHAVE_ESTRANGEIRA = Pattern.compile("^(?:(.*)_)?([a-z]{3})_id$");

    private Nomes() {
    }

    /** Coluna completa, com o prefixo da tabela (ex.: {@code mem_igr_id}) → campo JSON. */
    public static String campo(String coluna) {
        if (coluna == null || coluna.isBlank()) {
            return null;
        }
        return campoSemPrefixo(semPrefixo(coluna));
    }

    /** Coluna sem o prefixo da tabela (ex.: {@code igr_id}) → campo JSON. */
    public static String campoSemPrefixo(String coluna) {
        Matcher m = CHAVE_ESTRANGEIRA.matcher(coluna);
        if (m.matches() && TABELA_POR_PREFIXO.containsKey(m.group(2))) {
            String papel = m.group(1);
            String entidade = nomeEntidade(TABELA_POR_PREFIXO.get(m.group(2)));
            return papel == null
                    ? entidade + "Id"
                    : camel(papel) + maiuscula(entidade) + "Id";
        }
        return camel(coluna);
    }

    /** Retira o prefixo de 3 letras se for um prefixo conhecido. */
    public static String semPrefixo(String coluna) {
        if (coluna.length() > 4 && coluna.charAt(3) == '_' && TABELA_POR_PREFIXO.containsKey(coluna.substring(0, 3))) {
            return coluna.substring(4);
        }
        return coluna;
    }

    static String nomeEntidade(String tabela) {
        return ALIAS.getOrDefault(tabela, camel(tabela));
    }

    static String camel(String s) {
        String[] partes = s.split("_");
        StringBuilder sb = new StringBuilder(partes[0]);
        for (int i = 1; i < partes.length; i++) {
            sb.append(maiuscula(partes[i]));
        }
        return sb.toString();
    }

    private static String maiuscula(String s) {
        return s.isEmpty() ? s : Character.toUpperCase(s.charAt(0)) + s.substring(1);
    }
}
