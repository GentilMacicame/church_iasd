package mz.org.iasd.igreja.infraestrutura.erros;

import java.sql.SQLException;

import org.postgresql.util.PSQLException;
import org.postgresql.util.ServerErrorMessage;

import mz.org.iasd.igreja.comum.Nomes;

/**
 * Traduz um erro do PostgreSQL para a resposta HTTP do contrato (CLAUDE.md, "Erros").
 *
 * <pre>
 *   42501 → 403 sem_permissao        P0001 → 422 regra_negocio
 *   23514 → 422 validacao            23505 → 409 duplicado
 *   23503 → 422 referencia_invalida  23502 → 400 campo_obrigatorio
 *   40001 / 40P01 → 503 tentar_novamente (depois de 3 tentativas)
 * </pre>
 *
 * A mensagem das regras de negócio vem da base de dados, já em português, e passa tal e qual; a das restrições
 * (CHECK e únicos) também, a partir do COMMENT de cada uma (V29, {@link MensagensRestricoes}).
 * Nunca se devolve SQL nem stack traces ao cliente.
 */
public final class TradutorErrosSql {

    public record Traducao(int estadoHttp, String codigo, String mensagem, String campo) {
    }

    private TradutorErrosSql() {
    }

    /** Erros em que vale a pena repetir a transacção inteira. */
    public static boolean repetivel(SQLException e) {
        return "40001".equals(e.getSQLState()) || "40P01".equals(e.getSQLState());
    }

    /** Procura uma SQLException na cadeia de causas. */
    public static SQLException encontrar(Throwable t) {
        for (Throwable x = t; x != null; x = x.getCause()) {
            if (x instanceof SQLException sql) {
                return sql;
            }
            if (x.getCause() == x) {
                break;
            }
        }
        return null;
    }

    public static Traducao traduzir(SQLException e) {
        String estado = e.getSQLState() == null ? "" : e.getSQLState();
        ServerErrorMessage detalhe = e instanceof PSQLException p ? p.getServerErrorMessage() : null;
        String mensagemBd = detalhe != null && detalhe.getMessage() != null ? detalhe.getMessage() : e.getMessage();
        String restricao = detalhe != null ? detalhe.getConstraint() : null;
        String coluna = detalhe != null ? detalhe.getColumn() : null;

        return switch (estado) {
            case "42501" -> new Traducao(403, "sem_permissao", mensagemPermissao(mensagemBd), null);
            case "P0001" -> new Traducao(422, "regra_negocio", mensagemBd, null);
            case "23514" -> comFrase(restricao, new Traducao(422, "validacao",
                    "Valor não permitido" + (restricao != null ? " (" + restricao + ")" : ""), campoDaRestricao(restricao)));
            case "23505" -> comFrase(restricao, new Traducao(409, "duplicado", "Já existe um registo com estes dados",
                    campoDaRestricao(restricao)));
            case "23503" -> new Traducao(422, "referencia_invalida", "O registo indicado não existe", campoDaRestricao(restricao));
            case "23502" -> new Traducao(400, "campo_obrigatorio", "Falta preencher um campo obrigatório", Nomes.campo(coluna));
            case "57014" -> new Traducao(503, "tentar_novamente",
                    "A operação demorou demasiado e foi interrompida. Tente de novo ou reduza o período pedido.", null);
            case "55P03" -> new Traducao(503, "tentar_novamente",
                    "O registo está a ser alterado por outro pedido. Tente de novo.", null);
            case "40001", "40P01" -> new Traducao(503, "tentar_novamente",
                    "O sistema está ocupado com outro pedido igual. Tente de novo.", null);
            case "22P02", "22007", "22008", "22003", "22001" -> new Traducao(400, "pedido_invalido",
                    "Valor com formato inválido ou demasiado grande", Nomes.campo(coluna));
            default -> estado.startsWith("08")
                    ? new Traducao(503, "tentar_novamente", "Base de dados indisponível de momento. Tente de novo.", null)
                    : new Traducao(500, "erro_interno", "Erro interno. Se persistir, contacte o suporte.", null);
        };
    }

    /**
     * Usa a frase da restrição escrita na base de dados (V29, {@link MensagensRestricoes}) quando existe; o campo
     * da frase tem prioridade sobre o deduzido do nome.
     */
    static Traducao comFrase(String restricao, Traducao generica) {
        MensagensRestricoes.Mensagem m = MensagensRestricoes.de(restricao);
        if (m == null) {
            return generica;
        }
        return new Traducao(generica.estadoHttp(), generica.codigo(), m.texto(), m.campo() != null ? m.campo() : generica.campo());
    }

    /** As recusas por RLS e por falta de GRANT vêm em inglês; as de nucleo.fn_exigir já vêm em português. */
    static String mensagemPermissao(String mensagemBd) {
        if (mensagemBd == null) {
            return "Sem permissão para esta operação";
        }
        if (mensagemBd.startsWith("new row violates row-level security policy")) {
            return "Sem permissão para gravar este registo nesta igreja";
        }
        if (mensagemBd.startsWith("permission denied")) {
            return "Sem permissão para esta operação";
        }
        return mensagemBd;
    }

    /**
     * Campo JSON a partir do nome da restrição: {@code fk_mem_igr_id → igrejaId},
     * {@code uq_usu_email → email}. Restrições de várias colunas ou CHECK com nome livre → {@code null}
     * (o erro aparece no topo do formulário, em vez de junto a um campo errado).
     */
    static String campoDaRestricao(String restricao) {
        if (restricao == null) {
            return null;
        }
        String[] partes = restricao.split("_", 2);
        if (partes.length < 2) {
            return null;
        }
        String resto = partes[1];
        return switch (partes[0]) {
            case "fk" -> Nomes.campo(resto);
            case "uq" -> resto.contains("_id_") ? null : Nomes.campo(resto);
            default -> null;
        };
    }
}
