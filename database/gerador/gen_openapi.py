"""Gera openapi.yaml a partir da definição do esquema (v5/defs.py) e das enumerações de V1__base.sql."""
import os, re, sys, json, yaml
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from defs import MODULES, SCOPE, SYSTEM_WRITE, GLOBAL_READ
from nomes import RES

ALL = [t for m in MODULES for t in m[4]]
BY = {t.name: t for t in ALL}
BYP = {t.p: t for t in ALL}

# enumerações
base = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sql', 'V1__base.sql')).read()
ENUMS = {m.group(1): re.findall(r"'([A-Z0-9_]+)'", m.group(2))
         for m in re.finditer(r"CREATE TYPE nucleo\.(\w+)\s+AS ENUM \((.*?)\);", base, re.S)}

ALIAS = {'contagem_numerario': 'contagem', 'conta_financeira': 'conta', 'relatorio_sabado': 'relatorio',
         'transferencia_membro': 'transferencia', 'movimento_membro': 'movimento', 'igreja_departamento': 'departamentoIgreja',
         'pagamento_mpesa': 'pagamentoMpesa', 'log_auditoria': 'log', 'pontuacao_config': 'pesosPontuacao'}
def camel(s):
    p = s.split('_'); return p[0] + ''.join(x[:1].upper() + x[1:] for x in p[1:])
def ent_name(table): return ALIAS.get(table, camel(table))
def campo(col):
    """nome da coluna (sem prefixo da tabela) -> nome do campo JSON"""
    m = re.match(r'^(?:(.*)_)?([a-z]{3})_id$', col)
    if m and m.group(2) in BYP:
        role, ref = m.group(1), BYP[m.group(2)].name
        n = ent_name(ref)
        return (camel(role) + n[:1].upper() + n[1:] + 'Id') if role else n + 'Id'
    return camel(col)
def pascal(table): n = ent_name(table); return n[:1].upper() + n[1:]
def modpath(s): return s.replace('_', '-')
def path_of(t): return f'/v1/{modpath(t.schema)}/{RES[t.name]}'

MONEY = {'type': 'string', 'pattern': r'^-?\d{1,14}(\.\d{1,2})?$', 'example': '650.00'}
def tipo(sqlt):
    u = sqlt.upper()
    if u.startswith('BIGINT'): return {'type': 'integer', 'format': 'int64'}
    if u.startswith(('INT', 'SMALLINT')): return {'type': 'integer'}
    m = re.match(r'(VAR)?CHAR\((\d+)\)', u)
    if m: return {'type': 'string', 'maxLength': int(m.group(2))}
    if u.startswith('TEXT'): return {'type': 'string'}
    if u.startswith('DECIMAL'): return dict(MONEY) if re.match(r'DECIMAL\((1[2-6]),2\)', u) else {'type': 'string', 'pattern': r'^-?\d+(\.\d+)?$'}
    if u.startswith('TIMESTAMPTZ'): return {'type': 'string', 'format': 'date-time'}
    if u.startswith('DATE'): return {'type': 'string', 'format': 'date'}
    if u.startswith('BOOLEAN'): return {'type': 'boolean'}
    if u.startswith('JSONB'): return {'type': 'object'}
    if sqlt in ENUMS: return {'$ref': f'#/components/schemas/{camel(sqlt[:-2]).capitalize() if False else enum_name(sqlt)}'}
    raise ValueError(sqlt)
def enum_name(e): return 'Enum' + ''.join(x.capitalize() for x in e[:-2].split('_'))

# campos que a base de dados preenche sozinha (igreja copiada, validação, aprovações)
AUTO = {'tra_igr_id', 'tli_igr_id', 'ect_igr_id', 'ers_igr_id', 'epr_igr_id', 'mem_validado_por_usu_id',
        'mem_data_validacao', 'des_aprovado_por_usu_id', 'des_aprovado_em', 'usu_ultimo_login'}

schemas = {enum_name(k): {'type': 'string', 'enum': v} for k, v in ENUMS.items()}
schemas['Erro'] = {'type': 'object', 'required': ['erro', 'mensagem', 'pedidoId'], 'properties': {
    'erro': {'type': 'string', 'enum': ['sem_permissao', 'regra_negocio', 'validacao', 'duplicado', 'referencia_invalida',
                                        'campo_obrigatorio', 'tentar_novamente', 'nao_encontrado', 'nao_autenticado', 'pedido_invalido']},
    'mensagem': {'type': 'string', 'description': 'Em português, pronta a mostrar ao utilizador'},
    'campo': {'type': 'string', 'nullable': True, 'description': 'Campo do formulário a que o erro se refere'},
    'pedidoId': {'type': 'string'}}}

paths = {}
def op(summary, tag, perm=None, **kw):
    o = {'summary': summary, 'tags': [tag]}
    if perm: o['x-permissao'] = perm
    o.update(kw); return o
ERRS = {'400': {'$ref': '#/components/responses/PedidoInvalido'}, '401': {'$ref': '#/components/responses/NaoAutenticado'},
        '403': {'$ref': '#/components/responses/SemPermissao'}, '404': {'$ref': '#/components/responses/NaoEncontrado'},
        '409': {'$ref': '#/components/responses/Duplicado'}, '422': {'$ref': '#/components/responses/RegraNegocio'}}
def resp(code, schema=None, desc='OK'):
    r = {code: {'description': desc}}
    if schema: r[code]['content'] = {'application/json': {'schema': schema}}
    return {**r, **ERRS}
def ref(n): return {'$ref': f'#/components/schemas/{n}'}
IDEMP = {'$ref': '#/components/parameters/IdempotencyKey'}

for fname, schema, title, desc, tables in MODULES:
    tag = title
    for t in tables:
        S = pascal(t.name)
        props = {'id': {'type': 'integer', 'format': 'int64' if t.big else 'int32', 'readOnly': True}}
        req_create = []
        uniq1 = {u[0] for u in t.uniq if len(u) == 1}
        for c in t.cols:
            col, sqlt = c[0], c[1]
            opt = c[2] if len(c) > 2 else ''
            full = f'{t.p}_{col}'
            if sqlt.startswith('fk:'):
                ref_t = BY[sqlt[3:]]
                s = {'type': 'integer', 'format': 'int64' if ref_t.big else 'int32',
                     'description': f'→ {ref_t.schema}.{ref_t.name}'}
            else:
                s = tipo(sqlt)
                if col == 'senha_hash': continue                  # nunca exposto
            d = c[3] if len(c) > 3 and c[3] else None
            if d:
                if '$ref' in s: s = {'allOf': [s], 'description': d}
                else: s['description'] = (s.get('description', '') + ' · ' + d).strip(' ·')
            if full in AUTO: s = {**s, 'readOnly': True} if '$ref' not in s else {'allOf': [s], 'readOnly': True}
            props[campo(col)] = s
            if 'NOT NULL' in opt and 'DEFAULT' not in opt and full not in AUTO:
                req_create.append(campo(col))
        et = t.estado[0]
        props['estado'] = ref(enum_name(et))
        for a, f in [('criadoEm', 'date-time'), ('modificadoEm', 'date-time'), ('endDate', 'date-time')]:
            props[a] = {'type': 'string', 'format': f, 'readOnly': True, **({'nullable': True} if a == 'endDate' else {})}
        for a in ['criadoPor', 'modificadoPor']:
            props[a] = {'type': 'integer', 'readOnly': True, 'nullable': True}
        schemas[S] = {'type': 'object', 'description': t.desc, 'x-tabela': f'{t.schema}.{t.name}', 'x-prefixo': t.p,
                      'properties': props}
        if req_create: schemas[S]['x-obrigatorios-ao-criar'] = req_create
        create = {'allOf': [ref(S)], 'required': req_create} if req_create else ref(S)
        if t.name == 'transacao':
            create = {'allOf': [ref(S), {'type': 'object', 'required': ['linhas'], 'properties': {'linhas': {
                'type': 'array', 'minItems': 1, 'description': 'Divisão por fundo; a soma tem de ser igual a valorTotal (vazio só em transferências)',
                'items': {'type': 'object', 'required': ['fundoId', 'categoriaId', 'valor'], 'properties': {
                    'fundoId': {'type': 'integer'}, 'categoriaId': {'type': 'integer'},
                    'departamentoIgrejaId': {'type': 'integer'}, 'actividadeId': {'type': 'integer'},
                    'valor': MONEY, 'descricao': {'type': 'string', 'maxLength': 255}}}}}}], 'required': req_create}

        base_p, code = path_of(t), f'{t.schema}.{t.name}'
        params = [{'$ref': '#/components/parameters/Limite'}, {'$ref': '#/components/parameters/Depois'},
                  {'$ref': '#/components/parameters/Ordem'}, {'$ref': '#/components/parameters/IncluirTerminados'}]
        sc = SCOPE.get(t.name)
        if sc and sc[0] == 'direct' and t.name != 'igreja':
            params.insert(0, {'name': 'igrejaId', 'in': 'query', 'required': True, 'schema': {'type': 'integer'}})
        for c in t.cols:
            if c[1].startswith('fk:') and not (sc and sc[0] == 'direct' and c[0] == sc[1]):
                params.append({'name': campo(c[0]), 'in': 'query', 'schema': {'type': 'integer'}})
            elif c[1] in ENUMS:
                params.append({'name': campo(c[0]), 'in': 'query', 'schema': ref(enum_name(c[1]))})
        params.append({'name': 'estado', 'in': 'query', 'schema': ref(enum_name(et))})
        if any(c[0] in ('data', 'data_hora', 'data_inicio') for c in t.cols):
            params += [{'name': 'desde', 'in': 'query', 'schema': {'type': 'string', 'format': 'date'}},
                       {'name': 'ate', 'in': 'query', 'schema': {'type': 'string', 'format': 'date'}}]
        if t.name == 'membro':
            params.append({'name': 'q', 'in': 'query', 'description': 'Procura por nome ou apelido', 'schema': {'type': 'string'}})
        lista = {'type': 'object', 'required': ['dados', 'proximo'], 'properties': {
            'dados': {'type': 'array', 'items': ref(S)}, 'proximo': {'type': 'string', 'nullable': True}}}
        paths[base_p] = {'get': op(f'Listar: {t.desc}', tag, f'{code}.ler' if t.name not in GLOBAL_READ else None,
                                   operationId=f'listar{S}', parameters=params, responses=resp('200', lista))}
        ro = t.name in SYSTEM_WRITE
        if not ro:
            post_params = [IDEMP] if t.schema in ('tesouraria', 'pagamentos') else []
            paths[base_p]['post'] = op(f'Criar: {t.desc}', tag, f'{code}.criar', operationId=f'criar{S}',
                                       parameters=post_params,
                                       requestBody={'required': True, 'content': {'application/json': {'schema': create}}},
                                       responses=resp('201', ref(S), 'Criado'))
        idp = [{'$ref': '#/components/parameters/Id'}]
        paths[base_p + '/{id}'] = {'get': op(f'Ler um registo', tag, f'{code}.ler' if t.name not in GLOBAL_READ else None,
                                              operationId=f'ler{S}', parameters=idp, responses=resp('200', ref(S)))}
        if not ro:
            paths[base_p + '/{id}']['patch'] = op('Alterar (só os campos enviados)', tag, f'{code}.alterar', operationId=f'alterar{S}',
                                                  parameters=idp, requestBody={'required': True, 'content': {'application/json': {'schema': ref(S)}}},
                                                  responses=resp('200', ref(S)))
            for acc, verb in [('terminar', 'Terminar (preenche endDate; nada se apaga)'), ('reactivar', 'Reactivar (limpa endDate)')]:
                paths[f'{base_p}/{{id}}/{acc}'] = {'post': op(verb, tag, f'{code}.terminar', operationId=f'{acc}{S}',
                                                               parameters=idp, responses=resp('200', ref(S)))}

# ---------------------------------------------------------------- acções de negócio
def acao(path, summary, tag, perm, body=None, resp_schema=None, fn=None, idemp=False, code='200'):
    o = op(summary, tag, perm, operationId=re.sub(r'[^A-Za-z]', '', path.title()))
    ps = []
    if '{id}' in path: ps.append({'$ref': '#/components/parameters/Id'})
    if idemp: ps.append(IDEMP)
    if ps: o['parameters'] = ps
    if body: o['requestBody'] = {'required': True, 'content': {'application/json': {'schema': body}}}
    if fn: o['x-funcao-bd'] = fn
    o['responses'] = resp(code, resp_schema)
    paths.setdefault(path, {})['post' if not path.endswith('/presencas') else 'put'] = o
def obj(req, **props): return {'type': 'object', 'required': req, 'properties': props}
I, D, DT, STR = {'type': 'integer'}, {'type': 'string', 'format': 'date'}, {'type': 'string', 'format': 'date-time'}, {'type': 'string'}

A = 'Autenticação'
acao('/v1/auth/login', 'Entrar', A, None, obj(['login', 'senha'], login=STR, senha=STR),
     obj(['tokenAcesso', 'expiraEm'], tokenAcesso=STR, expiraEm=DT), 'nucleo.fn_credenciais + nucleo.fn_abrir_sessao')
acao('/v1/auth/renovar', 'Renovar o token (cookie de renovação)', A, None, None, obj(['tokenAcesso'], tokenAcesso=STR, expiraEm=DT), 'nucleo.fn_renovar_sessao')
acao('/v1/auth/sair', 'Sair', A, None, None, None, 'nucleo.fn_terminar_sessao')
acao('/v1/auth/recuperar', 'Pedir código de recuperação (resposta igual exista ou não o login)', A, None, obj(['login'], login=STR), None, 'nucleo.fn_pedir_recuperacao')
acao('/v1/auth/redefinir', 'Definir senha nova com o código', A, None, obj(['login', 'codigo', 'senha'], login=STR, codigo={'type': 'string', 'pattern': r'^\d{6}$'}, senha={'type': 'string', 'minLength': 8}), None, 'nucleo.fn_redefinir_senha')
paths['/v1/eu'] = {'get': op('Utilizador, igrejas e permissões', A, None, operationId='eu', **{'x-funcao-bd': 'nucleo.fn_minhas_permissoes'},
    responses=resp('200', obj(['usuario', 'igrejas', 'permissoes'], usuario=obj(['id'], id=I, nome=STR, membroId={'type': 'integer', 'nullable': True}),
        igrejas={'type': 'array', 'items': obj(['id', 'nome'], id=I, nome=STR, perfis={'type': 'array', 'items': STR})},
        permissoes={'type': 'object', 'additionalProperties': {'type': 'array', 'items': STR}, 'description': 'igrejaId → códigos de permissão'})))}

SEC, ES, TES, PAG = 'Secretaria', 'Escola Sabatina', 'Tesouraria', 'Pagamentos electrónicos'
VOTO = obj(['votoId', 'data'], votoId=I, data=D)
acao('/v1/secretaria/membros/{id}/validar', 'Aprovar o registo do membro', SEC, 'secretaria.membro.validar', None, ref('Membro'))
acao('/v1/secretaria/transferencias/{id}/emitir-carta', 'Emitir a carta (voto da origem, 2ª leitura)', SEC, 'secretaria.transferencia_membro.emitir_carta', VOTO, ref('Transferencia'))
acao('/v1/secretaria/transferencias/{id}/concluir', 'Concluir no destino (voto do destino, até 6 meses)', SEC, 'secretaria.transferencia_membro.aceitar', VOTO, ref('Transferencia'))
acao('/v1/secretaria/transferencias/{id}/recusar', 'Recusar', SEC, 'secretaria.transferencia_membro.alterar', obj(['motivo'], motivo=STR), ref('Transferencia'))
acao('/v1/escola-sabatina/relatorios-sabado/{id}/presencas', 'Gravar a chamada inteira de uma vez (recalcula M.P. e E.D.)', ES, 'escola_sabatina.presenca.criar',
     {'type': 'array', 'items': obj(['membroId', 'presente'], membroId=I, presente={'type': 'boolean'}, estudouLicao={'type': 'boolean'})}, ref('Relatorio'))
acao('/v1/escola-sabatina/relatorios-sabado/{id}/ofertas', 'Tesoureiro lança as ofertas da classe (uma linha por fundo) e liga-as ao relatório', ES, 'tesouraria.transacao.criar',
     obj(['contaId', 'missoes', 'decimoTerceiro', 'despesas'], contaId=I, missoes=MONEY, decimoTerceiro=MONEY, despesas=MONEY, contagemId=I), ref('Transacao'),
     'tesouraria.transacao + escola_sabatina.fn_ligar_ofertas', idemp=True)
acao('/v1/escola-sabatina/relatorios-sabado/{id}/fechar', 'Fechar o relatório', ES, 'escola_sabatina.relatorio_sabado.fechar', None, ref('Relatorio'))
acao('/v1/escola-sabatina/relatorios-sabado/{id}/reabrir', 'Reabrir o relatório', ES, 'escola_sabatina.relatorio_sabado.reabrir', None, ref('Relatorio'))
acao('/v1/tesouraria/transacoes/{id}/aprovar', 'Aprovar uma saída pendente (em nome próprio)', TES, 'tesouraria.transacao.aprovar', None, ref('Transacao'), 'tesouraria.fn_aprovar_saida')
acao('/v1/tesouraria/transacoes/{id}/confirmar', 'Confirmar', TES, 'tesouraria.transacao.alterar', None, ref('Transacao'))
acao('/v1/tesouraria/transacoes/{id}/estornar', 'Criar o estorno (transacção do tipo contrário)', TES, 'tesouraria.transacao.criar',
     obj(['valor', 'linhas', 'motivo'], valor=MONEY, motivo=STR, linhas={'type': 'array', 'items': obj(['fundoId', 'categoriaId', 'valor'], fundoId=I, categoriaId=I, valor=MONEY)}),
     ref('Transacao'), idemp=True, code='201')
acao('/v1/tesouraria/transacoes/{id}/recibo', 'Emitir o recibo numerado', TES, 'tesouraria.recibo.criar', None, ref('Recibo'), 'tesouraria.fn_proximo_recibo', idemp=True, code='201')
acao('/v1/tesouraria/despesas/{id}/decidir', 'Aprovar (com valor) ou rejeitar (com motivo)', TES, 'tesouraria.despesa.aprovar',
     obj(['aprovar'], aprovar={'type': 'boolean'}, valor=MONEY, motivo=STR), ref('Despesa'), 'tesouraria.fn_decidir_despesa')
acao('/v1/tesouraria/orcamentos/{id}/aprovar', 'Marcar como aprovado, com o voto da igreja', TES, 'tesouraria.orcamento.aprovar', obj(['votoId'], votoId=I), ref('Orcamento'), 'tesouraria.fn_aprovar_orcamento')
acao('/v1/tesouraria/remessas/{id}/enviar', 'Marcar a remessa como enviada', TES, 'tesouraria.remessa.alterar', obj(['transacaoId', 'data'], transacaoId=I, data=D), ref('Remessa'))
acao('/v1/tesouraria/remessas/{id}/confirmar', 'Associação confirma a recepção', TES, 'tesouraria.remessa.confirmar', None, ref('Remessa'), 'tesouraria.fn_confirmar_remessa')
acao('/v1/tesouraria/fechos/{id}/reabrir', 'Reabrir o mês', TES, 'tesouraria.fecho_periodo.terminar', None, ref('FechoPeriodo'))
acao('/v1/tesouraria/extractos/importar', 'Importar o extracto (CSV) de uma conta', TES, 'tesouraria.extrato_linha.criar',
     obj(['contaId', 'csv'], contaId=I, csv={'type': 'string', 'description': 'data;descricao;referencia;valor'}), obj(['importadas', 'repetidas'], importadas=I, repetidas=I))
acao('/v1/tesouraria/extractos/{id}/reconciliar', 'Ligar a linha do extracto a uma transacção', TES, 'tesouraria.extrato_linha.alterar', obj(['transacaoId'], transacaoId=I), ref('ExtratoLinha'))
acao('/v1/pagamentos/mpesa', 'Iniciar um pagamento M-Pesa (cria a transacção pendente e chama a Vodacom)', PAG, 'pagamentos.pagamento_mpesa.criar',
     obj(['contaId', 'msisdn', 'linhas'], contaId=I, msisdn={'type': 'string', 'pattern': r'^2588[2-7]\d{7}$'}, membroId=I,
         linhas={'type': 'array', 'items': obj(['fundoId', 'categoriaId', 'valor'], fundoId=I, categoriaId=I, valor=MONEY)}),
     obj(['transacaoId', 'estado'], transacaoId=I, estado=ref('EnumEstadoTransacao')), idemp=True, code='202')
acao('/v1/pagamentos/mpesa/callback', 'Resposta da Vodacom (conta de serviço; idempotente)', PAG, 'perfil INTEGRACAO', {'type': 'object'}, None)

# rotas aninhadas (atalhos para tabelas-filho)
def aninhada(path, filho, summary, tag, perm_ler, perm_criar=None):
    idp = [{'$ref': '#/components/parameters/Id'}]
    paths[path] = {'get': op(summary, tag, perm_ler, operationId='listar' + re.sub(r'[^A-Za-z]', '', path.title()), parameters=idp,
                             responses=resp('200', {'type': 'array', 'items': ref(filho)}))}
    if perm_criar:
        paths[path]['post'] = op('Criar ' + summary.lower(), tag, perm_criar, operationId='criar' + re.sub(r'[^A-Za-z]', '', path.title()),
                                 parameters=idp, requestBody={'required': True, 'content': {'application/json': {'schema': ref(filho)}}},
                                 responses=resp('201', ref(filho), 'Criado'))
aninhada('/v1/secretaria/reunioes/{id}/votos', 'Voto', 'Votos da reunião', SEC, 'secretaria.voto.ler', 'secretaria.voto.criar')
aninhada('/v1/escola-sabatina/relatorios-sabado/{id}/visitantes', 'Visitante', 'Visitantes do relatório', ES, 'escola_sabatina.visitante.ler', 'escola_sabatina.visitante.criar')
aninhada('/v1/tesouraria/transacoes/{id}/linhas', 'TransacaoLinha', 'Linhas da transacção', TES, 'tesouraria.transacao_linha.ler')

# relatórios (vistas)
def rel(path, vista, tag, perm, extra=()):
    ps = [{'name': 'igrejaId', 'in': 'query', 'schema': {'type': 'integer'}},
          {'name': 'formato', 'in': 'query', 'schema': {'type': 'string', 'enum': ['json', 'csv', 'pdf'], 'default': 'json'}}] + list(extra)
    paths[path] = {'get': op(f'Relatório: {vista}', tag, perm, operationId='rel' + re.sub(r'[^A-Za-z]', '', path.title()),
                             parameters=ps, **{'x-vista': vista},
                             responses=resp('200', {'type': 'array', 'items': {'type': 'object'}}))}
ANO = [{'name': 'ano', 'in': 'query', 'schema': {'type': 'integer'}}, {'name': 'mes', 'in': 'query', 'schema': {'type': 'integer'}}]
TRI = [{'name': 'trimestreId', 'in': 'query', 'schema': {'type': 'integer'}}]
for p_, v_, perm in [('relatorio-mensal', 'secretaria.vw_relatorio_mensal_membros', 'secretaria.movimento_membro.ler'),
                     ('cartas-pendentes', 'secretaria.vw_cartas_pendentes', 'secretaria.transferencia_membro.ler'),
                     ('censuras-activas', 'secretaria.vw_censuras_activas', 'secretaria.disciplina.ler'),
                     ('mandatos-a-terminar', 'secretaria.vw_mandatos_a_terminar', 'secretaria.oficial.ler'),
                     ('menores-pendentes', 'secretaria.vw_menores_pendentes', 'secretaria.membro.ler'),
                     ('familias-resumo', 'secretaria.vw_familia_resumo', 'secretaria.familia.ler')]:
    rel(f'/v1/secretaria/{p_}', v_, SEC, perm, ANO if p_ == 'relatorio-mensal' else ())
for p_, v_ in [('classificacao', 'vw_classificacao'), ('painel', 'vw_painel'), ('evolucao', 'vw_evolucao_sabado'),
               ('relatorios-em-falta', 'vw_relatorios_em_falta'), ('conferencia-ofertas', 'vw_conferencia_ofertas'),
               ('relatorio-associacao', 'vw_relatorio_associacao')]:
    rel(f'/v1/escola-sabatina/{p_}', 'escola_sabatina.' + v_, ES, 'escola_sabatina.relatorio_sabado.ler', TRI)
for p_, v_, perm in [('saldos-contas', 'vw_saldo_conta', 'tesouraria.conta_financeira.ler'),
                     ('saldos-fundos', 'vw_saldo_fundo', 'tesouraria.saldo_diario_fundo.ler'),
                     ('remessas-devidas', 'vw_remessa_devida', 'tesouraria.saldo_diario_fundo.ler'),
                     ('execucao-orcamento', 'vw_execucao_orcamento', 'tesouraria.orcamento.ler'),
                     ('contribuicoes', 'vw_contribuicoes_membro', 'tesouraria.transacao.ler (ou o próprio membro)'),
                     ('extracto-anual', 'vw_extracto_anual', 'tesouraria.transacao.ler (ou o próprio membro)'),
                     ('progresso-alvos', 'vw_progresso_alvo', 'tesouraria.alvo.ler'),
                     ('conferencia-contagens', 'vw_contagem_conferencia', 'tesouraria.contagem_numerario.ler'),
                     ('despesas-por-pagar', 'vw_despesas_por_pagar', 'tesouraria.despesa.ler'),
                     ('extractos-por-reconciliar', 'vw_extrato_por_reconciliar', 'tesouraria.extrato_linha.ler')]:
    rel(f'/v1/tesouraria/{p_}', 'tesouraria.' + v_, TES, perm, ANO if p_ in ('remessas-devidas', 'extracto-anual') else ())
rel('/v1/actividades/escalas-proximas', 'actividades.vw_escala_proximas', 'Actividades e escalas', 'actividades.escala.ler')

doc = {
 'openapi': '3.0.3',
 'info': {'title': 'Sistema de Gestão da Igreja Adventista · API', 'version': '1.0.0',
          'description': ('Contrato gerado a partir do esquema da base de dados v5 (+ V14). Campos = colunas sem o prefixo, em camelCase. '
                          'Nada se apaga: use /terminar. As regras e as permissões são aplicadas pela base de dados; '
                          '`x-permissao` diz qual é exigida, `x-funcao-bd` a função usada, `x-vista` a vista lida.')},
 'servers': [{'url': 'https://api.exemplo.org', 'description': 'Substituir pelo endereço real'}],
 'security': [{'bearer': []}],
 'tags': [{'name': A}] + [{'name': m[2], 'description': m[3]} for m in MODULES],
 'paths': dict(sorted(paths.items())),
 'components': {
   'securitySchemes': {'bearer': {'type': 'http', 'scheme': 'bearer', 'bearerFormat': 'JWT'}},
   'parameters': {
     'Id': {'name': 'id', 'in': 'path', 'required': True, 'schema': {'type': 'integer', 'format': 'int64'}},
     'Limite': {'name': 'limite', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 1, 'maximum': 200, 'default': 50}},
     'Depois': {'name': 'depois', 'in': 'query', 'description': 'Cursor devolvido em `proximo`', 'schema': {'type': 'string'}},
     'Ordem': {'name': 'ordem', 'in': 'query', 'description': 'Campo de ordenação; "-" inverte (ex.: -dataHora)', 'schema': {'type': 'string'}},
     'IncluirTerminados': {'name': 'incluirTerminados', 'in': 'query', 'schema': {'type': 'boolean', 'default': False}},
     'IdempotencyKey': {'name': 'Idempotency-Key', 'in': 'header', 'description': 'UUID gerado no frontend; o mesmo pedido repetido devolve a mesma resposta durante 24 horas',
                        'schema': {'type': 'string', 'format': 'uuid'}}},
   'responses': {
     'PedidoInvalido': {'description': 'Pedido mal formado ou campo obrigatório em falta', 'content': {'application/json': {'schema': ref('Erro')}}},
     'NaoAutenticado': {'description': 'Sem token ou token expirado', 'content': {'application/json': {'schema': ref('Erro')}}},
     'SemPermissao': {'description': 'SQLSTATE 42501', 'content': {'application/json': {'schema': ref('Erro')}}},
     'NaoEncontrado': {'description': 'Não existe ou não é visível para o utilizador', 'content': {'application/json': {'schema': ref('Erro')}}},
     'Duplicado': {'description': 'SQLSTATE 23505', 'content': {'application/json': {'schema': ref('Erro')}}},
     'RegraNegocio': {'description': 'Regra do Manual ou da tesouraria (P0001, 23514, 23503)', 'content': {'application/json': {'schema': ref('Erro')}}}},
   'schemas': dict(sorted(schemas.items()))}}
for p in ['/v1/auth/login', '/v1/auth/renovar', '/v1/auth/recuperar', '/v1/auth/redefinir']:
    paths[p]['post']['security'] = []
open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'api', 'openapi.yaml'), 'w').write(yaml.safe_dump(json.loads(json.dumps(doc)), allow_unicode=True, sort_keys=False, width=140))
n_ops = sum(len(v) for v in paths.values())
print('caminhos', len(paths), 'operações', n_ops, 'esquemas', len(schemas))
