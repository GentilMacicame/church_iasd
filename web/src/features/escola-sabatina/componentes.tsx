/**
 * Peças comuns das folhas e relatórios da Escola Sabatina, com a leitura do quadro em Excel que substituem:
 * percentagens a cores (verde, âmbar, vermelho), barras de dados, medalhas do 1.º, 2.º e 3.º lugar, selector do
 * trimestre e a moldura de tabela de folha de cálculo (cabeçalho escuro, números à direita, linha de totais).
 */
import type { ReactNode } from 'react'
import { Seleccao } from '@/components/comum/Seleccao'
import { cn } from '@/lib/utils'
import { nomeTrimestre, type Trimestre } from './api'

/** Fracção (0–1, texto ou número) → número; vazio → null. */
export const fr = (v?: string | number | null) => (v == null || v === '' ? null : Number(v))

/** "81,3%" (ou "—"). */
export function textoPct(v?: string | number | null, casas = 1) {
  const n = fr(v)
  return n == null || Number.isNaN(n) ? '—' : `${(n * 100).toLocaleString('pt-PT', { minimumFractionDigits: casas, maximumFractionDigits: casas })}%`
}

/** Número com casas fixas ("13,2"). */
export function textoNum(v?: string | number | null, casas = 1) {
  const n = fr(v)
  return n == null || Number.isNaN(n) ? '—' : n.toLocaleString('pt-PT', { minimumFractionDigits: casas, maximumFractionDigits: casas })
}

/** Dinheiro inteiro como no quadro ("6 910 MT"); o detalhe com cêntimos fica nos ecrãs de dinheiro. */
export function textoMT(v?: string | number | null) {
  const n = fr(v)
  // milhares com espaço sempre ("2 600 MT"; o pt-PT não separa números de 4 algarismos)
  return n == null || Number.isNaN(n) ? '—' : `${String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, ' ')} MT`
}

/**
 * Tom de uma percentagem, com os limiares do quadro: presença e estudo (≥ 85% bom, ≥ 75% atenção) ou alvo
 * (≥ 100% bom, ≥ 90% atenção).
 */
export function tomPct(v: number | null, tipo: 'presenca' | 'alvo') {
  if (v == null || Number.isNaN(v)) return ''
  const [bom, medio] = tipo === 'alvo' ? [1, 0.9] : [0.85, 0.75]
  return v >= bom ? 'bg-tint-success text-success-text' : v >= medio ? 'bg-tint-warning text-warning-text' : 'bg-tint-destructive text-destructive-text'
}

/** Célula de percentagem a cores. */
export function CelulaPct({ v, tipo = 'presenca', casas = 1, className }: { v?: string | number | null; tipo?: 'presenca' | 'alvo'; casas?: number; className?: string }) {
  const n = fr(v)
  return <td className={cn('num font-medium tabular-nums', tomPct(n, tipo), className)}>{textoPct(n, casas)}</td>
}

/** Diferença para a média: verde se acima, vermelho se abaixo (p.p. ou MT). */
export function Diferenca({ v, tipo }: { v?: string | number | null; tipo: 'pp' | 'mt' }) {
  const n = fr(v)
  if (n == null || Number.isNaN(n)) return <span className="text-muted-foreground">—</span>
  const sinal = n > 0 ? '+' : n < 0 ? '−' : ''
  const abs = Math.abs(n)
  const texto = tipo === 'pp' ? `${sinal}${(abs * 100).toLocaleString('pt-PT', { minimumFractionDigits: 1, maximumFractionDigits: 1 })}%` : `${sinal}${textoMT(abs)}`
  return <span className={cn('font-medium tabular-nums', n > 0 ? 'text-success-text' : n < 0 ? 'text-destructive-text' : 'text-muted-foreground')}>{texto}</span>
}

/** Barra de dados dentro da célula (como a formatação condicional do Excel). */
export function BarraDados({ v, max, children, tom = 'primary' }: { v: number; max: number; children: ReactNode; tom?: 'primary' | 'warning' }) {
  const pct = max > 0 ? Math.max(0, Math.min(100, (v / max) * 100)) : 0
  return (
    <span className="relative flex h-6 items-center justify-end overflow-hidden rounded-sm px-1.5">
      <span aria-hidden className={cn('absolute inset-y-0 left-0 rounded-sm', tom === 'warning' ? 'bg-warning/25' : 'bg-primary/15')} style={{ width: `${pct}%` }} />
      <span className="relative tabular-nums">{children}</span>
    </span>
  )
}

const MEDALHAS = [
  { rotulo: '1.º lugar', classe: 'bg-[#f6e7b0] text-[#7a5a00] ring-[#d4af37]/60 dark:bg-[#4a3b0a] dark:text-[#f2d77a]' },
  { rotulo: '2.º lugar', classe: 'bg-[#e9edf2] text-[#4b5563] ring-[#a8b0ba]/70 dark:bg-[#2b3038] dark:text-[#d1d5db]' },
  { rotulo: '3.º lugar', classe: 'bg-[#f3dccb] text-[#7c4a21] ring-[#cd7f32]/60 dark:bg-[#43291a] dark:text-[#f0b98c]' },
]

/** "1.º lugar" dourado, 2.º prateado, 3.º bronze; os outros sem medalha. */
export function Lugar({ n }: { n?: number | null }) {
  if (!n) return <span className="text-muted-foreground">—</span>
  const m = MEDALHAS[n - 1]
  return m
    ? <span className={cn('inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold whitespace-nowrap ring-1', m.classe)}>{m.rotulo}</span>
    : <span className="text-sm tabular-nums text-muted-foreground">{n}.º lugar</span>
}

/** Cor da barra de pontuação: o 1.º, 2.º e 3.º com a cor da medalha. */
export function corPontuacao(lugar?: number | null) {
  return lugar === 1 ? '#d4af37' : lugar === 2 ? '#a8b0ba' : lugar === 3 ? '#cd7f32' : 'var(--primary)'
}

/** Selector do trimestre (cabeçalhos das páginas). */
export function EscolherTrimestre({ trimestres, valor, aoMudar, className }: { trimestres: Trimestre[]; valor?: number; aoMudar: (id: string) => void; className?: string }) {
  if (!trimestres.length) return null
  return (
    <div className={cn('w-60', className)}>
      <Seleccao aria-label="Trimestre" value={valor ?? ''} onChange={(e) => aoMudar(e.target.value)}>
        {trimestres.map((x) => <option key={x.id} value={x.id}>{nomeTrimestre(x)}{x.temaLicao ? ` · ${x.temaLicao}` : ''}</option>)}
      </Seleccao>
    </div>
  )
}

/**
 * Tabela no estilo da folha de cálculo: cabeçalho em faixa escura (como o quadro), números à direita, linhas finas,
 * primeira coluna fixa ao deslocar no telemóvel e linha de totais destacada (<tfoot>). Imprime com as cores.
 */
export function Folha({ children, className, minimo = 'min-w-[56rem]' }: { children: ReactNode; className?: string; minimo?: string }) {
  return (
    <div className="relative w-full overflow-x-auto rounded-lg border print:overflow-visible print:border-0">
      <table className={cn(
        'w-full border-collapse text-sm text-foreground [print-color-adjust:exact]', minimo,
        '[&_thead_th]:bg-[#1f3a5f] [&_thead_th]:px-3 [&_thead_th]:py-2.5 [&_thead_th]:text-[11px] [&_thead_th]:font-semibold [&_thead_th]:tracking-wide [&_thead_th]:text-white [&_thead_th]:uppercase dark:[&_thead_th]:bg-[#16283f]',
        '[&_thead_tr+tr_th]:bg-[#2b4b74] [&_thead_tr+tr_th]:py-1.5 [&_thead_tr+tr_th]:text-[10px] dark:[&_thead_tr+tr_th]:bg-[#1d3452]',
        '[&_thead_th]:border-r [&_thead_th]:border-white/10 [&_thead_th:last-child]:border-r-0',
        '[&_tbody_td]:border-t [&_tbody_td]:px-3 [&_tbody_td]:py-2 [&_tbody_tr:hover]:bg-muted/40',
        '[&_tfoot_td]:border-t-2 [&_tfoot_td]:border-[#1f3a5f]/40 [&_tfoot_td]:bg-[#e8eef6] [&_tfoot_td]:px-3 [&_tfoot_td]:py-2.5 [&_tfoot_td]:font-semibold dark:[&_tfoot_td]:bg-[#1a2635]',
        '[&_.num]:text-right [&_.num]:whitespace-nowrap [&_th.num]:text-right [&_.centro]:text-center',
        '[&_tbody_td:first-child]:sticky [&_tbody_td:first-child]:left-0 [&_tbody_td:first-child]:z-[1] [&_tbody_td:first-child]:bg-card',
        '[&_tfoot_td:first-child]:sticky [&_tfoot_td:first-child]:left-0 [&_tfoot_td:first-child]:z-[1]',
        className,
      )}>
        {children}
      </table>
    </div>
  )
}
