---
description: Rever as alterações actuais contra as regras do projecto
---
Revê `git diff` (e ficheiros novos) contra o CLAUDE.md. Verifica em especial:

- Alguma ligação à base de dados como dono, ou `set_config(..., false)` na API?
- Alguma regra de negócio ou verificação de permissão reimplementada na API ou no frontend?
- Algum `DELETE`/`TRUNCATE`, ou migração existente editada em vez de uma nova?
- SQL montado com texto do pedido?
- Dinheiro como `number`/float em vez de string/DECIMAL?
- Endpoint novo sem teste de perfil autorizado + não autorizado?
- Campos JSON com prefixo de tabela, ou colunas sem prefixo na base de dados?
- Textos da interface/erros fora do português ou fora do ficheiro de traduções?

Lista os problemas por gravidade, com ficheiro e linha, e propõe a correcção.
