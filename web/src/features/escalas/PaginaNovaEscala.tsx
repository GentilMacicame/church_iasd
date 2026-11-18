/**
 * Nova escala: título, período e quem assina. Ao gravar, a base de dados gera um dia por sábado do período
 * (actividades.fn_gerar_dias_escala) e abre-se o editor.
 */
import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ArrowLeft, CalendarPlus, PenLine } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Cartao, TituloPagina } from '@/components/comum/elementos'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { Seleccao } from '@/components/comum/Seleccao'
import { secretarioOficial, useConselho } from '@/features/conselho/api'
import { useIgreja } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { hojeIso } from '@/lib/formatos'
import { TIPOS_ESCALA, useCriarPlano, type TipoEscala } from './api'
import { cn } from '@/lib/utils'

const dataIso = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Escreva a data como dd/mm/aaaa')
const esquema = z.object({
  titulo: z.string().trim().min(1, t.comum.obrigatorio).max(150),
  dataInicio: dataIso,
  dataFim: dataIso,
  localEmissao: z.string().trim().max(100),
  anciao: z.number().nullable(),
  secretario: z.number().nullable(),
  observacoes: z.string().trim().max(255),
  tipo: z.enum(['CULTO', 'ESCOLA_SABATINA', 'JA']),
}).refine((v) => v.dataFim >= v.dataInicio, { path: ['dataFim'], message: 'O fim tem de ser depois do início' })
type Valores = z.infer<typeof esquema>

const TITULO: Record<TipoEscala, string> = { CULTO: 'Escala do Culto Divino', ESCOLA_SABATINA: 'Escala da Escola Sabatina', JA: 'Escala da JA' }

/** Trimestre civil (o da Escola Sabatina segue o mesmo calendário): início e fim em ISO. */
function trimestre(desloca: number): { inicio: string; fim: string; nome: string } {
  const [a, m] = hojeIso().split('-').map(Number)
  let n = Math.floor((m - 1) / 3) + desloca, ano = a
  while (n > 3) { n -= 4; ano++ }
  const mi = n * 3 + 1, mf = mi + 2
  const ultimo = new Date(Date.UTC(ano, mf, 0)).getUTCDate()
  const pad = (x: number) => String(x).padStart(2, '0')
  return { inicio: `${ano}-${pad(mi)}-01`, fim: `${ano}-${pad(mf)}-${ultimo}`, nome: `${['I', 'II', 'III', 'IV'][n]} trimestre de ${ano}` }
}

export default function PaginaNovaEscala() {
  const igreja = useIgreja()
  const navigate = useNavigate()
  const criar = useCriarPlano()
  const [erro, setErro] = useState<string | null>(null)
  const form = useForm<Valores>({
    resolver: zodResolver(esquema),
    defaultValues: { titulo: 'Escala do Culto Divino', dataInicio: '', dataFim: '', localEmissao: '', anciao: null, secretario: null, observacoes: '', tipo: 'CULTO' },
  })
  const e = form.formState.errors
  // quem assina: os oficiais em exercício (anciãos e secretários); por defeito, o primeiro ancião e o secretário oficial
  const conselho = useConselho()
  const activos = (conselho.data ?? []).filter((o) => o.estadoMandato === 'ACTIVO' || o.estadoMandato === 'A_TERMINAR')
  const anciaos = activos.filter((o) => /anci[aã]o/i.test(o.cargo))
  const secretarios = activos.filter((o) => /secret[aá]rio/i.test(o.cargo))
  useEffect(() => {
    if (!conselho.data) return
    if (form.getValues('anciao') == null && anciaos[0]) form.setValue('anciao', anciaos[0].membroId)
    const sec = secretarioOficial(conselho.data) ?? secretarios[0]
    if (form.getValues('secretario') == null && sec) form.setValue('secretario', sec.membroId)
  }, [conselho.data])  // eslint-disable-line react-hooks/exhaustive-deps
  const opcoesOficiais = (lista: typeof activos) => [...new Map(lista.map((o) => [o.membroId, o])).values()]
  const usar = (d: number) => {
    const tr = trimestre(d)
    form.setValue('dataInicio', tr.inicio, { shouldValidate: true })
    form.setValue('dataFim', tr.fim, { shouldValidate: true })
    const base = TITULO[form.getValues('tipo')]
    if (form.getValues('titulo') === base) form.setValue('titulo', `${base} · ${tr.nome}`)
  }

  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    try {
      const p = await criar.mutateAsync({
        igrejaId: igreja.id, titulo: v.titulo, tipo: v.tipo, dataInicio: v.dataInicio, dataFim: v.dataFim,
        localEmissao: v.localEmissao || undefined, dataEmissao: hojeIso(),
        anciaoMembroId: v.anciao ?? undefined, secretarioMembroId: v.secretario ?? undefined, observacoes: v.observacoes || undefined,
      })
      toast.success(t.escalas.criada)
      navigate(`/escalas/${p.id}`)
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })

  return (
    <form onSubmit={submeter} noValidate>
      <TituloPagina
        antes={<Link to="/escalas" className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" /> {t.escalas.titulo}</Link>}
        icone={CalendarPlus}
        titulo={t.escalas.nova}
        descricao="Culto Divino, Escola Sabatina ou JA; os sábados criam-se sozinhos"
      />
      <div className="grid gap-6 lg:grid-cols-12">
        <div className="grid gap-6 lg:col-span-9 xl:col-span-8">
          <ErroFormulario mensagem={erro} />
          <Cartao titulo="Período" descricao="Normalmente um trimestre" icone={CalendarPlus}>
            <div className="grid gap-4">
              <div role="radiogroup" aria-label="Escala de" className="grid gap-2 sm:grid-cols-3">
                {(Object.keys(TIPOS_ESCALA) as TipoEscala[]).map((k) => (
                  <button key={k} type="button" role="radio" aria-checked={form.watch('tipo') === k}
                    onClick={() => {
                      const antes = TITULO[form.getValues('tipo')]
                      form.setValue('tipo', k)
                      if (form.getValues('titulo').startsWith(antes)) form.setValue('titulo', form.getValues('titulo').replace(antes, TITULO[k]))
                    }}
                    className={cn('alvo rounded-lg border px-3 py-2.5 text-left', form.watch('tipo') === k ? 'border-primary bg-primary/5' : 'hover:bg-muted/50')}>
                    <span className="block text-sm font-medium">{TIPOS_ESCALA[k]}</span>
                    <span className="block text-xs text-muted-foreground">{k === 'CULTO' ? 'Apresentador, Sermão principal, tradutor…' : 'Com as colunas que a igreja define'}</span>
                  </button>
                ))}
              </div>
              <div className="flex flex-wrap gap-2">
                <Button type="button" variant="outline" size="sm" onClick={() => usar(0)}>Este trimestre ({trimestre(0).nome})</Button>
                <Button type="button" variant="outline" size="sm" onClick={() => usar(1)}>Próximo trimestre ({trimestre(1).nome})</Button>
              </div>
              <CampoFormulario rotulo="Título" erro={e.titulo?.message} obrigatorio>
                {(p) => <Input {...p} {...form.register('titulo')} className="alvo" />}
              </CampoFormulario>
              <div className="grid gap-4 sm:grid-cols-2">
                <CampoFormulario rotulo="Primeiro dia" erro={e.dataInicio?.message} obrigatorio>
                  {(p) => <Controller control={form.control} name="dataInicio" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
                </CampoFormulario>
                <CampoFormulario rotulo="Último dia" erro={e.dataFim?.message} obrigatorio>
                  {(p) => <Controller control={form.control} name="dataFim" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
                </CampoFormulario>
              </div>
            </div>
          </Cartao>
          <Cartao titulo="Assinaturas" descricao="Quem assina a escala impressa" icone={PenLine}>
            <div className="grid gap-4 sm:grid-cols-2">
              <CampoFormulario rotulo="Local de emissão" erro={e.localEmissao?.message}>
                {(p) => <Input {...p} {...form.register('localEmissao')} placeholder="ex.: Marracuene" className="alvo" />}
              </CampoFormulario>
              <div className="hidden sm:block" />
              <CampoFormulario rotulo="Ancião">
                {(p) => <Controller control={form.control} name="anciao" render={({ field }) => (
                  <Seleccao id={p.id} value={field.value ? String(field.value) : ''} onChange={(ev) => field.onChange(ev.target.value ? Number(ev.target.value) : null)}>
                    <option value="">{anciaos.length ? 'Escolher o ancião…' : 'Sem anciãos no mandato'}</option>
                    {opcoesOficiais(anciaos).map((o) => <option key={o.membroId} value={o.membroId}>{o.membro}</option>)}
                  </Seleccao>
                )} />}
              </CampoFormulario>
              <CampoFormulario rotulo="Secretário(a)">
                {(p) => <Controller control={form.control} name="secretario" render={({ field }) => (
                  <Seleccao id={p.id} value={field.value ? String(field.value) : ''} onChange={(ev) => field.onChange(ev.target.value ? Number(ev.target.value) : null)}>
                    <option value="">{secretarios.length ? 'Escolher o secretário…' : 'Sem secretário no mandato'}</option>
                    {opcoesOficiais(secretarios).map((o) => <option key={o.membroId} value={o.membroId}>{o.membro} · {o.cargo}</option>)}
                  </Seleccao>
                )} />}
              </CampoFormulario>
              <CampoFormulario rotulo="Observações" erro={e.observacoes?.message} className="sm:col-span-2">
                {(p) => <Textarea {...p} {...form.register('observacoes')} rows={2} />}
              </CampoFormulario>
            </div>
          </Cartao>
        </div>
      </div>
      <div className="sticky bottom-0 -mx-4 mt-6 flex justify-end gap-2 border-t bg-background/95 px-4 py-3 backdrop-blur sm:static sm:mx-0 sm:border-0 sm:bg-transparent sm:p-0">
        <Button asChild variant="outline" className="alvo"><Link to="/escalas">{t.comum.cancelar}</Link></Button>
        <Button type="submit" disabled={form.formState.isSubmitting} className="alvo min-w-32">{form.formState.isSubmitting ? t.comum.aGravar : 'Criar escala'}</Button>
      </div>
    </form>
  )
}
