/**
 * Reunião · a preparação e o registo: agenda e deliberações, presenças (a partir do conselho da igreja), votos
 * formais, encerramento e o estado (convocada → realizada → acta aprovada, que fecha o registo). A acta para
 * imprimir/PDF está em /reunioes/:id/acta.
 */
import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ArrowLeft, Check, Circle, Clock, FileText, Landmark, ListChecks, Lock, Pencil, Plus, ShieldCheck, Users, Vote } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Pilula, Tabela } from '@/components/comum/elementos'
import { CampoData } from '@/components/comum/CampoData'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { Seleccao } from '@/components/comum/Seleccao'
import { ErroApi, mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { dataPorExtenso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { emExercicio, useConselho, type Oficial } from '@/features/conselho/api'
import { EscolherDoConselho } from '@/features/conselho/EscolherDoConselho'
import { useCriarVoto, usePontos, usePresencas, useReuniao, useReuniaoMut, useVotos, type EstadoPonto, type Ponto, type Presenca, type Reuniao, type TipoVoto, type Voto } from './api'
import { PilulaEstadoReuniao } from './PaginaReunioes'
import { CartaoDevocional } from './Devocional'
import { Paginada } from '@/components/comum/Paginacao'

const n = z.string().regex(/^\d*$/, 'Só algarismos')
const esquema = z.object({
  numero: z.string().trim().min(1, t.comum.obrigatorio).max(20),
  tipo: z.string().min(1),
  assunto: z.string().trim().min(1, t.comum.obrigatorio).max(255),
  texto: z.string().trim().max(2000),
  leitura: z.string(),
  aFavor: n, contra: n, abstencoes: n,
  estado: z.string(),
})

/** Próximo número da acta no ano da reunião: 2026-001, 2026-002, ... */
function proximoNumero(votos: Voto[], ano: string) {
  const maior = votos.map((v) => /^(\d{4})-(\d+)$/.exec(v.numero)).filter((m) => m && m[1] === ano).reduce((s, m) => Math.max(s, Number(m![2])), 0)
  return `${ano}-${String(maior + 1).padStart(3, '0')}`
}

function DialogoVoto({ reuniao, votos, aberto, aoMudar }: { reuniao: Reuniao; votos: Voto[]; aberto: boolean; aoMudar: (v: boolean) => void }) {
  const criar = useCriarVoto()
  const [erro, setErro] = useState<string | null>(null)
  const form = useForm({
    resolver: zodResolver(esquema),
    values: { numero: proximoNumero(votos, reuniao.data.slice(0, 4)), tipo: 'ADMISSAO', assunto: '', texto: '', leitura: '1', aFavor: '', contra: '', abstencoes: '', estado: 'APROVADO' },
  })
  const e = form.formState.errors
  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    const num = (x: string) => (x ? Number(x) : undefined)
    try {
      await criar.mutateAsync({
        reuniaoId: reuniao.id, numero: v.numero, tipo: v.tipo as TipoVoto, assunto: v.assunto, texto: v.texto || undefined,
        leitura: Number(v.leitura), aFavor: num(v.aFavor), contra: num(v.contra), abstencoes: num(v.abstencoes), estado: v.estado as Voto['estado'],
      })
      toast.success(`Voto ${v.numero} registado.`)
      aoMudar(false)
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })
  return (
    <Dialog open={aberto} onOpenChange={aoMudar}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Registar voto</DialogTitle>
          <DialogDescription>Como ficou na acta. Para uma admissão, ponha no assunto o nome da pessoa.</DialogDescription>
        </DialogHeader>
        <form onSubmit={submeter} noValidate className="grid gap-4 sm:grid-cols-2">
          <div className="sm:col-span-2"><ErroFormulario mensagem={erro} /></div>
          <CampoFormulario rotulo="Número na acta" erro={e.numero?.message} obrigatorio>
            {(p) => <Input {...p} {...form.register('numero')} className="alvo num" />}
          </CampoFormulario>
          <CampoFormulario rotulo="Tipo de voto">
            {(p) => <Seleccao {...p} {...form.register('tipo')}>{Object.entries(rotulos.tipoVoto).map(([k, r]) => <option key={k} value={k}>{r}</option>)}</Seleccao>}
          </CampoFormulario>
          <CampoFormulario rotulo="Assunto" erro={e.assunto?.message} obrigatorio className="sm:col-span-2" ajuda="ex.: Admissão por baptismo de Amélia Chirindza">
            {(p) => <Input {...p} {...form.register('assunto')} className="alvo" />}
          </CampoFormulario>
          <CampoFormulario rotulo="Texto do voto" erro={e.texto?.message} className="sm:col-span-2">
            {(p) => <Textarea {...p} {...form.register('texto')} rows={2} />}
          </CampoFormulario>
          <CampoFormulario rotulo="Leitura" ajuda="Transferências: votação na 2.ª leitura">
            {(p) => <Seleccao {...p} {...form.register('leitura')}><option value="1">1.ª leitura</option><option value="2">2.ª leitura (votação)</option></Seleccao>}
          </CampoFormulario>
          <CampoFormulario rotulo="Resultado">
            {(p) => <Seleccao {...p} {...form.register('estado')}>{Object.entries(rotulos.resultadoVoto).map(([k, r]) => <option key={k} value={k}>{r}</option>)}</Seleccao>}
          </CampoFormulario>
          <div className="grid grid-cols-3 gap-3 sm:col-span-2">
            <CampoFormulario rotulo="A favor" erro={e.aFavor?.message}>{(p) => <Input {...p} {...form.register('aFavor')} inputMode="numeric" className="alvo num" />}</CampoFormulario>
            <CampoFormulario rotulo="Contra" erro={e.contra?.message}>{(p) => <Input {...p} {...form.register('contra')} inputMode="numeric" className="alvo num" />}</CampoFormulario>
            <CampoFormulario rotulo="Abstenções" erro={e.abstencoes?.message}>{(p) => <Input {...p} {...form.register('abstencoes')} inputMode="numeric" className="alvo num" />}</CampoFormulario>
          </div>
          <DialogFooter className="sm:col-span-2">
            <Button type="button" variant="outline" onClick={() => aoMudar(false)}>{t.comum.cancelar}</Button>
            <Button type="submit" disabled={form.formState.isSubmitting}>{form.formState.isSubmitting ? t.comum.aGravar : 'Registar voto'}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

export function PilulaResultado({ v }: { v: Voto }) {
  return v.estado === 'APROVADO' ? <Pilula variante="success">Aprovado</Pilula> : v.estado === 'REJEITADO' ? <Pilula variante="destructive">Rejeitado</Pilula> : <Pilula variante="warning">Adiado</Pilula>
}

export default function PaginaReuniao() {
  const id = Number(useParams().id)
  const { pode } = useSessao()
  const q = useReuniao(id)
  const votos = useVotos()
  const basicos = useMembrosBasicos()
  const conselho = useConselho()
  const presencas = usePresencas(id)
  const pontos = usePontos(id)
  const mut = useReuniaoMut(id)
  const [novoVoto, setNovoVoto] = useState(false)
  const [ponto, setPonto] = useState<Ponto | 'novo' | null>(null)
  const [editar, setEditar] = useState(false)
  const [aprovar, setAprovar] = useState(false)
  const nomeDe = (mid?: number | null) => { const m = mid ? basicos.data?.find((x) => x.id === mid) : null; return m ? `${m.nome} ${m.apelido}` : null }

  const voltar = <Link to="/reunioes" className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" /> {t.livro.reunioes}</Link>
  if (q.isPending) return <>{voltar}<Barra className="h-40 w-full" /></>
  if (q.isError) return <>{voltar}{q.error instanceof ErroApi && q.error.naoEncontrado
    ? <div className="rounded-xl border bg-card shadow-card"><EstadoVazio icone={Landmark} titulo="Reunião não encontrada">Esta reunião não existe ou não é desta igreja.</EstadoVazio></div>
    : <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />}</>
  const r = q.data
  const daReuniao = (votos.data ?? []).filter((v) => v.reuniaoId === r.id).sort((a, b) => a.numero.localeCompare(b.numero))
  const quando = dataPorExtenso(r.data)
  const fechada = r.estado === 'ACTA_APROVADA' || r.estado === 'CANCELADA'
  const podeEditar = pode('secretaria.reuniao.alterar') && !fechada
  const listaPontos = (pontos.data ?? []).filter((p) => !p.endDate)
  const presentes = (presencas.data ?? []).filter((p) => !p.endDate && p.presente).length
  const mudarEstado = (estado: 'REALIZADA' | 'ACTA_APROVADA', msg: string) => mut.alterarReuniao.mutate(
    { estado, ...(estado === 'ACTA_APROVADA' && presencas.data?.length ? { quorumPresentes: presentes } : {}) } as never,
    { onSuccess: () => { toast.success(msg); setAprovar(false) }, onError: (e) => { toast.error(mensagemDe(e)); setAprovar(false) } })

  return (
    <>
      {voltar}
      <section className="mb-6 rounded-xl border bg-card p-5 shadow-card sm:p-6">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div className="flex min-w-0 items-start gap-3">
            <span className="flex size-11 flex-none items-center justify-center rounded-lg bg-primary/10 text-primary" aria-hidden><Landmark className="size-5" /></span>
            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <h1 className="text-2xl font-semibold tracking-tight">{rotulos.tipoReuniao[r.tipo]}</h1>
                {r.numero && <Pilula variante="outline" className="tabular-nums">n.º {r.numero}</Pilula>}
                <PilulaEstadoReuniao estado={r.estado} />
              </div>
              <p className="mt-1 text-sm text-muted-foreground">
                {quando.charAt(0).toUpperCase() + quando.slice(1)}, às {hora(r.data)}{r.local ? ` · ${r.local}` : ''}
              </p>
              <p className="mt-1 text-sm text-muted-foreground">
                Presidida por <span className="font-medium text-foreground">{nomeDe(r.presididaPorMembroId) ?? '—'}</span> · Secretário(a) <span className="font-medium text-foreground">{nomeDe(r.secretarioMembroId) ?? '—'}</span>
              </p>
            </div>
          </div>
          <div className="flex flex-wrap gap-2">
            <Button asChild variant="outline" className="alvo"><Link to={`/reunioes/${r.id}/acta`}><FileText className="size-4" />Acta</Link></Button>
            {podeEditar && <Button variant="outline" className="alvo" onClick={() => setEditar(true)}><Pencil className="size-4" />Editar</Button>}
            {podeEditar && r.estado === 'CONVOCADA' && <Button className="alvo" disabled={mut.alterarReuniao.isPending} onClick={() => mudarEstado('REALIZADA', 'Reunião marcada como realizada.')}><Check className="size-4" />Marcar como realizada</Button>}
            {podeEditar && r.estado === 'REALIZADA' && <Button className="alvo" onClick={() => setAprovar(true)}><ShieldCheck className="size-4" />Aprovar acta</Button>}
          </div>
        </div>
        {fechada && <p className="mt-4 flex items-center gap-2 rounded-lg border bg-muted/40 px-4 py-2.5 text-sm text-muted-foreground"><Lock className="size-4" />{r.estado === 'CANCELADA' ? 'Reunião cancelada.' : 'Acta aprovada: as presenças, a agenda e o encerramento já não se alteram.'}</p>}
      </section>

      <div className="grid items-start gap-6 lg:grid-cols-12">
        <div className="grid min-w-0 gap-6 lg:col-span-8">
          <Cartao titulo="Agenda e deliberações" descricao={`${listaPontos.length} ponto(s) · ${listaPontos.filter((p) => p.estado === 'APROVADO').length} aprovado(s) · ${listaPontos.filter((p) => p.estado === 'PENDENTE').length} pendente(s)`} icone={ListChecks} semMargem
            accoes={pode('secretaria.reuniao_ponto.criar') && !fechada && <Button size="sm" className="alvo" onClick={() => setPonto('novo')}><Plus className="size-4" />Acrescentar ponto</Button>}>
            {pontos.isPending ? <div className="px-6 pb-6"><Barra className="h-24 w-full" /></div>
              : pontos.isError ? <EstadoErro erro={pontos.error} aoTentar={() => pontos.refetch()} className="mx-6 mb-6" />
              : !listaPontos.length ? <EstadoVazio icone={ListChecks} titulo="Sem pontos na agenda">Acrescente os assuntos a tratar: o que se discutiu, se foi votado e o que se decidiu.</EstadoVazio>
              : (
                <Paginada itens={listaPontos}>{(vis, ini) => (
                <ol className="divide-y border-t">
                  {vis.map((p, iLocal) => { const i = ini + iLocal; return (
                    <li key={p.id}>
                      <button type="button" disabled={fechada || !pode('secretaria.reuniao_ponto.alterar')} onClick={() => setPonto(p)}
                        className="flex w-full gap-4 px-4 py-4 text-left enabled:hover:bg-muted/40 sm:px-6">
                        <span className="flex size-7 flex-none items-center justify-center rounded-full bg-muted text-xs font-semibold tabular-nums">{i + 1}</span>
                        <span className="min-w-0 flex-1">
                          <span className="flex flex-wrap items-center gap-2"><span className="font-medium">{p.assunto}</span><PilulaPonto estado={p.estado} /></span>
                          {p.detalhes && <span className="mt-1 line-clamp-2 block text-sm text-muted-foreground">{p.detalhes}</span>}
                          <span className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
                            <span className="inline-flex items-center gap-1">{p.discutido ? <Check className="size-3.5 text-success-text" /> : <Circle className="size-3" />}{p.discutido ? 'Discutido' : 'Por discutir'}</span>
                            {p.votado && <span className="inline-flex items-center gap-1 tabular-nums"><Vote className="size-3.5" />{p.aFavor ?? 0} a favor · {p.contra ?? 0} contra · {p.abstencoes ?? 0} abst.</span>}
                          </span>
                          {p.deliberacao && <span className="mt-2 block rounded-md border-l-2 border-primary/60 bg-primary/5 px-3 py-1.5 text-sm"><span className="font-medium">Deliberação: </span>{p.deliberacao}</span>}
                        </span>
                      </button>
                    </li>
                  ) })}
                </ol>
                )}</Paginada>
              )}
          </Cartao>

          <Cartao titulo="Votos da acta" descricao="Admissões, transferências, eleições: os votos formais, pela ordem do número" icone={Vote} semMargem
            accoes={pode('secretaria.voto.criar') && !fechada && <Button size="sm" variant="outline" className="alvo" onClick={() => setNovoVoto(true)}><Plus className="size-4" />Registar voto</Button>}>
            {votos.isPending ? <div className="px-6 pb-6"><Barra className="h-24 w-full" /></div>
              : votos.isError ? <EstadoErro erro={votos.error} aoTentar={() => votos.refetch()} className="mx-6 mb-6" />
              : daReuniao.length === 0 ? <EstadoVazio icone={Vote} titulo="Sem votos formais">Só para os actos que o livro de membros exige (admissões, transferências, remoções, eleições).</EstadoVazio>
              : (
                <Tabela>
                  <thead><tr><th className="sm:pl-6">N.º</th><th>Assunto</th><th className="hidden md:table-cell">Tipo</th><th className="num hidden sm:table-cell">Votação</th><th className="sm:pr-6">Resultado</th></tr></thead>
                  <tbody>
                    {daReuniao.map((v) => (
                      <tr key={v.id}>
                        <td className="tabular-nums font-medium whitespace-nowrap sm:pl-6">{v.numero}</td>
                        <td><p className="font-medium">{v.assunto}</p>{v.leitura === 2 && <p className="text-xs text-muted-foreground">2.ª leitura</p>}</td>
                        <td className="hidden text-muted-foreground md:table-cell">{rotulos.tipoVoto[v.tipo]}</td>
                        <td className="num hidden whitespace-nowrap text-muted-foreground sm:table-cell">{v.aFavor ?? '—'} / {v.contra ?? '—'} / {v.abstencoes ?? '—'}</td>
                        <td className="sm:pr-6"><PilulaResultado v={v} /></td>
                      </tr>
                    ))}
                  </tbody>
                </Tabela>
              )}
          </Cartao>
        </div>

        <div className="grid min-w-0 gap-6 lg:col-span-4 lg:sticky lg:top-[calc(var(--header-height)+1.5rem)]">
          <CartaoDevocional reuniao={r} fechada={!podeEditar} nomeDe={(id) => nomeDe(id) ?? undefined} />
          <Presencas reuniaoId={r.id} fechada={fechada} oficiais={conselho.data ?? []} presencas={presencas.data ?? []} aCarregar={presencas.isPending || conselho.isPending} nomeDe={nomeDe} />
          <Encerramento reuniao={r} fechada={!podeEditar} />
        </div>
      </div>

      <DialogoVoto reuniao={r} votos={votos.data ?? []} aberto={novoVoto} aoMudar={setNovoVoto} />
      {ponto && <DialogoPonto reuniaoId={r.id} ponto={ponto === 'novo' ? null : ponto} ordem={listaPontos.length + 1} votos={daReuniao} aoFechar={() => setPonto(null)} />}
      {editar && <DialogoEditarReuniao reuniao={r} aoFechar={() => setEditar(false)} />}
      <DialogoConfirmar aberto={aprovar} aoMudar={setAprovar} titulo="Aprovar a acta?"
        texto={<>Depois de aprovada, a acta fica fechada: as presenças ({presentes} presente(s)), os {listaPontos.length} pontos da agenda e o encerramento já não se alteram.</>}
        accao="Aprovar acta" aCorrer={mut.alterarReuniao.isPending} aoConfirmar={() => mudarEstado('ACTA_APROVADA', 'Acta aprovada.')} />
    </>
  )
}

const hora = (iso?: string | null) => (iso ? new Date(iso).toLocaleTimeString('pt-PT', { hour: '2-digit', minute: '2-digit', timeZone: 'Africa/Maputo' }) : '')

const ESTADO_PONTO: Record<EstadoPonto, { r: string; v: 'secondary' | 'success' | 'destructive' | 'warning' | 'info' }> = {
  PENDENTE: { r: 'Pendente', v: 'warning' }, APROVADO: { r: 'Aprovado', v: 'success' }, REJEITADO: { r: 'Rejeitado', v: 'destructive' },
  ADIADO: { r: 'Adiado', v: 'secondary' }, INFORMATIVO: { r: 'Informativo', v: 'info' },
}
export function PilulaPonto({ estado }: { estado: EstadoPonto }) {
  return <Pilula variante={ESTADO_PONTO[estado].v}>{ESTADO_PONTO[estado].r}</Pilula>
}

/** Presenças: os membros do conselho em exercício (presente / ausente) e outros participantes. */
function Presencas({ reuniaoId, fechada, oficiais, presencas, aCarregar, nomeDe }: {
  reuniaoId: number; fechada: boolean; oficiais: Oficial[]; presencas: Presenca[]; aCarregar: boolean; nomeDe: (id?: number | null) => string | null
}) {
  const { pode } = useSessao()
  const mut = useReuniaoMut(reuniaoId)
  const [outro, setOutro] = useState<number | null>(null)
  const podeMarcar = !fechada && pode('secretaria.reuniao_presenca.criar') && pode('secretaria.reuniao_presenca.alterar')
  const activas = presencas.filter((p) => !p.endDate)
  const porMembro = new Map(activas.map((p) => [p.membroId, p]))
  // o conselho em exercício (uma linha por pessoa, com os cargos juntos) + quem foi acrescentado
  const cargos = new Map<number, string[]>()
  for (const o of oficiais.filter(emExercicio)) cargos.set(o.membroId, [...(cargos.get(o.membroId) ?? []), o.cargo])
  const pessoas = [...cargos.keys(), ...activas.map((p) => p.membroId).filter((m) => !cargos.has(m))]
  const presentes = activas.filter((p) => p.presente).length
  const ausentes = activas.filter((p) => !p.presente).length
  const porMarcar = pessoas.filter((m) => !porMembro.has(m)).length
  const marcar = (membroId: number, presente: boolean, justificacao?: string) => mut.marcar.mutate(
    { existente: porMembro.get(membroId), membroId, presente, funcao: cargos.get(membroId)?.join(', ') ?? null, justificacao },
    { onError: (e) => toast.error(mensagemDe(e)) })
  const todosPresentes = () => pessoas.filter((m) => !porMembro.has(m)).forEach((m) => marcar(m, true))

  return (
    <Cartao titulo="Presenças" descricao={`${presentes} presente(s) · ${ausentes} ausente(s)${porMarcar ? ` · ${porMarcar} por marcar` : ''}`} icone={Users} semMargem
      accoes={podeMarcar && porMarcar > 0 && <Button size="sm" variant="ghost" onClick={todosPresentes}>Todos presentes</Button>}>
      {aCarregar ? <div className="px-6 pb-6"><Barra className="h-32 w-full" /></div>
        : !pessoas.length ? <EstadoVazio icone={Users} titulo="Sem conselho registado">Registe os oficiais em <Link to="/conselho" className="font-medium text-primary hover:underline">Conselho da igreja</Link> ou acrescente participantes abaixo.</EstadoVazio>
        : (
          <Paginada itens={pessoas}>{(vis) => (
          <ul className="divide-y border-t">
            {vis.map((m) => {
              const p = porMembro.get(m)
              return (
                <li key={m} className="px-4 py-3 sm:px-6">
                  <div className="flex items-center justify-between gap-3">
                    <div className="min-w-0">
                      <p className="truncate text-sm font-medium">{nomeDe(m) ?? `Membro ${m}`}</p>
                      <p className="truncate text-xs text-muted-foreground">{cargos.get(m)?.join(', ') ?? p?.funcao ?? 'Participante'}</p>
                    </div>
                    <div role="radiogroup" aria-label={`Presença de ${nomeDe(m) ?? ''}`} className="flex flex-none rounded-lg bg-muted p-0.5">
                      {[{ v: true, r: 'Presente' }, { v: false, r: 'Ausente' }].map((o) => (
                        <button key={o.r} type="button" role="radio" aria-checked={p?.presente === o.v} disabled={!podeMarcar || mut.marcar.isPending}
                          onClick={() => marcar(m, o.v)}
                          className={cn('alvo rounded-md px-2.5 py-1 text-xs font-medium text-muted-foreground disabled:cursor-not-allowed',
                            p?.presente === o.v && (o.v ? 'bg-card text-success-text shadow-sm' : 'bg-card text-destructive-text shadow-sm'))}>
                          {o.r}
                        </button>
                      ))}
                    </div>
                  </div>
                  {p && !p.presente && (
                    <Input defaultValue={p.justificacao ?? ''} disabled={!podeMarcar} placeholder="Justificação da ausência (opcional)" aria-label={`Justificação de ${nomeDe(m) ?? ''}`}
                      onBlur={(e) => { if ((e.target.value || null) !== (p.justificacao ?? null)) marcar(m, false, e.target.value) }} className="mt-2 h-8 text-xs" />
                  )}
                </li>
              )
            })}
          </ul>
          )}</Paginada>
        )}
      {podeMarcar && (
        <div className="grid gap-1.5 border-t px-4 py-3 sm:px-6">
          <span className="text-xs font-medium text-muted-foreground">Acrescentar participante (fora do conselho)</span>
          <CampoMembro valor={outro} excluir={pessoas} aoMudar={(v) => { setOutro(null); if (v) marcar(v, true) }} nomeDe={(i) => nomeDe(i) ?? undefined} vazio="Escolher membro…" />
        </div>
      )}
    </Cartao>
  )
}

/** Encerramento: hora e registo (oração final, próxima reunião). */
function Encerramento({ reuniao, fechada }: { reuniao: Reuniao; fechada: boolean }) {
  const mut = useReuniaoMut(reuniao.id)
  const [horaFim, setHoraFim] = useState(reuniao.encerradaEm ? hora(reuniao.encerradaEm) : '')
  const [texto, setTexto] = useState(reuniao.encerramento ?? '')
  const alterado = horaFim !== (reuniao.encerradaEm ? hora(reuniao.encerradaEm) : '') || texto !== (reuniao.encerramento ?? '')
  const guardar = () => {
    if (horaFim && !/^([01]\d|2[0-3]):[0-5]\d$/.test(horaFim)) return toast.error('Escreva a hora como 17:30.')
    mut.alterarReuniao.mutate({ encerradaEm: horaFim ? `${reuniao.data.slice(0, 10)}T${horaFim}:00+02:00` : null, encerramento: texto.trim() || null } as never,
      { onSuccess: () => toast.success('Encerramento guardado.'), onError: (e) => toast.error(mensagemDe(e)) })
  }
  return (
    <Cartao titulo="Encerramento" icone={Clock}>
      <div className="grid gap-3">
        <div className="grid gap-1.5">
          <label htmlFor="enc-hora" className="text-sm font-medium">Hora do encerramento</label>
          <Input id="enc-hora" type="time" value={horaFim} onChange={(e) => setHoraFim(e.target.value)} disabled={fechada} className="alvo num w-36" />
        </div>
        <div className="grid gap-1.5">
          <label htmlFor="enc-texto" className="text-sm font-medium">Registo</label>
          <Textarea id="enc-texto" rows={3} value={texto} onChange={(e) => setTexto(e.target.value)} disabled={fechada} placeholder="ex.: Oração final pelo ancião Alberto Macuácua; próxima reunião a 13/12." />
        </div>
        {!fechada && <Button size="sm" variant="outline" className="justify-self-end" disabled={!alterado || mut.alterarReuniao.isPending} onClick={guardar}>{mut.alterarReuniao.isPending ? t.comum.aGravar : t.comum.guardar}</Button>}
      </div>
    </Cartao>
  )
}

/** Acrescentar ou editar um ponto da agenda. */
function DialogoPonto({ reuniaoId, ponto, ordem, votos, aoFechar }: { reuniaoId: number; ponto: Ponto | null; ordem: number; votos: Voto[]; aoFechar: () => void }) {
  const mut = useReuniaoMut(reuniaoId)
  const { pode } = useSessao()
  const [assunto, setAssunto] = useState(ponto?.assunto ?? '')
  const [detalhes, setDetalhes] = useState(ponto?.detalhes ?? '')
  const [discutido, setDiscutido] = useState(ponto?.discutido ?? false)
  const [votado, setVotado] = useState(ponto?.votado ?? false)
  const [aFavor, setAFavor] = useState(ponto?.aFavor != null ? String(ponto.aFavor) : '')
  const [contra, setContra] = useState(ponto?.contra != null ? String(ponto.contra) : '')
  const [abst, setAbst] = useState(ponto?.abstencoes != null ? String(ponto.abstencoes) : '')
  const [estado, setEstado] = useState<EstadoPonto>(ponto?.estado ?? 'PENDENTE')
  const [deliberacao, setDeliberacao] = useState(ponto?.deliberacao ?? '')
  const [votoId, setVotoId] = useState(ponto?.votoId ? String(ponto.votoId) : '')
  const [erro, setErro] = useState<string | null>(null)
  const [retirar, setRetirar] = useState(false)
  const n = (x: string) => (x === '' ? null : Number(x))
  const submeter = async () => {
    setErro(null)
    if (!assunto.trim()) return setErro('Escreva o assunto.')
    if ([aFavor, contra, abst].some((x) => x !== '' && !/^\d+$/.test(x))) return setErro('Os votos são números inteiros.')
    try {
      await mut.gravarPonto.mutateAsync({
        id: ponto?.id, ordem: ponto?.ordem ?? ordem, assunto: assunto.trim(), detalhes: detalhes.trim() || null, discutido, votado,
        aFavor: votado ? n(aFavor) : null, contra: votado ? n(contra) : null, abstencoes: votado ? n(abst) : null,
        estado, deliberacao: deliberacao.trim() || null, votoId: votoId ? Number(votoId) : null,
      } as never)
      toast.success(ponto ? 'Ponto actualizado.' : 'Ponto acrescentado à agenda.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="max-h-[92dvh] overflow-y-auto sm:max-w-xl">
        <DialogHeader>
          <DialogTitle>{ponto ? `Ponto ${ponto.ordem}` : `Novo ponto (n.º ${ordem})`}</DialogTitle>
          <DialogDescription>O assunto, se foi discutido e votado, e o que se decidiu.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5"><label htmlFor="pt-ass" className="text-sm font-medium">Assunto <span className="text-destructive-text">*</span></label>
            <Input id="pt-ass" value={assunto} onChange={(e) => setAssunto(e.target.value)} maxLength={255} placeholder="ex.: Pintura da fachada do templo" className="alvo" autoFocus /></div>
          <div className="grid gap-1.5"><label htmlFor="pt-det" className="text-sm font-medium">Detalhes</label>
            <Textarea id="pt-det" rows={3} value={detalhes} onChange={(e) => setDetalhes(e.target.value)} placeholder="O que foi apresentado, propostas, valores…" /></div>
          <div className="grid gap-2 sm:grid-cols-2">
            <label className="alvo flex items-center gap-2 rounded-lg border px-3 py-2 text-sm"><input type="checkbox" checked={discutido} onChange={(e) => setDiscutido(e.target.checked)} className="size-4 accent-[var(--primary)]" />Foi discutido</label>
            <label className="alvo flex items-center gap-2 rounded-lg border px-3 py-2 text-sm"><input type="checkbox" checked={votado} onChange={(e) => setVotado(e.target.checked)} className="size-4 accent-[var(--primary)]" />Foi submetido à votação</label>
          </div>
          {votado && (
            <div className="grid grid-cols-3 gap-3 rounded-lg bg-muted/40 p-3">
              <div className="grid gap-1.5"><label htmlFor="pt-fav" className="text-xs font-medium">A favor</label><Input id="pt-fav" inputMode="numeric" value={aFavor} onChange={(e) => setAFavor(e.target.value)} className="alvo num" /></div>
              <div className="grid gap-1.5"><label htmlFor="pt-con" className="text-xs font-medium">Contra</label><Input id="pt-con" inputMode="numeric" value={contra} onChange={(e) => setContra(e.target.value)} className="alvo num" /></div>
              <div className="grid gap-1.5"><label htmlFor="pt-abs" className="text-xs font-medium">Abstenções</label><Input id="pt-abs" inputMode="numeric" value={abst} onChange={(e) => setAbst(e.target.value)} className="alvo num" /></div>
            </div>
          )}
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="grid gap-1.5"><label htmlFor="pt-est" className="text-sm font-medium">Resultado</label>
              <Seleccao id="pt-est" value={estado} onChange={(e) => setEstado(e.target.value as EstadoPonto)}>
                {(Object.keys(ESTADO_PONTO) as EstadoPonto[]).map((k) => <option key={k} value={k}>{ESTADO_PONTO[k].r}</option>)}
              </Seleccao></div>
            {votos.length > 0 && (
              <div className="grid gap-1.5"><label htmlFor="pt-vot" className="text-sm font-medium">Voto formal da acta</label>
                <Seleccao id="pt-vot" value={votoId} onChange={(e) => setVotoId(e.target.value)}>
                  <option value="">Nenhum</option>
                  {votos.map((v) => <option key={v.id} value={v.id}>{v.numero} · {v.assunto}</option>)}
                </Seleccao></div>
            )}
          </div>
          <div className="grid gap-1.5"><label htmlFor="pt-del" className="text-sm font-medium">Deliberação / decisão</label>
            <Textarea id="pt-del" rows={3} value={deliberacao} onChange={(e) => setDeliberacao(e.target.value)} placeholder="O que ficou decidido, quem faz o quê e até quando" /></div>
        </div>
        <DialogFooter className="gap-2 sm:justify-between">
          {ponto && pode('secretaria.reuniao_ponto.terminar')
            ? <Button variant="ghost" className="alvo text-destructive-text hover:text-destructive-text" onClick={() => setRetirar(true)}>Retirar da agenda</Button> : <span />}
          <div className="flex gap-2">
            <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
            <Button className="alvo" disabled={mut.gravarPonto.isPending} onClick={submeter}>{mut.gravarPonto.isPending ? t.comum.aGravar : ponto ? t.comum.guardar : 'Acrescentar'}</Button>
          </div>
        </DialogFooter>
        {ponto && (
          <DialogoConfirmar aberto={retirar} aoMudar={setRetirar} titulo="Retirar este ponto da agenda?" texto="Fica no histórico; deixa de aparecer na acta." accao="Retirar" perigo
            aCorrer={mut.retirarPonto.isPending}
            aoConfirmar={() => mut.retirarPonto.mutate(ponto.id, { onSuccess: () => { toast.success('Ponto retirado.'); setRetirar(false); aoFechar() }, onError: (e) => { toast.error(mensagemDe(e)); setRetirar(false) } })} />
        )}
      </DialogContent>
    </Dialog>
  )
}

/** Editar os dados da reunião (número, tipo, data, local, presidente, secretário). */
function DialogoEditarReuniao({ reuniao, aoFechar }: { reuniao: Reuniao; aoFechar: () => void }) {
  const mut = useReuniaoMut(reuniao.id)
  const conselho = useConselho()
  const basicos = useMembrosBasicos()
  const [numero, setNumero] = useState(reuniao.numero ?? '')
  const [tipo, setTipo] = useState<string>(reuniao.tipo)
  const [dia, setDia] = useState(reuniao.data.slice(0, 10))
  const [h, setH] = useState(hora(reuniao.data))
  const [local, setLocal] = useState(reuniao.local ?? '')
  const [pres, setPres] = useState<number | null>(reuniao.presididaPorMembroId ?? null)
  const [sec, setSec] = useState<number | null>(reuniao.secretarioMembroId ?? null)
  const [erro, setErro] = useState<string | null>(null)
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }
  const submeter = async () => {
    setErro(null)
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dia) || !/^([01]\d|2[0-3]):[0-5]\d$/.test(h)) return setErro('Escreva a data (dd/mm/aaaa) e a hora (10:00).')
    try {
      await mut.alterarReuniao.mutateAsync({ numero: numero.trim() || null, tipo, data: `${dia}T${h}:00+02:00`, local: local.trim() || null,
        presididaPorMembroId: pres, secretarioMembroId: sec } as never)
      toast.success('Reunião actualizada.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader><DialogTitle>Editar a reunião</DialogTitle><DialogDescription>Identificação da reunião, presidente e secretário(a).</DialogDescription></DialogHeader>
        <div className="grid gap-x-4 gap-y-3 sm:grid-cols-2">
          <div className="sm:col-span-2"><ErroFormulario mensagem={erro} /></div>
          <div className="grid gap-1.5"><label htmlFor="ed-num" className="text-sm font-medium">N.º da reunião</label><Input id="ed-num" value={numero} onChange={(e) => setNumero(e.target.value)} className="alvo num" /></div>
          <div className="grid gap-1.5"><label htmlFor="ed-tipo" className="text-sm font-medium">Tipo</label>
            <Seleccao id="ed-tipo" value={tipo} onChange={(e) => setTipo(e.target.value)}>{Object.entries(rotulos.tipoReuniao).map(([k, r]) => <option key={k} value={k}>{r}</option>)}</Seleccao></div>
          <div className="grid gap-1.5"><label htmlFor="ed-dia" className="text-sm font-medium">Data</label><CampoData id="ed-dia" value={dia} onChange={setDia} className="alvo" /></div>
          <div className="grid gap-1.5"><label htmlFor="ed-hora" className="text-sm font-medium">Hora</label><Input id="ed-hora" type="time" value={h} onChange={(e) => setH(e.target.value)} className="alvo num" /></div>
          <div className="grid gap-1.5 sm:col-span-2"><label htmlFor="ed-local" className="text-sm font-medium">Local</label><Input id="ed-local" value={local} onChange={(e) => setLocal(e.target.value)} className="alvo" /></div>
          <div className="grid gap-1.5"><label htmlFor="ed-pres" className="text-sm font-medium">Presidida por</label><EscolherDoConselho id="ed-pres" valor={pres} aoMudar={setPres} oficiais={conselho.data ?? []} nomeDe={nomeDe} /></div>
          <div className="grid gap-1.5"><label htmlFor="ed-sec" className="text-sm font-medium">Secretário(a)</label><EscolherDoConselho id="ed-sec" valor={sec} aoMudar={setSec} oficiais={conselho.data ?? []} nomeDe={nomeDe} /></div>
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={mut.alterarReuniao.isPending} onClick={submeter}>{mut.alterarReuniao.isPending ? t.comum.aGravar : t.comum.guardar}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
