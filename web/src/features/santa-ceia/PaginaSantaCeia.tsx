/**
 * Santa Ceia (V39) · "Quando é a próxima e quantos participaram nas anteriores?"
 * A próxima celebração agendada, o histórico em tabela (homens, mulheres, visitantes, total) e a evolução dos
 * participantes; agendar, registar os participantes depois de realizada, editar e cancelar.
 */
import { useEffect, useState } from 'react'
import { CalendarCheck, CalendarPlus, Check, MoreHorizontal, Pencil, Printer, Search, UserCheck, Users, Wine, XCircle } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { Cartao, Indicador, Pilula, Segmentos, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { GraficoBarras } from '@/components/comum/graficos'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { data, dataPorExtenso, hojeIso } from '@/lib/formatos'
import { useMembrosBasicos } from '@/features/membros/api'
import { ROTULO_ESTADO, gravarAcompanhantes, gravarParticipacao, lerAcompanhantes, lerParticipantes, lerSantaCeia, useHistoricoSantaCeia, useParticipacaoSantaCeia, useSantaCeiaMut, type SantaCeia } from './api'
import { useConselho } from '@/features/conselho/api'
import { Seleccao } from '@/components/comum/Seleccao'
import { cn } from '@/lib/utils'
import { EscolhaMultipla, type OpcaoEscolha } from '@/components/comum/CampoEscolha'
import { CampoHora } from '@/components/comum/CampoHora'

const VARIANTE = { AGENDADA: 'info', REALIZADA: 'success', CANCELADA: 'secondary' } as const

export default function PaginaSantaCeia() {
  const { pode } = useSessao()
  const q = useHistoricoSantaCeia()
  const { alterar } = useSantaCeiaMut()
  const [agendar, setAgendar] = useState<SantaCeia | 'nova' | null>(null)
  const [participantes, setParticipantes] = useState<SantaCeia | null>(null)
  const podeGerir = pode('actividades.santa_ceia.criar')
  const hoje = hojeIso()
  const lista = q.data ?? []
  const proxima = [...lista].filter((s) => s.estado === 'AGENDADA' && s.data >= hoje).sort((a, b) => a.data.localeCompare(b.data))[0]
  const realizadas = lista.filter((s) => s.estado === 'REALIZADA').sort((a, b) => a.data.localeCompare(b.data))
  const doAno = realizadas.filter((s) => s.ano === Number(hoje.slice(0, 4)))
  const media = doAno.length ? Math.round(doAno.reduce((s, x) => s + x.total, 0) / doAno.length) : 0
  const ultima = realizadas.at(-1), anterior = realizadas.at(-2)
  const porRegistar = lista.filter((s) => s.estado === 'AGENDADA' && s.data < hoje)
  const recentes = realizadas.slice(-8)
  const anosComNomes = [...new Set(realizadas.filter((s) => (s.nomeados ?? 0) > 0).map((s) => s.ano))].sort((a, b) => b - a)
  const cancelar = (s: SantaCeia) => alterar.mutate({ id: s.stcId, estado: 'CANCELADA' }, {
    onSuccess: () => toast.success('Santa Ceia cancelada.'), onError: (e) => toast.error(mensagemDe(e)),
  })

  return (
    <>
      <TituloPagina icone={Wine} titulo="Santa Ceia" descricao="Agendamento e participação nas celebrações"
        accoes={podeGerir && <Button className="alvo" onClick={() => setAgendar('nova')}><CalendarPlus className="size-4" />Agendar Santa Ceia</Button>} />

      {q.isPending ? <div className="grid gap-3"><Barra className="h-24 w-full" /><Barra className="h-64 w-full" /></div>
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
        : (
          <div className="grid gap-6">
            <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
              <Indicador rotulo="Próxima" valor={proxima ? data(proxima.data) : '—'} icone={CalendarCheck}
                nota={proxima ? [proxima.hora, proxima.local].filter(Boolean).join(' · ') || 'agendada' : 'nenhuma agendada'} />
              <Indicador rotulo="Celebrações no ano" valor={doAno.length} icone={Wine} tom="success" nota={`${realizadas.length} no total registadas`} />
              <Indicador rotulo="Média de participantes" valor={media} icone={Users} tom="info" nota="por celebração, este ano" />
              <Indicador rotulo="Última" valor={ultima ? ultima.total : '—'} icone={Users}
                tom={ultima && anterior && ultima.total < anterior.total ? 'warning' : 'primary'}
                nota={ultima ? `${data(ultima.data)}${anterior ? ` · anterior: ${anterior.total}` : ''}` : 'sem registo'} />
            </div>

            {porRegistar.length > 0 && podeGerir && (
              <section role="status" className="rounded-xl border border-warning/50 bg-tint-warning p-4 text-sm">
                <p className="font-semibold text-warning-text">Falta registar os participantes</p>
                <ul className="mt-2 flex flex-wrap gap-2">
                  {porRegistar.map((s) => (
                    <li key={s.stcId}><Button size="sm" variant="outline" className="alvo bg-card" onClick={() => setParticipantes(s)}>{data(s.data)} · registar</Button></li>
                  ))}
                </ul>
              </section>
            )}

            {recentes.length > 1 && (
              <Cartao titulo="Participantes" descricao="Últimas celebrações realizadas">
                <GraficoBarras rotulo="Participantes por celebração" categorias={recentes.map((s) => data(s.data).slice(0, 5))} inteiros
                  series={[{ nome: 'Homens', slot: 1, valores: recentes.map((s) => s.homens ?? 0) }, { nome: 'Mulheres', slot: 3, valores: recentes.map((s) => s.mulheres ?? 0) },
                    { nome: 'Visitantes', slot: 2, valores: recentes.map((s) => s.visitantes ?? 0) }]} formatar={(v) => String(v)} />
              </Cartao>
            )}

            <section className="rounded-xl border bg-card shadow-card" aria-label="Histórico">
              {!lista.length ? (
                <EstadoVazio icone={Wine} titulo="Ainda sem Santa Ceia registada"
                  accao={podeGerir && <Button onClick={() => setAgendar('nova')}><CalendarPlus className="size-4" />Agendar</Button>}>
                  Agende a próxima celebração; depois de realizada, registe os participantes.
                </EstadoVazio>
              ) : (
                <Tabela>
                  <thead>
                    <tr>
                      <th className="sm:pl-6">Data</th>
                      <th className="hidden md:table-cell">Local</th>
                      <th className="hidden lg:table-cell">Responsável</th>
                      <th>Estado</th>
                      <th className="num hidden sm:table-cell">Homens</th>
                      <th className="num hidden sm:table-cell">Mulheres</th>
                      <th className="num hidden sm:table-cell">Visitantes</th>
                      <th className="num">Total</th>
                      <th className="w-12 sm:pr-6"><span className="sr-only">Acções</span></th>
                    </tr>
                  </thead>
                  <tbody>
                    {[...lista].sort((a, b) => b.data.localeCompare(a.data)).map((s) => (
                      <tr key={s.stcId}>
                        <td className="sm:pl-6"><span className="block font-medium first-letter:uppercase">{dataPorExtenso(s.data)}</span><span className="block text-xs text-muted-foreground">{data(s.data)}{s.hora ? ` · ${s.hora}` : ''}</span></td>
                        <td className="hidden md:table-cell">{s.local ?? '—'}</td>
                        <td className="hidden lg:table-cell">{s.responsavel ?? '—'}</td>
                        <td><Pilula variante={VARIANTE[s.estado]}>{ROTULO_ESTADO[s.estado]}</Pilula></td>
                        <td className="num hidden sm:table-cell">{s.homens ?? '—'}</td>
                        <td className="num hidden sm:table-cell">{s.mulheres ?? '—'}</td>
                        <td className="num hidden sm:table-cell">{s.visitantes ?? '—'}</td>
                        <td className="num"><span className="font-semibold">{s.estado === 'REALIZADA' ? s.total : '—'}</span>
                          {s.estado === 'REALIZADA' && (s.nomeados ?? 0) > 0 && <span className="block text-xs whitespace-nowrap text-muted-foreground">{s.nomeados} pelo nome</span>}</td>
                        <td className="sm:pr-6">
                          {podeGerir && s.estado !== 'CANCELADA' && (
                            <DropdownMenu>
                              <DropdownMenuTrigger asChild>
                                <Button variant="ghost" size="icon" className="alvo size-9 text-muted-foreground" aria-label={`Acções de ${data(s.data)}`}><MoreHorizontal className="size-4" /></Button>
                              </DropdownMenuTrigger>
                              <DropdownMenuContent align="end">
                                {s.data <= hoje && <DropdownMenuItem onSelect={() => setParticipantes(s)}><Users className="size-4" />{s.estado === 'REALIZADA' ? 'Corrigir participantes' : 'Registar participantes'}</DropdownMenuItem>}
                                <DropdownMenuItem onSelect={() => setAgendar(s)}><Pencil className="size-4" />Editar</DropdownMenuItem>
                                {s.estado === 'AGENDADA' && (<><DropdownMenuSeparator /><DropdownMenuItem className="text-destructive-text" onSelect={() => cancelar(s)}><XCircle className="size-4" />Cancelar</DropdownMenuItem></>)}
                              </DropdownMenuContent>
                            </DropdownMenu>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </Tabela>
              )}
            </section>

            {anosComNomes.length > 0 && <ParticipacaoMembros anos={anosComNomes} />}
          </div>
        )}

      {agendar && <DialogoAgendar santaCeia={agendar === 'nova' ? undefined : agendar} aoFechar={() => setAgendar(null)} />}
      {participantes && <DialogoParticipantes s={participantes} aoFechar={() => setParticipantes(null)} />}
    </>
  )
}

function DialogoAgendar({ santaCeia, aoFechar }: { santaCeia?: SantaCeia; aoFechar: () => void }) {
  const igreja = useIgreja()
  const basicos = useMembrosBasicos()
  const { criar, alterar } = useSantaCeiaMut()
  const [dia, setDia] = useState(santaCeia?.data ?? '')
  const [hora, setHora] = useState(santaCeia?.hora ?? '09:00')
  const [local, setLocal] = useState(santaCeia?.local ?? '')
  const [responsavel, setResponsavel] = useState<number | null>(null)
  const [observacoes, setObservacoes] = useState('')
  const [diaconos, setDiaconos] = useState<string[]>([])
  const [diaconisas, setDiaconisas] = useState<string[]>([])
  // quem dirige: o pastor ou um ancião ordenado; a equipa de apoio: os diáconos e as diaconisas (sem número fixo)
  const conselho = useConselho()
  const activos = (conselho.data ?? []).filter((o) => o.estadoMandato === 'ACTIVO' || o.estadoMandato === 'A_TERMINAR')
  const unicos = (l: typeof activos) => [...new Map(l.map((o) => [o.membroId, o])).values()]
  const oficiantes = unicos(activos.filter((o) => /anci[aã]o|pastor/i.test(o.cargo)))
  const opcoesEquipa = (funcao: 'DIACONO' | 'DIACONISA'): OpcaoEscolha[] => {
    // primeiro quem tem o cargo no mandato em exercício; depois os outros membros activos do mesmo sexo
    const cargo = new Map(unicos(activos.filter((o) => (funcao === 'DIACONO' ? /di[aá]cono(?!isa)/i : /diaconisa/i).test(o.cargo))).map((o) => [o.membroId, o.cargo]))
    const outro = funcao === 'DIACONO' ? diaconisas : diaconos
    return (basicos.data ?? [])
      .filter((m) => m.estado === 'ACTIVO' && m.id !== responsavel && !outro.includes(String(m.id)) && m.sexo !== (funcao === 'DIACONO' ? 'F' : 'M'))
      .map((m) => ({ valor: String(m.id), rotulo: `${m.nome} ${m.apelido}`, detalhe: cargo.get(m.id) ?? undefined }))
      .sort((a, b) => Number(!a.detalhe) - Number(!b.detalhe) || a.rotulo.localeCompare(b.rotulo, 'pt'))
  }
  const [erro, setErro] = useState<string | null>(null)
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }
  // ao editar: o responsável e as observações vêm da ficha (a vista só tem o nome)
  const id = santaCeia?.stcId
  useEffect(() => {
    if (!id) return
    let vivo = true
    lerSantaCeia(id).then((f) => {
      if (!vivo) return
      const x = f as { responsavelMembroId?: number | null; observacoes?: string | null }
      setResponsavel(x.responsavelMembroId ?? null)
      setObservacoes(x.observacoes ?? '')
    }).catch(() => undefined)
    lerAcompanhantes(id, igreja.id).then((l) => {
      if (!vivo) return
      setDiaconos(l.filter((a) => a.funcao !== 'DIACONISA').map((a) => String(a.membroId)))
      setDiaconisas(l.filter((a) => a.funcao === 'DIACONISA').map((a) => String(a.membroId)))
    }).catch(() => undefined)
    return () => { vivo = false }
  }, [id, igreja.id])
  const gravar = async () => {
    setErro(null)
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dia)) return setErro('Escreva a data como dd/mm/aaaa.')
    const corpo = { data: dia, hora: hora || null, local: local.trim() || null, responsavelMembroId: responsavel, observacoes: observacoes.trim() || null }
    try {
      let stcId = santaCeia?.stcId
      if (santaCeia) await alterar.mutateAsync({ id: santaCeia.stcId, ...corpo })
      else stcId = ((await criar.mutateAsync({ igrejaId: igreja.id, ...corpo })) as { id: number }).id
      if (stcId) await gravarAcompanhantes(stcId, igreja.id, [
        ...diaconos.map((m) => ({ membroId: Number(m), funcao: 'DIACONO' as const })),
        ...diaconisas.map((m) => ({ membroId: Number(m), funcao: 'DIACONISA' as const })),
      ])
      toast.success(santaCeia ? 'Santa Ceia actualizada.' : 'Santa Ceia agendada.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{santaCeia ? 'Editar Santa Ceia' : 'Agendar Santa Ceia'}</DialogTitle>
          <DialogDescription className="sr-only">Data, oficiante e equipa de apoio</DialogDescription>
        </DialogHeader>
        <ErroFormulario mensagem={erro} />
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="grid grid-cols-2 gap-3 sm:col-span-2">
            <div className="campo-flutuante grid gap-1.5"><label htmlFor="stc-data" className="text-sm font-medium">Data <span className="text-destructive-text">*</span></label><CampoData id="stc-data" value={dia} onChange={setDia} className="alvo" /></div>
            <div className="campo-flutuante grid gap-1.5"><label htmlFor="stc-hora" className="text-sm font-medium">Hora</label><CampoHora id="stc-hora" value={hora} onChange={(e) => setHora(e.target.value)} className="alvo w-full" /></div>
          </div>
          <div className="campo-flutuante grid gap-1.5 sm:col-span-2"><label htmlFor="stc-local" className="text-sm font-medium">Local</label><Input id="stc-local" value={local} onChange={(e) => setLocal(e.target.value)} maxLength={150} className="alvo" placeholder="ex.: Templo" /></div>
          <div className="campo-flutuante grid gap-1.5 sm:col-span-2"><label htmlFor="stc-resp" className="text-sm font-medium">Oficiante <span className="font-normal text-muted-foreground">(pastor ou ancião)</span></label>
            {oficiantes.length ? (
              <Seleccao id="stc-resp" value={responsavel ? String(responsavel) : ''} onChange={(e) => setResponsavel(e.target.value ? Number(e.target.value) : null)}>
                <option value="">Escolher…</option>
                {oficiantes.map((o) => <option key={o.membroId} value={o.membroId}>{o.membro} · {o.cargo}</option>)}
                {responsavel && !oficiantes.some((o) => o.membroId === responsavel) && <option value={responsavel}>{nomeDe(responsavel) ?? 'Outro'}</option>}
              </Seleccao>
            ) : <CampoMembro id="stc-resp" valor={responsavel} aoMudar={setResponsavel} nomeDe={nomeDe} />}
          </div>
          <div className="campo-flutuante grid gap-1.5"><label htmlFor="stc-diaconos">Diáconos</label>
            <EscolhaMultipla id="stc-diaconos" valores={diaconos} aoMudar={setDiaconos} opcoes={opcoesEquipa('DIACONO')} vazio="Escolher diáconos…" pesquisar="Procurar pelo nome…" semOpcoes="Sem membros activos" />
          </div>
          <div className="campo-flutuante grid gap-1.5"><label htmlFor="stc-diaconisas">Diaconisas</label>
            <EscolhaMultipla id="stc-diaconisas" valores={diaconisas} aoMudar={setDiaconisas} opcoes={opcoesEquipa('DIACONISA')} vazio="Escolher diaconisas…" pesquisar="Procurar pelo nome…" semOpcoes="Sem membros activos" />
          </div>
          <div className="campo-flutuante grid gap-1.5 sm:col-span-2"><label htmlFor="stc-obs" className="text-sm font-medium">Observações</label><Textarea id="stc-obs" value={observacoes} onChange={(e) => setObservacoes(e.target.value)} rows={2} maxLength={500} placeholder="Opcional" /></div>
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={criar.isPending || alterar.isPending} onClick={gravar}>{criar.isPending || alterar.isPending ? t.comum.aGravar : t.comum.guardar}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function DialogoParticipantes({ s, aoFechar }: { s: SantaCeia; aoFechar: () => void }) {
  const igreja = useIgreja()
  const qc = useQueryClient()
  const basicos = useMembrosBasicos()
  const [homens, setHomens] = useState(s.homens != null ? String(s.homens) : '')
  const [mulheres, setMulheres] = useState(s.mulheres != null ? String(s.mulheres) : '')
  const [visitantes, setVisitantes] = useState(s.visitantes != null ? String(s.visitantes) : '0')
  const [marcados, setMarcados] = useState<number[]>([])
  const [antes, setAntes] = useState<number[]>([])
  const [busca, setBusca] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const [aGravar, setAGravar] = useState(false)
  useEffect(() => {
    let vivo = true
    lerParticipantes(s.stcId, igreja.id).then((l) => { if (vivo) { const ids = l.map((p) => p.membroId); setMarcados(ids); setAntes(ids) } }).catch(() => undefined)
    return () => { vivo = false }
  }, [s.stcId, igreja.id])
  const num = (v: string) => (/^\d{1,4}$/.test(v.trim()) ? Number(v) : null)
  const total = (num(homens) ?? 0) + (num(mulheres) ?? 0) + (num(visitantes) ?? 0)
  // os membros activos (e quem já estava marcado), por ordem alfabética
  const membros = (basicos.data ?? []).filter((m) => m.estado === 'ACTIVO' || antes.includes(m.id))
    .sort((a, b) => `${a.nome} ${a.apelido}`.localeCompare(`${b.nome} ${b.apelido}`, 'pt'))
  const sexoDe = new Map(membros.map((m) => [m.id, m.sexo]))
  const contar = (lista: number[], sexo: 'M' | 'F') => lista.filter((id) => sexoDe.get(id) === sexo).length
  const hm = contar(marcados, 'M'), mm = contar(marcados, 'F')
  const normal = (x: string) => x.normalize('NFD').replace(/\p{Diacritic}/gu, '').toLowerCase()
  const visiveis = busca.trim() ? membros.filter((m) => normal(`${m.nome} ${m.apelido}`).includes(normal(busca.trim()))) : membros
  // marcar nomes sobe os números quando ficam abaixo (os números incluem quem não foi marcado pelo nome)
  useEffect(() => {
    setHomens((v) => ((num(v) ?? 0) < hm ? String(hm) : v))
    setMulheres((v) => ((num(v) ?? 0) < mm ? String(mm) : v))
  }, [hm, mm])
  const marcar = setMarcados
  const trocar = (id: number) => setMarcados((l) => (l.includes(id) ? l.filter((x) => x !== id) : [...l, id]))
  const gravar = async () => {
    setErro(null)
    const h = num(homens), m = num(mulheres), v = num(visitantes)
    if (h == null || m == null || v == null) return setErro('Escreva os três números (0 se não houve).')
    if (h < hm) return setErro(`Estão marcados ${hm} homens pelo nome: o número de homens não pode ser menor.`)
    if (m < mm) return setErro(`Estão marcadas ${mm} mulheres pelo nome: o número de mulheres não pode ser menor.`)
    setAGravar(true)
    try {
      await gravarParticipacao(s.stcId, igreja.id, marcados, { estado: 'REALIZADA', homens: h, mulheres: m, visitantes: v })
      toast.success('Participantes registados.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) } finally {
      setAGravar(false)
      void qc.invalidateQueries({ queryKey: ['santa-ceia'] })
    }
  }
  const campo = (id: string, rotulo: string, v: string, set: (x: string) => void) => (
    <div className="campo-flutuante grid gap-1.5"><label htmlFor={id} className="text-sm font-medium">{rotulo}</label>
      <Input id={id} value={v} onChange={(e) => set(e.target.value)} inputMode="numeric" className="alvo num text-center text-lg" /></div>
  )
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Participantes da Santa Ceia</DialogTitle>
          <DialogDescription className="first-letter:uppercase">{dataPorExtenso(s.data)}</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid grid-cols-3 gap-3">
            {campo('stc-h', 'Homens', homens, setHomens)}
            {campo('stc-m', 'Mulheres', mulheres, setMulheres)}
            {campo('stc-v', 'Visitantes', visitantes, setVisitantes)}
          </div>
          <p className="text-center text-sm text-muted-foreground">Total: <strong className="text-foreground tabular-nums">{total}</strong></p>

          <section aria-labelledby="stc-nomes" className="grid gap-2 border-t pt-4">
            <div className="flex flex-wrap items-baseline justify-between gap-2">
              <h3 id="stc-nomes" className="text-sm font-semibold">Quem participou <span className="font-normal text-muted-foreground">(membros, pelo nome)</span></h3>
              <span className="text-xs text-muted-foreground tabular-nums">{marcados.length} marcados{marcados.length ? ` · ${hm} H · ${mm} M` : ''}</span>
            </div>
            <div className="flex gap-2">
              <div className="relative min-w-0 flex-1">
                <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" aria-hidden />
                <Input value={busca} onChange={(e) => setBusca(e.target.value)} placeholder="Procurar pelo nome…" aria-label="Procurar membro" className="pl-9" />
              </div>
              <Button type="button" variant="outline" onClick={() => marcar([...new Set([...marcados, ...visiveis.map((m) => m.id)])])}>Marcar todos</Button>
            </div>
            <ul className="max-h-64 divide-y overflow-y-auto rounded-[2px] border" aria-label="Membros activos">
              {basicos.isPending && <li className="px-3 py-6 text-center text-sm text-muted-foreground">A carregar…</li>}
              {!basicos.isPending && !visiveis.length && <li className="px-3 py-6 text-center text-sm text-muted-foreground">Nenhum membro encontrado</li>}
              {visiveis.map((m) => {
                const sim = marcados.includes(m.id)
                return (
                  <li key={m.id}>
                    <button type="button" role="checkbox" aria-checked={sim} onClick={() => trocar(m.id)}
                      className={cn('alvo flex w-full items-center gap-3 px-3 py-2 text-left text-sm transition-colors hover:bg-muted/60', sim && 'bg-primary/5')}>
                      <span className={cn('flex size-4 flex-none items-center justify-center rounded-[2px] border', sim ? 'border-primary bg-primary text-primary-foreground' : 'border-input bg-card')} aria-hidden>
                        {sim && <Check className="size-3" />}
                      </span>
                      <span className={cn('min-w-0 flex-1 truncate', sim && 'font-medium')}>{m.nome} {m.apelido}</span>
                      {m.sexo && <span className="text-xs text-muted-foreground">{m.sexo === 'M' ? 'Homem' : 'Mulher'}</span>}
                    </button>
                  </li>
                )
              })}
            </ul>
            {marcados.length > 0 && <button type="button" className="justify-self-end text-xs font-medium text-primary hover:underline" onClick={() => marcar([])}>Desmarcar todos</button>}
          </section>
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={aGravar} onClick={gravar}>{aGravar ? t.comum.aGravar : 'Registar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/** V52 · Relatório: em quantas Santas Ceias (com nomes) cada membro participou no ano, as faltas e a última. */
function ParticipacaoMembros({ anos }: { anos: number[] }) {
  const [ano, setAno] = useState(anos[0])
  const [filtro, setFiltro] = useState<'todos' | 'faltas' | 'nunca'>('todos')
  const q = useParticipacaoSantaCeia(ano)
  const linhas = q.data ?? []
  const celebracoes = linhas[0]?.celebracoes ?? 0
  const nunca = linhas.filter((l) => l.participacoes === 0)
  const comFaltas = linhas.filter((l) => l.faltas > 0)
  const todas = linhas.filter((l) => l.faltas === 0)
  const vistas = filtro === 'nunca' ? nunca : filtro === 'faltas' ? comFaltas : linhas
  const ordenadas = [...vistas].sort((a, b) => a.participacoes - b.participacoes || a.membro.localeCompare(b.membro, 'pt'))
  return (
    <Cartao icone={UserCheck} titulo="Participação dos membros" recolhivel className="print:border-0 print:shadow-none"
      descricao={celebracoes ? `${celebracoes} celebraç${celebracoes === 1 ? 'ão' : 'ões'} com os nomes registados em ${ano}` : `Só contam as celebrações com os participantes registados pelo nome`}
      accoes={(
        <div className="flex items-center gap-2 print:hidden">
          <Seleccao aria-label="Ano" value={String(ano)} onChange={(e) => setAno(Number(e.target.value))} className="w-28">
            {anos.map((a) => <option key={a} value={a}>{a}</option>)}
          </Seleccao>
          <Button variant="outline" onClick={() => window.print()}><Printer className="size-4" />Imprimir</Button>
        </div>
      )}>
      {q.isPending ? <Barra className="h-40 w-full" /> : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} /> : !linhas.length ? (
        <EstadoVazio icone={UserCheck} titulo="Sem participantes registados pelo nome">
          Ao registar os participantes de uma Santa Ceia, marque quem participou: aqui aparece quem faltou e quem nunca participou.
        </EstadoVazio>
      ) : (
        <div className="grid gap-4">
          <div className="hidden grid-cols-3 gap-3 sm:grid">
            <Indicador rotulo="Em todas" valor={todas.length} icone={UserCheck} tom="success" nota={`de ${linhas.length} membros`} />
            <Indicador rotulo="Faltaram a alguma" valor={comFaltas.length} icone={Users} tom="warning" nota="pelo menos uma falta" />
            <Indicador rotulo="Nunca participaram" valor={nunca.length} icone={XCircle} tom={nunca.length ? 'destructive' : 'primary'} nota={`em ${ano}`} />
          </div>
          <Segmentos rotulo="Mostrar" valor={filtro} aoMudar={setFiltro} className="print:hidden"
            opcoes={[{ valor: 'todos', rotulo: 'Todos', contagem: linhas.length }, { valor: 'faltas', rotulo: 'Com faltas', contagem: comFaltas.length }, { valor: 'nunca', rotulo: 'Nunca participaram', contagem: nunca.length }]} />
          <div className="-mx-4 sm:-mx-6">
            <Tabela>
              <thead>
                <tr>
                  <th className="sm:pl-6">Membro</th>
                  <th className="num">Participou</th>
                  <th className="num hidden sm:table-cell">Faltas</th>
                  <th className="sm:pr-6">Última</th>
                </tr>
              </thead>
              <tbody>
                {ordenadas.map((l) => (
                  <tr key={l.membroId}>
                    <td className="sm:pl-6"><span className="font-medium">{l.membro}</span></td>
                    <td className="num"><span className={cn('tabular-nums', l.participacoes === 0 && 'font-semibold text-destructive-text')}>{l.participacoes} de {l.celebracoes}</span></td>
                    <td className="num hidden sm:table-cell">{l.faltas || '—'}</td>
                    <td className="sm:pr-6">{l.ultima ? data(l.ultima) : <span className="text-muted-foreground">Nunca</span>}</td>
                  </tr>
                ))}
              </tbody>
            </Tabela>
          </div>
        </div>
      )}
    </Cartao>
  )
}
