/**
 * Lançar entrada (P-06 passos 2 e 3) · os dízimos e ofertas de um membro (com recibo numerado) ou as ofertas da salva
 * (sem nome). Pensada para o sábado, envelope a envelope, e para os comprovativos que chegam durante a semana:
 *
 * 1. Quem contribui: o membro, ou as ofertas da salva.
 * 2. Como entregou: uma escolha por conta real (envelope em numerário no caixa; M-Pesa ou depósito na conta da igreja;
 *    depósito ou M-Pesa directamente na Missão). A forma de pagamento sai da conta, não se escolhe à parte.
 *    O que não é numerário pede o comprovativo: referência e a descrição que o membro mandou.
 * 3. Valores: dízimo e oferta em destaque; os outros fundos recolhidos.
 *
 * O que foi pago na Missão (V21) só aceita fundos da Missão e a referência; conta como contribuição do membro e como já
 * remetido, e não entra no saldo da igreja. A soma das linhas = total, e o resto das regras, são da base de dados.
 */
import { useMemo, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { Controller, useFieldArray, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ArrowLeft, Banknote, Paperclip, ChevronDown, FileCheck2, HandCoins, HandHeart, Landmark, Plus, Receipt, Smartphone, UserRound, Users, Wallet } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Cartao, Dinheiro, TituloPagina } from '@/components/comum/elementos'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { Seleccao } from '@/components/comum/Seleccao'
import { Barra, EstadoErro } from '@/components/comum/estados'
import { useSessao } from '@/auth/sessao'
import { mensagemDe } from '@/api/erros'
import { t } from '@/i18n/pt-MZ'
import { centimos, data as dataEcra, deCentimos, dinheiro, hojeIso } from '@/lib/formatos'
import { useMembrosBasicos } from '@/features/membros/api'
import { cn } from '@/lib/utils'
import { CATEGORIA_POR_FUNDO, carregarComprovativo, daMissao, useCategorias, useContagens, useContas, useContribuicoesDoAno, useCriarMovimento, useFundos, type Conta } from './api'
import { CampoComprovativo } from './Comprovativos'
import { parteDoFundo } from './comum'

const valorApi = /^\d{1,14}(\.\d{1,2})?$/
const esquema = z.object({
  contaId: z.string().min(1, 'Diga como o dinheiro foi entregue'),
  metodo: z.string().min(1),
  data: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Escreva a data como dd/mm/aaaa').refine((d) => d <= hojeIso(), 'A data não pode ser no futuro'),
  hora: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'Hora como 10:00'),
  membro: z.number().nullable(),
  contagemId: z.string(),
  referencia: z.string().trim().max(100),
  descricao: z.string().trim().max(255),
  recibo: z.boolean(),
  linhas: z.array(z.object({ fundoId: z.number(), categoriaId: z.string(), valor: z.string().refine((v) => v === '' || valorApi.test(v), 'Valor inválido') })),
}).refine((v) => v.linhas.some((l) => l.valor && centimos(l.valor) > 0), { path: ['linhas'], message: 'Escreva o valor de pelo menos um fundo' })
type Valores = z.infer<typeof esquema>

export const METODO_DA_CONTA: Record<string, string> = { CAIXA: 'NUMERARIO', MPESA: 'MPESA', EMOLA: 'EMOLA', BANCO: 'BANCO' }
/** Os fundos de quase todos os envelopes: ficam em destaque; os outros abrem-se em "Outros fundos". */
const PRINCIPAIS = ['DIZIMO', 'OFERTA_COMBINADA']

/** Como o membro entregou, dito pela conta onde o dinheiro está. */
function comoEntregou(c: Conta) {
  const missao = daMissao(c)
  switch (c.tipo) {
    case 'CAIXA': return { titulo: 'Envelope em numerário', I: Banknote }
    case 'MPESA': return { titulo: missao ? 'M-Pesa da Missão' : 'M-Pesa da igreja', I: Smartphone }
    case 'EMOLA': return { titulo: missao ? 'e-Mola da Missão' : 'e-Mola da igreja', I: Smartphone }
    default: return { titulo: missao ? 'Depósito na conta da Missão' : 'Depósito na conta da igreja', I: Landmark }
  }
}
const detalheConta = (c: Conta) => [c.nome === comoEntregou(c).titulo ? null : c.nome, c.banco, c.numero].filter(Boolean).filter((x, i, l) => l.indexOf(x) === i).join(' · ')

interface Lancada { id: number; quem: string; como: string; valor: string; recibo?: string; comprovativo?: boolean }

export default function PaginaEntrada() {
  const navigate = useNavigate()
  const { pode } = useSessao()
  const contas = useContas()
  const fundos = useFundos()
  const categorias = useCategorias()
  const basicos = useMembrosBasicos()
  const criar = useCriarMovimento()
  const contagens = useContagens()
  const contribuicoes = useContribuicoesDoAno(Number(hojeIso().slice(0, 4)))
  const [chave, setChave] = useState(() => crypto.randomUUID())
  const [erro, setErro] = useState<string | null>(null)
  const [sessao, setSessao] = useState<Lancada[]>([])
  const [params] = useSearchParams()
  const [verCategorias, setVerCategorias] = useState(false)
  const [verOutros, setVerOutros] = useState(false)
  const [salva, setSalva] = useState(false)          // ofertas sem nome (salva): só em numerário
  const [comprovativo, setComprovativo] = useState<File | null>(null)   // fotografia/PDF: enviado depois de gravar

  const todas = (contas.data ?? []).filter((c) => !c.endDate)
  // o envelope em numerário primeiro: é o mais comum
  const daIgreja = todas.filter((c) => !daMissao(c)).sort((a, b) => Number(b.tipo === 'CAIXA') - Number(a.tipo === 'CAIXA'))
  const naMissaoContas = todas.filter((c) => daMissao(c))
  // por defeito: o caixa (envelopes do sábado); com ?onde=missao, a primeira conta da Missão
  // ?conta= (vindo da ficha de um movimento: "lançar outra entrada" do mesmo membro, da mesma forma)
  const pedida = todas.find((c) => String(c.id) === params.get('conta'))
  const inicial = pedida ?? (params.get('onde') === 'missao' ? naMissaoContas[0] : daIgreja.find((c) => c.tipo === 'CAIXA') ?? daIgreja[0])
  const membroPedido = Number(params.get('membro')) || null

  const receitas = (categorias.data ?? []).filter((c) => c.tipo === 'RECEITA')
  const catPorCodigo = new Map(receitas.map((c) => [c.codigo, c.id]))
  const linhasIniciais = useMemo(() => (fundos.data ?? []).filter((f) => !f.endDate).map((f) => ({
    fundoId: f.id, categoriaId: String(catPorCodigo.get(CATEGORIA_POR_FUNDO[f.tipo] ?? 'R9') ?? receitas[0]?.id ?? ''), valor: '',
  // eslint-disable-next-line react-hooks/exhaustive-deps
  })), [fundos.data, categorias.data])

  const form = useForm<Valores>({
    resolver: zodResolver(esquema),
    values: {
      contaId: inicial ? String(inicial.id) : '', metodo: METODO_DA_CONTA[inicial?.tipo ?? 'CAIXA'],
      data: hojeIso(), hora: new Date().toTimeString().slice(0, 5), membro: membroPedido, contagemId: '', referencia: '', descricao: '', recibo: true, linhas: linhasIniciais,
    },
    resetOptions: { keepDirtyValues: true },
  })
  const { fields } = useFieldArray({ control: form.control, name: 'linhas' })
  const linhas = form.watch('linhas')
  const membro = form.watch('membro')
  const e = form.formState.errors
  const contagensAbertas = (contagens.data ?? []).filter((c) => c.estado === 'ABERTA' && !c.endDate)
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }
  const fundoPorId = new Map((fundos.data ?? []).map((f) => [f.id, f]))
  const conta = todas.find((c) => String(c.id) === form.watch('contaId'))
  const naMissao = !!conta && daMissao(conta)
  const numerario = conta?.tipo === 'CAIXA'
  const anonimo = salva && !naMissao
  /** Na conta da Missão só entram os fundos dessa entidade (a base de dados recusa os outros). */
  const fundoVisivel = (id: number) => {
    if (!naMissao) return true
    const f = fundoPorId.get(id)
    return !!f && f.destinoEntidadeId === conta?.entidadeId && Number(f.percentagemRemessa ?? 0) > 0
  }
  const valido = (v: string) => valorApi.test(v)
  const total = linhas.reduce((s, l) => s + (valido(l.valor) && fundoVisivel(l.fundoId) ? centimos(l.valor) : 0), 0)
  // quanto vai para a Missão (percentagem de cada fundo) e quanto fica na igreja
  const paraMissao = linhas.reduce((s, l) => {
    const f = fundoPorId.get(l.fundoId)
    return s + (valido(l.valor) && fundoVisivel(l.fundoId) && f?.destinoEntidadeId ? Math.round(centimos(l.valor) * Number(f.percentagemRemessa ?? 0) / 100) : 0)
  }, 0)
  const indices = fields.map((f, i) => ({ f, i, fundo: fundoPorId.get(f.fundoId) })).filter((x) => fundoVisivel(x.f.fundoId))
  const principais = indices.filter((x) => PRINCIPAIS.includes(x.fundo?.tipo ?? ''))
  const outros = indices.filter((x) => !PRINCIPAIS.includes(x.fundo?.tipo ?? ''))
  const outrosComValor = outros.filter((x) => valido(linhas[x.i]?.valor ?? '') && centimos(linhas[x.i].valor) > 0).length
  const abertosOutros = verOutros || outrosComValor > 0 || principais.length === 0

  // o que o membro escolhido já deu este ano
  const doMembro = (contribuicoes.data ?? []).filter((c) => c.membroId === membro)
  const anoMembro = doMembro.reduce((s, c) => s + centimos(c.valor), 0)
  const ultima = [...doMembro].sort((a, b) => b.dataHora.localeCompare(a.dataHora))[0]
  const totalSessao = sessao.reduce((s, x) => s + centimos(x.valor), 0)

  const escolherConta = (c: Conta) => {
    form.setValue('contaId', String(c.id), { shouldDirty: true })
    form.setValue('metodo', METODO_DA_CONTA[c.tipo ?? 'CAIXA'], { shouldDirty: true })
    if (c.tipo !== 'CAIXA') form.setValue('contagemId', '')
    form.clearErrors(['contaId', 'referencia'])
    setErro(null)
  }
  const escolherSalva = (sim: boolean) => {
    setSalva(sim)
    form.clearErrors('membro')
    if (!sim) return
    form.setValue('membro', null)
    // ofertas da salva: só em numerário, no caixa da igreja
    const caixa = daIgreja.find((c) => c.tipo === 'CAIXA')
    if (caixa) escolherConta(caixa)
  }

  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    const preenchidas = v.linhas.filter((l) => l.valor && centimos(l.valor) > 0 && fundoVisivel(l.fundoId))
    if (!anonimo && v.membro == null) {
      form.setError('membro', { message: naMissao ? 'Diga que membro pagou na Missão' : 'Escolha o membro (ou "Ofertas da salva" para ofertas sem nome)' })
      return
    }
    if (naMissao && !v.referencia) { form.setError('referencia', { message: 'Escreva a referência do comprovativo' }); return }
    try {
      const membroId = anonimo ? null : v.membro
      const { transacao: tr, recibo, erroRecibo } = await criar.mutateAsync({
        chave,
        confirmar: true,
        recibo: v.recibo && membroId != null && pode('tesouraria.recibo.criar'),
        corpo: {
          tipo: 'ENTRADA', metodo: v.metodo as never, valorTotal: deCentimos(total), contaId: Number(v.contaId),
          membroId: membroId ?? undefined, anonimo: membroId == null, contagemId: numerario && v.contagemId ? Number(v.contagemId) : undefined, dataHora: `${v.data}T${v.hora}:00+02:00`,
          referencia: v.referencia || undefined,
          descricao: v.descricao || (naMissao ? 'Pago directamente na Missão' : anonimo ? 'Ofertas da salva' : numerario ? 'Envelope' : undefined),
          linhas: preenchidas.map((l) => ({ fundoId: l.fundoId, categoriaId: Number(l.categoriaId), valor: l.valor })),
        } as never,
      })
      const numero = recibo ? `${recibo.numero}/${recibo.ano}` : undefined
      // o ficheiro do comprovativo vai depois da entrada (precisa do id); se falhar, a entrada fica e junta-se na ficha
      let juntou = false
      if (comprovativo && !numerario) {
        try {
          await carregarComprovativo(tr.id, comprovativo)
          juntou = true
        } catch (errFicheiro) {
          toast.warning('A entrada foi gravada, mas o comprovativo não foi carregado', { description: `${mensagemDe(errFicheiro)} Junte-o na ficha do movimento.` })
        }
      }
      setSessao((s) => [{ id: tr.id, quem: membroId ? nomeDe(membroId) ?? 'Membro' : 'Ofertas da salva', como: conta ? comoEntregou(conta).titulo : '', valor: tr.valorTotal, recibo: numero, comprovativo: juntou }, ...s])
      toast.success(numero ? `Entrada gravada. Recibo n.º ${numero}.` : 'Entrada gravada e confirmada.')
      if (erroRecibo) toast.warning('O recibo não foi emitido', { description: `${mensagemDe(erroRecibo)} Emita-o na ficha do movimento.` })
      setChave(crypto.randomUUID())
      // pronto para a entrada seguinte: mantém como foi entregue, a data e a hora
      form.reset({ ...v, membro: null, referencia: '', descricao: '', linhas: linhasIniciais })
      setComprovativo(null)
      setVerOutros(false)
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })

  if (contas.isPending || fundos.isPending || categorias.isPending) return <div className="grid gap-4" aria-busy="true" aria-label="A carregar"><Barra className="h-8 w-64" /><Barra className="h-96 w-full" /></div>
  const falha = contas.error ?? fundos.error ?? categorias.error
  if (falha) return <EstadoErro erro={falha} aoTentar={() => { contas.refetch(); fundos.refetch(); categorias.refetch() }} />

  const campoValor = (i: number, grande = false) => {
    const fundo = fundoPorId.get(fields[i].fundoId)
    return (
      <Controller control={form.control} name={`linhas.${i}.valor`} render={({ field, fieldState }) => (
        <div>
          <CampoDinheiro {...field} aria-label={`Valor para ${fundo?.nome}`} aria-invalid={!!fieldState.error} className={cn('alvo', grande && 'h-12 text-lg font-semibold')} />
          {fieldState.error && <p className="mt-1 text-xs text-destructive-text">{fieldState.error.message}</p>}
        </div>
      )} />
    )
  }
  const categoria = (i: number) => verCategorias && (
    <Seleccao aria-label={`Categoria de ${fundoPorId.get(fields[i].fundoId)?.nome}`} {...form.register(`linhas.${i}.categoriaId`)} className="mt-2 h-8 text-xs">
      {receitas.map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
    </Seleccao>
  )
  const opcao = (c: Conta) => {
    const { titulo, I } = comoEntregou(c)
    const sel = conta?.id === c.id
    return (
      <button key={c.id} type="button" role="radio" aria-checked={sel} onClick={() => escolherConta(c)}
        className={cn('alvo flex items-center gap-3 rounded-lg border px-3 py-2.5 text-left', sel ? 'border-primary bg-primary/5' : 'hover:bg-muted/50')}>
        <I className={cn('size-5 flex-none', sel ? 'text-primary' : 'text-muted-foreground')} />
        <span className="min-w-0"><span className="block text-sm font-medium">{titulo}</span><span className="block truncate text-xs text-muted-foreground">{detalheConta(c)}</span></span>
      </button>
    )
  }

  return (
    <form onSubmit={submeter} noValidate>
      <TituloPagina
        antes={<Link to="/tesouraria" className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" /> {t.tesouraria.titulo}</Link>}
        icone={HandCoins} titulo={t.tesouraria.entrada}
        descricao="Os dízimos e ofertas de cada membro (envelope ou comprovativo) e as ofertas da salva."
      />
      <div className="grid items-start gap-6 lg:grid-cols-12">
        <div className="grid min-w-0 gap-6 lg:col-span-8">
          <ErroFormulario mensagem={erro} />

          {/* 1 · quem contribui */}
          <Cartao titulo="1. Quem contribui" icone={UserRound}>
            <div role="radiogroup" aria-label="Quem contribui" className="mb-4 grid grid-cols-2 gap-2">
              {[{ v: false, r: 'Um membro', I: UserRound, d: 'Com recibo numerado' }, { v: true, r: 'Ofertas da salva', I: Users, d: 'Sem nome, em numerário' }].map((o) => (
                <button key={o.r} type="button" role="radio" aria-checked={anonimo === o.v} onClick={() => escolherSalva(o.v)}
                  className={cn('alvo flex items-center gap-3 rounded-lg border px-3 py-2.5 text-left', anonimo === o.v ? 'border-primary bg-primary/5' : 'hover:bg-muted/50')}>
                  <o.I className={cn('size-5 flex-none', anonimo === o.v ? 'text-primary' : 'text-muted-foreground')} />
                  <span className="min-w-0"><span className="block text-sm font-medium">{o.r}</span><span className="block text-xs text-muted-foreground">{o.d}</span></span>
                </button>
              ))}
            </div>
            {!anonimo && (
              <CampoFormulario rotulo="Membro" erro={e.membro?.message} obrigatorio>
                {(p) => <Controller control={form.control} name="membro" render={({ field }) => (
                  <CampoMembro id={p.id} valor={field.value} aoMudar={(x) => { field.onChange(x); form.clearErrors('membro') }} nomeDe={nomeDe} estados={['ACTIVO', 'INTERESSADO']} vazio="Procurar o membro pelo nome…" />
                )} />}
              </CampoFormulario>
            )}
            {!anonimo && membro != null && (
              <p className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 rounded-lg bg-muted/50 px-3 py-2 text-sm text-muted-foreground">
                <span>Este ano: <strong className="num text-foreground">{dinheiro(deCentimos(anoMembro))}</strong> em {new Set(doMembro.map((c) => c.id)).size} entrega(s)</span>
                {ultima && <span>Última: {dataEcra(ultima.dataHora)}</span>}
              </p>
            )}
            {anonimo && <p className="flex items-center gap-2 text-sm text-muted-foreground"><HandHeart className="size-4 flex-none" />O que se recolheu na salva: entra nos fundos, em numerário, sem recibo.</p>}
          </Cartao>

          {/* 2 · como entregou */}
          {!anonimo && (
            <Cartao titulo="2. Como entregou o dinheiro" icone={Wallet} descricao="Em envelope na igreja, ou por depósito / M-Pesa com comprovativo">
              <div role="radiogroup" aria-label="Como entregou o dinheiro" className="grid gap-4">
                <div>
                  <p className="mb-2 text-xs font-semibold tracking-wider text-muted-foreground uppercase">Na igreja</p>
                  <div className="grid gap-2 sm:grid-cols-2">{daIgreja.map(opcao)}</div>
                </div>
                <div>
                  <p className="mb-2 text-xs font-semibold tracking-wider text-muted-foreground uppercase">Directamente na Missão</p>
                  {naMissaoContas.length > 0 && <div className="grid gap-2 sm:grid-cols-2">{naMissaoContas.map(opcao)}</div>}
                  {pode('tesouraria.conta_financeira.criar') && (
                    <Link to="/tesouraria/contas?nova=missao" className="alvo mt-1 inline-flex items-center gap-1.5 text-sm font-medium text-primary hover:underline">
                      <Plus className="size-4" />{naMissaoContas.length ? 'Outra conta da Missão (ex.: M-Pesa da Missão)' : 'Registar a conta da Missão (banco ou M-Pesa)'}
                    </Link>
                  )}
                  {!naMissaoContas.length && !pode('tesouraria.conta_financeira.criar') && <p className="text-sm text-muted-foreground">Ainda não há contas da Missão registadas.</p>}
                </div>
              </div>
              {e.contaId && <p className="mt-2 text-sm text-destructive-text">{e.contaId.message}</p>}
              {naMissao && (
                <p className="mt-4 rounded-lg border border-info/30 bg-tint-info px-3 py-2 text-sm text-info-text">
                  O dinheiro já está na Missão: conta como contribuição do membro (com recibo) e como já remetido; não entra no saldo da igreja.
                </p>
              )}
            </Cartao>
          )}

          {/* 3 · comprovativo (o que não é numerário) */}
          {!numerario && conta && (
            <Cartao titulo="Comprovativo" icone={FileCheck2} descricao="O que o membro mandou ao tesoureiro: o talão do depósito ou a mensagem do M-Pesa">
              <div className="grid gap-4 sm:grid-cols-2">
                <CampoFormulario rotulo={conta.tipo === 'BANCO' ? 'N.º do talão / referência' : 'Código da transacção'} erro={e.referencia?.message} obrigatorio={naMissao}>
                  {(p) => <Input {...p} {...form.register('referencia')} placeholder={conta.tipo === 'BANCO' ? 'ex.: 004512' : 'ex.: QK7H2LM9PX'} className="alvo num uppercase placeholder:normal-case" />}
                </CampoFormulario>
                <div className="grid grid-cols-[1fr_auto] gap-3">
                  <CampoFormulario rotulo="Data do pagamento" erro={e.data?.message} obrigatorio>
                    {(p) => <Controller control={form.control} name="data" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
                  </CampoFormulario>
                  <CampoFormulario rotulo="Hora" erro={e.hora?.message}>
                    {(p) => <Input {...p} {...form.register('hora')} type="time" className="alvo num w-28" />}
                  </CampoFormulario>
                </div>
                <CampoFormulario rotulo="Descrição" erro={e.descricao?.message} className="sm:col-span-2" ajuda="O que o membro escreveu no comprovativo (ex.: dízimo de Outubro)">
                  {(p) => <Input {...p} {...form.register('descricao')} placeholder="ex.: Dízimo e oferta de Outubro" className="alvo" />}
                </CampoFormulario>
                <div className="sm:col-span-2"><CampoComprovativo ficheiro={comprovativo} aoMudar={setComprovativo} /></div>
              </div>
            </Cartao>
          )}

          {/* valores */}
          <Cartao titulo={anonimo ? '2. Valores' : '3. Valores'} descricao="Escreva só o que tem valor; o total soma-se sozinho" icone={HandCoins}
            accoes={<Button type="button" variant="ghost" size="sm" className="hidden sm:inline-flex" aria-pressed={verCategorias} onClick={() => setVerCategorias((v) => !v)}>{verCategorias ? 'Ocultar categorias' : 'Alterar categorias'}</Button>}>
            {principais.length > 0 && (
              <div className="grid gap-4 sm:grid-cols-2">
                {principais.map(({ i, fundo }) => (
                  <div key={fields[i].id} className="rounded-lg border p-4">
                    <p className="text-sm font-semibold">{fundo?.tipo === 'OFERTA_COMBINADA' ? 'Oferta' : fundo?.nome}</p>
                    <p className="mb-2 text-xs text-muted-foreground">{fundo?.tipo === 'OFERTA_COMBINADA' ? `${fundo.nome} · ` : ''}{fundo && parteDoFundo(fundo)}</p>
                    {campoValor(i, true)}
                    {categoria(i)}
                  </div>
                ))}
              </div>
            )}
            {outros.length > 0 && (
              <div className={cn('rounded-lg border', principais.length > 0 && 'mt-4')}>
                <button type="button" aria-expanded={abertosOutros} onClick={() => setVerOutros((v) => !v)}
                  className="alvo flex w-full items-center justify-between gap-3 px-4 py-2.5 text-left text-sm font-medium">
                  <span>Outros fundos <span className="font-normal text-muted-foreground">({outros.length}{outrosComValor ? ` · ${outrosComValor} com valor` : ''})</span></span>
                  <ChevronDown className={cn('size-4 flex-none text-muted-foreground transition-transform', abertosOutros && 'rotate-180')} />
                </button>
                {abertosOutros && (
                  <ul className="divide-y border-t">
                    {outros.map(({ i, fundo }) => (
                      <li key={fields[i].id} className="grid grid-cols-[1fr_140px] items-center gap-3 px-4 py-2.5 sm:grid-cols-[1fr_190px]">
                        <div className="min-w-0"><p className="text-sm font-medium">{fundo?.nome}</p><p className="text-xs text-muted-foreground">{fundo && parteDoFundo(fundo)}</p>{categoria(i)}</div>
                        {campoValor(i)}
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            )}
            {e.linhas?.root?.message || e.linhas?.message ? <p className="mt-3 text-sm font-medium text-destructive-text">{e.linhas?.root?.message ?? e.linhas?.message}</p> : null}
            {numerario && (
              <div className="mt-4 grid gap-4 border-t pt-4 sm:grid-cols-[1fr_1fr]">
                <div className="grid grid-cols-[1fr_auto] gap-3">
                  <CampoFormulario rotulo="Data" erro={e.data?.message} obrigatorio>
                    {(p) => <Controller control={form.control} name="data" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
                  </CampoFormulario>
                  <CampoFormulario rotulo="Hora" erro={e.hora?.message}>
                    {(p) => <Input {...p} {...form.register('hora')} type="time" className="alvo num w-28" />}
                  </CampoFormulario>
                </div>
                {contagensAbertas.length > 0 && (
                  <CampoFormulario rotulo="Contagem do culto" ajuda="Onde este dinheiro foi contado: soma na conferência.">
                    {(p) => (
                      <Seleccao {...p} {...form.register('contagemId')}>
                        <option value="">Sem contagem</option>
                        {contagensAbertas.map((c) => <option key={c.id} value={c.id}>{dataEcra(c.data)} · {c.ocasiao ?? 'Culto'}</option>)}
                      </Seleccao>
                    )}
                  </CampoFormulario>
                )}
              </div>
            )}
          </Cartao>
        </div>

        <aside className="hidden lg:sticky lg:top-[calc(var(--header-height)+1.5rem)] lg:col-span-4 lg:grid lg:gap-6">
          <Cartao titulo="Resumo">
            <p className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Total</p>
            <p className="num mt-1 text-3xl font-bold tracking-tight"><Dinheiro valor={deCentimos(total)} /></p>
            <p className="mt-1 truncate text-sm text-muted-foreground">{anonimo ? 'Ofertas da salva' : membro ? nomeDe(membro) : 'Escolha o membro'}</p>
            {conta && <p className="truncate text-sm text-muted-foreground">{anonimo ? 'Em numerário' : comoEntregou(conta).titulo}</p>}
            {total > 0 && (
              <div className="mt-4 grid gap-1.5 text-sm">
                <div className="flex h-2 overflow-hidden rounded-full bg-muted" aria-hidden>
                  <div className="h-full bg-[var(--serie-1)]" style={{ width: `${(paraMissao / total) * 100}%` }} />
                  <div className="h-full bg-[var(--serie-3)]" style={{ width: `${((total - paraMissao) / total) * 100}%` }} />
                </div>
                <p className="flex justify-between"><span className="flex items-center gap-1.5 text-muted-foreground"><span className="size-2 rounded-[2px] bg-[var(--serie-1)]" />Para a Missão</span><span className="num">{dinheiro(deCentimos(paraMissao))}</span></p>
                <p className="flex justify-between"><span className="flex items-center gap-1.5 text-muted-foreground"><span className="size-2 rounded-[2px] bg-[var(--serie-3)]" />Fica na igreja</span><span className="num">{dinheiro(deCentimos(total - paraMissao))}</span></p>
                {naMissao && <p className="text-xs text-muted-foreground">Já está na Missão: não entra no depósito do fim do mês.</p>}
              </div>
            )}
            <label className={cn('alvo mt-4 flex items-center gap-2 text-sm', (anonimo || !membro) && 'opacity-50')}>
              <input type="checkbox" disabled={anonimo || !membro} checked={form.watch('recibo') && !anonimo} onChange={(ev) => form.setValue('recibo', ev.target.checked)} className="size-4 accent-[var(--primary)]" />
              Emitir recibo numerado
            </label>
            <Button type="submit" disabled={form.formState.isSubmitting || total <= 0} className="alvo mt-4 h-11 w-full text-base">
              {form.formState.isSubmitting ? t.comum.aGravar : 'Gravar entrada'}
            </Button>
            <Button type="button" variant="ghost" className="alvo mt-2 w-full" onClick={() => navigate('/tesouraria')}>{sessao.length ? 'Terminar' : t.comum.cancelar}</Button>
          </Cartao>
          {sessao.length > 0 && <ListaSessao sessao={sessao} total={totalSessao} />}
        </aside>
      </div>
      {/* telemóvel: o que se lançou nesta sessão, e o total e o botão sempre à vista no fundo do ecrã */}
      {sessao.length > 0 && <div className="mt-6 lg:hidden"><ListaSessao sessao={sessao.slice(0, 5)} total={totalSessao} n={sessao.length} /></div>}
      <div className="fixed inset-x-0 bottom-0 z-20 border-t bg-background/95 px-4 py-3 backdrop-blur lg:hidden">
        <div className="flex items-center gap-3">
          <div className="min-w-0 flex-1">
            <p className="text-[11px] font-semibold tracking-wider text-muted-foreground uppercase">Total</p>
            <p className="num truncate text-xl font-bold"><Dinheiro valor={deCentimos(total)} /></p>
            {total > 0 && paraMissao > 0 && <p className="num truncate text-[11px] text-muted-foreground">Missão {dinheiro(deCentimos(paraMissao))} · igreja {dinheiro(deCentimos(total - paraMissao))}</p>}
          </div>
          {membro && !anonimo && (
            <label className="alvo flex items-center gap-1.5 text-xs">
              <input type="checkbox" checked={form.watch('recibo')} onChange={(ev) => form.setValue('recibo', ev.target.checked)} className="size-4 accent-[var(--primary)]" />Recibo
            </label>
          )}
          <Button type="submit" disabled={form.formState.isSubmitting || total <= 0} className="alvo h-11 px-5">{form.formState.isSubmitting ? t.comum.aGravar : 'Gravar'}</Button>
        </div>
      </div>
      <div className="h-24 lg:hidden" aria-hidden />
    </form>
  )
}

function ListaSessao({ sessao, total, n }: { sessao: Lancada[]; total: number; n?: number }) {
  return (
    <Cartao titulo="Nesta sessão" descricao={`${n ?? sessao.length} lançamento(s) · ${dinheiro(deCentimos(total))}`} icone={Receipt} semMargem>
      <ul className="max-h-72 divide-y overflow-y-auto">
        {sessao.map((x) => (
          <li key={x.id}>
            <Link to={`/tesouraria/movimentos/${x.id}`} className="alvo flex items-center justify-between gap-3 px-4 py-2 text-sm hover:bg-muted/50 sm:px-6">
              <span className="min-w-0">
                <span className="block truncate font-medium">{x.quem}</span>
                <span className="flex items-center gap-1 truncate text-xs text-muted-foreground">{x.comprovativo && <Paperclip className="size-3 flex-none" aria-label="com comprovativo" />}{[x.como, x.recibo && `recibo n.º ${x.recibo}`].filter(Boolean).join(' · ')}</span>
              </span>
              <span className="num flex-none"><Dinheiro valor={x.valor} /></span>
            </Link>
          </li>
        ))}
      </ul>
    </Cartao>
  )
}
