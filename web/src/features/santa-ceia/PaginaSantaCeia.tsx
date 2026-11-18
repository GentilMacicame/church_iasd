/**
 * Santa Ceia (V39) · "Quando é a próxima e quantos participaram nas anteriores?"
 * A próxima celebração agendada, o histórico em tabela (homens, mulheres, visitantes, total) e a evolução dos
 * participantes; agendar, registar os participantes depois de realizada, editar e cancelar.
 */
import { useEffect, useState } from 'react'
import { CalendarCheck, CalendarPlus, Clock, MapPin, MoreHorizontal, Pencil, Users, Wine, XCircle } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { Cartao, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
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
import { ROTULO_ESTADO, lerSantaCeia, useHistoricoSantaCeia, useSantaCeiaMut, type SantaCeia } from './api'
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
                        <td className="sm:pl-6"><span className="font-medium capitalize">{dataPorExtenso(s.data)}</span><span className="block text-xs text-muted-foreground">{data(s.data)}{s.hora ? ` · ${s.hora}` : ''}</span></td>
                        <td className="hidden md:table-cell">{s.local ?? '—'}</td>
                        <td className="hidden lg:table-cell">{s.responsavel ?? '—'}</td>
                        <td><Pilula variante={VARIANTE[s.estado]}>{ROTULO_ESTADO[s.estado]}</Pilula></td>
                        <td className="num hidden sm:table-cell">{s.homens ?? '—'}</td>
                        <td className="num hidden sm:table-cell">{s.mulheres ?? '—'}</td>
                        <td className="num hidden sm:table-cell">{s.visitantes ?? '—'}</td>
                        <td className="num font-semibold">{s.estado === 'REALIZADA' ? s.total : '—'}</td>
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
    return () => { vivo = false }
  }, [id])
  const gravar = async () => {
    setErro(null)
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dia)) return setErro('Escreva a data como dd/mm/aaaa.')
    const corpo = { data: dia, hora: hora || null, local: local.trim() || null, responsavelMembroId: responsavel, observacoes: observacoes.trim() || null }
    try {
      if (santaCeia) await alterar.mutateAsync({ id: santaCeia.stcId, ...corpo })
      else await criar.mutateAsync({ igrejaId: igreja.id, ...corpo })
      toast.success(santaCeia ? 'Santa Ceia actualizada.' : 'Santa Ceia agendada.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{santaCeia ? 'Editar Santa Ceia' : 'Agendar Santa Ceia'}</DialogTitle>
          <DialogDescription>Depois de realizada, registe os participantes.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="sm:col-span-2"><ErroFormulario mensagem={erro} /></div>
          <div className="grid gap-1.5"><label htmlFor="stc-data" className="text-sm font-medium">Data <span className="text-destructive-text">*</span></label><CampoData id="stc-data" value={dia} onChange={setDia} className="alvo" /></div>
          <div className="grid gap-1.5"><label htmlFor="stc-hora" className="text-sm font-medium"><Clock className="mr-1 inline size-3.5" />Hora</label><CampoHora id="stc-hora" value={hora} onChange={(e) => setHora(e.target.value)} className="alvo num" /></div>
          <div className="grid gap-1.5 sm:col-span-2"><label htmlFor="stc-local" className="text-sm font-medium"><MapPin className="mr-1 inline size-3.5" />Local</label><Input id="stc-local" value={local} onChange={(e) => setLocal(e.target.value)} maxLength={150} className="alvo" placeholder="ex.: Templo" /></div>
          <div className="grid gap-1.5 sm:col-span-2"><label htmlFor="stc-resp" className="text-sm font-medium">Responsável (quem oficia)</label>
            <CampoMembro id="stc-resp" valor={responsavel} aoMudar={setResponsavel} nomeDe={nomeDe} /></div>
          <div className="grid gap-1.5 sm:col-span-2"><label htmlFor="stc-obs" className="text-sm font-medium">Observações</label><Textarea id="stc-obs" value={observacoes} onChange={(e) => setObservacoes(e.target.value)} rows={2} maxLength={500} /></div>
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
  const { alterar } = useSantaCeiaMut()
  const [homens, setHomens] = useState(s.homens != null ? String(s.homens) : '')
  const [mulheres, setMulheres] = useState(s.mulheres != null ? String(s.mulheres) : '')
  const [visitantes, setVisitantes] = useState(s.visitantes != null ? String(s.visitantes) : '0')
  const [erro, setErro] = useState<string | null>(null)
  const num = (v: string) => (/^\d{1,4}$/.test(v.trim()) ? Number(v) : null)
  const total = (num(homens) ?? 0) + (num(mulheres) ?? 0) + (num(visitantes) ?? 0)
  const gravar = async () => {
    setErro(null)
    const h = num(homens), m = num(mulheres), v = num(visitantes)
    if (h == null || m == null || v == null) return setErro('Escreva os três números (0 se não houve).')
    try {
      await alterar.mutateAsync({ id: s.stcId, estado: 'REALIZADA', homens: h, mulheres: m, visitantes: v })
      toast.success('Participantes registados.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  const campo = (id: string, rotulo: string, v: string, set: (x: string) => void) => (
    <div className="grid gap-1.5"><label htmlFor={id} className="text-sm font-medium">{rotulo}</label>
      <Input id={id} value={v} onChange={(e) => set(e.target.value)} inputMode="numeric" className="alvo num text-center text-lg" /></div>
  )
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Participantes da Santa Ceia</DialogTitle>
          <DialogDescription className="capitalize">{dataPorExtenso(s.data)}</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid grid-cols-3 gap-3">
            {campo('stc-h', 'Homens', homens, setHomens)}
            {campo('stc-m', 'Mulheres', mulheres, setMulheres)}
            {campo('stc-v', 'Visitantes', visitantes, setVisitantes)}
          </div>
          <p className="text-center text-sm text-muted-foreground">Total: <strong className="text-foreground tabular-nums">{total}</strong></p>
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={alterar.isPending} onClick={gravar}>{alterar.isPending ? t.comum.aGravar : 'Registar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
