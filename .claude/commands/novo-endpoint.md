---
description: Implementar um recurso/endpoint da API a partir do openapi.yaml, com testes de perfil
argument-hint: <caminho, ex. /v1/tesouraria/transacoes, ou ID F-TES-03>
---
Implementar: $ARGUMENTS

1. Lê o(s) caminho(s) em `api/openapi.yaml` (incluindo `x-permissao`, `x-funcao-bd`, `x-vista`) e, na
   `docs/especificacao.md`, a funcionalidade F-xx e o processo P-xx relacionados.
2. Implementa no módulo NestJS correspondente usando a unidade de trabalho existente (transacção +
   `set_config('app.usuario_id', ..., true)`). Não reimplementes regras nem verificações de permissão:
   a base de dados decide. Converte camelCase ⇄ colunas com prefixo num único sítio (mapper do recurso).
3. Dinheiro como string, paginação por cursor, `Idempotency-Key` se cria dinheiro, sem DELETE.
4. Testes de integração (Testcontainers, PostgreSQL real com as migrações):
   - caminho feliz com o perfil autorizado;
   - perfil sem permissão → 403 (ou 404 se a linha fica invisível);
   - pelo menos uma regra de negócio recusada → 422 com a mensagem da base de dados;
   - pedido repetido com a mesma `Idempotency-Key` não duplica (se aplicável).
5. Corre os testes e o lint. Resume o que foi feito com o ID F-xx.
