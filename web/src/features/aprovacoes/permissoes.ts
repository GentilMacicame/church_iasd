/**
 * Quem pode abrir as Aprovações: quem lê algum dos objectos com fluxo (despesas, transacções, contagens, orçamentos, livro de
 * membros). Ficheiro à parte para o menu (no pacote inicial) não arrastar o resto da funcionalidade.
 */
export const PERMISSOES_APROVACOES = [
  'tesouraria.despesa.ler', 'tesouraria.transacao.ler', 'tesouraria.contagem_numerario.ler', 'tesouraria.orcamento.ler',
  'secretaria.movimento_membro.ler',
]
