/**
 * Paginação das tabelas e listas: 10 de cada vez, para não haver tabelas longas no ecrã. Ao imprimir ou guardar em
 * PDF mostra-se tudo (os itens fora da página só se escondem no ecrã: classe "hidden print:…").
 */
import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { cn } from '@/lib/utils'

export const POR_PAGINA = 10

/** Página actual de uma lista de n itens (volta ao início se a lista encolher, ex.: ao filtrar). */
export function usePagina(total: number, porPagina = POR_PAGINA) {
  const paginas = Math.max(1, Math.ceil(total / porPagina))
  const [pagina, setPagina] = useState(1)
  useEffect(() => { if (pagina > paginas) setPagina(paginas) }, [pagina, paginas])
  const actual = Math.min(pagina, paginas)
  const inicio = (actual - 1) * porPagina
  return { pagina: actual, paginas, setPagina, inicio, fim: Math.min(total, inicio + porPagina), naPagina: (i: number) => i >= inicio && i < inicio + porPagina }
}

/** Para listas (<ul>): os itens desta página e o controlo. */
export function usePaginacao<T>(itens: T[], porPagina = POR_PAGINA) {
  const p = usePagina(itens.length, porPagina)
  const visiveis = useMemo(() => itens.slice(p.inicio, p.fim), [itens, p.inicio, p.fim])
  return { ...p, visiveis, total: itens.length }
}

/** As páginas a mostrar: 1 … 4 5 6 … 12 */
function numeros(pagina: number, paginas: number): (number | '…')[] {
  if (paginas <= 7) return Array.from({ length: paginas }, (_, i) => i + 1)
  const meio = [pagina - 1, pagina, pagina + 1].filter((n) => n > 1 && n < paginas)
  return [1, ...(meio[0] > 2 ? ['…' as const] : []), ...meio, ...(meio[meio.length - 1] < paginas - 1 ? ['…' as const] : []), paginas]
}

export function ControlosPaginacao({ pagina, paginas, setPagina, inicio, fim, total, className }: {
  pagina: number; paginas: number; setPagina: (n: number) => void; inicio: number; fim: number; total: number; className?: string
}) {
  if (paginas <= 1) return null
  const botao = 'alvo inline-flex min-w-9 items-center justify-center rounded-md px-2 text-sm tabular-nums transition-colors disabled:pointer-events-none disabled:opacity-40'
  return (
    <nav aria-label="Paginação" className={cn('flex flex-wrap items-center justify-between gap-2 border-t px-4 py-2.5 print:hidden sm:px-6', className)}>
      <p className="text-xs text-muted-foreground tabular-nums">{inicio + 1}–{fim} de {total}</p>
      <div className="flex items-center gap-1">
        <button type="button" className={cn(botao, 'hover:bg-accent')} onClick={() => setPagina(pagina - 1)} disabled={pagina <= 1} aria-label="Página anterior">
          <ChevronLeft className="size-4" />
        </button>
        {numeros(pagina, paginas).map((n, i) => n === '…'
          ? <span key={`r${i}`} className="px-1 text-sm text-muted-foreground" aria-hidden>…</span>
          : (
            <button key={n} type="button" onClick={() => setPagina(n)} aria-current={n === pagina ? 'page' : undefined} aria-label={`Página ${n}`}
              className={cn(botao, 'hidden sm:inline-flex', n === pagina ? 'bg-primary font-semibold text-primary-foreground' : 'hover:bg-accent')}>
              {n}
            </button>
          ))}
        <span className="px-2 text-sm tabular-nums sm:hidden">{pagina} / {paginas}</span>
        <button type="button" className={cn(botao, 'hover:bg-accent')} onClick={() => setPagina(pagina + 1)} disabled={pagina >= paginas} aria-label="Página seguinte">
          <ChevronRight className="size-4" />
        </button>
      </div>
    </nav>
  )
}

/**
 * Envolve uma lista (<ul>, <ol>, cartões): desenha só os itens desta página e o controlo por baixo.
 * Uso: <Paginada itens={lista}>{(visiveis, inicio) => <ul>{visiveis.map(...)}</ul>}</Paginada>
 */
export function Paginada<T>({ itens, porPagina = POR_PAGINA, children, className }: {
  itens: T[]; porPagina?: number; children: (visiveis: T[], inicio: number) => ReactNode; className?: string
}) {
  const p = usePaginacao(itens, porPagina)
  return (
    <>
      {children(p.visiveis, p.inicio)}
      <ControlosPaginacao {...p} className={className} />
    </>
  )
}
