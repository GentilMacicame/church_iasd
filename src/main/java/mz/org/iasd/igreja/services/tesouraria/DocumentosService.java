package mz.org.iasd.igreja.services.tesouraria;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import jakarta.json.JsonObject;

import mz.org.iasd.igreja.infraestrutura.erros.ApiException;
import mz.org.iasd.igreja.infraestrutura.ficheiros.ArmazemFicheiros;
import mz.org.iasd.igreja.models.catalogo.Catalogo;
import mz.org.iasd.igreja.models.catalogo.Tabela;
import mz.org.iasd.igreja.models.tesouraria.Documento;
import mz.org.iasd.igreja.repositories.base.TabelaRepository;
import mz.org.iasd.igreja.repositories.base.TabelaRepository.Valor;

/**
 * Comprovativos com ficheiro (F-TES-03, P-06): a fotografia do talão ou o print do M-Pesa que o membro manda, ou a
 * factura de uma despesa. A linha de {@code tesouraria.documento} é criada primeiro, na transacção do pedido: a RLS
 * decide se o utilizador pode juntar documentos àquele movimento ou despesa. Só depois se escreve o ficheiro; se a
 * escrita falhar, a transacção é desfeita e não fica uma linha sem ficheiro.
 */
public final class DocumentosService {

    public static final Tabela DOCUMENTO = Catalogo.de(Documento.class);

    private DocumentosService() {
    }

    public record Ficheiro(String nome, ArmazemFicheiros.Tipo tipo, byte[] dados) {
    }

    public static JsonObject carregar(Connection c, ArmazemFicheiros armazem, Long transacaoId, Long despesaId, String tipo,
            String nome, byte[] dados) throws SQLException {
        if (dados == null || dados.length == 0) {
            throw ApiException.pedidoInvalido("Escolha o ficheiro do comprovativo", "ficheiro");
        }
        ArmazemFicheiros.Tipo t = ArmazemFicheiros.tipo(dados).orElseThrow(() ->
                ApiException.pedidoInvalido("O comprovativo tem de ser uma fotografia (JPG, PNG ou WebP) ou um PDF", "ficheiro"));
        if ((transacaoId == null) == (despesaId == null)) {
            throw ApiException.pedidoInvalido("Diga a que movimento (ou despesa) pertence o comprovativo", "transacaoId");
        }
        String chave = ArmazemFicheiros.novaChave(t);
        List<Valor> valores = new ArrayList<>();
        if (transacaoId != null) {
            valores.add(Valor.campo(DOCUMENTO, "transacaoId", transacaoId.toString()));
        } else {
            valores.add(Valor.campo(DOCUMENTO, "despesaId", despesaId.toString()));
        }
        valores.add(Valor.campo(DOCUMENTO, "tipo", tipo == null || tipo.isBlank() ? "COMPROVATIVO" : tipo));
        valores.add(Valor.campo(DOCUMENTO, "nomeFicheiro", nomeLimpo(nome, t)));
        valores.add(Valor.campo(DOCUMENTO, "url", ArmazemFicheiros.PREFIXO + chave));
        JsonObject doc = TabelaRepository.criar(c, DOCUMENTO, valores);
        armazem.guardar(chave, dados);
        return doc;
    }

    /** O ficheiro de um documento visível (RLS); 404 se a linha não for visível ou não tiver ficheiro aqui. */
    public static Ficheiro ficheiro(Connection c, ArmazemFicheiros armazem, long id) throws SQLException {
        JsonObject doc = TabelaRepository.obterOu404(c, DOCUMENTO, id);
        String chave = ArmazemFicheiros.chaveDoUrl(doc.getString("url", null)).orElseThrow(ApiException::naoEncontrado);
        byte[] dados = armazem.ler(chave).orElseThrow(ApiException::naoEncontrado);
        return new Ficheiro(doc.getString("nomeFicheiro"), ArmazemFicheiros.Tipo.daChave(chave), dados);
    }

    /** Nome para mostrar: sem pastas nem caracteres de controlo, até 120 caracteres, com a extensão verdadeira. */
    static String nomeLimpo(String nome, ArmazemFicheiros.Tipo t) {
        String n = nome == null ? "" : nome.replace('\\', '/');
        n = n.substring(n.lastIndexOf('/') + 1).replaceAll("[\\p{Cntrl}\"<>|:*?]", "").strip();
        int ponto = n.lastIndexOf('.');
        if (ponto > 0) {
            n = n.substring(0, ponto);
        }
        if (n.isEmpty()) {
            n = "comprovativo";
        }
        if (n.length() > 120) {
            n = n.substring(0, 120);
        }
        return n + "." + t.extensao();
    }
}
