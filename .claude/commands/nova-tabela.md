---
description: Acrescentar ou alterar uma tabela na base de dados seguindo as convenções do projecto
argument-hint: <descrição da tabela ou alteração>
---
Pedido: $ARGUMENTS

Segue a secção "Acrescentar ou alterar uma tabela" do CLAUDE.md:

1. Lê `database/gerador/defs.py` e escolhe o módulo (schema). Propõe o nome, o **prefixo de 3 letras único**
   (confirma que não existe: `grep -n "', '<pfx>'" database/gerador/defs.py`) e as colunas, com FKs no formato
   `<pfx>_<papel>_<pfxdest>_id`. Não acrescentes as colunas-padrão à mão: o gerador cria-as.
2. Decide as regras de negócio (trigger em `gerador/sql/<schema>_regras.sql`, funções SECURITY DEFINER com
   `search_path` fixo) e as permissões (que perfis ganham ler/criar/alterar/terminar em `PERFIS`).
3. Corre `cd database/gerador && python3 gen.py`, compara `out/migracoes/` com `database/migrations/` e
   escreve **só a diferença** numa nova migração `database/migrations/V<próximo>__<nome>.sql`.
   Nunca edites uma migração já existente.
4. Corre `python3 gen_openapi.py` e revê o diff de `api/openapi.yaml`.
5. Acrescenta casos a um teste em `database/tests/` (perfil autorizado consegue; não autorizado é recusado),
   corre `scripts/db-test.sh`, revê o diff e, se for o esperado, `ACTUALIZAR=1 scripts/db-test.sh`.
6. Resume: tabela, prefixo, regras, permissões, ficheiros alterados.
