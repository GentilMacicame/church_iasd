/**
 * Lista de escolha com pesquisa (combobox): para listas longas (Associações, distritos, províncias, ...), em vez
 * da lista nativa. Pesquisa sem acentos nem maiúsculas ("chokwe" encontra "Chókwè"); teclado: ↑ ↓ Enter Esc.
 * Abre num popover (não estica os diálogos). <Seleccao> usa-a por dentro: todas as listas têm pesquisa.
 */
import { useMemo, useRef, useState } from 'react'
import { Check, ChevronDown, Search, X } from 'lucide-react'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { cn } from '@/lib/utils'

export interface OpcaoEscolha { valor: string; rotulo: string; detalhe?: string; desactivada?: boolean }

const normal = (s: string) => s.normalize('NFD').replace(/\p{Diacritic}/gu, '').toLowerCase()

export function CampoEscolha({ id, valor, aoMudar, opcoes, vazio = 'Escolher…', semOpcoes = 'Sem opções', pesquisar = 'Pesquisar…', disabled, invalido, permitirLimpar, aoFechar, rotuloAcessivel }: {
  id?: string
  valor: string
  aoMudar: (valor: string) => void
  opcoes: OpcaoEscolha[]
  /** texto quando nada está escolhido */
  vazio?: string
  /** texto quando a lista está vazia */
  semOpcoes?: string
  pesquisar?: string
  disabled?: boolean
  invalido?: boolean
  permitirLimpar?: boolean
  /** ao fechar a lista (para o "blur" dos formulários) */
  aoFechar?: () => void
  rotuloAcessivel?: string
}) {
  const [aberto, setAberto] = useState(false)
  const [busca, setBusca] = useState('')
  const [activo, setActivo] = useState(0)
  const lista = useRef<HTMLUListElement>(null)
  const escolhida = opcoes.find((o) => o.valor === valor)
  const filtradas = useMemo(() => {
    const q = normal(busca.trim())
    return q ? opcoes.filter((o) => normal(`${o.rotulo} ${o.detalhe ?? ''}`).includes(q)) : opcoes
  }, [opcoes, busca])

  const escolher = (o: OpcaoEscolha) => { if (o.desactivada) return; aoMudar(o.valor); setAberto(false); setBusca(''); aoFechar?.() }
  const mover = (d: number) => {
    setActivo((a) => {
      const n = Math.max(0, Math.min(filtradas.length - 1, a + d))
      lista.current?.querySelectorAll('[role=option]')[n]?.scrollIntoView({ block: 'nearest' })
      return n
    })
  }

  return (
    <Popover open={aberto} onOpenChange={(v) => { setAberto(v); if (!v) aoFechar?.(); if (v) { setBusca(''); setActivo(Math.max(0, opcoes.findIndex((o) => o.valor === valor))) } }}>
      <PopoverTrigger asChild>
        <button id={id} type="button" role="combobox" aria-label={rotuloAcessivel} aria-expanded={aberto} aria-haspopup="listbox" disabled={disabled} aria-invalid={invalido || undefined}
          className={cn('group/escolha alvo flex h-10 w-full items-center justify-between gap-2 rounded-[2px] border border-input bg-card px-3 text-left text-sm shadow-[0_1px_2px_rgb(15_23_42/0.04)] transition-[border-color,box-shadow] hover:border-foreground/20',
            'focus-visible:border-primary focus-visible:ring-[3px] focus-visible:ring-primary/15 focus-visible:outline-none aria-expanded:border-primary aria-expanded:ring-[3px] aria-expanded:ring-primary/15 disabled:cursor-not-allowed disabled:opacity-60 aria-invalid:border-destructive')}>
          <span className={cn('truncate', escolhida ? 'text-foreground' : 'text-muted-foreground')}>{escolhida ? escolhida.rotulo : (opcoes.length ? vazio : semOpcoes)}</span>
          {escolhida && permitirLimpar
            ? <span role="button" tabIndex={0} aria-label="Limpar" onClick={(e) => { e.stopPropagation(); aoMudar('') }}
                onKeyDown={(e) => { if (e.key === 'Enter') { e.stopPropagation(); aoMudar('') } }}
                className="flex-none text-xs text-muted-foreground hover:text-foreground">Limpar</span>
            : <ChevronDown aria-hidden className="size-4 flex-none text-muted-foreground transition-transform duration-200 group-aria-expanded/escolha:rotate-180" />}
        </button>
      </PopoverTrigger>
      <PopoverContent align="start" className="w-[var(--radix-popover-trigger-width)] min-w-56 overflow-hidden p-0">
        <div className="flex items-center gap-2 border-b bg-muted/30 px-3">
          <Search className="size-4 flex-none text-muted-foreground" aria-hidden />
          <input autoFocus value={busca} placeholder={pesquisar} aria-label={pesquisar}
            onChange={(e) => { setBusca(e.target.value); setActivo(0) }}
            onKeyDown={(e) => {
              if (e.key === 'ArrowDown') { e.preventDefault(); mover(1) }
              else if (e.key === 'ArrowUp') { e.preventDefault(); mover(-1) }
              else if (e.key === 'Enter') { e.preventDefault(); const o = filtradas[activo]; if (o) escolher(o) }
            }}
            className="h-10 w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground" />
        </div>
        <ul ref={lista} role="listbox" className="max-h-64 overflow-y-auto p-1.5">
          {filtradas.length === 0 && <li className="px-3 py-6 text-center text-sm text-muted-foreground">{opcoes.length ? 'Nada encontrado' : semOpcoes}</li>}
          {filtradas.map((o, i) => (
            <li key={o.valor} role="option" aria-selected={o.valor === valor} aria-disabled={o.desactivada || undefined}
              onMouseEnter={() => setActivo(i)} onMouseDown={(e) => e.preventDefault()} onClick={() => escolher(o)}
              className={cn('flex min-h-9 cursor-pointer items-center gap-2 rounded-md px-2 py-1.5 text-sm transition-colors', i === activo && 'bg-muted', o.valor === valor && 'font-medium text-primary', o.desactivada && 'cursor-not-allowed opacity-50')}>
              <Check className={cn('size-4 flex-none', o.valor === valor ? 'text-primary' : 'invisible')} aria-hidden />
              <span className="min-w-0">
                <span className="block truncate">{o.rotulo}</span>
                {o.detalhe && <span className="block truncate text-xs text-muted-foreground">{o.detalhe}</span>}
              </span>
            </li>
          ))}
        </ul>
      </PopoverContent>
    </Popover>
  )
}

/**
 * Escolha de várias opções numa lista pendente com pesquisa: o campo mostra os escolhidos em etiquetas (cada uma
 * com ×) e a lista fica aberta enquanto se marca. Teclado: ↑ ↓ Enter (marca/desmarca) Esc.
 */
export function EscolhaMultipla({ id, valores, aoMudar, opcoes, vazio = 'Escolher…', semOpcoes = 'Sem opções', pesquisar = 'Pesquisar…', disabled, rotuloAcessivel }: {
  id?: string
  valores: string[]
  aoMudar: (valores: string[]) => void
  opcoes: OpcaoEscolha[]
  vazio?: string
  semOpcoes?: string
  pesquisar?: string
  disabled?: boolean
  rotuloAcessivel?: string
}) {
  const [aberto, setAberto] = useState(false)
  const [busca, setBusca] = useState('')
  const [activo, setActivo] = useState(0)
  const lista = useRef<HTMLUListElement>(null)
  const escolhidas = valores.map((v) => opcoes.find((o) => o.valor === v)).filter((o): o is OpcaoEscolha => Boolean(o))
  const filtradas = useMemo(() => {
    const q = normal(busca.trim())
    return q ? opcoes.filter((o) => normal(`${o.rotulo} ${o.detalhe ?? ''}`).includes(q)) : opcoes
  }, [opcoes, busca])
  const trocar = (o: OpcaoEscolha) => {
    if (o.desactivada) return
    aoMudar(valores.includes(o.valor) ? valores.filter((v) => v !== o.valor) : [...valores, o.valor])
  }
  const mover = (d: number) => {
    setActivo((a) => {
      const n = Math.max(0, Math.min(filtradas.length - 1, a + d))
      lista.current?.querySelectorAll('[role=option]')[n]?.scrollIntoView({ block: 'nearest' })
      return n
    })
  }

  return (
    <Popover open={aberto} onOpenChange={(v) => { setAberto(v); if (v) { setBusca(''); setActivo(0) } }}>
      <PopoverTrigger asChild>
        <button id={id} type="button" role="combobox" aria-label={rotuloAcessivel} aria-expanded={aberto} aria-haspopup="listbox" disabled={disabled}
          className={cn('group/escolha alvo flex min-h-10 w-full items-center justify-between gap-2 rounded-[2px] border border-input bg-card py-1.5 pr-3 pl-1.5 text-left text-sm transition-[border-color,box-shadow] hover:border-foreground/20',
            'focus-visible:border-primary focus-visible:ring-[3px] focus-visible:ring-primary/15 focus-visible:outline-none aria-expanded:border-primary aria-expanded:ring-[3px] aria-expanded:ring-primary/15 disabled:cursor-not-allowed disabled:opacity-60')}>
          <span className="flex min-w-0 flex-1 flex-wrap gap-1">
            {escolhidas.length ? escolhidas.map((o) => (
              <span key={o.valor} className="inline-flex max-w-full items-center gap-1 rounded-[2px] bg-primary/10 py-0.5 pr-1 pl-2 text-sm font-medium text-primary">
                <span className="truncate">{o.rotulo}</span>
                <span role="button" tabIndex={-1} aria-label={`Retirar ${o.rotulo}`}
                  onPointerDown={(e) => { e.preventDefault(); e.stopPropagation() }}
                  onClick={(e) => { e.stopPropagation(); trocar(o) }}
                  className="flex size-5 items-center justify-center rounded-[2px] hover:bg-primary/15"><X className="size-3.5" aria-hidden /></span>
              </span>
            )) : <span className="px-1.5 text-muted-foreground">{opcoes.length ? vazio : semOpcoes}</span>}
          </span>
          <ChevronDown aria-hidden className="size-4 flex-none text-muted-foreground transition-transform duration-200 group-aria-expanded/escolha:rotate-180" />
        </button>
      </PopoverTrigger>
      <PopoverContent align="start" className="w-[var(--radix-popover-trigger-width)] min-w-56 overflow-hidden p-0">
        <div className="flex items-center gap-2 border-b bg-muted/30 px-3">
          <Search className="size-4 flex-none text-muted-foreground" aria-hidden />
          <input autoFocus value={busca} placeholder={pesquisar} aria-label={pesquisar}
            onChange={(e) => { setBusca(e.target.value); setActivo(0) }}
            onKeyDown={(e) => {
              if (e.key === 'ArrowDown') { e.preventDefault(); mover(1) }
              else if (e.key === 'ArrowUp') { e.preventDefault(); mover(-1) }
              else if (e.key === 'Enter') { e.preventDefault(); const o = filtradas[activo]; if (o) trocar(o) }
            }}
            className="h-10 w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground" />
        </div>
        <ul ref={lista} role="listbox" aria-multiselectable className="max-h-64 overflow-y-auto p-1.5">
          {filtradas.length === 0 && <li className="px-3 py-6 text-center text-sm text-muted-foreground">{opcoes.length ? 'Nada encontrado' : semOpcoes}</li>}
          {filtradas.map((o, i) => {
            const sim = valores.includes(o.valor)
            return (
              <li key={o.valor} role="option" aria-selected={sim} aria-disabled={o.desactivada || undefined}
                onMouseEnter={() => setActivo(i)} onMouseDown={(e) => e.preventDefault()} onClick={() => trocar(o)}
                className={cn('flex min-h-9 cursor-pointer items-center gap-2.5 rounded-[2px] px-2 py-1.5 text-sm transition-colors', i === activo && 'bg-muted', o.desactivada && 'cursor-not-allowed opacity-50')}>
                <span className={cn('flex size-4 flex-none items-center justify-center rounded-[2px] border', sim ? 'border-primary bg-primary text-primary-foreground' : 'border-input bg-card')} aria-hidden>
                  {sim && <Check className="size-3" />}
                </span>
                <span className="min-w-0">
                  <span className={cn('block truncate', sim && 'font-medium')}>{o.rotulo}</span>
                  {o.detalhe && <span className="block truncate text-xs text-muted-foreground">{o.detalhe}</span>}
                </span>
              </li>
            )
          })}
        </ul>
        {valores.length > 0 && (
          <div className="flex items-center justify-between border-t px-3 py-2 text-xs text-muted-foreground">
            <span>{valores.length} escolhido{valores.length === 1 ? '' : 's'}</span>
            <button type="button" className="font-medium text-primary hover:underline" onClick={() => aoMudar([])}>Limpar</button>
          </div>
        )}
      </PopoverContent>
    </Popover>
  )
}
