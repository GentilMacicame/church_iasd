/**
 * Lista de escolha com pesquisa (combobox): para listas longas (Associações, distritos, províncias, ...), em vez
 * da lista nativa. Pesquisa sem acentos nem maiúsculas ("chokwe" encontra "Chókwè"); teclado: ↑ ↓ Enter Esc.
 * Abre num popover (não estica os diálogos). Para listas curtas continua a usar-se <Seleccao>.
 */
import { useMemo, useRef, useState } from 'react'
import { Check, ChevronDown, Search } from 'lucide-react'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { cn } from '@/lib/utils'

export interface OpcaoEscolha { valor: string; rotulo: string; detalhe?: string }

const normal = (s: string) => s.normalize('NFD').replace(/\p{Diacritic}/gu, '').toLowerCase()

export function CampoEscolha({ id, valor, aoMudar, opcoes, vazio = 'Escolher…', semOpcoes = 'Sem opções', pesquisar = 'Pesquisar…', disabled, invalido, permitirLimpar }: {
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

  const escolher = (o: OpcaoEscolha) => { aoMudar(o.valor); setAberto(false); setBusca('') }
  const mover = (d: number) => {
    setActivo((a) => {
      const n = Math.max(0, Math.min(filtradas.length - 1, a + d))
      lista.current?.querySelectorAll('[role=option]')[n]?.scrollIntoView({ block: 'nearest' })
      return n
    })
  }

  return (
    <Popover open={aberto} onOpenChange={(v) => { setAberto(v); if (v) { setBusca(''); setActivo(Math.max(0, opcoes.findIndex((o) => o.valor === valor))) } }}>
      <PopoverTrigger asChild>
        <button id={id} type="button" role="combobox" aria-expanded={aberto} aria-haspopup="listbox" disabled={disabled} aria-invalid={invalido || undefined}
          className={cn('alvo flex h-9 w-full items-center justify-between gap-2 rounded-md border border-input bg-card px-3 text-left text-sm shadow-[0_1px_2px_rgb(0_0_0/0.04)]',
            'focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/30 focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-60 aria-invalid:border-destructive')}>
          <span className={cn('truncate', escolhida ? 'text-foreground' : 'text-muted-foreground')}>{escolhida ? escolhida.rotulo : (opcoes.length ? vazio : semOpcoes)}</span>
          {escolhida && permitirLimpar
            ? <span role="button" tabIndex={0} aria-label="Limpar" onClick={(e) => { e.stopPropagation(); aoMudar('') }}
                onKeyDown={(e) => { if (e.key === 'Enter') { e.stopPropagation(); aoMudar('') } }}
                className="flex-none text-xs text-muted-foreground hover:text-foreground">Limpar</span>
            : <ChevronDown aria-hidden className="size-4 flex-none text-muted-foreground" />}
        </button>
      </PopoverTrigger>
      <PopoverContent align="start" className="w-[var(--radix-popover-trigger-width)] min-w-56 p-0">
        <div className="flex items-center gap-2 border-b px-3">
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
        <ul ref={lista} role="listbox" className="max-h-64 overflow-y-auto p-1">
          {filtradas.length === 0 && <li className="px-3 py-6 text-center text-sm text-muted-foreground">{opcoes.length ? 'Nada encontrado' : semOpcoes}</li>}
          {filtradas.map((o, i) => (
            <li key={o.valor} role="option" aria-selected={o.valor === valor}
              onMouseEnter={() => setActivo(i)} onMouseDown={(e) => e.preventDefault()} onClick={() => escolher(o)}
              className={cn('flex min-h-9 cursor-pointer items-center gap-2 rounded-md px-2 py-1.5 text-sm', i === activo && 'bg-accent text-accent-foreground')}>
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
