"""Gera os models da API a partir da definição do esquema da base de dados.

Escreve:
  models/<modulo>/<Tabela>.java   um record por tabela (@TabelaBd + @ColunaBd em cada campo)
  models/tipos/<Tipo>.java        um enum por tipo enumerado do PostgreSQL (@TipoBd)
  models/catalogo/CatalogoGerado.java   lista dos models e enums (o catálogo é lido deles)

Usa os mesmos ficheiros que geram as migrações e o openapi.yaml (database/gerador/defs.py, nomes.py,
sql/V1__base.sql) e a mesma regra de nomes dos campos (gen_openapi.campo), para a API e o contrato
nunca divergirem.

Uso:  python ferramentas/gen_catalogo.py [pasta do gerador]
      (por defeito database/gerador, neste repositório)
"""
import keyword
import os
import re
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
GERADOR = sys.argv[1] if len(sys.argv) > 1 else os.path.join(AQUI, '..', 'database', 'gerador')
sys.path.insert(0, os.path.abspath(GERADOR))
from defs import MODULES, SCOPE, SYSTEM_WRITE  # noqa: E402
from nomes import RES  # noqa: E402

PKG = 'mz.org.iasd.igreja'
JAVA = os.path.join(AQUI, '..', 'src', 'main', 'java', *PKG.split('.'))
MARCA = 'GERADO por ferramentas/gen_catalogo.py'

ALL = [t for m in MODULES for t in m[4]]
BYP = {t.p: t for t in ALL}
BY = {t.name: t for t in ALL}
for _f, _schema, _ti, _de, _tables in MODULES:
    for _t in _tables:
        _t.schema = _schema
base = open(os.path.join(GERADOR, 'sql', 'V1__base.sql'), encoding='utf-8').read()
ENUMS = {m.group(1): re.findall(r"'([A-Z0-9_]+)'", m.group(2))
         for m in re.finditer(r"CREATE TYPE nucleo\.(\w+)\s+AS ENUM \((.*?)\);", base, re.S)}

# iguais a gen_openapi.py
ALIAS = {'contagem_numerario': 'contagem', 'conta_financeira': 'conta', 'relatorio_sabado': 'relatorio',
         'transferencia_membro': 'transferencia', 'movimento_membro': 'movimento', 'igreja_departamento': 'departamentoIgreja',
         'pagamento_mpesa': 'pagamentoMpesa', 'log_auditoria': 'log', 'pontuacao_config': 'pesosPontuacao'}
AUTO = {'tra_igr_id', 'tli_igr_id', 'ect_igr_id', 'ers_igr_id', 'epr_igr_id', 'mem_validado_por_usu_id',
        'mem_data_validacao', 'des_aprovado_por_usu_id', 'des_aprovado_em', 'usu_ultimo_login'}
# iguais a gen_openapi.py: NOT NULL sem DEFAULT, mas a base calcula-os se vierem vazios
CALCULADOS = {'ers_membros_matriculados', 'esc_data', 'esc_igr_id'}

# Tipo (models.catalogo.Tipo) → tipo Java do campo
JTIPO = {'INT': 'Integer', 'BIGINT': 'Long', 'TEXTO': 'String', 'DINHEIRO': 'BigDecimal', 'DECIMAL': 'BigDecimal',
         'DATA': 'LocalDate', 'DATA_HORA': 'OffsetDateTime', 'BOOLEANO': 'Boolean', 'JSON': 'JsonValue'}
JIMPORT = {'BigDecimal': 'java.math.BigDecimal', 'LocalDate': 'java.time.LocalDate',
           'OffsetDateTime': 'java.time.OffsetDateTime', 'JsonValue': 'jakarta.json.JsonValue'}


def camel(s):
    p = s.split('_')
    return p[0] + ''.join(x[:1].upper() + x[1:] for x in p[1:])


def pascal(s):
    c = camel(s)
    return c[:1].upper() + c[1:]


def ent_name(table):
    return ALIAS.get(table, camel(table))


def campo(col):
    m = re.match(r'^(?:(.*)_)?([a-z]{3})_id$', col)
    if m and m.group(2) in BYP:
        role, n = m.group(1), ent_name(BYP[m.group(2)].name)
        return (camel(role) + n[:1].upper() + n[1:] + 'Id') if role else n + 'Id'
    return camel(col)


def tipo(sqlt):
    """(Tipo, tipo enum SQL ou None)"""
    if sqlt.startswith('fk:'):
        return ('BIGINT' if BY[sqlt[3:]].big else 'INT'), None
    u = sqlt.upper()
    if u.startswith('BIGINT'):
        return 'BIGINT', None
    if u.startswith(('INT', 'SMALLINT')):
        return 'INT', None
    if re.match(r'(VAR)?CHAR\(', u) or u.startswith('TEXT'):
        return 'TEXTO', None
    if u.startswith('DECIMAL'):
        return ('DINHEIRO' if re.match(r'DECIMAL\((1[2-6]),2\)', u) else 'DECIMAL'), None
    if u.startswith('TIMESTAMPTZ'):
        return 'DATA_HORA', None
    if u.startswith('DATE'):
        return 'DATA', None
    if u.startswith('BOOLEAN'):
        return 'BOOLEANO', None
    if u.startswith('JSONB'):
        return 'JSON', None
    if sqlt in ENUMS:
        return 'ENUM', sqlt
    raise ValueError(sqlt)


def nome_enum(sql):
    return pascal(re.sub(r'_t$', '', sql))


def doc(s):
    return (s or '').replace('*/', '*&#47;').replace('<', '&lt;').replace('>', '&gt;').strip()


def escrever(caminho, texto):
    os.makedirs(os.path.dirname(caminho), exist_ok=True)
    with open(caminho, 'w', encoding='utf-8', newline='\n') as f:
        f.write(texto)


def apagar_gerados(pasta):
    if os.path.isdir(pasta):
        for f in os.listdir(pasta):
            caminho = os.path.join(pasta, f)
            if f.endswith('.java') and MARCA in open(caminho, encoding='utf-8').read():
                os.remove(caminho)


def colunas(t):
    """[(coluna, campo, Tipo, enum, escrita, obrigatoria, naoNula, descricao)]"""
    p = t.p
    r = [(f'{p}_id', 'id', 'BIGINT' if t.big else 'INT', None, False, False, True, 'Identificador')]
    for c in t.cols:
        col, sqlt = c[0], c[1]
        opt = c[2] if len(c) > 2 else ''
        if col == 'senha_hash':
            continue                                        # nunca exposta
        full = f'{p}_{col}'
        tp, en = tipo(sqlt)
        escrita = full not in AUTO
        nao_nula = 'NOT NULL' in opt
        obrig = nao_nula and 'DEFAULT' not in opt and escrita and full not in CALCULADOS
        desc = c[3] if len(c) > 3 and c[3] else None
        if desc is None and sqlt.startswith('fk:'):
            desc = f'Referência a {BY[sqlt[3:]].schema}.{sqlt[3:]}'
        if not escrita:
            desc = (desc + ' ' if desc else '') + '(preenchido pela base de dados)'
        r.append((full, campo(col), tp, en, escrita, obrig, nao_nula, desc))
    r.append((f'{p}_estado', 'estado', 'ENUM', t.estado[0], True, False, True, 'Estado do registo'))
    for c, f, tp, d in [('criado_em', 'criadoEm', 'DATA_HORA', 'Data de criação'),
                        ('modificado_em', 'modificadoEm', 'DATA_HORA', 'Data da última alteração'),
                        ('end_date', 'endDate', 'DATA_HORA', 'Data em que foi terminado (null = activo)'),
                        ('criado_por', 'criadoPor', 'INT', 'Utilizador que criou'),
                        ('modificado_por', 'modificadoPor', 'INT', 'Utilizador que alterou por último')]:
        r.append((f'{p}_{c}', f, tp, None, False, False, c in ('criado_em', 'modificado_em'),
                  d + ' (preenchido pela base de dados)'))
    return r


# ------------------------------------------------------------------------------------------- enums
pasta_tipos = os.path.join(JAVA, 'models', 'tipos')
apagar_gerados(pasta_tipos)
for sql, valores in sorted(ENUMS.items()):
    n = nome_enum(sql)
    escrever(os.path.join(pasta_tipos, f'{n}.java'), f'''package {PKG}.models.tipos;

import {PKG}.models.catalogo.TipoBd;

/**
 * Tipo {{@code nucleo.{sql}}} da base de dados.
 * <p>
 * {MARCA} a partir de database/gerador. NÃO EDITAR À MÃO.
 */
@TipoBd("{sql}")
public enum {n} {{
    {(',' + chr(10) + '    ').join(valores)}
}}
''')

# ------------------------------------------------------------------------------------------- models
modelos = []
for _f, schema, _ti, _de, tables in MODULES:
    apagar_gerados(os.path.join(JAVA, 'models', schema.replace('_', '')))
for _f, schema, _ti, _de, tables in MODULES:
    pasta_mod = schema.replace('_', '')
    for t in tables:
        nome = pascal(t.name)
        imports = {f'{PKG}.models.catalogo.ColunaBd', f'{PKG}.models.catalogo.TabelaBd', f'{PKG}.models.catalogo.Tipo'}
        componentes = []
        params = []
        for (col, cmp, tp, en, escrita, obrig, nn, d) in colunas(t):
            if keyword.iskeyword(cmp):
                raise ValueError(f'{t.name}.{cmp} é palavra reservada em Java')
            jt = nome_enum(en) if tp == 'ENUM' else JTIPO[tp]
            if tp == 'ENUM':
                imports.add(f'{PKG}.models.tipos.{jt}')
            elif jt in JIMPORT:
                imports.add(JIMPORT[jt])
            attrs = [f'value = "{col}"', f'tipo = Tipo.{tp}']
            if not escrita:
                attrs.append('escrita = false')
            if obrig:
                attrs.append('obrigatoria = true')
            if nn:
                attrs.append('naoNula = true')
            extra = ''
            if tp == 'DINHEIRO':
                imports.add('jakarta.json.bind.annotation.JsonbNumberFormat')
                extra = '@JsonbNumberFormat(value = "0.00", locale = "en") '
            componentes.append(f'        @ColunaBd({", ".join(attrs)})\n        {extra}{jt} {cmp}')
            nota = []
            if obrig:
                nota.append('obrigatório ao criar')
            if tp == 'DINHEIRO':
                nota.append('dinheiro: no JSON é texto com 2 casas, ex. "650.00"')
            params.append(f' * @param {cmp} {doc(d) or ("coluna {@code " + col + "}")}'
                          + (f' — {", ".join(nota)}' if nota else ''))
        sc = SCOPE.get(t.name)
        col_igreja = f'{t.p}_{sc[1]}' if sc and sc[0] == 'direct' else None
        modulo = schema.replace('_', '-')
        tabela_attrs = [f'schema = "{schema}"', f'nome = "{t.name}"', f'prefixo = "{t.p}"',
                        f'modulo = "{modulo}"', f'recurso = "{RES[t.name]}"']
        if t.name in SYSTEM_WRITE:
            tabela_attrs.append('soLeitura = true')
        if col_igreja:
            tabela_attrs.append(f'colunaIgreja = "{col_igreja}"')
        blocos = [sorted(i for i in imports if i.startswith(p)) for p in ('java.', 'jakarta.', PKG)]
        txt_imports = '\n\n'.join('\n'.join(f'import {i};' for i in b) for b in blocos if b)
        escrever(os.path.join(JAVA, 'models', pasta_mod, f'{nome}.java'), f'''package {PKG}.models.{pasta_mod};

{txt_imports}

/**
 * {doc(t.desc)}.
 * <p>
 * Tabela {{@code {schema}.{t.name}}} · rota {{@code /v1/{modulo}/{RES[t.name]}}}. Os nomes dos campos são os do
 * JSON (iguais a {{@code api/openapi.yaml}}); {{@link ColunaBd}} diz a coluna correspondente.
 * <p>
 * {MARCA} a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
{chr(10).join(params)}
 */
@TabelaBd({", ".join(tabela_attrs)})
public record {nome}(
{(',' + chr(10)).join(componentes)}) {{
}}
''')
        modelos.append(f'{PKG}.models.{pasta_mod}.{nome}')

# ------------------------------------------------------------------------------------------- registo
lista_tipos = ',\n            '.join(f'{nome_enum(s)}.class' for s in sorted(ENUMS))
lista_modelos = ',\n            '.join(f'{m.rsplit(".", 1)[1]}.class' for m in modelos)
imps = sorted([f'{PKG}.models.tipos.{nome_enum(s)}' for s in ENUMS] + modelos)
escrever(os.path.join(JAVA, 'models', 'catalogo', 'CatalogoGerado.java'), f'''package {PKG}.models.catalogo;

import java.util.List;
import java.util.Map;

{chr(10).join(f"import {i};" for i in imps)}

/**
 * Lista dos models ({{@code models/<modulo>/}}) e dos tipos enumerados ({{@code models/tipos/}}).
 * O catálogo das operações-padrão é lido das anotações desses ficheiros ({{@link LeitorModelos}}).
 * <p>
 * {MARCA} a partir de database/gerador/defs.py. NÃO EDITAR À MÃO.
 */
public final class CatalogoGerado {{

    private CatalogoGerado() {{
    }}

    public static final List<Class<? extends Enum<?>>> TIPOS = List.of(
            {lista_tipos});

    public static final List<Class<? extends Record>> MODELOS = List.of(
            {lista_modelos});

    /** Valores de cada tipo enumerado do schema nucleo. */
    public static final Map<String, List<String>> ENUMS = LeitorModelos.enums(TIPOS);

    public static final List<Tabela> TABELAS = MODELOS.stream().map(LeitorModelos::tabela).toList();
}}
''')
print(f'{len(modelos)} models, {len(ENUMS)} enums  (gerador: {os.path.normpath(GERADOR)})')
