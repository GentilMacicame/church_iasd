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
| Base de dados (PostgreSQL 16) | **Concluída e testada.** 91 tabelas, 6 schemas, migrações V1–V56 |
| Contrato da API | **Concluído.** `api/openapi.yaml` (444 caminhos, 616 operações) |
| API (Jakarta EE 10 / Java 21) | **Contrato inteiro ligado** (na raiz do repositório): auth, `/v1/eu`, CRUD genérico das 61 tabelas, as 29 vistas como relatórios, acções de negócio, escalas com lembretes por SMS, tarefas de manutenção, correcções da auditoria (`docs/AUDITORIA.md`). Testada contra PostgreSQL real (CI). Relatórios em `?formato=json|csv|pdf` (PDF com OpenPDF). Por fazer: M-Pesa (Fase 4), escolher o fornecedor de SMS, teste de carga |
| Frontend (React) | Em `web/`: secretaria (membros, livro, reuniões, mandatos com conselho e direcção, famílias, transferências, disciplina, relatório), tesouraria (entradas, saídas, despesas, contagens, depósitos à Missão, fecho, orçamento, reconciliação, contas, fundos e alvos), escalas, igrejas e acessos. Ver `web/README.md` |

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
scripts/db-reset.sh                           # base BD_NOME com V1–V56 (apaga-a se existir) — SÓ no PC
scripts/db-migrar.sh                          # servidor: aplica só as migrações que faltam (não apaga nada)
scripts/criar-papel-api.sh                    # utilizador da API (BD_UTILIZADOR / BD_SENHA)
scripts/db-test.sh                            # base BD_NOME_TESTE + testes 00–39 (tem de dar 40× ok)
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
5. **Migrações aplicadas não se editam.** Alteração = nova migração `V52__...sql`, `V53__...`.
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
  - Cada CHECK e cada único tem a frase em português no `COMMENT ON CONSTRAINT/INDEX` (V29; formato
    `"[campoJson] Mensagem"`). A API devolve-a em vez de "Valor não permitido". Restrição nova = COMMENT novo
    (o teste `15_mensagens_das_restricoes` falha se um CHECK ficar sem frase).
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
- Identificar por código fixo, nunca por nome (V32): perfis do sistema por `per_codigo` (ADMIN, PASTOR, ...; não muda,
  não se terminam), categorias por `cat_codigo` e permissões por `prm_codigo` (imutáveis depois de criados). O nome é só
  texto mostrado. Os ENUM (`tra_tipo = 'ENTRADA'`) não são nomes: guardam o identificador interno do valor.
- Super-administrador (V32): ninguém lhe altera as permissões pelo sistema (acesso total, estado, terminar), nem o
  próprio nem outro super-administrador; só a manutenção da base, sem utilizador na sessão.
- Painel geral (V30, `/v1/organizacao/painel-igrejas`): sem `igrejaId`, cada um recebe só as igrejas a que tem acesso
  (vistas `security_invoker`): pastor do distrito (`distrito.dst_pastor_usu_id`) → as do distrito; Associação → as suas.
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
  SQL/Flyway. Argon2id (password4j), JWT HS256 (java-jwt), PDF (OpenPDF), `java.util.logging`, JUnit 5 + Testcontainers
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
- Comprovativos (fotografias/PDF): `POST /v1/tesouraria/documentos/carregar` (o ficheiro no corpo, tipo verificado
  pelos primeiros bytes, até 5 MB) e `GET .../documentos/{id}/ficheiro`; a linha de `tesouraria.documento` (RLS) decide
  quem junta e vê. Ficheiros em `FICHEIROS_PASTA` (`infraestrutura/ficheiros/ArmazemFicheiros`, único sítio a mudar para S3).
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
- Ficha do membro (V33): cônjuge por `mem_conjuge_mem_id` (ligação recíproca feita pela base; quem já está ligado a outro
  não pode ser escolhido; `mem_nome_conjuge` só para quem não está no sistema). O baptismo anterior de um ex-membro é a
  linha de `baptismo` sem rebaptismo. Contacto `TELEFONE` = telemóvel (recebe SMS); `TELEFONE_FIXO` não recebe.
  Possíveis duplicados: `nucleo.fn_membros_parecidos` (`GET /v1/secretaria/membros-parecidos`) só avisa, não bloqueia.
- Actividades (V34): responsáveis além do principal em `actividade_responsavel` (membro da mesma igreja); conflitos de
  calendário com `actividades.fn_conflitos_actividade` / `fn_datas_alternativas` (`GET /v1/actividades/conflitos`): só
  avisam, a actividade grava-se se quem regista confirmar; programa anual e execução (previsto, material, despesas,
  saídas confirmadas) na vista `vw_actividades_execucao` (`GET /v1/actividades/programa?ano=`).
- Área pastoral (V35): a actividade é de um departamento da igreja (`act_ide_id`) OU do distrito pastoral (`act_dst_id`).
  `actividades.fn_acesso_distrito`: lêem-na as igrejas do distrito; cria/altera o pastor do distrito, quem tem a
  permissão na Associação, ou o super-administrador (um director de departamento não). Entra nos conflitos e no
  programa de cada igreja do distrito (`origem` = AREA_PASTORAL). Nas políticas "custom" do gerador, `{C}` = código da permissão.
- Decisões do plano (V36):
  - **Membro inactivo** = estado ACTIVO no livro sem presença na ES nem contribuição (dele ou da família) há 6 meses
    (`secretaria.fn_participacao_membros`, `GET /v1/secretaria/participacao`). É um indicador: o estado só muda por voto.
  - **"Cobrança duplicada"** = o dízimo do mesmo mês lançado em nome do membro e da família
    (`tesouraria.fn_contribuicoes_sobrepostas`): aviso com confirmação em Lançar entrada; não bloqueia.
  - Estado civil `NOIVO`. Viúvos e viúvas saem do estado VIUVO e do sexo.
  - **Reavivamento** = fundo próprio da igreja + alvo por ano; `tesouraria.fn_alvo_sugerido` sugere o alvo do ano
    anterior + 5% (ajustável); o arrecadado mês a mês em `vw_fundo_mensal`.
- Comunicados (V37, `/v1/nucleo/comunicados`, `comunicados-igrejas`): um emissor — igreja, distrito pastoral ou
  Associação (`chk_cmc_emissor`); destinatários = as igrejas escolhidas ou, sem linhas, todas as do emissor. Publica
  `nucleo.fn_comunicado_emissor` (igreja: a permissão nela; distrito: o pastor; Associação: perfil lá; rascunhos só para
  quem edita); lê `fn_comunicado_para_mim` (publicado, em vigor, liderança das igrejas destinatárias ou, se MEMBROS, o
  membro). Nas políticas, nunca usar `criado_por` para dar acesso de escrita: o trigger preenche-o antes da verificação.
- Dashboard por período (V38, `GET /v1/organizacao/painel-periodo?inicio=&fim=`, `organizacao.fn_painel_periodo`): por igreja
  visível, membros (ACTIVO), activos/inactivos (V36), dízimos, ofertas (as outras entradas sem dízimo nem reavivamento),
  reavivamento (fundo do tipo `REAVIVAMENTO`, próprio da igreja), contribuintes (fidelidade = contribuintes ÷ membros; o
  contribuinte conta na igreja do membro, o dinheiro na igreja onde foi lançado), entradas e perdas de membros.
- Santa Ceia (V39, `/v1/actividades/santas-ceias`, histórico em `santa-ceia-historico` / `vw_santa_ceia`): uma por igreja e
  dia; REALIZADA exige homens, mulheres e visitantes e só depois do dia; a hora é texto `hh:mm` (a API não tem tipo TIME).
- Família (V40): `mem_parentesco` (CHEFE, CONJUGE, FILHO, PAI_MAE, IRMAO, NETO, OUTRO) em relação ao chefe; um só chefe por
  família; mudar de família ou sair limpa o parentesco (trigger).
- Dados confidenciais (V41): `secretaria.disciplina.dsc_motivo` não tem SELECT para app_igreja; grava-se como antes e lê-se
  só por `secretaria.fn_disciplina_motivo` (`GET /v1/secretaria/disciplinas/{id}/motivo`), que regista a consulta em
  `nucleo.acesso_confidencial` (lêem o pastor e a Associação). No catálogo, `SO_ESCRITA` (defs.py) → `@ColunaBd(leitura =
  false)`: fora dos SELECT e do JSON. O log de auditoria guarda só "(confidencial: alterado)". P0002 → 404.
- Tesouraria (V42): conta `FUNDO_MANEIO` (como o caixa, nunca da Missão; repõe-se por transferência, gasta-se com saídas);
  `tesouraria.contagem_participante` (`/v1/tesouraria/participantes-contagem`: membro da igreja da contagem, função
  TESOUREIRO/ESCOLA_SABATINA/DIACONO/ANCIAO/OUTRO); o SMS do recibo leva o resumo por fundo (`nucleo.fn_texto_mt` formata
  "1 400,00") e `ntf_chave = 'recibo:<id>'` (um SMS por recibo). Reenviar uma falhada = PATCH estado PENDENTE, tentativas 0.
  Valor novo de enum (ALTER TYPE ADD VALUE): na mesma migração só se compara como `::text`.
- Membro único (V43): `nucleo.fn_membro_existente` (SECURITY DEFINER, todas as igrejas) = mesmo documento (≥ 5 caracteres,
  só letras e algarismos) ou mesmo nome completo (`nucleo.fn_nome_comparavel`: sem acentos nem espaços a mais) e mesma data
  de nascimento; de igrejas que o utilizador não vê devolve só o nome e a igreja. O trigger `trg_mem_05_unico` recusa o
  segundo registo (ao inserir e ao mudar nome, data, documento ou end_date). `membros-parecidos` traz `existe` e `igreja`
  (`membroId` nulo fora das igrejas visíveis). O frontend começa o registo pela procura (`/membros/novo`), a ficha é
  `/membros/novo/ficha`. A transferência não é afectada (muda `mem_igr_id` no mesmo registo).
- Contagem (V43): para passar a CONFERIDA tem de ter participantes TESOUREIRO, ESCOLA_SABATINA e DIACONO; depois de
  conferida os participantes não mudam. P0001 com `USING COLUMN` → o erro da API leva o `campo` (TradutorErrosSql).
- Escala e programação do dia (V44): funções novas em `funcao_escala_t` (APRESENTADOR_ES, APRESENTADOR_CULTO, SERMAO_CRIANCA,
  ORACAO_INICIAL, ORACAO_FINAL, APRESENTADOR_JA, MEDITACAO_JA; PREGADOR mostra-se "Sermão principal"); `eds_fam_id` = família
  da Escola Sabatina no dia. `actividades.programa_dia/parte/item` (`/v1/actividades/programas-dia`, `partes-programa`,
  `itens-programa`); `escala` liga parte/item a uma função (ou FAMILIA_ES) e `fn_programa_preencher` põe lá o escalado;
  `fn_programa_preparar` (POST `programas-dia/preparar`) cria do modelo ou copia outro dia. Permissões = as da escala.
  O gerador reescreve `api/openapi.yaml`: mudanças ao contrato fazem-se em `database/gerador/gen_openapi.py`.
- Escalas da ES e da JA (V45): `escala_plano.epl_tipo` (CULTO, ESCOLA_SABATINA, JA); `actividades.escala_coluna` (prefixo
  `ecn`; `ecl` é a classe da ES) = colunas que cada igreja define (nome, ordem, MEMBRO ou FAMILIA); a escala ganha `esc_ecn_id`
  e `esc_fam_id` (membro ou família, `chk_esc_quem`; função OUTRA nas colunas); trigger `fn_esc_coluna`. Partes e itens da
  programação ligam-se a colunas (`ecn_id`). SMS das colunas com o nome da coluna.
- Fundo de construção (V45): `tipo_fundo_t` CONSTRUCAO (fundo próprio da igreja); a contagem tem `cnu_construcao`
  (conferida à parte em `vw_contagem_conferencia`). Lançar entrada na igreja local: só dízimo, oferta e ofertas especiais.
- Procura de membros (V45): `nucleo.fn_nome_fonetico` (sem acentos, y/i, z/s, k/c, w/u, ph/f, h mudo, letras dobradas);
  `fn_membros_parecidos` com o nome trocado, mesmo apelido com a mesma data e o telemóvel (7.º parâmetro). O registo abre
  a janela `DialogoRegistarMembro` (`/membros?registar=1`), com a data de nascimento obrigatória.
- `comum/Nomes.java` (`TABELA_POR_PREFIXO`): acrescentar o prefixo de cada tabela nova, senão os erros dão o campo errado.
- Painéis (V46): `organizacao.vw_painel_membros` (`GET /v1/organizacao/painel-membros`) = por igreja visível, sexo, idades,
  estado civil e sem família. "Membros" = no livro como ACTIVO; "activos" = desses, com participação nos últimos 6 meses
  (V36); "inactivos" = o resto. O Início de cada igreja usa os mesmos números (painel-periodo filtrado à igreja).
- Escola Sabatina (V47): `presenca.epr_oferta` = oferta de cada aluno na chamada (o PUT `.../presencas` aceita `oferta`);
  `escola_sabatina.meta_individual` (`emt`, aluno matriculado; o trigger recalcula `ect_alvo_oferta_sabado` = soma ÷ sábados);
  `vw_metas_alunos` / `vw_metas_classes` (`/v1/escola-sabatina/metas-alunos`, `metas-classes`); `semana_especial` (`ese`:
  ORACAO, FAMILIA, EVANGELISMO, JOVENS, MORDOMIA, OUTRO) com alerta 14 dias antes. Permissões = as de classe_trimestre
  (o secretário da ES só lê; definem o director da ES e o administrador).
- Área pastoral fora da igreja local: o pastor do distrito (`dst_pastor_usu_id`) tem as permissões de PASTOR em todas as
  igrejas do distrito (`fn_igrejas_com_permissao`), sem `usuario_igreja`. `GET /v1/eu` traz `distritos` (id, nome, igrejas);
  a sessão do frontend tem o contexto do distrito (`distrito`, `escolherDistrito`): menu próprio (Painel do distrito,
  Programa da área pastoral, Comunicados) e a página inicial é `PaginaPainelDistrito` (Painel geral fixo no distrito +
  acompanhamento das actividades por igreja).
- Acompanhamento das actividades (V48): `act_motivo_cancelamento` obrigatório ao cancelar (trigger `fn_act_cancelar`);
  `vw_actividades_execucao` com `motivo_cancelamento` e `actualizada_em`. Componente `actividades/Acompanhamento.tsx`
  (realizadas, atrasadas = planeadas com a data passada, canceladas, orçamento; comparação por departamento ou igreja).
- Reavivamento por pessoa (V49): `tesouraria.quota_reavivamento` (prefixo `qrv`, só as quotas ajustadas à mão) e
  `vw_reavivamento_pessoas` (o alvo do fundo REAVIVAMENTO do ano repartido igualmente pelos membros activos e pelas
  crianças; as ajustadas ficam fora e as outras repartem o resto). Rotas `quotas-reavivamento` e `reavivamento-pessoas`.
  Também o tipo de documento `CARTAO_ELEITOR`. Os fundos `ES_MISSOES`, `ES_13_SABADO` e `OFERTA_MISSIONARIA` não se mostram
  no frontend (`FUNDOS_OCULTOS`): contam dentro de "Ofertas".
- Extractos (V50): `percentagem_departamento` (dpp, a parte de cada departamento no ano, soma ≤ 100%),
  `transferencia_departamento` (tdp) e `adiantamento` (adt, com prestação de contas). Funções `fn_extracto_departamentos`
  e `fn_extracto_fundos(igreja, inicio, fim)` (SECURITY INVOKER), rotas `extracto-departamentos` e `extracto-fundos`.
  Doação distribuída = parte da igreja nas entradas sem departamento (OFERTA_COMBINADA e ORCAMENTO_LOCAL) × % do ano.
- V51: `quota_escalao_reavivamento` (rqe, quota fixa por ano para adultos e/ou crianças; a quota de cada pessoa é a
  ajustada → a do escalão → a automática; coluna `origem` na vista) e `santa_ceia_acompanhante` (sca, diáconos).
- Fluxos de aprovação (V54, `nucleo.fluxo_aprovacao` fap, `fluxo_etapa` fae, `aprovacao` apv, `aprovacao_decisao` apd): cada
  DESPESA, SAIDA (sem despesa, e estornos), CONTAGEM (conferência), ORCAMENTO, ADMISSAO_MEMBRO e REMOCAO_MEMBRO segue etapas por
  ordem; cada etapa é decidida por um PERFIL, por quem tem uma PERMISSAO, ou por um ORGAO (voto numa reunião desse tipo;
  a decisão é o resultado do voto). `fae_outra_pessoa`: nem quem pediu nem quem já decidiu outra etapa. O fluxo escolhe-se por
  valor (`fap_valor_minimo`, o maior que não passe o valor); com fluxo próprio da igreja para um processo, os modelos da
  Associação (`fap_igr_id` vazio) deixam de se aplicar a esse processo nela. Os processos iniciam-se por trigger (despesa
  submetida, saída pendente, contagem aberta, orçamento em rascunho, primeiro voto de admissão/remoção em `voto_membro`) e
  decidem-se com `nucleo.fn_aprovacao_decidir(apv, aprovar, vot, motivo, valor)` (POST `/v1/nucleo/aprovacoes/{id}/decidir`).
  `fn_decidir_despesa`, `fn_aprovar_saida`, `fn_aprovar_orcamento` e o PATCH do estado decidem a etapa em curso (o PATCH só
  se for a última e não for de um órgão). O objecto só muda quando a última etapa aprova (as guardas reconhecem-no por
  `nucleo.fn_aprovacao_concluida_agora`). Membros: o voto decide a etapa do órgão da reunião, pela ordem (Conselho → Igreja em
  reunião administrativa); o livro só aceita o movimento com um voto de um processo aprovado (`trg_mmb_12_fluxo`).
  Acompanhamento: `vw_aprovacoes` (etapa em curso, quem decide com os nomes, `pode_decidir`) e `vw_aprovacao_etapas`
  (`/v1/nucleo/acompanhamento-aprovacoes`, `etapas-aprovacao`). Frontend: `/aprovacoes` e `/aprovacoes/fluxos`.
  Modelos por defeito (V56, decisão do utilizador): **todo o dinheiro que sai dos fundos da igreja, seja qual for o valor**
  (despesa e saída sem despesa): tesoureiro aprecia → Conselho da Igreja vota → Igreja vota em reunião administrativa; o pastor
  e o ancião não aprovam despesas nem saídas (só registam os votos). Estorno (processo ESTORNO): pastor ou ancião confirma.
  Contagem: o tesoureiro. Orçamento, admissão e remoção: Conselho → Igreja em reunião administrativa.
- Fundo de maneio (V56): `cfi_valor_maneio` = o valor que a igreja definiu. `tesouraria.reposicao_maneio` (rpm): cada mês
  pede-se a reposição do gasto (valor definido − saldo, calculado pela base); se o fundo não foi usado não há reposição; se
  as despesas passaram o valor, repõe-se o gasto (mais do que o valor). Uma reposição pendente de cada vez, uma por mês
  (salvo rejeitada). O Conselho vota (processo MANEIO); depois `tesouraria.fn_repor_maneio(rpm, conta_origem)` (POST
  `/v1/tesouraria/reposicoes-maneio/{id}/repor`) faz a transferência. Só entra dinheiro no fundo de maneio por uma reposição
  aprovada (`trg_tra_91_maneio`, no COMMIT); as saídas do fundo de maneio não precisam de aprovação (fn_tra_soma_linhas).
- Colunas de vistas: a API tira o prefixo de 3 letras (`act_id` → `id`, `igr_id` → `id`!). Numa vista com mais de um
  id, dê nomes sem prefixo (`igreja_id`, `departamento_igreja_id`), senão os campos sobrepõem-se no JSON.
- Conselho e reuniões: os cargos do conselho (`car_conselho`) e a duração dos mandatos da igreja (`igr_mandato_anos`);
  o fim previsto de cada mandato é calculado (`ofi_fim_previsto`); vista `vw_conselho`. Mandatos (V31, `secretaria.mandato`,
  `/v1/secretaria/mandatos`): período com duração; mandatos activos da mesma igreja não se sobrepõem; cada oficial pertence a um
  mandato (`ofi_mdt_id`, copia início e fim e acompanha mudanças de datas) e a um órgão (`ofi_orgao` CONSELHO|DIRECCAO, por
  defeito do cargo). Reunião com presenças
  (`reuniao_presenca`), pontos da agenda e deliberações (`reuniao_ponto`); acta aprovada fecha presenças e pontos.
- Tabelas comuns (fundos gerais, plano de contas, calendário, lição da ES): só se mudam ao nível da Associação
  (`nucleo.fn_tem_permissao_comum`: perfil em `usuario_entidade` ou super-admin); ter a permissão numa igreja não chega (V23).
  Cada igreja tem as suas ofertas/projectos (`fun_igr_id`, 100% da igreja, só nos movimentos e despesas dela).
  "Outras despesas" (D9) exige `des_outra_categoria`. A contagem do numerário separa dízimos, ofertas, Escola Sabatina
  e outras (soma = total) e a conferência compara cada parte com o lançado.
- Transferências (V27): o directório de igrejas (`vw_directorio_igrejas`, só nome e localização) serve para escolher o
  destino; a igreja de destino vê a transferência com o nome do membro em `vw_transferencias` (`/v1/secretaria/transferencias-resumo`),
  embora a RLS lhe esconda a ficha do membro até à conclusão.
- ES: três ofertas separadas (missões, 13.º sábado, despesas); relatório fechado só reabre com permissão.

## Testes e definição de pronto

Uma funcionalidade só está pronta quando:
- tem testes de integração contra PostgreSQL real com **um perfil autorizado e um não autorizado**
  para cada endpoint novo (o não autorizado recebe 403/404);
- os processos afectados (P-xx) têm teste ponta-a-ponta;
- `scripts/db-test.sh` dá 40× ok e os testes da API passam;
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
