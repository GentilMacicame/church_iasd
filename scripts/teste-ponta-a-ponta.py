"""Teste de ponta a ponta da API: servidor + PostgreSQL, por HTTP, como o frontend.

Uso (com a API a correr e um utilizador com perfil de administração na igreja 1):
    API_URL=http://localhost:9080 API_LOGIN=admin@igreja.local API_SENHA=... python scripts/teste-ponta-a-ponta.py

Cobre: login, /v1/eu, listagens com pesquisa e cursor, relatórios (JSON e CSV), criar/alterar/terminar,
erros 400/404/422, Idempotency-Key, corpo demasiado grande (413), sair (o token deixa de servir) e o limite
de pedidos no login (429). Cria uma família e uma conta de caixa de teste na igreja 1.
"""
import json
import os
import sys
import urllib.error
import urllib.request
import uuid

B = os.environ.get("API_URL", "http://localhost:9080")
LOGIN = os.environ.get("API_LOGIN", "admin@igreja.local")
SENHA = os.environ.get("API_SENHA")
if not SENHA:
    sys.exit("Defina API_SENHA (e, se preciso, API_URL e API_LOGIN)")
resultados = []


def pedir(metodo, caminho, corpo=None, token=None, headers=None, cru=None):
    h = {"Content-Type": "application/json"}
    if token:
        h["Authorization"] = "Bearer " + token
    h.update(headers or {})
    dados = cru if cru is not None else (json.dumps(corpo).encode() if corpo is not None else None)
    r = urllib.request.Request(B + caminho, data=dados, method=metodo, headers=h)
    try:
        with urllib.request.urlopen(r, timeout=30) as resp:
            texto = resp.read().decode("utf-8")
            return resp.status, dict(resp.headers), texto
    except urllib.error.HTTPError as e:
        return e.code, dict(e.headers), e.read().decode("utf-8")


def json_de(t):
    try:
        return json.loads(t)
    except Exception:
        return t


def verificar(nome, cond, detalhe=""):
    resultados.append(cond)
    print(("OK    " if cond else "FALHA ") + nome + ("" if cond else "  → " + str(detalhe)[:300]))


s, h, t = pedir("POST", "/v1/auth/login", {"login": LOGIN.upper(), "senha": SENHA})
verificar("login (e-mail com maiúsculas)", s == 200, (s, t))
token = json_de(t)["tokenAcesso"]
cookie = h.get("Set-Cookie", "")
verificar("cookie de renovação HttpOnly SameSite=Strict", "HttpOnly" in cookie and "SameSite=Strict" in cookie, cookie)

s, h, t = pedir("GET", "/v1/eu", token=token)
verificar("GET /v1/eu", s == 200 and "usuario" in json_de(t), (s, t))

s, h, t = pedir("GET", "/v1/secretaria/membros?igrejaId=1&q=a&limite=2", token=token)
d = json_de(t)
verificar("listar membros com pesquisa e limite (estava partido: ORDER BY ambíguo)", s == 200 and len(d["dados"]) <= 2, (s, t))
if d.get("proximo"):
    s2, _, t2 = pedir("GET", "/v1/secretaria/membros?igrejaId=1&q=a&limite=2&depois=" + d["proximo"], token=token)
    ids1 = {x["id"] for x in d["dados"]}
    ids2 = {x["id"] for x in json_de(t2)["dados"]}
    verificar("página seguinte pelo cursor, sem repetidos", s2 == 200 and not (ids1 & ids2), (s2, t2))

s, h, t = pedir("GET", "/v1/organizacao/igrejas?ordem=-nome", token=token)
verificar("listar igrejas ordenadas por nome descendente", s == 200, (s, t))

s, h, t = pedir("GET", "/v1/secretaria/membros", token=token)
verificar("listar sem igrejaId → 400 com campo", s == 400 and json_de(t)["campo"] == "igrejaId", (s, t))

for rel in ["/v1/escola-sabatina/classificacao?igrejaId=1", "/v1/escola-sabatina/resumo-classes?igrejaId=1",
            "/v1/escola-sabatina/conferencia-ofertas?igrejaId=1", "/v1/tesouraria/saldos-contas?igrejaId=1",
            "/v1/secretaria/membros-basico?igrejaId=1", "/v1/escola-sabatina/visitantes-a-anonimizar",
            "/v1/tesouraria/mpesa-pendentes", "/v1/nucleo/notificacoes-a-enviar"]:
    s, h, t = pedir("GET", rel, token=token)
    verificar("relatório " + rel.split("?")[0], s == 200 and isinstance(json_de(t), list), (s, t))

s, h, t = pedir("GET", "/v1/escola-sabatina/classificacao?igrejaId=1&formato=csv", token=token)
verificar("relatório em CSV", s == 200 and "text/csv" in h.get("Content-Type", ""), (s, h.get("Content-Type")))

s, h, t = pedir("POST", "/v1/secretaria/familias", {"igrejaId": 1, "nome": "Família E2E"}, token=token)
verificar("criar família → 201", s == 201, (s, t))
fid = json_de(t)["id"]
s, h, t = pedir("PATCH", f"/v1/secretaria/familias/{fid}", {"morada": "Bairro Central"}, token=token)
verificar("alterar família", s == 200 and json_de(t)["morada"] == "Bairro Central", (s, t))
s, h, t = pedir("POST", f"/v1/secretaria/familias/{fid}/terminar", token=token)
verificar("terminar família (nada se apaga)", s == 200 and json_de(t)["endDate"] is not None, (s, t))
s, h, t = pedir("PATCH", f"/v1/secretaria/familias/{fid}", {"morada": "X"}, token=token)
verificar("alterar registo terminado → 422 com a mensagem da base", s == 422, (s, t))

s, h, t = pedir("POST", "/v1/secretaria/familias", {"igrejaId": "um", "nome": "X"}, token=token)
verificar("tipo errado → 400 com campo", s == 400 and json_de(t)["campo"] == "igrejaId", (s, t))
s, h, t = pedir("GET", "/v1/secretaria/familias/999999", token=token)
verificar("registo inexistente → 404", s == 404, (s, t))

# idempotência (L3): mesma chave e mesmo corpo → mesma resposta; outro corpo → 422
chave = str(uuid.uuid4())
corpo = {"igrejaId": 1, "tipo": "CAIXA", "nome": "Caixa E2E " + chave[:8], "dataSaldoInicial": "2026-01-01"}
s1, h1, t1 = pedir("POST", "/v1/tesouraria/contas", corpo, token=token, headers={"Idempotency-Key": chave})
s2, h2, t2 = pedir("POST", "/v1/tesouraria/contas", corpo, token=token, headers={"Idempotency-Key": chave})
verificar("Idempotency-Key repetida devolve a mesma resposta", s1 == 201 and s2 == 201
          and json_de(t1) == json_de(t2) and h2.get("Idempotency-Replayed") == "true", (s1, s2, t1, t2))
corpo2 = dict(corpo, nome="Outra")
s3, _, t3 = pedir("POST", "/v1/tesouraria/contas", corpo2, token=token, headers={"Idempotency-Key": chave})
verificar("a mesma chave com outro corpo → 422", s3 == 422, (s3, t3))

# corpo demasiado grande (M6)
grande = json.dumps({"contaId": 1, "csv": "x" * (3 * 1024 * 1024)}).encode()
s, h, t = pedir("POST", "/v1/tesouraria/extractos/importar", token=token, cru=grande)
verificar("corpo de 3 MB → 413", s == 413, (s, t[:200]))

# sair → o token de acesso deixa de servir imediatamente (M1)
s, h, t = pedir("POST", "/v1/auth/sair", token=token, headers={"Cookie": cookie.split(";")[0]})
verificar("sair", s == 200, (s, t))
s, h, t = pedir("GET", "/v1/eu", token=token)
verificar("token de acesso depois de sair → 401", s == 401, (s, t))

# limite de pedidos no login (H2)
codigos = []
for i in range(12):
    s, h, t = pedir("POST", "/v1/auth/login", {"login": "ataque@x.mz", "senha": "errada" + str(i)})
    codigos.append(s)
# (numa segunda execução dentro de 5 minutos o IP já pode estar no limite: só 429)
verificar("logins errados: 401 até ao limite e depois 429", 429 in codigos and set(codigos) <= {401, 429}, codigos)

print(f"\n{sum(resultados)}/{len(resultados)} verificações OK")
sys.exit(0 if all(resultados) else 1)
