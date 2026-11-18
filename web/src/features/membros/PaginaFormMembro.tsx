/**
 * Registar ou editar a ficha do membro (F-SEC-01, V33), em 6 secções e a revisão:
 *   Dados pessoais · Dados familiares · Contactos e residência · Profissão e estudos · Religião e baptismo ·
 *   Participação na igreja · Rever.
 * Cada secção valida só o formato (Zod) antes de avançar; as regras (encarregado para menores, cônjuge já ligado,
 * datas, quem pode alterar) são da base de dados e um erro dela leva à secção do campo.
 * Ao editar, todas as secções ficam abertas e "Guardar" está sempre à mão; envia só o que mudou.
 * Campos condicionais (casamento, baptismo anterior) escondem-se mas não se apagam: o que já estava gravado fica.
 * Registos parecidos (mesmo documento, nome e data de nascimento) aparecem como aviso: quem regista confirma que é
 * outra pessoa; não há bloqueio automático só pelo nome.
 * V43: o registo novo começa pela procura (/membros/novo → PaginaProcurarMembro): esta ficha só abre depois dela e vem
 * com o que se procurou. O mesmo membro já registado (existe = true: mesmo documento, ou mesmo nome e data de
 * nascimento, em qualquer igreja) não se grava outra vez — a base de dados também o recusa.
 */
import { useEffect, useMemo, useState } from 'react'
import { Link, Navigate, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import {
  AlertTriangle, ArrowLeft, ArrowRight, Briefcase, Check, Church, ClipboardCheck, Droplets, Heart, IdCard, MapPin, Pencil, Phone,
  UserPen, UserPlus,
} from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Cartao, Pilula, TituloPagina } from '@/components/comum/elementos'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { Seleccao } from '@/components/comum/Seleccao'
import { CampoData } from '@/components/comum/CampoData'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { Barra, EstadoErro } from '@/components/comum/estados'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { PROVINCIAS, rotulos, t } from '@/i18n/pt-MZ'
import { data as dataEcra, hojeIso, idade } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import {
  contactoDoTipo, gravarBaptismosFicha, gravarContactosFicha, useAlterarMembro, useBaptismos, useContactos, useCriarMembro,
  useInvalidarFicha, useMembro, useMembrosBasicos, useParecidos, type Membro, type MembroParecido,
} from './api'

const texto = (max: number) => z.string().trim().max(max, `No máximo ${max} caracteres`)
const ISO = /^\d{4}-\d{2}-\d{2}$/
const dataPassada = z.string()
  .refine((d) => d === '' || ISO.test(d), 'Escreva a data como dd/mm/aaaa')
  .refine((d) => !d || d <= hojeIso(), 'A data não pode ser no futuro')
const TELEFONE = /^\+?\d[\d\s]{7,16}$/
const telefone = texto(30).refine((v) => !v || TELEFONE.test(v), 'Escreva o número com o indicativo, por exemplo +258 84 123 4567')
const OUTRA = 'outra'
/** Sugestões para "Como conheceu a mensagem" (texto livre: pode escrever outra). */
const METODOS_CONVERSAO = ['Estudo bíblico', 'Campanha de evangelismo', 'Família', 'Amigo ou vizinho', 'Escola Sabatina',
  'Pequeno grupo', 'Rádio ou televisão', 'Literatura', 'Internet e redes sociais']

const esquema = z.object({
  // pessoais
  nome: texto(100).min(1, t.comum.obrigatorio),
  apelido: texto(100).min(1, t.comum.obrigatorio),
  sexo: z.string(),
  dataNascimento: dataPassada,
  naturalidade: texto(150),
  nacionalidade: texto(60),
  tipoIdentificacao: z.string(),
  numeroIdentificacao: texto(30),
  outroDocumento: texto(100),
  // familiares
  estadoCivil: z.string(),
  dataCasamento: dataPassada,
  conjugeMembroId: z.string(),
  nomeConjuge: texto(150),
  dependentes: z.string().refine((v) => v === '' || (/^\d+$/.test(v) && Number(v) <= 50), 'Um número de 0 a 50'),
  nomePai: texto(150),
  nomeMae: texto(150),
  encarregadoMembroId: z.string(),
  // contactos e residência (os contactos ficam na tabela de contactos)
  telemovel: telefone,
  telefoneFixo: telefone,
  email: texto(150).refine((v) => !v || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v), 'Endereço de e-mail inválido'),
  provincia: texto(60),
  cidadeDistrito: texto(100),
  bairro: texto(100),
  quarteirao: texto(20),
  numeroCasa: texto(20),
  morada: texto(255),
  enderecoPostal: texto(150),
  codigoPostal: texto(20),
  // profissão e estudos
  profissao: texto(100),
  localTrabalho: texto(150),
  escolaridade: z.string(),
  // religião e baptismo (o baptismo fica na tabela de baptismos)
  religiaoAnterior: texto(100),
  metodoConversao: texto(100),
  exMembro: z.boolean(),
  dataBaptismoAnterior: dataPassada,
  dataBaptismo: dataPassada,
  igrejaBaptismo: z.string(),
  localBaptismo: texto(150),
  oficiante: texto(150),
  // participação
  dataEntrada: dataPassada,
  modoEntrada: z.string(),
}).superRefine((v, ctx) => {
  const doc = v.numeroIdentificacao.replace(/\s/g, '')
  if (doc && v.tipoIdentificacao === 'BI' && !/^\d{12}[A-Za-z]$/.test(doc)) {
    ctx.addIssue({ code: 'custom', path: ['numeroIdentificacao'], message: 'O BI tem 12 algarismos e uma letra, ex.: 110100000000A' })
  }
  if (doc && v.tipoIdentificacao === 'PASSAPORTE' && !/^[A-Za-z0-9]{6,12}$/.test(doc)) {
    ctx.addIssue({ code: 'custom', path: ['numeroIdentificacao'], message: 'O passaporte tem de 6 a 12 letras ou algarismos' })
  }
  if (doc && !v.tipoIdentificacao) {
    ctx.addIssue({ code: 'custom', path: ['tipoIdentificacao'], message: 'Escolha o tipo de documento' })
  }
  if (v.dataCasamento && v.dataNascimento && v.dataCasamento <= v.dataNascimento) {
    ctx.addIssue({ code: 'custom', path: ['dataCasamento'], message: 'A data do casamento tem de ser depois da data de nascimento' })
  }
  if (!v.dataBaptismo && (v.localBaptismo || v.oficiante)) {
    ctx.addIssue({ code: 'custom', path: ['dataBaptismo'], message: 'Indique a data do baptismo' })
  }
  if (v.dataBaptismo && v.dataNascimento && v.dataBaptismo <= v.dataNascimento) {
    ctx.addIssue({ code: 'custom', path: ['dataBaptismo'], message: 'O baptismo tem de ser depois do nascimento' })
  }
  if (v.exMembro && v.dataBaptismoAnterior && v.dataBaptismo && v.dataBaptismoAnterior >= v.dataBaptismo) {
    ctx.addIssue({ code: 'custom', path: ['dataBaptismoAnterior'], message: 'O baptismo anterior tem de ser antes do actual' })
  }
})
type Valores = z.infer<typeof esquema>
type Chave = keyof Valores

const VAZIO: Valores = {
  nome: '', apelido: '', sexo: '', dataNascimento: '', naturalidade: '', nacionalidade: 'Moçambicana', tipoIdentificacao: '',
  numeroIdentificacao: '', outroDocumento: '', estadoCivil: '', dataCasamento: '', conjugeMembroId: '', nomeConjuge: '',
  dependentes: '', nomePai: '', nomeMae: '', encarregadoMembroId: '', telemovel: '', telefoneFixo: '', email: '', provincia: '',
  cidadeDistrito: '', bairro: '', quarteirao: '', numeroCasa: '', morada: '', enderecoPostal: '', codigoPostal: '', profissao: '',
  localTrabalho: '', escolaridade: '', religiaoAnterior: '', metodoConversao: '', exMembro: false, dataBaptismoAnterior: '',
  dataBaptismo: '', igrejaBaptismo: '', localBaptismo: '', oficiante: '', dataEntrada: '', modoEntrada: '',
}

/** Campos que não são da tabela do membro: contactos e baptismo gravam-se nas tabelas próprias. */
const CONTACTOS: Chave[] = ['telemovel', 'telefoneFixo', 'email']
const BAPTISMO: Chave[] = ['dataBaptismoAnterior', 'dataBaptismo', 'igrejaBaptismo', 'localBaptismo', 'oficiante']
const FORA_DO_MEMBRO = new Set<Chave>([...CONTACTOS, ...BAPTISMO])
const IDS = new Set<Chave>(['encarregadoMembroId', 'conjugeMembroId', 'dependentes'])

function paraForm(m: Membro): Valores {
  const v = { ...VAZIO }
  for (const k of Object.keys(VAZIO) as Chave[]) {
    if (FORA_DO_MEMBRO.has(k)) continue
    const x = (m as Record<string, unknown>)[k]
    if (k === 'exMembro') v.exMembro = x === true
    else (v as Record<string, unknown>)[k] = x == null ? '' : String(x)
  }
  return v
}

/** Valores do formulário → corpo da API (só os campos do membro): texto vazio é null; ids e números são números. */
function paraApi(v: Partial<Valores>): Record<string, unknown> {
  const out: Record<string, unknown> = {}
  for (const [k, x] of Object.entries(v) as [Chave, unknown][]) {
    if (FORA_DO_MEMBRO.has(k)) continue
    const s = typeof x === 'string' ? x.trim() : x
    out[k] = s === '' ? null : IDS.has(k) ? Number(s) : k === 'numeroIdentificacao' && typeof s === 'string' ? s.toUpperCase() : s
  }
  return out
}

/** As secções e os campos de cada uma (para validar e para saltar à secção de um erro). */
const PASSOS = [
  { chave: 'pessoal', titulo: 'Dados pessoais', descricao: 'Nome, nascimento e documentos', icone: IdCard,
    campos: ['nome', 'apelido', 'sexo', 'dataNascimento', 'naturalidade', 'nacionalidade', 'tipoIdentificacao', 'numeroIdentificacao', 'outroDocumento'] },
  { chave: 'familia', titulo: 'Dados familiares', descricao: 'Estado civil, cônjuge, pais e encarregado', icone: Heart,
    campos: ['estadoCivil', 'dataCasamento', 'conjugeMembroId', 'nomeConjuge', 'dependentes', 'nomePai', 'nomeMae', 'encarregadoMembroId'] },
  { chave: 'contactos', titulo: 'Contactos e residência', descricao: 'Telefones, e-mail e morada', icone: Phone,
    campos: ['telemovel', 'telefoneFixo', 'email', 'provincia', 'cidadeDistrito', 'bairro', 'quarteirao', 'numeroCasa', 'morada', 'enderecoPostal', 'codigoPostal'] },
  { chave: 'profissao', titulo: 'Profissão e estudos', descricao: 'Profissão, trabalho e nível académico', icone: Briefcase,
    campos: ['profissao', 'localTrabalho', 'escolaridade'] },
  { chave: 'religiao', titulo: 'Religião e baptismo', descricao: 'Conversão e baptismo', icone: Droplets,
    campos: ['religiaoAnterior', 'metodoConversao', 'exMembro', 'dataBaptismoAnterior', 'dataBaptismo', 'igrejaBaptismo', 'localBaptismo', 'oficiante'] },
  { chave: 'igreja', titulo: 'Participação na igreja', descricao: 'Entrada nesta igreja', icone: Church, campos: ['dataEntrada', 'modoEntrada'] },
  { chave: 'rever', titulo: 'Rever', descricao: 'Confirmar antes de gravar', icone: ClipboardCheck, campos: [] },
] as const satisfies readonly { chave: string; titulo: string; descricao: string; icone: unknown; campos: readonly Chave[] }[]

/**
 * Secções do registo. No computador: coluna lateral fixa com as secções (feita / em curso / por fazer) e o
 * progresso. No telemóvel: cabeçalho compacto "Secção 2 de 7" com a barra de progresso.
 */
function Passos({ actual, feitos, aoEscolher, livre }: { actual: number; feitos: Set<number>; aoEscolher: (i: number) => void; livre: boolean }) {
  const total = PASSOS.length
  const pct = Math.round(((actual + 1) / total) * 100)
  const podeIr = (i: number) => livre || i <= actual || feitos.has(i) || feitos.has(i - 1)
  const P = PASSOS[actual]
  return (
    <>
      <nav aria-label="Secções da ficha" className="rounded-xl border bg-card p-4 shadow-card lg:hidden">
        <div className="flex items-center gap-3">
          <span className="flex size-10 flex-none items-center justify-center rounded-full bg-primary text-primary-foreground"><P.icone className="size-5" /></span>
          <div className="min-w-0 flex-1">
            <p className="text-xs font-medium text-muted-foreground">Secção {actual + 1} de {total}</p>
            <p className="truncate font-semibold">{P.titulo}</p>
          </div>
          <span className="text-xs font-medium text-muted-foreground tabular-nums">{pct}%</span>
        </div>
        <div className="mt-3 flex gap-1" aria-hidden>
          {PASSOS.map((x, i) => <span key={x.chave} className={cn('h-1.5 flex-1 rounded-full', i <= actual ? 'bg-primary' : feitos.has(i) ? 'bg-primary/40' : 'bg-muted')} />)}
        </div>
        {livre && (
          <div className="-mx-1 mt-3 flex gap-1 overflow-x-auto pb-1">
            {PASSOS.map((x, i) => (
              <button key={x.chave} type="button" onClick={() => aoEscolher(i)} aria-current={i === actual ? 'step' : undefined}
                className={cn('alvo flex-none rounded-full border px-3 text-xs font-medium', i === actual ? 'border-primary bg-primary text-primary-foreground' : 'bg-card text-muted-foreground')}>
                {x.titulo}
              </button>
            ))}
          </div>
        )}
      </nav>

      <nav aria-label="Secções da ficha" className="hidden rounded-xl border bg-card p-5 shadow-card lg:sticky lg:top-[calc(var(--header-height)+1.5rem)] lg:block">
        <p className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Progresso</p>
        <div className="mt-2 flex items-baseline justify-between text-sm">
          <span className="font-medium">Secção {actual + 1} de {total}</span>
          <span className="text-muted-foreground tabular-nums">{pct}%</span>
        </div>
        <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-muted" aria-hidden>
          <div className="h-full rounded-full bg-primary transition-[width] duration-300" style={{ width: `${pct}%` }} />
        </div>
        <ol className="mt-6">
          {PASSOS.map((x, i) => {
            const emCurso = i === actual
            const feito = feitos.has(i) && !emCurso
            return (
              <li key={x.chave} className="relative pb-4 last:pb-0">
                {i < total - 1 && <span aria-hidden className={cn('absolute top-10 bottom-0 left-[19px] w-0.5 rounded-full', feito ? 'bg-primary/50' : 'bg-border')} />}
                <button type="button" disabled={!podeIr(i)} onClick={() => aoEscolher(i)} aria-current={emCurso ? 'step' : undefined}
                  className={cn('alvo group relative flex w-full items-start gap-3 rounded-lg p-1 text-left transition-colors disabled:cursor-not-allowed',
                    emCurso ? 'bg-accent/60' : 'enabled:hover:bg-muted/60')}>
                  <span className={cn('flex size-8 flex-none items-center justify-center rounded-full border-2 text-sm font-semibold transition-colors',
                    emCurso || feito ? 'border-primary bg-primary text-primary-foreground' : 'border-border bg-card text-muted-foreground',
                    emCurso && 'shadow-sm ring-4 ring-primary/15')}>
                    {feito ? <Check className="size-4" /> : emCurso ? <x.icone className="size-4" /> : i + 1}
                  </span>
                  <span className="min-w-0 pt-0.5">
                    <span className={cn('block text-sm font-semibold', emCurso || feito ? 'text-foreground' : 'text-muted-foreground')}>{x.titulo}</span>
                    <span className="block text-xs leading-snug text-muted-foreground">{x.descricao}</span>
                  </span>
                </button>
              </li>
            )
          })}
        </ol>
      </nav>
    </>
  )
}

/** No computador, por cima do formulário: a secção em curso. */
function CabecalhoPasso({ passo }: { passo: number }) {
  const P = PASSOS[passo]
  return (
    <header className="hidden items-center gap-3 border-b pb-4 lg:flex">
      <span className="flex size-10 flex-none items-center justify-center rounded-lg bg-accent text-accent-foreground"><P.icone className="size-5" /></span>
      <div>
        <p className="text-xs font-medium text-muted-foreground">Secção {passo + 1} de {PASSOS.length}</p>
        <h2 className="text-lg font-semibold tracking-tight">{P.titulo} <span className="font-normal text-muted-foreground">· {P.descricao}</span></h2>
      </div>
    </header>
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

/** O valor depois de o utilizador parar de escrever (para não pedir à API a cada tecla). */
function useAtrasado<T>(valor: T, ms = 600): T {
  const [v, setV] = useState(valor)
  useEffect(() => {
    const id = setTimeout(() => setV(valor), ms)
    return () => clearTimeout(id)
  }, [valor, ms])
  return v
}

/**
 * Aviso de registos parecidos (V33). Prováveis (70 pontos ou mais: mesmo documento, ou nome e data de nascimento)
 * pedem a confirmação de que é outra pessoa; possíveis (só o nome) são informação. Nada é bloqueado.
 */
function AvisoParecidos({ lista, confirmado, aoConfirmar, editar }: {
  lista: MembroParecido[]; confirmado: boolean; aoConfirmar: (v: boolean) => void; editar: boolean
}) {
  const { igrejas } = useSessao()
  if (lista.length === 0) return null
  const existe = lista.some((p) => p.existe)
  const provaveis = !existe && lista.some((p) => p.pontos >= 70)
  return (
    <section role={existe || provaveis ? 'alert' : 'status'}
      className={cn('rounded-xl border p-4', existe ? 'border-destructive/40 bg-tint-destructive' : provaveis ? 'border-warning/40 bg-tint-warning' : 'border-border bg-muted/40')}>
      <div className="flex items-start gap-3">
        <AlertTriangle className={cn('mt-0.5 size-5 flex-none', existe ? 'text-destructive-text' : provaveis ? 'text-warning-text' : 'text-muted-foreground')} aria-hidden />
        <div className="min-w-0 flex-1">
          <h3 className="text-sm font-semibold">{existe ? 'Este membro já existe' : provaveis ? 'Pode ser alguém que já está registado' : 'Há registos com nome parecido'}</h3>
          <p className="mt-0.5 text-sm text-muted-foreground">
            {existe ? `Mesmo documento, ou mesmo nome e data de nascimento: não se ${editar ? 'guarda' : 'regista'} outra vez. Use o registo existente (ou peça a transferência à igreja onde está).`
              : `Confira antes de ${editar ? 'guardar' : 'registar'}: um segundo registo da mesma pessoa divide o histórico dela.`}
          </p>
          <ul className="mt-3 grid gap-2">
            {lista.map((p, i) => (
              <li key={p.membroId ?? `f${i}`} className="flex flex-wrap items-center gap-x-3 gap-y-1 rounded-lg border bg-card px-3 py-2 text-sm">
                {p.membroId != null
                  ? <Link to={`/membros/${p.membroId}`} target="_blank" className="font-medium hover:text-primary hover:underline">{p.nome}</Link>
                  : <span className="font-medium">{p.nome}</span>}
                <span className="text-muted-foreground">
                  {[p.dataNascimento && dataEcra(p.dataNascimento), p.numeroIdentificacao, p.igreja ?? igrejas.find((x) => x.id === p.igrejaId)?.nome,
                    p.estado && rotulos.estadoMembro[p.estado]].filter(Boolean).join(' · ')}
                </span>
                <span className="flex flex-wrap gap-1">
                  {p.motivos.map((m) => <Pilula key={m} variante={p.existe ? 'destructive' : p.pontos >= 70 ? 'warning' : 'secondary'}>{m}</Pilula>)}
                </span>
              </li>
            ))}
          </ul>
          {provaveis && (
            <label className="alvo mt-3 flex items-center gap-2 text-sm font-medium">
              <input type="checkbox" checked={confirmado} onChange={(e) => aoConfirmar(e.target.checked)} className="size-4 accent-[var(--primary)]" />
              Conferi: é outra pessoa
            </label>
          )}
        </div>
      </div>
    </section>
  )
}

export default function PaginaFormMembro() {
  const params = useParams()
  const id = params.id ? Number(params.id) : null
  const igreja = useIgreja()
  const { igrejas } = useSessao()
  const navigate = useNavigate()
  const [qs] = useSearchParams()
  // registo novo: só depois da procura (V43), com o que se procurou
  const procurado = qs.get('procurado') === '1'
  const daProcura = { nome: qs.get('nome') ?? '', apelido: qs.get('apelido') ?? '', dataNascimento: qs.get('dataNascimento') ?? '',
    naturalidade: qs.get('naturalidade') ?? '', numeroIdentificacao: qs.get('numeroIdentificacao') ?? '' }
  const confirmadoNaProcura = qs.get('confirmado') === '1'
  const existente = useMembro(id ?? 0)
  const contactos = useContactos(id ?? 0)
  const baptismos = useBaptismos(id ?? 0)
  const basicos = useMembrosBasicos()
  const criar = useCriarMembro()
  const alterar = useAlterarMembro(id ?? 0)
  const invalidarFicha = useInvalidarFicha()
  const [erroTopo, setErroTopo] = useState<string | null>(null)
  const [passo, setPasso] = useState(0)
  const [feitos, setFeitos] = useState<Set<number>>(new Set())
  const [confirmouOutra, setConfirmouOutra] = useState(false)
  const ultimo = PASSOS.length - 1

  const form = useForm<Valores>({ resolver: zodResolver(esquema), defaultValues: { ...VAZIO, ...(id ? {} : daProcura), igrejaBaptismo: String(igreja.id) } })
  const { register, formState: { errors: e, isSubmitting, dirtyFields } } = form

  // carrega a ficha (membro, contactos e baptismos) uma vez, quando tudo chega; "form" não entra nas dependências:
  // no React Hook Form 7.54 é um objecto novo sempre que o estado muda, e cada mudança voltava a repor os dados antigos
  const { reset } = form
  useEffect(() => {
    if (!id || !existente.data || !contactos.data || !baptismos.data) return
    const v = paraForm(existente.data)
    v.telemovel = contactoDoTipo(contactos.data, 'TELEFONE')?.valor ?? ''
    v.telefoneFixo = contactoDoTipo(contactos.data, 'TELEFONE_FIXO')?.valor ?? ''
    v.email = contactoDoTipo(contactos.data, 'EMAIL')?.valor ?? ''
    const original = baptismos.data.find((b) => !b.rebaptismo)
    const actual = v.exMembro ? baptismos.data.find((b) => b.rebaptismo) : original
    if (v.exMembro) v.dataBaptismoAnterior = original?.data ?? ''
    v.dataBaptismo = actual?.data ?? ''
    v.igrejaBaptismo = actual ? (actual.localIgrejaId ? String(actual.localIgrejaId) : OUTRA) : String(igreja.id)
    v.localBaptismo = actual?.local ?? ''
    v.oficiante = actual?.oficiante ?? ''
    reset(v)
  }, [id, existente.data, contactos.data, baptismos.data, reset, igreja.id])

  const v = form.watch()
  const anos = ISO.test(v.dataNascimento) ? idade(v.dataNascimento) : null
  const ordenar = (a: { nome: string; apelido: string }, b: { nome: string; apelido: string }) => `${a.nome} ${a.apelido}`.localeCompare(`${b.nome} ${b.apelido}`, 'pt')
  const candidatosEncarregado = useMemo(
    () => (basicos.data ?? []).filter((b) => b.id !== id && b.estado === 'ACTIVO').sort(ordenar),
    [basicos.data, id],
  )
  // não se oferece como cônjuge quem já está ligado a outra pessoa (a base de dados também o recusa)
  const ocupados = useMemo(
    () => (basicos.data ?? []).filter((b) => b.conjugeMembroId != null && b.conjugeMembroId !== id).map((b) => b.id),
    [basicos.data, id],
  )
  const nomeDe = (mid: number) => { const b = basicos.data?.find((x) => x.id === mid); return b ? `${b.nome} ${b.apelido}` : undefined }

  // possíveis duplicados: só procura depois de parar de escrever
  const chaveParecidos = useAtrasado({ nome: v.nome, apelido: v.apelido, dataNascimento: v.dataNascimento, naturalidade: v.naturalidade, numeroIdentificacao: v.numeroIdentificacao })
  const parecidos = useParecidos({ ...chaveParecidos, excluirId: id })
  const listaParecidos = parecidos.data ?? []
  const jaExiste = listaParecidos.some((p) => p.existe)
  const provaveis = !jaExiste && listaParecidos.some((p) => p.pontos >= 70)
  // o "é outra pessoa" confirmado na procura vale enquanto os dados forem os mesmos que se procuraram
  const mesmosDaProcura = [v.nome.trim(), v.apelido.trim(), v.dataNascimento, v.numeroIdentificacao.trim()].join('|')
    === [daProcura.nome, daProcura.apelido, daProcura.dataNascimento, daProcura.numeroIdentificacao].join('|')
  useEffect(() => { setConfirmouOutra(!id && confirmadoNaProcura && mesmosDaProcura) }, [parecidos.data]) // eslint-disable-line react-hooks/exhaustive-deps

  const casado = v.estadoCivil === 'CASADO' || v.estadoCivil === 'UNIAO_FACTO'
  const mostraCasamento = casado || !!(v.dataCasamento || v.conjugeMembroId || v.nomeConjuge)   // nada se esconde se já tiver valor
  const mostraAnterior = v.exMembro || !!v.dataBaptismoAnterior

  const irPara = (i: number) => {
    setPasso(i)
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
  /** Valida os campos da secção actual; se estiverem certos, marca-a feita e avança. */
  const avancar = async () => {
    const ok = await form.trigger([...PASSOS[passo].campos] as Chave[])
    if (!ok) return
    setFeitos((f) => new Set(f).add(passo))
    irPara(Math.min(passo + 1, ultimo))
  }
  /** Um erro (do Zod ou da base de dados) num campo leva à secção onde esse campo está. */
  const passoDoErro = (campos: string[]) => {
    const i = PASSOS.findIndex((p) => (p.campos as readonly string[]).some((c) => campos.includes(c)))
    if (i >= 0) irPara(i)
  }

  const baptismoDoForm = (x: Valores) => ({
    data: x.dataBaptismo,
    localIgrejaId: x.igrejaBaptismo && x.igrejaBaptismo !== OUTRA ? Number(x.igrejaBaptismo) : null,
    local: x.localBaptismo.trim(),
    oficiante: x.oficiante.trim(),
  })
  const contactosDoForm = (x: Valores) => ({ TELEFONE: x.telemovel, TELEFONE_FIXO: x.telefoneFixo, EMAIL: x.email })

  const submeter = form.handleSubmit(async (x) => {
    setErroTopo(null)
    if (jaExiste) {
      setErroTopo('Este membro já existe (veja a lista em "Dados pessoais"): abra o registo existente em vez de criar outro.')
      irPara(0)
      return
    }
    if (provaveis && !confirmouOutra) {
      setErroTopo('Há um registo que pode ser desta pessoa. Confira a lista em "Dados pessoais" e marque "Conferi: é outra pessoa" para continuar.')
      irPara(0)
      return
    }
    let membroId = id
    try {
      if (id) {
        const alterados = Object.fromEntries((Object.keys(dirtyFields) as Chave[]).filter((k) => !FORA_DO_MEMBRO.has(k)).map((k) => [k, x[k]])) as Partial<Valores>
        if (Object.keys(alterados).length) await alterar.mutateAsync(paraApi(alterados) as never)
      } else {
        const m = await criar.mutateAsync({ igrejaId: igreja.id, ...paraApi(x) } as never)
        membroId = m.id
      }
    } catch (err) {
      setErroTopo(aplicarErroApi(form, err))
      passoDoErro(Object.keys(form.formState.errors))
      window.scrollTo({ top: 0, behavior: 'smooth' })
      return
    }
    // contactos e baptismo: tabelas próprias; se falharem, a ficha já está gravada e o erro diz o que faltou
    const mid = membroId as number
    const sujos = Object.keys(dirtyFields) as Chave[]
    const avisos: string[] = []
    if (!id || sujos.some((k) => CONTACTOS.includes(k))) {
      try { await gravarContactosFicha(mid, igreja.id, contactos.data ?? [], contactosDoForm(x)) } catch (err) { avisos.push(`Contactos: ${mensagemDe(err)}`) }
    }
    if ((!id && (x.dataBaptismo || x.dataBaptismoAnterior)) || sujos.some((k) => BAPTISMO.includes(k) || k === 'exMembro')) {
      try { await gravarBaptismosFicha(mid, baptismos.data ?? [], x.exMembro, baptismoDoForm(x), x.dataBaptismoAnterior) } catch (err) { avisos.push(`Baptismo: ${mensagemDe(err)}`) }
    }
    invalidarFicha(mid)
    if (avisos.length) toast.warning(`${id ? 'Ficha actualizada' : 'Membro registado'}, mas falta gravar — ${avisos.join(' · ')}`, { duration: 10_000 })
    else toast.success(id ? t.membros.alterado : t.membros.criado)
    navigate(`/membros/${mid}`)
  }, (erros) => passoDoErro(Object.keys(erros)))

  // Enter num campo avança a secção (no registo novo); só grava na última
  const aoSubmeter = (ev: React.FormEvent) => {
    if (!id && passo < ultimo) { ev.preventDefault(); void avancar(); return }
    void submeter(ev)
  }

  const voltarPara = id ? `/membros/${id}` : '/membros/novo'
  const titulo = id ? t.membros.editarTitulo : t.membros.novo

  if (!id && !procurado) return <Navigate to="/membros/novo" replace />
  if (id && (existente.isPending || contactos.isPending || baptismos.isPending)) {
    return <div className="grid gap-4" aria-busy="true" aria-label="A carregar"><Barra className="h-8 w-64" /><Barra className="h-64 w-full" /></div>
  }
  const erroCarga = existente.error ?? contactos.error ?? baptismos.error
  if (id && erroCarga) return <EstadoErro erro={erroCarga} aoTentar={() => { void existente.refetch(); void contactos.refetch(); void baptismos.refetch() }} />

  const grade = 'grid gap-x-5 gap-y-4 sm:grid-cols-2 lg:grid-cols-3'
  const opcao = (mapa: Record<string, string>, k: string) => (k ? mapa[k] ?? k : '')
  const encarregado = candidatosEncarregado.find((b) => String(b.id) === v.encarregadoMembroId)
  const nomeIgrejaBaptismo = v.igrejaBaptismo === OUTRA ? '' : igrejas.find((i) => String(i.id) === v.igrejaBaptismo)?.nome
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
  const data = (k: Chave) => (p: { id: string; 'aria-invalid': boolean; 'aria-describedby'?: string }) =>
    <Controller control={form.control} name={k} render={({ field }) => <CampoData {...p} {...field} value={field.value as string} className="alvo" />} />

  return (
    <form onSubmit={aoSubmeter} noValidate>
      <TituloPagina
        antes={
          <Link to={voltarPara} className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground">
            <ArrowLeft className="size-4" /> {id && existente.data ? `${existente.data.nome} ${existente.data.apelido}` : id ? t.membros.titulo : 'Voltar à procura'}
          </Link>
        }
        icone={id ? UserPen : UserPlus}
        titulo={titulo}
        descricao={id ? `Ficha no livro de membros de ${igreja.nome}` : `${igreja.nome} · o registo fica por aprovar pelo secretário`}
      />

      <div className="grid items-start gap-6 lg:grid-cols-[17rem_minmax(0,1fr)]">
        <Passos actual={passo} feitos={feitos} aoEscolher={irPara} livre={!!id} />
        <div className="grid min-w-0 gap-6">
        <CabecalhoPasso passo={passo} />
        <ErroFormulario mensagem={erroTopo} />

        {/* as secções ficam todas montadas (só se escondem): os valores e as validações não se perdem */}
        <div className={cn('grid gap-6', mostra(0))}>
          <Cartao titulo={t.ficha.identificacao} descricao="Nome e nascimento" icone={IdCard}>
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
                {data('dataNascimento')}
              </CampoFormulario>
              <CampoFormulario rotulo="Local de nascimento" erro={e.naturalidade?.message}>
                {(p) => <Input {...p} {...register('naturalidade')} placeholder="ex.: Xai-Xai, Gaza" className="alvo" />}
              </CampoFormulario>
              <CampoFormulario rotulo={t.ficha.nacionalidade} erro={e.nacionalidade?.message}>
                {(p) => <Input {...p} {...register('nacionalidade')} className="alvo" />}
              </CampoFormulario>
            </div>
          </Cartao>
          <Cartao titulo="Documentos" descricao="Documento de identificação e outro, se tiver" icone={IdCard}>
            <div className={grade}>
              <CampoFormulario rotulo={t.ficha.tipoIdentificacao} erro={e.tipoIdentificacao?.message}>
                {(p) => <Seleccao {...p} {...register('tipoIdentificacao')}><Opcoes mapa={rotulos.tipoIdentificacao} /></Seleccao>}
              </CampoFormulario>
              <CampoFormulario rotulo={t.ficha.numeroIdentificacao} erro={e.numeroIdentificacao?.message}
                ajuda={v.tipoIdentificacao === 'BI' ? '12 algarismos e uma letra' : undefined}>
                {(p) => <Input {...p} {...register('numeroIdentificacao')} autoComplete="off" className="alvo num uppercase" />}
              </CampoFormulario>
              <CampoFormulario rotulo={t.ficha.outroDocumento} erro={e.outroDocumento?.message} ajuda="Tipo e número, ex.: NUIT 400123456">
                {(p) => <Input {...p} {...register('outroDocumento')} autoComplete="off" className="alvo" />}
              </CampoFormulario>
            </div>
          </Cartao>
          <AvisoParecidos lista={listaParecidos} confirmado={confirmouOutra} aoConfirmar={setConfirmouOutra} editar={!!id} />
        </div>

        <div className={cn('grid gap-6', mostra(1))}>
          <Cartao titulo="Estado civil e cônjuge" descricao="Se o cônjuge for membro, escolha-o: os dois registos ficam ligados" icone={Heart}>
            <div className={grade}>
              <CampoFormulario rotulo={t.ficha.estadoCivil} erro={e.estadoCivil?.message}>
                {(p) => <Seleccao {...p} {...register('estadoCivil')}><Opcoes mapa={rotulos.estadoCivil} /></Seleccao>}
              </CampoFormulario>
              <CampoFormulario rotulo={t.ficha.dependentes} erro={e.dependentes?.message} ajuda="Filhos ou outras pessoas a cargo">
                {(p) => <Input {...p} {...register('dependentes')} inputMode="numeric" className="alvo num" />}
              </CampoFormulario>
            </div>
            {mostraCasamento && (
              <div className={cn(grade, 'mt-5 border-t pt-5')}>
                <CampoFormulario rotulo={t.ficha.dataCasamento} erro={e.dataCasamento?.message}>{data('dataCasamento')}</CampoFormulario>
                <CampoFormulario rotulo={t.ficha.conjuge} erro={e.conjugeMembroId?.message}
                  ajuda={v.conjugeMembroId ? 'O registo do cônjuge também fica ligado a este.' : 'Procure pelo nome; se não for membro, escreva o nome ao lado.'}>
                  {(p) => (
                    <Controller control={form.control} name="conjugeMembroId" render={({ field }) => (
                      <CampoMembro id={p.id} valor={field.value ? Number(field.value) : null} aoMudar={(n) => field.onChange(n == null ? '' : String(n))}
                        nomeDe={nomeDe} estados={['ACTIVO', 'INTERESSADO']} excluir={[...(id ? [id] : []), ...ocupados]} vazio="Procurar membro…" />
                    )} />
                  )}
                </CampoFormulario>
                {!v.conjugeMembroId && (
                  <CampoFormulario rotulo={t.ficha.nomeConjuge} erro={e.nomeConjuge?.message} ajuda="Só se não for membro desta igreja.">
                    {(p) => <Input {...p} {...register('nomeConjuge')} className="alvo" />}
                  </CampoFormulario>
                )}
              </div>
            )}
          </Cartao>
          <Cartao titulo={t.ficha.filiacao} descricao="Pais e encarregado de educação" icone={Heart}>
            <div className={grade}>
              <CampoFormulario rotulo={t.ficha.nomePai} erro={e.nomePai?.message}>
                {(p) => <Input {...p} {...register('nomePai')} className="alvo" />}
              </CampoFormulario>
              <CampoFormulario rotulo={t.ficha.nomeMae} erro={e.nomeMae?.message}>
                {(p) => <Input {...p} {...register('nomeMae')} className="alvo" />}
              </CampoFormulario>
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
          <Cartao titulo="Contactos" descricao="O telemóvel recebe os SMS (lembretes das escalas e recibos)" icone={Phone}>
            <div className={grade}>
              <CampoFormulario rotulo={t.ficha.telemovel} erro={e.telemovel?.message}>
                {(p) => <Input {...p} {...register('telemovel')} inputMode="tel" autoComplete="tel" placeholder="+258 84 123 4567" className="alvo num" />}
              </CampoFormulario>
              <CampoFormulario rotulo={t.ficha.telefoneFixo} erro={e.telefoneFixo?.message}>
                {(p) => <Input {...p} {...register('telefoneFixo')} inputMode="tel" placeholder="+258 21 123 456" className="alvo num" />}
              </CampoFormulario>
              <CampoFormulario rotulo={t.ficha.email} erro={e.email?.message}>
                {(p) => <Input {...p} {...register('email')} inputMode="email" autoComplete="email" className="alvo" />}
              </CampoFormulario>
            </div>
            {id && <p className="mt-4 text-xs text-muted-foreground">Mudar um contacto guarda o anterior no histórico. WhatsApp e outros contactos gerem-se na ficha.</p>}
          </Cartao>
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
              <CampoFormulario rotulo={t.ficha.enderecoPostal} erro={e.enderecoPostal?.message} ajuda="Caixa postal ou endereço para correspondência">
                {(p) => <Input {...p} {...register('enderecoPostal')} className="alvo" />}
              </CampoFormulario>
              <CampoFormulario rotulo={t.ficha.codigoPostal} erro={e.codigoPostal?.message}>
                {(p) => <Input {...p} {...register('codigoPostal')} className="alvo num" />}
              </CampoFormulario>
            </div>
          </Cartao>
        </div>

        <div className={cn('grid gap-6', mostra(3))}>
          <Cartao titulo="Profissão e estudos" descricao="O que faz, onde trabalha e até onde estudou" icone={Briefcase}>
            <div className={grade}>
              <CampoFormulario rotulo={t.ficha.profissao} erro={e.profissao?.message}>
                {(p) => <Input {...p} {...register('profissao')} className="alvo" />}
              </CampoFormulario>
              <CampoFormulario rotulo={t.ficha.localTrabalho} erro={e.localTrabalho?.message}>
                {(p) => <Input {...p} {...register('localTrabalho')} placeholder="Empresa ou instituição" className="alvo" />}
              </CampoFormulario>
              <CampoFormulario rotulo="Nível académico" erro={e.escolaridade?.message}>
                {(p) => <Seleccao {...p} {...register('escolaridade')}><Opcoes mapa={rotulos.escolaridade} /></Seleccao>}
              </CampoFormulario>
            </div>
          </Cartao>
        </div>

        <div className={cn('grid gap-6', mostra(4))}>
          <Cartao titulo="Conversão" descricao="De onde veio e como conheceu a mensagem" icone={Droplets}>
            <div className={grade}>
              <CampoFormulario rotulo={t.ficha.religiaoAnterior} erro={e.religiaoAnterior?.message}>
                {(p) => <Input {...p} {...register('religiaoAnterior')} placeholder="ex.: Católica, nenhuma" className="alvo" />}
              </CampoFormulario>
              <CampoFormulario rotulo={t.ficha.metodoConversao} erro={e.metodoConversao?.message} ajuda="Escolha da lista ou escreva">
                {(p) => <Input {...p} {...register('metodoConversao')} list="metodos-conversao" className="alvo" />}
              </CampoFormulario>
              <datalist id="metodos-conversao">{METODOS_CONVERSAO.map((m) => <option key={m} value={m} />)}</datalist>
            </div>
            <div className="mt-5 grid gap-4 border-t pt-5">
              <label className="alvo flex items-center gap-2 text-sm font-medium">
                <input type="checkbox" {...register('exMembro')} className="size-4 accent-[var(--primary)]" />
                {t.ficha.exMembro}
              </label>
              {mostraAnterior && (
                <div className={grade}>
                  <CampoFormulario rotulo={t.ficha.dataBaptismoAnterior} erro={e.dataBaptismoAnterior?.message}
                    ajuda="O baptismo de agora fica registado como rebaptismo.">
                    {data('dataBaptismoAnterior')}
                  </CampoFormulario>
                </div>
              )}
            </div>
          </Cartao>
          <Cartao titulo={v.exMembro ? 'Rebaptismo' : 'Baptismo'} descricao="Data, local e ministro que oficiou (a entrada no livro faz-se depois, com o voto)" icone={Droplets}>
            <div className={grade}>
              <CampoFormulario rotulo={t.ficha.dataBaptismo} erro={e.dataBaptismo?.message}>{data('dataBaptismo')}</CampoFormulario>
              <CampoFormulario rotulo={t.ficha.igrejaBaptismo} erro={e.igrejaBaptismo?.message}>
                {(p) => (
                  <Seleccao {...p} {...register('igrejaBaptismo')}>
                    {igrejas.map((i) => <option key={i.id} value={i.id}>{i.nome}</option>)}
                    <option value={OUTRA}>{t.baptismo.outraIgreja}</option>
                  </Seleccao>
                )}
              </CampoFormulario>
              <CampoFormulario rotulo={t.ficha.localBaptismo} erro={e.localBaptismo?.message} ajuda="ex.: Rio Matola, baptistério da igreja">
                {(p) => <Input {...p} {...register('localBaptismo')} className="alvo" />}
              </CampoFormulario>
              <CampoFormulario rotulo={t.ficha.oficiante} erro={e.oficiante?.message} ajuda="Nome do pastor ordenado que oficiou">
                {(p) => <Input {...p} {...register('oficiante')} className="alvo" />}
              </CampoFormulario>
            </div>
          </Cartao>
        </div>

        <div className={cn('grid gap-6', mostra(5))}>
          <Cartao titulo="Participação na igreja" descricao="Como e quando entrou nesta igreja" icone={Church}>
            <div className={grade}>
              <CampoFormulario rotulo={t.ficha.dataEntrada} erro={e.dataEntrada?.message} ajuda="Data do voto de admissão nesta igreja.">
                {data('dataEntrada')}
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
            <dl className="mt-5 grid gap-x-6 gap-y-3 border-t pt-5 text-sm sm:grid-cols-2">
              <div><dt className="text-muted-foreground">Igreja ou grupo</dt><dd className="font-medium">{igreja.nome}</dd></div>
              <div><dt className="text-muted-foreground">Cargos, classe da Escola Sabatina e família</dt>
                <dd>Vêm dos respectivos módulos (mandatos, Escola Sabatina, famílias) e aparecem na ficha.</dd></div>
            </dl>
          </Cartao>
        </div>

        {passo === ultimo && (
          <Cartao titulo="Rever a ficha" descricao={id ? 'Confira as alterações e guarde.' : 'Confira os dados; o registo fica por aprovar pelo secretário.'} icone={ClipboardCheck}>
            <div className="grid gap-4 lg:grid-cols-2">
              <Seccao i={0}>
                <Linha rotulo={t.ficha.nome} valor={`${v.nome} ${v.apelido}`.trim()} />
                <Linha rotulo={t.ficha.sexo} valor={opcao(rotulos.sexo, v.sexo)} />
                <Linha rotulo={t.ficha.dataNascimento} valor={v.dataNascimento ? `${dataEcra(v.dataNascimento)}${anos != null ? ` (${anos} anos)` : ''}` : ''} />
                <Linha rotulo="Local de nascimento" valor={v.naturalidade} />
                <Linha rotulo={t.ficha.tipoIdentificacao} valor={[opcao(rotulos.tipoIdentificacao, v.tipoIdentificacao), v.numeroIdentificacao.toUpperCase()].filter(Boolean).join(' · ')} />
                <Linha rotulo={t.ficha.outroDocumento} valor={v.outroDocumento} />
              </Seccao>
              <Seccao i={1}>
                <Linha rotulo={t.ficha.estadoCivil} valor={opcao(rotulos.estadoCivil, v.estadoCivil)} />
                {mostraCasamento && <Linha rotulo="Casamento" valor={[v.dataCasamento && dataEcra(v.dataCasamento), v.conjugeMembroId ? nomeDe(Number(v.conjugeMembroId)) : v.nomeConjuge].filter(Boolean).join(' · ')} />}
                <Linha rotulo={t.ficha.dependentes} valor={v.dependentes} />
                <Linha rotulo="Pais" valor={[v.nomePai, v.nomeMae].filter(Boolean).join(' · ')} />
                <Linha rotulo={t.ficha.encarregado} valor={encarregado ? `${encarregado.nome} ${encarregado.apelido}` : ''} />
              </Seccao>
              <Seccao i={2}>
                <Linha rotulo="Telefones" valor={[v.telemovel, v.telefoneFixo].filter(Boolean).join(' · ')} />
                <Linha rotulo={t.ficha.email} valor={v.email} />
                <Linha rotulo={t.ficha.bairro} valor={[v.bairro, v.quarteirao && `quarteirão ${v.quarteirao}`, v.numeroCasa && `casa ${v.numeroCasa}`, v.cidadeDistrito, v.provincia].filter(Boolean).join(' · ')} />
                <Linha rotulo={t.ficha.enderecoPostal} valor={[v.enderecoPostal, v.codigoPostal].filter(Boolean).join(' · ')} />
              </Seccao>
              <Seccao i={3}>
                <Linha rotulo={t.ficha.profissao} valor={v.profissao} />
                <Linha rotulo={t.ficha.localTrabalho} valor={v.localTrabalho} />
                <Linha rotulo="Nível académico" valor={opcao(rotulos.escolaridade, v.escolaridade)} />
              </Seccao>
              <Seccao i={4}>
                <Linha rotulo={t.ficha.religiaoAnterior} valor={v.religiaoAnterior} />
                <Linha rotulo={t.ficha.metodoConversao} valor={v.metodoConversao} />
                {mostraAnterior && <Linha rotulo={t.ficha.dataBaptismoAnterior} valor={v.dataBaptismoAnterior ? dataEcra(v.dataBaptismoAnterior) : ''} />}
                <Linha rotulo={v.exMembro ? 'Rebaptismo' : 'Baptismo'}
                  valor={[v.dataBaptismo && dataEcra(v.dataBaptismo), nomeIgrejaBaptismo, v.localBaptismo, v.oficiante].filter(Boolean).join(' · ')} />
              </Seccao>
              <Seccao i={5}>
                <Linha rotulo={t.ficha.dataEntrada} valor={v.dataEntrada ? dataEcra(v.dataEntrada) : ''} />
                <Linha rotulo={t.ficha.modoEntrada} valor={opcao(rotulos.modoEntrada, v.modoEntrada)} />
              </Seccao>
            </div>
            {listaParecidos.length > 0 && <div className="mt-4"><AvisoParecidos lista={listaParecidos} confirmado={confirmouOutra} aoConfirmar={setConfirmouOutra} editar={!!id} /></div>}
          </Cartao>
        )}

        <div className="sticky bottom-0 -mx-4 flex items-center gap-2 border-t bg-background/95 px-4 py-3 backdrop-blur sm:static sm:mx-0 sm:bg-transparent sm:px-0 sm:pt-5 sm:pb-0 sm:backdrop-blur-none">
          <Button asChild variant="ghost" className="alvo mr-auto"><Link to={voltarPara}>{t.comum.cancelar}</Link></Button>
          {passo > 0 && <Button type="button" variant="outline" className="alvo" onClick={() => irPara(passo - 1)}><ArrowLeft className="size-4" /><span className="hidden sm:inline">Anterior</span></Button>}
          {passo < ultimo && <Button type="button" variant={id ? 'outline' : 'default'} className="alvo min-w-28" onClick={() => void avancar()}>Seguinte<ArrowRight className="size-4" /></Button>}
          {(passo === ultimo || id) && (
            <Button type="submit" disabled={isSubmitting} className="alvo min-w-32">{isSubmitting ? t.comum.aGravar : id ? t.comum.guardar : t.membros.registar}</Button>
          )}
        </div>
        </div>
      </div>
    </form>
  )
}
