import os, re, sys, html
sys.path.insert(0, os.path.dirname(__file__))
import fnmatch
from defs import MODULES, PERFIS, NEGOCIO, ACCOES, SYSTEM_WRITE, GLOBAL_READ

ALL = [t for m in MODULES for t in m[4]]
BY = {t.name: t for t in ALL}
E = html.escape

def kind(typ):
    t = typ.upper()
    for k, v in [('BIGINT', 'bigint'), ('SMALLINT', 'int'), ('INT', 'int'), ('VARCHAR', 'string'), ('CHAR', 'string'),
                 ('TEXT', 'text'), ('DECIMAL', 'decimal'), ('TIMESTAMPTZ', 'timestamp'), ('DATE', 'date'),
                 ('BOOLEAN', 'bool'), ('JSONB', 'json')]:
        if t.startswith(k): return v
    return 'enum'

def ent(n): return n.upper()

def mermaid(tables):
    names = {t.name for t in tables}
    lines, stubs = ['erDiagram'], set()
    for t in tables:
        uniq1 = {u[0] for u in t.uniq if len(u) == 1}
        for c in t.cols:
            if not c[1].startswith('fk:'): continue
            ref = c[1][3:]
            if ref not in names: stubs.add(ref)
            req = len(c) > 2 and 'NOT NULL' in c[2]
            role = re.sub(r'_?[a-z]{3}_id$', '', c[0]).replace('_', ' ')
            lines.append(f'  {ent(ref)} {"||" if req else "|o"}--{"o|" if c[0] in uniq1 else "o{"} {ent(t.name)} : "{role}"')
    for t in tables:
        uniq1 = {u[0] for u in t.uniq if len(u) == 1}
        lines += [f'  {ent(t.name)} {{', f'    {"bigint" if t.big else "int"} {t.p}_id PK']
        for c in t.cols:
            fk = c[1].startswith('fk:')
            typ = ('bigint' if BY[c[1][3:]].big else 'int') if fk else kind(c[1])
            keys = ','.join(k for k, ok in (('FK', fk), ('UK', c[0] in uniq1)) if ok)
            lines.append(f'    {typ} {t.p}_{c[0]}{" " + keys if keys else ""}')
        lines += [f'    enum {t.p}_estado', '  }']
    for s in sorted(stubs):
        r = BY[s]
        lines.append(f'  {ent(s)} {{\n    {"bigint" if r.big else "int"} {r.p}_id PK\n  }}')
    return '\n'.join(lines)

def codigos():
    out = []
    for t in ALL:
        for a in ACCOES:
            if t.name in SYSTEM_WRITE and a != 'ler': continue
            if t.name in GLOBAL_READ and a == 'ler': continue
            out.append(f'{t.schema}.{t.name}.{a}')
    return out + [c for c, _ in NEGOCIO]
COD = codigos()
def perfil_set(regras):
    sel = set()
    for op, pat in regras:
        hit = {c for c in COD if fnmatch.fnmatchcase(c, pat)}
        sel = sel | hit if op == '+' else sel - hit
    return sel
NOMES_ACCAO = {'ler': 'ler', 'criar': 'criar', 'alterar': 'alterar', 'terminar': 'terminar'}
def celula(sel, schema):
    tabs = [t for m in MODULES if m[1] == schema for t in m[4] if t.name not in SYSTEM_WRITE]
    acc = []
    for a in ACCOES:
        n_ = sum(1 for t in tabs if f'{schema}.{t.name}.{a}' in sel)
        tot = sum(1 for t in tabs if not (t.name in GLOBAL_READ and a == 'ler'))
        if n_ == 0 or tot == 0: continue
        acc.append(a if n_ == tot else f'{a} ({n_}/{tot})')
    return '<br>'.join(acc) if acc else '<span class="mut">—</span>'
mat_head = ''.join(f'<th>{s}</th>' for _, s, *_ in MODULES)
mat_rows = ''
for nome, amb, desc, regras in PERFIS:
    sel = perfil_set(regras)
    neg = [c.split('.', 1)[1].replace('.', ' · ').replace('_', ' ') for c, _ in NEGOCIO if c in sel]
    cells = ''.join(f'<td>{celula(sel, s)}</td>' for _, s, *_ in MODULES)
    mat_rows += (f'<tr><th scope="row"><span class="perfil">{nome}</span><span class="amb">{"Associação" if amb == "ENTIDADE" else "igreja"}</span></th>'
                 f'{cells}<td>{", ".join(neg) if neg else "<span class=mut>—</span>"}</td></tr>')

mod_rows = ''.join(f'<tr><td><code>{s}</code></td><td>{E(title)}</td><td>{len(ts)}</td><td>{E(d)}</td></tr>'
                   for _, s, title, d, ts in MODULES)
sections = []
for i, (fname, schema, title, desc, tables) in enumerate(MODULES, 1):
    rows = ''.join(f'<tr><td><code>{t.p}_</code></td><td><code>{schema}.{t.name}</code></td><td>{E(t.desc)}</td></tr>' for t in tables)
    sections.append(f'''
  <section>
    <h2>{i}. {E(title)} <span class="schema">{schema}</span></h2>
    <p class="lead">{E(desc)}</p>
    <div class="panel"><pre class="mermaid">
{mermaid(tables)}
</pre></div>
    <details><summary>Tabelas e prefixos ({len(tables)})</summary>
      <div class="tbl"><table><thead><tr><th>Prefixo</th><th>Tabela</th><th>Para quê</th></tr></thead><tbody>{rows}</tbody></table></div>
    </details>
  </section>''')

manual = [
 ('Admissão de membros', 'Por baptismo, rebaptismo ou profissão de fé, sempre com voto da igreja. A junta directiva só recomenda.',
  'O movimento no livro de membros exige um voto aprovado numa reunião regular ou assembleia. Um voto da junta é recusado.'),
 ('Livro de membros', 'O secretário não acrescenta nem retira nomes sem voto da igreja, excepto por falecimento ou pedido escrito do membro.',
  'O estado e a igreja do membro só mudam através de um movimento com o voto que o autoriza. O falecimento não exige voto; o pedido de saída aceita um voto da junta.'),
 ('Carta de transferência', 'Primeira leitura e votação na semana seguinte. A carta vale 6 meses e o membro fica na igreja de origem até o destino o aceitar.',
  'Exige o voto da segunda leitura na origem e no destino. A aceitação fora dos 6 meses é recusada. Ao concluir, a saída e a entrada são registadas nas duas igrejas.'),
 ('Censura', 'Dura de 1 a 12 meses. Durante a censura o membro não ocupa cargos nem recebe carta de transferência. Nos menores, os pais têm de ser avisados.',
  'A duração máxima é verificada. A censura termina os cargos activos e bloqueia eleições e cartas. Num menor, é recusada se o encarregado não foi avisado.'),
 ('Membros desaparecidos', 'Só após 2 anos de buscas sem resultado e voto da assembleia administrativa.',
  'O movimento DESAPARECIDO exige voto da assembleia administrativa. Os 2 anos de buscas ficam a cargo do secretário.'),
 ('Eleições', 'Os oficiais são membros em situação regular, eleitos por voto da igreja sobre o relatório da comissão de nomeações.',
  'O cargo exige um membro activo da igreja, sem censura, e o voto de eleição. Uma vista avisa dos mandatos a terminar.'),
 ('Fundos da Associação', 'O dízimo e as ofertas missionárias são fundos da Associação: remetidos todos os meses, sem uso local.',
  'Os fundos de dízimo, missões e 13º sábado têm 100% de remessa obrigatória e só saem como remessa ou estorno. Uma vista calcula o que falta remeter por mês.'),
 ('Ofertas da Escola Sabatina', 'A oferta para despesas da ES fica separada da oferta missionária; não se juntam nem se dividem por percentagem.',
  'O relatório separa a oferta missionária, a do 13º sábado e a de despesas, e só fecha se a tesouraria tiver cada uma no seu fundo.'),
 ('Estrutura', 'Igreja organizada, grupo organizado e filial, dentro de uma Associação ou Missão, de uma União e de uma Divisão.',
  'A organização é hierárquica, com distritos pastorais e o pastor distrital a ver todas as igrejas do distrito. Há também um calendário de ofertas especiais definido pela Divisão, União ou Associação.'),
]
man_rows = ''.join(f'<tr><td>{E(a)}</td><td>{E(b)}</td><td>{E(c)}</td></tr>' for a, b, c in manual)

body = f'''
<div class="wrap">
  <header>
    <h1>Modelo de dados · versão 5</h1>
    <p class="lead">{len(ALL)} tabelas em {len(MODULES)} módulos (schemas PostgreSQL), com permissões por perfil verificadas pela própria base de dados, conformes ao Manual da Igreja Adventista do Sétimo Dia e testadas com 377 mil movimentos. Corresponde às migrações <code>V1</code> a <code>V13</code> e ao script único <code>schema_igreja_v5.sql</code> (PostgreSQL 15+).</p>
  </header>

  <section>
    <h2>Módulos</h2>
    <div class="tbl"><table><thead><tr><th>Schema</th><th>Módulo</th><th>Tabelas</th><th>Conteúdo</th></tr></thead><tbody>{mod_rows}</tbody></table></div>
    <div class="grid2">
      <div class="note">
        <h3>Nomes</h3>
        <p>Cada coluna começa pelo prefixo de 3 letras da sua tabela (<code>mem_nome</code>). A chave estrangeira diz para onde aponta: <code>ect_professor_mem_id</code>.</p>
      </div>
      <div class="note">
        <h3>Campos em todas as tabelas</h3>
        <p><code>_estado</code>, <code>_criado_em</code>, <code>_criado_por</code>, <code>_modificado_em</code>, <code>_modificado_por</code> e <code>_end_date</code>. Nada se apaga. Nos diagramas só aparece <code>_estado</code>.</p>
      </div>
    </div>
  </section>

  <section>
    <h2>Permissões</h2>
    <p class="lead">Cada tabela tem quatro permissões (<code>ler</code>, <code>criar</code>, <code>alterar</code>, <code>terminar</code>), com o código <code>&lt;módulo&gt;.&lt;tabela&gt;.&lt;acção&gt;</code>. A estas juntam-se nove acções de negócio. O PostgreSQL verifica-as em cada linha, na igreja a que o registo pertence; a API não consegue contorná-las.</p>
    <div class="grid2">
      <div class="note"><h3>De onde vêm as permissões</h3>
        <ul>
          <li><b>Perfil numa igreja</b> (<code>nucleo.usuario_igreja</code>).</li>
          <li><b>Perfil numa Associação/Missão</b> (<code>nucleo.usuario_entidade</code>): vale para todas as igrejas abaixo dela.</li>
          <li><b>Pastor distrital</b>: perfil PASTOR em todas as igrejas do distrito.</li>
          <li><b>O próprio membro</b>: vê sempre os seus dados, contribuições, matrículas e escalas, mesmo sem perfil.</li>
          <li><b>Super-administrador</b>: tudo.</li>
        </ul></div>
      <div class="note"><h3>Regras que ninguém contorna</h3>
        <ul>
          <li>Ninguém apaga registos; terminar ou reactivar exige a permissão <code>terminar</code>.</li>
          <li>Quem regista uma saída não a aprova; aprova-se só em nome próprio.</li>
          <li>Uma saída só é confirmada com despesa aprovada, aprovação de outra pessoa ou se for remessa.</li>
          <li>Ninguém altera os próprios perfis nem dá a outros um perfil com mais permissões do que as suas.</li>
          <li>Só um super-administrador cria outro, e só se gerem utilizadores das igrejas que se administram.</li>
          <li>A senha não é legível pela API; os saldos e o log só são escritos pelo sistema.</li>
        </ul></div>
    </div>
    <h3 class="sub">Matriz por perfil</h3>
    <p class="small">Em cada módulo, as acções que o perfil tem; "(n/m)" quer dizer que as tem em n das m tabelas do módulo. As tabelas comuns (categorias, departamentos, trimestres, ...) são legíveis por todos.</p>
    <div class="tbl"><table class="matriz"><thead><tr><th>Perfil</th>{mat_head}<th>Acções de negócio</th></tr></thead><tbody>{mat_rows}</tbody></table></div>
  </section>

  <section>
    <h2>Conformidade com o Manual da Igreja</h2>
    <div class="tbl"><table><thead><tr><th>Tema</th><th>O que o Manual pede</th><th>Como o sistema o garante</th></tr></thead><tbody>{man_rows}</tbody></table></div>
  </section>

  <section>
    <h2>Desempenho medido</h2>
    <p class="lead">Teste em PostgreSQL 16, numa máquina de 2 processadores: 300 igrejas, 45 mil membros, 377 mil movimentos e 755 mil linhas, cobrindo 2 anos.</p>
    <div class="tbl"><table><thead><tr><th>Operação</th><th>Tempo</th></tr></thead><tbody>
      <tr><td>Saldos das contas de uma igreja (tesoureiro, com permissões)</td><td class="num">9 ms</td></tr>
      <tr><td>Saldos por fundo de uma igreja</td><td class="num">3 ms</td></tr>
      <tr><td>Remessa devida, 24 meses</td><td class="num">5 ms</td></tr>
      <tr><td>Últimos 50 movimentos</td><td class="num">3 ms</td></tr>
      <tr><td>Declaração anual de contribuições de um membro</td><td class="num">8 ms</td></tr>
      <tr><td>Totais por fundo de 150 igrejas (Associação)</td><td class="num">78 ms</td></tr>
      <tr><td>Gravação com todas as regras e permissões activas, 4 sessões</td><td class="num">≈ 2 800 movimentos/s</td></tr>
      <tr><td>Tamanho total da base de dados</td><td class="num">376 MB</td></tr>
    </tbody></table></div>
    <div class="grid2">
      <div class="note"><h3>O que torna isto rápido</h3>
        <ul>
          <li>Saldos pré-calculados por dia, para cada conta e cada fundo.</li>
          <li>A igreja é copiada para as tabelas grandes, para que a segurança filtre por índice.</li>
          <li>As igrejas onde o utilizador tem cada permissão são calculadas uma vez por consulta, não linha a linha.</li>
          <li>O log de auditoria é particionado por mês e guarda só os campos alterados.</li>
          <li>Índices parciais e índices pela igreja e pela data.</li>
        </ul></div>
      <div class="note"><h3>Para crescer mais</h3>
        <ul>
          <li>Um conjunto de ligações (PgBouncer, modo transacção) é compatível com <code>set_config(…, true)</code>.</li>
          <li>Os relatórios de União e Divisão podem correr numa réplica de leitura.</li>
          <li>As partições antigas do log podem ser arquivadas sem bloquear nada.</li>
        </ul></div>
    </div>
  </section>
{"".join(sections)}
</div>
'''
head = open(os.path.join(os.path.dirname(__file__), 'page_head.html')).read()
extra_css = '''<style>
.schema{font-family:var(--mono);font-size:.8rem;font-weight:400;color:var(--accent);background:var(--accent-soft);padding:2px 8px;border-radius:999px;vertical-align:middle;margin-left:6px}
.note ul{margin:0;padding-left:1.1rem;display:grid;gap:4px}
td.num{font-variant-numeric:tabular-nums;white-space:nowrap;text-align:right}
td:first-child{white-space:normal}
h3.sub{font-family:var(--display);font-size:1.1rem;margin:8px 0 0}
.matriz th[scope=row]{white-space:nowrap;text-align:left;vertical-align:top}
.matriz td{font-size:.82rem;white-space:nowrap;vertical-align:top}
.matriz td:last-child{white-space:normal;min-width:180px}
.perfil{display:block;font-family:var(--mono);font-size:.8rem;font-weight:600;color:var(--fg)}
.amb{display:block;font-size:.72rem;color:var(--muted);font-weight:400;text-transform:none;letter-spacing:0}
.mut{color:var(--muted)}
</style>
'''
open(os.path.join(os.path.dirname(__file__), 'out', 'modelo_igreja.html'), 'w').write(head + extra_css + body)
print('ok')
