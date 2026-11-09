"""Junta a collection (pasta v3 em postman/collections/Igreja API) num só ficheiro JSON v2.1, para importar
no Postman (Import → ficheiro) ou partilhar: postman/Igreja-API.postman_collection.json

Os exemplos de resposta não vão no ficheiro (o contrato api/openapi.yaml descreve as respostas).

Uso (na raiz do projecto, depois de ferramentas/ajustar_collection.py):
  python ferramentas/exportar_collection.py
"""
import json
import uuid
from pathlib import Path

import yaml

RAIZ = Path(__file__).resolve().parent.parent
PASTA = RAIZ / 'postman' / 'collections' / 'Igreja API'
SAIDA = RAIZ / 'postman' / 'Igreja-API.postman_collection.json'
SCHEMA = 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json'


def ler(p):
    return yaml.safe_load(p.read_text(encoding='utf-8')) or {}


def lista(x):
    """headers/queryParams vêm como lista [{key, value}] ou como mapa {key: value}."""
    if isinstance(x, dict):
        return [{'key': k, 'value': str(v)} for k, v in x.items()]
    return x or []


def url(pedido):
    bruto = pedido['url']
    base, _, _ = bruto.partition('?')
    caminho = base.replace('{{baseUrl}}', '').strip('/')
    u = {'raw': bruto, 'host': ['{{baseUrl}}'], 'path': caminho.split('/') if caminho else []}
    query = [{'key': q['key'], 'value': str(q.get('value', '')), **({'disabled': True} if q.get('disabled') else {}),
              **({'description': q['description']} if q.get('description') else {})}
             for q in lista(pedido.get('queryParams'))]
    if query:
        u['query'] = query
    variaveis = [{'key': v['key'], 'value': str(v.get('value', ''))} for v in pedido.get('pathVariables') or []]
    if variaveis:
        u['variable'] = variaveis
    return u


def item_pedido(f):
    p = ler(f)
    nome = p.get('name') or f.name[:-len('.request.yaml')]
    req = {'method': p['method'], 'header': [
        {'key': h['key'], 'value': str(h.get('value', '')), **({'disabled': True} if h.get('disabled') else {}),
         **({'description': h['description']} if h.get('description') else {})} for h in lista(p.get('headers'))],
        'url': url(p)}
    if p.get('description'):
        req['description'] = p['description']
    corpo = p.get('body')
    if corpo and corpo.get('type') == 'json':
        req['body'] = {'mode': 'raw', 'raw': corpo['content'], 'options': {'raw': {'language': 'json'}}}
    item = {'name': nome, 'request': req}
    eventos = [{'listen': 'test' if s['type'] == 'afterResponse' else 'prerequest',
                'script': {'type': 'text/javascript', 'exec': s['code'].split('\n')}} for s in p.get('scripts') or []]
    if eventos:
        item['event'] = eventos
    return p.get('order', 0), item


def pasta(d):
    definicao = ler(d / '.resources' / 'definition.yaml') if (d / '.resources' / 'definition.yaml').exists() else {}
    filhos = [item_pedido(f) for f in d.glob('*.request.yaml')]
    filhos += [pasta(s) for s in d.iterdir() if s.is_dir() and s.name != '.resources']
    item = {'name': definicao.get('name') or d.name, 'item': [i for _, i in sorted(filhos, key=lambda x: x[0])]}
    if definicao.get('description'):
        item['description'] = definicao['description']
    return definicao.get('order', 0), item


def main():
    raiz = ler(PASTA / '.resources' / 'definition.yaml')
    _, conteudo = pasta(PASTA)
    variaveis = raiz.get('variables') or []
    if isinstance(variaveis, dict):
        variaveis = [{'key': k, 'value': str(v)} for k, v in variaveis.items()]
    colecao = {
        'info': {'_postman_id': str(uuid.uuid5(uuid.NAMESPACE_URL, 'igreja-api')), 'name': 'Igreja API',
                 'description': raiz.get('description', ''), 'schema': SCHEMA},
        'auth': {'type': 'bearer', 'bearer': [{'key': 'token', 'value': '{{bearerToken}}', 'type': 'string'}]},
        'variable': [{'key': v['key'], 'value': v.get('value', ''), 'type': 'string',
                      **({'description': v['description']} if v.get('description') else {})} for v in variaveis],
        'item': conteudo['item'],
    }
    SAIDA.write_text(json.dumps(colecao, ensure_ascii=False, indent=2), encoding='utf-8')

    def contar(itens):
        return sum(contar(i['item']) if 'item' in i else 1 for i in itens)
    print(f'{SAIDA.relative_to(RAIZ)}: {contar(colecao["item"])} pedidos em {len(colecao["item"])} pastas, '
          f'{SAIDA.stat().st_size // 1024} KB')


if __name__ == '__main__':
    main()
