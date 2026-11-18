/**
 * Editor da escala · "Quem serve em cada sábado, e falta alguém?"
 * Grelha como a escala em papel: um sábado por linha, as funções em colunas; um dia especial ocupa a linha inteira.
 *   - Culto Divino: apresentador, Sermão principal, tradutor, Sermão da criança, oração inicial e final, e o grupo coral;
 *     as outras funções (acompanhantes, diáconos…) escalam-se no diálogo do dia.
 *   - Escola Sabatina e JA (V45): as colunas que a igreja define ("Colunas da escala"), cada uma com um membro ou uma família.
 * Tocar numa célula escala, troca ou retira. Publicar torna-a visível aos membros (e activa os lembretes por SMS).
 * Imprimir dá a folha para afixar (A4 ao baixo), com as assinaturas.
 */
import { Marca } from '@/components/layout/Marca'
import { useMemo, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import {
  ArrowDown, ArrowLeft, ArrowUp, BellRing, CalendarDays, CalendarRange, CircleAlert, Columns3, Eye, EyeOff, Mic, MoreHorizontal, Music, Pencil, Plus,
  Printer, RefreshCw, Sparkles, Trash2, UserMinus,
} from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { Cartao, Indicador, Pilula } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { ListaMembros } from '@/components/comum/EscolherMembro'
import { CampoEscolha } from '@/components/comum/CampoEscolha'
import { Seleccao } from '@/components/comum/Seleccao'
import { ErroApi, mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { data, dataPorExtenso, hojeIso, qtd } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { useFamiliasResumo } from '@/features/secretaria/api'
import { EstadoPlano } from './PaginaEscalas'
import {
  COLUNAS, CURTO, FORA_DO_CULTO, TIPOS_ESCALA, useAlterarDia, useAlterarPlano, useColunas, useColunasMut, useDias, useEscalados, useEscalar,
  useGerarDias, usePlano, useRetirar, useTrocar, type Coluna, type Dia, type Escalado, type FuncaoEscala, type Plano, type TipoEscala,
} from './api'

/** Uma coluna da grelha: uma função do culto ou uma coluna da igreja (ES/JA). */
interface Col { chave: string; titulo: string; funcao: FuncaoEscala; coluna?: Coluna; destaque?: boolean }
interface Celula { dia: Dia; col: Col; escalado?: Escalado }

/* ---------------------------------------------------------------- escalar, trocar, retirar */
function DialogoCelula({ celula, plano, aoFechar, nomeDe }: { celula: Celula | null; plano: Plano; aoFechar: () => void; nomeDe: (e: Escalado) => string }) {
  const { pode } = useSessao()
  const familias = useFamiliasResumo()
  const escalar = useEscalar(plano.id)
  const trocar = useTrocar(plano.id)
  const retirar = useRetirar(plano.id)
  const aCorrer = escalar.isPending || trocar.isPending || retirar.isPending
  if (!celula) return null
  const { dia, col, escalado } = celula
  const porFamilia = col.coluna?.responsavel === 'FAMILIA'
  const podeMudar = escalado ? pode('actividades.escala.alterar') : pode('actividades.escala.criar')
  const feito = (msg: string) => () => { toast.success(msg); aoFechar() }
  const falhou = (e: unknown) => toast.error(mensagemDe(e))
  const base = { escalaDiaId: dia.id, funcao: col.funcao, escalaColunaId: col.coluna?.id }

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{col.coluna ? col.coluna.nome : rotulos.funcaoEscala[col.funcao]}</DialogTitle>
          <DialogDescription className="first-letter:uppercase">{dataPorExtenso(dia.data)}{porFamilia ? ' · uma família' : ''}</DialogDescription>
        </DialogHeader>
        {escalado && (
          <div className="flex items-center justify-between gap-3 rounded-lg bg-accent px-3 py-2.5">
            <div className="min-w-0">
              <p className="text-xs text-accent-foreground/80">Escalado</p>
              <p className="truncate font-semibold text-accent-foreground">{nomeDe(escalado)}</p>
            </div>
            {pode('actividades.escala.terminar') && (
              <Button variant="outline" size="sm" disabled={aCorrer} onClick={() => retirar.mutate(escalado.id, { onSuccess: feito('Retirado da escala.'), onError: falhou })}>
                <UserMinus className="size-4" /> Retirar
              </Button>
            )}
          </div>
        )}
        {!podeMudar ? <p className="text-sm text-muted-foreground">Não tem permissão para alterar a escala.</p>
          : porFamilia ? (
            <div className="grid gap-2">
              <p className="text-sm font-medium">{escalado ? 'Trocar pela família' : 'Escolher a família'}</p>
              <CampoEscolha valor="" vazio="Procurar a família…" pesquisar="Pesquisar família…" semOpcoes="Ainda não há famílias (Secretaria › Famílias)"
                opcoes={(familias.data ?? []).filter((f) => f.id !== escalado?.familiaId).map((f) => ({ valor: String(f.id), rotulo: f.nome }))}
                aoMudar={(v) => {
                  const f = familias.data?.find((x) => String(x.id) === v)
                  if (!f) return
                  if (escalado) trocar.mutate({ id: escalado.id, familiaId: f.id }, { onSuccess: feito(`${f.nome} fica escalada.`), onError: falhou })
                  else escalar.mutate({ ...base, familiaId: f.id }, { onSuccess: feito(`${f.nome} escalada.`), onError: falhou })
                }} />
            </div>
          ) : (
            <div className="grid gap-2">
              <p className="text-sm font-medium">{escalado ? 'Trocar por' : 'Escolher quem'}</p>
              <ListaMembros
                excluir={escalado?.membroId ? [escalado.membroId] : []}
                aoEscolher={(m) => escalado
                  ? trocar.mutate({ id: escalado.id, membroId: m.id }, { onSuccess: feito(`${m.nome} ${m.apelido} fica escalado(a).`), onError: falhou })
                  : escalar.mutate({ ...base, membroId: m.id }, { onSuccess: feito(`${m.nome} ${m.apelido} escalado(a).`), onError: falhou })}
              />
            </div>
          )}
      </DialogContent>
    </Dialog>
  )
}

/* ---------------------------------------------------------------- dia: evento, grupo coral, observações e outras funções (culto) */
const esquemaDia = z.object({ evento: z.string().trim().max(150), grupoCoral: z.string().trim().max(100), observacoes: z.string().trim().max(255) })

function DialogoDia({ dia, plano, aoFechar, outros, nomeDe }: { dia: Dia | null; plano: Plano; aoFechar: () => void; outros: Escalado[]; nomeDe: (e: Escalado) => string }) {
  const alterar = useAlterarDia(plano.id)
  const { pode } = useSessao()
  const escalar = useEscalar(plano.id)
  const retirar = useRetirar(plano.id)
  const [erro, setErro] = useState<string | null>(null)
  const [outraFuncao, setOutraFuncao] = useState<FuncaoEscala>('ACOMPANHANTE_BOAS_VINDAS')
  const culto = (plano.tipo ?? 'CULTO') === 'CULTO'
  const form = useForm({ resolver: zodResolver(esquemaDia), values: { evento: dia?.evento ?? '', grupoCoral: dia?.grupoCoral ?? '', observacoes: dia?.observacoes ?? '' } })
  if (!dia) return null
  const funcoesSemColuna = (Object.keys(rotulos.funcaoEscala) as FuncaoEscala[]).filter((f) => !COLUNAS.includes(f) && !FORA_DO_CULTO.includes(f))
  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    try {
      await alterar.mutateAsync({ id: dia.id, corpo: { evento: v.evento || null, grupoCoral: v.grupoCoral || null, observacoes: v.observacoes || null } as never })
      toast.success('Dia actualizado.')
      aoFechar()
    } catch (e) {
      setErro(aplicarErroApi(form, e))
    }
  })
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="max-h-[92dvh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle className="first-letter:uppercase">{dataPorExtenso(dia.data)}</DialogTitle>
          <DialogDescription>Substitui a escala desse sábado.</DialogDescription>
        </DialogHeader>
        <form onSubmit={submeter} noValidate className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <CampoFormulario rotulo="Dia especial" ajuda="ex.: Simpósio da Teologia, 13.º sábado, Santa Ceia" erro={form.formState.errors.evento?.message}>
            {(p) => <Input {...p} {...form.register('evento')} className="alvo" />}
          </CampoFormulario>
          {culto && (
            <CampoFormulario rotulo="Grupo coral" ajuda="ex.: MA, Coro Jovem" erro={form.formState.errors.grupoCoral?.message}>
              {(p) => <Input {...p} {...form.register('grupoCoral')} className="alvo" />}
            </CampoFormulario>
          )}
          <CampoFormulario rotulo="Observações" erro={form.formState.errors.observacoes?.message}>
            {(p) => <Textarea {...p} {...form.register('observacoes')} rows={2} />}
          </CampoFormulario>
          {culto && (
            <div className="grid gap-2 rounded-lg border p-3 text-sm">
              <p className="font-medium">Outras funções neste dia <span className="font-normal text-muted-foreground">(acompanhantes, diáconos, recepção…)</span></p>
              {outros.length > 0 && (
                <ul className="grid gap-1 text-muted-foreground">
                  {outros.map((o) => (
                    <li key={o.id} className="flex items-center justify-between gap-2">
                      <span>{rotulos.funcaoEscala[o.funcao]}: <span className="text-foreground">{nomeDe(o)}</span></span>
                      {pode('actividades.escala.terminar') && (
                        <Button type="button" variant="ghost" size="sm" disabled={retirar.isPending} aria-label={`Retirar ${nomeDe(o)}`}
                          onClick={() => retirar.mutate(o.id, { onSuccess: () => toast.success('Retirado da escala.'), onError: (e) => toast.error(mensagemDe(e)) })}>
                          <UserMinus className="size-4" />
                        </Button>
                      )}
                    </li>
                  ))}
                </ul>
              )}
              {pode('actividades.escala.criar') && (
                <div className="grid gap-2">
                  <Seleccao aria-label="Função a escalar" value={outraFuncao} onChange={(e) => setOutraFuncao(e.target.value as FuncaoEscala)}>
                    {funcoesSemColuna.map((f) => <option key={f} value={f}>{rotulos.funcaoEscala[f]}</option>)}
                  </Seleccao>
                  <ListaMembros aoEscolher={(m) => escalar.mutate({ escalaDiaId: dia.id, funcao: outraFuncao, membroId: m.id }, {
                    onSuccess: () => toast.success(`${m.nome} ${m.apelido} escalado(a) como ${rotulos.funcaoEscala[outraFuncao].toLowerCase()}.`),
                    onError: (e) => toast.error(mensagemDe(e)),
                  })} />
                </div>
              )}
            </div>
          )}
          <DialogFooter>
            <Button type="button" variant="outline" onClick={aoFechar}>{t.comum.cancelar}</Button>
            <Button type="submit" disabled={form.formState.isSubmitting}>{form.formState.isSubmitting ? t.comum.aGravar : t.comum.guardar}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

/* ---------------------------------------------------------------- colunas da escala da ES/JA (cada igreja define as suas) */
function DialogoColunas({ tipo, colunas, aoFechar }: { tipo: TipoEscala; colunas: Coluna[]; aoFechar: () => void }) {
  const { gravar, tirar } = useColunasMut()
  const { pode } = useSessao()
  const [nome, setNome] = useState('')
  const [responsavel, setResponsavel] = useState<'MEMBRO' | 'FAMILIA'>('MEMBRO')
  const falhou = (e: unknown) => toast.error(mensagemDe(e))
  const mover = (c: Coluna, d: -1 | 1) => {
    const i = colunas.findIndex((x) => x.id === c.id)
    const outra = colunas[i + d]
    if (!outra) return
    gravar.mutate({ id: c.id, ordem: outra.ordem }, { onError: falhou })
    gravar.mutate({ id: outra.id, ordem: c.ordem === outra.ordem ? c.ordem - d : c.ordem }, { onError: falhou })
  }
  const acrescentar = () => {
    if (!nome.trim()) return toast.error('Escreva o nome da coluna (ex.: Apresentador).')
    gravar.mutate({ tipo, nome: nome.trim(), responsavel, ordem: Math.max(0, ...colunas.map((c) => c.ordem)) + 1 }, {
      onSuccess: () => { setNome(''); toast.success('Coluna acrescentada.') }, onError: falhou,
    })
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="max-h-[92dvh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Colunas da escala da {TIPOS_ESCALA[tipo]}</DialogTitle>
          <DialogDescription>Cada igreja organiza a sua: o nome de cada coluna e se nela se escala um membro ou uma família. Valem para todas as escalas da {TIPOS_ESCALA[tipo]} desta igreja.</DialogDescription>
        </DialogHeader>
        <ul className="grid gap-2">
          {colunas.length === 0 && <li className="rounded-lg border border-dashed p-3 text-sm text-muted-foreground">Ainda sem colunas. Acrescente, por exemplo: Apresentador, Oração, Carta missionária.</li>}
          {colunas.map((c, i) => (
            <li key={c.id} className="flex items-center gap-2 rounded-lg border px-3 py-2 text-sm">
              <span className="min-w-0 flex-1"><span className="font-medium">{c.nome}</span> <span className="text-xs text-muted-foreground">· {c.responsavel === 'FAMILIA' ? 'uma família' : 'um membro'}</span></span>
              {pode('actividades.escala_coluna.alterar') && (
                <>
                  <Button type="button" variant="ghost" size="icon" className="size-8" disabled={i === 0 || gravar.isPending} aria-label={`Subir ${c.nome}`} onClick={() => mover(c, -1)}><ArrowUp className="size-4" /></Button>
                  <Button type="button" variant="ghost" size="icon" className="size-8" disabled={i === colunas.length - 1 || gravar.isPending} aria-label={`Descer ${c.nome}`} onClick={() => mover(c, 1)}><ArrowDown className="size-4" /></Button>
                </>
              )}
              {pode('actividades.escala_coluna.terminar') && (
                <Button type="button" variant="ghost" size="icon" className="size-8" disabled={tirar.isPending} aria-label={`Retirar ${c.nome}`}
                  onClick={() => tirar.mutate(c.id, { onSuccess: () => toast.success('Coluna retirada (o que já estava escalado fica no histórico).'), onError: falhou })}>
                  <Trash2 className="size-4" />
                </Button>
              )}
            </li>
          ))}
        </ul>
        {pode('actividades.escala_coluna.criar') && (
          <div className="grid gap-2 rounded-lg bg-muted/40 p-3 sm:grid-cols-[1fr_9rem_auto]">
            <Input aria-label="Nome da coluna" value={nome} onChange={(e) => setNome(e.target.value)} maxLength={80} placeholder="ex.: Apresentador" className="alvo" />
            <Seleccao aria-label="Quem se escala" value={responsavel} onChange={(e) => setResponsavel(e.target.value as 'MEMBRO' | 'FAMILIA')}>
              <option value="MEMBRO">Um membro</option><option value="FAMILIA">Uma família</option>
            </Seleccao>
            <Button type="button" className="alvo" disabled={gravar.isPending} onClick={acrescentar}><Plus className="size-4" />Acrescentar</Button>
          </div>
        )}
        <DialogFooter><Button type="button" variant="outline" onClick={aoFechar}>Fechar</Button></DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/* ---------------------------------------------------------------- uma célula da grelha */
function BotaoCelula({ nome, aoClicar, pode, destaque }: { nome?: string; aoClicar: () => void; pode: boolean; destaque?: boolean }) {
  if (!nome && !pode) return <span className="text-muted-foreground">—</span>
  return (
    <button type="button" onClick={aoClicar} aria-label={nome ? undefined : 'Escalar'}
      className={cn('group alvo -mx-2 flex min-h-9 w-[calc(100%+1rem)] items-center rounded-md px-2 text-left text-sm transition-colors hover:bg-accent hover:text-accent-foreground',
        nome ? (destaque ? 'font-semibold' : 'font-medium') : 'text-muted-foreground/40 print:hidden')}>
      {nome ?? (
        // vazio: só um "+" discreto; a palavra aparece ao passar o rato ou com o teclado (a grelha fica limpa)
        <span className="inline-flex items-center gap-1.5 group-hover:text-foreground group-focus-visible:text-foreground">
          <Plus className="size-3.5" /><span className="opacity-0 transition-opacity group-hover:opacity-100 group-focus-visible:opacity-100">Escalar</span>
        </span>
      )}
    </button>
  )
}

export default function PaginaEscala() {
  const id = Number(useParams().id)
  const igreja = useIgreja()
  const { pode } = useSessao()
  const plano = usePlano(id)
  const dias = useDias(id)
  const escalados = useEscalados(plano.data)
  const basicos = useMembrosBasicos()
  const familias = useFamiliasResumo()
  const tipo: TipoEscala = plano.data?.tipo ?? 'CULTO'
  const colunasIgreja = useColunas(plano.data ? tipo : undefined)
  const alterarPlano = useAlterarPlano(id)
  const gerar = useGerarDias(id)
  const [celula, setCelula] = useState<Celula | null>(null)
  const [diaAberto, setDiaAberto] = useState<Dia | null>(null)
  const [verColunas, setVerColunas] = useState(false)
  const [confirmarPublicar, setConfirmarPublicar] = useState(false)

  const nomes = useMemo(() => new Map((basicos.data ?? []).map((m) => [m.id, `${m.nome} ${m.apelido}`])), [basicos.data])
  const nomeFamilia = (fid?: number | null) => (fid ? familias.data?.find((f) => f.id === fid)?.nome : undefined)
  const nomeDe = (e: Escalado) => (e.familiaId ? nomeFamilia(e.familiaId) : e.membroId ? nomes.get(e.membroId) : undefined) ?? '—'
  const porDia = useMemo(() => {
    const mapa = new Map<number, Escalado[]>()
    for (const e of escalados.data ?? []) mapa.set(e.escalaDiaId!, [...(mapa.get(e.escalaDiaId!) ?? []), e])
    return mapa
  }, [escalados.data])

  if (plano.isPending) return <div className="grid gap-4" aria-busy="true" aria-label="A carregar"><Barra className="h-8 w-72" /><Barra className="h-96 w-full" /></div>
  if (plano.isError) {
    return plano.error instanceof ErroApi && plano.error.naoEncontrado
      ? <div className="rounded-xl border bg-card shadow-card"><EstadoVazio icone={CalendarDays} titulo="Escala não encontrada">Esta escala não existe ou não é desta igreja.</EstadoVazio></div>
      : <EstadoErro erro={plano.error} aoTentar={() => plano.refetch()} />
  }
  const p = plano.data
  const culto = tipo === 'CULTO'
  const cols: Col[] = culto
    ? COLUNAS.map((f) => ({ chave: f, titulo: CURTO[f], funcao: f, destaque: f === 'PREGADOR' }))
    : (colunasIgreja.data ?? []).map((c) => ({ chave: `c${c.id}`, titulo: c.nome, funcao: 'OUTRA' as FuncaoEscala, coluna: c }))
  const daCelula = (doDia: Escalado[], c: Col) => doDia.find((x) => (c.coluna ? x.escalaColunaId === c.coluna.id : x.funcao === c.funcao && !x.escalaColunaId))
  const lista = dias.data ?? []
  const normais = lista.filter((d) => !d.evento)
  const comPregador = normais.filter((d) => porDia.get(d.id)?.some((e) => e.funcao === 'PREGADOR')).length
  const porPreencher = normais.reduce((s, d) => s + cols.filter((c) => !daCelula(porDia.get(d.id) ?? [], c)).length, 0)
  const podeDia = pode('actividades.escala_dia.alterar')
  const podeCriar = pode('actividades.escala.criar')
  const hoje = hojeIso()
  const proximo = lista.find((d) => d.data >= hoje)?.id
  const semColunas = !culto && colunasIgreja.isSuccess && cols.length === 0

  const abrir = (dia: Dia, col: Col) => setCelula({ dia, col, escalado: daCelula(porDia.get(dia.id) ?? [], col) })
  const publicar = (v: boolean) => alterarPlano.mutate({ publicada: v } as never, {
    onSuccess: () => { toast.success(v ? 'Escala publicada: os membros já a vêem e os escalados recebem os lembretes.' : 'Publicação retirada.'); setConfirmarPublicar(false) },
    onError: (e) => toast.error(mensagemDe(e)),
  })

  return (
    <>
      {/* a grelha pode ter muitas colunas: imprime-se ao baixo */}
      <style>{'@media print { @page { size: A4 landscape; margin: 10mm; } }'}</style>
      {/* cabeçalho da folha impressa */}
      <div className="mb-6 hidden text-center print:block">
        <Marca className="mx-auto mb-2 size-12" />
        <p className="text-sm">Igreja Adventista do Sétimo Dia · {igreja.nome}</p>
        <h1 className="mt-1 text-xl font-bold">{p.titulo}</h1>
        <p className="text-sm">{TIPOS_ESCALA[tipo]} · {data(p.dataInicio)} a {data(p.dataFim)}</p>
      </div>

      <div className="print:hidden">
        <Link to="/escalas" className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" /> {t.escalas.titulo}
        </Link>
        <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div className="flex min-w-0 items-start gap-3">
            <span className="flex size-10 flex-none items-center justify-center rounded-lg bg-primary/10 text-primary" aria-hidden><CalendarRange className="size-5" /></span>
            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-2"><h1 className="text-2xl font-semibold tracking-tight">{p.titulo}</h1><Pilula variante="secondary">{TIPOS_ESCALA[tipo]}</Pilula><EstadoPlano p={p} /></div>
              <p className="mt-1 text-sm text-muted-foreground">{data(p.dataInicio)} a {data(p.dataFim)} · {lista.length} sábados</p>
            </div>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {!culto && pode('actividades.escala_coluna.ler') && <Button variant="outline" className="alvo" onClick={() => setVerColunas(true)}><Columns3 className="size-4" /> Colunas da escala</Button>}
            <Button variant="outline" className="alvo" onClick={() => window.print()}><Printer className="size-4" /> Imprimir</Button>
            {pode('actividades.escala_plano.alterar') && (p.publicada
              ? <Button variant="outline" className="alvo" onClick={() => publicar(false)} disabled={alterarPlano.isPending}><EyeOff className="size-4" /> Retirar publicação</Button>
              : <Button className="alvo" onClick={() => setConfirmarPublicar(true)}><Eye className="size-4" /> Publicar</Button>)}
            {pode('actividades.escala_dia.criar') && (
              <DropdownMenu>
                <DropdownMenuTrigger asChild><Button variant="outline" size="icon" aria-label="Mais acções" className="alvo"><MoreHorizontal className="size-4" /></Button></DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem disabled={gerar.isPending}
                    onSelect={() => gerar.mutate(undefined, { onSuccess: (r) => toast.success(`${qtd((r as { criados: number }).criados, 'sábado(s) acrescentado(s)')}.`), onError: (e) => toast.error(mensagemDe(e)) })}>
                    <RefreshCw className="size-4" /> Acrescentar sábados em falta
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            )}
          </div>
        </div>

        <div className="mb-6 grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-4">
          <Indicador rotulo="Sábados" valor={lista.length} nota={`${qtd(lista.length - normais.length, 'dia(s) especial(is)')}`} icone={CalendarDays} aCarregar={dias.isPending} />
          {culto
            ? <Indicador rotulo="Sermão principal" valor={`${comPregador}/${normais.length}`} nota="sábados com quem prega" icone={Mic} tom="success" aCarregar={dias.isPending || escalados.isPending} />
            : <Indicador rotulo="Colunas" valor={cols.length} nota={`definidas pela igreja para a ${TIPOS_ESCALA[tipo]}`} icone={Columns3} aCarregar={colunasIgreja.isPending} />}
          <Indicador rotulo="Por preencher" valor={porPreencher} nota="lugares ainda sem ninguém" icone={CircleAlert} tom={porPreencher ? 'warning' : 'success'} aCarregar={dias.isPending || escalados.isPending} />
          <Indicador rotulo="Lembretes" valor={p.publicada ? 'Activos' : 'Parados'} nota={p.publicada ? 'SMS à quarta e à sexta, 18:00' : 'publique para enviar os SMS'} icone={BellRing} tom={p.publicada ? 'info' : 'warning'} />
        </div>
      </div>

      <Cartao titulo="Escala" descricao="Toque numa célula para escalar ou trocar" icone={CalendarRange} semMargem className="print:border-0 print:shadow-none [&>header]:print:hidden">
        {dias.isPending || escalados.isPending || (!culto && colunasIgreja.isPending) ? <div className="grid gap-2 px-6 pb-6">{[0, 1, 2, 3, 4].map((i) => <Barra key={i} className="h-10 w-full" />)}</div>
          : dias.isError ? <EstadoErro erro={dias.error} aoTentar={() => dias.refetch()} className="mx-6 mb-6" />
          : escalados.isError ? <EstadoErro erro={escalados.error} aoTentar={() => escalados.refetch()} className="mx-6 mb-6" />
          : semColunas ? (
            <EstadoVazio icone={Columns3} titulo={`Defina as colunas da escala da ${TIPOS_ESCALA[tipo]}`}
              accao={pode('actividades.escala_coluna.criar') && <Button variant="outline" className="alvo" onClick={() => setVerColunas(true)}>Definir as colunas</Button>}>
              Cada igreja organiza a sua escala: por exemplo, Apresentador, Oração, Carta missionária (um membro) ou Família da programação (uma família).
            </EstadoVazio>
          )
          : lista.length === 0 ? <EstadoVazio icone={CalendarDays} titulo="Sem sábados">Use "Acrescentar sábados em falta" no menu de acções.</EstadoVazio>
          : (
            <>
              {/* computador e impressão: a grelha */}
              <div className="hidden overflow-x-auto lg:block print:block">
                <table className="w-full border-collapse text-sm">
                  <thead>
                    <tr className="border-b">
                      <th className="h-10 bg-muted/50 px-4 text-left text-xs font-medium text-muted-foreground sm:pl-6">Data</th>
                      {cols.map((c) => <th key={c.chave} className="h-10 bg-muted/50 px-4 text-left text-xs font-medium text-muted-foreground">{c.titulo}</th>)}
                      {culto && <th className="h-10 bg-muted/50 px-4 text-left text-xs font-medium text-muted-foreground sm:pr-6">Grupo coral</th>}
                    </tr>
                  </thead>
                  <tbody>
                    {lista.map((d) => {
                      const doDia = porDia.get(d.id) ?? []
                      return (
                        <tr key={d.id} className={cn('border-t', d.id === proximo && 'bg-accent/40')}>
                          <td className="px-4 py-2 whitespace-nowrap sm:pl-6">
                            <button type="button" disabled={!podeDia} onClick={() => setDiaAberto(d)}
                              className="alvo group -mx-2 flex items-center gap-2 rounded-md px-2 py-1 text-left enabled:hover:bg-accent">
                              <span className="num font-semibold">{data(d.data).slice(0, 5)}</span>
                              {d.id === proximo && <Pilula variante="info" className="print:hidden">Próximo</Pilula>}
                              {podeDia && <Pencil className="size-3 text-muted-foreground opacity-0 group-hover:opacity-100 print:hidden" />}
                            </button>
                          </td>
                          {d.evento ? (
                            <td colSpan={cols.length} className="px-4 py-2">
                              <span className="inline-flex items-center gap-2 font-semibold text-accent-foreground"><Sparkles className="size-4 print:hidden" />{d.evento}</span>
                            </td>
                          ) : cols.map((c) => {
                            const e = daCelula(doDia, c)
                            return (
                              <td key={c.chave} className="px-4 py-2">
                                <BotaoCelula nome={e && nomeDe(e)} destaque={c.destaque} pode={podeCriar} aoClicar={() => abrir(d, c)} />
                              </td>
                            )
                          })}
                          {culto && (
                            <td className="px-4 py-2 sm:pr-6">
                              <button type="button" disabled={!podeDia} onClick={() => setDiaAberto(d)} aria-label={d.grupoCoral ? undefined : 'Indicar o grupo coral'}
                                className="group alvo -mx-2 flex min-h-9 items-center rounded-md px-2 text-left enabled:hover:bg-accent">
                                {d.grupoCoral ?? (podeDia
                                  ? <span className="inline-flex items-center gap-1.5 text-muted-foreground/40 group-hover:text-foreground print:hidden"><Plus className="size-3.5" /><span className="opacity-0 transition-opacity group-hover:opacity-100">Grupo</span></span>
                                  : <span className="text-muted-foreground">—</span>)}
                              </button>
                            </td>
                          )}
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>

              {/* telemóvel e tablet: um cartão por sábado */}
              <ul className="grid gap-3 px-4 pb-4 lg:hidden print:hidden">
                {lista.map((d) => {
                  const doDia = porDia.get(d.id) ?? []
                  return (
                    <li key={d.id} className={cn('rounded-lg border p-3', d.id === proximo && 'border-primary/40 bg-accent/40')}>
                      <div className="mb-2 flex items-center justify-between gap-2">
                        <p className="font-semibold first-letter:uppercase">{dataPorExtenso(d.data)}</p>
                        {podeDia && <Button variant="ghost" size="icon" aria-label="Editar o dia" className="size-9" onClick={() => setDiaAberto(d)}><Pencil className="size-4" /></Button>}
                      </div>
                      {d.evento ? <p className="flex items-center gap-2 font-medium text-accent-foreground"><Sparkles className="size-4" />{d.evento}</p> : (
                        <dl className="grid gap-0.5">
                          {cols.map((c) => {
                            const e = daCelula(doDia, c)
                            return (
                              <div key={c.chave} className="flex items-center justify-between gap-3">
                                <dt className="text-sm text-muted-foreground">{c.titulo}</dt>
                                <dd className="min-w-0 max-w-[60%] text-right">
                                  <BotaoCelula nome={e && nomeDe(e)} destaque={c.destaque} pode={podeCriar} aoClicar={() => abrir(d, c)} />
                                </dd>
                              </div>
                            )
                          })}
                        </dl>
                      )}
                      {culto && d.grupoCoral && <p className="mt-2 flex items-center gap-1.5 text-sm text-muted-foreground"><Music className="size-3.5" />{d.grupoCoral}</p>}
                    </li>
                  )
                })}
              </ul>
            </>
          )}
      </Cartao>

      {/* rodapé da folha impressa: local, data e assinaturas */}
      <div className="mt-10 hidden print:block">
        <p className="text-sm">{p.localEmissao ?? '__________'}, {p.dataEmissao ? data(p.dataEmissao) : '___/___/______'}</p>
        <div className="mt-12 grid grid-cols-2 gap-16 text-center text-sm">
          <div><div className="border-t border-black pt-1">O Ancião</div><p>{p.anciaoMembroId ? nomes.get(p.anciaoMembroId) ?? '' : ''}</p></div>
          <div><div className="border-t border-black pt-1">O(A) Secretário(a)</div><p>{p.secretarioMembroId ? nomes.get(p.secretarioMembroId) ?? '' : ''}</p></div>
        </div>
      </div>

      <DialogoCelula celula={celula} plano={p} aoFechar={() => setCelula(null)} nomeDe={nomeDe} />
      <DialogoDia dia={diaAberto} plano={p} aoFechar={() => setDiaAberto(null)} nomeDe={nomeDe}
        outros={(diaAberto && porDia.get(diaAberto.id)?.filter((e) => !e.escalaColunaId && !COLUNAS.includes(e.funcao))) || []} />
      {verColunas && !culto && <DialogoColunas tipo={tipo} colunas={colunasIgreja.data ?? []} aoFechar={() => setVerColunas(false)} />}
      <DialogoConfirmar
        aberto={confirmarPublicar} aoMudar={setConfirmarPublicar} titulo="Publicar a escala?"
        texto="Os membros da igreja passam a vê-la e, a partir de agora, quem está escalado recebe um SMS à quarta e à sexta antes do seu sábado (se tiver telefone e consentimento)."
        accao="Publicar" aCorrer={alterarPlano.isPending} aoConfirmar={() => publicar(true)}
      />
    </>
  )
}
