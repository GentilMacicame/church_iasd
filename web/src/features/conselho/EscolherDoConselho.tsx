/**
 * Escolher um membro do conselho (nome · cargo) para presidir ou secretariar; "Outro membro…" abre a pesquisa
 * em todos os membros (ex.: o pastor ou um ancião de outra igreja).
 */
import { useState } from 'react'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { Seleccao } from '@/components/comum/Seleccao'
import { emExercicio, type Oficial } from './api'

const OUTRO = 'outro'

export function EscolherDoConselho({ id, valor, aoMudar, oficiais, nomeDe, vazio = 'Escolher…' }: {
  id?: string; valor: number | null; aoMudar: (id: number | null) => void; oficiais: Oficial[]
  nomeDe: (id: number) => string | undefined; vazio?: string
}) {
  // um membro com vários cargos aparece uma vez, com os cargos juntos
  const porMembro = new Map<number, { nome: string; cargos: string[] }>()
  for (const o of oficiais.filter(emExercicio)) {
    const x = porMembro.get(o.membroId) ?? { nome: o.membro, cargos: [] }
    x.cargos.push(o.cargo)
    porMembro.set(o.membroId, x)
  }
  const doConselho = [...porMembro.entries()].sort((a, b) => a[1].cargos[0].localeCompare(b[1].cargos[0], 'pt') || a[1].nome.localeCompare(b[1].nome, 'pt'))
  const [outro, setOutro] = useState(valor != null && !porMembro.has(valor))

  if (outro) {
    return (
      <div className="grid gap-1">
        <CampoMembro id={id} valor={valor} aoMudar={aoMudar} nomeDe={nomeDe} />
        <button type="button" onClick={() => { setOutro(false); aoMudar(null) }} className="justify-self-start text-xs font-medium text-primary hover:underline">
          Escolher do conselho
        </button>
      </div>
    )
  }
  return (
    <Seleccao id={id} value={valor == null ? '' : String(valor)}
      onChange={(e) => { if (e.target.value === OUTRO) { setOutro(true); aoMudar(null) } else aoMudar(e.target.value ? Number(e.target.value) : null) }}>
      <option value="">{vazio}</option>
      {doConselho.length > 0 && (
        <optgroup label="Conselho da igreja">
          {doConselho.map(([mid, x]) => <option key={mid} value={mid}>{x.nome} · {x.cargos.join(', ')}</option>)}
        </optgroup>
      )}
      <option value={OUTRO}>Outro membro…</option>
    </Seleccao>
  )
}
