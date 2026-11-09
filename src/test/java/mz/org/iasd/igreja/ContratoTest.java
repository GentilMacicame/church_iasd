package mz.org.iasd.igreja;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import java.io.IOException;
import java.lang.annotation.Annotation;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import jakarta.ws.rs.HttpMethod;

import mz.org.iasd.igreja.crud.CatalogoGerado;
import mz.org.iasd.igreja.crud.Coluna;
import mz.org.iasd.igreja.crud.Tabela;

/**
 * A API e o contrato (api/openapi.yaml) coincidem:
 * <ul>
 *   <li>as rotas das classes {@code *Controller} (lidas por reflexão, incluindo as herdadas) são exactamente as
 *       operações do contrato — nem a mais, nem a menos;</li>
 *   <li>os campos JSON de cada tabela são os do contrato (nomes, ordem e obrigatórios ao criar).</li>
 * </ul>
 * Como efeito secundário escreve {@code docs/ROTAS.md}: a lista de todas as rotas, com a classe e o método
 * Java que as tratam e a permissão exigida.
 */
class ContratoTest {

    record Rota(String metodo, String caminho, String classe, String funcao) {
        String chave() {
            return metodo + " " + caminho;
        }
    }

    static List<String> contrato;

    @BeforeAll
    static void ler() throws IOException {
        Path f = Path.of(System.getProperty("openapi.ficheiro", "api/openapi.yaml"));
        assumeTrue(Files.isRegularFile(f), "openapi.yaml não encontrado: " + f.toAbsolutePath());
        contrato = Files.readAllLines(f, StandardCharsets.UTF_8);
    }

    @Test
    void rotasDoCodigoIguaisAsDoContrato() throws Exception {
        Map<String, String> permissoes = operacoesDoContrato();
        List<Rota> rotas = rotasDoCodigo();
        TreeSet<String> codigo = rotas.stream().map(Rota::chave).collect(Collectors.toCollection(TreeSet::new));
        TreeSet<String> doContrato = new TreeSet<>(permissoes.keySet());

        escreverRotas(rotas, permissoes);

        TreeSet<String> emFalta = new TreeSet<>(doContrato);
        emFalta.removeAll(codigo);
        TreeSet<String> aMais = new TreeSet<>(codigo);
        aMais.removeAll(doContrato);
        assertTrue(doContrato.size() > 390, "operações no contrato: " + doContrato.size());
        assertEquals(new TreeSet<>(), emFalta, "operações do contrato sem rota no código");
        assertEquals(new TreeSet<>(), aMais, "rotas no código que não estão no contrato");
        assertEquals(codigo.size(), rotas.size(), "rotas repetidas no código");
    }

    @Test
    void camposDeCadaTabelaIguaisAosDoContrato() {
        Map<String, List<String>> campos = new LinkedHashMap<>();
        Map<String, List<String>> obrigatorios = new LinkedHashMap<>();
        String tabela = null;
        List<String> props = null;
        List<String> obrig = null;
        String bloco = "";
        for (String l : contrato) {
            if (l.matches("^    [A-Z]\\w*:$")) {
                if (tabela != null) {
                    campos.put(tabela, props);
                    obrigatorios.put(tabela, obrig);
                }
                tabela = null;
                props = new ArrayList<>();
                obrig = new ArrayList<>();
                bloco = "";
            } else if (props != null && l.startsWith("      x-tabela: ")) {
                tabela = l.substring("      x-tabela: ".length()).trim();
            } else if (props != null && l.matches("^      [a-z][\\w-]*:.*$")) {
                bloco = l.trim();
            } else if (props != null && bloco.equals("properties:") && l.matches("^        \\w+:$")) {
                props.add(l.trim().replace(":", ""));
            } else if (props != null && bloco.equals("x-obrigatorios-ao-criar:") && l.startsWith("      - ")) {
                obrig.add(l.substring(8).trim());
            }
        }
        if (tabela != null) {
            campos.put(tabela, props);
            obrigatorios.put(tabela, obrig);
        }

        assertEquals(CatalogoGerado.TABELAS.size(), campos.size(), "tabelas no contrato");
        for (Tabela t : CatalogoGerado.TABELAS) {
            assertEquals(campos.get(t.nomeCompleto()), t.colunas().stream().map(Coluna::campo).toList(),
                    "campos de " + t.nomeCompleto());
            assertEquals(new TreeSet<>(obrigatorios.getOrDefault(t.nomeCompleto(), List.of())),
                    t.colunas().stream().filter(Coluna::obrigatoria).map(Coluna::campo).collect(Collectors.toCollection(TreeSet::new)),
                    "obrigatórios de " + t.nomeCompleto());
        }
    }

    // ------------------------------------------------------------------ contrato

    /** "MÉTODO /caminho" → permissão exigida (x-permissao), pela ordem do ficheiro. */
    static Map<String, String> operacoesDoContrato() {
        Pattern caminho = Pattern.compile("^  (/v1/\\S+):$");
        Pattern metodo = Pattern.compile("^    (get|post|patch|put|delete):$");
        Map<String, String> r = new LinkedHashMap<>();
        String actual = null;
        String operacao = null;
        for (String l : contrato) {
            if (l.startsWith("components:")) {
                break;
            }
            Matcher c = caminho.matcher(l);
            if (c.matches()) {
                actual = c.group(1);
                continue;
            }
            Matcher m = metodo.matcher(l);
            if (m.matches() && actual != null) {
                operacao = m.group(1).toUpperCase() + " " + actual;
                r.put(operacao, "");
            } else if (operacao != null && l.startsWith("      x-permissao: ")) {
                r.put(operacao, l.substring("      x-permissao: ".length()).trim());
            }
        }
        return r;
    }

    // ------------------------------------------------------------------ código

    static List<Rota> rotasDoCodigo() throws Exception {
        Path raiz = Path.of("target", "classes");
        Path modulos = raiz.resolve("mz/org/iasd/igreja/controllers");
        List<String> classes;
        try (Stream<Path> s = Files.walk(modulos)) {
            classes = s.map(p -> raiz.relativize(p).toString().replace('\\', '/'))
                    .filter(n -> n.endsWith("Controller.class") && !n.contains("$"))
                    .map(n -> n.substring(0, n.length() - ".class".length()).replace('/', '.'))
                    .sorted().toList();
        }
        List<Rota> rotas = new ArrayList<>();
        for (String nome : classes) {
            Class<?> c = Class.forName(nome);
            jakarta.ws.rs.Path base = c.getAnnotation(jakarta.ws.rs.Path.class);
            if (base == null || Modifier.isAbstract(c.getModifiers())) {
                continue;
            }
            for (Method m : c.getMethods()) {
                Method anotado = declaracaoJaxRs(c, m);
                if (anotado == null) {
                    continue;
                }
                String verbo = verbo(anotado);
                if (verbo == null) {
                    continue;
                }
                jakarta.ws.rs.Path sub = anotado.getAnnotation(jakarta.ws.rs.Path.class);
                rotas.add(new Rota(verbo, normalizar(base.value() + (sub == null ? "" : "/" + sub.value())),
                        c.getSimpleName(), m.getName()));
            }
        }
        rotas.sort(Comparator.comparing(Rota::caminho).thenComparing(Rota::metodo));
        return rotas;
    }

    /** Regra do JAX-RS: vale a declaração mais próxima que tenha anotações JAX-RS (herança de anotações). */
    private static Method declaracaoJaxRs(Class<?> c, Method m) {
        for (Class<?> k = c; k != null && k != Object.class; k = k.getSuperclass()) {
            try {
                Method d = k.getDeclaredMethod(m.getName(), m.getParameterTypes());
                for (Annotation a : d.getAnnotations()) {
                    if (a.annotationType().getPackageName().startsWith("jakarta.ws.rs")) {
                        return d;
                    }
                }
            } catch (NoSuchMethodException e) {
                // continua na superclasse
            }
        }
        return null;
    }

    private static String verbo(Method m) {
        for (Annotation a : m.getAnnotations()) {
            HttpMethod h = a.annotationType().getAnnotation(HttpMethod.class);
            if (h != null) {
                return h.value();
            }
        }
        return null;
    }

    static String normalizar(String caminho) {
        String s = caminho.replaceAll("\\{(\\w+)\\s*:[^}]*}", "{$1}").replaceAll("/+", "/");
        return s.length() > 1 && s.endsWith("/") ? s.substring(0, s.length() - 1) : s;
    }

    // ------------------------------------------------------------------ docs/ROTAS.md

    private static void escreverRotas(List<Rota> rotas, Map<String, String> permissoes) throws IOException {
        Map<String, List<Rota>> porModulo = new TreeMap<>();
        for (Rota r : rotas) {
            porModulo.computeIfAbsent(r.caminho().split("/")[2], k -> new ArrayList<>()).add(r);
        }
        StringBuilder md = new StringBuilder();
        md.append("# Rotas da API\n\n")
                .append("Gerado por `ContratoTest` a partir das classes `*Controller` (não editar à mão). ")
                .append(rotas.size()).append(" rotas, iguais às operações de `api/openapi.yaml`.\n")
                .append("Documentação interactiva: `http://localhost:9080/openapi/ui` (servidor a correr).\n\n");
        for (var e : porModulo.entrySet()) {
            md.append("## ").append(e.getKey()).append("\n\n")
                    .append("| Método | Caminho | Classe · método | Permissão |\n| --- | --- | --- | --- |\n");
            for (Rota r : e.getValue()) {
                String perm = permissoes.getOrDefault(r.chave(), "");
                md.append("| ").append(r.metodo()).append(" | `").append(r.caminho()).append("` | ")
                        .append(r.classe()).append(" · ").append(r.funcao()).append(" | ")
                        .append(perm.isEmpty() ? "—" : "`" + perm + "`").append(" |\n");
            }
            md.append('\n');
        }
        Path destino = Path.of("docs", "ROTAS.md");
        Files.createDirectories(destino.getParent());
        Files.writeString(destino, md.toString(), StandardCharsets.UTF_8);
    }
}
