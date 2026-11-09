> Versão em Markdown de `Especificacao_Sistema_Igreja_v1.1.docx`, gerada com pandoc para leitura pelo Claude Code. O documento Word é a fonte; se divergirem, vale o Word.

**SISTEMA DE GESTÃO DA IGREJA ADVENTISTA**

**Especificação Funcional e Técnica**

Base de dados, API e aplicação (frontend)

|                     |                                           |
|---------------------|-------------------------------------------|
| **Documento**       | Especificação Funcional e Técnica         |
| **Versão**          | 1.1                                       |
| **Data**            | 08/11/2026                                |
| **Estado**          | Para revisão e aprovação                  |
| **Classificação**   | Uso interno                               |
| **Base de dados**   | Esquema v5 + migração V14 (PostgreSQL 16) |
| **Contrato da API** | openapi.yaml (OpenAPI 3.0, 282 caminhos)  |

**Controlo do documento**

**Histórico de versões**

| **Versão** | **Data**   | **Autor**          | **Descrição das alterações**                                                                                                                               |
|------------|------------|--------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1.0        | 08/11/2026 | Equipa do projecto | Guia inicial de desenvolvimento da API e do frontend                                                                                                       |
| 1.1        | 08/11/2026 | Equipa do projecto | Reorganização como especificação funcional e técnica: descrição de cada módulo, funcionalidade e processo; requisitos não funcionais; matriz de permissões |

**Aprovações**

| **Função**                                     | **Nome** | **Data** | **Assinatura** |
|------------------------------------------------|----------|----------|----------------|
| Responsável do projecto                        |          |          |                |
| Pastor distrital / representante da Associação |          |          |                |
| Secretário(a) da igreja                        |          |          |                |
| Tesoureiro(a) da igreja                        |          |          |                |
| Responsável técnico                            |          |          |                |

**Documentos de referência**

| **Ref.** | **Documento**                                                                               |
|----------|---------------------------------------------------------------------------------------------|
| \[R1\]   | Manual da Igreja Adventista do Sétimo Dia (edição em vigor)                                 |
| \[R2\]   | Guia para Secretaria de Iglesia, Conferência Geral, 2023                                    |
| \[R3\]   | Esquema da base de dados v5 e migração V14 (schema_igreja_v5.sql, V14\_\_sessoes_e_api.sql) |
| \[R4\]   | Contrato da API (openapi.yaml)                                                              |
| \[R5\]   | Quadro Comparativo dos Grupos da Escola Sabatina (planilha Excel em uso)                    |

# 1. Introdução

## 1.1 Objectivo do documento

Este documento especifica o Sistema de Gestão da Igreja Adventista: o que o sistema faz (funcionalidades e processos), como se comporta (regras de negócio e permissões) e como deve ser construído (API, aplicação, testes e implantação). Serve de referência comum à igreja, que valida o comportamento, e à equipa técnica, que o implementa.

## 1.2 Âmbito

O sistema cobre a gestão administrativa de igrejas locais e da respectiva Associação ou Missão:

- secretaria: membros, famílias, reuniões e votos, livro de membros, transferências, disciplina e eleições;

- Escola Sabatina: classes, relatórios de cada sábado, presenças, ofertas e classificação das classes;

- tesouraria: entradas, saídas, despesas, recibos, remessas à Associação, orçamento e fecho mensal;

- actividades dos departamentos e escalas de serviço;

- pagamentos por M-Pesa e mensagens aos membros por SMS, WhatsApp e e-mail.

Ficam fora do âmbito desta versão: contabilidade geral da Associação, gestão de escolas e instituições, e integração directa com o sistema de membros da Conferência Geral (o campo de código ACMS fica preparado para essa integração).

## 1.3 Situação actual

> **A base de dados está concluída e testada.** Contém 59 tabelas em 8 módulos, as regras do Manual da Igreja, as regras da tesouraria e as permissões de cada perfil. Foi validada com os dados reais da planilha da Escola Sabatina (classificação idêntica) e com um teste de carga de 300 igrejas e 377 mil movimentos. Falta construir a API e a aplicação, que são o objecto dos capítulos 5 a 10.

## 1.4 Definições e abreviaturas

| **Termo**            | **Definição**                                                                                                   |
|----------------------|-----------------------------------------------------------------------------------------------------------------|
| API                  | Programa no servidor que recebe os pedidos da aplicação, identifica o utilizador e comunica com a base de dados |
| Frontend / aplicação | Interface usada pelas pessoas no computador ou no telemóvel                                                     |
| Endpoint             | Endereço da API que executa uma operação, por exemplo POST /v1/tesouraria/transacoes                            |
| Módulo               | Área funcional do sistema; na base de dados corresponde a um schema                                             |
| Perfil               | Papel de um utilizador numa igreja ou Associação (tesoureiro, secretário, ancião, ...)                          |
| Permissão            | Autorização elementar, com o código módulo.tabela.acção (ex.: tesouraria.transacao.aprovar)                     |
| Terminar             | Marcar um registo como encerrado com uma data de fim. Nenhum registo é apagado                                  |
| Estorno              | Movimento de sentido contrário que corrige um movimento financeiro já confirmado                                |
| Fundo da Associação  | Fundo que pertence à Associação/Missão e é remetido mensalmente (dízimo, ofertas missionárias, 13º sábado)      |
| RLS                  | Row Level Security: mecanismo do PostgreSQL que limita as linhas visíveis a cada utilizador                     |
| M.M. / M.P. / E.D.   | Escola Sabatina: membros matriculados / membros presentes / estudo diário da lição                              |
| PWA                  | Aplicação web instalável no telemóvel, que pode funcionar sem rede                                              |

*Tabela 1 · Definições e abreviaturas*

# 2. Descrição geral do sistema

## 2.1 Contexto

Hoje a gestão das igrejas assenta em livros de papel, folhas de cálculo e mensagens. Isto dificulta a consolidação de dados pela Associação, torna a conferência das contas demorada, não deixa rasto de quem alterou o quê e depende de pessoas concretas para encontrar a informação.

## 2.2 Objectivos

| **ID** | **Objectivo**                                                        | **Como se mede**                                                             |
|--------|----------------------------------------------------------------------|------------------------------------------------------------------------------|
| OBJ-01 | Ter um livro de membros único, fiável e conforme ao Manual da Igreja | Todos os movimentos de membros têm o voto que os autoriza                    |
| OBJ-02 | Dar transparência e controlo à tesouraria                            | Toda a saída tem aprovação de uma segunda pessoa; o mês fecha sem diferenças |
| OBJ-03 | Garantir a remessa correcta e atempada dos fundos da Associação      | Valor em falta por fundo e por mês sempre visível                            |
| OBJ-04 | Substituir o quadro comparativo em Excel da Escola Sabatina          | Classificação igual à da planilha, sem papel                                 |
| OBJ-05 | Permitir contribuições por M-Pesa com recibo imediato                | Recibo enviado ao membro após a confirmação                                  |
| OBJ-06 | Proteger os dados pessoais e sensíveis                               | Cada perfil vê apenas o que precisa; tudo fica registado                     |

*Tabela 2 · Objectivos do sistema*

## 2.3 Utilizadores

| **Perfil**                       | **Âmbito**         | **Responsabilidades no sistema**                                                                 |
|----------------------------------|--------------------|--------------------------------------------------------------------------------------------------|
| Secretário(a) da igreja          | Igreja             | Mantém o livro de membros, regista reuniões e votos, trata transferências, disciplina e eleições |
| Tesoureiro(a)                    | Igreja             | Regista entradas e saídas, contagens, recibos e remessas; nunca aprova o que regista             |
| Ancião                           | Igreja             | Aprova saídas e despesas, fecha e reabre o mês, conduz reuniões                                  |
| Pastor                           | Igreja ou distrito | Acompanha todas as igrejas do distrito; gere a secretaria e aprova despesas                      |
| Director(a) da Escola Sabatina   | Igreja             | Configura classes e alvos; acompanha o painel e a classificação                                  |
| Secretário(a) da Escola Sabatina | Igreja             | Regista o relatório de cada sábado, a chamada e os visitantes                                    |
| Director(a) de departamento      | Igreja             | Planeia actividades e escalas; pede despesas                                                     |
| Administrador                    | Igreja             | Gere utilizadores e a configuração técnica; não vê dados de disciplina                           |
| Membro                           | Os seus dados      | Consulta a sua ficha, contribuições, recibos e escalas; contribui por M-Pesa                     |
| Administração da Associação      | Associação         | Gere igrejas, distritos, tabelas comuns e utilizadores                                           |
| Tesouraria da Associação         | Associação         | Consulta as tesourarias e confirma a recepção das remessas                                       |
| Secretaria da Associação         | Associação         | Consulta os livros de membros e as estatísticas                                                  |

*Tabela 3 · Utilizadores e perfis*

## 2.4 Módulos

| **Módulo**      | **Descrição**                                                                                                                   |
|-----------------|---------------------------------------------------------------------------------------------------------------------------------|
| Núcleo          | Utilizadores, perfis e permissões; sessões de login; histórico de todas as alterações                                           |
| Organização     | Estrutura da Igreja (Divisão, União, Associação/Missão, distritos, igrejas, grupos e filiais), departamentos e cargos           |
| Secretaria      | Membros, famílias, consentimentos, reuniões e votos, livro de membros, transferências, disciplina, eleições e baptismos         |
| Actividades     | Actividades dos departamentos, material necessário e escalas de serviço                                                         |
| Escola Sabatina | Trimestres, classes por divisão, matrículas, relatório de cada sábado, chamada, visitantes, pontuação e painel                  |
| Tesouraria      | Contas, fundos, movimentos divididos por fundo, despesas, contagens, recibos, remessas, orçamento, fecho mensal e reconciliação |
| Pagamentos      | Integração com o M-Pesa (Vodacom) e registo de pagamentos bancários                                                             |
| Comunicação     | Fila de mensagens por SMS, WhatsApp e e-mail, sempre com consentimento do membro                                                |

*Tabela 4 · Módulos do sistema*

## 2.5 Arquitectura

<img src="media/66dd37ce9a5501fc8f0d7b3027f8a78331d67487.png" title="Figura 1 · Arquitectura do sistema" style="width:6.25in;height:2.91667in" alt="Figura 1 · Arquitectura do sistema" />

*Figura 1 · Arquitectura do sistema*

| **Componente**    | **Função**                                                                                                                              |
|-------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| Aplicação (PWA)   | Interface no computador e no telemóvel. Mostra a cada pessoa apenas o que pode fazer. Funciona sem rede no relatório da Escola Sabatina |
| API               | Autentica o utilizador, abre a sessão na base de dados em cada pedido, traduz os pedidos em SQL e devolve as respostas                  |
| Trabalhador       | Executa as tarefas automáticas: consultas ao M-Pesa, envio de mensagens, lembretes e manutenção                                         |
| PostgreSQL        | Guarda os dados e aplica as regras de negócio e as permissões antes de qualquer leitura ou escrita                                      |
| Serviços externos | Vodacom M-Pesa, fornecedores de SMS e WhatsApp, armazenamento de ficheiros (S3)                                                         |

*Tabela 5 · Componentes da arquitectura*

## 2.6 Princípios de concepção

| **Princípio**             | **Descrição**                                                                                            |
|---------------------------|----------------------------------------------------------------------------------------------------------|
| A base de dados decide    | Regras e permissões estão no PostgreSQL. A API e a aplicação não as repetem e não as conseguem contornar |
| Nada se apaga             | Os registos terminam com uma data de fim; os erros de dinheiro corrigem-se com estornos                  |
| Tudo fica registado       | Cada registo guarda quem o criou e alterou, e quando; cada alteração fica no histórico de auditoria      |
| Segregação de funções     | Quem regista uma saída não a aprova; ninguém altera os próprios perfis                                   |
| Conformidade com o Manual | Admissões, transferências, censuras e eleições exigem o voto e o tipo de reunião que o Manual prevê      |
| Privacidade               | Dados sensíveis (disciplina, contactos de menores) só para quem precisa; consentimento para mensagens    |

*Tabela 6 · Princípios de concepção*

# 3. Funcionalidades

Este capítulo descreve cada funcionalidade do sistema, agrupada por módulo. Cada funcionalidade tem um identificador (F-módulo-número) usado nos processos (capítulo 4), nos testes e no plano de trabalho.

## 3.1 Núcleo: acesso e auditoria

Controla quem entra no sistema, o que cada pessoa pode fazer e o registo de todas as alterações.

| **ID**   | **Funcionalidade**      | **Descrição**                                                                                                                                                                     | **Utilizadores**                           |
|----------|-------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------|
| F-NUC-01 | Autenticação            | Entrada com e-mail ou telefone e senha. A sessão dura 15 minutos e renova-se automaticamente até 30 dias. Após 10 tentativas falhadas seguidas, o login fica bloqueado 15 minutos | Todos                                      |
| F-NUC-02 | Recuperação de senha    | Envio de um código de 6 dígitos por SMS ou WhatsApp, válido 15 minutos e com 5 tentativas. A senha nova termina todas as sessões abertas                                          | Todos                                      |
| F-NUC-03 | Gestão de utilizadores  | Criar e desactivar utilizadores e ligá-los a um membro. Só se gerem utilizadores das igrejas que se administram                                                                   | Administrador                              |
| F-NUC-04 | Atribuição de perfis    | Dar perfis numa igreja ou numa Associação. Ninguém altera os próprios perfis nem dá um perfil com mais permissões do que as suas                                                  | Administrador, Administração da Associação |
| F-NUC-05 | As minhas permissões    | Lista do que o utilizador pode fazer em cada igreja; a aplicação usa-a para montar menus e botões                                                                                 | Todos                                      |
| F-NUC-06 | Histórico de alterações | Consulta de quem alterou cada registo, quando, e que valores mudaram                                                                                                              | Administração da Associação                |

*Tabela 7 · Funcionalidades · Núcleo: acesso e auditoria*

## 3.2 Organização

Mantém a estrutura da Igreja, da Divisão à igreja local, e os catálogos de departamentos e cargos.

| **ID**   | **Funcionalidade**        | **Descrição**                                                                                          | **Utilizadores**                           |
|----------|---------------------------|--------------------------------------------------------------------------------------------------------|--------------------------------------------|
| F-ORG-01 | Estrutura denominacional  | Divisão, União, Associação ou Missão, em árvore. Define a que entidade cada igreja remete os fundos    | Administração da Associação                |
| F-ORG-02 | Distritos pastorais       | Agrupa igrejas num distrito e indica o pastor, que passa a acompanhar todas essas igrejas              | Administração da Associação                |
| F-ORG-03 | Igrejas, grupos e filiais | Registo de igrejas organizadas, grupos organizados, grupos e filiais, com a igreja-mãe e o código ACMS | Administração da Associação                |
| F-ORG-04 | Departamentos e cargos    | Catálogo de departamentos e cargos do Manual (já carregado) e os departamentos activos em cada igreja  | Administrador, Administração da Associação |

*Tabela 8 · Funcionalidades · Organização*

## 3.3 Secretaria

Mantém o livro de membros conforme o Manual da Igreja: cada entrada e saída é autorizada por um voto registado em acta.

| **ID**   | **Funcionalidade**       | **Descrição**                                                                                                                                                                                   | **Utilizadores**             |
|----------|--------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------|
| F-SEC-01 | Registo de membros       | Ficha com dados pessoais, contactos, família e encarregado (menores). Entra como interessado e é validada pela secretaria                                                                       | Secretário                   |
| F-SEC-02 | Famílias                 | Agrupa membros de uma casa; permite contribuições em nome da família e o resumo de baptizados                                                                                                   | Secretário                   |
| F-SEC-03 | Consentimentos e menores | Regista os consentimentos para dados pessoais, fotografias e mensagens; nos menores, dados pelo encarregado. Lista os menores com pendências                                                    | Secretário                   |
| F-SEC-04 | Reuniões e votos         | Regista junta directiva, reunião regular, assembleia administrativa, comissão de nomeações e conselho da ES, com cada voto numerado, a leitura e o resultado                                    | Secretário, Ancião, Pastor   |
| F-SEC-05 | Livro de membros         | Cada admissão (baptismo, rebaptismo, profissão de fé, transferência) e saída (transferência, falecimento, remoção, desaparecido) com o voto que a autoriza. O estado do membro só muda por aqui | Secretário                   |
| F-SEC-06 | Transferências           | Pedido, carta da igreja de origem e aceitação da igreja de destino, com segunda leitura e prazo de 6 meses                                                                                      | Secretários das duas igrejas |
| F-SEC-07 | Disciplina               | Censura de 1 a 12 meses votada pela igreja. Durante a censura o membro não ocupa cargos nem recebe carta. Visível só ao pastor e ao secretário                                                  | Secretário, Pastor           |
| F-SEC-08 | Eleições e mandatos      | Mandatos de cada cargo com o voto da eleição; aviso dos mandatos a terminar                                                                                                                     | Secretário                   |
| F-SEC-09 | Baptismos                | Data, local, pastor e a classe da Escola Sabatina que preparou o candidato                                                                                                                      | Secretário                   |
| F-SEC-10 | Relatórios da secretaria | Relatório mensal à Associação (entradas e saídas por tipo), cartas pendentes, censuras activas, mandatos a terminar                                                                             | Secretário, Associação       |

*Tabela 9 · Funcionalidades · Secretaria*

## 3.4 Actividades

Apoia os departamentos a planear actividades e a organizar as escalas de serviço.

| **ID**   | **Funcionalidade** | **Descrição**                                                                                                        | **Utilizadores**               |
|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|--------------------------------|
| F-ACT-01 | Actividades        | Actividade de um departamento com responsável, local, datas, valor previsto e lembrete automático                    | Directores de departamento     |
| F-ACT-02 | Material           | Lista do material necessário para cada actividade, com quantidade e preço                                            | Directores de departamento     |
| F-ACT-03 | Escalas de serviço | Escala por período (ex.: escala de pregação do trimestre) com os sábados, dias especiais, grupo coral e departamento; pregador, tradutor, acompanhantes, ancião do dia, diáconos e outras funções, com substitutos; publicada para os membros; lembrete por SMS à quarta e à sexta | Secretário, Ancião, Directores |

*Tabela 10 · Funcionalidades · Actividades*

## 3.5 Escola Sabatina

Substitui o Quadro Comparativo em Excel: regista cada sábado por classe e calcula a pontuação e a classificação com as mesmas fórmulas.

| **ID**  | **Funcionalidade**            | **Descrição**                                                                                                            | **Utilizadores**                 |
|---------|-------------------------------|--------------------------------------------------------------------------------------------------------------------------|----------------------------------|
| F-ES-01 | Trimestres e sábados          | Calendário de cada trimestre (13 ou 14 sábados) e o sábado da oferta do 13º sábado                                       | Administração da Associação      |
| F-ES-02 | Classes e matrículas          | Classes por divisão (rol do berço a adultos) e a inscrição de membros e interessados                                     | Director da ES, Secretário da ES |
| F-ES-03 | Classe no trimestre           | Professor, auxiliar, secretário, alvos (membros, estudo diário, filiais, ofertas, baptismos) e se a classe está activa   | Director da ES                   |
| F-ES-04 | Relatório do sábado           | M.M., M.P., E.D., visitantes, filiais e três ofertas separadas: missões, 13º sábado e despesas                           | Secretário da ES                 |
| F-ES-05 | Chamada nominal               | Presença e estudo da lição por pessoa; recalcula M.P. e E.D. automaticamente                                             | Secretário da ES                 |
| F-ES-06 | Visitantes                    | Nome, contacto e quem convidou, para seguimento; anonimizados após 12 meses se não se tornarem membros                   | Secretário da ES                 |
| F-ES-07 | Pontuação e classificação     | Pontuação de 0 a 100 (presença 30%, estudo 30%, ofertas 25%, visitantes 15%, pesos configuráveis) e lugar de cada classe | Director da ES, Pastor           |
| F-ES-08 | Painel e relatório trimestral | Totais da igreja e relatório consolidado por Associação e por divisão                                                    | Director da ES, Associação       |

*Tabela 11 · Funcionalidades · Escola Sabatina*

## 3.6 Tesouraria

Regista todo o dinheiro da igreja com divisão por fundos, separação entre quem regista e quem aprova, e remessa dos fundos da Associação.

| **ID**   | **Funcionalidade**          | **Descrição**                                                                                                        | **Utilizadores**                     |
|----------|-----------------------------|----------------------------------------------------------------------------------------------------------------------|--------------------------------------|
| F-TES-01 | Contas                      | Contas M-Pesa, bancárias e caixa, com moeda e saldo inicial                                                          | Tesoureiro                           |
| F-TES-02 | Fundos e categorias         | Fundos da Associação (100% remetidos) e locais; plano de contas de receitas e despesas                               | Tesoureiro, Associação               |
| F-TES-03 | Entradas                    | Uma entrega dividida por vários fundos (ex.: dízimo + oferta + 13º sábado), em nome de um membro, família ou anónima | Tesoureiro                           |
| F-TES-04 | Contagem de numerário       | Contagem do dinheiro do culto por duas pessoas diferentes e conferência com o lançado                                | Tesoureiro, Diácono                  |
| F-TES-05 | Recibos                     | Recibos numerados por igreja e por ano, enviados ao membro por WhatsApp ou SMS se consentiu                          | Tesoureiro                           |
| F-TES-06 | Despesas                    | Requisição por um departamento, decisão por ancião ou pastor (pode aprovar menos) e pagamento pelo tesoureiro        | Directores, Ancião, Tesoureiro       |
| F-TES-07 | Saídas                      | Saídas com aprovação de outra pessoa. O dízimo e as ofertas missionárias só saem como remessa                        | Tesoureiro, Ancião                   |
| F-TES-08 | Estornos                    | Correcção de um movimento confirmado por um movimento contrário, com aprovação                                       | Tesoureiro, Ancião                   |
| F-TES-09 | Transferências entre contas | Ex.: depósito do dinheiro da caixa no banco, sem afectar os fundos                                                   | Tesoureiro                           |
| F-TES-10 | Remessas                    | Cálculo do devido por fundo e mês, envio à Associação e confirmação de recepção                                      | Tesoureiro, Tesouraria da Associação |
| F-TES-11 | Orçamento                   | Orçamento anual por categoria, aprovado por voto da igreja, e a sua execução                                         | Tesoureiro, Ancião                   |
| F-TES-12 | Alvos                       | Alvos de arrecadação por fundo e período, com a percentagem atingida                                                 | Tesoureiro                           |
| F-TES-13 | Fecho mensal                | Bloqueia os movimentos de um mês conferido; reabrir fica registado                                                   | Ancião                               |
| F-TES-14 | Reconciliação               | Importação do extracto bancário ou M-Pesa e ligação de cada linha a um movimento                                     | Tesoureiro                           |
| F-TES-15 | Saldos e relatórios         | Saldos por conta e por fundo, contribuições por membro, declaração anual, despesas por pagar                         | Tesoureiro, Ancião, Membro           |

*Tabela 12 · Funcionalidades · Tesouraria*

## 3.7 Pagamentos

Permite contribuir por M-Pesa a partir da aplicação, com confirmação automática e recibo.

| **ID**   | **Funcionalidade**    | **Descrição**                                                                                                        | **Utilizadores**   |
|----------|-----------------------|----------------------------------------------------------------------------------------------------------------------|--------------------|
| F-PAG-01 | Pagamento M-Pesa      | O membro indica o número e o valor por fundo e confirma no telemóvel; a entrada fica confirmada e o recibo é enviado | Membro, Tesoureiro |
| F-PAG-02 | Registo das respostas | Guarda todas as respostas da Vodacom, ignora repetições e consulta os pedidos sem resposta                           | Sistema            |
| F-PAG-03 | Pagamentos bancários  | Dados bancários de pagamentos por transferência (NIB, titular, referência)                                           | Tesoureiro         |

*Tabela 13 · Funcionalidades · Pagamentos*

## 3.8 Comunicação

Envia mensagens aos membros, sempre respeitando o consentimento dado para cada canal.

| **ID**   | **Funcionalidade**    | **Descrição**                                                                                | **Utilizadores** |
|----------|-----------------------|----------------------------------------------------------------------------------------------|------------------|
| F-COM-01 | Fila de mensagens     | SMS, WhatsApp e e-mail com agendamento, até 3 tentativas e registo do resultado              | Sistema          |
| F-COM-02 | Lembretes automáticos | Relatórios da ES em falta, escalas da semana, cartas e mandatos, remessa do mês, actividades | Sistema          |

*Tabela 14 · Funcionalidades · Comunicação*

# 4. Processos de negócio

Este capítulo descreve os processos da igreja suportados pelo sistema. Para cada processo indica-se o objectivo, quem participa, o que tem de existir antes, os passos com a chamada à API correspondente, as situações que o sistema recusa e o resultado final. As validações indicadas são feitas pela base de dados e chegam à aplicação como mensagens em português.

| **ID** | **Processo**                                       | **Funcionalidades**                              |
|--------|----------------------------------------------------|--------------------------------------------------|
| P-01   | Admissão de membro por baptismo ou profissão de fé | F-SEC-01, F-SEC-03, F-SEC-04, F-SEC-05, F-SEC-09 |
| P-02   | Transferência de membro                            | F-SEC-05, F-SEC-06                               |
| P-03   | Censura e remoção de membro                        | F-SEC-05, F-SEC-07                               |
| P-04   | Eleição de oficiais                                | F-SEC-04, F-SEC-08                               |
| P-05   | Relatório do sábado na Escola Sabatina             | F-ES-03 a F-ES-07, F-TES-03                      |
| P-06   | Entrada de dinheiro em numerário                   | F-TES-03, F-TES-04, F-TES-05                     |
| P-07   | Despesa com requisição                             | F-TES-06, F-TES-07, F-TES-11                     |
| P-08   | Saída avulsa                                       | F-TES-07                                         |
| P-09   | Remessa mensal à Associação                        | F-TES-10                                         |
| P-10   | Fecho do mês                                       | F-TES-13, F-TES-14                               |
| P-11   | Contribuição por M-Pesa                            | F-PAG-01, F-PAG-02, F-TES-05                     |
| P-12   | Correcção de um erro de dinheiro (estorno)         | F-TES-08                                         |
| P-13   | Atribuição de acessos                              | F-NUC-03, F-NUC-04                               |

*Tabela 15 · Lista de processos*

## P-01 Admissão de membro por baptismo ou profissão de fé

Regista a entrada de uma pessoa como membro da igreja, desde o primeiro contacto como interessado até ao voto da igreja e ao registo no livro de membros.

<table>
<colgroup>
<col style="width: 23%" />
<col style="width: 76%" />
</colgroup>
<tbody>
<tr class="odd">
<td><strong>Objectivo</strong></td>
<td>Garantir que só passa a membro quem foi votado pela igreja, como exige o Manual, e que o livro de membros fica com o voto que autoriza a admissão.</td>
</tr>
<tr class="even">
<td><strong>Actores</strong></td>
<td>Secretário(a); junta directiva; igreja reunida; pastor (baptismo)</td>
</tr>
<tr class="odd">
<td><strong>Pré-condições</strong></td>
<td><p>• A pessoa está registada como interessada</p>
<p>• Para menores: encarregado e consentimento registados</p></td>
</tr>
<tr class="even">
<td><strong>Resultado</strong></td>
<td><p>• Membro activo na igreja, com data e modo de entrada</p>
<p>• Movimento contado no relatório mensal à Associação</p></td>
</tr>
<tr class="odd">
<td><strong>Regra de referência</strong></td>
<td>Manual da Igreja e [R2]: a admissão exige voto da igreja; a junta apenas recomenda.</td>
</tr>
<tr class="even">
<td><strong>Funcionalidades</strong></td>
<td>F-SEC-01, F-SEC-03, F-SEC-04, F-SEC-05, F-SEC-09</td>
</tr>
</tbody>
</table>

**Fluxo principal**

| **\#** | **Actor**       | **Acção**                                                       | **Chamada à API**                        |
|--------|-----------------|-----------------------------------------------------------------|------------------------------------------|
| 1      | Secretário      | Regista a pessoa como interessada, com contactos e família      | POST /v1/secretaria/membros              |
| 2      | Secretário      | Confere os dados e aprova o registo                             | POST /v1/secretaria/membros/{id}/validar |
| 3      | Junta directiva | Recomenda a admissão (fica em acta)                             | POST /v1/secretaria/reunioes/{id}/votos  |
| 4      | Igreja          | Vota a admissão em reunião regular ou assembleia administrativa | POST /v1/secretaria/reunioes/{id}/votos  |
| 5      | Secretário      | Regista o baptismo (data, local, pastor, classe da ES)          | POST /v1/secretaria/baptismos            |
| 6      | Secretário      | Regista o movimento no livro de membros com o voto              | POST /v1/secretaria/movimentos-membro    |

**Excepções e validações**

- Voto tomado pela junta directiva: recusado ("este acto exige reunião regular ou assembleia administrativa")

- Voto não aprovado ou de outra igreja: recusado

- Alterar o estado do membro directamente: recusado (só por movimento)

## P-02 Transferência de membro

Transfere um membro de uma igreja para outra através da carta de transferência, com o voto das duas igrejas.

<table>
<colgroup>
<col style="width: 23%" />
<col style="width: 76%" />
</colgroup>
<tbody>
<tr class="odd">
<td><strong>Objectivo</strong></td>
<td>Manter o membro sempre registado numa só igreja e cumprir os prazos e votos do Manual.</td>
</tr>
<tr class="even">
<td><strong>Actores</strong></td>
<td>Membro; secretários das igrejas de origem e destino; as duas igrejas</td>
</tr>
<tr class="odd">
<td><strong>Pré-condições</strong></td>
<td><p>• Membro activo na igreja de origem</p>
<p>• Membro sem censura em vigor</p></td>
</tr>
<tr class="even">
<td><strong>Resultado</strong></td>
<td><p>• Saída registada na origem e entrada no destino</p>
<p>• Membro activo na igreja de destino</p></td>
</tr>
<tr class="odd">
<td><strong>Regra de referência</strong></td>
<td>[R2]: a carta é válida 6 meses e o membro permanece na origem até o destino confirmar.</td>
</tr>
<tr class="even">
<td><strong>Funcionalidades</strong></td>
<td>F-SEC-05, F-SEC-06</td>
</tr>
</tbody>
</table>

**Fluxo principal**

| **\#** | **Actor**             | **Acção**                                          | **Chamada à API**                                    |
|--------|-----------------------|----------------------------------------------------|------------------------------------------------------|
| 1      | Membro ou secretário  | Pede a carta, indicando a igreja de destino        | POST /v1/secretaria/transferencias                   |
| 2      | Igreja de origem      | Primeira leitura numa semana e votação na seguinte | Voto com leitura = 2                                 |
| 3      | Secretário da origem  | Emite a carta com o voto                           | POST /v1/secretaria/transferencias/{id}/emitir-carta |
| 4      | Igreja de destino     | Vota a aceitação, também em duas leituras          | Voto com leitura = 2                                 |
| 5      | Secretário do destino | Conclui a transferência                            | POST /v1/secretaria/transferencias/{id}/concluir     |

**Excepções e validações**

- Membro sob censura: carta recusada

- Voto sem segunda leitura: recusado

- Aceitação mais de 6 meses depois da carta: recusada (carta expirada)

## P-03 Censura e remoção de membro

Aplica a disciplina votada pela igreja e, quando for o caso, remove o membro do livro.

<table>
<colgroup>
<col style="width: 23%" />
<col style="width: 76%" />
</colgroup>
<tbody>
<tr class="odd">
<td><strong>Objectivo</strong></td>
<td>Aplicar a disciplina com o devido processo, protegendo a confidencialidade e os menores.</td>
</tr>
<tr class="even">
<td><strong>Actores</strong></td>
<td>Igreja; secretário(a); pastor</td>
</tr>
<tr class="odd">
<td><strong>Pré-condições</strong></td>
<td>Voto da igreja em reunião regular ou assembleia administrativa</td>
</tr>
<tr class="even">
<td><strong>Resultado</strong></td>
<td><p>• Membro sem cargos e sem direito a carta durante a censura</p>
<p>• Remoção contada no relatório mensal</p></td>
</tr>
<tr class="odd">
<td><strong>Regra de referência</strong></td>
<td>Manual: a censura dura de 1 a 12 meses; o desaparecido só é removido após 2 anos de buscas e voto.</td>
</tr>
<tr class="even">
<td><strong>Funcionalidades</strong></td>
<td>F-SEC-05, F-SEC-07</td>
</tr>
</tbody>
</table>

**Fluxo principal**

| **\#** | **Actor**  | **Acção**                                        | **Chamada à API**                     |
|--------|------------|--------------------------------------------------|---------------------------------------|
| 1      | Igreja     | Vota a censura ou a remoção                      | Voto do tipo DISCIPLINA ou REMOCAO    |
| 2      | Secretário | Regista a censura com o período (1 a 12 meses)   | POST /v1/secretaria/disciplinas       |
| 3      | Sistema    | Termina os cargos do membro                      | Automático                            |
| 4      | Secretário | Se votada, regista a remoção no livro de membros | POST /v1/secretaria/movimentos-membro |

**Excepções e validações**

- Censura superior a 12 meses: recusada

- Membro menor sem aviso aos pais: recusada

- Remoção por disciplina ou desaparecimento sem voto da assembleia administrativa: recusada

## P-04 Eleição de oficiais

Regista os oficiais eleitos pela igreja sob proposta da comissão de nomeações.

|                         |                                                                            |
|-------------------------|----------------------------------------------------------------------------|
| **Objectivo**           | Garantir que os cargos são ocupados por membros activos, eleitos por voto. |
| **Actores**             | Comissão de nomeações; igreja; secretário(a)                               |
| **Pré-condições**       | Relatório da comissão de nomeações preparado                               |
| **Resultado**           | Mandatos activos; aviso 60 dias antes do fim                               |
| **Regra de referência** | Manual: os oficiais são membros em situação regular, eleitos pela igreja.  |
| **Funcionalidades**     | F-SEC-04, F-SEC-08                                                         |

**Fluxo principal**

| **\#** | **Actor**             | **Acção**                       | **Chamada à API**            |
|--------|-----------------------|---------------------------------|------------------------------|
| 1      | Comissão de nomeações | Reúne e prepara a lista         | POST /v1/secretaria/reunioes |
| 2      | Igreja                | Vota o relatório                | Voto do tipo ELEICAO         |
| 3      | Secretário            | Regista cada mandato com o voto | POST /v1/secretaria/oficiais |

**Excepções e validações**

- Membro não activo ou de outra igreja: recusado

- Membro sob censura: recusado

## P-05 Relatório do sábado na Escola Sabatina

Regista, em cada sábado e para cada classe, os números da Escola Sabatina e as ofertas, e liga as ofertas à tesouraria.

<table>
<colgroup>
<col style="width: 23%" />
<col style="width: 76%" />
</colgroup>
<tbody>
<tr class="odd">
<td><strong>Objectivo</strong></td>
<td>Substituir o quadro em papel e Excel e garantir que as ofertas registadas na classe são as mesmas que entram na tesouraria.</td>
</tr>
<tr class="even">
<td><strong>Actores</strong></td>
<td>Director(a) da ES; secretário(a) da ES; tesoureiro(a)</td>
</tr>
<tr class="odd">
<td><strong>Pré-condições</strong></td>
<td><p>• Trimestre e sábados criados</p>
<p>• Classe configurada para o trimestre</p></td>
</tr>
<tr class="even">
<td><strong>Resultado</strong></td>
<td><p>• Classificação e painel actualizados</p>
<p>• Ofertas missionárias contadas na remessa do mês</p></td>
</tr>
<tr class="odd">
<td><strong>Regra de referência</strong></td>
<td>Manual: a oferta para despesas da ES fica separada da oferta missionária.</td>
</tr>
<tr class="even">
<td><strong>Funcionalidades</strong></td>
<td>F-ES-03 a F-ES-07, F-TES-03</td>
</tr>
</tbody>
</table>

**Fluxo principal**

| **\#** | **Actor**        | **Acção**                                                                      | **Chamada à API**                          |
|--------|------------------|--------------------------------------------------------------------------------|--------------------------------------------|
| 1      | Director da ES   | No início do trimestre, configura professor, secretário e alvos de cada classe | POST /v1/escola-sabatina/classes-trimestre |
| 2      | Secretário da ES | Abre o relatório da classe (M.M. calculado se não indicado)                    | POST /v1/escola-sabatina/relatorios-sabado |
| 3      | Secretário da ES | Faz a chamada (opcional) e regista visitantes                                  | PUT .../relatorios-sabado/{id}/presencas   |
| 4      | Secretário da ES | Anota as três ofertas: missões, 13º sábado, despesas                           | PATCH .../relatorios-sabado/{id}           |
| 5      | Tesoureiro       | Lança as ofertas na tesouraria e liga-as ao relatório                          | POST .../relatorios-sabado/{id}/ofertas    |
| 6      | Secretário da ES | Fecha o relatório                                                              | POST .../relatorios-sabado/{id}/fechar     |

**Excepções e validações**

- Sábado de outro trimestre: recusado

- Presentes acima dos matriculados: recusado

- Fechar sem as ofertas confirmadas nos fundos certos: recusado

- Alterar um relatório fechado: recusado (só o director reabre)

## P-06 Entrada de dinheiro em numerário

Regista o dinheiro recolhido num culto, desde a contagem até aos recibos.

<table>
<colgroup>
<col style="width: 23%" />
<col style="width: 76%" />
</colgroup>
<tbody>
<tr class="odd">
<td><strong>Objectivo</strong></td>
<td>Assegurar que o dinheiro contado é igual ao lançado e que cada contribuinte recebe recibo.</td>
</tr>
<tr class="even">
<td><strong>Actores</strong></td>
<td>Tesoureiro(a); diácono</td>
</tr>
<tr class="odd">
<td><strong>Pré-condições</strong></td>
<td><p>• Conta de caixa criada</p>
<p>• Fundos e categorias configurados</p></td>
</tr>
<tr class="even">
<td><strong>Resultado</strong></td>
<td><p>• Saldos da conta e dos fundos actualizados</p>
<p>• Recibo enviado ao membro, se consentiu</p></td>
</tr>
<tr class="odd">
<td><strong>Funcionalidades</strong></td>
<td>F-TES-03, F-TES-04, F-TES-05</td>
</tr>
</tbody>
</table>

**Fluxo principal**

| **\#** | **Actor**            | **Acção**                                                | **Chamada à API**                          |
|--------|----------------------|----------------------------------------------------------|--------------------------------------------|
| 1      | Tesoureiro e diácono | Contam o dinheiro juntos e registam o total              | POST /v1/tesouraria/contagens              |
| 2      | Tesoureiro           | Lança cada envelope com uma linha por fundo              | POST /v1/tesouraria/transacoes             |
| 3      | Tesoureiro           | Emite o recibo de cada contribuinte identificado         | POST /v1/tesouraria/transacoes/{id}/recibo |
| 4      | Tesoureiro           | Confere: diferença entre contado e lançado deve ser zero | GET /v1/tesouraria/conferencia-contagens   |

**Excepções e validações**

- A mesma pessoa como os dois contadores: recusado

- Soma das linhas diferente do total: recusado

- Mês já fechado: recusado

## P-07 Despesa com requisição

Pagamento de uma despesa pedida por um departamento, com aprovação prévia.

<table>
<colgroup>
<col style="width: 23%" />
<col style="width: 76%" />
</colgroup>
<tbody>
<tr class="odd">
<td><strong>Objectivo</strong></td>
<td>Garantir que nenhuma despesa é paga sem aprovação de uma pessoa diferente de quem a pediu.</td>
</tr>
<tr class="even">
<td><strong>Actores</strong></td>
<td>Director(a) de departamento; ancião ou pastor; tesoureiro(a)</td>
</tr>
<tr class="odd">
<td><strong>Pré-condições</strong></td>
<td>Orçamento ou fundo com saldo</td>
</tr>
<tr class="even">
<td><strong>Resultado</strong></td>
<td><p>• Despesa marcada como paga</p>
<p>• Execução do orçamento actualizada</p></td>
</tr>
<tr class="odd">
<td><strong>Funcionalidades</strong></td>
<td>F-TES-06, F-TES-07, F-TES-11</td>
</tr>
</tbody>
</table>

**Fluxo principal**

| **\#** | **Actor**                | **Acção**                                              | **Chamada à API**                         |
|--------|--------------------------|--------------------------------------------------------|-------------------------------------------|
| 1      | Director de departamento | Pede a despesa e junta a factura                       | POST /v1/tesouraria/despesas              |
| 2      | Ancião ou pastor         | Aprova (podendo reduzir o valor) ou rejeita com motivo | POST /v1/tesouraria/despesas/{id}/decidir |
| 3      | Tesoureiro               | Paga a despesa aprovada                                | POST /v1/tesouraria/transacoes            |

**Excepções e validações**

- Quem pede tenta aprovar: recusado

- Pagar antes de aprovar ou acima do valor aprovado: recusado

- Pagar com dízimo ou ofertas missionárias: recusado

## P-08 Saída avulsa

Saída de dinheiro sem requisição prévia (por exemplo, uma conta de luz).

|                     |                                                                    |
|---------------------|--------------------------------------------------------------------|
| **Objectivo**       | Exigir a aprovação de uma segunda pessoa antes de o dinheiro sair. |
| **Actores**         | Tesoureiro(a); ancião                                              |
| **Pré-condições**   | Nenhuma                                                            |
| **Resultado**       | Saldos actualizados                                                |
| **Funcionalidades** | F-TES-07                                                           |

**Fluxo principal**

| **\#** | **Actor**  | **Acção**                     | **Chamada à API**                             |
|--------|------------|-------------------------------|-----------------------------------------------|
| 1      | Tesoureiro | Regista a saída como pendente | POST /v1/tesouraria/transacoes                |
| 2      | Ancião     | Aprova a saída                | POST /v1/tesouraria/transacoes/{id}/aprovar   |
| 3      | Tesoureiro | Confirma a saída              | POST /v1/tesouraria/transacoes/{id}/confirmar |

**Excepções e validações**

- Confirmar sem aprovação: recusado

- O tesoureiro aprovar a própria saída: recusado

## P-09 Remessa mensal à Associação

Envia à Associação ou Missão os fundos que lhe pertencem, recebidos no mês.

|                         |                                                                                                      |
|-------------------------|------------------------------------------------------------------------------------------------------|
| **Objectivo**           | Remeter todos os meses o valor correcto de cada fundo da Associação.                                 |
| **Actores**             | Tesoureiro(a) da igreja; tesouraria da Associação                                                    |
| **Pré-condições**       | Entradas do mês confirmadas                                                                          |
| **Resultado**           | Valor em falta do mês a zero                                                                         |
| **Regra de referência** | Manual: os fundos da Associação são remetidos no fim de cada mês e não podem ser usados pela igreja. |
| **Funcionalidades**     | F-TES-10                                                                                             |

**Fluxo principal**

| **\#** | **Actor**                | **Acção**                                         | **Chamada à API**                           |
|--------|--------------------------|---------------------------------------------------|---------------------------------------------|
| 1      | Tesoureiro               | Consulta o valor devido por fundo                 | GET /v1/tesouraria/remessas-devidas         |
| 2      | Tesoureiro               | Cria a remessa e paga-a (sem aprovação adicional) | POST /v1/tesouraria/remessas                |
| 3      | Tesoureiro               | Marca a remessa como enviada                      | POST /v1/tesouraria/remessas/{id}/enviar    |
| 4      | Tesouraria da Associação | Confirma a recepção                               | POST /v1/tesouraria/remessas/{id}/confirmar |

**Excepções e validações**

- Tesoureiro da igreja tenta confirmar: recusado

## P-10 Fecho do mês

Confere e bloqueia os movimentos de um mês.

<table>
<colgroup>
<col style="width: 23%" />
<col style="width: 76%" />
</colgroup>
<tbody>
<tr class="odd">
<td><strong>Objectivo</strong></td>
<td>Garantir que as contas de um mês conferido não mudam depois.</td>
</tr>
<tr class="even">
<td><strong>Actores</strong></td>
<td>Ancião; tesoureiro(a)</td>
</tr>
<tr class="odd">
<td><strong>Pré-condições</strong></td>
<td><p>• Remessa do mês enviada</p>
<p>• Extractos reconciliados</p></td>
</tr>
<tr class="even">
<td><strong>Resultado</strong></td>
<td>Mês bloqueado</td>
</tr>
<tr class="odd">
<td><strong>Funcionalidades</strong></td>
<td>F-TES-13, F-TES-14</td>
</tr>
</tbody>
</table>

**Fluxo principal**

| **\#** | **Actor**  | **Acção**                              | **Chamada à API**                       |
|--------|------------|----------------------------------------|-----------------------------------------|
| 1      | Tesoureiro | Importa o extracto e reconcilia        | POST /v1/tesouraria/extractos/importar  |
| 2      | Ancião     | Confere os saldos e fecha o mês        | POST /v1/tesouraria/fechos              |
| 3      | Ancião     | Se necessário, reabre (fica registado) | POST /v1/tesouraria/fechos/{id}/reabrir |

**Excepções e validações**

- Lançar ou alterar movimentos num mês fechado: recusado

- Tesoureiro tenta reabrir: recusado

## P-11 Contribuição por M-Pesa

O membro contribui a partir do telemóvel e recebe o recibo automaticamente.

|                     |                                                                      |
|---------------------|----------------------------------------------------------------------|
| **Objectivo**       | Facilitar a contribuição e evitar pagamentos duplicados ou perdidos. |
| **Actores**         | Membro ou tesoureiro(a); sistema; Vodacom                            |
| **Pré-condições**   | Conta M-Pesa da igreja configurada                                   |
| **Resultado**       | Entrada confirmada e recibo enviado                                  |
| **Funcionalidades** | F-PAG-01, F-PAG-02, F-TES-05                                         |

**Fluxo principal**

| **\#** | **Actor** | **Acção**                                                            | **Chamada à API**                  |
|--------|-----------|----------------------------------------------------------------------|------------------------------------|
| 1      | Membro    | Indica o número e o valor por fundo                                  | POST /v1/tesouraria/mpesa          |
| 2      | Membro    | Confirma no telemóvel com o PIN                                      | —                                  |
| 3      | Sistema   | Recebe a resposta, confirma a entrada e emite o recibo               | POST /v1/tesouraria/mpesa/callback |
| 4      | Sistema   | Consulta os pedidos sem resposta; após 30 minutos marca como falhado | Tarefa automática                  |

**Excepções e validações**

- Valor M-Pesa diferente do total: recusado

- Resposta repetida da Vodacom: ignorada

## P-12 Correcção de um erro de dinheiro (estorno)

Corrige um movimento financeiro já confirmado sem o alterar nem apagar.

|                     |                                                     |
|---------------------|-----------------------------------------------------|
| **Objectivo**       | Manter o histórico completo e auditável das contas. |
| **Actores**         | Tesoureiro(a); ancião                               |
| **Pré-condições**   | Movimento original confirmado                       |
| **Resultado**       | Contribuições e remessas descontam o estorno        |
| **Funcionalidades** | F-TES-08                                            |

**Fluxo principal**

| **\#** | **Actor**  | **Acção**                                | **Chamada à API**                             |
|--------|------------|------------------------------------------|-----------------------------------------------|
| 1      | Tesoureiro | Regista o estorno com o valor e o motivo | POST /v1/tesouraria/transacoes/{id}/estornar  |
| 2      | Ancião     | Aprova o estorno                         | POST /v1/tesouraria/transacoes/{id}/aprovar   |
| 3      | Tesoureiro | Confirma                                 | POST /v1/tesouraria/transacoes/{id}/confirmar |

**Excepções e validações**

- Alterar ou terminar o movimento confirmado: recusado

- Estorno de valor superior ao original: recusado

## P-13 Atribuição de acessos

Dá a uma pessoa acesso ao sistema com o perfil adequado à sua função.

|                     |                                                              |
|---------------------|--------------------------------------------------------------|
| **Objectivo**       | Garantir que cada pessoa tem apenas o acesso de que precisa. |
| **Actores**         | Administrador da igreja ou da Associação                     |
| **Pré-condições**   | Pessoa eleita ou nomeada para a função                       |
| **Resultado**       | O utilizador vê apenas os menus do seu perfil                |
| **Funcionalidades** | F-NUC-03, F-NUC-04                                           |

**Fluxo principal**

| **\#** | **Actor**     | **Acção**                            | **Chamada à API**               |
|--------|---------------|--------------------------------------|---------------------------------|
| 1      | Administrador | Cria o utilizador e liga-o ao membro | POST /v1/nucleo/usuarios        |
| 2      | Administrador | Atribui o perfil na igreja           | POST /v1/nucleo/usuarios-igreja |
| 3      | Utilizador    | Entra e define a senha               | POST /v1/auth/login             |

**Excepções e validações**

- Atribuir um perfil com mais permissões do que as do administrador: recusado

- Alterar os próprios perfis: recusado

- Criar um super-administrador sem o ser: recusado

# 5. Especificação técnica da API

A API é uma camada fina sobre a base de dados. As regras de negócio e as permissões não são reimplementadas na API: ela autentica, identifica o utilizador perante a base de dados, executa o pedido e traduz o resultado.

## 5.1 Ligação à base de dados

A API liga-se sempre com o utilizador api_igreja, membro do papel app_igreja, e nunca com o dono das tabelas (que ignora as permissões).

> CREATE ROLE api_igreja LOGIN PASSWORD '...' IN ROLE app_igreja;
>
> ALTER ROLE api_igreja SET search_path = nucleo, organizacao, secretaria, actividades,
>
> escola_sabatina, tesouraria;

Cada pedido HTTP é executado numa transacção própria, sempre com os mesmos passos:

1.  Obter uma ligação do pool (PgBouncer em modo transacção).

2.  Abrir a transacção (BEGIN).

3.  Identificar o utilizador: SELECT set_config('app.usuario_id', '\<id\>', true).

4.  Executar o pedido.

5.  Terminar com COMMIT ou, em caso de erro, ROLLBACK.

> Sem a identificação do passo 3, a base de dados não devolve dados e recusa qualquer escrita. Este comportamento é implementado uma única vez (interceptor), nunca em cada endpoint.

## 5.2 Autenticação

| **Endpoint**            | **Descrição**                                                                                                                          | **Função na base de dados**                      |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------|
| POST /v1/auth/login     | Valida a senha (Argon2id) e abre a sessão. Devolve o token de acesso (15 min) e grava o token de renovação (30 dias) num cookie seguro | fn_credenciais, fn_abrir_sessao, fn_login_falhou |
| POST /v1/auth/renovar   | Troca o token de renovação por um novo. A reutilização de um token antigo termina todas as sessões                                     | fn_renovar_sessao                                |
| POST /v1/auth/sair      | Termina a sessão                                                                                                                       | fn_terminar_sessao                               |
| POST /v1/auth/recuperar | Envia um código de 6 dígitos; resposta igual exista ou não o utilizador                                                                | fn_pedir_recuperacao                             |
| POST /v1/auth/redefinir | Define a senha nova com o código                                                                                                       | fn_redefinir_senha                               |
| GET /v1/eu              | Utilizador, igrejas e permissões por igreja                                                                                            | fn_minhas_permissoes                             |

*Tabela 16 · Endpoints de autenticação*

## 5.3 Autorização

Cada tabela tem quatro permissões (ler, criar, alterar, terminar), mais nove acções de negócio. A base de dados verifica-as em cada linha, na igreja a que o registo pertence. A matriz completa por perfil está no Anexo A. Quando um registo existe mas o utilizador não o pode ver, a resposta é 404, para não revelar a sua existência.

## 5.4 Convenções

| **Operação**         | **Pedido**                                  | **Resposta**                   |
|----------------------|---------------------------------------------|--------------------------------|
| Listar               | GET /v1/\<módulo\>/\<recurso\>?igrejaId=1   | 200 e uma página de resultados |
| Ler                  | GET /v1/\<módulo\>/\<recurso\>/{id}         | 200 ou 404                     |
| Criar                | POST /v1/\<módulo\>/\<recurso\>             | 201 e o registo criado         |
| Alterar              | PATCH /v1/\<módulo\>/\<recurso\>/{id}       | 200 e o registo                |
| Terminar / reactivar | POST .../{id}/terminar · .../{id}/reactivar | 200                            |

*Tabela 17 · Operações-padrão de cada recurso*

- Não existe DELETE: os registos terminam-se.

- Campos em camelCase, sem o prefixo da tabela (mem_data_nascimento → dataNascimento).

- Dinheiro como texto com duas casas decimais ("650.00"); datas ISO 8601 com fuso.

- Paginação por cursor: 50 por página, máximo 200.

- Pedidos que criam dinheiro levam Idempotency-Key: um pedido repetido não cria duplicados.

## 5.5 Tratamento de erros

| **SQLSTATE**  | **Situação**                       | **HTTP**                  | **Código de erro**  |
|---------------|------------------------------------|---------------------------|---------------------|
| 42501         | Falta de permissão                 | 403                       | sem_permissao       |
| P0001         | Regra de negócio                   | 422                       | regra_negocio       |
| 23514         | Valor fora do permitido            | 422                       | validacao           |
| 23505         | Valor repetido                     | 409                       | duplicado           |
| 23503         | Referência inexistente             | 422                       | referencia_invalida |
| 23502         | Campo obrigatório em falta         | 400                       | campo_obrigatorio   |
| 40001 / 40P01 | Conflito entre pedidos simultâneos | 503 (repetir até 3 vezes) | tentar_novamente    |

*Tabela 18 · Correspondência entre erros da base de dados e HTTP*

> { "erro": "sem_permissao",
>
> "mensagem": "Sem permissão: Aprovar uma saída de dinheiro ... na igreja 1",
>
> "campo": null, "pedidoId": "9f1c2e..." }

## 5.6 Endpoints

O contrato completo (todos os campos, tipos, filtros, respostas e a permissão exigida por cada operação) está no ficheiro openapi.yaml \[R4\]. Resumo por módulo:

| **Módulo**      | **Caminho**         | **Recursos**                                                                                                                       |
|-----------------|---------------------|------------------------------------------------------------------------------------------------------------------------------------|
| Núcleo          | /v1/nucleo          | perfis, permissoes, usuarios, usuarios-igreja, usuarios-entidade, auditoria, notificacoes                                          |
| Organização     | /v1/organizacao     | entidades, distritos, igrejas, departamentos, departamentos-igreja, cargos                                                         |
| Secretaria      | /v1/secretaria      | familias, membros, contactos, consentimentos, reunioes, votos, movimentos-membro, transferencias, disciplinas, oficiais, baptismos |
| Actividades     | /v1/actividades     | actividades, materiais, escalas                                                                                                    |
| Escola Sabatina | /v1/escola-sabatina | trimestres, sabados, classes, classes-trimestre, matriculas, relatorios-sabado, presencas, visitantes, pesos-pontuacao             |
| Tesouraria      | /v1/tesouraria      | contas, fundos, categorias, alvos, orcamentos, despesas, contagens, transacoes, recibos, documentos, remessas, fechos, extractos, mpesa, bancarios |

*Tabela 19 · Recursos por módulo*

## 5.7 Tarefas automáticas

| **Tarefa**                  | **Frequência**  | **Descrição**                                                                    |
|-----------------------------|-----------------|----------------------------------------------------------------------------------|
| Consulta M-Pesa             | 1 minuto        | Consulta os pagamentos sem resposta; marca como falhados após 30 minutos         |
| Envio de mensagens          | 1 minuto        | Envia a fila de SMS, WhatsApp e e-mail (3 tentativas)                            |
| Lembrete da Escola Sabatina | Sábado, 14:00   | Avisa as classes sem relatório                                                   |
| Escalas da semana           | Quarta e sexta, 18:00 | Lembra por SMS quem está escalado para o sábado (só escalas publicadas, com consentimento) |
| Cartas e mandatos           | Segunda, 08:00  | Cartas a expirar e mandatos a terminar                                           |
| Remessa do mês              | Dia 3, 08:00    | Lembra o tesoureiro do valor em falta                                            |
| Manutenção                  | Mensal / diária | Partições do histórico, anonimização de visitantes, limpeza de pedidos repetidos |

*Tabela 20 · Tarefas automáticas*

# 6. Especificação do frontend

## 6.1 Princípios

- Uma só aplicação para computador e telemóvel, instalável (PWA).

- O menu, os ecrãs e os botões dependem das permissões do utilizador; o que não pode fazer não aparece.

- As mensagens de erro da base de dados são mostradas tal como chegam, já em português.

- Os tipos de dados e as validações dos formulários são gerados a partir do openapi.yaml.

## 6.2 Estrutura do código

> src/
>
> api/ cliente gerado do openapi.yaml, token, erros
>
> auth/ login, renovação, pode(permissão, igreja)
>
> layout/ selector de igreja, menu lateral
>
> modulos/
>
> secretaria/ escola-sabatina/ tesouraria/ actividades/
>
> organizacao/ acesso/ eu/
>
> partilhado/ Dinheiro, Data, SeleccionarMembro, Tabela, ...

## 6.3 Ecrãs

| **Ecrã**                  | **Descrição**                                                                                                                                                                       | **Utilizadores**                  |
|---------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------|
| Início por perfil         | Primeira página depois do login, diferente por perfil: o tesoureiro abre em "Lançar entrada", o ancião em "Por aprovar", o secretário no livro de membros, o membro nos seus dados. | Todos                             |
| Selector de igreja        | Na barra superior; escolhe a igreja de trabalho. Todas as listas e formulários usam a igreja escolhida.                                                                             | Quem tem perfil em várias igrejas |
| Lista e ficha de membros  | Procura por nome; ficha com separadores: dados, contactos, família, livro de membros, cargos, Escola Sabatina e contribuições (estes só com permissão).                             | Secretário, Pastor                |
| Reuniões e votos          | Registo da reunião, presenças e votos numerados; o voto indica a leitura e o resultado.                                                                                             | Secretário, Ancião                |
| Novo movimento no livro   | Assistente: escolher o tipo, depois a reunião e o voto. Só mostra as reuniões válidas para o tipo escolhido.                                                                        | Secretário                        |
| Transferência             | Linha do tempo com os passos (pedido, carta, aceitação, conclusão) e o prazo de 6 meses visível.                                                                                    | Secretário                        |
| Sábado da Escola Sabatina | Um ecrã por classe, pensado para o telemóvel: números, chamada com botões grandes, visitantes e as três ofertas. Funciona sem rede.                                                 | Secretário da ES                  |
| Painel e classificação    | Indicadores do trimestre e lugar de cada classe, com a diferença para a média.                                                                                                      | Director da ES, Pastor            |
| Lançar entrada            | Contribuinte (membro, família ou anónimo), conta e linhas por fundo com a soma ao vivo; botão de recibo.                                                                            | Tesoureiro                        |
| Contagem                  | Dois contadores, total contado e diferença para o lançado.                                                                                                                          | Tesoureiro, Diácono               |
| Por aprovar               | Lista única de saídas e despesas pendentes, com o comprovativo ao lado e os botões aprovar ou rejeitar.                                                                             | Ancião, Pastor                    |
| Remessa do mês            | Valores devidos por fundo já preenchidos; envio e estado da confirmação.                                                                                                            | Tesoureiro                        |
| Fecho do mês              | Saldos por conta comparados com o extracto; diferenças destacadas; botão fechar.                                                                                                    | Ancião                            |
| Os meus dados             | Ficha, contribuições do ano, recibos, escalas e contribuição por M-Pesa.                                                                                                            | Membro                            |
| Utilizadores e perfis     | Lista de utilizadores, perfis por igreja e histórico de alterações.                                                                                                                 | Administrador                     |

*Tabela 21 · Ecrãs da aplicação*

## 6.4 Regras de interface

| **Tema**       | **Regra**                                                                                       |
|----------------|-------------------------------------------------------------------------------------------------|
| Valores        | Componente único de dinheiro: aceita "1 500,50", envia "1500.50", mostra "1 500,50 MT"          |
| Datas          | dd/mm/aaaa no ecrã; ISO 8601 na API                                                             |
| Erros          | Com campo indicado: junto ao campo; sem campo: no topo do formulário                            |
| Duplicados     | Cada formulário que cria dinheiro gera uma Idempotency-Key ao abrir                             |
| Sem rede       | Relatório do sábado, chamada e visitantes guardados no telemóvel e enviados quando a rede volta |
| Rede fraca     | Primeira carga abaixo de 300 KB; módulos carregados quando abertos; listas de 50                |
| Acessibilidade | Botões de pelo menos 44 × 44 px, contraste AA, navegação por teclado                            |
| Língua         | Português de Moçambique; textos num ficheiro de traduções                                       |

*Tabela 22 · Regras de interface*

# 7. Requisitos não funcionais

| **ID** | **Categoria**   | **Requisito**                                                                                  | **Referência actual**                                          |
|--------|-----------------|------------------------------------------------------------------------------------------------|----------------------------------------------------------------|
| RNF-01 | Desempenho      | 95% das consultas abaixo de 200 ms                                                             | Consultas do tesoureiro entre 3 e 9 ms no teste de carga       |
| RNF-02 | Capacidade      | Suportar uma Associação com centenas de igrejas                                                | Testado com 300 igrejas, 45 mil membros, 377 mil movimentos    |
| RNF-03 | Gravação        | Pelo menos 1 000 movimentos por segundo                                                        | Cerca de 2 800 por segundo com todas as regras activas         |
| RNF-04 | Disponibilidade | 99,5% por mês                                                                                  | A medir em produção                                            |
| RNF-05 | Recuperação     | Perda máxima de 1 minuto de dados; reposição em 4 horas                                        | Cópia diária + arquivo contínuo; reposição testada mensalmente |
| RNF-06 | Segurança       | HTTPS; senhas com Argon2id; permissões verificadas na base de dados                            | Implementado na base de dados                                  |
| RNF-07 | Auditoria       | Todas as alterações registadas com autor, data e valores                                       | Implementado (histórico particionado por mês)                  |
| RNF-08 | Privacidade     | Dados sensíveis restritos; consentimento para mensagens; visitantes anonimizados após 12 meses | Implementado                                                   |
| RNF-09 | Retenção        | Nenhum registo é apagado                                                                       | Implementado (DELETE proibido)                                 |
| RNF-10 | Compatibilidade | Duas últimas versões de Chrome, Edge e Firefox; Android 8 ou superior                          | A verificar nos testes                                         |
| RNF-11 | Rede            | Utilizável em 3G; relatório da ES sem rede                                                     | A verificar nos testes                                         |
| RNF-12 | Acessibilidade  | WCAG 2.1 nível AA                                                                              | A verificar nos testes                                         |

*Tabela 23 · Requisitos não funcionais*

# 8. Qualidade e testes

Os testes da API correm sempre contra uma base de dados PostgreSQL real, criada pelas migrações. O critério principal é provar que cada perfil faz o que deve e nada mais.

| **Nível**     | **Âmbito**                                                   | **Ferramenta**                  | **Frequência**       |
|---------------|--------------------------------------------------------------|---------------------------------|----------------------|
| Base de dados | Regras do Manual, tesouraria, permissões por perfil, sessões | Testes SQL (pasta testes/)      | Cada migração        |
| Permissões    | Cada endpoint com um perfil autorizado e um não autorizado   | JUnit 5, Testcontainers         | Cada alteração       |
| Processos     | Os 13 processos do capítulo 4, de ponta a ponta              | JUnit 5, REST Assured           | Cada alteração       |
| Interface     | Componentes e processos P-05, P-06, P-07 no navegador        | Vitest, Playwright              | Cada alteração       |
| Carga         | 50 utilizadores a consultar e 4 a lançar                     | k6                              | Antes de cada versão |
| Aceitação     | Processos validados por utilizadores reais da igreja         | Sessões guiadas                 | Fim de cada fase     |

*Tabela 24 · Níveis de teste*

**Critérios de qualidade obrigatórios:** nenhuma alteração que toque em permissões, dinheiro ou no livro de membros entra sem um teste de perfil; a API nunca usa o dono das tabelas; nenhum SQL é montado com texto do pedido; segredos ficam fora do código.

# 9. Implantação e operação

| **Ambiente**    | **Finalidade**                             | **Dados**                     |
|-----------------|--------------------------------------------|-------------------------------|
| Desenvolvimento | Trabalho de cada programador               | Dados de exemplo              |
| Testes          | Validação pela igreja antes de cada versão | Cópia anonimizada da produção |
| Produção        | Uso real                                   | Dados reais                   |

*Tabela 25 · Ambientes*

| **Serviço**                | **Instâncias**                     | **Observações**                                                        |
|----------------------------|------------------------------------|------------------------------------------------------------------------|
| API                        | 2                                  | Atrás do Nginx, com HTTPS                                              |
| Trabalhador                | 1                                  | Tarefas automáticas                                                    |
| Frontend                   | —                                  | Ficheiros estáticos no Nginx                                           |
| PostgreSQL 16 + PgBouncer  | 1 (+ réplica de leitura no futuro) | Estimativa inicial: 4 núcleos e 8 GB, a confirmar com o teste de carga |
| Armazenamento de ficheiros | —                                  | Compatível com S3; comprovativos e actas                               |

*Tabela 26 · Serviços em produção*

**Alterações à base de dados:** só por migrações novas (V15, V16, ...), nunca alterando uma já aplicada; aplicadas primeiro em testes e depois em produção, com cópia de segurança imediatamente antes.

| **Indicador**               | **Alerta quando**                      |
|-----------------------------|----------------------------------------|
| Erros da API                | Mais de 1% em 5 minutos                |
| Tempo de resposta           | 95% acima de 500 ms durante 10 minutos |
| Pagamentos M-Pesa pendentes | Algum há mais de 30 minutos            |
| Mensagens falhadas          | Mais de 20 numa hora                   |
| Disco da base de dados      | Acima de 75%                           |
| Última cópia de segurança   | Mais de 26 horas                       |

*Tabela 27 · Alertas de monitorização*

# 10. Plano de trabalho

Com uma equipa de 2 programadores de API e 2 de frontend, estima-se chegar a 3 igrejas piloto em cerca de 20 semanas. Cada fase termina apenas quando os utilizadores aceitam o resultado. As semanas convertem-se em datas no fim da fase 0, quando se conhecer a velocidade real da equipa.

| **Fase**                | **Semanas** | **Âmbito**                                                                           | **Critério de aceitação**                           |
|-------------------------|-------------|--------------------------------------------------------------------------------------|-----------------------------------------------------|
| 0 · Base                | 1–2         | Repositório, integração contínua, migrações, sessão, autenticação, permissões, erros | Login e permissões testados para os 13 perfis       |
| 1 · Secretaria          | 3–6         | F-SEC-01 a F-SEC-10; processos P-01 a P-04                                           | Processos aceites pelo secretário da igreja piloto  |
| 2 · Tesouraria          | 7–12        | F-TES-01 a F-TES-15; processos P-06 a P-10, P-12                                     | Um mês real em paralelo com o papel, sem diferenças |
| 3 · Escola Sabatina     | 13–15       | F-ES-01 a F-ES-08; processo P-05                                                     | 4 sábados sem papel; classificação igual à planilha |
| 4 · M-Pesa e mensagens  | 16–18       | F-PAG, F-COM; processo P-11                                                          | 50 pagamentos reais sem duplicados nem perdidos     |
| 5 · Associação e piloto | 19–20       | F-ORG, F-NUC-06, relatórios; processo P-13                                           | 3 igrejas usam só o sistema durante um mês          |

*Tabela 28 · Fases do projecto*

**Definição de pronto** (para qualquer funcionalidade): testes de perfil escritos e a passar; mensagens de erro em português no ecrã; funciona num telemóvel com rede 3G; validada por alguém da igreja.

# Anexo A · Matriz de permissões

Acções por perfil e módulo: L = ler, C = criar, A = alterar, T = terminar. Um asterisco (\*) indica que a acção existe só em parte das tabelas do módulo. As tabelas comuns (categorias, departamentos, cargos, trimestres) são legíveis por todos os utilizadores autenticados. O membro sem perfil vê sempre os seus próprios dados. Colunas: NUC Núcleo, ORG Organização, SEC Secretaria, ACT Actividades, ES Escola Sabatina, TES Tesouraria, PAG Pagamentos, COM Comunicação.

| **Perfil**            | **Âmbito** | **NUC**      | **ORG**    | **SEC**      | **ACT**      | **ES**     | **TES**    | **PAG** | **COM** |
|-----------------------|------------|--------------|------------|--------------|--------------|------------|------------|---------|---------|
| ADMIN                 | Igreja     | L\*C\*A\*T\* | LC\*A\*T\* | L\*C\*A\*T\* | LCAT         | LCAT       | LCAT       | LCAT    | LCAT    |
| PASTOR                | Igreja     | L            | L          | LCAT         | LCAT         | L          | L          | L       | L       |
| ANCIAO                | Igreja     | L\*          | L          | LC\*A\*T\*   | LCAT         | L          | LC\*A\*T\* | —       | —       |
| SECRETARIO            | Igreja     | —            | L          | LCAT         | L\*C\*A\*T\* | L          | —          | —       | —       |
| TESOUREIRO            | Igreja     | —            | L          | L\*          | L\*          | L\*        | LCAT\*     | LCAT    | LCAT    |
| DIRECTOR ES           | Igreja     | —            | L\*        | L\*          | L\*C\*A\*T\* | LCAT       | —          | —       | —       |
| SECRETARIO ES         | Igreja     | —            | L\*        | L\*          | —            | LC\*A\*T\* | —          | —       | —       |
| DIRECTOR DEPARTAMENTO | Igreja     | —            | L          | L\*          | LCA          | —          | L\*C\*     | —       | —       |
| MEMBRO                | Igreja     | —            | —          | —            | —            | —          | —          | —       | —       |
| ADMIN ASSOCIACAO      | Associação | LC\*A\*T\*   | LCAT       | L\*          | L            | LC\*A\*T\* | LC\*A\*T\* | L       | L       |
| TESOUREIRO ASSOCIACAO | Associação | —            | L          | —            | —            | —          | LA\*       | L       | —       |
| SECRETARIO ASSOCIACAO | Associação | —            | L          | L\*          | —            | L          | —          | —       | —       |
| INTEGRACAO            | Associação | —            | —          | —            | —            | —          | L\*A\*     | LCA     | LA      |

*Tabela 29 · Matriz de acções por perfil e módulo*

| **Perfil**            | **Acções de negócio**                                                                                                                  |
|-----------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| PASTOR                | membro.validar, transferencia membro.emitir carta, transferencia membro.aceitar, transacao.aprovar, despesa.aprovar, orcamento.aprovar |
| ANCIAO                | transacao.aprovar, despesa.aprovar, orcamento.aprovar                                                                                  |
| SECRETARIO            | membro.validar, transferencia membro.emitir carta, transferencia membro.aceitar                                                        |
| DIRECTOR ES           | relatorio sabado.fechar, relatorio sabado.reabrir                                                                                      |
| SECRETARIO ES         | relatorio sabado.fechar                                                                                                                |
| TESOUREIRO ASSOCIACAO | remessa.confirmar                                                                                                                      |

*Tabela 30 · Acções de negócio por perfil*

# Anexo B · Ficheiros do projecto

| **Ficheiro**                            | **Conteúdo**                                                                                            |
|-----------------------------------------|---------------------------------------------------------------------------------------------------------|
| schema_igreja_v5.sql e migracoes/V1–V13 | Base de dados completa: 59 tabelas, regras, permissões, vistas, dados de referência                     |
| migracoes/V14\_\_sessoes_e_api.sql      | Sessões de login, recuperação de senha, bloqueio de login, pedidos repetidos, ligação das ofertas da ES |
| openapi.yaml                            | Contrato da API (OpenAPI 3.0): 282 caminhos e 396 operações, com a permissão exigida por cada uma       |
| testes/                                 | Testes SQL das regras, das permissões e das sessões; scripts do teste de carga                          |
| gerador/                                | Definição do esquema e programas que geram o SQL e o openapi.yaml                                       |
| CLAUDE.md                               | Instruções do projecto para o Claude Code                                                               |

*Tabela 31 · Ficheiros entregues*
