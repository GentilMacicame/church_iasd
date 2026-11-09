# API

Stack: **Java 21, Jakarta EE 10** (o nome actual do Java EE: JAX-RS, CDI, JSON-B, Bean Validation),
MicroProfile Config, servidor **Open Liberty**, Maven (`./mvnw`), JDBC puro sobre PostgreSQL.

O código da Fase 0 está, por agora, em `../church_iasd` (fora deste repositório) e será movido para
esta pasta. O contrato é `openapi.yaml` (gerado por `database/gerador/gen_openapi.py`).
Ver CLAUDE.md na raiz.

```bash
./mvnw liberty:dev     # API em http://localhost:9080 (recompila ao gravar)
./mvnw test            # testes; os de integração precisam de Docker ou de BD_TESTE_URL
```
