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
  lançar entrada em 3 passos: quem contribui (membro, com o que já deu este ano, ou ofertas da salva), como entregou
  (envelope em numerário, M-Pesa/depósito na conta da igreja, depósito ou M-Pesa directamente na Missão: uma escolha por
  conta, a forma de pagamento sai dela) e os valores (dízimo e oferta em destaque); o que não é numerário pede o
  comprovativo (referência, data, descrição e a fotografia ou PDF, reduzida no telemóvel antes de enviar); resumo com a parte da Missão e a da igreja e a lista da sessão; recibo
  numerado; registar saída (fica por
  aprovar: quem regista não aprova; o ancião aprova, o tesoureiro confirma); movimentos do mês com filtros; ficha do
  movimento (confirmar, aprovar, recibo para imprimir, anular pendente, comprovativos: abrir e juntar). Pedidos de dinheiro com Idempotency-Key.
  Despesas (P-07): pedir, decidir (aprovar, pode reduzir, ou rejeitar com motivo; quem pede não decide), pagar (a saída
  confirma-se logo e a despesa passa a paga). Remessas (P-09): o devido por mês e fundo, enviar (remessa + linhas +
  saída de remessa + enviada; retoma-se se falhar a meio), confirmar a recepção (Associação). Fecho do mês (P-10):
  últimos 12 meses, fechar (avisa dos pendentes), reabrir (fica no histórico). Estornos (P-12) na ficha do movimento,
  por fundo, com motivo; seguem aprovação e confirmação. Contagem do numerário (P-06 passo 1): dois contadores,
  conferência contado × lançado; as entradas em numerário escolhem a contagem.
  Dízimos e ofertas com a divisão de cada fundo (dízimo 100% Missão, oferta combinada 50/50); a igreja só gasta a sua
  parte. Pagamentos feitos pelos membros directamente na conta da Missão ("Lançar entrada" → "Pago na conta da
  Missão", com o comprovativo e recibo): contam como contribuição e como já remetidos. Contas (incl. a conta da
  Missão). Remessa = depósito na conta da Missão com o n.º do talão (e complementar, se entrar mais depois).
  Relatório mensal para a Missão (resumo por fundo, depósitos, recibos de cada membro, ofertas sem nome), para imprimir.
- **Escalas** (F-ACT-03): lista, nova escala (gera os sábados do período), editor em grelha como a escala em papel
  (escalar, trocar, retirar, dias especiais, grupo coral), publicar (activa os lembretes por SMS) e imprimir (A4 deitado,
  com as assinaturas).
- **Utilizadores e perfis** (F-NUC-03, P-13), como a gestão de contas do SGMS: separadores Utilizadores (indicadores,
  filtros, pesquisa, perfis nesta igreja, estado: activo / ainda não entrou / desactivado), Perfis (lista, detalhes,
  novo, editar, activar/desactivar) e Permissões (matriz por módulo: ver, criar, alterar, terminar e acções
  específicas; só o super-administrador altera). Ficha do utilizador: dados, membro ligado, perfis em cartões, estado da
  conta, enviar o código por SMS (o "convite": o utilizador define a senha em "Esqueci a senha"), desactivar/reactivar.
  As regras são da base de dados: ninguém altera os próprios perfis nem dá um perfil com mais permissões do que as suas.

- **Conselho da igreja e reuniões** (F-SEC-07/08, P-04): conselho com cargos, contactos e mandatos (em exercício, a
  terminar, terminados), duração dos mandatos por igreja; reunião com número, presidente e secretário escolhidos do
  conselho (secretário oficial por defeito), presenças (presente/ausente com justificação), agenda com deliberações e
  votações, votos formais, encerramento, estados (convocada → realizada → acta aprovada, que fecha o registo) e a
  acta formal para imprimir/guardar em PDF (A4, assinaturas do Presidente e do Secretário). O campo de escolher membro
  abre num popover (já não estica os diálogos). Registo de membro em assistente de 5 passos.

## Por fazer (próximas iterações)

- Secretaria: transferências com carta (P-02), disciplina e censura (P-03), eleição de oficiais (P-04).
- Tesouraria: orçamento anual (F-TES-11), transferências entre contas, depósito da contagem no banco, relatórios
  mensais em PDF (Fase 4).
- Escola Sabatina com o relatório do sábado offline (PWA, IndexedDB, P-05).
- Escolha do pastor oficiante no baptismo (precisa de uma lista de pastores na API).
