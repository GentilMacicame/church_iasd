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
  migrations/             V1__base.sql … V15__perfis_proprios_e_manutencao.sql
  schema_igreja_v5.sql    script único original (= V1–V13 juntas, igual linha a linha); referência
  tests/                  testes SQL 00–04 e resultado esperado
  gerador/                defs.py (fonte do esquema) + gen.py, gen_openapi.py
api/openapi.yaml          contrato da API (gerado de defs.py)
pom.xml, src/             a API (Maven + Open Liberty)
ferramentas/              gen_catalogo.py (gera os models da API de defs.py)
scripts/                  db-reset.sh, db-test.sh, criar-papel-api.sql
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

```bash
# 1. Base de dados: PostgreSQL 16, migrações V1–V15 e o papel da API
docker compose up -d db
export PGHOST=localhost PGUSER=postgres PGPASSWORD=postgres
scripts/db-reset.sh                                                   # base "igreja"
scripts/db-test.sh                                                    # testes SQL (deve dar 5× ok)
psql -v senha="'mudar'" -d igreja -f scripts/criar-papel-api.sql      # papel api_igreja

# 2. Configuração: o Open Liberty lê src/main/liberty/config/server.env (não vai para o git)
cp .env.exemplo src/main/liberty/config/server.env                    # e mudar os segredos

# 3. API em modo de desenvolvimento (recompila ao gravar) em http://localhost:9080
./mvnw liberty:dev            # Windows: mvnw.cmd liberty:dev
```

Não é preciso instalar Maven nem o servidor: o `mvnw` e o plugin descarregam-nos.

## Testes

```bash
./mvnw test
```

- Unitários: nomes de campos, paginação, tradução de erros, JWT, Argon2id, conversões.
- `ContratoTest`: as rotas das classes `*Controller` são exactamente as operações do `openapi.yaml` e os
  campos de cada tabela são os do contrato; escreve `docs/ROTAS.md`.
- Integração (`BaseDadosTest`): aplica as migrações V1–V15 num PostgreSQL real e testa, sempre com o
  papel da API (nunca o dono): `set_config` por transacção, RLS, permissões dos 13 perfis, erros
  403/422/409, sessões e rotação do token, bloqueio de login, recuperação de senha, idempotência,
  CRUD com perfis, processos P-05 (relatório do sábado) e P-08 (saída avulsa).
  - com Docker: PostgreSQL 16 descartável (Testcontainers);
  - sem Docker: `BD_TESTE_URL=jdbc:postgresql://localhost:5432/postgres BD_TESTE_SENHA=... ./mvnw test`
    (cria a base `igreja_teste_api` e o papel `api_igreja_teste`);
  - a pasta das migrações vem de `-Dmigracoes.dir` (por defeito `database/migrations`).

## Ver as rotas

- **No browser:** com o servidor a correr, `http://localhost:9080/openapi/ui` (Swagger UI com o contrato,
  campos e exemplos; botão *Authorize* para colar o token de `POST /v1/auth/login`).
- **Numa lista:** [docs/ROTAS.md](docs/ROTAS.md) — as 403 rotas, com a classe e o método Java de cada uma e
  a permissão exigida. É regenerada pelo `ContratoTest` em cada `./mvnw test`.
- **No código, num só ficheiro:** [Rotas.java](src/main/java/mz/org/iasd/igreja/Rotas.java) — todos os
  caminhos, por módulo. Os `*Controller` usam estas constantes no `@Path` (`@Path(Rotas.Secretaria.MEMBROS)`);
  para mudar um endereço, muda-se ali.

## Estrutura

```
src/main/java/mz/org/iasd/igreja/
├── AplicacaoRest.java                 raiz JAX-RS
├── Rotas.java                         TODAS AS ROTAS da API, por módulo
├── controllers/<modulo>/              CONTROLLERS (JAX-RS): recebem o pedido HTTP e respondem
│                                      secretaria/MembrosController, tesouraria/TransacoesController, ...
├── models/<modulo>/                   MODELS: um record por tabela (secretaria/Membro, tesouraria/Transacao, ...) · GERADO
├── models/tipos/                      enums iguais aos tipos do PostgreSQL (EstadoMembro, Sexo, ...) · GERADO
├── services/<modulo>/                 operações com vários passos (TransacoesService, RelatoriosSabadoService)
├── repositories/<modulo>/             SQL próprio (AuthRepository, EuRepository)
├── config/                            Configuracao (MicroProfile Config), Json (JSON-B)
├── infraestrutura/                    técnico, sem regras de negócio
│   ├── bd/                            ExecutorTransaccao (BEGIN + set_config + COMMIT), @Transaccional,
│   │                                  @Idempotente (Idempotency-Key), UnidadeDeTrabalho
│   ├── erros/                         formato {erro, mensagem, campo, pedidoId}; SQLSTATE → HTTP
│   ├── seguranca/                     JWT, Argon2id, filtro Authorization: Bearer, @Publico
│   └── mensagens/                     SMS/WhatsApp (Fase 4)
├── comum/                             Nomes (coluna ⇄ campo), Paginacao, Dinheiro, Sql
└── crud/                              motor partilhado pelos controllers
    ├── BaseLeituraController/BaseTabelaController   rotas-padrão herdadas (listar, ler, criar, alterar, terminar, reactivar)
    ├── BaseRelatoriosController, Relatorio          relatórios lidos das vistas (JSON ou CSV)
    ├── TabelaRepository                            SQL das operações-padrão (só parâmetros ?)
    └── TabelaBd/ColunaBd/TipoBd, LeitorModelos      anotações dos models e leitura do catálogo
```

Módulos: auth, eu, nucleo, organizacao, secretaria, escolasabatina, tesouraria, actividades, pagamentos,
comunicacao.

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
a API o pode escrever. O motor `crud/` lê estas anotações, por isso o model é a descrição única da tabela.
Dinheiro é `BigDecimal` com `@JsonbNumberFormat("0.00")` (texto com 2 casas no JSON).

Os models e os enums são **gerados**; não se editam à mão. Para mudar uma tabela:

1. editar `database/gerador/defs.py` e criar a migração nova (ver CLAUDE.md, "Acrescentar ou alterar uma tabela");
2. `cd database/gerador && python3 gen_openapi.py` (contrato `api/openapi.yaml`);
3. `python ferramentas/gen_catalogo.py` (models e enums);
4. `./mvnw test`: o `ContratoTest` confirma que models, rotas e contrato coincidem.

## Tarefas diárias

`infraestrutura/tarefas/TarefasAgendadas` (Jakarta Concurrency, feature `concurrent-3.0`) chama todos os dias,
começando 2 minutos depois do arranque, funções da base (SECURITY DEFINER) que fazem a manutenção:

| Função | Para quê |
| --- | --- |
| `nucleo.fn_criar_particoes_log(3)` | partições mensais do log de auditoria, 3 meses à frente |
| `nucleo.fn_idempotencia_limpar()` | termina as `Idempotency-Key` com mais de 24 horas |
| `escola_sabatina.fn_anonimizar_visitantes()` | visitantes com mais de 12 meses ficam sem nome nem telefone (V15) |

Com várias instâncias da API, `TAREFAS_ACTIVAS=false` nas que não as devem correr (são idempotentes).

## Pendente

- Envio real de SMS/WhatsApp (Fase 4); hoje, com `MENSAGENS_MODO=consola`, o código aparece no log.
- M-Pesa (`/v1/pagamentos/mpesa`, `/callback`) e PDF dos relatórios respondem 501 (Fase 4).
- CI e testes HTTP ponta-a-ponta (pedido → servidor → base de dados).
