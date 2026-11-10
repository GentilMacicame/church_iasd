/** Diálogos da ficha do membro: acrescentar um contacto e registar o baptismo. */
import { useState, type ReactNode } from 'react'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { Seleccao } from '@/components/comum/Seleccao'
import { CampoData } from '@/components/comum/CampoData'
import { useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { hojeIso } from '@/lib/formatos'
import { useCriarBaptismo, useCriarContacto, type Contacto } from './api'

type TipoContacto = NonNullable<Contacto['tipo']>

const esquemaContacto = z
  .object({ tipo: z.enum(['TELEFONE', 'WHATSAPP', 'EMAIL', 'OUTRO']), valor: z.string().trim().min(1, t.comum.obrigatorio), principal: z.boolean() })
  .superRefine((v, ctx) => {
    if ((v.tipo === 'TELEFONE' || v.tipo === 'WHATSAPP') && !/^\+?\d[\d\s]{7,16}$/.test(v.valor)) {
      ctx.addIssue({ code: 'custom', path: ['valor'], message: 'Escreva o número com o indicativo, por exemplo +258 84 123 4567' })
    }
    if (v.tipo === 'EMAIL' && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.valor)) {
      ctx.addIssue({ code: 'custom', path: ['valor'], message: 'Endereço de e-mail inválido' })
    }
  })

export function DialogoContacto({ membroId, igrejaId, gatilho, primeiro }: { membroId: number; igrejaId: number; gatilho: ReactNode; primeiro: boolean }) {
  const [aberto, setAberto] = useState(false)
  const [erro, setErro] = useState<string | null>(null)
  const criar = useCriarContacto(membroId)
  const form = useForm({ resolver: zodResolver(esquemaContacto), defaultValues: { tipo: 'TELEFONE' as TipoContacto, valor: '', principal: primeiro } })
  const e = form.formState.errors

  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    try {
      await criar.mutateAsync({ membroId, igrejaId, tipo: v.tipo, valor: v.valor.replace(/\s+/g, v.tipo === 'EMAIL' ? '' : ' ').trim(), principal: v.principal })
      toast.success(t.contactos.adicionado)
      form.reset({ tipo: 'TELEFONE', valor: '', principal: false })
      setAberto(false)
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })

  return (
    <Dialog open={aberto} onOpenChange={(v) => { setAberto(v); if (!v) setErro(null) }}>
      <DialogTrigger asChild>{gatilho}</DialogTrigger>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{t.contactos.adicionar}</DialogTitle>
          <DialogDescription>O telefone principal recebe os lembretes das escalas por SMS.</DialogDescription>
        </DialogHeader>
        <form onSubmit={submeter} noValidate className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <CampoFormulario rotulo={t.contactos.tipo} erro={e.tipo?.message}>
            {(p) => (
              <Seleccao {...p} {...form.register('tipo')}>
                {(['TELEFONE', 'WHATSAPP', 'EMAIL', 'OUTRO'] as const).map((k) => <option key={k} value={k}>{rotulos.tipoContacto[k]}</option>)}
              </Seleccao>
            )}
          </CampoFormulario>
          <CampoFormulario rotulo={t.contactos.valor} erro={e.valor?.message} obrigatorio>
            {(p) => <Input {...p} {...form.register('valor')} inputMode={form.watch('tipo') === 'EMAIL' ? 'email' : 'tel'} autoComplete="off" className="alvo" />}
          </CampoFormulario>
          <label className="alvo flex items-center gap-2 text-sm">
            <input type="checkbox" {...form.register('principal')} className="size-4 accent-[var(--accent)]" />
            {t.contactos.principal}
          </label>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => setAberto(false)} className="alvo">{t.comum.cancelar}</Button>
            <Button type="submit" disabled={form.formState.isSubmitting} className="alvo">{form.formState.isSubmitting ? t.comum.aGravar : t.comum.guardar}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

const OUTRA = 'outra'
const esquemaBaptismo = z.object({
  data: z.string().min(1, t.comum.obrigatorio)
    .refine((d) => /^\d{4}-\d{2}-\d{2}$/.test(d), 'Escreva a data como dd/mm/aaaa')
    .refine((d) => d <= hojeIso(), 'A data não pode ser no futuro'),
  igreja: z.string(),
  local: z.string().trim().max(150),
  oficiante: z.string().trim().max(150),
  rebaptismo: z.boolean(),
})

export function DialogoBaptismo({ membroId, gatilho }: { membroId: number; gatilho: ReactNode }) {
  const { igrejas, igreja } = useSessao()
  const [aberto, setAberto] = useState(false)
  const [erro, setErro] = useState<string | null>(null)
  const criar = useCriarBaptismo(membroId)
  const form = useForm({
    resolver: zodResolver(esquemaBaptismo),
    defaultValues: { data: '', igreja: String(igreja?.id ?? OUTRA), local: '', oficiante: '', rebaptismo: false },
  })
  const e = form.formState.errors

  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    try {
      await criar.mutateAsync({
        membroId,
        data: v.data,
        localIgrejaId: v.igreja === OUTRA ? undefined : Number(v.igreja),
        local: v.local || undefined,
        oficiante: v.oficiante || undefined,
        rebaptismo: v.rebaptismo,
      })
      toast.success(t.baptismo.registado)
      setAberto(false)
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })

  return (
    <Dialog open={aberto} onOpenChange={(v) => { setAberto(v); if (!v) setErro(null) }}>
      <DialogTrigger asChild>{gatilho}</DialogTrigger>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{t.baptismo.registar}</DialogTitle>
          <DialogDescription>A entrada no livro de membros faz-se depois, com o voto que a autoriza.</DialogDescription>
        </DialogHeader>
        <form onSubmit={submeter} noValidate className="grid gap-4 sm:grid-cols-2">
          <div className="sm:col-span-2"><ErroFormulario mensagem={erro} /></div>
          <CampoFormulario rotulo={t.baptismo.data} erro={e.data?.message} obrigatorio>
            {(p) => <Controller control={form.control} name="data" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
          </CampoFormulario>
          <CampoFormulario rotulo={t.baptismo.igreja}>
            {(p) => (
              <Seleccao {...p} {...form.register('igreja')}>
                {igrejas.map((i) => <option key={i.id} value={i.id}>{i.nome}</option>)}
                <option value={OUTRA}>{t.baptismo.outraIgreja}</option>
              </Seleccao>
            )}
          </CampoFormulario>
          <CampoFormulario rotulo={t.baptismo.local} erro={e.local?.message} className="sm:col-span-2">
            {(p) => <Input {...p} {...form.register('local')} className="alvo" />}
          </CampoFormulario>
          <CampoFormulario rotulo={t.baptismo.oficiante} erro={e.oficiante?.message} className="sm:col-span-2" ajuda="Nome do pastor ordenado que oficiou.">
            {(p) => <Input {...p} {...form.register('oficiante')} className="alvo" />}
          </CampoFormulario>
          <label className="alvo flex items-center gap-2 text-sm sm:col-span-2">
            <input type="checkbox" {...form.register('rebaptismo')} className="size-4 accent-[var(--accent)]" />
            {t.baptismo.rebaptismo}
          </label>
          <DialogFooter className="sm:col-span-2">
            <Button type="button" variant="outline" onClick={() => setAberto(false)} className="alvo">{t.comum.cancelar}</Button>
            <Button type="submit" disabled={form.formState.isSubmitting} className="alvo">{form.formState.isSubmitting ? t.comum.aGravar : t.comum.guardar}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
