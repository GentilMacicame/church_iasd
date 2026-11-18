/**
 * Actividades e programa anual (F-ACT, V34) · "O que a igreja vai fazer este ano, quem organiza e quanto custa?"
 * Programa anual: as actividades de todos os departamentos, mês a mês, com o previsto e o executado (saídas da
 * tesouraria ligadas à actividade). Por departamento: quantas actividades e a execução de cada um.
 */
import { useMemo, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { CalendarPlus, CalendarRange, ChevronLeft, ChevronRight, Layers, ListChecks, Plus } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { Seleccao } from '@/components/comum/Seleccao'
import { Exportar } from '@/components/comum/Exportar'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { centimos, deCentimos, dinheiro, hojeIso, hora } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { DialogoActividade } from './DialogoActividade'
import { Acompanhamento } from './Acompanhamento'
import { ROTULO_ESTADO, VARIANTE_ESTADO, useActividadesMut, useDepartamentosIgreja, usePrograma, type LinhaPrograma } from './api'

const MESES = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro']
const DIA = new Intl.DateTimeFormat('pt-MZ', { weekday: 'short', day: '2-digit', month: '2-digit', timeZone: 'Africa/Maputo' })

const soma = (l: LinhaPrograma[], f: (x: LinhaPrograma) => string) => l.reduce((s, x) => s + centimos(f(x)), 0)
const pct = (a: number, b: number) => (b > 0 ? `${Math.round((a / b) * 100)}%` : '—')

export default function PaginaActividades() {
  const igreja = useIgreja()
  const { pode } = useSessao()
  const navigate = useNavigate()
  const [params, setParams] = useSearchParams()
  const ano = Number(params.get('ano')) || Number(hojeIso().slice(0, 4))
  const dep = params.get('departamento') ?? ''
  const estado = params.get('estado') ?? ''
  const aba = params.get('ver') === 'departamentos' ? 'departamentos' : params.get('ver') === 'acompanhamento' ? 'acompanhamento' : 'programa'
  const mudar = (k: string, v: string) => setParams((p) => { const n = new URLSearchParams(p); if (v) n.set(k, v); else n.delete(k); return n }, { replace: true })
  const [nova, setNova] = useState(false)

  const q = usePrograma(ano)
  const deps = useDepartamentosIgreja()
  const linhas = useMemo(
    () => (q.data ?? []).filter((x) => (!dep || (dep === 'pastoral' ? x.origem === 'AREA_PASTORAL' : String(x.departamentoIgrejaId) === dep)) && (!estado || x.estado === estado)),
    [q.data, dep, estado],
  )
  const contam = linhas.filter((x) => x.estado !== 'CANCELADA')
  const previsto = soma(contam, (x) => x.valorPrevisto), executado = soma(contam, (x) => x.executado)

  return (
    <>
      <TituloPagina icone={CalendarRange} titulo="Actividades e programa anual"
        descricao="Actividades dos departamentos e da área pastoral"
        accoes={
          <>
            <Exportar caminho="/v1/actividades/programa" query={{ igrejaId: igreja.id, ano }} nome={`programa-${ano}-${igreja.nome}`} />
            {pode('actividades.actividade.criar') && <Button className="alvo" onClick={() => setNova(true)}><CalendarPlus className="size-4" />Nova actividade</Button>}
          </>
        } />

      <Tabs value={aba} onValueChange={(v) => mudar('ver', v === 'programa' ? '' : v)}>
        <div className="mb-4 flex flex-wrap items-center gap-3">
          <TabsList>
            <TabsTrigger value="programa" className="alvo gap-1.5"><CalendarRange className="size-4" />Programa anual</TabsTrigger>
            <TabsTrigger value="acompanhamento" className="alvo gap-1.5"><ListChecks className="size-4" />Acompanhamento</TabsTrigger>
            <TabsTrigger value="departamentos" className="alvo gap-1.5"><Layers className="size-4" />Por departamento</TabsTrigger>
          </TabsList>
          <div className="flex items-center gap-1 rounded-lg border bg-card p-0.5">
            <Button variant="ghost" size="icon" className="alvo size-8" aria-label="Ano anterior" onClick={() => mudar('ano', String(ano - 1))}><ChevronLeft className="size-4" /></Button>
            <span className="min-w-12 text-center text-sm font-semibold tabular-nums">{ano}</span>
            <Button variant="ghost" size="icon" className="alvo size-8" aria-label="Ano seguinte" onClick={() => mudar('ano', String(ano + 1))}><ChevronRight className="size-4" /></Button>
          </div>
          {aba === 'programa' && (
            <div className="grid w-full grid-cols-2 gap-2 sm:w-auto">
              <Seleccao aria-label="Filtrar por departamento" value={dep} onChange={(e) => mudar('departamento', e.target.value)} className="h-9 sm:w-52">
                <option value="">Todos os departamentos</option>
                <option value="pastoral">Área pastoral (distrito)</option>
                {(deps.data?.daIgreja ?? []).map((d) => <option key={d.id} value={d.id}>{d.nome}</option>)}
              </Seleccao>
              <Seleccao aria-label="Filtrar por estado" value={estado} onChange={(e) => mudar('estado', e.target.value)} className="h-9 sm:w-40">
                <option value="">Todos os estados</option>
                {Object.entries(ROTULO_ESTADO).map(([k, r]) => <option key={k} value={k}>{r}</option>)}
              </Seleccao>
            </div>
          )}
        </div>

        {q.isPending ? <div className="grid gap-3"><Barra className="h-10 w-full" /><Barra className="h-64 w-full" /></div>
          : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
          : (
            <>
              <TabsContent value="programa" className="mt-0">
                <p className="mb-4 text-sm text-muted-foreground">
                  <strong className="text-foreground tabular-nums">{contam.length}</strong> {contam.length === 1 ? 'actividade' : 'actividades'} ·
                  previsto <strong className="text-foreground">{dinheiro(deCentimos(previsto))}</strong> ·
                  executado <strong className="text-foreground">{dinheiro(deCentimos(executado))}</strong> ({pct(executado, previsto)})
                </p>
                {!linhas.length ? (
                  <section className="rounded-xl border bg-card shadow-card">
                    <EstadoVazio icone={CalendarRange} titulo={`Sem actividades em ${ano}`}
                      accao={pode('actividades.actividade.criar') && <Button onClick={() => setNova(true)}><Plus className="size-4" />Nova actividade</Button>}>
                      {dep || estado ? 'Nenhuma actividade com estes filtros.' : 'Registe as actividades dos departamentos para montar o programa do ano.'}
                    </EstadoVazio>
                  </section>
                ) : (
                  <div className="grid gap-5">
                    {MESES.map((nomeMes, i) => {
                      const doMes = linhas.filter((x) => x.mes === i + 1)
                      if (!doMes.length) return null
                      return (
                        <section key={nomeMes} className="rounded-xl border bg-card shadow-card" aria-label={nomeMes}>
                          <h2 className="flex items-baseline justify-between gap-3 px-4 pt-4 text-base font-semibold sm:px-6">
                            {nomeMes} <span className="text-xs font-normal text-muted-foreground">{doMes.length} {doMes.length === 1 ? 'actividade' : 'actividades'}</span>
                          </h2>
                          <Tabela className="mt-3" porPagina={false}>
                            <thead>
                              <tr>
                                <th className="sm:pl-6">Data</th>
                                <th>Actividade</th>
                                <th className="hidden md:table-cell">Departamento</th>
                                <th className="hidden lg:table-cell">Responsável</th>
                                <th>Estado</th>
                                <th className="num hidden sm:table-cell">Previsto</th>
                                <th className="num hidden sm:table-cell sm:pr-6">Executado</th>
                              </tr>
                            </thead>
                            <tbody>
                              {doMes.map((x) => (
                                <tr key={x.id} onClick={() => navigate(`/actividades/${x.id}`)} className={cn('cursor-pointer', x.estado === 'CANCELADA' && 'text-muted-foreground')}>
                                  <td className="whitespace-nowrap sm:pl-6"><span className="font-medium capitalize">{DIA.format(new Date(x.dataInicio))}</span><span className="block text-xs text-muted-foreground tabular-nums">{hora(x.dataInicio)}{x.dataFim ? `–${hora(x.dataFim)}` : ''}</span></td>
                                  <td>
                                    <Link to={`/actividades/${x.id}`} onClick={(ev) => ev.stopPropagation()} className={cn('font-medium hover:text-primary', x.estado === 'CANCELADA' && 'line-through')}>{x.nome}</Link>
                                    {x.origem === 'AREA_PASTORAL' && <Pilula variante="info" className="ml-2 align-middle">Área pastoral</Pilula>}
                                    <span className="block text-xs text-muted-foreground md:hidden">{x.departamento}</span>
                                    {x.local && <span className="hidden text-xs text-muted-foreground md:block">{x.local}</span>}
                                  </td>
                                  <td className="hidden md:table-cell">{x.origem === 'AREA_PASTORAL' ? `Distrito · ${x.distrito ?? ''}` : x.departamento}</td>
                                  <td className="hidden lg:table-cell">{x.responsavel ?? '—'}{x.outrosResponsaveis > 0 && <span className="text-xs text-muted-foreground"> +{x.outrosResponsaveis}</span>}</td>
                                  <td><Pilula variante={VARIANTE_ESTADO[x.estado]}>{ROTULO_ESTADO[x.estado]}</Pilula></td>
                                  <td className="num hidden sm:table-cell">{dinheiro(x.valorPrevisto)}</td>
                                  <td className="num hidden sm:table-cell sm:pr-6">{dinheiro(x.executado)}</td>
                                </tr>
                              ))}
                            </tbody>
                          </Tabela>
                        </section>
                      )
                    })}
                  </div>
                )}
              </TabsContent>
              <TabsContent value="acompanhamento" className="mt-0">
                <Acompanhamento ano={ano} rotuloGrupo="departamento"
                  linhas={(q.data ?? []).map((x) => ({ ...x, grupo: x.origem === 'AREA_PASTORAL' ? 'Área pastoral' : x.departamento }))} />
              </TabsContent>
              <TabsContent value="departamentos" className="mt-0">
                <PorDepartamento linhas={q.data ?? []} aoVer={(id) => setParams((p) => { const n = new URLSearchParams(p); n.delete('ver'); n.set('departamento', String(id)); return n })} />
              </TabsContent>
            </>
          )}
      </Tabs>

      {nova && <DialogoActividade departamentoInicial={dep && dep !== 'pastoral' ? Number(dep) : undefined} aoFechar={() => setNova(false)} aoGravar={(id) => navigate(`/actividades/${id}`)} />}
    </>
  )
}

/** Resumo por departamento: actividades, concluídas, previsto, executado e % de execução; activar departamentos. */
function PorDepartamento({ linhas, aoVer }: { linhas: LinhaPrograma[]; aoVer: (departamentoIgrejaId: number) => void }) {
  const { pode } = useSessao()
  const deps = useDepartamentosIgreja()
  const { activarDepartamento } = useActividadesMut()
  const [novo, setNovo] = useState('')
  const daIgreja = (deps.data?.daIgreja ?? []).filter((d) => !d.endDate)
  const porActivar = (deps.data?.todos ?? []).filter((d) => !daIgreja.some((x) => x.departamentoId === d.id))
  const activar = () => activarDepartamento.mutate(Number(novo), {
    onSuccess: () => { toast.success('Departamento activado nesta igreja.'); setNovo('') },
    onError: (e) => toast.error(mensagemDe(e)),
  })
  if (deps.isPending) return <Barra className="h-48 w-full" />
  if (deps.isError) return <EstadoErro erro={deps.error} aoTentar={() => deps.refetch()} />
  return (
    <section className="rounded-xl border bg-card shadow-card">
      {pode('organizacao.igreja_departamento.criar') && porActivar.length > 0 && (
        <div className="flex flex-wrap items-center gap-2 border-b px-4 py-3 sm:px-6">
          <Seleccao aria-label="Departamento a activar" value={novo} onChange={(e) => setNovo(e.target.value)} className="h-9 sm:w-64">
            <option value="">Activar outro departamento…</option>
            {porActivar.map((d) => <option key={d.id} value={d.id}>{d.nome}</option>)}
          </Seleccao>
          <Button size="sm" className="alvo" disabled={!novo || activarDepartamento.isPending} onClick={activar}><Plus className="size-4" />Activar</Button>
        </div>
      )}
      {!daIgreja.length ? <EstadoVazio icone={Layers} titulo="Sem departamentos">Esta igreja ainda não tem departamentos activos.</EstadoVazio> : (
        <Tabela>
          <thead>
            <tr>
              <th className="sm:pl-6">Departamento</th>
              <th className="num">Actividades</th>
              <th className="num hidden sm:table-cell">Concluídas</th>
              <th className="num">Previsto</th>
              <th className="num">Executado</th>
              <th className="num sm:pr-6">Execução</th>
            </tr>
          </thead>
          <tbody>
            {daIgreja.map((d) => {
              const l = linhas.filter((x) => x.departamentoIgrejaId === d.id && x.estado !== 'CANCELADA')
              const p = soma(l, (x) => x.valorPrevisto), e = soma(l, (x) => x.executado)
              return (
                <tr key={d.id} onClick={() => aoVer(d.id)} className="cursor-pointer">
                  <td className="font-medium sm:pl-6">{d.nome}</td>
                  <td className="num">{l.length}</td>
                  <td className="num hidden sm:table-cell">{l.filter((x) => x.estado === 'CONCLUIDA').length}</td>
                  <td className="num">{dinheiro(deCentimos(p))}</td>
                  <td className="num">{dinheiro(deCentimos(e))}</td>
                  <td className="num sm:pr-6">{pct(e, p)}</td>
                </tr>
              )
            })}
            {(() => {
              const l = linhas.filter((x) => x.origem === 'AREA_PASTORAL' && x.estado !== 'CANCELADA')
              if (!l.length) return null
              const p = soma(l, (x) => x.valorPrevisto), e = soma(l, (x) => x.executado)
              return (
                <tr className="bg-tint-info/40">
                  <td className="font-medium sm:pl-6">Área pastoral <span className="text-xs font-normal text-muted-foreground">· {l[0].distrito}</span></td>
                  <td className="num">{l.length}</td>
                  <td className="num hidden sm:table-cell">{l.filter((x) => x.estado === 'CONCLUIDA').length}</td>
                  <td className="num">{dinheiro(deCentimos(p))}</td>
                  <td className="num">{dinheiro(deCentimos(e))}</td>
                  <td className="num sm:pr-6">{pct(e, p)}</td>
                </tr>
              )
            })()}
          </tbody>
        </Tabela>
      )}
    </section>
  )
}
