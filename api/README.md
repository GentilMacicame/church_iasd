# Contrato da API

`openapi.yaml` é o contrato da API (fonte de verdade para a API e para o frontend). É **gerado** a partir do
esquema da base de dados:

```bash
cd database/gerador && python3 gen_openapi.py
```

O código da API está na raiz do repositório (`pom.xml`, `src/`); ver o README da raiz. O `ContratoTest`
garante que as rotas do código são exactamente as deste ficheiro, e o Swagger UI
(`http://localhost:9080/openapi/ui`) mostra-o com o servidor a correr.
