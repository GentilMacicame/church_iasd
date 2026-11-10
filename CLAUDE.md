# CLAUDE.md — Sistema de Gestão da Igreja Adventista

Sistema de gestão para igrejas locais da Igreja Adventista do Sétimo Dia e para a respectiva
Associação/Missão (Moçambique): secretaria (livro de membros), Escola Sabatina, tesouraria,
actividades, pagamentos M-Pesa e mensagens.

**Língua do projecto: português (de Moçambique / norma europeia).** Código de domínio, nomes de
tabelas, colunas, endpoints, mensagens de erro, textos da interface, commits e comentários em
português. Termos técnicos genéricos (controller, service, hook) podem ficar em inglês.

## Estado actual

| Parte | Estado |
| --- | --- |
| Base de dados (PostgreSQL 16) | **Concluída e testada.** 61 tabelas, 6 schemas, migrações V1–V21 |
| Contrato da API | **Concluído.** `api/openapi.yaml` (299 caminhos, 417 operações) |
| API (Jakarta EE 10 / Java 21) | **Contrato inteiro ligado** (na raiz do repositório): auth, `/v1/eu`, CRUD genérico das 61 tabelas, as 29 vistas como relatórios, acções de negócio, escalas com lembretes por SMS, tarefas de manutenção, correcções da auditoria (`docs/AUDITORIA.md`). Testada contra PostgreSQL real (CI). Por fazer: M-Pesa e PDF (Fase 4), escolher o fornecedor de SMS, teste de carga |
| Frontend (React) | **Iteração 1 feita** em `web/`: Design System, entrar, Início, Membros (lista, ficha, registo). Ver `web/README.md` |

Especificação completa: `docs/especificacao.md` (Markdown, gerado do Word em
`docs/Especificacao_Sistema_Igreja_v1.1.docx`). Funcionalidades têm IDs `F-SEC-05`, processos
`P-01`…`P-13`, requisitos `RNF-xx`. Cita estes IDs em commits, PRs e testes.
Modelo de dados navegável: `docs/modelo_dados.html`.

## Estrutura do repositório

```
CLAUDE.md                 este ficheiro
README.md                 arranque rápido para pessoas
docker-compose.yml        PostgreSQL 16 local
scripts/db-reset.sh       recria a base a partir das migrações
scripts/db-test.sh        recria a base de testes e compara os testes SQL com o esperado
database/
  migrations/             V1__base.sql … V16__correccoes_da_auditoria.sql  (Flyway: V<n>__<nome>.sql)
  tests/                  00–04 testes SQL; esperado/*.out = resultado de referência; carga_*.sql
  gerador/                defs.py (fonte do esquema) + gen.py, seguranca_gen.py, gen_openapi.py
api/openapi.yaml          contrato da API (fonte de verdade para API e frontend)
pom.xml, mvnw, src/       API Jakarta EE (Maven + Open Liberty); estrutura no README
  src/main/java/mz/org/iasd/igreja/Rotas.java   todas as rotas da API, por módulo
ferramentas/gen_catalogo.py  gera os models da API (src/.../models/) a partir de defs.py
scripts/                  db-reset.sh, db-test.sh, criar-papel-api.sh, backup-bd.sh (lêem o .env)
web/                      (React + Vite a criar aqui)
docs/                     especificação, modelo de dados, ROTAS.md (gerado pelos testes da API)
.claude/commands/         comandos do projecto (/nova-tabela, /novo-endpoint, /rever)
```

## Comandos

```bash
cp .env.exemplo .env                          # TODA a configuração (base de dados e API) está só no .env
docker compose up -d db                       # PostgreSQL 16 (porta e administrador do .env)
scripts/db-reset.sh                           # base BD_NOME com V1–V21 (apaga-a se existir) — SÓ no PC
scripts/db-migrar.sh                          # servidor: aplica só as migrações que faltam (não apaga nada)
scripts/criar-papel-api.sh                    # utilizador da API (BD_UTILIZADOR / BD_SENHA)
scripts/db-test.sh                            # base BD_NOME_TESTE + testes 00–08 (tem de dar 9× ok)
scripts/gerar-schema-completo.sh              # database/schema_completo.sql (todas as migrações num ficheiro)
ACTUALIZAR=1 scripts/db-test.sh               # aceitar novo resultado esperado (só se a mudança for intencional)

cd database/gerador && python3 gen.py         # regenera o esquema inteiro em gerador/out/ (não toca em migrations/)
cd database/gerador && python3 gen_openapi.py # regenera api/openapi.yaml (requer pyyaml)
python3 ferramentas/gen_catalogo.py           # regenera os models e enums da API a partir de defs.py

./mvnw liberty:dev                            # API em http://localhost:9080 (Swagger em /openapi/ui)
./mvnw test                                   # testes da API; integração: Docker ou BD_TESTE_URL + BD_TESTE_SENHA
```

Os testes SQL 01–03 provocam erros **de propósito** (cada `ERROR` é uma regra ou permissão a
recusar algo). O teste passa quando a saída é igual a `tests/esperado/`. Se a saída mudar, lê o
diff: um `ERROR` que desapareceu é quase sempre uma regra partida.

## Regras invioláveis

1. **A base de dados decide.** Regras de negócio e permissões estão no PostgreSQL (triggers, RLS,
   funções). A API e o frontend **não** as reimplementam nem tentam contorná-las. A API pode
   validar formato (Bean Validation) para dar mensagens melhores, nunca regras de negócio.
2. **Nada se apaga.** Não há `DELETE` nem `TRUNCATE` (triggers bloqueiam, sem GRANT). "Apagar" é
   terminar: `UPDATE ... SET <pfx>_end_date = now()` (endpoint `POST .../{id}/terminar`).
   Dinheiro confirmado nunca se altera: corrige-se com estorno.
3. **Nunca ligar como dono das tabelas.** O dono ignora RLS. A API usa `api_igreja`
   (`LOGIN IN ROLE app_igreja`). Testes de permissões também correm com `SET ROLE app_igreja`.
4. **Cada pedido = uma transacção com o utilizador identificado:**
   ```sql
   BEGIN;
   SELECT set_config('app.usuario_id', $1, true);   -- true = só nesta transacção (PgBouncer)
   -- ... trabalho ...
   COMMIT;
   ```
   Sem isto a base não devolve linhas e recusa escritas. Implementado **uma vez** em
   `bd/ExecutorTransaccao` + `@Transaccional` (interceptor CDI), nunca em cada endpoint. Nunca `set_config(..., false)` na API.
5. **Migrações aplicadas não se editam.** Alteração = nova migração `V22__...sql`, `V23__...`.
6. **SQL só parametrizado.** Nenhum texto do pedido concatenado em SQL (JDBC `PreparedStatement` com `?`).
7. **Segredos fora do código** (`.env`, nunca commitado).

## Convenções da base de dados

- 6 schemas: `nucleo` (inclui a fila de mensagens), `organizacao`, `secretaria`, `actividades`,
  `escola_sabatina`, `tesouraria` (inclui M-Pesa e bancos). Até à V18 havia também `pagamentos` e
  `comunicacao`. O `search_path` de `api_igreja` inclui todos.
- Listagens por igreja: a coluna de igreja tem o índice `(igreja, id)` (`idx_<pfx>_igr_pagina`), gerado
  pelo `gen.py`; a página de 50 sai do índice, sem ler o histórico todo da igreja (V18).
- **Cada tabela tem um prefixo de 3 letras** e todas as colunas começam por ele:
  `membro` → `mem_`, `transacao` → `tra_`, `transacao_linha` → `tli_`, `igreja` → `igr_`.
  - PK: `<pfx>_id` (INT identity; BIGINT nas tabelas grandes, ex. `tra_id`).
  - FK: `<pfx>_<pfxdestino>_id` ou `<pfx>_<papel>_<pfxdestino>_id`
    (`mem_igr_id`, `ect_professor_mem_id`, `tra_aprovado_por_usu_id`).
  - Colunas-padrão em **todas** as tabelas (preenchidas por trigger, não pela API):
    `<pfx>_estado`, `<pfx>_criado_em`, `<pfx>_criado_por`, `<pfx>_modificado_em`,
    `<pfx>_modificado_por`, `<pfx>_end_date`.
  - Únicos são parciais: `... WHERE <pfx>_end_date IS NULL`.
- Dinheiro: `DECIMAL(12,2)`/`DECIMAL(14,2)`. Datas-hora: `TIMESTAMPTZ`.
- Enums em `nucleo` (`estado_membro_t`, `tipo_movimento_t`, ...).
- Lista de prefixos e descrição de cada tabela/coluna: `database/gerador/defs.py` e
  `COMMENT ON` nas migrações.

### Acrescentar ou alterar uma tabela

1. Editar `database/gerador/defs.py` (tabela no módulo certo; regras em `gerador/sql/<schema>_regras.sql`).
2. `python3 gen.py` e copiar o SQL **só da parte nova** de `gerador/out/` para `database/migrations/V<n+1>__<nome>.sql`.
   Incluir: tabela, triggers-padrão (`fn_campos_padrao`, `fn_proibir_delete`), RLS + políticas,
   GRANT a `app_igreja`, permissões novas em `nucleo.permissao` e nos perfis.
3. `python3 gen_openapi.py` (actualiza o contrato) — confirmar o diff de `api/openapi.yaml` — e
   `python3 ferramentas/gen_catalogo.py` (model Java da tabela).
4. Teste em `database/tests/` (perfil autorizado + perfil não autorizado), `scripts/db-test.sh`.

Usa `/nova-tabela` para seguir este processo.

## Permissões (resumo)

- Códigos `<schema>.<tabela>.<ler|criar|alterar|terminar>` (236) + 9 acções de negócio:
  `secretaria.membro.validar`, `secretaria.transferencia_membro.emitir_carta`,
  `secretaria.transferencia_membro.aceitar`, `tesouraria.transacao.aprovar`,
  `tesouraria.despesa.aprovar`, `tesouraria.orcamento.aprovar`, `tesouraria.remessa.confirmar`,
  `escola_sabatina.relatorio_sabado.fechar`, `escola_sabatina.relatorio_sabado.reabrir`.
- 13 perfis: igreja — ADMIN, PASTOR, ANCIAO, SECRETARIO, TESOUREIRO, DIRECTOR_ES,
  SECRETARIO_ES, DIRECTOR_DEPARTAMENTO, MEMBRO; Associação — ADMIN_ASSOCIACAO,
  TESOUREIRO_ASSOCIACAO, SECRETARIO_ASSOCIACAO, INTEGRACAO. Matriz: Anexo A da especificação.
- Origem: `nucleo.usuario_igreja` (perfil numa igreja), `nucleo.usuario_entidade` (perfil numa
  Associação → todas as igrejas abaixo), pastor do distrito, o próprio membro (vê os seus dados),
  `usu_super_admin`.
- Ler/criar/alterar: RLS. Terminar e acções de negócio: triggers com `nucleo.fn_exigir()`.
- Segregação: quem cria uma saída não a aprova; ninguém altera os próprios perfis; não se dá um
  perfil com mais permissões do que as próprias.
- Linha que existe mas não é visível → a API responde **404**, não 403.
- `nucleo.fn_minhas_permissoes()` → `(codigo, igr_id)`; o frontend usa-a para menus e botões
  (`pode('tesouraria.transacao.aprovar', igrejaId)`). Esconder botões é UX, não segurança.

## Funções da base de dados que a API chama

| Função | Uso |
| --- | --- |
| `nucleo.fn_credenciais(login)` | Login: devolve `usu_id, senha_hash, estado` (a coluna da senha não é legível) |
| `nucleo.fn_login_bloqueado_ate(login)` / `fn_login_falhou(login)` | Bloqueio após 10 falhas (15 min) |
| `nucleo.fn_abrir_sessao(usu, refresh_hash, ip, navegador)` | Cria sessão; guardar só o hash do refresh token |
| `nucleo.fn_renovar_sessao(hash, novo_hash, ip, navegador)` | Devolve `(resultado, utilizador, sessao_id)`; `resultado` ∈ OK, INVALIDA, EXPIRADA, REUTILIZADA (reutilização termina todas as sessões) |
| `nucleo.fn_terminar_sessao(hash)` | Logout |
| `nucleo.fn_pedir_recuperacao(login, codigo_hash)` / `fn_redefinir_senha(login, codigo_hash, nova_hash)` | Recuperação; `fn_redefinir_senha` → OK, CODIGO_ERRADO, EXPIRADO |
| `nucleo.fn_idempotencia_obter(chave)` / `fn_idempotencia_guardar(...)` | Header `Idempotency-Key` |
| `nucleo.fn_minhas_permissoes()` | `GET /v1/eu` |
| `tesouraria.fn_aprovar_saida(tra)` | Aprovar saída/estorno |
| `tesouraria.fn_decidir_despesa(des, aprovar, valor, motivo)` | Aprovar (pode reduzir valor) ou rejeitar |
| `tesouraria.fn_aprovar_orcamento(orc, vot)` / `fn_confirmar_remessa(rem)` | |
| `escola_sabatina.fn_ligar_ofertas(ers, tra)` | Liga as ofertas do relatório do sábado à transacção |
| `actividades.fn_gerar_dias_escala(epl, dia_semana)` | Elaborar a escala: um dia por sábado do período |
| `actividades.fn_lembretes_escala()` | Tarefa horária: SMS à quarta e à sexta para quem está escalado no sábado |
| `nucleo.fn_notificacoes_reservar(n)` / `fn_notificacao_resultado(id, ok, erro)` | Envio da fila de SMS (tarefa da API) |

No `openapi.yaml`: `x-permissao` = permissão exigida, `x-funcao-bd` = função chamada,
`x-vista` = vista lida. Segue-os.

## Convenções da API

- Stack: **Java 21, Jakarta EE 10** (o nome actual do Java EE: JAX-RS, CDI, JSON-B, Bean Validation)
  + MicroProfile Config, servidor **Open Liberty**, Maven (`./mvnw`). Acesso à base com **JDBC puro**
  (driver PostgreSQL, datasource `jdbc/igreja`) — sem JPA/ORM nem migrações próprias: as migrações são
  SQL/Flyway. Argon2id (password4j), JWT HS256 (java-jwt), `java.util.logging`, JUnit 5 + Testcontainers
  (PostgreSQL real) para testes. Tarefas agendadas: Jakarta Concurrency (`ManagedScheduledExecutorService`).
- Organização (`mz.org.iasd.igreja`): `controllers/<modulo>/*Controller` (JAX-RS, `@RequestScoped
  @Transaccional`, caminhos em `Rotas.java`) → `services/<modulo>/*Service` (vários passos) →
  `repositories/<modulo>/*Repository` (JDBC, recebe a `Connection` de `UnidadeDeTrabalho.ligacao()`).
  `models/<modulo>/`: um `record` por tabela, igual ao schema do contrato (`@TabelaBd`/`@ColunaBd`),
  **gerado** por `ferramentas/gen_catalogo.py` a partir de `defs.py` — não editar à mão. Nunca abrir ligações à mão.
  O comum a todas as tabelas fica em `base/` de cada camada: `controllers/base/` (as 6 rotas-padrão,
  relatórios), `repositories/base/` (`TabelaRepository`, `Relatorio`, `Conversao`), `models/catalogo/` (anotações e
  catálogo). Um controller de tabela só diz a rota e o model; acrescenta métodos para as acções próprias.
- POST que cria dinheiro: `@Idempotente` e devolver `Response`. Endpoints sem token: `@Publico`.
- Caminhos: `/v1/<modulo-com-hifen>/<recurso-plural>` (`/v1/escola-sabatina/relatorios-sabado`).
- Campos JSON em camelCase **sem prefixo**: `mem_data_nascimento` → `dataNascimento`,
  `mem_igr_id` → `igrejaId`, `ect_professor_mem_id` → `professorMembroId`. O mapeamento
  tabela→recurso está em `database/gerador/nomes.py`; os nomes exactos estão no `openapi.yaml`.
- Sem `DELETE`. `POST /{id}/terminar` e `POST /{id}/reactivar`.
- Paginação por cursor: `?limite=50&depois=<cursor>` (máx. 200). Resposta `{ dados, proximo }`.
- Dinheiro em JSON é **string** com 2 casas: `"650.00"`. Nunca `number`/float.
- Datas ISO 8601 com fuso.
- `Idempotency-Key` (UUID) obrigatório em POST que criam dinheiro (transacções, remessas, M-Pesa).
- Configuração: num só sítio, o `.env` da raiz (o Maven usa-o como `server.env` do Liberty; os scripts com
  `scripts/carregar-env.sh`; o docker compose e os testes lêem-no). Nunca repetir valores da base noutros
  ficheiros. Perfil `dev` (`MP_CONFIG_PROFILE=dev`) só no PC; em produção não há segredos
  por defeito e a API recusa arrancar com os de desenvolvimento (`config/Configuracao`). Endpoints públicos
  com limite de pedidos (`LimitadorPedidos`, 429); cálculo de senhas fora de transacções (`ControloSenhas`).
  Cada transacção tem `statement_timeout`/`lock_timeout` e confirma a sessão do token (`fn_sessao_activa`).
  Produção: `docs/producao/README.md`; auditoria: `docs/AUDITORIA.md`.
- Auth: access token JWT 15 min (header `Authorization: Bearer`); refresh token 30 dias em cookie
  `HttpOnly; Secure; SameSite=Strict`, rodado em cada renovação.

### Erros

Formato: `{ "erro": "<codigo>", "mensagem": "<texto>", "campo": "<campo|null>", "pedidoId": "<uuid>" }`.
A `mensagem` dos erros de regra vem da base de dados, já em português — passa-a ao cliente tal e qual.

| SQLSTATE | HTTP | `erro` |
| --- | --- | --- |
| 42501 (insufficient_privilege, RLS) | 403 | `sem_permissao` |
| P0001 (RAISE EXCEPTION) | 422 | `regra_negocio` |
| 23514 check | 422 | `validacao` |
| 23505 unique | 409 | `duplicado` |
| 23503 foreign key | 422 | `referencia_invalida` |
| 23502 not null | 400 | `campo_obrigatorio` |
| 40001 / 40P01 | 503 (repetir a transacção até 3× antes) | `tentar_novamente` |

`campo`: extrair do nome da constraint/coluna e converter para o nome camelCase do JSON.
Nunca devolver stack traces nem SQL ao cliente.

## Convenções do frontend

- React 18 + Vite + TypeScript, TanStack Query, React Hook Form + Zod, React Router.
- Tipos e cliente gerados do `openapi.yaml` (`openapi-typescript` ou `orval`) — não escrever tipos à mão.
- PWA. O relatório do sábado da ES (P-05) funciona sem rede (IndexedDB + fila de envio com `Idempotency-Key`).
- Componente único `<Dinheiro>`: aceita "1 500,50", envia "1500.50", mostra "1 500,50 MT".
- Datas `dd/mm/aaaa` no ecrã. Textos num ficheiro de traduções (pt-MZ).
- Erros com `campo` → junto ao campo; sem `campo` → topo do formulário.
- Pensado para telemóvel Android em 3G: primeira carga < 300 KB, rotas com lazy loading.
- Acessibilidade WCAG 2.1 AA; alvos de toque ≥ 44 px.

## Regras de negócio que mais vão aparecer (detalhe na especificação, cap. 4)

- O estado do membro **só muda por movimento no livro de membros** (`movimento_membro`) com o voto
  que o autoriza. Admissão, transferência e remoção exigem voto em REUNIAO_REGULAR ou
  ASSEMBLEIA_ADMINISTRATIVA (a junta directiva só recomenda).
- Transferência: carta e aceitação com 2.ª leitura; carta válida 6 meses; membro sob censura não recebe carta.
- Censura: 1–12 meses; termina os cargos; menores exigem aviso aos pais.
- Tesouraria: transacção = cabeçalho + linhas por fundo (soma tem de bater). Fundos da Associação
  (dízimo, oferta missionária, ES missões, 13.º sábado) saem **só** como remessa. Saídas exigem
  aprovação por outra pessoa (ou despesa aprovada, ou ser remessa). Mês fechado bloqueia movimentos.
  Fundos repartidos (oferta combinada: 50% Missão, 50% igreja): a igreja só gasta a sua parte (`fn_fundo_disponivel`).
  No fim do mês deposita-se na conta da Missão 100% do dízimo e a parte da Missão nas ofertas (remessa, com o talão;
  pode haver remessa complementar no mesmo mês) e envia-se o relatório mensal com os recibos.
  Membros que pagam directamente na conta da Missão: entrada na conta marcada com `cfi_ent_id` (só entradas, só fundos
  da Missão, com a referência do comprovativo); conta como contribuição e como já remetido, não como saldo da igreja.
- ES: três ofertas separadas (missões, 13.º sábado, despesas); relatório fechado só reabre com permissão.

## Testes e definição de pronto

Uma funcionalidade só está pronta quando:
- tem testes de integração contra PostgreSQL real com **um perfil autorizado e um não autorizado**
  para cada endpoint novo (o não autorizado recebe 403/404);
- os processos afectados (P-xx) têm teste ponta-a-ponta;
- `scripts/db-test.sh` dá 9× ok e os testes da API passam;
- as mensagens de erro aparecem em português no ecrã;
- funciona em largura de telemóvel.

Mudanças em permissões, dinheiro ou no livro de membros **nunca** entram sem teste de perfil.

## Plano (especificação, cap. 10)

| Fase | Âmbito |
| --- | --- |
| **0 · Base** (começar aqui) | Monorepo (`api/`, `web/`), CI, Flyway, `docker compose`, unidade de trabalho com `set_config`, auth (login/renovar/sair/recuperar), `GET /v1/eu`, tradução de erros, paginação, idempotência, testes com Testcontainers para os 13 perfis |
| 1 · Secretaria | F-SEC-01…10, P-01…P-04 |
| 2 · Tesouraria | F-TES-01…15, P-06…P-10, P-12 |
| 3 · Escola Sabatina | F-ES-01…08, P-05 (offline) |
| 4 · M-Pesa e mensagens | F-PAG, F-COM, P-11 |
| 5 · Associação e piloto | F-ORG, F-NUC-06, relatórios, P-13 |

## Como trabalhar neste repositório

- Antes de implementar um recurso, lê o caminho no `openapi.yaml` e o processo P-xx relacionado.
- Se uma regra parecer faltar na base de dados, **não a implementes na API**: propõe uma migração
  nova e um teste SQL.
- Se o `openapi.yaml` e a base de dados divergirem, a base de dados vence; regenera o contrato.
- Commits pequenos, mensagem em português, com o ID: `F-TES-03: lançar entrada com linhas por fundo`.
- Não instales dependências novas sem necessidade clara; prefere as da stack acima.
