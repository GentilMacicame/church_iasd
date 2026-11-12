/**
 * Uma classe da Escola Sabatina (F-ES-02, F-ES-03): a configuração no trimestre (professor, auxiliar, secretário,
 * alvos, activa ou desactivada) e as matrículas (membros e interessados; sair da classe guarda a data, nada se apaga).
 * Cada membro só tem uma matrícula activa: a base de dados recusa matricular quem já está noutra classe.
 */
import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ArrowLeft, Pencil, School, Target, UserMinus, UserPlus, Users } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Avatar, Cartao, Pilula, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { Paginada } from '@/components/comum/Paginacao'
import { Seleccao } from '@/components/comum/Seleccao'
import { useSessao } from '@/auth/sessao'
import { mensagemDe } from '@/api/erros'
import { rotulos, t } from '@/i18n/pt-MZ'
import { data } from '@/lib/formatos'
import { useMembrosBasicos } from '@/features/membros/api'
import {
  DIVISOES, nomeTrimestre, trimestreActual, useAlterarClasse, useClasses, useClassesTrimestre, useGravarClasseTrimestre, useMatricular,
  useMatriculas, useTerminarClasse, useTirarMatricula, useTrimestres, type Classe, type ClasseTrimestre, type Divisao, type Trimestre,
} from './api'

export default function PaginaClasse() {
  const id = Number(useParams().id)
  const navigate = useNavigate()
  const { pode } = useSessao()
  const [params, setParams] = useSearchParams()
  const classes = useClasses()
  const classe = classes.data?.find((c) => c.id === id)
  const trimestres = useTrimestres()
  const trimestre = trimestres.data?.find((x) => x.id === Number(params.get('trimestre'))) ?? trimestreActual(trimestres.data ?? [])
  const cts = useClassesTrimestre(trimestre?.id)
  const ct = cts.data?.find((c) => c.classeId === id)
  const [editar, setEditar] = useState(false)
  const [terminar, setTerminar] = useState(false)
  const terminarClasse = useTerminarClasse()

  if (classes.isError) return <EstadoErro erro={classes.error} aoTentar={() => classes.refetch()} />
  if (classes.isPending) return <Cartao><LinhasACarregar linhas={5} /></Cartao>
  if (!classe) return <Cartao><EstadoVazio icone={School} titulo="Classe não encontrada">A classe não existe ou foi terminada. <Link to="/escola-sabatina/classes" className="text-primary hover:underline">Ver as classes</Link></EstadoVazio></Cartao>

  return (
    <>
      <TituloPagina
        antes={<Link to="/escola-sabatina/classes" className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" />{t.es.classes}</Link>}
        icone={School}
        titulo={classe.nome}
        descricao={[rotulos.divisao[classe.divisao], classe.localReuniao].filter(Boolean).join(' · ')}
        accoes={<>
          {pode('escola_sabatina.classe.alterar') && <Button variant="outline" className="alvo" onClick={() => setEditar(true)}><Pencil className="size-4" />{t.comum.editar}</Button>}
          {pode('escola_sabatina.classe.terminar') && <Button variant="ghost" className="alvo text-destructive-text" onClick={() => setTerminar(true)}>Terminar</Button>}
        </>}
      />
      <div className="grid gap-6 lg:grid-cols-12">
        <div className="lg:col-span-7">
          <Cartao titulo="No trimestre" icone={Target}
            descricao="Professor, secretário e alvos. Sem esta configuração não se regista o relatório do sábado."
            accoes={(trimestres.data?.length ?? 0) > 0 && (
              <div className="w-48">
                <Seleccao aria-label="Trimestre" value={trimestre?.id ?? ''} onChange={(e) => setParams({ trimestre: e.target.value }, { replace: true })}>
                  {(trimestres.data ?? []).map((x) => <option key={x.id} value={x.id}>{nomeTrimestre(x)}</option>)}
                </Seleccao>
              </div>
            )}>
            {!trimestre ? <EstadoVazio>Ainda não há trimestres criados pela Associação.</EstadoVazio>
              : cts.isPending ? <LinhasACarregar linhas={4} />
              : cts.isError ? <EstadoErro erro={cts.error} aoTentar={() => cts.refetch()} />
              : <FormTrimestre key={`${trimestre.id}-${ct?.id ?? 'novo'}`} classe={classe} trimestre={trimestre} ct={ct} />}
          </Cartao>
        </div>
        <div className="lg:col-span-5">
          <Matriculas classe={classe} />
        </div>
      </div>
      {editar && <DialogoEditar classe={classe} aoFechar={() => setEditar(false)} />}
      <DialogoConfirmar aberto={terminar} aoMudar={setTerminar} perigo titulo={`Terminar a classe ${classe.nome}?`}
        texto="A classe deixa de aparecer nas listas; os relatórios e as matrículas ficam no histórico." accao="Terminar"
        aCorrer={terminarClasse.isPending}
        aoConfirmar={async () => {
          try { await terminarClasse.mutateAsync(classe.id); toast.success('Classe terminada.'); navigate('/escola-sabatina/classes') } catch (e) { toast.error(mensagemDe(e)) }
        }} />
    </>
  )
}

const inteiro = z.coerce.number({ invalid_type_error: 'Escreva um número' }).int('Só números inteiros').min(0, 'Não pode ser negativo').max(9999)
const esquemaCt = z.object({
  professor: z.number().nullable(),
  auxiliar: z.number().nullable(),
  secretario: z.number().nullable(),
  alvoMembros: inteiro,
  alvoEstudo: z.coerce.number({ invalid_type_error: 'Escreva um número' }).min(0, 'Entre 0 e 100').max(100, 'Entre 0 e 100'),
  alvoFiliais: inteiro,
  alvoOferta: z.string().regex(/^\d+(\.\d{1,2})?$/, 'Valor inválido (ex.: 650,00)'),
  alvoBaptismos: inteiro,
  activa: z.boolean(),
})
type ValoresCt = z.infer<typeof esquemaCt>

function FormTrimestre({ classe, trimestre, ct }: { classe: Classe; trimestre: Trimestre; ct?: ClasseTrimestre }) {
  const { pode } = useSessao()
  const basicos = useMembrosBasicos()
  const gravar = useGravarClasseTrimestre()
  const [erro, setErro] = useState<string | null>(null)
  const podeGravar = ct ? pode('escola_sabatina.classe_trimestre.alterar') : pode('escola_sabatina.classe_trimestre.criar')
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }
  const form = useForm<ValoresCt>({
    resolver: zodResolver(esquemaCt),
    defaultValues: {
      professor: ct?.professorMembroId ?? null, auxiliar: ct?.auxiliarMembroId ?? null, secretario: ct?.secretarioMembroId ?? null,
      alvoMembros: ct?.alvoMembros ?? 0, alvoEstudo: Math.round(Number(ct?.alvoEstudoDiario ?? '1') * 100), alvoFiliais: ct?.alvoFiliais ?? 0,
      alvoOferta: ct?.alvoOfertaSabado ?? '0.00', alvoBaptismos: ct?.alvoBaptismos ?? 0, activa: ct ? ct.estado !== 'INACTIVO' : true,
    },
  })
  const e = form.formState.errors
  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    try {
      await gravar.mutateAsync({
        id: ct?.id,
        corpo: {
          classeId: classe.id, trimestreId: trimestre.id,
          professorMembroId: v.professor ?? undefined, auxiliarMembroId: v.auxiliar ?? undefined, secretarioMembroId: v.secretario ?? undefined,
          alvoMembros: v.alvoMembros, alvoEstudoDiario: (v.alvoEstudo / 100).toFixed(4), alvoFiliais: v.alvoFiliais,
          alvoOfertaSabado: v.alvoOferta, alvoBaptismos: v.alvoBaptismos, estado: v.activa ? 'ACTIVO' : 'INACTIVO',
        } as never,
      })
      toast.success(ct ? 'Configuração gravada.' : `Classe configurada para o ${nomeTrimestre(trimestre)}.`)
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })
  const membro = (nome: 'professor' | 'auxiliar' | 'secretario', rotulo: string) => (
    <CampoFormulario rotulo={rotulo} erro={e[nome]?.message}>
      {(p) => <Controller control={form.control} name={nome} render={({ field }) => (
        <CampoMembro id={p.id} valor={field.value} aoMudar={field.onChange} nomeDe={nomeDe} estados={['ACTIVO', 'INTERESSADO']} />
      )} />}
    </CampoFormulario>
  )

  return (
    <form onSubmit={submeter} noValidate className="grid gap-4">
      <ErroFormulario mensagem={erro} />
      {!ct && <p className="rounded-lg border border-warning/30 bg-tint-warning px-4 py-3 text-sm text-warning-text">Esta classe ainda não está configurada para o {nomeTrimestre(trimestre)}.</p>}
      <fieldset disabled={!podeGravar} className="grid gap-4">
        <div className="grid gap-4 sm:grid-cols-3">
          {membro('professor', 'Professor(a)')}
          {membro('auxiliar', 'Auxiliar')}
          {membro('secretario', 'Secretário(a)')}
        </div>
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
          <CampoFormulario rotulo="Alvo de membros" erro={e.alvoMembros?.message}>{(p) => <Input {...p} inputMode="numeric" {...form.register('alvoMembros')} className="num" />}</CampoFormulario>
          <CampoFormulario rotulo="Estudo diário (%)" erro={e.alvoEstudo?.message}>{(p) => <Input {...p} inputMode="numeric" {...form.register('alvoEstudo')} className="num" />}</CampoFormulario>
          <CampoFormulario rotulo="Alvo de filiais" erro={e.alvoFiliais?.message}>{(p) => <Input {...p} inputMode="numeric" {...form.register('alvoFiliais')} className="num" />}</CampoFormulario>
          <CampoFormulario rotulo="Oferta missionária por sábado" erro={e.alvoOferta?.message} className="col-span-2 sm:col-span-2">
            {(p) => <Controller control={form.control} name="alvoOferta" render={({ field }) => <CampoDinheiro {...p} value={field.value} onChange={field.onChange} onBlur={field.onBlur} />} />}
          </CampoFormulario>
          <CampoFormulario rotulo="Alvo de baptismos" erro={e.alvoBaptismos?.message}>{(p) => <Input {...p} inputMode="numeric" {...form.register('alvoBaptismos')} className="num" />}</CampoFormulario>
        </div>
        <label className="alvo flex items-center gap-3 text-sm">
          <input type="checkbox" {...form.register('activa')} className="size-5 accent-[var(--primary)]" />
          <span><span className="font-medium">Classe activa neste trimestre</span><span className="block text-xs text-muted-foreground">Desactivada: não entra na classificação nem nos relatórios em falta.</span></span>
        </label>
      </fieldset>
      {podeGravar && (
        <div className="flex justify-end">
          <Button type="submit" className="alvo min-w-32" disabled={form.formState.isSubmitting}>{form.formState.isSubmitting ? t.comum.aGravar : ct ? t.comum.guardar : 'Configurar'}</Button>
        </div>
      )}
    </form>
  )
}

function Matriculas({ classe }: { classe: Classe }) {
  const { pode } = useSessao()
  const q = useMatriculas(classe.id)
  const basicos = useMembrosBasicos()
  const matricular = useMatricular(classe.id)
  const tirar = useTirarMatricula()
  const [novo, setNovo] = useState<number | null>(null)
  const [aTirar, setATirar] = useState<number | null>(null)
  const [historico, setHistorico] = useState(false)
  const [erro, setErro] = useState<string | null>(null)
  const membros = useMemo(() => new Map((basicos.data ?? []).map((m) => [m.id, m])), [basicos.data])
  const nomeDe = (id: number) => { const m = membros.get(id); return m && `${m.nome} ${m.apelido}` }
  const activas = (q.data ?? []).filter((m) => !m.dataSaida).sort((a, b) => (nomeDe(a.membroId) ?? '').localeCompare(nomeDe(b.membroId) ?? '', 'pt'))
  const antigas = (q.data ?? []).filter((m) => m.dataSaida)

  useEffect(() => {
    if (novo == null) return
    setErro(null)
    matricular.mutateAsync(novo)
      .then(() => toast.success(`${nomeDe(novo) ?? 'Membro'} matriculado(a).`))
      .catch((e) => setErro(mensagemDe(e)))
      .finally(() => setNovo(null))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [novo])

  return (
    <Cartao titulo="Matrículas" icone={Users} descricao={`${activas.length} aluno(s) na classe`}
      accoes={antigas.length > 0 && <Button variant="ghost" size="sm" onClick={() => setHistorico((x) => !x)}>{historico ? 'Ocultar saídas' : `Saídas (${antigas.length})`}</Button>}>
      <div className="grid gap-3">
        <ErroFormulario mensagem={erro} />
        {pode('escola_sabatina.matricula.criar') && (
          <CampoFormulario rotulo="Matricular" ajuda="Membros e interessados; quem está noutra classe tem de sair dela primeiro.">
            {(p) => <CampoMembro id={p.id} valor={novo} aoMudar={setNovo} nomeDe={nomeDe} estados={['ACTIVO', 'INTERESSADO']}
              excluir={activas.map((m) => m.membroId)} vazio={matricular.isPending ? 'A matricular…' : 'Escolher membro ou interessado…'} />}
          </CampoFormulario>
        )}
        {q.isPending ? <LinhasACarregar linhas={3} />
          : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
          : activas.length === 0 ? <EstadoVazio icone={UserPlus}>Ainda ninguém matriculado nesta classe.</EstadoVazio>
          : (
            <Paginada itens={activas}>
              {(visiveis) => <div className="-mx-5 divide-y border-y sm:-mx-6">{visiveis.map((m) => {
                const b = membros.get(m.membroId)
                return (
                  <div key={m.id} className="flex items-center gap-3 px-5 py-2.5 sm:px-6">
                    <Avatar id={m.membroId} nome={b?.nome ?? '?'} apelido={b?.apelido} tamanho={30} />
                    <span className="min-w-0 flex-1">
                      <Link to={`/membros/${m.membroId}`} className="block truncate text-sm font-medium hover:text-primary">{nomeDe(m.membroId) ?? `Membro n.º ${m.membroId}`}</Link>
                      <span className="block text-xs text-muted-foreground">desde {data(m.dataEntrada)}{b?.estado === 'INTERESSADO' && ' · interessado'}</span>
                    </span>
                    {pode('escola_sabatina.matricula.alterar') && (
                      <Button variant="ghost" size="icon" className="size-11" aria-label={`Tirar ${nomeDe(m.membroId) ?? ''} da classe`} onClick={() => setATirar(m.id)}>
                        <UserMinus className="size-4" />
                      </Button>
                    )}
                  </div>
                )
              })}</div>}
            </Paginada>
          )}
        {historico && antigas.length > 0 && (
          <ul className="grid gap-1 text-sm text-muted-foreground">
            {antigas.map((m) => <li key={m.id}>{nomeDe(m.membroId) ?? `Membro n.º ${m.membroId}`} · {data(m.dataEntrada)} – {data(m.dataSaida)} <Pilula variante="secondary">Saiu</Pilula></li>)}
          </ul>
        )}
      </div>
      <DialogoConfirmar aberto={aTirar != null} aoMudar={(v) => !v && setATirar(null)} titulo="Tirar da classe?"
        texto="A matrícula termina hoje e fica no histórico; os relatórios anteriores não mudam." accao="Tirar da classe"
        aCorrer={tirar.isPending}
        aoConfirmar={async () => {
          try { await tirar.mutateAsync(aTirar!); toast.success('Saiu da classe.') } catch (e) { toast.error(mensagemDe(e)) } finally { setATirar(null) }
        }} />
    </Cartao>
  )
}

const esquemaClasse = z.object({
  nome: z.string().trim().min(1, t.comum.obrigatorio).max(100),
  divisao: z.enum(DIVISOES as [Divisao, ...Divisao[]]),
  localReuniao: z.string().trim().max(150),
})

function DialogoEditar({ classe, aoFechar }: { classe: Classe; aoFechar: () => void }) {
  const alterar = useAlterarClasse()
  const [erro, setErro] = useState<string | null>(null)
  const form = useForm<z.infer<typeof esquemaClasse>>({
    resolver: zodResolver(esquemaClasse),
    defaultValues: { nome: classe.nome, divisao: classe.divisao, localReuniao: classe.localReuniao ?? '' },
  })
  const e = form.formState.errors
  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    try {
      await alterar.mutateAsync({ id: classe.id, corpo: { nome: v.nome, divisao: v.divisao, localReuniao: v.localReuniao || undefined } })
      toast.success('Classe alterada.')
      aoFechar()
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <form onSubmit={submeter} noValidate className="grid gap-4">
          <DialogHeader><DialogTitle>Editar a classe</DialogTitle><DialogDescription>Nome, divisão e local de reunião.</DialogDescription></DialogHeader>
          <ErroFormulario mensagem={erro} />
          <CampoFormulario rotulo="Nome" erro={e.nome?.message} obrigatorio>{(p) => <Input {...p} {...form.register('nome')} />}</CampoFormulario>
          <CampoFormulario rotulo="Divisão" erro={e.divisao?.message} obrigatorio>
            {(p) => <Seleccao {...p} {...form.register('divisao')}>{DIVISOES.map((d) => <option key={d} value={d}>{rotulos.divisao[d]}</option>)}</Seleccao>}
          </CampoFormulario>
          <CampoFormulario rotulo="Local de reunião" erro={e.localReuniao?.message}>{(p) => <Input {...p} {...form.register('localReuniao')} />}</CampoFormulario>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={aoFechar}>{t.comum.cancelar}</Button>
            <Button type="submit" disabled={form.formState.isSubmitting}>{form.formState.isSubmitting ? t.comum.aGravar : t.comum.guardar}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
