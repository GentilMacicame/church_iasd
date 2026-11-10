/** Peças partilhadas da tesouraria: estado e tipo do movimento, valor com sinal, quem. */
import { Pilula } from '@/components/comum/elementos'
import { rotulos } from '@/i18n/pt-MZ'
import { dinheiro } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import type { Transacao } from './api'

export function PilulaEstado({ tr }: { tr: Transacao }) {
  if (tr.endDate) return <Pilula variante="secondary">Anulada</Pilula>
  if (tr.estado === 'CONFIRMADA') return <Pilula variante="success">Confirmada</Pilula>
  if (tr.estado === 'PENDENTE') {
    if (tr.tipo === 'SAIDA') return tr.aprovadoPorUsuarioId ? <Pilula variante="info">Aprovada</Pilula> : <Pilula variante="warning">Por aprovar</Pilula>
    return <Pilula variante="warning">Pendente</Pilula>
  }
  return <Pilula variante="destructive">{rotulos.estadoTransacao[tr.estado] ?? tr.estado}</Pilula>
}

/** Valor com sinal: entradas "+1 500,00 MT" em verde, saídas "−650,00 MT" na cor do texto. */
export function Valor({ tr, className }: { tr: Transacao; className?: string }) {
  const entrada = tr.tipo === 'ENTRADA'
  return (
    <span className={cn('num font-semibold whitespace-nowrap', entrada ? 'text-success-text' : tr.tipo === 'SAIDA' ? 'text-foreground' : 'text-muted-foreground', className)}>
      {entrada ? '+' : tr.tipo === 'SAIDA' ? '−' : ''}{dinheiro(tr.valorTotal)}
    </span>
  )
}

export function quem(tr: Transacao, nomeDe: (id: number) => string | undefined): string {
  if (tr.tipo === 'SAIDA') return tr.beneficiario ?? '—'
  if (tr.membroId) return nomeDe(tr.membroId) ?? `Membro ${tr.membroId}`
  return tr.anonimo ? 'Anónimo' : '—'
}
