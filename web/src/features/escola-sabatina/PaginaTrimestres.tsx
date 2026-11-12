/**
 * Trimestres e sábados (F-ES-01) e pesos da pontuação (F-ES-07) · tabelas comuns da Associação/Missão.
 * Novo trimestre: o período gera um sábado por semana (13 ou 14; a base de dados recusa outro número) com o
 * 13.º sábado marcado (por defeito, o último). As igrejas só lêem.
 */
import { useState } from 'react'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { CalendarRange, ChevronDown, Plus, Scale, Star } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Pilula, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { Seleccao } from '@/components/comum/Seleccao'
import { useSessao } from '@/auth/sessao'
import { mensagemDe } from '@/api/erros'
import { t } from '@/i18n/pt-MZ'
import { data, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import {
  nomeTrimestre, sabadosEntre, trimestreActual, useCriarSabadosEmFalta, useCriarTrimestre, useGravarPesos, useMarcar13, usePesos, useSabados, useTrimestres,
  type PesosPontuacao, type Trimestre,
} from './api'

export default function PaginaTrimestres() {
  const { pode } = useSessao()
  const q = useTrimestres()
  const [novo, setNovo] = useState(false)
  const actual = trimestreActual(q.data ?? [])
  const [aberto, setAberto] = useState<number | null>(null)
  const expandido = aberto ?? actual?.id ?? null

  return (
    <>
      <TituloPagina
        icone={CalendarRange}
        titulo={t.es.trimestres}
        descricao="Calendário da lição: trimestres, sábados e o sábado da oferta do 13.º sábado (definidos pela Associação)"
        accoes={pode('escola_sabatina.trimestre.criar') && <Button className="alvo" onClick={() => setNovo(true)}><Plus className="size-4" />Novo trimestre</Button>}
      />
      <div className="grid gap-6 lg:grid-cols-12">
        <Cartao className="lg:col-span-8" titulo="Trimestres" semMargem>
          {q.isPending ? <LinhasACarregar linhas={4} />
            : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="mx-6 mb-6" />
            : !q.data.length ? (
              <EstadoVazio icone={CalendarRange} titulo="Ainda não há trimestres"
                accao={pode('escola_sabatina.trimestre.criar') && <Button size="sm" onClick={() => setNovo(true)}><Plus className="size-4" />Novo trimestre</Button>}>
                {pode('escola_sabatina.trimestre.criar') ? 'Crie o trimestre da lição: os sábados são gerados automaticamente.' : 'A Associação ainda não criou os trimestres da lição.'}
              </EstadoVazio>
            ) : (
              <ul className="divide-y border-t">
                {q.data.map((tr) => (
                  <li key={tr.id}>
                    <button type="button" aria-expanded={expandido === tr.id} onClick={() => setAberto(expandido === tr.id ? -1 : tr.id)}
                      className="alvo flex w-full items-center gap-3 px-5 py-3 text-left hover:bg-muted/50 sm:px-6">
                      <span className="min-w-0 flex-1">
                        <span className="flex flex-wrap items-center gap-2 font-medium">{nomeTrimestre(tr)}{tr.id === actual?.id && <Pilula variante="info">Actual</Pilula>}</span>
                        <span className="block truncate text-xs text-muted-foreground">{data(tr.dataInicio)} – {data(tr.dataFim)} · {tr.numSabados} sábados{tr.temaLicao ? ` · ${tr.temaLicao}` : ''}</span>
                      </span>
                      <ChevronDown aria-hidden className={cn('size-4 text-muted-foreground transition-transform', expandido === tr.id && 'rotate-180')} />
                    </button>
                    {expandido === tr.id && <Sabados trimestre={tr} />}
                  </li>
                ))}
              </ul>
            )}
        </Cartao>
        <div className="lg:col-span-4">
          <Pesos trimestre={actual} />
        </div>
      </div>
      {novo && <DialogoTrimestre existentes={q.data ?? []} aoFechar={() => setNovo(false)} />}
    </>
  )
}

function Sabados({ trimestre }: { trimestre: Trimestre }) {
  const { pode } = useSessao()
  const q = useSabados(trimestre.id)
  const marcar = useMarcar13()
  const criarFalta = useCriarSabadosEmFalta()
  const anterior = q.data?.find((s) => s.decimoTerceiro)
  const podeMarcar = pode('escola_sabatina.sabado.alterar')
  if (q.isPending) return <LinhasACarregar linhas={3} />
  if (q.isError) return <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="mx-6 mb-4" />
  const emFalta = sabadosEntre(trimestre.dataInicio, trimestre.dataFim).length - q.data.length
  return (
    <>
    {emFalta > 0 && (
      <div className="flex flex-wrap items-center gap-3 bg-tint-warning px-5 py-3 text-sm text-warning-text sm:px-6">
        <p className="flex-1">Faltam {emFalta} sábado(s) neste trimestre.</p>
        {pode('escola_sabatina.sabado.criar') && (
          <Button size="sm" variant="outline" disabled={criarFalta.isPending}
            onClick={() => criarFalta.mutate({ trimestre, existentes: q.data }, { onSuccess: () => toast.success('Sábados criados.'), onError: (e) => toast.error(mensagemDe(e)) })}>
            {criarFalta.isPending ? 'A criar…' : 'Criar os que faltam'}
          </Button>
        )}
      </div>
    )}
    <ol className="grid grid-cols-2 gap-2 bg-muted/30 px-5 py-4 sm:grid-cols-4 sm:px-6">
      {q.data.map((s) => (
        <li key={s.id} className={cn('flex items-center justify-between gap-2 rounded-lg border bg-card px-3 py-2 text-sm', s.decimoTerceiro && 'border-warning/50 bg-tint-warning')}>
          <span><span className="block text-xs text-muted-foreground">{s.numero}.º sábado</span><span className="font-medium tabular-nums">{data(s.data)}</span></span>
          {s.decimoTerceiro ? <Star className="size-4 fill-current text-warning-text" aria-label="13.º sábado" />
            : podeMarcar && (
              <button type="button" className="alvo text-muted-foreground hover:text-warning-text" aria-label={`Marcar ${data(s.data)} como 13.º sábado`}
                disabled={marcar.isPending}
                onClick={() => marcar.mutate({ anterior: anterior?.id, novo: s.id }, { onSuccess: () => toast.success('13.º sábado alterado.'), onError: (e) => toast.error(mensagemDe(e)) })}>
                <Star className="size-4" />
              </button>
            )}
        </li>
      ))}
    </ol>
    </>
  )
}

const dataIso = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Escreva a data como dd/mm/aaaa')
const esquema = z.object({
  ano: z.coerce.number().int().min(2000, 'Ano inválido').max(2100, 'Ano inválido'),
  numero: z.coerce.number().int().min(1).max(4),
  temaLicao: z.string().trim().max(200),
  dataInicio: dataIso,
  dataFim: dataIso,
  decimoTerceiro: z.string(),
}).refine((v) => v.dataFim > v.dataInicio, { path: ['dataFim'], message: 'O fim tem de ser depois do início' })
type Valores = z.infer<typeof esquema>

/** Início (o primeiro sábado do trimestre civil) e fim (o último dia) do trimestre n do ano. */
function periodoCivil(ano: number, n: number) {
  const pad = (x: number) => String(x).padStart(2, '0')
  const mi = (n - 1) * 3 + 1, mf = mi + 2
  return { inicio: `${ano}-${pad(mi)}-01`, fim: `${ano}-${pad(mf)}-${new Date(Date.UTC(ano, mf, 0)).getUTCDate()}` }
}

function DialogoTrimestre({ existentes, aoFechar }: { existentes: Trimestre[]; aoFechar: () => void }) {
  const criar = useCriarTrimestre()
  const [erro, setErro] = useState<string | null>(null)
  const [ano0, mes0] = hojeIso().split('-').map(Number)
  // sugere o trimestre seguinte ao último criado (ou o actual)
  const ultimo = [...existentes].sort((a, b) => b.dataInicio.localeCompare(a.dataInicio))[0]
  const sug = ultimo ? (ultimo.numero === 4 ? { ano: ultimo.ano + 1, n: 1 } : { ano: ultimo.ano, n: ultimo.numero + 1 }) : { ano: ano0, n: Math.floor((mes0 - 1) / 3) + 1 }
  const p0 = periodoCivil(sug.ano, sug.n)
  const s0 = sabadosEntre(p0.inicio, p0.fim)
  const form = useForm<Valores>({
    resolver: zodResolver(esquema),
    defaultValues: { ano: sug.ano, numero: sug.n, temaLicao: '', dataInicio: p0.inicio, dataFim: p0.fim, decimoTerceiro: s0[s0.length - 1] ?? '' },
  })
  const e = form.formState.errors
  const [inicio, fim, d13] = form.watch(['dataInicio', 'dataFim', 'decimoTerceiro'])
  const sabados = /^\d{4}-\d{2}-\d{2}$/.test(inicio) && /^\d{4}-\d{2}-\d{2}$/.test(fim) && fim > inicio ? sabadosEntre(inicio, fim) : []
  const usarCivil = () => {
    const p = periodoCivil(Number(form.getValues('ano')), Number(form.getValues('numero')))
    form.setValue('dataInicio', p.inicio, { shouldValidate: true })
    form.setValue('dataFim', p.fim, { shouldValidate: true })
    const s = sabadosEntre(p.inicio, p.fim)
    form.setValue('decimoTerceiro', s[s.length - 1] ?? '')
  }

  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    if (sabados.length !== 13 && sabados.length !== 14) { setErro(`O período tem ${sabados.length} sábados; um trimestre tem 13 ou 14.`); return }
    try {
      await criar.mutateAsync({
        trimestre: { ano: v.ano, numero: v.numero, temaLicao: v.temaLicao || undefined, dataInicio: v.dataInicio, dataFim: v.dataFim },
        decimoTerceiro: sabados.includes(v.decimoTerceiro) ? v.decimoTerceiro : sabados[sabados.length - 1],
      })
      toast.success(`Trimestre criado com ${sabados.length} sábados.`)
      aoFechar()
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <form onSubmit={submeter} noValidate className="grid gap-4">
          <DialogHeader>
            <DialogTitle>Novo trimestre</DialogTitle>
            <DialogDescription>Os sábados do período são criados automaticamente, um por semana.</DialogDescription>
          </DialogHeader>
          <ErroFormulario mensagem={erro} />
          <div className="grid grid-cols-2 gap-4">
            <CampoFormulario rotulo="Ano" erro={e.ano?.message} obrigatorio>{(p) => <Input {...p} inputMode="numeric" {...form.register('ano')} />}</CampoFormulario>
            <CampoFormulario rotulo="Trimestre" erro={e.numero?.message} obrigatorio>
              {(p) => <Seleccao {...p} {...form.register('numero')}>{[1, 2, 3, 4].map((n) => <option key={n} value={n}>{['I', 'II', 'III', 'IV'][n - 1]} trimestre</option>)}</Seleccao>}
            </CampoFormulario>
          </div>
          <CampoFormulario rotulo="Tema da lição" erro={e.temaLicao?.message}>{(p) => <Input {...p} {...form.register('temaLicao')} />}</CampoFormulario>
          <div className="grid grid-cols-2 gap-4">
            <CampoFormulario rotulo="Primeiro dia" erro={e.dataInicio?.message} obrigatorio>
              {(p) => <Controller control={form.control} name="dataInicio" render={({ field }) => <CampoData {...p} {...field} />} />}
            </CampoFormulario>
            <CampoFormulario rotulo="Último dia" erro={e.dataFim?.message} obrigatorio>
              {(p) => <Controller control={form.control} name="dataFim" render={({ field }) => <CampoData {...p} {...field} />} />}
            </CampoFormulario>
          </div>
          <Button type="button" variant="link" size="sm" className="justify-self-start px-0" onClick={usarCivil}>Usar o trimestre civil do ano e número escolhidos</Button>
          <CampoFormulario rotulo="13.º sábado (oferta)" ajuda={`${sabados.length} sábados no período`}>
            {(p) => (
              <Seleccao {...p} value={sabados.includes(d13) ? d13 : sabados[sabados.length - 1] ?? ''} onChange={(ev) => form.setValue('decimoTerceiro', ev.target.value)} disabled={!sabados.length}>
                {sabados.map((s, i) => <option key={s} value={s}>{i + 1}.º sábado · {data(s)}</option>)}
              </Seleccao>
            )}
          </CampoFormulario>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={aoFechar}>{t.comum.cancelar}</Button>
            <Button type="submit" disabled={form.formState.isSubmitting}>{form.formState.isSubmitting ? t.comum.aGravar : 'Criar trimestre'}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

const ROTULOS_PESOS = [['pesoPresenca', 'Presença'], ['pesoEstudo', 'Estudo diário'], ['pesoOfertas', 'Ofertas'], ['pesoVisitantes', 'Visitantes']] as const

function Pesos({ trimestre }: { trimestre?: Trimestre }) {
  const { pode } = useSessao()
  const q = usePesos()
  const [editar, setEditar] = useState<{ id?: number; trimestreId?: number; base: PesosPontuacao | null } | null>(null)
  const defeito = q.data?.find((x) => x.trimestreId == null) ?? null
  const doTrimestre = trimestre ? q.data?.find((x) => x.trimestreId === trimestre.id) ?? null : null
  const efectivo = doTrimestre ?? defeito
  const valor = (k: (typeof ROTULOS_PESOS)[number][0]) => efectivo?.[k] ?? { pesoPresenca: '0.30', pesoEstudo: '0.30', pesoOfertas: '0.25', pesoVisitantes: '0.15' }[k]
  const podeEditar = pode('escola_sabatina.pontuacao_config.alterar') || pode('escola_sabatina.pontuacao_config.criar')

  return (
    <Cartao titulo="Pesos da pontuação" icone={Scale} descricao={doTrimestre && trimestre ? `Próprios do ${nomeTrimestre(trimestre)}` : 'Pesos por defeito (todos os trimestres)'}>
      {q.isPending ? <LinhasACarregar linhas={4} /> : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} /> : (
        <div className="grid gap-4">
          <dl className="grid gap-2 text-sm">
            {ROTULOS_PESOS.map(([k, rot]) => (
              <div key={k} className="grid gap-1">
                <div className="flex justify-between"><dt className="text-muted-foreground">{rot}</dt><dd className="font-medium tabular-nums">{Math.round(Number(valor(k)) * 100)}%</dd></div>
                <div className="h-1.5 overflow-hidden rounded-full bg-muted"><div className="h-full rounded-full bg-primary" style={{ width: `${Number(valor(k)) * 100}%` }} /></div>
              </div>
            ))}
            <div className="flex justify-between border-t pt-2"><dt className="text-muted-foreground">Limite das ofertas</dt><dd className="font-medium tabular-nums">{Math.round(Number(efectivo?.limiteOfertas ?? '1.20') * 100)}% do alvo</dd></div>
          </dl>
          {podeEditar && (
            <div className="flex flex-wrap gap-2">
              <Button variant="outline" size="sm" onClick={() => setEditar({ id: defeito?.id, base: defeito })}>Editar os pesos por defeito</Button>
              {trimestre && <Button variant="ghost" size="sm" onClick={() => setEditar({ id: doTrimestre?.id, trimestreId: trimestre.id, base: doTrimestre ?? defeito })}>Pesos só deste trimestre</Button>}
            </div>
          )}
        </div>
      )}
      {editar && <DialogoPesos {...editar} aoFechar={() => setEditar(null)} />}
    </Cartao>
  )
}

const pesoPct = z.coerce.number({ invalid_type_error: 'Número' }).int('Inteiro').min(0).max(100)
const esquemaPesos = z.object({ pesoPresenca: pesoPct, pesoEstudo: pesoPct, pesoOfertas: pesoPct, pesoVisitantes: pesoPct, limiteOfertas: z.coerce.number().int().min(100, 'Pelo menos 100%').max(999) })
  .refine((v) => v.pesoPresenca + v.pesoEstudo + v.pesoOfertas + v.pesoVisitantes === 100, { path: ['pesoVisitantes'], message: 'Os quatro pesos têm de somar 100%' })

function DialogoPesos({ id, trimestreId, base, aoFechar }: { id?: number; trimestreId?: number; base: PesosPontuacao | null; aoFechar: () => void }) {
  const gravar = useGravarPesos()
  const [erro, setErro] = useState<string | null>(null)
  const p100 = (v: string | undefined, d: number) => Math.round(Number(v ?? d) * 100)
  const form = useForm<z.infer<typeof esquemaPesos>>({
    resolver: zodResolver(esquemaPesos),
    defaultValues: {
      pesoPresenca: p100(base?.pesoPresenca, 0.3), pesoEstudo: p100(base?.pesoEstudo, 0.3), pesoOfertas: p100(base?.pesoOfertas, 0.25),
      pesoVisitantes: p100(base?.pesoVisitantes, 0.15), limiteOfertas: p100(base?.limiteOfertas, 1.2),
    },
  })
  const e = form.formState.errors
  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    const dec = (n: number) => (n / 100).toFixed(3)
    try {
      await gravar.mutateAsync({
        id,
        corpo: {
          ...(trimestreId ? { trimestreId } : {}),
          pesoPresenca: dec(v.pesoPresenca), pesoEstudo: dec(v.pesoEstudo), pesoOfertas: dec(v.pesoOfertas), pesoVisitantes: dec(v.pesoVisitantes),
          limiteOfertas: (v.limiteOfertas / 100).toFixed(2),
        } as never,
      })
      toast.success('Pesos gravados. A classificação já os usa.')
      aoFechar()
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <form onSubmit={submeter} noValidate className="grid gap-4">
          <DialogHeader>
            <DialogTitle>{trimestreId ? 'Pesos deste trimestre' : 'Pesos por defeito'}</DialogTitle>
            <DialogDescription>Em percentagem; os quatro somam 100%. O limite das ofertas é até onde conta passar o alvo.</DialogDescription>
          </DialogHeader>
          <ErroFormulario mensagem={erro} />
          <div className="grid grid-cols-2 gap-4">
            {ROTULOS_PESOS.map(([k, rot]) => (
              <CampoFormulario key={k} rotulo={`${rot} (%)`} erro={e[k]?.message}>{(p) => <Input {...p} inputMode="numeric" {...form.register(k)} className="num" />}</CampoFormulario>
            ))}
            <CampoFormulario rotulo="Limite das ofertas (%)" erro={e.limiteOfertas?.message} className="col-span-2">{(p) => <Input {...p} inputMode="numeric" {...form.register('limiteOfertas')} className="num" />}</CampoFormulario>
          </div>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={aoFechar}>{t.comum.cancelar}</Button>
            <Button type="submit" disabled={form.formState.isSubmitting}>{form.formState.isSubmitting ? t.comum.aGravar : t.comum.guardar}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
