# Sistema de Gestão da Igreja Adventista

Secretaria, Escola Sabatina, tesouraria, actividades, M-Pesa e mensagens para igrejas locais e para a
Associação/Missão (Moçambique).

- **Base de dados** (PostgreSQL 16): as regras de negócio e as permissões estão aqui (triggers, RLS, funções).
- **API** (Jakarta EE 10, Java 21, Open Liberty): REST sobre a base, sem reimplementar as regras.
- **Frontend** (React + Vite): por fazer, em `web/`.

```
CLAUDE.md                 regras e convenções do projecto (lidas pelo Claude Code)
docker-compose.yml        PostgreSQL 16 local
database/
  migrations/             V1__base.sql … V16__correccoes_da_auditoria.sql
  schema_completo.sql     todas as migrações num só script (gerado: scripts/gerar-schema-completo.sh)
  schema_igreja_v5.sql    script único original (= V1–V13 juntas, igual linha a linha); referência
  tests/                  testes SQL 00–04 e resultado esperado
  gerador/                defs.py (fonte do esquema) + gen.py, gen_openapi.py
api/openapi.yaml          contrato da API (gerado de defs.py)
pom.xml, src/             a API (Maven + Open Liberty)
ferramentas/              gen_catalogo.py (gera os models da API de defs.py)
scripts/                  db-reset.sh, db-test.sh, criar-papel-api.sh, backup-bd.sh (lêem o .env)
docs/                     especificação, modelo de dados, ROTAS.md
web/                      frontend (por fazer)
```

## Documentação

- `docs/Especificacao_Sistema_Igreja_v1.1.docx` — especificação funcional e técnica (fonte); `docs/especificacao.md` — a mesma em Markdown
- `docs/modelo_dados.html` — modelo de dados navegável
- `api/openapi.yaml` — contrato da API; `docs/ROTAS.md` — as rotas com a classe Java e a permissão de cada uma
- `CLAUDE.md` — regras e convenções; comandos do Claude Code: `/nova-tabela`, `/novo-endpoint`, `/rever`

# API

API REST em **Jakarta EE 10** (JAX-RS, CDI, JSON-B, Bean Validation, MicroProfile Config) sobre **Java 21**,
a correr no **Open Liberty**. Contrato: [api/openapi.yaml](api/openapi.yaml). Regras e permissões ficam no
PostgreSQL; a API não as reimplementa.

## Arranque

A configuração (base de dados e API) está **só no `.env`** da raiz, lido pela API, pelos scripts, pelo
`docker compose` e pelos testes. Não vai para o git.

```bash
# 1. Configuração: servidor, porta, nome da base, utilizador e senha da API, administrador
cp .env.exemplo .env                  # e preencher BD_SENHA e BD_ADMIN_SENHA

# 2. Base de dados: PostgreSQL 16, migrações V1–V28 e o utilizador da API
docker compose up -d db               # ou um PostgreSQL já instalado (os dados de ligação vêm do .env)
scripts/db-reset.sh                   # cria a base BD_NOME (APAGA-A se existir: só no PC ou na 1.ª instalação)
scripts/criar-papel-api.sh            # cria BD_UTILIZADOR com a senha BD_SENHA
scripts/db-test.sh                    # testes SQL na base BD_NOME_TESTE (deve dar 15× ok)

# 3. API em modo de desenvolvimento (recompila ao gravar) em http://localhost:9080
./mvnw liberty:dev                    # Windows: mvnw.cmd liberty:dev
```

No Windows, os scripts encontram sozinhos o `psql` da instalação do PostgreSQL.

Não é preciso instalar Maven nem o servidor: o `mvnw` e o plugin descarregam-nos.

## Testes

```bash
./mvnw test
```

- Unitários: nomes de campos, paginação, tradução de erros, JWT, Argon2id, conversões, configuração de produção,
  limite de pedidos, tamanho do pedido, CSV, IP de origem.
- `ContratoTest`: as rotas das classes `*Controller` são exactamente as operações do `openapi.yaml` e os
  campos de cada tabela são os do contrato; escreve `docs/ROTAS.md`.
- Integração (`BaseDadosTest`, 44 testes): aplica as migrações V1–V28 num PostgreSQL real e testa, sempre com o
  papel da API (nunca o dono): `set_config` por transacção, RLS, permissões dos 13 perfis, erros
  403/422/409, sessões e rotação do token, bloqueio de login, recuperação de senha, idempotência,
  CRUD com perfis, processos P-05 (relatório do sábado) e P-08 (saída avulsa).
  - no servidor do `.env` (administrador `BD_ADMIN_*`), se responder: cria a base `<BD_NOME_TESTE>_api` e o
    papel `api_igreja_teste`, sem tocar nas outras bases;
  - senão, com Docker: PostgreSQL 16 descartável (Testcontainers);
  - ou outro servidor: `BD_TESTE_URL=jdbc:postgresql://servidor:5432/postgres BD_TESTE_SENHA=... ./mvnw test`;
  - a pasta das migrações vem de `-Dmigracoes.dir` (por defeito `database/migrations`).
- Ponta a ponta (HTTP, com a API e a base a correr): `API_SENHA=... python scripts/teste-ponta-a-ponta.py`
  (28 verificações: login, listagens, relatórios, CRUD, erros, idempotência, 413, sair, 429).
- CI (`.github/workflows/ci.yml`): testes SQL e da API contra PostgreSQL 16 em cada push.

Sem Docker nem a senha do PostgreSQL instalado, um servidor só para testes (PostgreSQL 16+ instalado no
Windows); no `.env`: `BD_PORTA=55432` e `BD_ADMIN_SENHA=` (vazio):

```bash
P="/c/Program Files/PostgreSQL/16/bin"            # ou 17, 18
"$P/initdb" -D ~/pg-testes -U postgres --auth=trust -E UTF8 --locale=C
"$P/pg_ctl" -D ~/pg-testes -l ~/pg-testes.log -o "-p 55432" start
./mvnw test && scripts/db-test.sh
```

## Ver as rotas

- **No browser:** com o servidor a correr, `http://localhost:9080/openapi/ui` (Swagger UI com o contrato,
  campos e exemplos; botão *Authorize* para colar o token de `POST /v1/auth/login`).
- **Numa lista:** [docs/ROTAS.md](docs/ROTAS.md) — as 403 rotas, com a classe e o método Java de cada uma e
  a permissão exigida. É regenerada pelo `ContratoTest` em cada `./mvnw test`.
- **No código, num só ficheiro:** [Rotas.java](src/main/java/mz/org/iasd/igreja/Rotas.java) — todos os
  caminhos, por módulo. Os `*Controller` usam estas constantes no `@Path` (`@Path(Rotas.Secretaria.MEMBROS)`);
  para mudar um endereço, muda-se ali.

## Collection do Postman

`postman/collections/Igreja API/` tem os 417 pedidos da API, por módulo, gerados do contrato (formato v3 do
Postman: um ficheiro por pedido, para rever no git). Para o Postman há também um ficheiro único:
**`postman/Igreja-API.postman_collection.json`** (Postman → **Import** → escolher o ficheiro).

1. Nas variáveis da collection, preencha `login` e `senha` (não as grave no git); `baseUrl` é a API local
   (`http://localhost:9080`) e `igrejaId` a igreja usada nas listagens e criações.
2. Envie **Autenticação / Entrar**: guarda o token em `bearerToken`, que todos os outros pedidos usam
   (válido 15 minutos; **Renovar** também o guarda).
3. Listagens: só `igrejaId` e `limite` vão ligados; os filtros (`estado`, `desde`, `depois`, ...) estão lá,
   desligados. Criar: o corpo tem só os campos obrigatórios. Alterar (PATCH): envie só o que muda.
   Os POST da tesouraria levam `Idempotency-Key` = `{{$guid}}` (um UUID novo em cada envio).

```bash
cd "postman/collections/Igreja API"
postman collection run . -i "Entrar" -i "Membros: listar" --env-var login=... --env-var senha=...
```

Quando o contrato mudar, gera-se de novo (os ajustes acima são aplicados pela ferramenta):

```bash
postman spec generate collection api/openapi.yaml -n "Igreja API" --folder-strategy Tags --force
python ferramentas/ajustar_collection.py
python ferramentas/exportar_collection.py      # ficheiro único para importar
postman collection lint "postman/collections/Igreja API"
```

## Estrutura

```
src/main/java/mz/org/iasd/igreja/
├── AplicacaoRest.java                 raiz JAX-RS
├── Rotas.java                         TODAS AS ROTAS da API, por módulo
├── controllers/                       CONTROLLERS (JAX-RS): recebem o pedido HTTP e respondem
│   ├── base/                          BaseTabelaController/BaseLeituraController (as 6 rotas-padrão herdadas),
│   │                                  BaseRelatoriosController (relatórios JSON/CSV/PDF), Corpo (lê o JSON), Csv, Pdf
│   └── <modulo>/                      secretaria/MembrosController, tesouraria/TransacoesController, ...
├── services/<modulo>/                 operações com vários passos (TransacoesService, RelatoriosSabadoService)
├── repositories/                      SQL (só parâmetros ?)
│   ├── base/                          TabelaRepository (SQL das rotas-padrão), Relatorio (vistas), Conversao (JSON ⇄ SQL)
│   └── <modulo>/                      SQL próprio (AuthRepository, EuRepository)
├── models/                            MODELS
│   ├── catalogo/                      @TabelaBd/@ColunaBd/@TipoBd e o catálogo lido deles (Tabela, Coluna, Catalogo)
│   ├── <modulo>/                      um record por tabela (secretaria/Membro, tesouraria/Transacao, ...) · GERADO
│   └── tipos/                         enums iguais aos tipos do PostgreSQL (EstadoMembro, Sexo, ...) · GERADO
├── config/                            Configuracao (MicroProfile Config), Json (JSON-B)
├── infraestrutura/                    técnico, sem regras de negócio
│   ├── bd/                            ExecutorTransaccao (BEGIN + set_config + COMMIT), @Transaccional,
│   │                                  @Idempotente (Idempotency-Key), UnidadeDeTrabalho
│   ├── erros/                         formato {erro, mensagem, campo, pedidoId}; SQLSTATE → HTTP
│   ├── seguranca/                     JWT, Argon2id, filtro Authorization: Bearer, @Publico, limites de pedidos
│   ├── mensagens/                     envio de SMS (fornecedor do .env)
│   ├── tarefas/                       tarefas agendadas (manutenção, lembretes, fila de SMS)
│   └── saude/                         /health/ready (base de dados)
└── comum/                             Nomes (coluna ⇄ campo), Paginacao, Dinheiro, Sql, FuncoesBd
```

A mesma regra em todas as camadas: **`base/`** tem o que é comum a todas as tabelas, uma vez só; **`<modulo>/`**
tem o que é próprio de um módulo. Os testes (`src/test/java`) seguem os mesmos pacotes.
```

Módulos: auth, eu, nucleo (inclui a fila de mensagens), organizacao, secretaria, escolasabatina, tesouraria
(inclui M-Pesa e bancos), actividades.

Camadas: **Controller** (HTTP: caminho, corpo, código de resposta) → **Serviço** (quando a operação tem
vários passos, ex.: transacção com linhas) → **Repositório** (SQL). Permissões e regras de negócio ficam
na base de dados; a API não as repete.

Cada controller de tabela é uma classe pequena, ligada à rota e ao model:

```java
@Path(Rotas.Secretaria.MEMBROS)                                   // caminho definido em Rotas.java
@RequestScoped
public class MembrosController extends BaseTabelaController {     // herda as 6 rotas-padrão
    private static final Tabela TABELA = Catalogo.de(Membro.class);   // model em models/secretaria/
    @Override protected Tabela tabela() { return TABELA; }

    @POST @Path(Rotas.Secretaria.MEMBROS_VALIDAR)                 // acção de negócio própria
    public Response validar(@PathParam("id") long id) { ... }
}
```

### Models

Cada tabela tem um `record` em `models/<modulo>/` (ex.: [Membro.java](src/main/java/mz/org/iasd/igreja/models/secretaria/Membro.java)):
os campos têm o nome do JSON e o tipo Java; `@ColunaBd` diz a coluna da base, se é obrigatório ao criar e se
a API o pode escrever. O catálogo (`models/catalogo/`) lê estas anotações, e as rotas-padrão (`controllers/base/`,
`repositories/base/`) usam-no: o model é a descrição única da tabela.
Dinheiro é `BigDecimal` com `@JsonbNumberFormat("0.00")` (texto com 2 casas no JSON).

Os models e os enums são **gerados**; não se editam à mão. Para mudar uma tabela:

1. editar `database/gerador/defs.py` e criar a migração nova (ver CLAUDE.md, "Acrescentar ou alterar uma tabela");
2. `cd database/gerador && python3 gen_openapi.py` (contrato `api/openapi.yaml`);
3. `python ferramentas/gen_catalogo.py` (models e enums);
4. `./mvnw test`: o `ContratoTest` confirma que models, rotas e contrato coincidem.

## Escalas da igreja (F-ACT-03)

Como a escala de pregação em papel: a escala de um período, os sábados, e quem faz o quê em cada um.

1. `POST /v1/actividades/planos-escala` — título, período (ex.: IV trimestre), ancião e secretário que assinam;
2. `POST /v1/actividades/planos-escala/{id}/gerar-dias` — um dia por sábado do período;
3. `PATCH /v1/actividades/dias-escala/{id}` — grupo coral, departamento, ou um dia especial (`evento`: Simpósio,
   13.º sábado — sem lembretes);
4. `POST /v1/actividades/escalas` — `{escalaDiaId, funcao, membroId}` (PREGADOR, TRADUTOR, ACOMPANHANTE_VISITAS,
   ACOMPANHANTE_OFERTAS, ACOMPANHANTE_BOAS_VINDAS, ANCIAO_DO_DIA, DIACONO, …); a data e a igreja vêm do dia;
5. `PATCH /v1/actividades/planos-escala/{id}` `{"publicada": true}` — os membros passam a vê-la;
6. `GET /v1/actividades/escala-grelha?igrejaId=&planoId=` (`&formato=csv`) — a escala para imprimir ou afixar.

**Lembretes por SMS:** à quarta e à sexta, às 18:00, quem está escalado para o sábado seguinte (ou quem o
substitui) recebe um SMS. Só escalas publicadas, só quem tem telefone nos contactos e **consentimento
`CONTACTO_SMS`** registado; nunca duas vezes no mesmo dia. O envio usa o fornecedor de SMS do `.env`
(`MENSAGENS_MODO=http`, `SMS_URL`, `SMS_TOKEN`); sem ele as mensagens ficam na fila.

## Tarefas agendadas

`infraestrutura/tarefas/TarefasAgendadas` (Jakarta Concurrency, feature `concurrent-3.0`) chama todos os dias,
começando 2 minutos depois do arranque, funções da base (SECURITY DEFINER) que fazem a manutenção:

| Função | Para quê |
| --- | --- |
| `nucleo.fn_criar_particoes_log(3)` | partições mensais do log de auditoria, 3 meses à frente |
| `nucleo.fn_idempotencia_limpar()` | termina as `Idempotency-Key` com mais de 24 horas |
| `escola_sabatina.fn_anonimizar_visitantes()` | visitantes com mais de 12 meses ficam sem nome nem telefone (V15) |
| `nucleo.fn_limpar_sessoes()` | termina sessões, códigos de recuperação e bloqueios de login expirados (V16) |
| `actividades.fn_lembretes_escala()` | **de hora a hora**: à quarta e à sexta põe na fila os SMS das escalas de sábado (V17) |
| envio da fila de SMS | **a cada minuto** (com `MENSAGENS_MODO` consola ou http): envia e marca ENVIADA; erro → tenta de novo até 5 vezes |

Cada execução conta em `/metrics` (`tarefas_execucoes_total`, `tarefas_falhas_total`, `tarefas_ultimo_sucesso_segundos`,
`sms_enviados_total`, `sms_falhados_total`).

Com várias instâncias da API, `TAREFAS_ACTIVAS=false` nas que não as devem correr (são idempotentes).

## Desempenho das listagens (V18)

A API lista sempre por igreja e por ordem de id, com cursor (`?igrejaId=&limite=50&depois=`). Desde a V18
a coluna de igreja das 18 tabelas que crescem tem o índice `(igreja, id)`, e a página sai directamente do
índice. Medido com a carga de `database/tests/carga_*.sql` (300 igrejas, 45 mil membros, 453 mil
movimentos e 907 mil linhas), com RLS, como o tesoureiro de uma igreja:

| Listagem (página de 51) | Linhas lidas antes → depois | Tempo antes → depois |
| --- | --- | --- |
| movimentos, igreja com 5000 | 5000 → 51 | 5,7 → 2,4 ms |
| movimentos, igreja com 1500 | 1500 → 51 | 3,4 → 1,6 ms |
| linhas por fundo, igreja com 3000 | 3000 → 51 | 6,3 → 3,8 ms |

O mais importante é que o custo de uma página deixa de crescer com os anos de histórico da igreja. São
medições de consultas na base de dados, não um teste de carga da API (que continua por fazer: ver
`docs/AUDITORIA.md`).

## Produção e auditoria

- [docs/producao/README.md](docs/producao/README.md): variáveis obrigatórias (sem perfil `dev` a API recusa
  segredos de desenvolvimento), Nginx, monitorização (`/health/ready`, `/metrics`), backups, JVM.
- [docs/AUDITORIA.md](docs/AUDITORIA.md): defeitos encontrados, estado de cada um e condições para produção.

## Pendente

- Fornecedor de SMS: o envio está feito (`MENSAGENS_MODO=http`); falta escolher o fornecedor e, se o formato
  dele for outro, adaptar `EnvioMensagens.pedidoHttp`. Até lá, lembretes e recuperação de senha só no perfil `dev`.
- WhatsApp e e-mail (Fase 4).
- M-Pesa (`/v1/tesouraria/mpesa`, `/callback`) e PDF dos relatórios respondem 501 (Fase 4).
- Teste de carga (k6) antes da produção.
