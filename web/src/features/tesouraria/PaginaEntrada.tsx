/**
 * Lançar entrada (P-06 passos 2 e 3): um envelope ou uma contribuição, com uma linha por fundo; confirma-se logo
 * e, com contribuinte identificado, emite o recibo numerado. Depois de gravar fica pronto para o envelope seguinte
 * (mantém a conta e a data). A soma das linhas = total é verificada pela base de dados; aqui só se ajuda.
 */
import { useMemo, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Controller, useFieldArray, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ArrowLeft, HandCoins, Receipt, UserRound, Wallet } from 'lucide-react'
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
import { rotulos, t } from '@/i18n/pt-MZ'
import { centimos, data as dataEcra, deCentimos, hojeIso } from '@/lib/formatos'
import { useMembrosBasicos } from '@/features/membros/api'
import { CATEGORIA_POR_FUNDO, useCategorias, useContagens, useContas, useCriarMovimento, useFundos, type Conta } from './api'

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

  const receitas = (categorias.data ?? []).filter((c) => c.tipo === 'RECEITA')
  const catPorCodigo = new Map(receitas.map((c) => [c.codigo, c.id]))
  const linhasIniciais = useMemo(() => (fundos.data ?? []).map((f) => ({
    fundoId: f.id, categoriaId: String(catPorCodigo.get(CATEGORIA_POR_FUNDO[f.tipo] ?? 'R9') ?? receitas[0]?.id ?? ''), valor: '',
  // eslint-disable-next-line react-hooks/exhaustive-deps
  })), [fundos.data, categorias.data])

  const form = useForm<Valores>({
    resolver: zodResolver(esquema),
    values: {
      contaId: contas.data?.[0] ? String(contas.data[0].id) : '', metodo: METODO_DA_CONTA[contas.data?.[0]?.tipo ?? 'CAIXA'],
      data: hojeIso(), hora: new Date().toTimeString().slice(0, 5), membro: null, contagemId: '', referencia: '', descricao: '', recibo: true, linhas: linhasIniciais,
    },
    resetOptions: { keepDirtyValues: true },
  })
  const { fields } = useFieldArray({ control: form.control, name: 'linhas' })
  const linhas = form.watch('linhas')
  const membro = form.watch('membro')
  const metodo = form.watch('metodo')
  const contagensAbertas = (contagens.data ?? []).filter((c) => c.estado === 'ABERTA' && !c.endDate)
  const total = linhas.reduce((s, l) => s + (valorApi.test(l.valor) ? centimos(l.valor) : 0), 0)
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }
  const fundoPorId = new Map((fundos.data ?? []).map((f) => [f.id, f]))

  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    const preenchidas = v.linhas.filter((l) => l.valor && centimos(l.valor) > 0)
    try {
      const { transacao: tr, recibo, erroRecibo } = await criar.mutateAsync({
        chave,
        confirmar: true,
        recibo: v.recibo && v.membro != null && pode('tesouraria.recibo.criar'),
        corpo: {
          tipo: 'ENTRADA', metodo: v.metodo as never, valorTotal: deCentimos(total), contaId: Number(v.contaId),
          membroId: v.membro ?? undefined, anonimo: v.membro == null, contagemId: v.metodo === 'NUMERARIO' && v.contagemId ? Number(v.contagemId) : undefined, dataHora: `${v.data}T${v.hora}:00+02:00`,
          referencia: v.referencia || undefined, descricao: v.descricao || undefined,
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
        descricao="Dízimos e ofertas de um envelope ou contribuição, com o valor de cada fundo."
      />
      {ultimo && (
        <div className="mb-6 flex flex-wrap items-center justify-between gap-3 rounded-lg border border-success/20 bg-tint-success px-4 py-3 text-sm text-success-text">
          <span>Última entrada gravada: <strong className="num"><Dinheiro valor={ultimo.valor} /></strong>{ultimo.recibo && <> · recibo n.º <strong className="num">{ultimo.recibo}</strong></>}. Pronto para o envelope seguinte.</span>
          <Button asChild size="sm" variant="outline"><Link to={`/tesouraria/movimentos/${ultimo.id}`}><Receipt className="size-4" />Ver / recibo</Link></Button>
        </div>
      )}
      <div className="grid items-start gap-6 lg:grid-cols-12">
        <div className="grid gap-6 lg:col-span-8">
          <ErroFormulario mensagem={erro} />
          <Cartao titulo="Quem e onde" descricao="A conta onde o dinheiro entra e quem contribui" icone={UserRound}>
            <div className="grid gap-4 sm:grid-cols-2">
              <CampoFormulario rotulo="Conta" erro={form.formState.errors.contaId?.message} obrigatorio>
                {(p) => (
                  <Seleccao {...p} {...form.register('contaId', {
                    onChange: (e) => { const c = contas.data?.find((x: Conta) => String(x.id) === e.target.value); if (c?.tipo) form.setValue('metodo', METODO_DA_CONTA[c.tipo]) },
                  })}>
                    {(contas.data ?? []).map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
                  </Seleccao>
                )}
              </CampoFormulario>
              <CampoFormulario rotulo="Forma de pagamento">
                {(p) => <Seleccao {...p} {...form.register('metodo')}>{Object.entries(rotulos.metodo).map(([k, r]) => <option key={k} value={k}>{r}</option>)}</Seleccao>}
              </CampoFormulario>
              <div className="grid grid-cols-[1fr_auto] gap-3">
                <CampoFormulario rotulo="Data" erro={form.formState.errors.data?.message} obrigatorio>
                  {(p) => <Controller control={form.control} name="data" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
                </CampoFormulario>
                <CampoFormulario rotulo="Hora" erro={form.formState.errors.hora?.message}>
                  {(p) => <Input {...p} {...form.register('hora')} type="time" className="alvo num w-28" />}
                </CampoFormulario>
              </div>
              <CampoFormulario rotulo="Contribuinte" ajuda="Sem contribuinte: entrada anónima (ex.: ofertas da salva), sem recibo.">
                {(p) => <Controller control={form.control} name="membro" render={({ field }) => (
                  <CampoMembro id={p.id} valor={field.value} aoMudar={field.onChange} nomeDe={nomeDe} estados={['ACTIVO', 'INTERESSADO']} vazio="Anónimo (sem contribuinte)" />
                )} />}
              </CampoFormulario>
              {metodo === 'NUMERARIO' && contagensAbertas.length > 0 && (
                <CampoFormulario rotulo="Contagem do culto" ajuda="O dinheiro contado onde este valor estava: soma na conferência.">
                  {(p) => (
                    <Seleccao {...p} {...form.register('contagemId')}>
                      <option value="">Sem contagem</option>
                      {contagensAbertas.map((c) => <option key={c.id} value={c.id}>{dataEcra(c.data)} · {c.ocasiao ?? 'Culto'}</option>)}
                    </Seleccao>
                  )}
                </CampoFormulario>
              )}
              <CampoFormulario rotulo="Referência" ajuda="Código da transacção M-Pesa ou do talão do banco" erro={form.formState.errors.referencia?.message}>
                {(p) => <Input {...p} {...form.register('referencia')} className="alvo num uppercase" />}
              </CampoFormulario>
              <CampoFormulario rotulo="Descrição" erro={form.formState.errors.descricao?.message}>
                {(p) => <Input {...p} {...form.register('descricao')} placeholder="ex.: Envelope do sábado" className="alvo" />}
              </CampoFormulario>
            </div>
          </Cartao>
          <Cartao titulo="Valores por fundo" descricao="Escreva só os fundos com valor; o total soma-se sozinho" icone={Wallet} semMargem>
            <ul className="divide-y">
              {fields.map((f, i) => {
                const fundo = fundoPorId.get(f.fundoId)
                return (
                  <li key={f.id} className="grid grid-cols-[1fr_150px] items-center gap-3 px-4 py-3 sm:grid-cols-[1fr_200px_170px] sm:px-6">
                    <div className="min-w-0">
                      <p className="text-sm font-medium">{fundo?.nome}</p>
                      <p className="text-xs text-muted-foreground">{fundo?.destinoEntidadeId ? `Vai para a Associação${Number(fundo.percentagemRemessa ?? '100') < 100 ? ` (${(fundo.percentagemRemessa ?? '').replace('.00', '')}%)` : ''}` : 'Fica na igreja'}</p>
                    </div>
                    <div className="hidden sm:block"><Seleccao aria-label={`Categoria de ${fundo?.nome}`} {...form.register(`linhas.${i}.categoriaId`)} className="h-9 text-xs">
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
    </form>
  )
}
