/**
 * Registar ou editar a ficha do membro, num assistente de 5 passos (Pessoa, Família, Morada, Igreja, Rever).
 * Cada passo valida só o seu formato (Zod) antes de avançar; as regras (encarregado para menores, estado só
 * por movimento, quem pode alterar) são da base de dados e um erro dela leva ao passo do campo em causa.
 * Ao editar, todos os passos ficam abertos e "Guardar" está sempre à mão; envia só os campos alterados (PATCH).
 */
import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ArrowLeft, ArrowRight, Briefcase, Check, Church, ClipboardCheck, IdCard, MapPin, Pencil, UserPen, UserPlus, Users } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Cartao, TituloPagina } from '@/components/comum/elementos'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { Seleccao } from '@/components/comum/Seleccao'
import { CampoData } from '@/components/comum/CampoData'
import { Barra, EstadoErro } from '@/components/comum/estados'
import { useIgreja } from '@/auth/sessao'
import { PROVINCIAS, rotulos, t } from '@/i18n/pt-MZ'
import { data as dataEcra, hojeIso, idade } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useAlterarMembro, useCriarMembro, useMembro, useMembrosBasicos, type Membro } from './api'

const texto = (max: number) => z.string().trim().max(max, `No máximo ${max} caracteres`)
const dataPassada = z.string()
  .refine((d) => d === '' || /^\d{4}-\d{2}-\d{2}$/.test(d), 'Escreva a data como dd/mm/aaaa')
  .refine((d) => !d || d <= hojeIso(), 'A data não pode ser no futuro')

const esquema = z.object({
  nome: texto(100).min(1, t.comum.obrigatorio),
  apelido: texto(100).min(1, t.comum.obrigatorio),
  sexo: z.string(),
  dataNascimento: dataPassada,
  estadoCivil: z.string(),
  tipoIdentificacao: z.string(),
  numeroIdentificacao: texto(30),
  nacionalidade: texto(60),
  naturalidade: texto(150),
  nomePai: texto(150),
  nomeMae: texto(150),
  provincia: texto(60),
  cidadeDistrito: texto(100),
  bairro: texto(100),
  quarteirao: texto(20),
  numeroCasa: texto(20),
  morada: texto(255),
  profissao: texto(100),
  escolaridade: z.string(),
  encarregadoMembroId: z.string(),
  dataEntrada: dataPassada,
  modoEntrada: z.string(),
})
type Valores = z.infer<typeof esquema>

const VAZIO: Valores = {
  nome: '', apelido: '', sexo: '', dataNascimento: '', estadoCivil: '', tipoIdentificacao: '', numeroIdentificacao: '',
  nacionalidade: 'Moçambicana', naturalidade: '', nomePai: '', nomeMae: '', provincia: '', cidadeDistrito: '', bairro: '',
  quarteirao: '', numeroCasa: '', morada: '', profissao: '', escolaridade: '', encarregadoMembroId: '', dataEntrada: '', modoEntrada: '',
}

function paraForm(m: Membro): Valores {
  const v = { ...VAZIO }
  for (const k of Object.keys(VAZIO) as (keyof Valores)[]) {
    const x = (m as Record<string, unknown>)[k]
    v[k] = x == null ? '' : String(x)
  }
  return v
}

/** Valores do formulário → corpo da API: texto vazio é null; o encarregado é um id. */
function paraApi(v: Partial<Valores>): Record<string, unknown> {
  const out: Record<string, unknown> = {}
  for (const [k, x] of Object.entries(v)) {
    const s = typeof x === 'string' ? x.trim() : x
    out[k] = s === '' ? null : k === 'encarregadoMembroId' ? Number(s) : s
  }
  return out
}

/** Os passos do assistente e os campos de cada um (para validar e para saltar ao passo de um erro). */
const PASSOS = [
  { chave: 'pessoa', titulo: 'Pessoa', descricao: 'Identificação, documento e origem', icone: IdCard,
    campos: ['nome', 'apelido', 'sexo', 'dataNascimento', 'estadoCivil', 'tipoIdentificacao', 'numeroIdentificacao', 'nacionalidade', 'naturalidade'] },
  { chave: 'familia', titulo: 'Família', descricao: 'Pai, mãe e encarregado de educação', icone: Users, campos: ['nomePai', 'nomeMae', 'encarregadoMembroId'] },
  { chave: 'morada', titulo: 'Morada', descricao: 'Onde vive', icone: MapPin, campos: ['provincia', 'cidadeDistrito', 'bairro', 'quarteirao', 'numeroCasa', 'morada'] },
  { chave: 'igreja', titulo: 'Igreja', descricao: 'Profissão, escolaridade e entrada na igreja', icone: Church, campos: ['profissao', 'escolaridade', 'dataEntrada', 'modoEntrada'] },
  { chave: 'rever', titulo: 'Rever', descricao: 'Confirmar antes de gravar', icone: ClipboardCheck, campos: [] },
] as const satisfies readonly { chave: string; titulo: string; descricao: string; icone: unknown; campos: readonly (keyof Valores)[] }[]

/** Barra de passos: número e nome de cada passo; no telemóvel, "Passo 2 de 5" e uma barra de progresso. */
function Passos({ actual, feitos, aoEscolher, livre }: { actual: number; feitos: Set<number>; aoEscolher: (i: number) => void; livre: boolean }) {
  return (
    <nav aria-label="Passos do registo" className="rounded-xl border bg-card px-4 py-4 shadow-card sm:px-6">
      <div className="flex items-center justify-between gap-3 text-sm sm:hidden">
        <span className="font-medium">Passo {actual + 1} de {PASSOS.length} · {PASSOS[actual].titulo}</span>
        <span className="text-xs text-muted-foreground">{PASSOS[actual].descricao}</span>
      </div>
      <div className="mt-3 h-1.5 overflow-hidden rounded-full bg-muted sm:hidden" aria-hidden>
        <div className="h-full rounded-full bg-primary transition-[width]" style={{ width: `${((actual + 1) / PASSOS.length) * 100}%` }} />
      </div>
      <ol className="hidden min-w-0 items-center sm:flex">
        {PASSOS.map((p, i) => {
          const feito = feitos.has(i) && i !== actual
          const podeIr = livre || i <= actual || feitos.has(i) || feitos.has(i - 1)
          return (
            <li key={p.chave} className="flex min-w-0 flex-1 items-center last:flex-none">
              <button type="button" disabled={!podeIr} onClick={() => aoEscolher(i)} aria-current={i === actual ? 'step' : undefined}
                className="alvo group flex items-center gap-3 rounded-lg pr-2 text-left disabled:cursor-not-allowed">
                <span className={cn('flex size-9 flex-none items-center justify-center rounded-full border-2 text-sm font-semibold transition-colors',
                  i === actual ? 'border-primary bg-primary text-primary-foreground'
                    : feito ? 'border-primary bg-primary/10 text-primary'
                    : 'border-border text-muted-foreground group-enabled:group-hover:border-primary/50')}>
                  {feito ? <Check className="size-4" /> : i + 1}
                </span>
                <span className={cn('text-sm font-medium whitespace-nowrap', i === actual ? 'text-foreground' : 'text-muted-foreground')}>{p.titulo}</span>
              </button>
              {i < PASSOS.length - 1 && <span aria-hidden className={cn('mx-3 h-0.5 min-w-4 flex-1 rounded-full', feitos.has(i) ? 'bg-primary/60' : 'bg-border')} />}
            </li>
          )
        })}
      </ol>
      <p className="mt-3 hidden text-sm text-muted-foreground sm:block">{PASSOS[actual].descricao}</p>
    </nav>
  )
}

/** Uma linha do resumo: rótulo e valor (ou "—"). */
function Linha({ rotulo, valor }: { rotulo: string; valor?: string | null }) {
  return (
    <div className="grid grid-cols-[minmax(0,10rem)_1fr] gap-3 py-1.5 text-sm">
      <dt className="text-muted-foreground">{rotulo}</dt>
      <dd className={cn('min-w-0 break-words', !valor && 'text-muted-foreground')}>{valor || '—'}</dd>
    </div>
  )
}

function Opcoes({ mapa }: { mapa: Record<string, string> }) {
  return (
    <>
      <option value="">{t.ficha.escolher}</option>
      {Object.entries(mapa).map(([k, r]) => <option key={k} value={k}>{r}</option>)}
    </>
  )
}

export default function PaginaFormMembro() {
  const params = useParams()
  const id = params.id ? Number(params.id) : null
  const igreja = useIgreja()
  const navigate = useNavigate()
  const existente = useMembro(id ?? 0)
  const basicos = useMembrosBasicos()
  const criar = useCriarMembro()
  const alterar = useAlterarMembro(id ?? 0)
  const [erroTopo, setErroTopo] = useState<string | null>(null)
  const [passo, setPasso] = useState(0)
  const [feitos, setFeitos] = useState<Set<number>>(new Set())
  const ultimo = PASSOS.length - 1

  const form = useForm<Valores>({ resolver: zodResolver(esquema), defaultValues: VAZIO })
  const { register, formState: { errors: e, isSubmitting, dirtyFields } } = form

  useEffect(() => {
    if (id && existente.data) form.reset(paraForm(existente.data))
  }, [id, existente.data, form])

  const nasc = form.watch('dataNascimento')
  const anos = /^\d{4}-\d{2}-\d{2}$/.test(nasc) ? idade(nasc) : null
  const candidatosEncarregado = useMemo(
    () => (basicos.data ?? []).filter((b) => b.id !== id && b.estado === 'ACTIVO').sort((a, b) => `${a.nome} ${a.apelido}`.localeCompare(`${b.nome} ${b.apelido}`, 'pt')),
    [basicos.data, id],
  )

  const irPara = (i: number) => {
    setPasso(i)
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
  /** Valida os campos do passo actual; se estiverem certos, marca-o feito e avança. */
  const avancar = async () => {
    const ok = await form.trigger([...PASSOS[passo].campos] as (keyof Valores)[])
    if (!ok) return
    setFeitos((f) => new Set(f).add(passo))
    irPara(Math.min(passo + 1, ultimo))
  }
  /** Um erro (do Zod ou da base de dados) num campo leva ao passo onde esse campo está. */
  const passoDoErro = (campos: string[]) => {
    const i = PASSOS.findIndex((p) => (p.campos as readonly string[]).some((c) => campos.includes(c)))
    if (i >= 0) irPara(i)
  }

  const submeter = form.handleSubmit(async (v) => {
    setErroTopo(null)
    try {
      if (id) {
        const alterados = Object.fromEntries(Object.keys(dirtyFields).map((k) => [k, v[k as keyof Valores]])) as Partial<Valores>
        if (Object.keys(alterados).length) await alterar.mutateAsync(paraApi(alterados) as never)
        toast.success(t.membros.alterado)
        navigate(`/membros/${id}`)
      } else {
        const m = await criar.mutateAsync({ igrejaId: igreja.id, ...paraApi(v) } as never)
        toast.success(t.membros.criado)
        navigate(`/membros/${m.id}`)
      }
    } catch (err) {
      setErroTopo(aplicarErroApi(form, err))
      passoDoErro(Object.keys(form.formState.errors))
      window.scrollTo({ top: 0, behavior: 'smooth' })
    }
  }, (erros) => passoDoErro(Object.keys(erros)))

  // Enter num campo avança o passo (no registo novo); só grava no último passo
  const aoSubmeter = (ev: React.FormEvent) => {
    if (!id && passo < ultimo) { ev.preventDefault(); void avancar(); return }
    void submeter(ev)
  }

  const voltarPara = id ? `/membros/${id}` : '/membros'
  const titulo = id ? t.membros.editarTitulo : t.membros.novo

  if (id && existente.isPending) {
    return <div className="grid gap-4" aria-busy="true" aria-label="A carregar"><Barra className="h-8 w-64" /><Barra className="h-64 w-full" /></div>
  }
  if (id && existente.isError) return <EstadoErro erro={existente.error} aoTentar={() => existente.refetch()} />

  const grade = 'grid gap-x-5 gap-y-4 sm:grid-cols-2 lg:grid-cols-3'
  const v = form.watch()
  const opcao = (mapa: Record<string, string>, k: string) => (k ? mapa[k] ?? k : '')
  const encarregado = candidatosEncarregado.find((b) => String(b.id) === v.encarregadoMembroId)
  const Seccao = ({ i, children }: { i: number; children: React.ReactNode }) => (
    <section className="rounded-lg border">
      <div className="flex items-center justify-between gap-3 border-b px-4 py-2.5">
        <h3 className="text-sm font-semibold">{PASSOS[i].titulo}</h3>
        <Button type="button" variant="ghost" size="sm" onClick={() => irPara(i)}><Pencil className="size-3.5" />Alterar</Button>
      </div>
      <dl className="px-4 py-2">{children}</dl>
    </section>
  )
  const mostra = (i: number) => (passo === i ? undefined : 'hidden')

  return (
    <form onSubmit={aoSubmeter} noValidate>
      <TituloPagina
        antes={
          <Link to={voltarPara} className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground">
            <ArrowLeft className="size-4" /> {id && existente.data ? `${existente.data.nome} ${existente.data.apelido}` : t.membros.titulo}
          </Link>
        }
        icone={id ? UserPen : UserPlus}
        titulo={titulo}
        descricao={id ? `Ficha no livro de membros de ${igreja.nome}` : `${igreja.nome} · o registo fica por aprovar pelo secretário`}
      />

      <div className="grid gap-6">
        <Passos actual={passo} feitos={feitos} aoEscolher={irPara} livre={!!id} />
        <ErroFormulario mensagem={erroTopo} />

        {/* os passos ficam todos montados (só se escondem): os valores e as validações não se perdem */}
        <div className={cn('grid gap-6', mostra(0))}>
        <Cartao titulo={t.ficha.identificacao} descricao="Nome, data de nascimento e estado civil" icone={IdCard}>
          <div className={grade}>
            <CampoFormulario rotulo={t.ficha.nome} erro={e.nome?.message} obrigatorio>
              {(p) => <Input {...p} {...register('nome')} autoComplete="given-name" className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.apelido} erro={e.apelido?.message} obrigatorio>
              {(p) => <Input {...p} {...register('apelido')} autoComplete="family-name" className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.sexo} erro={e.sexo?.message}>
              {(p) => <Seleccao {...p} {...register('sexo')}><Opcoes mapa={rotulos.sexo} /></Seleccao>}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.dataNascimento} erro={e.dataNascimento?.message} ajuda={anos != null ? `${anos} anos` : undefined}>
              {(p) => <Controller control={form.control} name="dataNascimento" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.estadoCivil} erro={e.estadoCivil?.message}>
              {(p) => <Seleccao {...p} {...register('estadoCivil')}><Opcoes mapa={rotulos.estadoCivil} /></Seleccao>}
            </CampoFormulario>
          </div>
        </Cartao>

        <Cartao titulo={t.ficha.documento} descricao="Documento de identificação e onde nasceu" icone={IdCard}>
          <div className={grade}>
            <CampoFormulario rotulo={t.ficha.tipoIdentificacao} erro={e.tipoIdentificacao?.message}>
              {(p) => <Seleccao {...p} {...register('tipoIdentificacao')}><Opcoes mapa={rotulos.tipoIdentificacao} /></Seleccao>}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.numeroIdentificacao} erro={e.numeroIdentificacao?.message}>
              {(p) => <Input {...p} {...register('numeroIdentificacao')} autoComplete="off" className="alvo num uppercase" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.nacionalidade} erro={e.nacionalidade?.message}>
              {(p) => <Input {...p} {...register('nacionalidade')} className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.naturalidade} erro={e.naturalidade?.message} className="sm:col-span-2 lg:col-span-1">
              {(p) => <Input {...p} {...register('naturalidade')} placeholder="ex.: Xai-Xai, Gaza" className="alvo" />}
            </CampoFormulario>
          </div>
        </Cartao>

        </div>

        <div className={cn('grid gap-6', mostra(1))}>
        <Cartao titulo={t.ficha.filiacao} descricao="Nomes do pai e da mãe" icone={Users}>
          <div className="grid gap-x-5 gap-y-4 sm:grid-cols-2">
            <CampoFormulario rotulo={t.ficha.nomePai} erro={e.nomePai?.message}>
              {(p) => <Input {...p} {...register('nomePai')} className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.nomeMae} erro={e.nomeMae?.message}>
              {(p) => <Input {...p} {...register('nomeMae')} className="alvo" />}
            </CampoFormulario>
          </div>
        </Cartao>
        <Cartao titulo="Encarregado de educação" descricao="Obrigatório para menores de 18 anos (a base de dados confirma)" icone={Users}>
          <div className="grid gap-x-5 gap-y-4 sm:grid-cols-2">
            <CampoFormulario rotulo={t.ficha.encarregado} erro={e.encarregadoMembroId?.message}
              ajuda={anos != null && anos < 18 ? `${t.ficha.encarregadoAjuda} Este membro tem ${anos} anos.` : t.ficha.encarregadoAjuda}>
              {(p) => (
                <Seleccao {...p} {...register('encarregadoMembroId')} disabled={basicos.isPending}>
                  <option value="">{basicos.isPending ? 'A carregar…' : t.ficha.nenhum}</option>
                  {candidatosEncarregado.map((b) => <option key={b.id} value={b.id}>{b.nome} {b.apelido}</option>)}
                </Seleccao>
              )}
            </CampoFormulario>
          </div>
        </Cartao>
        </div>

        <div className={cn('grid gap-6', mostra(2))}>

        <Cartao titulo={t.ficha.moradaTitulo} descricao="Onde vive: permite encontrar o membro e fazer relatórios por bairro" icone={MapPin}>
          <div className={grade}>
            <CampoFormulario rotulo={t.ficha.provincia} erro={e.provincia?.message}>
              {(p) => (
                <Seleccao {...p} {...register('provincia')}>
                  <option value="">{t.ficha.escolher}</option>
                  {PROVINCIAS.map((pr) => <option key={pr} value={pr}>{pr}</option>)}
                </Seleccao>
              )}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.cidadeDistrito} erro={e.cidadeDistrito?.message}>
              {(p) => <Input {...p} {...register('cidadeDistrito')} className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.bairro} erro={e.bairro?.message}>
              {(p) => <Input {...p} {...register('bairro')} className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.quarteirao} erro={e.quarteirao?.message}>
              {(p) => <Input {...p} {...register('quarteirao')} inputMode="numeric" className="alvo num" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.numeroCasa} erro={e.numeroCasa?.message}>
              {(p) => <Input {...p} {...register('numeroCasa')} className="alvo num" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.morada} erro={e.morada?.message} ajuda="Como chegar: perto de quê, rua, avenida.">
              {(p) => <Input {...p} {...register('morada')} className="alvo" />}
            </CampoFormulario>
          </div>
        </Cartao>

        </div>

        <div className={cn('grid gap-6', mostra(3))}>
        <Cartao titulo={t.ficha.vida} descricao="Profissão e escolaridade" icone={Briefcase}>
          <div className={grade}>
            <CampoFormulario rotulo={t.ficha.profissao} erro={e.profissao?.message}>
              {(p) => <Input {...p} {...register('profissao')} className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.escolaridade} erro={e.escolaridade?.message}>
              {(p) => <Seleccao {...p} {...register('escolaridade')}><Opcoes mapa={rotulos.escolaridade} /></Seleccao>}
            </CampoFormulario>
          </div>
        </Cartao>

        <Cartao titulo={t.ficha.igreja} descricao="Como e quando entrou nesta igreja" icone={Church}>
          <div className={grade}>
            <CampoFormulario rotulo={t.ficha.dataEntrada} erro={e.dataEntrada?.message} ajuda="Data do voto de admissão nesta igreja.">
              {(p) => <Controller control={form.control} name="dataEntrada" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.modoEntrada} erro={e.modoEntrada?.message}>
              {(p) => (
                <Seleccao {...p} {...register('modoEntrada')}>
                  <option value="">{t.ficha.escolher}</option>
                  {(['BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE', 'TRANSFERENCIA_ENTRADA'] as const).map((k) => <option key={k} value={k}>{rotulos.modoEntrada[k]}</option>)}
                </Seleccao>
              )}
            </CampoFormulario>
          </div>
        </Cartao>

        </div>

        {passo === ultimo && (
          <Cartao titulo="Rever o registo" descricao={id ? 'Confira as alterações e guarde.' : 'Confira os dados; o registo fica por aprovar pelo secretário.'} icone={ClipboardCheck}>
            <div className="grid gap-4 lg:grid-cols-2">
              <Seccao i={0}>
                <Linha rotulo={t.ficha.nome} valor={`${v.nome} ${v.apelido}`.trim()} />
                <Linha rotulo={t.ficha.sexo} valor={opcao(rotulos.sexo, v.sexo)} />
                <Linha rotulo={t.ficha.dataNascimento} valor={v.dataNascimento ? `${dataEcra(v.dataNascimento)}${anos != null ? ` (${anos} anos)` : ''}` : ''} />
                <Linha rotulo={t.ficha.estadoCivil} valor={opcao(rotulos.estadoCivil, v.estadoCivil)} />
                <Linha rotulo={t.ficha.tipoIdentificacao} valor={[opcao(rotulos.tipoIdentificacao, v.tipoIdentificacao), v.numeroIdentificacao].filter(Boolean).join(' · ')} />
                <Linha rotulo={t.ficha.nacionalidade} valor={v.nacionalidade} />
                <Linha rotulo={t.ficha.naturalidade} valor={v.naturalidade} />
              </Seccao>
              <Seccao i={1}>
                <Linha rotulo={t.ficha.nomePai} valor={v.nomePai} />
                <Linha rotulo={t.ficha.nomeMae} valor={v.nomeMae} />
                <Linha rotulo={t.ficha.encarregado} valor={encarregado ? `${encarregado.nome} ${encarregado.apelido}` : ''} />
              </Seccao>
              <Seccao i={2}>
                <Linha rotulo={t.ficha.provincia} valor={v.provincia} />
                <Linha rotulo={t.ficha.cidadeDistrito} valor={v.cidadeDistrito} />
                <Linha rotulo={t.ficha.bairro} valor={[v.bairro, v.quarteirao && `quarteirão ${v.quarteirao}`, v.numeroCasa && `casa ${v.numeroCasa}`].filter(Boolean).join(' · ')} />
                <Linha rotulo={t.ficha.morada} valor={v.morada} />
              </Seccao>
              <Seccao i={3}>
                <Linha rotulo={t.ficha.profissao} valor={v.profissao} />
                <Linha rotulo={t.ficha.escolaridade} valor={opcao(rotulos.escolaridade, v.escolaridade)} />
                <Linha rotulo={t.ficha.dataEntrada} valor={v.dataEntrada ? dataEcra(v.dataEntrada) : ''} />
                <Linha rotulo={t.ficha.modoEntrada} valor={opcao(rotulos.modoEntrada, v.modoEntrada)} />
              </Seccao>
            </div>
          </Cartao>
        )}

        <div className="sticky bottom-0 -mx-4 flex items-center gap-2 border-t bg-background/95 px-4 py-3 backdrop-blur sm:static sm:mx-0 sm:border-0 sm:bg-transparent sm:p-0 sm:backdrop-blur-none">
          <Button asChild variant="ghost" className="alvo mr-auto"><Link to={voltarPara}>{t.comum.cancelar}</Link></Button>
          {passo > 0 && <Button type="button" variant="outline" className="alvo" onClick={() => irPara(passo - 1)}><ArrowLeft className="size-4" />Anterior</Button>}
          {passo < ultimo && <Button type="button" variant={id ? 'outline' : 'default'} className="alvo min-w-28" onClick={() => void avancar()}>Seguinte<ArrowRight className="size-4" /></Button>}
          {(passo === ultimo || id) && (
            <Button type="submit" disabled={isSubmitting} className="alvo min-w-32">{isSubmitting ? t.comum.aGravar : id ? t.comum.guardar : t.membros.registar}</Button>
          )}
        </div>
      </div>
    </form>
  )
}
