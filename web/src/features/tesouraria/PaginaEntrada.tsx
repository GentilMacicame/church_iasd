/**
 * Lançar entrada (P-06 passos 2 e 3): um envelope ou uma contribuição, com uma linha por fundo; confirma-se logo
 * e, com contribuinte identificado, emite o recibo numerado. Depois de gravar fica pronto para o envelope seguinte
 * (mantém a conta e a data). A soma das linhas = total é verificada pela base de dados; aqui só se ajuda.
 *
 * Dois casos: o que se recolhe na igreja (sábado: dízimos e ofertas no caixa, M-Pesa da igreja) e o que o membro
 * pagou directamente na conta da Missão e comprovou (V21): vai para a conta da Missão, só fundos da Missão, com a
 * referência do comprovativo; conta como contribuição do membro e como já remetido.
 */
import { useMemo, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { Controller, useFieldArray, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ArrowLeft, Church, HandCoins, Landmark, Receipt, UserRound, Wallet } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Cartao, Dinheiro, TituloPagina } from '@/components/comum/elementos'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { Seleccao } from '@/components/comum/Seleccao'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { useSessao } from '@/auth/sessao'
import { mensagemDe } from '@/api/erros'
import { rotulos, t } from '@/i18n/pt-MZ'
import { centimos, data as dataEcra, deCentimos, hojeIso } from '@/lib/formatos'
import { useMembrosBasicos } from '@/features/membros/api'
import { cn } from '@/lib/utils'
import { CATEGORIA_POR_FUNDO, daMissao, useCategorias, useContagens, useContas, useCriarMovimento, useFundos, type Conta } from './api'
import { parteDoFundo } from './comum'

const valorApi = /^\d{1,14}(\.\d{1,2})?$/
const esquema = z.object({
  contaId: z.string().min(1, t.comum.obrigatorio),
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

export default function PaginaEntrada() {
  const navigate = useNavigate()
  const { pode } = useSessao()
  const contas = useContas()
  const fundos = useFundos()
  const categorias = useCategorias()
  const basicos = useMembrosBasicos()
  const criar = useCriarMovimento()
  const contagens = useContagens()
  const [chave, setChave] = useState(() => crypto.randomUUID())
  const [erro, setErro] = useState<string | null>(null)
  const [ultimo, setUltimo] = useState<{ id: number; valor: string; recibo?: string } | null>(null)
  const [params, setParams] = useSearchParams()
  // a categoria de cada fundo vem sugerida; só se mostra quando o tesoureiro a quer mudar
  const [verCategorias, setVerCategorias] = useState(false)
  const naMissao = params.get('onde') === 'missao'
  const contasDoCaso = (contas.data ?? []).filter((c) => daMissao(c) === naMissao)

  const receitas = (categorias.data ?? []).filter((c) => c.tipo === 'RECEITA')
  const catPorCodigo = new Map(receitas.map((c) => [c.codigo, c.id]))
  const linhasIniciais = useMemo(() => (fundos.data ?? []).map((f) => ({
    fundoId: f.id, categoriaId: String(catPorCodigo.get(CATEGORIA_POR_FUNDO[f.tipo] ?? 'R9') ?? receitas[0]?.id ?? ''), valor: '',
  // eslint-disable-next-line react-hooks/exhaustive-deps
  })), [fundos.data, categorias.data])

  const form = useForm<Valores>({
    resolver: zodResolver(esquema),
    values: {
      contaId: contasDoCaso[0] ? String(contasDoCaso[0].id) : '', metodo: METODO_DA_CONTA[contasDoCaso[0]?.tipo ?? 'CAIXA'],
      data: hojeIso(), hora: new Date().toTimeString().slice(0, 5), membro: null, contagemId: '', referencia: '', descricao: '', recibo: true, linhas: linhasIniciais,
    },
    resetOptions: { keepDirtyValues: true },
  })
  const { fields } = useFieldArray({ control: form.control, name: 'linhas' })
  const linhas = form.watch('linhas')
  const membro = form.watch('membro')
  const metodo = form.watch('metodo')
  const contagensAbertas = (contagens.data ?? []).filter((c) => c.estado === 'ABERTA' && !c.endDate)
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }
  const fundoPorId = new Map((fundos.data ?? []).map((f) => [f.id, f]))
  const contaEscolhida = contas.data?.find((c) => String(c.id) === form.watch('contaId'))
  /** Na conta da Missão só entram os fundos dessa entidade (a base de dados recusa os outros). */
  const fundoVisivel = (id: number) => {
    if (!naMissao) return true
    const f = fundoPorId.get(id)
    return !!f && f.destinoEntidadeId === contaEscolhida?.entidadeId && Number(f.percentagemRemessa ?? 0) > 0
  }
  const total = linhas.reduce((s, l) => s + (valorApi.test(l.valor) && fundoVisivel(l.fundoId) ? centimos(l.valor) : 0), 0)
  const mudarCaso = (missao: boolean) => {
    setParams((p) => { const n = new URLSearchParams(p); if (missao) n.set('onde', 'missao'); else n.delete('onde'); return n }, { replace: true })
    const lista = (contas.data ?? []).filter((c) => daMissao(c) === missao)
    form.setValue('contaId', lista[0] ? String(lista[0].id) : '')
    form.setValue('metodo', METODO_DA_CONTA[lista[0]?.tipo ?? 'CAIXA'])
    form.setValue('linhas', linhasIniciais)
    form.clearErrors()
    setErro(null)
  }

  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    const preenchidas = v.linhas.filter((l) => l.valor && centimos(l.valor) > 0 && fundoVisivel(l.fundoId))
    if (naMissao) {
      let falta = false
      if (v.membro == null) { form.setError('membro', { message: 'Diga que membro pagou na conta da Missão' }); falta = true }
      if (!v.referencia) { form.setError('referencia', { message: 'Escreva a referência do comprovativo' }); falta = true }
      if (falta) return
    }
    try {
      const { transacao: tr, recibo, erroRecibo } = await criar.mutateAsync({
        chave,
        confirmar: true,
        recibo: v.recibo && v.membro != null && pode('tesouraria.recibo.criar'),
        corpo: {
          tipo: 'ENTRADA', metodo: v.metodo as never, valorTotal: deCentimos(total), contaId: Number(v.contaId),
          membroId: v.membro ?? undefined, anonimo: v.membro == null, contagemId: v.metodo === 'NUMERARIO' && v.contagemId ? Number(v.contagemId) : undefined, dataHora: `${v.data}T${v.hora}:00+02:00`,
          referencia: v.referencia || undefined, descricao: v.descricao || (naMissao ? 'Pago na conta da Missão' : undefined),
          linhas: preenchidas.map((l) => ({ fundoId: l.fundoId, categoriaId: Number(l.categoriaId), valor: l.valor })),
        } as never,
      })
      const numero = recibo ? `${recibo.numero}/${recibo.ano}` : undefined
      setUltimo({ id: tr.id, valor: tr.valorTotal, recibo: numero })
      toast.success(numero ? `Entrada gravada e confirmada. Recibo n.º ${numero}.` : 'Entrada gravada e confirmada.')
      if (erroRecibo) toast.warning('O recibo não foi emitido', { description: `${mensagemDe(erroRecibo)} Emita-o na ficha do movimento.` })
      setChave(crypto.randomUUID())
      // pronto para o envelope seguinte: mantém conta, método e data
      form.reset({ ...v, membro: null, referencia: '', descricao: '', linhas: linhasIniciais })
    } catch (e) {
      setErro(aplicarErroApi(form, e))
    }
  })

  if (contas.isPending || fundos.isPending || categorias.isPending) return <div className="grid gap-4" aria-busy="true" aria-label="A carregar"><Barra className="h-8 w-64" /><Barra className="h-96 w-full" /></div>
  const falha = contas.error ?? fundos.error ?? categorias.error
  if (falha) return <EstadoErro erro={falha} aoTentar={() => { contas.refetch(); fundos.refetch(); categorias.refetch() }} />

  return (
    <form onSubmit={submeter} noValidate>
      <TituloPagina
        antes={<Link to="/tesouraria" className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" /> {t.tesouraria.titulo}</Link>}
        icone={HandCoins} titulo={t.tesouraria.entrada}
        descricao={naMissao ? 'O membro pagou directamente na conta da Missão e mandou o comprovativo.' : 'Dízimos e ofertas de um envelope ou contribuição, com o valor de cada fundo.'}
      />
      <div role="tablist" aria-label="Onde foi pago" className="mb-6 grid grid-cols-2 gap-1 rounded-lg bg-muted p-1 sm:inline-grid">
        {[{ m: false, rot: 'Recolhido na igreja', I: Church }, { m: true, rot: 'Pago na conta da Missão', I: Landmark }].map(({ m, rot, I }) => (
          <button key={rot} type="button" role="tab" aria-selected={naMissao === m} onClick={() => mudarCaso(m)}
            className={cn('alvo flex items-center justify-center gap-2 rounded-md px-3 py-2 text-sm font-medium text-muted-foreground', naMissao === m && 'bg-card text-foreground shadow-sm')}>
            <I className="size-4 shrink-0" />{rot}
          </button>
        ))}
      </div>
      {ultimo && (
        <div className="mb-6 flex flex-wrap items-center justify-between gap-3 rounded-lg border border-success/20 bg-tint-success px-4 py-3 text-sm text-success-text">
          <span>Última entrada gravada: <strong className="num"><Dinheiro valor={ultimo.valor} /></strong>{ultimo.recibo && <> · recibo n.º <strong className="num">{ultimo.recibo}</strong></>}. Pronto para o envelope seguinte.</span>
          <Button asChild size="sm" variant="outline"><Link to={`/tesouraria/movimentos/${ultimo.id}`}><Receipt className="size-4" />Ver / recibo</Link></Button>
        </div>
      )}
      {naMissao && !contasDoCaso.length ? (
        <div className="rounded-xl border bg-card shadow-card">
          <EstadoVazio icone={Landmark} titulo="Ainda não está registada a conta da Missão"
            accao={pode('tesouraria.conta_financeira.criar') && <Button asChild className="alvo"><Link to="/tesouraria/contas?nova=missao">Registar a conta da Missão</Link></Button>}>
            Para lançar o que os membros pagam directamente na Missão, registe primeiro a conta bancária (ou M-Pesa) da Missão.
          </EstadoVazio>
        </div>
      ) : <>
      <div className="grid items-start gap-6 lg:grid-cols-12">
        <div className="grid gap-6 lg:col-span-8">
          <ErroFormulario mensagem={erro} />
          {naMissao && (
            <p className="rounded-lg border border-info/30 bg-tint-info px-4 py-3 text-sm text-info-text">
              O dinheiro já está na Missão: conta como contribuição do membro (com recibo) e como já remetido, e não entra no saldo da igreja.
            </p>
          )}
          <Cartao titulo="Quem e onde" descricao="A conta onde o dinheiro entra e quem contribui" icone={UserRound}>
            <div className="grid gap-4 sm:grid-cols-2">
              <CampoFormulario rotulo="Conta" erro={form.formState.errors.contaId?.message} obrigatorio>
                {(p) => (
                  <Seleccao {...p} {...form.register('contaId', {
                    onChange: (e) => { const c = contas.data?.find((x: Conta) => String(x.id) === e.target.value); if (c?.tipo) form.setValue('metodo', METODO_DA_CONTA[c.tipo]) },
                  })}>
                    {contasDoCaso.map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
                  </Seleccao>
                )}
              </CampoFormulario>
              <CampoFormulario rotulo="Forma de pagamento">
                {(p) => <Seleccao {...p} {...form.register('metodo')}>{Object.entries(rotulos.metodo).map(([k, r]) => <option key={k} value={k}>{r}</option>)}</Seleccao>}
              </CampoFormulario>
              <div className="grid grid-cols-[1fr_auto] gap-3">
                <CampoFormulario rotulo={naMissao ? 'Data do pagamento' : 'Data'} erro={form.formState.errors.data?.message} obrigatorio>
                  {(p) => <Controller control={form.control} name="data" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
                </CampoFormulario>
                <CampoFormulario rotulo="Hora" erro={form.formState.errors.hora?.message}>
                  {(p) => <Input {...p} {...form.register('hora')} type="time" className="alvo num w-32" />}
                </CampoFormulario>
              </div>
              <CampoFormulario rotulo="Contribuinte" erro={form.formState.errors.membro?.message} obrigatorio={naMissao}
                ajuda={naMissao ? 'O membro que pagou e mandou o comprovativo.' : 'Sem contribuinte: entrada anónima (ex.: ofertas da salva), sem recibo.'}>
                {(p) => <Controller control={form.control} name="membro" render={({ field }) => (
                  <CampoMembro id={p.id} valor={field.value} aoMudar={field.onChange} nomeDe={nomeDe} estados={['ACTIVO', 'INTERESSADO']} vazio={naMissao ? 'Escolher o membro…' : 'Anónimo (sem contribuinte)'} />
                )} />}
              </CampoFormulario>
              {!naMissao && metodo === 'NUMERARIO' && contagensAbertas.length > 0 && (
                <CampoFormulario rotulo="Contagem do culto" ajuda="O dinheiro contado onde este valor estava: soma na conferência.">
                  {(p) => (
                    <Seleccao {...p} {...form.register('contagemId')}>
                      <option value="">Sem contagem</option>
                      {contagensAbertas.map((c) => <option key={c.id} value={c.id}>{dataEcra(c.data)} · {c.ocasiao ?? 'Culto'}</option>)}
                    </Seleccao>
                  )}
                </CampoFormulario>
              )}
              <CampoFormulario rotulo={naMissao ? 'Referência do comprovativo' : 'Referência'} obrigatorio={naMissao} erro={form.formState.errors.referencia?.message}
                ajuda={naMissao ? 'N.º do talão do depósito ou código da transacção M-Pesa que o membro mandou' : 'Código da transacção M-Pesa ou do talão do banco'}>
                {(p) => <Input {...p} {...form.register('referencia')} className="alvo num uppercase" />}
              </CampoFormulario>
              <CampoFormulario rotulo="Descrição" erro={form.formState.errors.descricao?.message}>
                {(p) => <Input {...p} {...form.register('descricao')} placeholder="ex.: Envelope do sábado" className="alvo" />}
              </CampoFormulario>
            </div>
          </Cartao>
          <Cartao titulo="Valores por fundo" descricao="Escreva só os fundos com valor; o total soma-se sozinho" icone={Wallet} semMargem
            accoes={<Button type="button" variant="ghost" size="sm" className="hidden sm:inline-flex" aria-pressed={verCategorias} onClick={() => setVerCategorias((v) => !v)}>{verCategorias ? 'Ocultar categorias' : 'Alterar categorias'}</Button>}>
            <ul className="divide-y">
              {fields.map((f, i) => {
                const fundo = fundoPorId.get(f.fundoId)
                if (!fundoVisivel(f.fundoId)) return null
                return (
                  <li key={f.id} className={cn('grid grid-cols-[1fr_150px] items-center gap-3 px-4 py-3 sm:px-6', verCategorias ? 'sm:grid-cols-[1fr_200px_170px]' : 'sm:grid-cols-[1fr_190px]')}>
                    <div className="min-w-0">
                      <p className="text-sm font-medium">{fundo?.nome}</p>
                      <p className="text-xs text-muted-foreground">{fundo && parteDoFundo(fundo)}</p>
                    </div>
                    <div className={verCategorias ? 'hidden sm:block' : 'hidden'}><Seleccao aria-label={`Categoria de ${fundo?.nome}`} {...form.register(`linhas.${i}.categoriaId`)} className="h-9 text-xs">
                      {receitas.map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
                    </Seleccao></div>
                    <Controller control={form.control} name={`linhas.${i}.valor`} render={({ field, fieldState }) => (
                      <div>
                        <CampoDinheiro {...field} aria-label={`Valor para ${fundo?.nome}`} aria-invalid={!!fieldState.error} className="alvo" />
                        {fieldState.error && <p className="mt-1 text-xs text-destructive-text">{fieldState.error.message}</p>}
                      </div>
                    )} />
                  </li>
                )
              })}
            </ul>
            {form.formState.errors.linhas?.root?.message || form.formState.errors.linhas?.message
              ? <p className="border-t px-6 py-3 text-sm font-medium text-destructive-text">{form.formState.errors.linhas?.root?.message ?? form.formState.errors.linhas?.message}</p> : null}
          </Cartao>
        </div>
        <aside className="hidden lg:sticky lg:top-[calc(var(--header-height)+1.5rem)] lg:col-span-4 lg:block">
          <Cartao titulo="Resumo">
            <p className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Total da entrada</p>
            <p className="num mt-1 text-3xl font-bold tracking-tight"><Dinheiro valor={deCentimos(total)} /></p>
            <p className="mt-1 text-sm text-muted-foreground">{linhas.filter((l) => l.valor && centimos(l.valor) > 0).length} fundo(s) · {membro ? nomeDe(membro) : 'anónimo'}</p>
            <label className={`alvo mt-5 flex items-center gap-2 text-sm ${membro ? '' : 'opacity-50'}`}>
              <input type="checkbox" disabled={!membro} checked={form.watch('recibo')} onChange={(e) => form.setValue('recibo', e.target.checked)} className="size-4 accent-[var(--primary)]" />
              Emitir recibo numerado
            </label>
            <Button type="submit" disabled={form.formState.isSubmitting || total <= 0} className="alvo mt-5 h-11 w-full text-base">
              {form.formState.isSubmitting ? t.comum.aGravar : 'Gravar entrada'}
            </Button>
            <Button type="button" variant="ghost" className="alvo mt-2 w-full" onClick={() => navigate('/tesouraria')}>{t.comum.cancelar}</Button>
          </Cartao>
        </aside>
      </div>
      {/* telemóvel: o total e o botão sempre à vista, no fundo do ecrã */}
      <div className="fixed inset-x-0 bottom-0 z-20 border-t bg-background/95 px-4 py-3 backdrop-blur lg:hidden">
        <div className="flex items-center gap-3">
          <div className="min-w-0 flex-1">
            <p className="text-[11px] font-semibold tracking-wider text-muted-foreground uppercase">Total</p>
            <p className="num truncate text-xl font-bold"><Dinheiro valor={deCentimos(total)} /></p>
          </div>
          {membro && (
            <label className="alvo flex items-center gap-1.5 text-xs">
              <input type="checkbox" checked={form.watch('recibo')} onChange={(e) => form.setValue('recibo', e.target.checked)} className="size-4 accent-[var(--primary)]" />Recibo
            </label>
          )}
          <Button type="submit" disabled={form.formState.isSubmitting || total <= 0} className="alvo h-11 px-5">{form.formState.isSubmitting ? t.comum.aGravar : 'Gravar'}</Button>
        </div>
      </div>
      <div className="h-20 lg:hidden" aria-hidden />
      </>}
    </form>
  )
}
