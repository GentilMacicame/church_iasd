# Pôr a API em produção

Lista do que tem de estar feito antes de abrir o sistema às igrejas. Os pontos marcados com um código
(C1, H2, …) vêm da auditoria técnica ([../AUDITORIA.md](../AUDITORIA.md)).

## 1. Base de dados

- PostgreSQL 16, com as migrações aplicadas **antes** de instalar a versão nova da API
  (`database/migrations`, por ordem; a API desta versão precisa da V16).
- O utilizador da API: `scripts/criar-papel-api.sh` (BD_UTILIZADOR / BD_SENHA do `.env`, membro de `app_igreja`, nunca o dono das tabelas).
- `scripts/db-test.sh` numa cópia da base: tem de dar **8× ok**.
- **Backups (continuidade):**
  - PITR: arquivo contínuo de WAL (ex.: pgBackRest ou o serviço gerido do fornecedor), retenção mínima de 30 dias;
  - cópia lógica diária com `scripts/backup-bd.sh` para outro servidor;
  - **testar o restauro** uma vez por trimestre numa base nova (o backup só vale se o restauro funcionar).
- Réplica de leitura/standby recomendada: a base é o único ponto de falha do sistema.

## 2. Variáveis de ambiente da API

Num só ficheiro: o `.env` (modelo em `.env.exemplo`), que no servidor é o `server.env` do Open Liberty
(`wlp/usr/servers/defaultServer/server.env`, legível só pelo utilizador do serviço) ou variáveis de ambiente
do serviço. **No ficheiro da API não pôr `BD_ADMIN_UTILIZADOR` nem `BD_ADMIN_SENHA`**: a API não precisa do
administrador; esses valores ficam só no `.env` de quem corre os scripts (migrações, backups).

Sem perfil (`MP_CONFIG_PROFILE` vazio) a API está em modo produção e **recusa arrancar** com segredos em falta,
com os segredos de desenvolvimento, com `MENSAGENS_MODO=consola` ou com `COOKIE_SEGURO=false` (C1, H1).

| Variável | Obrigatória | Valor |
| --- | --- | --- |
| `JWT_SEGREDO` | sim | aleatório, ≥ 32 caracteres (`openssl rand -base64 48`) |
| `CODIGO_SEGREDO` | sim | aleatório, ≥ 16 caracteres |
| `BD_SERVIDOR`, `BD_PORTA`, `BD_NOME` | sim | ligação ao PostgreSQL |
| `BD_SENHA` | sim | senha do `api_igreja` (sem valor por defeito) |
| `BD_POOL_MAX` | não (20) | ligações à base por instância; ajustar com o teste de carga |
| `BD_TIMEOUT_CONSULTA_SEGUNDOS` | não (30) | tempo máximo de cada instrução SQL |
| `BD_TIMEOUT_BLOQUEIO_SEGUNDOS` | não (5) | espera máxima por um registo bloqueado |
| `PEDIDO_MAX_KB` | não (2048) | tamanho máximo de um pedido |
| `SENHAS_CONCORRENCIA` | não (nº de CPUs) | cálculos de senha (Argon2id, 19 MiB cada) em simultâneo |
| `PROXY_CONFIAVEL` | sim, atrás do Nginx | `true` |
| `TAREFAS_ACTIVAS` | não (true) | `false` nas instâncias que não devem correr as tarefas diárias |
| `LOG_FORMATO` | recomendado | `JSON` (uma linha por mensagem, para o agregador de logs) |
| `MENSAGENS_MODO` | sim, para SMS | `http` com o fornecedor; `desligado` = lembretes e códigos ficam por enviar |
| `SMS_URL`, `SMS_TOKEN`, `SMS_REMETENTE` | com `http` | fornecedor de SMS (a API recusa arrancar com `http` sem URL e token) |
| `FICHEIROS_PASTA` | sim, para comprovativos | pasta onde a API guarda as fotografias/PDF dos comprovativos (utilizador da API com escrita; incluir no backup). Sem ela, carregar dá 503 |

Trocar `JWT_SEGREDO` termina todas as sessões (os utilizadores entram de novo).

## 3. Nginx

[nginx.conf.exemplo](nginx.conf.exemplo): HTTPS, HSTS e headers de segurança, limite de pedidos por IP
(o limite da API é por instância), `client_max_body_size`, `X-Forwarded-For` substituído pelo Nginx e
`/openapi`, `/metrics` e `/health` só na rede interna.

## 4. Monitorização (alertas mínimos)

| Onde | Alerta |
| --- | --- |
| `GET /health/ready` | diferente de 200 durante 1 minuto (a API não fala com a base) |
| `/metrics` · `tarefas_falhas_total` | aumentou (tarefa diária falhou: ver o log com o nome da tarefa) |
| `/metrics` · `sms_falhados_total` | a subir (fornecedor de SMS em baixo ou a recusar: ver `ntf_erro` na fila) |
| `/metrics` · `tarefas_ultimo_sucesso_segundos` | mais de 26 horas sem sucesso |
| `/metrics` · pool de ligações (`connectionpool_*`) | tempo de espera > 1 s ou pool cheio |
| `/metrics` · JVM (`memory_*`, `thread_*`, `gc_*`) | heap > 85 % durante 10 minutos |
| log | mensagens `SEVERE` (erros internos, com o id do pedido) |
| Nginx | taxa de 5xx > 1 % ou de 429 anormal |

O id de cada pedido (`X-Pedido-Id`) é gerado pelo Nginx e aparece no log do Nginx, no log da API e na resposta.

## 5. JVM

Heap fixa e GC com pausas curtas, em `jvm.options` do servidor (ou `JAVA_TOOL_OPTIONS`):

```
-Xms1g
-Xmx1g
-XX:+UseG1GC
-XX:+ExitOnOutOfMemoryError
```

Com `SENHAS_CONCORRENCIA=8` os cálculos de senha usam até ~160 MiB; o resto depende dos relatórios
(até 5000 linhas cada). Confirmar com o teste de carga.

## 6. Antes de abrir

1. `./mvnw test` com a base de testes (89 testes, incluindo os 40 de integração) e a CI verde.
2. `python scripts/teste-ponta-a-ponta.py` contra o ambiente de testes (28 verificações).
3. Teste de carga (k6) — login, listagens e relatórios com a carga de `database/tests/carga_*.sql`;
   o resultado define `BD_POOL_MAX`, `SENHAS_CONCORRENCIA` e o número de instâncias.
4. Restauro de um backup testado.
5. Fase 4 (M-Pesa, SMS, PDF) concluída ou fora do âmbito do lançamento: hoje respondem 501.
