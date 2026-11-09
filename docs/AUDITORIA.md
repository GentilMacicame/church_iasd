# Auditoria técnica da API e da base de dados

**Data:** 2026-11-09 · **Âmbito:** API Jakarta EE (`src/`), configuração (`server.xml`,
`microprofile-config.properties`, `pom.xml`) e migrações V1–V15.

**Independência:** a auditoria e as correcções foram feitas pelo assistente que escreveu a maior parte do código,
por isso não é uma auditoria independente. Recomenda-se uma revisão humana externa antes da produção.

## Avaliação

| | Antes | Depois das correcções |
| --- | --- | --- |
| Classificação | **NOT READY FOR PRODUCTION** | **READY WITH CONDITIONS** (secção "Condições") |
| Testes contra PostgreSQL real | nenhum (0 de 23 correram) | 40 de integração + 5 testes SQL + 28 verificações HTTP de ponta a ponta |

Os testes contra a base real (C2) encontraram três defeitos que a leitura do código não tinha encontrado; o mais
grave fazia **todas as listagens responderem 500** (ver "Defeitos encontrados ao testar").

## Estado de cada defeito

| ID | Severidade | Defeito | Estado | Correcção e verificação |
| --- | --- | --- | --- | --- |
| C1 | CRITICAL | Segredo JWT por defeito, público, aceite em produção | Corrigido | Os segredos só existem no perfil `dev`; em produção a API recusa arrancar sem segredos ou com os de desenvolvimento (`Configuracao.verificar`, `ConfiguracaoTest`; verificado com o servidor). `BD_SENHA` sem valor por defeito. |
| C2 | CRITICAL | Nenhum teste contra a base real | Corrigido | 89 testes da API (40 de integração) e `db-test.sh` 5× ok contra PostgreSQL; `scripts/teste-ponta-a-ponta.py` (28 verificações HTTP); CI no GitHub (`.github/workflows/ci.yml`) com PostgreSQL 16 em cada push. |
| H1 | HIGH | Códigos de recuperação escritos no log | Corrigido | `consola` só no perfil `dev` (a API recusa arrancar com ele em produção). O envio real de SMS continua por fazer (Fase 4): até lá, a recuperação de senha não funciona em produção. |
| H2 | HIGH | Sem limite de pedidos; Argon2 sem limite de concorrência | Corrigido | `LimitadorPedidos` (por IP e por login: login, recuperar, redefinir, renovar → 429 + Retry-After); `ControloSenhas` (máximo de cálculos Argon2 em simultâneo → 503); Nginx com `limit_req`; limpeza diária de `bloqueio_login` (V16). Verificado de ponta a ponta. |
| H3 | HIGH | Hashes das senhas no log de auditoria | Corrigido | V16: `fn_log_auditoria` guarda só "(alterada)"; limpa os hashes já existentes. Verificado numa base com dados antigos e em `BaseDadosTest`. |
| H4 | HIGH | Ligações presas sob carga, sem timeouts | Mitigado | Argon2 fora da transacção; `statement_timeout` (30 s) e `lock_timeout` (5 s) em cada transacção; `connectTimeout`/`socketTimeout` no driver; pool configurável. **Falta o teste de carga** para dimensionar. |
| M1 | MEDIUM | Token de acesso válido depois de sair | Corrigido | V16 `fn_sessao_activa` verificada na mesma ida à base de cada pedido; sair, senha redefinida, roubo de token ou utilizador inactivo → 401 imediato. Verificado de ponta a ponta. |
| M2 | MEDIUM | Corrida na renovação da sessão | Corrigido | V16: `FOR UPDATE`; o mesmo token nos 10 s seguintes → `CONCORRENTE` (409, sem apagar o cookie); depois disso continua a ser roubo (`REUTILIZADA`). Testes SQL 03 e `BaseDadosTest`. |
| M3 | MEDIUM | Login distingue maiúsculas; recuperação não | Corrigido | V16: comparação sem maiúsculas em todo o lado e índice único `lower(usu_email)`. |
| M4 | MEDIUM | Relatórios cortados a 5000 linhas sem aviso | Corrigido | Headers `X-Relatorio-Truncado` e `X-Relatorio-Limite`. O frontend deve avisar e pedir um filtro. |
| M5 | MEDIUM | Injecção de fórmulas no CSV | Corrigido | `Csv.celula` neutraliza `= + - @` (sem mexer em números); `CrudTest`. |
| M6 | MEDIUM | Sem limite de tamanho do pedido | Corrigido | `LimiteCorpo` (413, também sem Content-Length); máximo de 20 000 linhas por extracto; Nginx `client_max_body_size`. |
| M7 | MEDIUM | Pesquisa de membros sem índice | Corrigido | V16: índice trigram (`pg_trgm`) para `?q=`. Ordenações por colunas sem índice continuam a depender do volume: medir no teste de carga. |
| M8 | MEDIUM | Corridas nas aprovações e nos recibos | Corrigido | V16: `FOR UPDATE` nas funções de aprovação; número de recibo com bloqueio por igreja e ano. |
| M9 | MEDIUM | Sem health check nem métricas | Corrigido | `/health/ready` (base de dados), `/health/live`, `/metrics` (JVM, pool, tarefas diárias); logs JSON (`LOG_FORMATO`); `X-Pedido-Id` do Nginx propagado. Alertas em `docs/producao/README.md`. |
| M10 | MEDIUM | Sem separação DEV/PROD; Swagger público | Corrigido | Perfil `dev` (MicroProfile Config); `/openapi`, `/metrics` e `/health` só na rede interna (Nginx). |
| L1 | LOW | X-Forwarded-For falsificável | Corrigido | Usa o último endereço (o do Nginx), e o Nginx substitui o header; `OrigemPedidoTest`. |
| L2 | LOW | Código morto e acoplamento | Corrigido | `Paginacao` só com o limite; `FuncoesBd` em vez de `TransacoesService.funcao`. |
| L3 | LOW | Idempotency-Key sem verificar o corpo | Corrigido | V16 guarda o SHA-256 do pedido; a mesma chave com outro corpo → 422. Verificado de ponta a ponta. |
| L4 | LOW | Sem HTTPS nem headers de segurança | Corrigido no Nginx | `docs/producao/nginx.conf.exemplo` (TLS, HSTS, nosniff, frame-deny). |
| L5 | LOW | Tabelas de sessão a crescer sem limpeza | Corrigido | V16 `fn_limpar_sessoes`, tarefa diária. |
| L6 | LOW | Dependências sem vigilância | Mitigado | Dependabot (Maven e Actions). Correr também um scanner de vulnerabilidades antes da produção. |

## Defeitos encontrados ao testar contra a base real

| Defeito | Severidade | Correcção |
| --- | --- | --- |
| Todas as listagens falhavam com `ORDER BY "igr_id" is ambiguous` (o SELECT repetia a coluna de ordenação e o id) | CRITICAL | `TabelaRepository.listar`: colunas extra com nome próprio e ORDER BY com o nome da tabela. Coberto por `paginacaoPorCursor`, `tesoureiroSoVeASuaIgreja` e pelo teste de ponta a ponta. |
| Conferência das ofertas da ES mostrava "Por lançar" a quem não vê a tesouraria (Director da ES), com as ofertas já lançadas e confirmadas | MEDIUM | V16: vista `vw_conferencia_ofertas` — relatório fechado é sempre "Conferido"; lançamento invisível → "Lançado (sem acesso à tesouraria)". |
| Teste de permissões com uma premissa errada (o tesoureiro vê famílias, por isso 403 e não 404) | — | Teste corrigido; 404 verificado com um perfil que não as vê. |

## Condições para produção

1. **Teste de carga** (k6) com a carga de `database/tests/carga_*.sql`: login, listagens e relatórios, em carga,
   stress, pico (sábado) e duração (8 h). Define `BD_POOL_MAX`, `SENHAS_CONCORRENCIA` e o número de instâncias.
   Nenhum número de utilizadores simultâneos está garantido sem ele.
2. **Backups com restauro testado** e PITR (`docs/producao/README.md`).
3. **Nginx e variáveis de produção** como em `docs/producao/`.
4. **CI verde** no GitHub (os testes locais correram em PostgreSQL 18; a CI usa o 16 da produção).
5. **Fase 4** concluída ou fora do âmbito do lançamento: M-Pesa, SMS (incluindo a recuperação de senha) e PDF
   respondem 501.
6. Revisão de segurança humana independente.
