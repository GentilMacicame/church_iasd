package mz.org.iasd.igreja.controllers.base;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

import jakarta.json.JsonArray;
import jakarta.json.JsonObject;
import jakarta.json.JsonString;
import jakarta.json.JsonValue;

import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Image;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.ColumnText;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfPageEventHelper;
import com.lowagie.text.pdf.PdfWriter;

/**
 * Relatório em PDF ({@code ?formato=pdf}): o cabeçalho da igreja, o título, os filtros e a tabela das linhas, com
 * os nomes das colunas em português, dinheiro como "1 500,00", datas dd/mm/aaaa e o número da página. As colunas
 * de identificadores ({@code id}, {@code ...Id}) ficam de fora: não dizem nada a quem lê o papel.
 */
final class Pdf {

    private static final ZoneId MAPUTO = ZoneId.of("Africa/Maputo");
    private static final Pattern DINHEIRO = Pattern.compile("-?\\d+\\.\\d{2}");
    private static final Pattern DATA = Pattern.compile("\\d{4}-\\d{2}-\\d{2}");
    private static final Pattern DATA_HORA = Pattern.compile("\\d{4}-\\d{2}-\\d{2}T.*");
    private static final Pattern CODIGO = Pattern.compile("[A-Z][A-Z0-9]*(_[A-Z0-9]+)+|[A-Z]{5,}");
    private static final Color CINZA = new Color(0xEE, 0xF1, 0xF5);
    private static final Color AZUL = new Color(0x1E, 0x3A, 0x8A);

    /** Palavras que perdem o acento nos nomes técnicos (rotas e colunas). */
    private static final Map<String, String> ACENTOS = Map.ofEntries(
            Map.entry("relatorio", "relatório"), Map.entry("relatorios", "relatórios"), Map.entry("contribuicoes", "contribuições"),
            Map.entry("execucao", "execução"), Map.entry("orcamento", "orçamento"), Map.entry("conferencia", "conferência"),
            Map.entry("transferencias", "transferências"), Map.entry("transferencia", "transferência"), Map.entry("familias", "famílias"),
            Map.entry("familia", "família"), Map.entry("directorio", "directório"), Map.entry("sabado", "sábado"),
            Map.entry("classificacao", "classificação"), Map.entry("evolucao", "evolução"), Map.entry("variacao", "variação"),
            Map.entry("missao", "missão"), Map.entry("associacao", "associação"), Map.entry("diferenca", "diferença"),
            Map.entry("percentagem", "percentagem"), Map.entry("pct", "%"), Map.entry("numero", "n.º"), Map.entry("data", "data"),
            Map.entry("descricao", "descrição"), Map.entry("referencia", "referência"), Map.entry("ocasiao", "ocasião"),
            Map.entry("lancado", "lançado"), Map.entry("remessa", "remessa"), Map.entry("remessas", "remessas"),
            Map.entry("profissoes", "profissões"), Map.entry("fe", "fé"), Map.entry("remocoes", "remoções"),
            Map.entry("baptizados", "baptizados"), Map.entry("activos", "activos"), Map.entry("activas", "activas"),
            Map.entry("presencas", "presenças"), Map.entry("visitantes", "visitantes"), Map.entry("licao", "lição"),
            Map.entry("missoes", "missões"), Map.entry("saidas", "saídas"), Map.entry("saida", "saída"), Map.entry("disponivel", "disponível"),
            Map.entry("previsto", "previsto"), Map.entry("conselho", "conselho"), Map.entry("provincia", "província"),
            Map.entry("dias", "dias"), Map.entry("aprovacao", "aprovação"), Map.entry("valida", "válida"), Map.entry("ate", "até"),
            Map.entry("inicio", "início"), Map.entry("periodo", "período"), Map.entry("mes", "mês"), Map.entry("consentimento", "consentimento"));

    private Pdf() {
    }

    /** O logotipo da IASD (src/main/resources/documentos); sem ele, o PDF sai só com o texto. */
    private static Image logotipo() {
        try (InputStream in = Pdf.class.getResourceAsStream("/documentos/logotipo-iasd.png")) {
            return in == null ? null : Image.getInstance(in.readAllBytes());
        } catch (Exception e) {
            return null;
        }
    }

    /** "relatorio-mensal" ou "totalContado" → "Relatório mensal" / "Total contado". */
    static String humano(String tecnico) {
        String[] partes = tecnico.replace('-', ' ').replace('_', ' ').replaceAll("([a-z])([A-Z])", "$1 $2").toLowerCase().trim().split("\\s+");
        StringBuilder sb = new StringBuilder();
        for (String p : partes) {
            if (!sb.isEmpty()) {
                sb.append(' ');
            }
            sb.append(ACENTOS.getOrDefault(p, p));
        }
        return sb.isEmpty() ? tecnico : Character.toUpperCase(sb.charAt(0)) + sb.substring(1);
    }

    static String dinheiro(String v) {
        boolean neg = v.startsWith("-");
        String[] p = (neg ? v.substring(1) : v).split("\\.");
        String inteiro = p[0].replaceAll("\\B(?=(\\d{3})+(?!\\d))", " ");
        return (neg ? "-" : "") + inteiro + "," + p[1];
    }

    static String texto(JsonValue v) {
        if (v == null || v.getValueType() == JsonValue.ValueType.NULL) {
            return "—";
        }
        return switch (v.getValueType()) {
            case TRUE -> "Sim";
            case FALSE -> "Não";
            case NUMBER -> v.toString();
            case STRING -> {
                String s = ((JsonString) v).getString();
                if (DINHEIRO.matcher(s).matches()) {
                    yield dinheiro(s);
                }
                if (DATA.matcher(s).matches()) {
                    yield s.substring(8, 10) + "/" + s.substring(5, 7) + "/" + s.substring(0, 4);
                }
                if (DATA_HORA.matcher(s).matches()) {
                    try {
                        yield ZonedDateTime.parse(s).withZoneSameInstant(MAPUTO).format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
                    } catch (RuntimeException e) {
                        yield s;
                    }
                }
                if (CODIGO.matcher(s).matches()) {
                    yield humano(s.toLowerCase());          // A_TERMINAR → "A terminar", ACTIVO → "Activo"
                }
                yield s;
            }
            default -> v.toString();
        };
    }

    private static boolean aDireita(JsonValue v) {
        return v != null && (v.getValueType() == JsonValue.ValueType.NUMBER
                || (v.getValueType() == JsonValue.ValueType.STRING && DINHEIRO.matcher(((JsonString) v).getString()).matches()));
    }

    /**
     * @param titulo   título técnico (último troço da rota)
     * @param igreja   nome da igreja (ou null)
     * @param filtros  texto dos filtros (ex.: "Ano 2026 · Mês 11"), ou vazio
     */
    static byte[] de(JsonArray linhas, String titulo, String igreja, String filtros, boolean truncado) {
        List<String> colunas = new ArrayList<>();
        for (JsonValue l : linhas) {
            for (String k : l.asJsonObject().keySet()) {
                if (!colunas.contains(k)) {
                    colunas.add(k);
                }
            }
        }
        List<String> visiveis = colunas.stream().filter(c -> !c.equals("id") && !c.endsWith("Id")).toList();
        if (visiveis.isEmpty()) {
            visiveis = colunas;
        }
        Rectangle pagina = visiveis.size() > 6 ? PageSize.A4.rotate() : PageSize.A4;
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        Document doc = new Document(pagina, 36, 36, 40, 44);
        PdfWriter w = PdfWriter.getInstance(doc, out);
        w.setPageEvent(new PdfPageEventHelper() {
            @Override
            public void onEndPage(PdfWriter writer, Document d) {
                ColumnText.showTextAligned(writer.getDirectContent(), Element.ALIGN_RIGHT,
                        new Phrase("Página " + writer.getPageNumber(), FontFactory.getFont(FontFactory.HELVETICA, 8, Color.GRAY)),
                        d.right(), d.bottom() - 20, 0);
            }
        });
        doc.addTitle(humano(titulo));
        doc.addCreator("Sistema de Gestão da Igreja Adventista");
        doc.open();

        // cabeçalho: o logotipo à esquerda, a igreja, o título e os filtros à direita (como nos documentos impressos)
        PdfPTable cabecalho = new PdfPTable(new float[] {1f, 11f});
        cabecalho.setWidthPercentage(100);
        PdfPCell logo = new PdfPCell();
        logo.setBorder(Rectangle.NO_BORDER);
        logo.setVerticalAlignment(Element.ALIGN_MIDDLE);
        Image img = logotipo();
        if (img != null) {
            img.scaleToFit(42, 42);
            logo.addElement(img);
        }
        cabecalho.addCell(logo);
        PdfPCell textos = new PdfPCell();
        textos.setBorder(Rectangle.NO_BORDER);
        textos.setPaddingLeft(6);
        textos.addElement(new Paragraph("IGREJA ADVENTISTA DO SÉTIMO DIA", FontFactory.getFont(FontFactory.HELVETICA, 8, AZUL)));
        textos.addElement(new Paragraph(humano(titulo), FontFactory.getFont(FontFactory.HELVETICA_BOLD, 15)));
        String sub = (igreja == null ? "" : igreja) + (filtros.isEmpty() ? "" : (igreja == null ? "" : " · ") + filtros);
        if (!sub.isEmpty()) {
            textos.addElement(new Paragraph(sub, FontFactory.getFont(FontFactory.HELVETICA, 10)));
        }
        textos.addElement(new Paragraph("Gerado em " + ZonedDateTime.now(MAPUTO).format(DateTimeFormatter.ofPattern("dd/MM/yyyy 'às' HH:mm"))
                + " · " + linhas.size() + (linhas.size() == 1 ? " linha" : " linhas"), FontFactory.getFont(FontFactory.HELVETICA, 8, Color.GRAY)));
        cabecalho.addCell(textos);
        doc.add(cabecalho);
        doc.add(new Paragraph(" ", FontFactory.getFont(FontFactory.HELVETICA, 6)));

        if (linhas.isEmpty()) {
            doc.add(new Paragraph("Sem dados para estes filtros.", FontFactory.getFont(FontFactory.HELVETICA_OBLIQUE, 10)));
        } else {
            PdfPTable t = new PdfPTable(visiveis.size());
            t.setWidthPercentage(100);
            t.setHeaderRows(1);
            Font cab = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8);
            Font cel = FontFactory.getFont(FontFactory.HELVETICA, 8);
            JsonObject primeira = linhas.getJsonObject(0);
            for (String c : visiveis) {
                PdfPCell h = new PdfPCell(new Phrase(humano(c), cab));
                h.setBackgroundColor(CINZA);
                h.setBorderColor(Color.LIGHT_GRAY);
                h.setPadding(4);
                h.setHorizontalAlignment(aDireita(primeira.get(c)) ? Element.ALIGN_RIGHT : Element.ALIGN_LEFT);
                t.addCell(h);
            }
            for (JsonValue l : linhas) {
                JsonObject o = l.asJsonObject();
                for (String c : visiveis) {
                    PdfPCell x = new PdfPCell(new Phrase(texto(o.get(c)), cel));
                    x.setBorderColor(Color.LIGHT_GRAY);
                    x.setPadding(3.5f);
                    x.setHorizontalAlignment(aDireita(o.get(c)) ? Element.ALIGN_RIGHT : Element.ALIGN_LEFT);
                    t.addCell(x);
                }
            }
            doc.add(t);
        }
        if (truncado) {
            doc.add(new Paragraph("Atenção: o relatório tem mais linhas do que as mostradas. Use um filtro (igreja, ano ou mês).",
                    FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9, new Color(0xB4, 0x53, 0x09))));
        }
        doc.close();
        return out.toByteArray();
    }
}
