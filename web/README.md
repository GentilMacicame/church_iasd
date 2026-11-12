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

- **Início** (painel de direcção): indicadores (membros, saldo, entradas do mês), "Precisa de atenção" (tudo o que
  espera uma acção da secretaria e da tesouraria, num só sítio), o próximo sábado, tesouraria e membros em faixas.
- **Fundos e ofertas**: os fundos da Missão (só leitura) e as ofertas e projectos próprios da igreja (criar, terminar);
  aparecem em "Lançar entrada" e nas despesas. Despesas: "Outras despesas" pede que despesa é; fundos agrupados (da igreja /
  parte da igreja). Contagem por partes (dízimos, ofertas, Escola Sabatina, outras) com a conferência parte a parte.
  Fecho do mês com a lista de verificação do mês a fechar (pendentes, contagens, remessa, saldos).

- **Igrejas** (super-administrador e administração da Associação): registar igrejas (tipo, Associação, distrito,
  igreja-mãe) com o seu administrador (perfil ADMIN; código por SMS para definir a senha), ver quem administra cada
  uma e abri-la. As páginas exigem a mesma permissão que o menu ("Sem acesso a esta página").

- **Associações/Missões e distritos pastorais** (separadores em Igrejas): registar e listar; a Associação pode ser
  criada já com os fundos (dízimo, ofertas, Escola Sabatina, parte da Missão na oferta combinada). Cada igreja só vê os
  fundos da sua Associação. Listas longas com pesquisa (`CampoEscolha`: sem acentos, teclado).
- **Indicação de carregamento**: barra fina no topo enquanto há pedidos; páginas carregam dentro da moldura; botões com
  "A …". **Sessão inactiva**: 5 min sem mexer → aviso com 30 s → logout (actividade partilhada entre separadores).

- **Transferências entre contas** (F-TES-09): na página Contas (caixa → banco, M-Pesa → banco) e "Depositar no banco" nas
  contagens conferidas (com o n.º do talão; a contagem passa a depositada).
- **Reconciliação** (F-TES-14): importar o extracto do banco/M-Pesa em CSV (`data;descricao;referencia;valor`) e ligar
  cada linha ao movimento; sugere o da mesma conta, valor e direcção (até 5 dias).
- **Orçamento anual** (F-TES-11): previsto por categoria (receitas e despesas), aprovado com o voto da igreja, realizado
  e % de execução. **Alvos** (F-TES-12) em Fundos e ofertas, com barra de progresso.
- **Transferências com carta** (P-02): pedido (igreja do sistema, pelo directório, ou de fora), carta votada em 2.ª
  leitura e impressa com o logotipo, aceitação pela igreja de destino (que vê o nome do membro), recusa, validade de 6 meses.
- **Disciplina** (P-03): censura de 1 a 12 meses com o voto, aviso ao encarregado nos menores, motivo confidencial.
- **Famílias** e **consentimentos** (cartão na ficha do membro: o último de cada tipo, histórico guardado; nos menores,
  dado pelo encarregado). **Relatório da secretaria** (F-SEC-10): movimento do livro mês a mês, membros por estado,
  pendentes (menores sem encarregado ou consentimento, censuras, transferências), para imprimir.

- **Eleição de oficiais** (P-04, F-SEC-08) em Conselho › Eleição de oficiais: a comissão de nomeações prepara a lista
  (cargo → membro, guardada no aparelho) e imprime o relatório; com o voto da igreja (ELEICAO) registam-se todos os
  mandatos de uma vez e terminam-se os anteriores na véspera; cada recusa da base (censura, membro de outra igreja) aparece na linha.
- **PDF**: "Imprimir / guardar PDF" nos documentos (relatórios, orçamento, carta, relatório da comissão) com nome de
  ficheiro útil; "Exportar" (PDF ou CSV) descarrega os relatórios da API (`?formato=pdf`).

- **Reuniões: abertura e encerramento** (V28): primeira oração, hino entoado, meditação (membro ou convidado) e última
  oração, num cartão da reunião; entram no texto da acta.
- **Menu** com ícones Phosphor (linha fina; cheio no item activo).

- **Todas as listas com pesquisa**: `Seleccao` (a lista usada nos formulários e filtros) passou a ser uma lista com pesquisa
  sem acentos e com teclado, com a mesma interface de um `<select>` (por dentro há um `<select>` escondido, que o
  formulário lê).
- **Contribuições por família** em Lançar entrada: "Um membro", "Uma família" (ex.: Família Macicame, com recibo) ou
  "Ofertas da salva"; o nome da família aparece nos movimentos, na ficha e no recibo.

- **Paginação de 10 em 10** em todas as tabelas (o componente `Tabela` pagina sozinho; as linhas de total ficam sempre;
  ao imprimir ou guardar em PDF saem todas) e nas listas (`Paginada`): movimentos, membros, famílias, reconciliação,
  contagens, pontos da agenda, presenças, alvos, pendentes do Início, proposta da eleição.

- **Escola Sabatina** (F-ES-01…08, P-05), em `features/escola-sabatina/`:
  - **Painel e classificação**: indicadores do trimestre (classes activas, presença e estudo diário médios, ofertas,
    visitantes, baptismos face ao alvo), lugar e pontuação de cada classe com a diferença para a média, presença
    sábado a sábado, relatórios em falta, ofertas por conferir com a tesouraria, resumo das classes (exportar PDF/CSV).
  - **Relatório do sábado**: as classes do sábado (por fazer, aberto, fechado, por enviar) e o ecrã de cada classe,
    pensado para o telemóvel: M.M. (pelas matrículas ou à mão), M.P., E.D., visitantes e filiais com botões − e +,
    chamada nominal com botões grandes (presente / estudou; conta os números sozinha), visitantes com contacto e
    quem convidou, as três ofertas separadas. O tesoureiro lança as ofertas na tesouraria (uma linha por fundo,
    Idempotency-Key); o secretário fecha; só o director reabre.
  - **Sem rede**: o ecrã de cada classe do sábado fica guardado no telemóvel (IndexedDB) quando se abre a lista com
    rede; o relatório, a chamada e os visitantes ficam num rascunho local e "Guardar" põe-no na fila, enviada logo,
    ao voltar a rede e ao abrir a aplicação (`offline.ts`; envio retomável, sem duplicar). Uma recusa da base de
    dados fica no rascunho com a mensagem para corrigir. Service worker em `public/sw.js` (só no build de produção:
    a aplicação abre sem rede; a API nunca passa pela cache) e `manifest.webmanifest`. Sem rede ao abrir, a sessão
    continua com a última cópia de `GET /v1/eu` e renova-se quando a rede volta.
  - **Classes**: classes por divisão, matrículas (membros e interessados; sair guarda a data) e a configuração no
    trimestre (professor, auxiliar, secretário, alvos, activa ou desactivada).
  - **Trimestres** (Associação): novo trimestre com os sábados gerados (13 ou 14) e o 13.º sábado marcado; mudar o
    13.º sábado; criar os sábados em falta; pesos da pontuação por defeito e por trimestre.
  - **Visitantes**: por acompanhar / tornaram-se membros, ligar o visitante ao registo de membro.
  - Cenários tratados: dois telemóveis no mesmo relatório (o envio pára e pergunta "Gravar por cima" ou
    "Descartar"); resposta perdida a meio do envio (o relatório e cada visitante levam `Idempotency-Key`: repetir
    não duplica); membro já matriculado noutra classe ("Mudar para esta classe", fica o histórico); início do
    trimestre ("Copiar do trimestre anterior" a configuração das classes); sem rede não há logout por inactividade
    nas páginas da ES; sair com relatórios por enviar pede confirmação; relatórios em falta abrem o ecrã da classe;
    aviso do 13.º sábado nas ofertas. As recusas da base chegam com a frase da restrição (V29), não com o nome.

- **Sino de alertas** (barra de topo, em todas as páginas; `features/alertas/`): tudo o que espera uma acção do
  utilizador na igreja escolhida, um alerta por assunto, e cada um abre o ecrã onde se resolve. Secretaria: registos
  por aprovar (ficha do membro), menores com a ficha incompleta, cartas por emitir e membros a aceitar
  (transferências, separador certo), mandatos a terminar. Reuniões: actas por aprovar, reuniões passadas por marcar
  como realizadas. Tesouraria: saídas por aprovar (não as próprias) e movimentos por confirmar (ficha do movimento),
  despesas por decidir (não as próprias) ou pagar (abre o diálogo: `/tesouraria/despesas?despesa=id`), contagens,
  depósito à Missão em falta, depósitos por confirmar (Associação), orçamento por aprovar, mês anterior por fechar.
  Escola Sabatina: ofertas por lançar ou diferentes, relatórios prontos a fechar, relatórios em falta, relatórios
  no telemóvel por enviar. Escalas por publicar. Cada fonte só existe para quem tem a permissão de agir e usa as
  consultas do módulo (o que se aprova num ecrã tira o alerta). O número no sino conta os novos; abrir marca-os como
  vistos (neste aparelho); refresca de 3 em 3 minutos. O "Precisa de atenção" do Início mostra os mesmos alertas.

## Por fazer (próximas iterações)

- Escolha do pastor oficiante no baptismo (precisa de uma lista de pastores na API).
