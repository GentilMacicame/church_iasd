/**
 * Escolher um membro da igreja, com pesquisa pelo nome (sem acentos nem maiúsculas). Lista os membros
 * activos (vista vw_membro_basico); usado nas escalas, nas assinaturas e, mais tarde, noutros módulos.
 */
import { useMemo, useState } from 'react'
import { ChevronDown, Search } from 'lucide-react'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { Input } from '@/components/ui/input'
import { Avatar } from '@/components/comum/elementos'
import { Barra, EstadoErro } from '@/components/comum/estados'
import { useMembrosBasicos, type MembroBasico } from '@/features/membros/api'
import { cn } from '@/lib/utils'

const normal = (s: string) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()

export function ListaMembros({ aoEscolher, excluir = [], seleccionado, autoFocus = true, altura = 'max-h-72', estados = ['ACTIVO'] }: {
  aoEscolher: (m: MembroBasico) => void
  excluir?: number[]
  seleccionado?: number | null
  autoFocus?: boolean
  altura?: string
  /** estados aceites (por defeito só membros activos; contribuintes podem ser interessados) */
  estados?: string[]
}) {
  const q = useMembrosBasicos()
  const [texto, setTexto] = useState('')
  const lista = useMemo(() => {
    const n = normal(texto.trim())
    return (q.data ?? [])
      .filter((m) => estados.includes(m.estado) && !excluir.includes(m.id))
      .filter((m) => !n || normal(`${m.nome} ${m.apelido}`).includes(n))
      .sort((a, b) => `${a.nome} ${a.apelido}`.localeCompare(`${b.nome} ${b.apelido}`, 'pt'))
  }, [q.data, texto, excluir, estados])

  return (
    <div className="grid gap-2">
      <div className="relative">
        <Search aria-hidden className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
        <Input value={texto} onChange={(e) => setTexto(e.target.value)} placeholder="Procurar pelo nome" aria-label="Procurar membro pelo nome"
          autoFocus={autoFocus} className="alvo h-9 pl-9" />
      </div>
      {q.isPending ? <div className="grid gap-2 py-2">{[0, 1, 2].map((i) => <Barra key={i} className="h-8 w-full" />)}</div>
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
        : (
          <ul role="listbox" aria-label="Membros" className={cn('-mx-1 overflow-y-auto', altura)}>
            {lista.length === 0 && <li className="px-2 py-3 text-sm text-muted-foreground">Ninguém com esse nome.</li>}
            {lista.map((m) => (
              <li key={m.id} role="option" aria-selected={m.id === seleccionado}>
                <button type="button" onClick={() => aoEscolher(m)}
                  className={cn('alvo flex w-full items-center gap-2.5 rounded-md px-2 py-1.5 text-left text-sm hover:bg-accent hover:text-accent-foreground',
                    m.id === seleccionado && 'bg-accent font-medium text-accent-foreground')}>
                  <Avatar id={m.id} nome={m.nome} apelido={m.apelido} tamanho={28} />
                  <span className="truncate">{m.nome} {m.apelido}</span>
                </button>
              </li>
            ))}
          </ul>
        )}
    </div>
  )
}

/**
 * Campo de formulário que mostra o membro escolhido e abre a lista num popover flutuante (com a largura do
 * campo e altura limitada): não empurra o resto do formulário nem estica os diálogos.
 */
export function CampoMembro({ id, valor, aoMudar, nomeDe, estados, vazio = 'Escolher membro…', excluir }: {
  id?: string; valor: number | null; aoMudar: (id: number | null) => void; nomeDe: (id: number) => string | undefined; estados?: string[]; vazio?: string
  excluir?: number[]
}) {
  const [aberto, setAberto] = useState(false)
  return (
    <Popover open={aberto} onOpenChange={setAberto}>
      <PopoverTrigger asChild>
        <button id={id} type="button" aria-expanded={aberto} aria-haspopup="listbox"
          className="alvo flex h-9 w-full items-center justify-between gap-2 rounded-md border border-input bg-card px-3 text-left text-sm shadow-[0_1px_2px_rgb(0_0_0/0.04)] focus-visible:ring-2 focus-visible:ring-ring/50 focus-visible:outline-none">
          <span className={cn('truncate', valor ? 'text-foreground' : 'text-muted-foreground')}>{valor ? nomeDe(valor) ?? '—' : vazio}</span>
          {valor
            ? <span role="button" tabIndex={0} aria-label="Limpar" onClick={(e) => { e.stopPropagation(); aoMudar(null) }}
                onKeyDown={(e) => { if (e.key === 'Enter') { e.stopPropagation(); aoMudar(null) } }}
                className="flex-none text-xs text-muted-foreground hover:text-foreground">Limpar</span>
            : <ChevronDown aria-hidden className="size-4 flex-none text-muted-foreground" />}
        </button>
      </PopoverTrigger>
      <PopoverContent align="start" className="w-[var(--radix-popover-trigger-width)] min-w-64 p-2">
        <ListaMembros seleccionado={valor} estados={estados} excluir={excluir} aoEscolher={(m) => { aoMudar(m.id); setAberto(false) }} altura="max-h-60" />
      </PopoverContent>
    </Popover>
  )
}
