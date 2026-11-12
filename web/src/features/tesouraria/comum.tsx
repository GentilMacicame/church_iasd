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

export function quem(tr: Transacao, nomeDe: (id: number) => string | undefined, familiaDe?: (id: number) => string | undefined): string {
  if (tr.estornoTransacaoId) return `Estorno do n.º ${tr.estornoTransacaoId}`
  if (tr.tipo === 'SAIDA') return tr.beneficiario ?? '—'
  if (tr.membroId) return nomeDe(tr.membroId) ?? `Membro ${tr.membroId}`
  if (tr.familiaId) return familiaDe?.(tr.familiaId) ?? `Família n.º ${tr.familiaId}`
  return tr.anonimo ? 'Anónimo' : '—'
}

/** Para quem vai o dinheiro de um fundo: "100% para a Missão", "50% Missão · 50% igreja" ou "Fica na igreja". */
export function parteDoFundo(f: { percentagemRemessa?: string | number | null; destinoEntidadeId?: number | null }): string {
  const p = Number(f.percentagemRemessa ?? 0)
  if (!f.destinoEntidadeId || p <= 0) return 'Fica na igreja'
  if (p >= 100) return '100% para a Missão'
  const n = (x: number) => String(Math.round(x * 100) / 100).replace('.', ',')
  return `${n(p)}% Missão · ${n(100 - p)}% igreja`
}
