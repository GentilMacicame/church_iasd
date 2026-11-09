"""Torna utilizável a collection Postman gerada do contrato (api/openapi.yaml).

O gerador do Postman põe valores inventados em tudo; esta ferramenta corrige-os a partir do contrato:
  - variáveis da collection: baseUrl (API local), igrejaId, login e senha (preenchidas no Postman, nunca no git);
  - "Entrar" e "Renovar" guardam o token em bearerToken (os outros pedidos usam-no: Authorization: Bearer);
  - listagens e relatórios: só igrejaId e limite ligados; os filtros opcionais ficam desligados, prontos a ligar;
  - criar: todos os campos que se podem preencher (os opcionais com exemplos; ids opcionais a null; sem estado
    nem validacao, que mudam por movimento ou aprovação); acções: só os obrigatórios;
  - alterar (PATCH): corpo {} — enviam-se só os campos a mudar;
  - Idempotency-Key: {{$guid}} (um UUID novo em cada envio); :id = 1.

Uso (na raiz do projecto):
  postman spec generate collection api/openapi.yaml -n "Igreja API" --folder-strategy Tags --force
  python ferramentas/ajustar_collection.py
"""
import json
import re
import sys
from pathlib import Path

import yaml

RAIZ = Path(__file__).resolve().parent.parent
COLECCAO = RAIZ / 'postman' / 'collections' / 'Igreja API'
CONTRATO = yaml.safe_load((RAIZ / 'api' / 'openapi.yaml').read_text(encoding='utf-8'))
COMP = CONTRATO['components']
IGREJA = '__IGREJA__'   # trocado por {{igrejaId}} sem aspas (número no JSON)
NAO_PREENCHER = {'estado', 'validacao'}
EXEMPLOS = {   # valores plausíveis para os campos de texto opcionais (o resto: por tipo)
    'morada': 'Perto da escola primária', 'naturalidade': 'Xai-Xai, Gaza', 'nacionalidade': 'Moçambicana',
    'numeroIdentificacao': '110100000000A', 'profissao': 'Professor', 'nomePai': 'João Langa', 'nomeMae': 'Maria Cossa',
    'provincia': 'Maputo', 'cidadeDistrito': 'Matola', 'bairro': 'Machava', 'quarteirao': '12', 'numeroCasa': '34',
    'local': 'Rio Matola', 'oficiante': 'Pr. António Mabjaia', 'observacoes': '', 'descricao': '',
    'nome': 'Ana', 'apelido': 'Langa', 'dataNascimento': '1990-05-20', 'escolaridade': 'SECUNDARIO',
    'rebaptismo': False,
}

VARIAVEIS = [
    {'key': 'baseUrl', 'value': 'http://localhost:9080', 'description': 'Endereço da API (local: ./mvnw liberty:dev)'},
    {'key': 'igrejaId', 'value': '1', 'description': 'Igreja usada nas listagens, relatórios e criações'},
    {'key': 'login', 'value': '', 'description': 'E-mail ou telefone do utilizador (preencher no Postman)'},
    {'key': 'senha', 'value': '', 'description': 'Preencher no Postman; não guardar a senha no git'},
    {'key': 'bearerToken', 'value': '', 'description': 'Preenchido pelo pedido "Entrar" (válido 15 minutos)'},
]
SCRIPT_TOKEN = """const r = pm.response.json();
pm.test('devolve o token de acesso', () => pm.expect(r.tokenAcesso).to.be.a('string'));
if (r.tokenAcesso) {
    pm.collectionVariables.set('bearerToken', r.tokenAcesso);
}"""


class Literal(str):
    """Texto com várias linhas, escrito como bloco YAML (|-)."""


def _literal(dumper, dados):
    return dumper.represent_scalar('tag:yaml.org,2002:str', dados, style='|')


yaml.SafeDumper.add_representer(Literal, _literal)


def resolver(s):
    while isinstance(s, dict) and '$ref' in s:
        s = COMP[s['$ref'].split('/')[2]][s['$ref'].split('/')[3]]
    return s


def juntar(s):
    """allOf → um só objecto (propriedades e obrigatórios)."""
    s = resolver(s)
    if 'allOf' not in s:
        return s
    props, req = {}, list(s.get('required', []))
    for parte in s['allOf']:
        p = juntar(parte)
        props.update(p.get('properties', {}))
        req += p.get('required', [])
    return {'type': 'object', 'properties': props, 'required': list(dict.fromkeys(req))}


def exemplo(s, campo='', todos=False):
    if campo in EXEMPLOS:
        return EXEMPLOS[campo]
    s = juntar(s)
    if 'enum' in s:
        return s['enum'][0]
    t = s.get('type')
    if t == 'object' or 'properties' in s:
        obrig = s.get('required', [])
        if not todos:
            return {k: exemplo(s['properties'].get(k, {}), k) for k in obrig}
        out = {}
        for k, sub in s['properties'].items():
            sub_r = juntar(sub)
            if k in obrig:
                out[k] = exemplo(sub, k)
            elif sub_r.get('readOnly') or k in NAO_PREENCHER:
                continue
            elif k.endswith('Id') and sub_r.get('type') == 'integer':
                out[k] = None                     # referência opcional: preencher com um id que exista
            elif k in EXEMPLOS:
                out[k] = EXEMPLOS[k]
            else:
                out[k] = exemplo(sub, k)
        return out
    if t == 'array':
        return [exemplo(s.get('items', {}), campo)]
    if t == 'integer':
        return IGREJA if campo == 'igrejaId' else 1
    if t == 'number':
        return 1
    if t == 'boolean':
        return True
    if campo in ('login', 'senha'):
        return '{{' + campo + '}}'
    if 'example' in s:
        return s['example']
    fmt = s.get('format')
    if fmt == 'date':
        return '2026-11-14'
    if fmt == 'date-time':
        return '2026-11-14T09:00:00+02:00'
    if fmt == 'uuid':
        return '{{$guid}}'
    if s.get('pattern') == r'^\d{6}$':
        return '123456'
    return 'texto'


def operacao(pedido):
    url = pedido['url'].replace('{{baseUrl}}', '').split('?')[0]
    caminho = re.sub(r':(\w+)', r'{\1}', url)
    return CONTRATO['paths'].get(caminho, {}).get(pedido['method'].lower())


def cabecalhos(pedido):
    h = pedido.get('headers') or []
    if isinstance(h, dict):
        h = [{'key': k, 'value': v} for k, v in h.items()]
    for x in h:
        if x['key'] == 'Idempotency-Key':
            x['value'] = '{{$guid}}'
    pedido['headers'] = h


def parametros(pedido, op):
    if not pedido.get('queryParams'):
        return
    if isinstance(pedido['queryParams'], dict):
        pedido['queryParams'] = [{'key': k, 'value': str(v)} for k, v in pedido['queryParams'].items()]
    obrig = {resolver(p)['name'] for p in op.get('parameters', []) if resolver(p).get('required')}
    for q in pedido['queryParams']:
        ligar = q['key'] in obrig or q['key'] in ('limite', 'igrejaId')
        q['disabled'] = not ligar
        if q['key'] == 'igrejaId':
            q['value'] = '{{igrejaId}}'
        elif q['key'] == 'incluirTerminados':
            q['value'] = 'true'
        elif q.get('value') in ('string', '<string>') or (not ligar and str(q.get('value', '')).isdigit()):
            q['value'] = ''
        q.pop('description', None) if q.get('description') == '(Required) ' else None
    ligados = [q for q in pedido['queryParams'] if not q['disabled']]
    base = pedido['url'].split('?')[0]
    pedido['url'] = base + ('?' + '&'.join(f"{q['key']}={q['value']}" for q in ligados) if ligados else '')


def corpo(pedido, op):
    if 'body' not in pedido or not op or 'requestBody' not in op:
        return
    if pedido['method'] == 'PATCH':
        texto = '{}'
    else:
        todos = op.get('operationId', '').startswith('criar')   # criar de uma tabela (não as acções)
        valor = exemplo(op['requestBody']['content']['application/json']['schema'], todos=todos)
        texto = json.dumps(valor, ensure_ascii=False, indent=2).replace(f'"{IGREJA}"', '{{igrejaId}}')
    pedido['body'] = {'type': 'json', 'content': Literal(texto)}


def main():
    if not COLECCAO.exists():
        sys.exit(f'Não existe {COLECCAO}: gere primeiro a collection (ver o início deste ficheiro).')
    definicao = COLECCAO / '.resources' / 'definition.yaml'
    d = yaml.safe_load(definicao.read_text(encoding='utf-8'))
    d['variables'] = VARIAVEIS
    d['description'] = (CONTRATO['info']['description'] + '\n\nComeçar: preencha as variáveis login e senha, envie '
                        '"Autenticação / Entrar" (guarda o token) e depois qualquer pedido. igrejaId diz a igreja.')
    definicao.write_text(yaml.safe_dump(d, allow_unicode=True, sort_keys=False, width=1000), encoding='utf-8')

    n = sem_op = 0
    for f in sorted(COLECCAO.rglob('*.request.yaml')):
        pedido = yaml.safe_load(f.read_text(encoding='utf-8'))
        op = operacao(pedido)
        if op is None:
            sem_op += 1
            print('sem operação no contrato:', f.relative_to(COLECCAO))
            continue
        cabecalhos(pedido)
        parametros(pedido, op)
        corpo(pedido, op)
        for v in pedido.get('pathVariables') or []:
            v['value'] = '1'
            v.pop('description', None) if v.get('description') == '(Required) ' else None
        if pedido['url'].split('?')[0].endswith(('/v1/auth/login', '/v1/auth/renovar')):
            pedido['scripts'] = [{'type': 'afterResponse', 'code': Literal(SCRIPT_TOKEN), 'language': 'text/javascript'}]
        f.write_text(yaml.safe_dump(pedido, allow_unicode=True, sort_keys=False, width=1000), encoding='utf-8')
        n += 1
    print(f'{n} pedidos ajustados' + (f'; {sem_op} sem operação no contrato' if sem_op else ''))
    sys.exit(1 if sem_op else 0)


if __name__ == '__main__':
    main()
