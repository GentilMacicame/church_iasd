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

- **Mandatos, conselho e direcção** (F-SEC-07, V31): cada mandato (início e duração de 1–5 anos ou outra data) mostra-se
  como raiz de uma hierarquia com dois ramos — Conselho da igreja e Direcção — e os oficiais agrupados por cargo; acrescentar
  oficial (o órgão vem do cargo e pode mudar-se), passar de órgão, corrigir datas, terminar antes do fim; oficiais antigos sem
  mandato associam-se a um.
- **Reuniões** (F-SEC-08, P-04): reunião com número, presidente e secretário escolhidos do
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

- **Eleição de oficiais** (P-04, F-SEC-08) em Mandatos e conselho › Eleição de oficiais: a comissão de nomeações prepara a lista
  (cargo → membro, guardada no aparelho) e imprime o relatório; com o voto da igreja (ELEICAO) registam-se todos os
  eleitos de uma vez no mandato escolhido (ou criado ali) e terminam-se os anteriores na véspera; cada recusa da base (censura, membro de outra igreja) aparece na linha.
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
  - **Quadro das classes** (Classes): n.º, nome do grupo, professor/líder, alvos de membros, E.D., filiais, ofertas por
    sábado e baptismos, estado (activo/desactivado, a cinzento), total; registo e edição num só formulário
    (`DialogoClasse`: classe + configuração no trimestre).
  - **Folha da classe** (separador da classe): sábado a sábado como a folha do quadro: M.M., M.P., % presença, E.D.,
    % E.D., visitantes, oferta do sábado, alvo, total acumulado, % do alvo, 13.º sábado, despesas da ES, filiais e a
    linha total/média; escreve-se nas células (Enter desce) e grava os sábados alterados; percentagens a cores.
  - **Relatórios** (Escola Sabatina › Relatórios): resumo do trimestre por classe (médias, % presença, % E.D.,
    visitantes, filiais, ofertas e alvo, 13.º sábado, baptismos e alvo, barras de dados, média das activas),
    classificação (pontuação, posição, lugar com medalhas e gráfico), quadro comparativo com a média, evolução
    sábado a sábado e por divisão (Associação); imprimir e exportar.
  - Ecrã do sábado: números em cartões, chamada em tabela, ofertas, visitantes em tabela e o resumo do sábado ao lado.
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

- **Painel geral das igrejas** (`/painel-geral`, menu só para quem acompanha várias igrejas): indicadores (igrejas, membros
  activos, transferidos no ano, dizimistas e % dos activos, saldo, entradas e saídas, dízimos, por depositar à Missão),
  gráficos dos últimos 12 meses (entradas e saídas, dízimos, movimento de membros), comparativo de uma medida igreja a
  igreja com a média e o quadro de todas as igrejas (ordenável, total; "sem acesso" onde não pode ver). Filtros por
  Associação, distrito pastoral e nome. O pastor do distrito vê só as igrejas do seu distrito (a base de dados decide:
  vistas V30 `security_invoker`).

- **Ficha do membro completa** (F-SEC-01, V33): formulário em 6 secções (dados pessoais, familiares, contactos e
  residência, profissão e estudos, religião e baptismo, participação) e a revisão. Novos: outro documento, ex-membro com a
  data do baptismo anterior (o actual fica como rebaptismo), endereço e código postal, local de trabalho, casamento e
  cônjuge (escolhido entre os membros: os dois registos ficam ligados; senão, o nome), dependentes, religião anterior e
  como conheceu a mensagem. Telemóvel, telefone fixo e e-mail editam-se no formulário (mudar guarda o anterior no
  histórico); o baptismo também (data, igreja, local, ministro). Campos condicionais escondem-se mas não se apagam.
  Validação do BI (12 algarismos e uma letra), passaporte, telefones e e-mail. **Possíveis duplicados**: enquanto se
  escreve, a API devolve os registos parecidos (mesmo documento; nome e data/local de nascimento); os prováveis pedem
  "Conferi: é outra pessoa" antes de gravar, nada é bloqueado. Ficha com cônjuge (ligação), cargos actuais e classe da
  Escola Sabatina. Lista com filtros por sexo e estado civil e "Exportar" (PDF/CSV de `membros-lista`).
- **Mandatos em tabelas**: no mandato escolhido (actual, a terminar ou terminado: o histórico fica na linha dos mandatos),
  separadores Conselho da igreja, Direcção e Todos os oficiais, cada um uma tabela (membro, cargo, órgão, início, término,
  estado, acções: ver a ficha, passar de órgão, corrigir datas, terminar antes do fim). Oficiais sem mandato também em tabela.
- **Membros sem família** em destaque (o cartão inteiro na cor de aviso, `Indicador destaque`) em Famílias e no Início;
  no cartão Membros do Início, os activos por estado civil (casados, solteiros, viúvos, viúvas, ...), cada um abre a lista filtrada.

- **Actividades e programa anual** (F-ACT, V34; menu Actividades › Programa anual, `features/actividades/`): o programa
  do ano mês a mês (data, hora, actividade, departamento, responsável, estado, previsto, executado), com filtros por
  departamento e estado, total previsto/executado e "Exportar"; separador Por departamento (actividades, concluídas,
  previsto, executado, % de execução; activar outro departamento na igreja). Nova/editar actividade com objectivos,
  datas e horas (pode terminar noutro dia), local, responsável principal e orçamento: antes de gravar procura **conflitos
  de calendário** na igreja e, havendo, mostra as actividades envolvidas, os dias livres seguintes à mesma hora (um clique
  muda a data) e "Gravar mesmo assim". Ficha da actividade: iniciar, concluir, cancelar; objectivos; responsáveis com a
  função; material (orçamento detalhado); despesas pedidas para a actividade ("Pedir despesa" liga-a à actividade e ao
  departamento; decide-se na tesouraria) e a execução (saídas confirmadas, barra e aviso se passar o previsto).

- **Área pastoral** (V35): o pastor do distrito (ou a Associação) regista actividades do distrito ("Origem: Área
  pastoral" em Nova actividade); aparecem no programa e nos conflitos de todas as igrejas do distrito, com a etiqueta
  "Área pastoral", o filtro próprio e uma linha no resumo por departamento. Os directores das igrejas vêem-nas mas não as alteram.

- **Decisões do plano** (V36): Início com os activos que participam e os **inactivos** (sem presença na ES nem
  contribuição há 6 meses) e os **noivos**; a ficha do membro mostra a última participação. Lançar entrada avisa quando o
  **dízimo do mês já foi lançado** em nome da família do membro (ou de um membro da família) e pede "Conferi: não é o
  mesmo dízimo". Novo alvo sugere a **meta do ano anterior + 5%** (ex.: reavivamento, um fundo da igreja), ajustável.

- **Comunicados** (V37, menu Comunicados, `features/comunicados/`): mural com os comunicados em vigor para o utilizador
  (da igreja, do distrito pastoral e da Missão; os 3 mais recentes também no Início); Gerir (quem publica): rascunhos,
  publicados, agendados, expirados e arquivados em tabela, com editar, publicar, arquivar e retirar. Novo comunicado:
  quem publica (esta igreja, o distrito se for o pastor, a Associação se tiver perfil lá), para que igrejas (todas ou
  escolhidas), público (todos os membros ou só a liderança), publicar em e válido até.

- **Painel geral por período** (V38): este mês, este ano, o ano anterior ou um intervalo. Indicadores: total de membros
  (com as entradas e perdas no período), membros activos e % (e os inactivos), fidelidade contributiva, dízimos (com as
  ofertas no mesmo cartão), reavivamento, saldo e depósitos em falta (hoje). Gráficos: evolução das contribuições
  (dízimos, ofertas, reavivamento), entradas e saídas de membros e de dinheiro, comparativo de uma medida. Quadro
  comparativo: membros, activos, inactivos, % activos, dízimos, ofertas, reavivamento, fidelidade, entradas e perdas de
  membros, saldo e por depositar. Fundos da igreja: novo tipo "Reavivamento".

- **Santa Ceia** (V39, menu Actividades › Santa Ceia, `features/santa-ceia/`): a próxima celebração, celebrações e média
  de participantes no ano, a última comparada com a anterior, aviso das que falta registar, gráfico dos participantes
  (homens, mulheres, visitantes) e o histórico em tabela; agendar (data, hora, local, responsável, observações), registar
  os participantes, editar e cancelar. No Início, a próxima e a última; no painel geral, celebrações e participantes no período.

- **Relações familiares** (V40): a família mostra os membros em tabela com o parentesco com o chefe (alterável ali: chefe,
  cônjuge, filho, pai/mãe, irmão, neto, outro), idade, estado civil e estado, e as relações conhecidas: casais (cônjuges ligados)
  e menores. A ficha do membro mostra a família e o parentesco.

- **Disciplina** (V41): indicadores (em censura, terminam em 30 dias, censuras e removidos no ano); separadores Censuras
  (tempo cumprido em barra, dias que faltam, anular), Removidos (por disciplina e a pedido, do livro de membros) e Registo de
  acessos (pastor e Associação: quem consultou que motivo e quando). O motivo não aparece nas listas: "Motivo" abre um aviso e
  só depois de "Ver o motivo" é lido (a base de dados regista a consulta).

- **Tesouraria** (V42): **fundo de maneio** em Contas (novo tipo de conta; valor inicial, saldo, Repor = transferência de
  outra conta, Despesa urgente = saída com quem a fez e o comprovativo na ficha, Histórico = movimentos dessa conta com
  `?conta=`). **Contagens**: participantes com a função (tesoureiro, Escola Sabatina, diácono, ancião, outro), juntar e tirar
  enquanto está aberta. **Lançar entrada**: o 13.º sábado e a oferta missionária saem do envelope da igreja local (ficam na
  conta da Missão); três linhas de oferta especial (fundo de oferta especial, projecto ou reavivamento + designação + valor).
  **Notificações** (Administração, `features/notificacoes/`): histórico dos SMS/WhatsApp/e-mail com estado, tentativas e
  erro, filtros por estado e canal, e Reenviar das que falharam.

- **Registar membro começa pela procura** (V43, `PaginaProcurarMembro`): nome, apelido, data e local de nascimento e
  documento, em todas as igrejas. Sem resultados segue logo para a ficha (`/membros/novo/ficha`, já preenchida); o mesmo
  membro (mesmo documento, ou mesmo nome e data) aparece como "Este membro já existe", com a ficha ou, se for de outra
  igreja, a indicação de pedir a transferência, e não se regista; parecidos só pelo nome pedem "Conferi: é outra pessoa".
- **Contagem** (V43): a nova contagem pede o tesoureiro, o representante da Escola Sabatina e o diácono (o ancião é
  opcional) e regista-os como participantes; "Conferir" só fica activo com os três.

- **Escala** (V44): colunas pelas partes do dia — Escola Sabatina (família responsável e apresentador), Culto Divino
  (apresentador, Sermão principal, tradutor, Sermão da criança, oração inicial e final) e JA (apresentador e meditação);
  os acompanhantes e as outras funções escalam-se no diálogo do dia. Imprime-se ao baixo (A4 paisagem).
- **Programação do dia** (V44, menu Actividades, `features/programacao/`): lista por data e "Preparar" (do modelo da
  igreja ou copiando outro dia, já com os nomes da escala); a folha como a da igreja (título, partes com o apresentador,
  horas, actividade, responsável, linhas em destaque, nota), editável linha a linha (membro, família, departamento ou
  texto; ligação à escala), "Preencher pela escala" e "Imprimir" (A4).
- **Escalas** (V45): três tipos — Culto Divino (as colunas do culto e o grupo coral), Escola Sabatina e JA (as colunas que
  a igreja define em "Colunas da escala": nome, ordem, um membro ou uma família). A programação liga-se também a elas.
- **Registar membro** (V45): janela com nome, apelido e data de nascimento obrigatórios, local, BI e telemóvel; procura ao
  escrever, em todas as igrejas (nome como se ouve e trocado, data, documento, telemóvel); "Já está registada" não deixa
  continuar, "Pode ser" pede "Conferi: é outra pessoa". **Lançar entrada**: sem "Outros fundos" na igreja local.
  **Fundos**: tipo "Fundo de construção". **Contagem**: parte "Fundo de construção".
- **Painéis** (V46): o Início de cada igreja tem duas filas — Membros (total, activos com a % e os inactivos, sem família
  em destaque, por aprovar) e Tesouraria (dízimos do mês com as ofertas, reavivamento, fidelidade, saldo) — e a evolução
  das contribuições. O Painel geral ganha os inactivos, os sem família, as entradas e perdas, a composição dos membros
  (sexo, idades, estado civil) e a coluna "Sem família" no quadro comparativo.
- **Escola Sabatina** (V47): a chamada tem a oferta de cada aluno (contribuição individual; o total identificado
  compara-se com a oferta da classe); a ficha da classe tem o separador **Metas** (meta de cada aluno, "aplicar a todos",
  contribuído, presenças e cumprimento; a meta da classe é a soma); o painel da ES mostra as metas das classes e os
  **programas especiais** (semana de oração, da família, de evangelismo…), que geram alertas 14 dias antes.
- **Área pastoral** (contexto próprio do pastor do distrito, no menu do utilizador): Painel do distrito (indicadores,
  composição e comparação das igrejas; acompanhamento das actividades por igreja), Programa da área pastoral (com
  Acompanhamento) e Comunicados. As actividades da área pastoral aparecem no Programa anual de cada igreja.
- **Acompanhamento** (Programa anual › Acompanhamento; V48): realizadas, atrasadas, canceladas (com o motivo, obrigatório
  ao cancelar), orçamento executado, mês a mês e a comparação por departamento.
- **Reavivamento** (Tesouraria › Reavivamento; V49): o alvo do ano repartido por pessoa (adultos e crianças), quota
  ajustável, contribuído e falta; na entrada, o campo Reavivamento mostra a quota do membro.
- **Extractos** (Tesouraria › Extractos; V50): por departamento e por fundo, no mês, trimestre, semestre ou ano;
  percentagens dos departamentos, transferências entre eles e adiantamentos com prestação de contas.
- **Reavivamento por escalão** (V51): quota fixa para adultos e/ou crianças; **Santa Ceia** com oficiante (pastor ou
  ancião) e acompanhantes (diáconos). Painel geral com "Igrejas lado a lado"; quadro comparativo da ES com gráficos.

## Por fazer (próximas iterações)

- Escolha do pastor oficiante no baptismo (precisa de uma lista de pastores na API).
