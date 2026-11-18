# Relatório de entrega — melhoria do sistema de gestão da igreja

Ramo `f-sec-01-membros-e-actividades` · 19 commits · 207 ficheiros · migrações **V33 a V48** · 18 de Novembro de 2026.
Tudo aplicado e a funcionar no servidor de testes (`church_iasd_db`, PostgreSQL 16).

## 1. O que foi implementado, por ponto da especificação

| Ponto | Implementado | Versão |
|---|---|---|
| **4 · Membros** | Ficha completa em 6 secções (pessoais, família, contactos, profissão, religião e baptismo, igreja); cônjuge ligado nos dois registos; ex-membro com o baptismo anterior; campos condicionais que não se apagam; validações (e-mail, telefone, documento). **Registo único**: janela de procura antes de registar (nome como se ouve e trocado, data de nascimento obrigatória, documento, telemóvel, em todas as igrejas); a base de dados recusa o mesmo membro duas vezes; parecidos pedem confirmação. Filtros, exportação e consulta detalhada. | V33, V43, V45 |
| **5 · Departamentos e actividades** | Actividades com objectivos, responsáveis, orçamento, material, despesas e execução; **conflitos de calendário** com datas alternativas e confirmação; programa anual consolidado; **acompanhamento** (realizadas, atrasadas, canceladas com motivo, orçamento, mês a mês, comparação por departamento). | V34, V48 |
| **6 · Área pastoral** | Actividades do distrito nos calendários das igrejas do distrito; **contexto próprio do pastor**, fora da igreja local (Painel do distrito, Programa da área pastoral, Comunicados); o pastor acede a todas as igrejas do distrito por ser o pastor; distritos editáveis (nome, pastor, igrejas). | V35, V48 |
| **7 · Comunicados** | Da igreja, do distrito ou da Associação; para uma, várias ou todas as igrejas; liderança ou todos os membros; datas de publicação e validade; rascunho, publicado, arquivado. | V37 |
| **8 · Mandatos** | Separadores Conselho, Direcção e Oficiais em tabelas; duração configurável; activos e encerrados; histórico. | V31–V33 |
| **9 · Painéis** | **Painel geral** por período (membros, activos, inactivos, %, dízimos com ofertas, reavivamento, fidelidade, entradas e perdas, composição: sexo, idades, estado civil; gráficos; quadro comparativo das igrejas). **Início de cada igreja** com as mesmas métricas filtradas à igreja. | V38, V46 |
| **10 · Reavivamento** | Fundo próprio, contribuições mensais, alvo anual com +5% sugerido e ajustável, histórico. | V36, V38 |
| **11 · Santa Ceia** | Agendamento (data, hora, local, responsável), participantes (homens, mulheres, visitantes), histórico, no Início e nos painéis. | V39 |
| **12 · Famílias** | Parentesco com o chefe; membros sem família em destaque (vermelho) nos painéis. | V40 |
| **13 · Disciplina** | Censuras com tempo cumprido e restante, remoções (botão "Registar remoção"), painel; **motivo confidencial** lido a pedido com registo de acessos. | V41 |
| **14 · Tesouraria** | Dízimo em duplicado (membro/família) avisado; **fundo de maneio**; entrada com 3 ofertas especiais e sem 13.º sábado/oferta missionária na igreja local; **fundo de construção**; contagem com tesoureiro, Escola Sabatina e diácono (obrigatórios); **SMS do recibo** com resumo por fundo, um por recibo, histórico e reenvio. | V36, V42, V43, V45 |
| **15 · Escola Sabatina** | Meta individual por aluno (a da classe é a soma); oferta de cada aluno na chamada (também sem rede); acompanhamento por aluno e por classe; **semanas especiais** com alertas. | V47 |
| **16 · Estado civil** | Casados, solteiros, viúvos, viúvas, noivos (e outros) no Início e no Painel geral. | V36, V46 |
| **17 · Reuniões** | Presidida por, presenças, agenda com descrição, **discussão**, votação e deliberação (aprovada, rejeitada, pendente), secretário oficial por defeito, acta em PDF A4 com assinaturas. | V22, V43 |
| **Escalas e programação** | Escala do Culto Divino; escalas da Escola Sabatina e da JA com colunas definidas por cada igreja (membro ou família); **programação do dia** (folha do sábado) preparada do modelo ou de outro dia, preenchida pela escala, para imprimir. | V44, V45 |
| **20 · Segurança** | RLS e permissões por perfil na base de dados para todas as tabelas novas; dados confidenciais com registo de acessos; auditoria de alterações. | todas |

## 2. Alterações na base de dados (V33–V48)

Nenhuma migração apaga dados; as alterações estruturais são acrescentos (colunas, tabelas, vistas, funções, triggers).

| Versão | Principais alterações |
|---|---|
| V33 | Campos da ficha do membro; cônjuge recíproco; `fn_membros_parecidos` |
| V34 | `actividade_responsavel`; conflitos e datas alternativas; `vw_actividades_execucao` |
| V35 | Actividades do distrito (`act_dst_id`) e acesso do pastor |
| V36 | Participação (inactivos), dízimo sobreposto, alvo +5%, NOIVO |
| V37 | `comunicado`, `comunicado_igreja` |
| V38 | Fundo REAVIVAMENTO; `fn_painel_periodo` |
| V39 | `santa_ceia` |
| V40 | Parentesco na família |
| V41 | Motivo da censura confidencial; `acesso_confidencial` |
| V42 | Fundo de maneio; `contagem_participante`; SMS do recibo |
| V43 | Membro único (`fn_membro_existente`); contagem com três participantes; discussão do ponto |
| V44 | Funções do culto na escala; `programa_dia`, `programa_parte`, `programa_item` |
| V45 | `escala_coluna` (ES e JA); fundo CONSTRUCAO; parte da contagem; procura fonética |
| V46 | `vw_painel_membros`; outras saídas no mensal |
| V47 | `meta_individual`, oferta na chamada, `semana_especial`, vistas das metas |
| V48 | Motivo do cancelamento das actividades |

## 3. APIs criadas ou alteradas

Contrato completo em `api/openapi.yaml` (**388 caminhos, 538 operações**); lista em `docs/ROTAS.md`. As principais novas:

- Membros: `GET /v1/secretaria/membros-parecidos` (com `existe` e `telefone`), `membros-lista`, `participacao`.
- Actividades: `responsaveis-actividade`, `conflitos`, `programa`, `santas-ceias`, `colunas-escala`, `programas-dia` (+ `preparar`, `preencher-escala`), `partes-programa`, `itens-programa`.
- Organização: `painel-periodo`, `painel-membros`, `comunicados`, `comunicados-igrejas`; `GET /v1/eu` com os distritos do pastor.
- Tesouraria: `participantes-contagem`, `contribuicoes-sobrepostas`, `alvo-sugerido`; notificações (`/v1/nucleo/notificacoes`).
- Escola Sabatina: `metas-individuais`, `metas-alunos`, `metas-classes`, `semanas-especiais`; chamada com `oferta`.
- Disciplina: `GET /v1/secretaria/disciplinas/{id}/motivo` (registado), `acessos-confidenciais`.

## 4. Testes executados e resultados

| Testes | Resultado |
|---|---|
| Base de dados (`scripts/db-test.sh`, testes 00–34: regras, permissões por perfil, RLS) | **35 × ok** |
| API (JUnit, `BaseDadosTest`, contrato rotas ↔ openapi) | **121 testes, 0 falhas** |
| Frontend: tipos (`tsc -b`), lint (`eslint`), build (`vite build`) | sem erros |
| Verificações no servidor de testes | números dos painéis e das metas conferidos; login e contexto do pastor pela API |

Cada versão foi testada antes do commit: um teste SQL por versão (recusas, permissões, cálculos) e testes de integração na API.

## 5. Pendente

1. **Testes no browser** (percursos completos, telemóvel, exportações): pedem o `@playwright/test` como dependência de desenvolvimento e um utilizador de teste.
2. **Revisão visual fina** (alinhamentos, espaços, janelas, telemóvel), ecrã a ecrã, a partir de capturas; a 1.ª volta (textos e blocos de explicação) está feita.
3. **Envio de SMS por Twilio**: feito no código, por commitar.
4. **Teste de carga de 1 milhão de membros**: preparado; ajustar o gerador à regra do membro único (V43).
5. **Sugestões para a procura de membros**: nome dos pais, BI obrigatório para adultos, cartão com QR, fotografia, revisão de duplicados.
6. **Dados de teste**: 2 pares de membros duplicados e 2 contagens abertas sem participantes no servidor de testes.
