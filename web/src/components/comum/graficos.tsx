/**
 * Gráficos do sistema, em SVG (sem bibliotecas): barras agrupadas por período e donut de composição.
 * Regras (skill dataviz): paleta categórica validada (--serie-1..3, modo claro e escuro), cores pela ordem fixa
 * e pela entidade (nunca pela posição), um só eixo, marcas finas com 4px arredondados no topo e 2px de folga,
 * grelha discreta, legenda sempre que há 2+ séries, dica ao passar o rato e vista em tabela (acessibilidade).
 */
import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { Table2 } from 'lucide-react'
import { cn } from '@/lib/utils'

export type Slot = 1 | 2 | 3 | 'neutra'
const cor = (s: Slot) => (s === 'neutra' ? 'var(--serie-neutra)' : `var(--serie-${s})`)

function useLargura<T extends HTMLElement>() {
  const ref = useRef<T>(null)
  const [w, setW] = useState(0)
  useEffect(() => {
    if (!ref.current) return
    const o = new ResizeObserver(([e]) => setW(Math.floor(e.contentRect.width)))
    o.observe(ref.current)
    return () => o.disconnect()
  }, [])
  return [ref, w] as const
}

/** Máximo "redondo" para o eixo (1, 2, 2.5, 5 × 10ⁿ) e os seus 4 intervalos. */
function escala(max: number, inteiros = false) {
  if (max <= 0) return { topo: 4, passos: [0, 1, 2, 3, 4] }
  const bruto = max / 4
  const p = 10 ** Math.floor(Math.log10(bruto))
  let passo = [1, 2, 2.5, 5, 10].map((m) => m * p).find((x) => x >= bruto) ?? 10 * p
  if (inteiros) passo = Math.max(1, Math.ceil(passo))   // contagens de pessoas: nunca 0,5
  return { topo: passo * 4, passos: [0, 1, 2, 3, 4].map((i) => i * passo) }
}

/** "12 480" → "12,5 mil" no eixo; o valor exacto vai na dica. */
export function curto(v: number): string {
  const a = Math.abs(v)
  const f = (x: number) => String(Math.round(x * 10) / 10).replace('.', ',')
  if (a >= 1_000_000) return `${f(v / 1_000_000)} M`
  if (a >= 1_000) return `${f(v / 1_000)} mil`
  return f(v)
}

function Legenda({ itens }: { itens: { nome: string; slot: Slot; extra?: ReactNode }[] }) {
  return (
    <ul className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
      {itens.map((i) => (
        <li key={i.nome} className="flex items-center gap-1.5">
          <span aria-hidden className="size-2.5 rounded-[3px]" style={{ background: cor(i.slot) }} />
          <span>{i.nome}</span>{i.extra}
        </li>
      ))}
    </ul>
  )
}

function VistaTabela({ aberta, aoMudar, children }: { aberta: boolean; aoMudar: (v: boolean) => void; children: ReactNode }) {
  return (
    <>
      <button type="button" onClick={() => aoMudar(!aberta)} aria-expanded={aberta}
        className="alvo inline-flex items-center gap-1.5 text-xs font-medium text-muted-foreground hover:text-foreground print:hidden">
        <Table2 className="size-3.5" />{aberta ? 'Ocultar tabela' : 'Ver em tabela'}
      </button>
      {aberta && <div className="mt-2 overflow-x-auto rounded-lg border text-sm">{children}</div>}
    </>
  )
}

export interface SerieBarras { nome: string; slot: Slot; valores: number[] }

/**
 * Barras agrupadas: uma categoria (ex.: mês) por grupo, uma barra por série. Uma série → sem legenda (o título
 * nomeia-a). Valores ≥ 0.
 */
export function GraficoBarras({ categorias, series, formatar, altura = 220, rotulo, destaque, inteiros }: {
  categorias: string[]; series: SerieBarras[]; formatar: (v: number) => string; altura?: number
  /** descrição para leitores de ecrã, ex.: "Entradas e saídas por mês" */
  rotulo: string
  /** índice da categoria a destacar (ex.: o mês actual) */
  destaque?: number
  /** eixo só com números inteiros (contagens) */
  inteiros?: boolean
}) {
  const [ref, largura] = useLargura<HTMLDivElement>()
  const [foco, setFoco] = useState<number | null>(null)
  const [tabela, setTabela] = useState(false)
  const m = { cima: 8, baixo: 26, esq: 48, dir: 4 }
  const w = Math.max(0, largura - m.esq - m.dir)
  const h = altura - m.cima - m.baixo
  const max = Math.max(0, ...series.flatMap((s) => s.valores))
  const { topo, passos } = escala(max, inteiros)
  const grupo = categorias.length ? w / categorias.length : 0
  const larguraBarra = Math.max(4, Math.min(28, (grupo * 0.62 - 2 * (series.length - 1)) / series.length))
  const y = (v: number) => m.cima + h - (v / topo) * h
  const barra = (x: number, v: number) => {
    const topoY = y(v), base = m.cima + h, r = Math.min(4, larguraBarra / 2, base - topoY)
    if (v <= 0) return ''
    return `M${x},${base} V${topoY + r} Q${x},${topoY} ${x + r},${topoY} H${x + larguraBarra - r} Q${x + larguraBarra},${topoY} ${x + larguraBarra},${topoY + r} V${base} Z`
  }
  const rotuloCada = Math.ceil(categorias.length / Math.max(1, Math.floor(w / 44)))

  return (
    <div className="grid gap-3">
      {series.length > 1 && <Legenda itens={series.map((s) => ({ nome: s.nome, slot: s.slot }))} />}
      <div ref={ref} className="relative" style={{ height: altura }} onMouseLeave={() => setFoco(null)}>
        {largura > 0 && (
          <svg width={largura} height={altura} role="img" aria-label={rotulo} className="overflow-visible">
            {passos.map((p) => (
              <g key={p}>
                <line x1={m.esq} x2={m.esq + w} y1={y(p)} y2={y(p)} stroke="var(--border)" strokeDasharray={p === 0 ? undefined : '3 4'} />
                <text x={m.esq - 8} y={y(p)} dy="0.32em" textAnchor="end" className="fill-muted-foreground text-[11px] tabular-nums">{curto(p)}</text>
              </g>
            ))}
            {categorias.map((c, i) => {
              const x0 = m.esq + i * grupo
              const inicio = x0 + (grupo - (larguraBarra * series.length + 2 * (series.length - 1))) / 2
              return (
                <g key={c + i}>
                  {(foco === i || destaque === i) && <rect x={x0 + 2} y={m.cima} width={grupo - 4} height={h} rx={6} className={foco === i ? 'fill-muted' : 'fill-muted/50'} />}
                  {series.map((s, j) => <path key={s.nome} d={barra(inicio + j * (larguraBarra + 2), s.valores[i] ?? 0)} fill={cor(s.slot)} />)}
                  {i % rotuloCada === 0 && (
                    <text x={x0 + grupo / 2} y={m.cima + h + 17} textAnchor="middle" className={cn('text-[11px]', destaque === i ? 'fill-foreground font-medium' : 'fill-muted-foreground')}>{c}</text>
                  )}
                  <rect x={x0} y={0} width={grupo} height={altura} fill="transparent" onMouseEnter={() => setFoco(i)} onClick={() => setFoco(i)} />
                </g>
              )
            })}
          </svg>
        )}
        {foco !== null && largura > 0 && (
          <div role="status" className="pointer-events-none absolute top-0 z-10 min-w-36 rounded-lg border bg-popover px-3 py-2 text-xs text-popover-foreground shadow-lg"
            style={{ left: Math.min(Math.max(0, m.esq + foco * grupo + grupo / 2 - 72), largura - 150) }}>
            <p className="mb-1 font-semibold">{categorias[foco]}</p>
            {series.map((s) => (
              <p key={s.nome} className="flex items-center justify-between gap-4">
                <span className="flex items-center gap-1.5 text-muted-foreground"><span className="size-2 rounded-[2px]" style={{ background: cor(s.slot) }} />{s.nome}</span>
                <span className="num font-medium">{formatar(s.valores[foco] ?? 0)}</span>
              </p>
            ))}
          </div>
        )}
      </div>
      <VistaTabela aberta={tabela} aoMudar={setTabela}>
        <table className="w-full">
          <thead className="bg-muted/50 text-xs text-muted-foreground"><tr><th className="px-3 py-2 text-left font-medium">Período</th>{series.map((s) => <th key={s.nome} className="px-3 py-2 text-right font-medium">{s.nome}</th>)}</tr></thead>
          <tbody>
            {categorias.map((c, i) => (
              <tr key={c + i} className="border-t"><td className="px-3 py-1.5">{c}</td>{series.map((s) => <td key={s.nome} className="num px-3 py-1.5 text-right">{formatar(s.valores[i] ?? 0)}</td>)}</tr>
            ))}
          </tbody>
        </table>
      </VistaTabela>
    </div>
  )
}

export interface FatiaDonut { nome: string; valor: number; slot: Slot }

/** Donut de composição (até 3 cores + "outros" em neutro), com o total no centro e a legenda com valores e %. */
export function Donut({ fatias, formatar, rotulo, centro, tamanho = 148, lado }: {
  fatias: FatiaDonut[]; formatar: (v: number) => string; rotulo: string; centro?: string; tamanho?: number
  /** legenda ao lado (só em cartões largos); por defeito fica por baixo */
  lado?: boolean
}) {
  const [foco, setFoco] = useState<number | null>(null)
  const total = fatias.reduce((s, f) => s + f.valor, 0)
  const raio = tamanho / 2, espessura = 20, r = raio - espessura / 2
  const arcos = useMemo(() => {
    let a = -Math.PI / 2
    return fatias.map((f) => {
      const ang = total > 0 ? (f.valor / total) * Math.PI * 2 : 0
      const ini = a, fim = a + ang
      a = fim
      return { ini, fim, ang }
    })
  }, [fatias, total])
  const ponto = (ang: number) => [raio + r * Math.cos(ang), raio + r * Math.sin(ang)]
  const caminho = (ini: number, fim: number) => {
    const [x1, y1] = ponto(ini), [x2, y2] = ponto(fim)
    return `M${x1},${y1} A${r},${r} 0 ${fim - ini > Math.PI ? 1 : 0} 1 ${x2},${y2}`
  }
  const pct = (v: number) => (total ? `${String(Math.round((v / total) * 1000) / 10).replace('.', ',')}%` : '0%')
  const activa = foco !== null ? fatias[foco] : null

  return (
    <div className={cn('flex min-w-0 flex-col items-center gap-4', lado && 'sm:flex-row sm:gap-6')}>
      <svg width={tamanho} height={tamanho} role="img" aria-label={`${rotulo}: ${fatias.map((f) => `${f.nome} ${formatar(f.valor)}`).join(', ')}`} className="flex-none">
        <circle cx={raio} cy={raio} r={r} fill="none" stroke="var(--muted)" strokeWidth={espessura} />
        {total > 0 && arcos.map((a, i) => (
          a.ang >= Math.PI * 2 - 0.0001
            ? <circle key={i} cx={raio} cy={raio} r={r} fill="none" stroke={cor(fatias[i].slot)} strokeWidth={espessura} />
            : a.ang > 0 && (
              <path key={i} d={caminho(a.ini, a.fim)} fill="none" stroke={cor(fatias[i].slot)} strokeWidth={foco === i ? espessura + 4 : espessura}
                opacity={foco === null || foco === i ? 1 : 0.35} onMouseEnter={() => setFoco(i)} onMouseLeave={() => setFoco(null)} className="transition-[opacity,stroke-width]" />
            )
        ))}
        {/* 2px de folga entre fatias, na cor da superfície */}
        {total > 0 && fatias.filter((f) => f.valor > 0).length > 1 && arcos.map((a, i) => a.ang > 0 && (
          <line key={`g${i}`} x1={raio + (r - espessura) * Math.cos(a.ini)} y1={raio + (r - espessura) * Math.sin(a.ini)}
            x2={raio + (r + espessura) * Math.cos(a.ini)} y2={raio + (r + espessura) * Math.sin(a.ini)} stroke="var(--card)" strokeWidth={2} />
        ))}
        <text x={raio} y={raio - 4} textAnchor="middle" className="fill-foreground text-lg font-semibold tabular-nums">{activa ? formatar(activa.valor) : centro ?? formatar(total)}</text>
        <text x={raio} y={raio + 14} textAnchor="middle" className="fill-muted-foreground text-[11px]">{activa ? pct(activa.valor) : 'total'}</text>
      </svg>
      <ul className="grid w-full min-w-0 gap-2 text-sm">
        {fatias.map((f, i) => (
          <li key={f.nome} onMouseEnter={() => setFoco(i)} onMouseLeave={() => setFoco(null)}
            className={cn('flex items-center justify-between gap-3 rounded-md px-1.5 py-0.5', foco === i && 'bg-muted')}>
            <span className="flex min-w-0 items-center gap-2"><span aria-hidden className="size-2.5 flex-none rounded-[3px]" style={{ background: cor(f.slot) }} /><span className="truncate">{f.nome}</span></span>
            <span className="flex-none text-right"><span className="num font-medium">{formatar(f.valor)}</span> <span className="num text-xs text-muted-foreground">{pct(f.valor)}</span></span>
          </li>
        ))}
      </ul>
    </div>
  )
}
