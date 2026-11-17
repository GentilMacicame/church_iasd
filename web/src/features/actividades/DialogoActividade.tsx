/**
 * Registar ou editar uma actividade (F-ACT, V34). Antes de gravar procura conflitos de calendário na igreja: se houver,
 * mostra as actividades envolvidas e os dias livres seguintes (à mesma hora); o utilizador escolhe outra data ou
 * confirma "Gravar mesmo assim". O conflito nunca bloqueia: só avisa.
 */
import { useState } from 'react'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { AlertTriangle, CalendarCheck } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { Seleccao } from '@/components/comum/Seleccao'
import { CampoData } from '@/components/comum/CampoData'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { data, dataPorExtenso, hora, isoMaputo, partesMaputo } from '@/lib/formatos'
import { useMembrosBasicos } from '@/features/membros/api'
import { cn } from '@/lib/utils'
import { ROTULO_ESTADO, procurarConflitos, useActividadesMut, useDepartamentosIgreja, useDistritoDaIgreja, type Actividade, type Conflitos } from './api'

const HORA = /^([01]\d|2[0-3]):[0-5]\d$/
const esquema = z.object({
  origem: z.enum(['IGREJA', 'AREA_PASTORAL']),
  departamentoIgrejaId: z.string(),
  nome: z.string().trim().min(1, t.comum.obrigatorio).max(150, 'No máximo 150 caracteres'),
  dataInicio: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Escreva a data como dd/mm/aaaa'),
  horaInicio: z.string().regex(HORA, 'Hora como hh:mm'),
  dataFim: z.string().refine((v) => v === '' || /^\d{4}-\d{2}-\d{2}$/.test(v), 'Escreva a data como dd/mm/aaaa'),
  horaFim: z.string().refine((v) => v === '' || HORA.test(v), 'Hora como hh:mm'),
  local: z.string().trim().max(255),
  responsavelMembroId: z.string(),
  valorPrevisto: z.string(),
  descricao: z.string().trim(),
  objectivos: z.string().trim(),
  estado: z.string(),
}).superRefine((v, ctx) => {
  if (v.origem === 'IGREJA' && !v.departamentoIgrejaId) ctx.addIssue({ code: 'custom', path: ['departamentoIgrejaId'], message: 'Escolha o departamento' })
  if (v.horaFim && v.dataInicio) {
    const ini = `${v.dataInicio}T${v.horaInicio}`, fim = `${v.dataFim || v.dataInicio}T${v.horaFim}`
    if (fim < ini) ctx.addIssue({ code: 'custom', path: ['horaFim'], message: 'O fim tem de ser depois do início' })
  }
})
type Valores = z.infer<typeof esquema>

/** Soma dias a uma data aaaa-mm-dd (para mudar o fim junto com o início). */
function somarDias(iso: string, dias: number) {
  const d = new Date(`${iso}T12:00:00Z`)
  d.setUTCDate(d.getUTCDate() + dias)
  return d.toISOString().slice(0, 10)
}
const diasEntre = (a: string, b: string) => Math.round((Date.parse(`${b}T12:00:00Z`) - Date.parse(`${a}T12:00:00Z`)) / 86_400_000)

export function DialogoActividade({ actividade, departamentoInicial, dataInicial, aoFechar, aoGravar }: {
  actividade?: Actividade; departamentoInicial?: number; dataInicial?: string; aoFechar: () => void; aoGravar?: (id: number) => void
}) {
  const igreja = useIgreja()
  const deps = useDepartamentosIgreja()
  const { usuario, pode } = useSessao()
  const distrito = useDistritoDaIgreja()
  // área pastoral: o pastor do distrito ou quem gere os distritos (Associação, super-administrador); a base de dados decide
  const podeDistrito = !!distrito.data && (distrito.data.pastorUsuarioId === usuario?.id || pode('organizacao.distrito.alterar'))
  const basicos = useMembrosBasicos()
  const { criar, alterar } = useActividadesMut()
  const [erro, setErro] = useState<string | null>(null)
  const [conflitos, setConflitos] = useState<Conflitos | null>(null)
  const ini = partesMaputo(actividade?.dataInicio)
  const fim = partesMaputo(actividade?.dataFim)
  const form = useForm<Valores>({
    resolver: zodResolver(esquema),
    defaultValues: {
      origem: actividade?.distritoId ? 'AREA_PASTORAL' : 'IGREJA',
      departamentoIgrejaId: String(actividade?.departamentoIgrejaId ?? departamentoInicial ?? ''),
      nome: actividade?.nome ?? '', dataInicio: ini.data || dataInicial || '', horaInicio: ini.hora || '09:00',
      dataFim: fim.data && fim.data !== ini.data ? fim.data : '', horaFim: fim.hora,
      local: actividade?.local ?? '', responsavelMembroId: actividade?.responsavelMembroId ? String(actividade.responsavelMembroId) : '',
      valorPrevisto: actividade?.valorPrevisto ?? '', descricao: actividade?.descricao ?? '', objectivos: actividade?.objectivos ?? '',
      estado: actividade?.estado ?? 'PLANEADA',
    },
  })
  const e = form.formState.errors
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }
  const intervalo = (v: Valores) => ({
    inicio: isoMaputo(v.dataInicio, v.horaInicio),
    fim: v.horaFim ? isoMaputo(v.dataFim || v.dataInicio, v.horaFim) : v.dataFim ? isoMaputo(v.dataFim, '23:59') : null,
  })

  const gravar = async (v: Valores) => {
    const { inicio, fim: fimIso } = intervalo(v)
    const corpo = {
      departamentoIgrejaId: v.origem === 'IGREJA' ? Number(v.departamentoIgrejaId) : null,
      distritoId: v.origem === 'AREA_PASTORAL' ? actividade?.distritoId ?? distrito.data?.id ?? null : null,
      nome: v.nome, dataInicio: inicio, dataFim: fimIso,
      local: v.local || null, responsavelMembroId: v.responsavelMembroId ? Number(v.responsavelMembroId) : null,
      valorPrevisto: v.valorPrevisto || '0.00', descricao: v.descricao || null, objectivos: v.objectivos || null,
    }
    if (actividade) {
      await alterar.mutateAsync({ id: actividade.id, ...corpo, estado: v.estado as never } as never)
      toast.success('Actividade actualizada.')
      aoGravar?.(actividade.id)
    } else {
      const a = await criar.mutateAsync(corpo as never)
      toast.success('Actividade registada.')
      aoGravar?.(a.id)
    }
    aoFechar()
  }

  /** 1.º procura conflitos; havendo, mostra-os e espera a escolha. "Gravar mesmo assim" chama gravar directamente. */
  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    try {
      if (v.estado !== 'CANCELADA') {
        const { inicio, fim: fimIso } = intervalo(v)
        const r = await procurarConflitos(igreja.id, inicio, fimIso, actividade?.id)
        if (r.conflitos.length) { setConflitos(r); return }
      }
      await gravar(v)
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })
  const gravarMesmoAssim = async () => {
    setErro(null)
    try { await gravar(form.getValues()) } catch (err) { setErro(mensagemDe(err)) }
  }
  const usarData = (inicioIso: string) => {
    const novo = partesMaputo(inicioIso).data
    const v = form.getValues()
    if (v.dataFim) form.setValue('dataFim', somarDias(novo, diasEntre(v.dataInicio, v.dataFim)), { shouldDirty: true })
    form.setValue('dataInicio', novo, { shouldDirty: true })
    setConflitos(null)
    toast.info(`Data mudada para ${data(novo)}. Confira e grave.`)
  }

  const listaDeps = deps.data?.daIgreja.filter((d) => !d.endDate) ?? []
  const origem = form.watch('origem')
  const aGravar = form.formState.isSubmitting || criar.isPending || alterar.isPending

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="max-h-[92vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{actividade ? 'Editar actividade' : 'Nova actividade'}</DialogTitle>
          <DialogDescription>Antes de gravar confirma-se se há outra actividade da igreja à mesma hora.</DialogDescription>
        </DialogHeader>
        <form onSubmit={submeter} noValidate className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          {!deps.isPending && !listaDeps.length && origem === 'IGREJA' && (
            <p className="rounded-lg border border-warning/40 bg-tint-warning px-3 py-2 text-sm text-warning-text">
              Esta igreja ainda não tem departamentos activos. Active um no separador Departamentos.
            </p>
          )}
          <div className="grid gap-4 sm:grid-cols-2">
            <CampoFormulario rotulo="Nome" erro={e.nome?.message} obrigatorio className="sm:col-span-2">
              {(p) => <Input {...p} {...form.register('nome')} placeholder="ex.: Semana de oração jovem" className="alvo" autoFocus />}
            </CampoFormulario>
            {(podeDistrito || actividade?.distritoId) && (
              <fieldset className="grid gap-1.5 sm:col-span-2">
                <legend className="mb-1.5 text-sm font-medium">Origem</legend>
                <div role="radiogroup" aria-label="Origem" className="grid grid-cols-2 gap-2">
                  {(['IGREJA', 'AREA_PASTORAL'] as const).map((o) => (
                    <button key={o} type="button" role="radio" aria-checked={origem === o} disabled={!!actividade}
                      onClick={() => form.setValue('origem', o, { shouldDirty: true })}
                      className={cn('alvo rounded-lg border px-3 py-2 text-left text-sm font-medium transition disabled:cursor-not-allowed disabled:opacity-70',
                        origem === o ? 'border-primary bg-primary/10 text-primary' : 'text-muted-foreground hover:border-primary/40')}>
                      {o === 'IGREJA' ? `Igreja local · ${igreja.nome}` : `Área pastoral · ${distrito.data?.nome ?? 'distrito'}`}
                    </button>
                  ))}
                </div>
                {origem === 'AREA_PASTORAL' && <p className="text-xs text-muted-foreground">Aparece no calendário de todas as igrejas do distrito.</p>}
              </fieldset>
            )}
            {origem === 'IGREJA' && (
              <CampoFormulario rotulo="Departamento" erro={e.departamentoIgrejaId?.message} obrigatorio>
                {(p) => (
                  <Seleccao {...p} {...form.register('departamentoIgrejaId')}>
                    <option value="">Escolher…</option>
                    {listaDeps.map((d) => <option key={d.id} value={d.id}>{d.nome}</option>)}
                  </Seleccao>
                )}
              </CampoFormulario>
            )}
            <CampoFormulario rotulo="Responsável principal" erro={e.responsavelMembroId?.message}>
              {(p) => (
                <Controller control={form.control} name="responsavelMembroId" render={({ field }) => (
                  <CampoMembro id={p.id} valor={field.value ? Number(field.value) : null} aoMudar={(n) => field.onChange(n == null ? '' : String(n))} nomeDe={nomeDe} />
                )} />
              )}
            </CampoFormulario>
            <div className="grid grid-cols-[1fr_7rem] gap-3">
              <CampoFormulario rotulo="Data" erro={e.dataInicio?.message} obrigatorio>
                {(p) => <Controller control={form.control} name="dataInicio" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
              </CampoFormulario>
              <CampoFormulario rotulo="Início" erro={e.horaInicio?.message} obrigatorio>
                {(p) => <Input {...p} type="time" {...form.register('horaInicio')} className="alvo num" />}
              </CampoFormulario>
            </div>
            <div className="grid grid-cols-[1fr_7rem] gap-3">
              <CampoFormulario rotulo="Termina noutro dia" erro={e.dataFim?.message} ajuda="Vazio = no mesmo dia">
                {(p) => <Controller control={form.control} name="dataFim" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
              </CampoFormulario>
              <CampoFormulario rotulo="Fim" erro={e.horaFim?.message}>
                {(p) => <Input {...p} type="time" {...form.register('horaFim')} className="alvo num" />}
              </CampoFormulario>
            </div>
            <CampoFormulario rotulo="Local" erro={e.local?.message}>
              {(p) => <Input {...p} {...form.register('local')} placeholder="ex.: Igreja, salão, praia" className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo="Orçamento previsto" erro={e.valorPrevisto?.message} ajuda="O material e as despesas registam-se na ficha">
              {(p) => <Controller control={form.control} name="valorPrevisto" render={({ field }) => <CampoDinheiro {...p} {...field} className="alvo" />} />}
            </CampoFormulario>
            <CampoFormulario rotulo="Objectivos" erro={e.objectivos?.message} className="sm:col-span-2">
              {(p) => <Textarea {...p} {...form.register('objectivos')} rows={2} placeholder="O que se quer alcançar" />}
            </CampoFormulario>
            <CampoFormulario rotulo="Descrição" erro={e.descricao?.message} className="sm:col-span-2">
              {(p) => <Textarea {...p} {...form.register('descricao')} rows={2} placeholder="Programa, público, observações" />}
            </CampoFormulario>
            {actividade && (
              <CampoFormulario rotulo="Estado" erro={e.estado?.message}>
                {(p) => (
                  <Seleccao {...p} {...form.register('estado')}>
                    {Object.entries(ROTULO_ESTADO).map(([k, r]) => <option key={k} value={k}>{r}</option>)}
                  </Seleccao>
                )}
              </CampoFormulario>
            )}
          </div>

          {conflitos && (
            <section role="alert" className="rounded-xl border border-warning/50 bg-tint-warning p-4">
              <h3 className="flex items-center gap-2 text-sm font-semibold text-warning-text"><AlertTriangle className="size-4" />Já há actividades a essa hora</h3>
              <ul className="mt-2 grid gap-1.5 text-sm">
                {conflitos.conflitos.map((c) => (
                  <li key={c.actividadeId} className="rounded-md border bg-card px-3 py-2">
                    <span className="font-medium">{c.nome}</span> <span className="text-muted-foreground">· {c.departamento} · {dataPorExtenso(c.dataInicio)}, {hora(c.dataInicio)}{c.dataFim ? `–${hora(c.dataFim)}` : ''}{c.local ? ` · ${c.local}` : ''}</span>
                  </li>
                ))}
              </ul>
              {conflitos.alternativas.length > 0 && (
                <>
                  <p className="mt-3 text-sm font-medium">Dias livres à mesma hora</p>
                  <div className="mt-1.5 flex flex-wrap gap-2">
                    {conflitos.alternativas.map((a) => (
                      <Button key={a.dataInicio} type="button" variant="outline" size="sm" className="alvo bg-card" onClick={() => usarData(a.dataInicio)}>
                        <CalendarCheck className="size-4" />{dataPorExtenso(a.dataInicio)}
                      </Button>
                    ))}
                  </div>
                </>
              )}
              <div className="mt-3 flex flex-wrap gap-2 border-t border-warning/30 pt-3">
                <Button type="button" variant="ghost" size="sm" className="alvo" onClick={() => setConflitos(null)}>Escolher outra data</Button>
                <Button type="button" size="sm" className="alvo" disabled={aGravar} onClick={gravarMesmoAssim}>{aGravar ? t.comum.aGravar : 'Gravar mesmo assim'}</Button>
              </div>
            </section>
          )}

          <DialogFooter>
            <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
            {!conflitos && <Button type="submit" className="alvo" disabled={aGravar}>{aGravar ? t.comum.aGravar : actividade ? t.comum.guardar : 'Registar'}</Button>}
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
