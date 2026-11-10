# Frontend · Sistema da Igreja

React 18 + Vite + TypeScript, Tailwind CSS 4 + shadcn/ui, ícones Lucide, TanStack Query, React Hook Form + Zod,
React Router. Tipos e cliente da API gerados de `../api/openapi.yaml` (openapi-typescript + openapi-fetch).

```bash
npm install
npm run gerar:api        # tipos da API a partir do contrato (sempre que o openapi.yaml mudar)
npm run dev              # http://localhost:5173 (a API tem de estar em http://localhost:9080: ./mvnw liberty:dev)
npm run build            # tsc + build de produção em dist/
npm run preview          # serve o dist/ em http://localhost:4173
```

O Vite encaminha `/v1` para a API (mesma origem: o cookie de renovação `HttpOnly; SameSite=Strict` funciona sem
CORS). Outra API: `API_URL=http://servidor:9080 npm run dev`.

## Estrutura

```
src/
  index.css               DESIGN SYSTEM: tokens (cores, tipo, raios), ligados ao Tailwind e ao shadcn
  i18n/pt-MZ.ts           todos os textos da interface e os nomes dos valores da base de dados
  api/                    cliente gerado (esquema.d.ts), sessão no pedido (token em memória, renovação), erros
  auth/sessao.tsx         entrar, sair, igreja escolhida, permissões (pode(...)) a partir de GET /v1/eu
  lib/formatos.ts         datas dd/mm/aaaa, dinheiro "1 500,50 MT" (texto, nunca float), iniciais
  components/ui/          componentes shadcn (Button, Input, Dialog, ...), ajustados ao Design System
  components/comum/       componentes partilhados: estados (vazio, a carregar, erro), Pilula, Avatar, Painel,
                          TituloPagina, Dinheiro, CampoFormulario, CampoData (dd/mm/aaaa), Seleccao, DialogoConfirmar
  components/layout/      Shell (barra lateral; no telemóvel, barra de 48px e menu em folha), Marca
  features/<modulo>/      uma pasta por módulo: páginas + api.ts (consultas e gravações do módulo)
```

## Regras

- **Design System** (`src/index.css`): tokens ao estilo shadcn/ui, os mesmos do SGMS (ardósia + azul, Inter, raio 10px,
  cartões com borda e sombra leve), tema claro e escuro (`.dark`). Componentes partilhados em `components/comum/`:
  `TituloPagina`, `Indicador`, `Cartao`, `Tabela`, `Pilula`, `EstadoVazio`/`EstadoErro`, `CampoData`, `EscolherMembro`, ...
- **A base de dados decide.** `pode(...)` só esconde o que o utilizador não pode usar; a base recusa o resto e a sua
  mensagem (em português) aparece junto ao campo (`campo`) ou no topo do formulário.
- **Nada fictício**: todos os blocos lêem a API; sem dados mostra-se o estado vazio com uma frase. O menu só tem
  módulos que existem.
- **Telemóvel em 3G**: páginas carregadas a pedido (lazy); primeira carga ~175 KB comprimidos. Alvos de toque ≥ 44px.
- **Datas** no ecrã dd/mm/aaaa (`CampoData`, não o campo nativo, que segue a língua do telemóvel).

## Feito

- **Base**: entrar e recuperar a senha (SMS), moldura (barra lateral que encolhe, gaveta no telemóvel, barra de topo com
  caminho, tema e utilizador), tema claro/escuro.
- **Início**: indicadores, o próximo sábado (escala do dia), pendentes da secretaria, livro de membros do ano, saldos.
- **Membros**: lista com indicadores que filtram, pesquisa, ficha (aprovar, editar, terminar, contactos, baptismo) e
  formulário completo.
- **Livro de membros** (P-01): reuniões (junta, regular, assembleia) e votos em acta com numeração anual; entradas
  (baptismo, profissão de fé) e saídas registadas na ficha do membro, com o voto que as autoriza; o livro com os números
  do ano.
- **Tesouraria** (P-06, P-08): painel (saldo total, do mês, contas, saldos por fundo com o que é da Associação);
  lançar entrada por fundos (envelope a envelope, total em cêntimos, recibo numerado); registar saída (fica por
  aprovar: quem regista não aprova; o ancião aprova, o tesoureiro confirma); movimentos do mês com filtros; ficha do
  movimento (confirmar, aprovar, recibo para imprimir, anular pendente). Pedidos de dinheiro com Idempotency-Key.
  Despesas (P-07): pedir, decidir (aprovar, pode reduzir, ou rejeitar com motivo; quem pede não decide), pagar (a saída
  confirma-se logo e a despesa passa a paga). Remessas (P-09): o devido por mês e fundo, enviar (remessa + linhas +
  saída de remessa + enviada; retoma-se se falhar a meio), confirmar a recepção (Associação). Fecho do mês (P-10):
  últimos 12 meses, fechar (avisa dos pendentes), reabrir (fica no histórico). Estornos (P-12) na ficha do movimento,
  por fundo, com motivo; seguem aprovação e confirmação. Contagem do numerário (P-06 passo 1): dois contadores,
  conferência contado × lançado; as entradas em numerário escolhem a contagem.
- **Escalas** (F-ACT-03): lista, nova escala (gera os sábados do período), editor em grelha como a escala em papel
  (escalar, trocar, retirar, dias especiais, grupo coral), publicar (activa os lembretes por SMS) e imprimir (A4 deitado,
  com as assinaturas).

## Por fazer (próximas iterações)

- Secretaria: transferências com carta (P-02), disciplina e censura (P-03), eleição de oficiais (P-04).
- Tesouraria: orçamento anual (F-TES-11), transferências entre contas, depósito da contagem no banco, relatórios
  mensais em PDF (Fase 4).
- Escola Sabatina com o relatório do sábado offline (PWA, IndexedDB, P-05).
- Escolha do pastor oficiante no baptismo (precisa de uma lista de pastores na API).
