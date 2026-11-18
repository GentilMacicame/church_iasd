/**
 * Painel do distrito pastoral (contexto da área pastoral, fora da igreja local): o pastor vê as igrejas do seu
 * distrito — membros, contribuições e a comparação entre elas (o Painel geral, fixo no distrito) — e o acompanhamento
 * das actividades: as da área pastoral e as locais de cada igreja, comparadas por igreja (realizadas, atrasadas,
 * canceladas, orçamento). "Abrir" uma igreja no quadro passa para o contexto dessa igreja.
 */
import { useQueries } from '@tanstack/react-query'
import { useSearchParams } from 'react-router-dom'
import { ChevronLeft, ChevronRight, ListChecks } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { EstadoErro, LinhasACarregar } from '@/components/comum/estados'
import { api, dados } from '@/api/cliente'
import { useSessao } from '@/auth/sessao'
import { hojeIso } from '@/lib/formatos'
import { Acompanhamento, type LinhaAcompanhamento } from '@/features/actividades/Acompanhamento'
import type { LinhaPrograma } from '@/features/actividades/api'
import PaginaPainelGeral from './PaginaPainelGeral'

export default function PaginaPainelDistrito() {
  const { distrito, igrejas } = useSessao()
  const [params, setParams] = useSearchParams()
  const ano = Number(params.get('ano')) || Number(hojeIso().slice(0, 4))
  const ids = distrito?.igrejas ?? []
  const nomeDe = (id: number) => igrejas.find((i) => i.id === id)?.nome ?? `Igreja ${id}`
  const qs = useQueries({
    queries: ids.map((id) => ({
      queryKey: ['distrito', distrito?.id, 'programa', id, ano],
      queryFn: async () => (await dados(api.GET('/v1/actividades/programa', { params: { query: { igrejaId: id, ano } } }))) as unknown as LinhaPrograma[],
    })),
  })
  const aCarregar = qs.some((q) => q.isPending)
  const erro = qs.find((q) => q.isError)?.error
  // as da área pastoral vêm repetidas em cada igreja do distrito: contam uma vez
  const vistas = new Set<number>()
  const linhas: LinhaAcompanhamento[] = []
  qs.forEach((q, i) => (q.data ?? []).forEach((x) => {
    if (x.origem === 'AREA_PASTORAL') {
      if (vistas.has(x.id)) return
      vistas.add(x.id)
      linhas.push({ ...x, grupo: 'Área pastoral' })
    } else linhas.push({ ...x, grupo: nomeDe(ids[i]) })
  }))
  const mudarAno = (n: number) => setParams((p) => { const x = new URLSearchParams(p); x.set('ano', String(n)); return x }, { replace: true })

  if (!distrito) return null
  return (
    <div className="grid gap-8">
      <PaginaPainelGeral distritoFixo={distrito.id} titulo={distrito.nome} />
      <section aria-label="Actividades do distrito" className="grid gap-4">
        <div className="flex flex-wrap items-end justify-between gap-3">
          <div>
            <h2 className="flex items-center gap-2 text-lg font-semibold"><ListChecks className="size-5 text-primary" />Actividades do distrito</h2>
            <p className="text-sm text-muted-foreground">Área pastoral e actividades locais de cada igreja, comparadas por igreja</p>
          </div>
          <div className="flex items-center gap-1 rounded-lg border bg-card p-0.5">
            <Button variant="ghost" size="icon" className="alvo size-8" aria-label="Ano anterior" onClick={() => mudarAno(ano - 1)}><ChevronLeft className="size-4" /></Button>
            <span className="min-w-12 text-center text-sm font-semibold tabular-nums">{ano}</span>
            <Button variant="ghost" size="icon" className="alvo size-8" aria-label="Ano seguinte" onClick={() => mudarAno(ano + 1)}><ChevronRight className="size-4" /></Button>
          </div>
        </div>
        {aCarregar ? <LinhasACarregar linhas={5} /> : erro ? <EstadoErro erro={erro} /> : <Acompanhamento linhas={linhas} rotuloGrupo="igreja" ano={ano} />}
      </section>
    </div>
  )
}
