# Sistema de Gestão da Igreja Adventista

Secretaria, Escola Sabatina, tesouraria, actividades, M-Pesa e mensagens para igrejas locais e Associação/Missão.

## Arranque rápido

```bash
docker compose up -d db
export PGHOST=localhost PGUSER=postgres PGPASSWORD=postgres
scripts/db-reset.sh     # cria a base "igreja" (migrações V1–V15)
scripts/db-test.sh      # testes da base de dados (deve dar 5× ok)
```

Primeiro utilizador da API (substituir a senha):

```sql
CREATE ROLE api_igreja LOGIN PASSWORD 'mudar' IN ROLE app_igreja;
ALTER ROLE api_igreja SET search_path = nucleo, organizacao, secretaria, actividades,
    escola_sabatina, tesouraria, pagamentos, comunicacao;
```

## Documentação

- `docs/Especificacao_Sistema_Igreja_v1.1.docx` — especificação funcional e técnica (fonte)
- `docs/especificacao.md` — a mesma, em Markdown
- `docs/modelo_dados.html` — modelo de dados navegável
- `api/openapi.yaml` — contrato da API
- `CLAUDE.md` — regras e convenções do projecto (para o Claude Code e para programadores)

## Trabalhar com o Claude Code

Abrir o Claude Code na raiz do repositório; ele lê o `CLAUDE.md` automaticamente. Comandos do projecto:
`/nova-tabela`, `/novo-endpoint`, `/rever`. Primeiro pedido sugerido:

> Lê o CLAUDE.md e a especificação. Implementa a Fase 0: monorepo com api/ (Jakarta EE 10, Java 21) e web/ (React + Vite),
> CI, unidade de trabalho com set_config, autenticação completa, GET /v1/eu, tradução de erros,
> paginação, idempotência e testes com Testcontainers para os 13 perfis.
