/** Reuniões · "Que reuniões houve e que votos ficaram em acta?" */
import { useMemo, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ChevronRight, Gavel, Landmark, Plus, Vote } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { Seleccao } from '@/components/comum/Seleccao'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { data, hojeIso } from '@/lib/formatos'
import { useMembrosBasicos } from '@/features/membros/api'
import { useCriarReuniao, useReunioes, useVotos, type Reuniao, type TipoReuniao } from './api'

export function varianteReuniao(t: TipoReuniao) {
  return t === 'ASSEMBLEIA_ADMINISTRATIVA' ? 'default' : t === 'REUNIAO_REGULAR' ? 'info' : 'secondary'
}

const esquema = z.object({
  tipo: z.string().min(1, t.comum.obrigatorio),
  data: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Escreva a data como dd/mm/aaaa'),
  hora: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'Hora como 10:00'),
  local: z.string().trim().max(150),
  presidente: z.number().nullable(),
  secretario: z.number().nullable(),
  quorum: z.string().regex(/^\d*$/, 'Só algarismos'),
})

function DialogoNovaReuniao({ aberto, aoMudar }: { aberto: boolean; aoMudar: (v: boolean) => void }) {
  const igreja = useIgreja()
  const navigate = useNavigate()
  const criar = useCriarReuniao()
  const basicos = useMembrosBasicos()
  const [erro, setErro] = useState<string | null>(null)
  const form = useForm({ resolver: zodResolver(esquema), defaultValues: { tipo: 'REUNIAO_REGULAR', data: hojeIso(), hora: '10:00', local: '', presidente: null as number | null, secretario: null as number | null, quorum: '' } })
  const e = form.formState.errors
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }
  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    try {
      const r = await criar.mutateAsync({
        igrejaId: igreja.id, tipo: v.tipo as TipoReuniao, data: `${v.data}T${v.hora}:00+02:00`, // data e hora, fuso de Maputo
        local: v.local || undefined,
        presididaPorMembroId: v.presidente ?? undefined, secretarioMembroId: v.secretario ?? undefined, quorumPresentes: v.quorum ? Number(v.quorum) : undefined,
      })
      toast.success('Reunião registada. Agora registe os votos.')
      aoMudar(false)
      navigate(`/reunioes/${r.id}`)
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })
  return (
    <Dialog open={aberto} onOpenChange={aoMudar}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Nova reunião</DialogTitle>
          <DialogDescription>Admissões e saídas do livro exigem voto em reunião regular ou assembleia administrativa; a junta directiva só recomenda.</DialogDescription>
        </DialogHeader>
        <form onSubmit={submeter} noValidate className="grid gap-4 sm:grid-cols-2">
          <div className="sm:col-span-2"><ErroFormulario mensagem={erro} /></div>
          <CampoFormulario rotulo="Tipo de reunião" erro={e.tipo?.message} obrigatorio>
            {(p) => <Seleccao {...p} {...form.register('tipo')}>{Object.entries(rotulos.tipoReuniao).map(([k, r]) => <option key={k} value={k}>{r}</option>)}</Seleccao>}
          </CampoFormulario>
          <CampoFormulario rotulo="Data" erro={e.data?.message} obrigatorio>
            {(p) => <Controller control={form.control} name="data" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
          </CampoFormulario>
          <CampoFormulario rotulo="Hora" erro={e.hora?.message} obrigatorio>
            {(p) => <Input {...p} {...form.register('hora')} type="time" className="alvo num" />}
          </CampoFormulario>
          <CampoFormulario rotulo="Local" erro={e.local?.message}>
            {(p) => <Input {...p} {...form.register('local')} placeholder="ex.: Templo" className="alvo" />}
          </CampoFormulario>
          <CampoFormulario rotulo="Presentes (quórum)" erro={e.quorum?.message}>
            {(p) => <Input {...p} {...form.register('quorum')} inputMode="numeric" className="alvo num" />}
          </CampoFormulario>
          <CampoFormulario rotulo="Presidida por">
            {(p) => <Controller control={form.control} name="presidente" render={({ field }) => <CampoMembro id={p.id} valor={field.value} aoMudar={field.onChange} nomeDe={nomeDe} />} />}
          </CampoFormulario>
          <CampoFormulario rotulo="Secretário(a)">
            {(p) => <Controller control={form.control} name="secretario" render={({ field }) => <CampoMembro id={p.id} valor={field.value} aoMudar={field.onChange} nomeDe={nomeDe} />} />}
          </CampoFormulario>
          <DialogFooter className="sm:col-span-2">
            <Button type="button" variant="outline" onClick={() => aoMudar(false)}>{t.comum.cancelar}</Button>
            <Button type="submit" disabled={form.formState.isSubmitting}>{form.formState.isSubmitting ? t.comum.aGravar : 'Registar reunião'}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

export default function PaginaReunioes() {
  const { pode } = useSessao()
  const navigate = useNavigate()
  const q = useReunioes()
  const votos = useVotos()
  const [nova, setNova] = useState(false)
  const ano = hojeIso().slice(0, 4)
  const lista = q.data ?? []
  const porReuniao = useMemo(() => {
    const m = new Map<number, number>()
    for (const v of votos.data ?? []) m.set(v.reuniaoId, (m.get(v.reuniaoId) ?? 0) + 1)
    return m
  }, [votos.data])
  const doAno = new Set(lista.filter((r) => r.data.startsWith(ano)).map((r) => r.id))
  const votosAno = (votos.data ?? []).filter((v) => doAno.has(v.reuniaoId))

  return (
    <>
      <TituloPagina icone={Landmark} titulo={t.livro.reunioes} descricao="Juntas directivas, reuniões regulares e assembleias, com os votos em acta"
        accoes={pode('secretaria.reuniao.criar') && <Button className="alvo" onClick={() => setNova(true)}><Plus className="size-4" />Nova reunião</Button>} />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4">
          <Indicador rotulo={`Reuniões em ${ano}`} valor={doAno.size} nota="registadas nesta igreja" icone={Landmark} aCarregar={q.isPending} />
          <Indicador rotulo="Votos aprovados" valor={votosAno.filter((v) => v.estado === 'APROVADO').length} nota={`em ${ano}`} icone={Vote} tom="success" aCarregar={votos.isPending} />
          <Indicador rotulo="Admissões votadas" valor={votosAno.filter((v) => v.tipo === 'ADMISSAO' && v.estado === 'APROVADO').length} nota="prontas para o livro" icone={Gavel} tom="info" aCarregar={votos.isPending} />
        </div>
        <Cartao titulo="Reuniões" descricao="A mais recente primeiro" semMargem>
          {q.isPending ? <LinhasACarregar linhas={4} />
            : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="mx-6 mb-6" />
            : lista.length === 0 ? (
              <EstadoVazio icone={Landmark} titulo="Ainda não há reuniões"
                accao={pode('secretaria.reuniao.criar') && <Button size="sm" onClick={() => setNova(true)}><Plus className="size-4" />Nova reunião</Button>}>
                Registe a reunião e os votos da acta: as admissões no livro de membros precisam do voto.
              </EstadoVazio>
            ) : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Data</th><th>Reunião</th><th className="hidden md:table-cell">Local</th><th className="num">Votos</th><th className="sm:pr-6" /></tr></thead>
                <tbody>
                  {lista.map((r: Reuniao) => (
                    <tr key={r.id} onClick={() => navigate(`/reunioes/${r.id}`)} className="cursor-pointer">
                      <td className="tabular-nums font-medium whitespace-nowrap sm:pl-6"><Link to={`/reunioes/${r.id}`} onClick={(e) => e.stopPropagation()} className="hover:text-primary">{data(r.data)}</Link></td>
                      <td><Pilula variante={varianteReuniao(r.tipo)}>{rotulos.tipoReuniao[r.tipo]}</Pilula></td>
                      <td className="hidden text-muted-foreground md:table-cell">{r.local ?? '—'}</td>
                      <td className="num">{porReuniao.get(r.id) ?? 0}</td>
                      <td className="w-10 sm:pr-6"><ChevronRight aria-hidden className="size-4 text-muted-foreground" /></td>
                    </tr>
                  ))}
                </tbody>
              </Tabela>
            )}
        </Cartao>
      </div>
      <DialogoNovaReuniao aberto={nova} aoMudar={setNova} />
    </>
  )
}
