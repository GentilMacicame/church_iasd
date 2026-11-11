# ---- segurança (incluído em gen.py)
n += 1
def arr(code):  # igrejas onde o utilizador tem a permissão, calculado uma vez por consulta
    return f"((SELECT nucleo.fn_igrejas_com_permissao('{code}'))::INT[])"
def glob(code):
    return f"(SELECT nucleo.fn_tem_permissao_global('{code}'))"
def comum(code):  # V23: linhas comuns da Associação (permissão ao nível da Associação ou super-administrador)
    return f"(SELECT nucleo.fn_tem_permissao_comum('{code}'))"
def global_ou_comum(t, accao, code):
    return comum(code) if accao != 'ler' and t.name in COMUNS_ASSOCIACAO else glob(code)

def cond(t, accao):
    code = f'{q(t)}.{accao}'
    kind = SCOPE[t.name]
    if kind[0] == 'direct':
        return f'{t.p}_{kind[1]} = ANY {arr(code)}'
    if kind[0] == 'parent':
        pt = BY[kind[2]]; pk = SCOPE[pt.name]
        assert pk[0] == 'direct'
        return f'EXISTS (SELECT 1 FROM {q(pt)} x WHERE x.{pt.p}_id = {t.p}_{kind[1]} AND x.{pt.p}_{pk[1]} = ANY {arr(code)})'
    return sub(t, kind[1]).replace('{A}', arr(code)).replace('{G}', global_ou_comum(t, accao, code))

s = ['-- =====================================================================',
     f'-- V{n} · Permissões e segurança por igreja (Row Level Security)',
     '--',
     '--   Cada tabela tem 4 permissões: <schema>.<tabela>.ler / criar / alterar / terminar.',
     '--   Ler, criar e alterar são verificadas pelo PostgreSQL linha a linha, na igreja do registo.',
     '--   Terminar (end_date) e as acções de negócio (aprovar, emitir carta, fechar relatório, ...)',
     '--   são verificadas pelos triggers. Ninguém tem DELETE.',
     '--   A API liga-se com um utilizador membro de app_igreja e, em cada transacção SQL:',
     "--     SELECT set_config('app.usuario_id', '<usu_id>', true);",
     '-- =====================================================================', HEADER,
     "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_igreja') THEN CREATE ROLE app_igreja NOLOGIN; END IF; END $$;"]
for sc in SCHEMAS:
    s += [f'GRANT USAGE ON SCHEMA {sc} TO app_igreja;',
          f'GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA {sc} TO app_igreja;',
          f'GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA {sc} TO app_igreja;',
          f'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA {sc} TO app_igreja;']
s.append('-- Tabelas escritas só pelo sistema')
for name in SYSTEM_WRITE:
    s.append(f'REVOKE INSERT, UPDATE ON {q(BY[name])} FROM app_igreja;')
s.append('ALTER FUNCTION nucleo.fn_log_auditoria() SECURITY DEFINER;')
u = BY['usuario']
cols = [f'{u.p}_id'] + [f'{u.p}_{c[0]}' for c in u.cols if c[0] != 'senha_hash'] + \
       [f'{u.p}_{x}' for x in ('estado', 'criado_em', 'criado_por', 'modificado_em', 'modificado_por', 'end_date')]
s += ['-- A senha nunca é legível pela API (o login usa nucleo.fn_credenciais)',
      'REVOKE SELECT ON nucleo.usuario FROM app_igreja;',
      f'GRANT SELECT ({", ".join(cols)}) ON nucleo.usuario TO app_igreja;', '']

def policies(t):
    out = [f'ALTER TABLE {q(t)} ENABLE ROW LEVEL SECURITY;']
    if t.name in SCOPE:
        out.append(f'CREATE POLICY pol_{t.p}_ler ON {q(t)} FOR SELECT USING ({cond(t, "ler")});')
        if t.name not in SYSTEM_WRITE:
            out.append(f'CREATE POLICY pol_{t.p}_criar ON {q(t)} FOR INSERT WITH CHECK ({cond(t, "criar")});')
            c = cond(t, 'alterar')
            out.append(f'CREATE POLICY pol_{t.p}_alterar ON {q(t)} FOR UPDATE USING ({c}) WITH CHECK ({c});')
    else:
        if t.name in GLOBAL_READ:
            out.append(f'CREATE POLICY pol_{t.p}_ler ON {q(t)} FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);')
        else:
            out.append(f'CREATE POLICY pol_{t.p}_ler ON {q(t)} FOR SELECT USING ({glob(q(t) + ".ler")});')
        if t.name not in SYSTEM_WRITE:
            out.append(f'CREATE POLICY pol_{t.p}_criar ON {q(t)} FOR INSERT WITH CHECK ({global_ou_comum(t, "criar", q(t) + ".criar")});')
            g = global_ou_comum(t, 'alterar', q(t) + '.alterar')
            out.append(f'CREATE POLICY pol_{t.p}_alterar ON {q(t)} FOR UPDATE USING ({g}) WITH CHECK ({g});')
    if t.name in OWNER_READ:
        out.append(f'CREATE POLICY pol_{t.p}_proprio ON {q(t)} FOR SELECT USING ({sub(t, OWNER_READ[t.name])});')
    if t.name == 'usuario':
        out.append(f'CREATE POLICY pol_usu_proprio_alterar ON {q(t)} FOR UPDATE USING (usu_id = nucleo.fn_usuario_sessao()) WITH CHECK (usu_id = nucleo.fn_usuario_sessao());')
    return out
for t in ALL:
    s += policies(t)
s.append('-- Tabelas comuns (lidas por qualquer utilizador autenticado): ' + ', '.join(sorted(q(BY[x]) for x in GLOBAL_READ)))
files.append((f'V{n}__permissoes_e_seguranca.sql', '\n'.join(s) + '\n'))

# ---- catálogo de permissões e perfis (vai para os dados de referência)
DESC = {'ler': 'Ler', 'criar': 'Criar', 'alterar': 'Alterar', 'terminar': 'Terminar (end_date)'}
def todas_permissoes():
    out = []
    for t in ALL:
        for a in ACCOES:
            if t.name in SYSTEM_WRITE and a != 'ler':
                continue
            if t.name in GLOBAL_READ and a == 'ler':
                continue                      # lidas por qualquer utilizador autenticado
            out.append((f'{q(t)}.{a}', f'{DESC[a]}: {t.desc}'[:255]))
    return out + NEGOCIO

def perfil_codigos(regras, codigos):
    sel = set()
    for op, pat in regras:
        hit = {c for c in codigos if fnmatch.fnmatchcase(c, pat)}
        sel = sel | hit if op == '+' else sel - hit
    return sorted(sel)

def esc(x): return x.replace("'", "''")

def catalogo():
    perms = todas_permissoes()
    codigos = [c for c, _ in perms]
    out = ['-- ---------------------------------------------------------------- permissões (geradas)',
           'INSERT INTO nucleo.permissao (prm_codigo, prm_descricao) VALUES']
    out.append(',\n'.join(f"  ('{c}', '{esc(d)}')" for c, d in perms) + ';')
    out.append('\n-- ---------------------------------------------------------------- perfis (gerados)')
    out.append('INSERT INTO nucleo.perfil (per_nome, per_ambito, per_descricao) VALUES')
    out.append(',\n'.join(f"  ('{n}', '{a}', '{esc(d)}')" for n, a, d, _ in PERFIS) + ';')
    for n_, a, d, regras in PERFIS:
        cs = perfil_codigos(regras, codigos)
        if not cs: continue
        out.append(f'\n-- {n_}: {len(cs)} permissões')
        out.append(f"INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)\n"
                   f"SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = '{n_}'), prm_id FROM nucleo.permissao\n"
                   f"WHERE prm_codigo IN (" + ', '.join(f"'{c}'" for c in cs) + ");")
    return '\n'.join(out) + '\n'

# matriz para a documentação
MATRIZ = {n_: set(perfil_codigos(regras, [c for c, _ in todas_permissoes()])) for n_, a, d, regras in PERFIS}
