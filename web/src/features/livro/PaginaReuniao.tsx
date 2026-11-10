/** Reunião · a acta: quem presidiu, quantos estavam, e os votos (número, assunto, contagem, resultado). */
import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ArrowLeft, Landmark, Plus, Users, Vote } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Campo, Cartao, Pilula, Tabela } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { Seleccao } from '@/components/comum/Seleccao'
import { ErroApi } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { data, dataPorExtenso } from '@/lib/formatos'
import { useMembrosBasicos } from '@/features/membros/api'
import { useCriarVoto, useReuniao, useVotos, type Reuniao, type TipoVoto, type Voto } from './api'
import { varianteReuniao } from './PaginaReunioes'

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
  const [novo, setNovo] = useState(false)
  const nomeDe = (mid?: number | null) => { const m = mid ? basicos.data?.find((x) => x.id === mid) : null; return m ? `${m.nome} ${m.apelido}` : null }

  const voltar = <Link to="/reunioes" className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" /> {t.livro.reunioes}</Link>
  if (q.isPending) return <>{voltar}<Barra className="h-40 w-full" /></>
  if (q.isError) return <>{voltar}{q.error instanceof ErroApi && q.error.naoEncontrado
    ? <div className="rounded-xl border bg-card shadow-card"><EstadoVazio icone={Landmark} titulo="Reunião não encontrada">Esta reunião não existe ou não é desta igreja.</EstadoVazio></div>
    : <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />}</>
  const r = q.data
  const daReuniao = (votos.data ?? []).filter((v) => v.reuniaoId === r.id).sort((a, b) => a.numero.localeCompare(b.numero))
  const quando = dataPorExtenso(r.data)

  return (
    <>
      {voltar}
      <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div className="flex min-w-0 items-start gap-3">
          <span className="flex size-10 flex-none items-center justify-center rounded-lg bg-primary/10 text-primary" aria-hidden><Landmark className="size-5" /></span>
          <div className="min-w-0">
            <div className="flex flex-wrap items-center gap-2"><h1 className="text-2xl font-semibold tracking-tight">{rotulos.tipoReuniao[r.tipo]}</h1><Pilula variante={varianteReuniao(r.tipo)}>{data(r.data)}</Pilula></div>
            <p className="mt-1 text-sm text-muted-foreground">{quando.charAt(0).toUpperCase() + quando.slice(1)}{r.local ? ` · ${r.local}` : ''}</p>
          </div>
        </div>
        {pode('secretaria.voto.criar') && <Button className="alvo" onClick={() => setNovo(true)}><Plus className="size-4" />Registar voto</Button>}
      </div>
      <div className="grid items-start gap-6 lg:grid-cols-12">
        <Cartao titulo="Votos da acta" descricao="Pela ordem do número" icone={Vote} semMargem className="lg:col-span-8">
          {votos.isPending ? <div className="px-6 pb-6"><Barra className="h-24 w-full" /></div>
            : votos.isError ? <EstadoErro erro={votos.error} aoTentar={() => votos.refetch()} className="mx-6 mb-6" />
            : daReuniao.length === 0 ? <EstadoVazio icone={Vote} titulo="Sem votos">Registe os votos tal como ficaram na acta.</EstadoVazio>
            : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">N.º</th><th>Assunto</th><th className="hidden md:table-cell">Tipo</th><th className="num hidden sm:table-cell">Votação</th><th className="sm:pr-6">Resultado</th></tr></thead>
                <tbody>
                  {daReuniao.map((v) => (
                    <tr key={v.id}>
                      <td className="tabular-nums font-medium whitespace-nowrap sm:pl-6">{v.numero}</td>
                      <td>
                        <p className="font-medium">{v.assunto}</p>
                        {v.leitura === 2 && <p className="text-xs text-muted-foreground">2.ª leitura</p>}
                      </td>
                      <td className="hidden text-muted-foreground md:table-cell">{rotulos.tipoVoto[v.tipo]}</td>
                      <td className="num hidden whitespace-nowrap text-muted-foreground sm:table-cell">{v.aFavor ?? '—'} / {v.contra ?? '—'} / {v.abstencoes ?? '—'}</td>
                      <td className="sm:pr-6"><PilulaResultado v={v} /></td>
                    </tr>
                  ))}
                </tbody>
              </Tabela>
            )}
        </Cartao>
        <Cartao titulo="Dados da reunião" icone={Users} className="lg:col-span-4">
          <dl className="grid gap-4">
            <Campo rotulo="Presidida por">{nomeDe(r.presididaPorMembroId)}</Campo>
            <Campo rotulo="Secretário(a)">{nomeDe(r.secretarioMembroId)}</Campo>
            <Campo rotulo="Presentes">{r.quorumPresentes != null ? String(r.quorumPresentes) : null}</Campo>
          </dl>
        </Cartao>
      </div>
      <DialogoVoto reuniao={r} votos={votos.data ?? []} aberto={novo} aoMudar={setNovo} />
    </>
  )
}
