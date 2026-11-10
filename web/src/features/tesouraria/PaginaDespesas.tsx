/**
 * Despesas (P-07) · "O que foi pedido, o que já está aprovado e o que falta pagar?"
 * Um departamento pede; quem tem a permissão decide (aprova, pode reduzir o valor, ou rejeita com motivo; quem
 * pede não decide); a tesouraria paga com uma saída ligada à despesa, que não precisa de outra aprovação. A
 * despesa passa a PAGA quando o pagamento é confirmado (a base de dados faz isso).
 */
import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Ban, Banknote, CircleCheck, ClipboardList, FilePlus2, Gavel, HandCoins, Hourglass } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Dinheiro, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { CampoData } from '@/components/comum/CampoData'
import { Seleccao } from '@/components/comum/Seleccao'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { centimos, data, deCentimos, dinheiro, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { METODO_DA_CONTA } from './PaginaEntrada'
import { fundosDaIgreja, useCategorias, useContasIgreja as useContas, useCriarMovimento, useDespesas, useDespesasMut, useFundos, type Despesa } from './api'

const VALOR = z.string().regex(/^\d{1,14}(\.\d{1,2})?$/, 'Escreva o valor, por exemplo 1 500,00').refine((v) => Number(v) > 0, 'O valor tem de ser maior que zero')

type Aba = 'decidir' | 'pagar' | 'pagas' | 'outras'
const ABAS: { k: Aba; rotulo: string; de: (d: Despesa) => boolean }[] = [
  { k: 'decidir', rotulo: 'Por decidir', de: (d) => !d.endDate && d.estado === 'SUBMETIDA' },
  { k: 'pagar', rotulo: 'Por pagar', de: (d) => !d.endDate && d.estado === 'APROVADA' },
  { k: 'pagas', rotulo: 'Pagas', de: (d) => !d.endDate && d.estado === 'PAGA' },
  { k: 'outras', rotulo: 'Rejeitadas e canceladas', de: (d) => !!d.endDate || d.estado === 'REJEITADA' || d.estado === 'CANCELADA' },
]

export function PilulaDespesa({ d }: { d: Despesa }) {
  if (d.endDate || d.estado === 'CANCELADA') return <Pilula variante="secondary">Cancelada</Pilula>
  const v = { SUBMETIDA: 'warning', APROVADA: 'info', PAGA: 'success', REJEITADA: 'destructive', CANCELADA: 'secondary' } as const
  const r = { SUBMETIDA: 'Por decidir', APROVADA: 'Aprovada', PAGA: 'Paga', REJEITADA: 'Rejeitada', CANCELADA: 'Cancelada' }
  return <Pilula variante={v[d.estado]}>{r[d.estado]}</Pilula>
}

export default function PaginaDespesas() {
  const { pode, usuario } = useSessao()
  const q = useDespesas()
  const fundos = useFundos()
  const categorias = useCategorias()
  const [aba, setAba] = useState<Aba>('decidir')
  const [pedir, setPedir] = useState(false)
  const [decidir, setDecidir] = useState<Despesa | null>(null)
  const [pagar, setPagar] = useState<Despesa | null>(null)
  const [cancelar, setCancelar] = useState<Despesa | null>(null)
  const mut = useDespesasMut()

  const lista = q.data ?? []
  const soma = (l: Despesa[], campo: 'valorSolicitado' | 'valorAprovado') => deCentimos(l.reduce((s, d) => s + centimos(d[campo] ?? d.valorSolicitado), 0))
  const porDecidir = lista.filter(ABAS[0].de)
  const porPagar = lista.filter(ABAS[1].de)
  const ano = hojeIso().slice(0, 4)
  const pagasAno = lista.filter((d) => ABAS[2].de(d) && (d.aprovadoEm ?? d.criadoEm ?? '').startsWith(ano))
  const visiveis = lista.filter(ABAS.find((a) => a.k === aba)!.de)
  const fundoDe = (id: number) => fundos.data?.find((f) => f.id === id)?.nome ?? '—'
  const categoriaDe = (id: number) => categorias.data?.find((c) => c.id === id)?.nome ?? '—'

  return (
    <>
      <TituloPagina icone={ClipboardList} titulo="Despesas" descricao="Pedidos de despesa: aprovar antes de pagar"
        accoes={pode('tesouraria.despesa.criar') && <Button className="alvo" onClick={() => setPedir(true)}><FilePlus2 className="size-4" />Pedir despesa</Button>} />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4 [&>*:last-child]:col-span-2 sm:[&>*:last-child]:col-span-1">
          <Indicador rotulo="Por decidir" valor={porDecidir.length} nota={dinheiro(soma(porDecidir, 'valorSolicitado'))} icone={Hourglass} tom="warning" aCarregar={q.isPending}
            aoClicar={() => setAba('decidir')} activo={aba === 'decidir'} />
          <Indicador rotulo="Aprovadas por pagar" valor={<Dinheiro valor={soma(porPagar, 'valorAprovado')} />} nota={`${porPagar.length} despesa(s)`} icone={HandCoins} tom="info" aCarregar={q.isPending}
            aoClicar={() => setAba('pagar')} activo={aba === 'pagar'} />
          <Indicador rotulo={`Pagas em ${ano}`} valor={<Dinheiro valor={soma(pagasAno, 'valorAprovado')} />} nota={`${pagasAno.length} despesa(s)`} icone={CircleCheck} tom="success" aCarregar={q.isPending}
            aoClicar={() => setAba('pagas')} activo={aba === 'pagas'} />
        </div>

        <section className="min-w-0 rounded-xl border bg-card shadow-card">
          <div className="border-b px-4 py-3 sm:px-6">
            <div role="tablist" aria-label="Filtrar" className="flex flex-wrap gap-1 rounded-lg bg-muted p-1 sm:inline-flex">
              {ABAS.map((a) => (
                <button key={a.k} role="tab" aria-selected={aba === a.k} type="button" onClick={() => setAba(a.k)}
                  className={cn('alvo rounded-md px-3 py-1.5 text-xs font-medium text-muted-foreground', aba === a.k && 'bg-card text-foreground shadow-sm')}>
                  {a.rotulo} <span className="num ml-1 opacity-70">{lista.filter(a.de).length}</span>
                </button>
              ))}
            </div>
          </div>
          {q.isPending ? <LinhasACarregar linhas={5} />
            : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="m-4" />
            : visiveis.length === 0 ? (
              <EstadoVazio icone={ClipboardList} titulo={aba === 'decidir' ? 'Nada por decidir' : 'Sem despesas'}>
                {aba === 'decidir' ? 'Os pedidos de despesa dos departamentos aparecem aqui até alguém os aprovar ou rejeitar.' : 'Nenhuma despesa neste estado.'}
              </EstadoVazio>
            ) : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Despesa</th><th className="hidden md:table-cell">Fundo</th><th>Estado</th><th className="num">Valor</th><th className="sm:pr-6"><span className="sr-only">Acções</span></th></tr></thead>
                <tbody>
                  {visiveis.map((d) => {
                    const minha = d.solicitadoPorUsuarioId === usuario?.id
                    return (
                      <tr key={d.id} className={cn(d.endDate && 'opacity-60')}>
                        <td className="sm:pl-6">
                          <p className="font-medium">{d.descricao}</p>
                          <p className="text-xs text-muted-foreground">
                            {d.fornecedor ? `${d.fornecedor} · ` : ''}{categoriaDe(d.categoriaId)} · pedida em {data(d.criadoEm)}
                            {d.estado === 'REJEITADA' && d.motivoRejeicao ? ` · ${d.motivoRejeicao}` : ''}
                          </p>
                        </td>
                        <td className="hidden text-muted-foreground md:table-cell">{fundoDe(d.fundoId)}</td>
                        <td><PilulaDespesa d={d} /></td>
                        <td className="num whitespace-nowrap">
                          <Dinheiro valor={d.valorAprovado ?? d.valorSolicitado} />
                          {d.valorAprovado && d.valorAprovado !== d.valorSolicitado && <p className="text-xs text-muted-foreground line-through"><Dinheiro valor={d.valorSolicitado} /></p>}
                        </td>
                        <td className="sm:pr-6">
                          <div className="flex justify-end gap-2">
                            {!d.endDate && d.estado === 'SUBMETIDA' && pode('tesouraria.despesa.aprovar') && !minha && (
                              <Button size="sm" className="alvo" onClick={() => setDecidir(d)}><Gavel className="size-4" />Decidir</Button>
                            )}
                            {!d.endDate && d.estado === 'APROVADA' && pode('tesouraria.transacao.criar') && (
                              <Button size="sm" className="alvo" onClick={() => setPagar(d)}><Banknote className="size-4" />Pagar</Button>
                            )}
                            {!d.endDate && (d.estado === 'SUBMETIDA' || d.estado === 'APROVADA') && pode('tesouraria.despesa.terminar') && (
                              <Button size="sm" variant="ghost" className="alvo text-muted-foreground" aria-label={`Cancelar ${d.descricao}`} onClick={() => setCancelar(d)}><Ban className="size-4" /></Button>
                            )}
                          </div>
                          {!d.endDate && d.estado === 'SUBMETIDA' && minha && <p className="text-right text-xs text-muted-foreground">outra pessoa decide</p>}
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </Tabela>
            )}
        </section>
        {aba === 'pagas' && pagasAno.length > 0 && (
          <p className="text-sm text-muted-foreground">Cada pagamento está em <Link to="/tesouraria/movimentos?ver=saidas" className="font-medium text-primary hover:underline">Movimentos</Link>.</p>
        )}
      </div>

      {pedir && <DialogoPedir aberto={pedir} aoMudar={setPedir} />}
      {decidir && <DialogoDecidir d={decidir} aoFechar={() => setDecidir(null)} />}
      {pagar && <DialogoPagar d={pagar} aoFechar={() => setPagar(null)} />}
      <DialogoConfirmar aberto={!!cancelar} aoMudar={(v) => !v && setCancelar(null)} titulo="Cancelar este pedido de despesa?"
        texto={<>“{cancelar?.descricao}” deixa de poder ser paga e fica no histórico como cancelada.</>} accao="Cancelar pedido" perigo
        aCorrer={mut.cancelar.isPending}
        aoConfirmar={() => cancelar && mut.cancelar.mutate(cancelar.id, {
          onSuccess: () => { toast.success('Pedido de despesa cancelado.'); setCancelar(null) },
          onError: (e) => { toast.error(mensagemDe(e)); setCancelar(null) },
        })} />
    </>
  )
}

/* -------------------------------------------------------------------- pedir */
const esquemaPedir = z.object({
  descricao: z.string().trim().min(3, 'Diga para que é a despesa').max(255),
  fornecedor: z.string().trim().max(150),
  valor: VALOR,
  categoriaId: z.string().min(1, t.comum.obrigatorio),
  fundoId: z.string().min(1, t.comum.obrigatorio),
})

function DialogoPedir({ aberto, aoMudar }: { aberto: boolean; aoMudar: (v: boolean) => void }) {
  const igreja = useIgreja()
  const { usuario } = useSessao()
  const fundos = useFundos()
  const categorias = useCategorias()
  const { pedir } = useDespesasMut()
  const [erro, setErro] = useState<string | null>(null)
  const locais = fundosDaIgreja(fundos.data)
  const cats = (categorias.data ?? []).filter((c) => c.tipo === 'DESPESA' && !c.eRemessa)
  const form = useForm<z.infer<typeof esquemaPedir>>({
    resolver: zodResolver(esquemaPedir),
    values: {
      descricao: '', fornecedor: '', valor: '', categoriaId: String(cats[0]?.id ?? ''),
      fundoId: String(locais.find((f) => f.tipo === 'ORCAMENTO_LOCAL')?.id ?? locais[0]?.id ?? ''),
    },
    resetOptions: { keepDirtyValues: true },
  })
  const e = form.formState.errors

  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    try {
      await pedir.mutateAsync({
        igrejaId: igreja.id, descricao: v.descricao, fornecedor: v.fornecedor || undefined, valorSolicitado: v.valor,
        categoriaId: Number(v.categoriaId), fundoId: Number(v.fundoId), solicitadoPorUsuarioId: usuario!.id,
      } as never)
      toast.success('Despesa pedida. Outra pessoa com permissão decide.')
      aoMudar(false)
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })

  return (
    <Dialog open={aberto} onOpenChange={aoMudar}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Pedir despesa</DialogTitle>
          <DialogDescription>O pedido fica por decidir até um ancião, o pastor ou a comissão o aprovar.</DialogDescription>
        </DialogHeader>
        <form onSubmit={submeter} noValidate className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <CampoFormulario rotulo="Para quê" erro={e.descricao?.message} obrigatorio>
            {(p) => <Input {...p} {...form.register('descricao')} placeholder="ex.: Tinta para a fachada" className="alvo" autoFocus />}
          </CampoFormulario>
          <div className="grid gap-4 sm:grid-cols-2">
            <CampoFormulario rotulo="Fornecedor" erro={e.fornecedor?.message}>
              {(p) => <Input {...p} {...form.register('fornecedor')} placeholder="ex.: Ferragem Nhamatanda" className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo="Valor pedido" erro={e.valor?.message} obrigatorio>
              {(p) => <Controller control={form.control} name="valor" render={({ field }) => <CampoDinheiro {...p} {...field} className="alvo" />} />}
            </CampoFormulario>
            <CampoFormulario rotulo="Categoria" erro={e.categoriaId?.message}>
              {(p) => <Seleccao {...p} {...form.register('categoriaId')}>{cats.map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}</Seleccao>}
            </CampoFormulario>
            <CampoFormulario rotulo="Paga pelo fundo" erro={e.fundoId?.message}>
              {(p) => <Seleccao {...p} {...form.register('fundoId')}>{locais.map((f) => <option key={f.id} value={f.id}>{f.nome}</option>)}</Seleccao>}
            </CampoFormulario>
          </div>
          <DialogFooter>
            <Button type="button" variant="outline" className="alvo" onClick={() => aoMudar(false)}>{t.comum.cancelar}</Button>
            <Button type="submit" className="alvo" disabled={form.formState.isSubmitting}>{form.formState.isSubmitting ? t.comum.aGravar : 'Pedir despesa'}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

/* -------------------------------------------------------------------- decidir */
function DialogoDecidir({ d, aoFechar }: { d: Despesa; aoFechar: () => void }) {
  const { decidir } = useDespesasMut()
  const [rejeitar, setRejeitar] = useState(false)
  const [valor, setValor] = useState(d.valorSolicitado)
  const [motivo, setMotivo] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const valido = /^\d{1,14}(\.\d{1,2})?$/.test(valor) && Number(valor) > 0
  const acima = valido && centimos(valor) > centimos(d.valorSolicitado)

  const submeter = async () => {
    setErro(null)
    if (rejeitar ? motivo.trim().length < 3 : !valido || acima) { setErro(rejeitar ? 'Diga porque é rejeitada.' : acima ? 'Não pode aprovar mais do que o pedido.' : 'Escreva o valor aprovado.'); return }
    try {
      await decidir.mutateAsync(rejeitar ? { id: d.id, aprovar: false, motivo: motivo.trim() } : { id: d.id, aprovar: true, valor, motivo: motivo.trim() || undefined })
      toast.success(rejeitar ? 'Despesa rejeitada.' : 'Despesa aprovada. A tesouraria já a pode pagar.')
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Decidir a despesa</DialogTitle>
          <DialogDescription>{d.descricao}{d.fornecedor ? ` · ${d.fornecedor}` : ''} · pedido de {dinheiro(d.valorSolicitado)}</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div role="radiogroup" aria-label="Decisão" className="grid grid-cols-2 gap-2">
            {[{ v: false, r: 'Aprovar' }, { v: true, r: 'Rejeitar' }].map((o) => (
              <button key={o.r} type="button" role="radio" aria-checked={rejeitar === o.v} onClick={() => setRejeitar(o.v)}
                className={cn('alvo rounded-lg border px-3 py-2 text-sm font-medium', rejeitar === o.v ? (o.v ? 'border-destructive bg-tint-destructive text-destructive-text' : 'border-primary bg-primary/10 text-primary') : 'text-muted-foreground')}>
                {o.r}
              </button>
            ))}
          </div>
          {!rejeitar && (
            <div className="grid gap-1.5">
              <label htmlFor="dec-valor" className="text-sm font-medium">Valor aprovado</label>
              <CampoDinheiro id="dec-valor" value={valor} onChange={setValor} className="alvo" />
              <p className="text-xs text-muted-foreground">Pode aprovar menos do que o pedido, nunca mais.</p>
            </div>
          )}
          <div className="grid gap-1.5">
            <label htmlFor="dec-motivo" className="text-sm font-medium">{rejeitar ? 'Motivo' : 'Nota'}{rejeitar && <span className="text-destructive-text"> *</span>}</label>
            <Textarea id="dec-motivo" rows={2} value={motivo} onChange={(e) => setMotivo(e.target.value)} placeholder={rejeitar ? 'ex.: fica para o orçamento do próximo trimestre' : 'opcional'} />
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className={cn('alvo', rejeitar && 'bg-destructive text-white hover:bg-destructive/90')} disabled={decidir.isPending} onClick={submeter}>
            {decidir.isPending ? t.comum.aGravar : rejeitar ? 'Rejeitar' : 'Aprovar'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/* -------------------------------------------------------------------- pagar */
function DialogoPagar({ d, aoFechar }: { d: Despesa; aoFechar: () => void }) {
  const contas = useContas()
  const criar = useCriarMovimento()
  const [chave] = useState(() => crypto.randomUUID())
  const aprovado = d.valorAprovado ?? d.valorSolicitado
  const [contaId, setContaId] = useState('')
  const [metodo, setMetodo] = useState('')
  const [dia, setDia] = useState(hojeIso())
  const [valor, setValor] = useState(aprovado)
  const [referencia, setReferencia] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const conta = contas.data?.find((c) => String(c.id) === contaId) ?? contas.data?.[0]
  const met = metodo || METODO_DA_CONTA[conta?.tipo ?? 'CAIXA']

  const submeter = async () => {
    setErro(null)
    if (!/^\d{1,14}(\.\d{1,2})?$/.test(valor) || Number(valor) <= 0) { setErro('Escreva o valor pago.'); return }
    if (centimos(valor) > centimos(aprovado)) { setErro(`Não pode pagar mais do que o aprovado (${dinheiro(aprovado)}).`); return }
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dia) || dia > hojeIso()) { setErro('A data tem de ser dd/mm/aaaa e não pode ser no futuro.'); return }
    try {
      const { transacao } = await criar.mutateAsync({
        chave, confirmar: true,
        corpo: {
          tipo: 'SAIDA', metodo: met, valorTotal: valor, contaId: conta!.id, dataHora: `${dia}T12:00:00+02:00`, despesaId: d.id,
          beneficiario: d.fornecedor || d.descricao, descricao: d.descricao, referencia: referencia || undefined,
          linhas: [{ fundoId: d.fundoId, categoriaId: d.categoriaId, valor }],
        } as never,
      })
      toast.success(transacao.estado === 'CONFIRMADA' ? 'Despesa paga e confirmada.' : 'Pagamento registado; falta confirmar na ficha do movimento.')
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Pagar a despesa</DialogTitle>
          <DialogDescription>{d.descricao} · aprovada por {dinheiro(aprovado)}. Já foi aprovada: o pagamento confirma-se logo.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="grid gap-1.5">
              <label htmlFor="pag-conta" className="text-sm font-medium">Conta</label>
              <Seleccao id="pag-conta" value={conta ? String(conta.id) : ''} onChange={(e) => { setContaId(e.target.value); setMetodo('') }}>
                {(contas.data ?? []).map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
              </Seleccao>
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="pag-metodo" className="text-sm font-medium">Forma de pagamento</label>
              <Seleccao id="pag-metodo" value={met} onChange={(e) => setMetodo(e.target.value)}>
                {Object.entries(rotulos.metodo).map(([k, r]) => <option key={k} value={k}>{r}</option>)}
              </Seleccao>
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="pag-valor" className="text-sm font-medium">Valor pago</label>
              <CampoDinheiro id="pag-valor" value={valor} onChange={setValor} className="alvo" />
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="pag-data" className="text-sm font-medium">Data</label>
              <CampoData id="pag-data" value={dia} onChange={setDia} className="alvo" />
            </div>
            <div className="grid gap-1.5 sm:col-span-2">
              <label htmlFor="pag-ref" className="text-sm font-medium">Referência</label>
              <Input id="pag-ref" value={referencia} onChange={(e) => setReferencia(e.target.value)} placeholder="n.º da factura ou do recibo" className="alvo num" />
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={criar.isPending || !conta} onClick={submeter}>{criar.isPending ? t.comum.aGravar : 'Pagar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
