/**
 * Um movimento: cabeçalho, linhas por fundo e as acções que o seu estado permite — confirmar, aprovar (saída,
 * por outra pessoa), emitir e imprimir o recibo, anular um pendente. Um movimento confirmado não se altera:
 * corrige-se com um estorno (a base de dados garante-o).
 */
import { CabecalhoDocumento } from '@/components/layout/Marca'
import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { ArrowLeft, Ban, Check, Plus, CircleCheck, Printer, Receipt, ShieldCheck, Undo2, Wallet } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Campo, Cartao, Dinheiro, Tabela } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { ErroApi, mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { data, dataPorExtenso, dinheiro } from '@/lib/formatos'
import { useMembrosBasicos } from '@/features/membros/api'
import { useFamiliasResumo } from '@/features/secretaria/api'
import { useAccao, useCategorias, useContas, useEstornosDe, useFundos, useLinhas, useRecibo, useTransacao } from './api'
import { DialogoEstorno } from './Estorno'
import { CartaoComprovativos } from './Comprovativos'
import { PilulaEstado, Valor, quem } from './comum'

export default function PaginaMovimento() {
  const id = Number(useParams().id)
  const igreja = useIgreja()
  const { pode, usuario } = useSessao()
  const q = useTransacao(id)
  const linhas = useLinhas(id)
  const recibo = useRecibo(id)
  const fundos = useFundos()
  const categorias = useCategorias()
  const contas = useContas()
  const basicos = useMembrosBasicos()
  const accoes = useAccao(id)
  const [anular, setAnular] = useState(false)
  const [estorno, setEstorno] = useState(false)
  const estornos = useEstornosDe(id)
  const nomeDe = (mid: number) => { const m = basicos.data?.find((x) => x.id === mid); return m && `${m.nome} ${m.apelido}` }
  const familias = useFamiliasResumo()
  const nomeFamilia = (fid: number) => familias.data?.find((f) => f.id === fid)?.nome

  const voltar = <Link to="/tesouraria/movimentos" className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground print:hidden"><ArrowLeft className="size-4" /> {t.tesouraria.movimentos}</Link>
  if (q.isPending) return <>{voltar}<Barra className="h-48 w-full" /></>
  if (q.isError) return <>{voltar}{q.error instanceof ErroApi && q.error.naoEncontrado
    ? <div className="rounded-xl border bg-card shadow-card"><EstadoVazio icone={Wallet} titulo="Movimento não encontrado">Este movimento não existe ou não é desta igreja.</EstadoVazio></div>
    : <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />}</>

  const tr = q.data
  const pendente = tr.estado === 'PENDENTE' && !tr.endDate
  const saida = tr.tipo === 'SAIDA'
  const aprovada = !!tr.aprovadoPorUsuarioId
  const fuiEu = tr.criadoPor === usuario?.id
  const podeConfirmar = pendente && pode('tesouraria.transacao.alterar') && (!saida || aprovada)
  const podeAprovar = pendente && saida && !aprovada && pode('tesouraria.transacao.aprovar')
  const podeRecibo = tr.estado === 'CONFIRMADA' && tr.tipo === 'ENTRADA' && !!(tr.membroId || tr.familiaId) && !recibo.data && recibo.isSuccess && pode('tesouraria.recibo.criar')
  const estornosValidos = (estornos.data ?? []).filter((x) => !x.endDate)
  const podeEstornar = tr.estado === 'CONFIRMADA' && !tr.endDate && !tr.estornoTransacaoId && tr.tipo !== 'TRANSFERENCIA' && pode('tesouraria.transacao.criar') && linhas.isSuccess
  const fundoDe = (fid: number) => fundos.data?.find((f) => f.id === fid)?.nome ?? `Fundo ${fid}`
  const categoriaDe = (cid: number) => categorias.data?.find((c) => c.id === cid)?.nome ?? '—'
  const correr = (m: { mutate: (v: undefined, o: object) => void }, ok: string) =>
    m.mutate(undefined, { onSuccess: () => toast.success(ok), onError: (e: unknown) => toast.error(mensagemDe(e)) })
  const quando = dataPorExtenso(tr.dataHora)

  return (
    <>
      {voltar}
      <div className="print:hidden">
        <section className="mb-6 rounded-xl border bg-card p-5 shadow-card sm:p-6">
          <div className="flex flex-col gap-5 sm:flex-row sm:items-center">
            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-center gap-2">
                <h1 className="text-2xl font-semibold tracking-tight">{rotulos.tipoTransacao[tr.tipo]} · {quem(tr, nomeDe, nomeFamilia)}</h1>
                <PilulaEstado tr={tr} />
              </div>
              <p className="mt-1 text-sm text-muted-foreground">{quando.charAt(0).toUpperCase() + quando.slice(1)} · {rotulos.metodo[tr.metodo ?? ''] ?? tr.metodo}{tr.descricao ? ` · ${tr.descricao}` : ''}</p>
            </div>
            <Valor tr={tr} className="text-3xl tracking-tight" />
          </div>
          {(podeConfirmar || podeAprovar || podeRecibo || recibo.data || podeEstornar || (pendente && pode('tesouraria.transacao.terminar'))) && (
            <div className="mt-5 flex flex-wrap gap-2 border-t pt-5">
              {podeAprovar && (
                <Button className="alvo" disabled={accoes.aprovar.isPending} onClick={() => correr(accoes.aprovar, 'Saída aprovada. Já pode ser confirmada.')}>
                  <ShieldCheck className="size-4" /> Aprovar saída
                </Button>
              )}
              {podeConfirmar && (
                <Button className="alvo" variant={podeAprovar ? 'outline' : 'default'} disabled={accoes.confirmar.isPending} onClick={() => correr(accoes.confirmar, 'Movimento confirmado: já conta nos saldos.')}>
                  <CircleCheck className="size-4" /> Confirmar
                </Button>
              )}
              {podeRecibo && (
                <Button className="alvo" disabled={accoes.recibo.isPending} onClick={() => correr(accoes.recibo, 'Recibo emitido.')}>
                  <Receipt className="size-4" /> Emitir recibo
                </Button>
              )}
              {recibo.data && <Button variant="outline" className="alvo" onClick={() => window.print()}><Printer className="size-4" /> Imprimir recibo n.º {recibo.data.numero}/{recibo.data.ano}</Button>}
              {podeEstornar && (
                <Button variant="outline" className="alvo" onClick={() => setEstorno(true)}><Undo2 className="size-4" /> Estornar</Button>
              )}
              {pendente && pode('tesouraria.transacao.terminar') && (
                <Button variant="outline" className="alvo text-destructive-text hover:text-destructive-text" onClick={() => setAnular(true)}><Ban className="size-4" /> Anular</Button>
              )}
            </div>
          )}
          {pendente && saida && !aprovada && (
            <p className="mt-4 rounded-lg border border-warning/30 bg-tint-warning px-4 py-3 text-sm text-warning-text">
              {fuiEu ? 'Foi você que registou esta saída: tem de ser aprovada por outra pessoa (ancião ou pastor).' : 'Esta saída espera aprovação antes de ser confirmada.'}
            </p>
          )}
          {tr.estornoTransacaoId && (
            <p className="mt-4 rounded-lg border bg-muted/40 px-4 py-3 text-sm">
              Estorno do <Link to={`/tesouraria/movimentos/${tr.estornoTransacaoId}`} className="font-medium text-primary hover:underline">movimento n.º {tr.estornoTransacaoId}</Link>.
            </p>
          )}
          {estornosValidos.length > 0 && (
            <p className="mt-4 rounded-lg border bg-muted/40 px-4 py-3 text-sm">
              Já tem {estornosValidos.length === 1 ? 'um estorno' : `${estornosValidos.length} estornos`}:{' '}
              {estornosValidos.map((x, i) => <span key={x.id}>{i > 0 && ', '}<Link to={`/tesouraria/movimentos/${x.id}`} className="font-medium text-primary hover:underline">n.º {x.id}</Link> ({dinheiro(x.valorTotal)}, {x.estado === 'CONFIRMADA' ? 'confirmado' : 'pendente'})</span>)}.
            </p>
          )}
          {tr.estado === 'CONFIRMADA' && (
            <div className="mt-4 flex flex-wrap items-center justify-between gap-3 text-sm text-muted-foreground">
              <p className="flex items-center gap-2"><Check className="size-4 flex-none" />Confirmado: não se altera. Para corrigir, registe um estorno.</p>
              {tr.tipo === 'ENTRADA' && tr.membroId && pode('tesouraria.transacao.criar') && (
                <Button asChild variant="outline" size="sm" className="alvo">
                  <Link to={`/tesouraria/entrada?membro=${tr.membroId}&conta=${tr.contaId}`}><Plus className="size-4" />Lançar outra entrada deste membro</Link>
                </Button>
              )}
            </div>
          )}
        </section>

        <div className="grid items-start gap-6 lg:grid-cols-12">
          <Cartao titulo="Por fundo" descricao="Como o valor se divide" icone={Wallet} semMargem className="lg:col-span-8">
            {linhas.isPending ? <div className="px-6 pb-6"><Barra className="h-20 w-full" /></div>
              : linhas.isError ? <EstadoErro erro={linhas.error} aoTentar={() => linhas.refetch()} className="mx-6 mb-6" />
              : (
                <Tabela>
                  <thead><tr><th className="sm:pl-6">Fundo</th><th>Categoria</th><th className="num sm:pr-6">Valor</th></tr></thead>
                  <tbody>
                    {(linhas.data ?? []).map((l) => (
                      <tr key={l.id}><td className="font-medium sm:pl-6">{fundoDe(l.fundoId)}</td><td className="text-muted-foreground">{categoriaDe(l.categoriaId)}</td><td className="num sm:pr-6"><Dinheiro valor={l.valor} /></td></tr>
                    ))}
                    <tr className="bg-muted/30"><td className="font-semibold sm:pl-6" colSpan={2}>Total</td><td className="num font-semibold sm:pr-6"><Dinheiro valor={tr.valorTotal} /></td></tr>
                  </tbody>
                </Tabela>
              )}
          </Cartao>
          <div className="grid gap-6 lg:col-span-4">
          <Cartao titulo="Dados">
            <dl className="grid gap-4">
              <Campo rotulo="Conta">{tr.contaId ? contas.data?.find((c) => c.id === tr.contaId)?.nome : null}</Campo>
              <Campo rotulo="Referência">{tr.referencia}</Campo>
              <Campo rotulo="Recibo">{recibo.data ? `n.º ${recibo.data.numero}/${recibo.data.ano}` : null}</Campo>
              {saida && <Campo rotulo="Aprovação">{aprovada ? 'Aprovada por outra pessoa' : 'Por aprovar'}</Campo>}
            </dl>
          </Cartao>
          <CartaoComprovativos transacaoId={id} />
          </div>
        </div>
      </div>

      {/* recibo impresso */}
      {recibo.data && (
        <div className="hidden print:block">
          <div className="mx-auto max-w-[180mm] border border-black p-8 text-black">
            <div className="flex items-start justify-between">
              <CabecalhoDocumento titulo={igreja.nome} />
              <div className="text-right"><p className="text-sm">Recibo</p><p className="text-lg font-bold">n.º {recibo.data.numero}/{recibo.data.ano}</p></div>
            </div>
            <p className="mt-8">Recebemos de <strong>{quem(tr, nomeDe, nomeFamilia)}</strong> a quantia de <strong>{dinheiro(tr.valorTotal)}</strong>, em {data(tr.dataHora)}, por {rotulos.metodo[tr.metodo ?? ''] ?? tr.metodo}:</p>
            <table className="mt-4 w-full text-sm">
              <tbody>
                {(linhas.data ?? []).map((l) => <tr key={l.id} className="border-b border-black/30"><td className="py-1">{fundoDe(l.fundoId)}</td><td className="py-1 text-right">{dinheiro(l.valor)}</td></tr>)}
                <tr><td className="pt-2 font-bold">Total</td><td className="pt-2 text-right font-bold">{dinheiro(tr.valorTotal)}</td></tr>
              </tbody>
            </table>
            <p className="mt-10 text-sm">Deus o abençoe.</p>
            <div className="mt-12 w-60 border-t border-black pt-1 text-center text-sm">O(A) Tesoureiro(a)</div>
          </div>
        </div>
      )}

      {podeEstornar && estorno && <DialogoEstorno tr={tr} linhas={linhas.data ?? []} fundoDe={fundoDe} aberto={estorno} aoMudar={setEstorno} />}

      <DialogoConfirmar aberto={anular} aoMudar={setAnular} titulo="Anular este movimento?"
        texto="O movimento pendente deixa de contar e fica no histórico como anulado. Nada se apaga." accao="Anular" perigo
        aCorrer={accoes.anular.isPending}
        aoConfirmar={() => accoes.anular.mutate(undefined, { onSuccess: () => { toast.success('Movimento anulado.'); setAnular(false) }, onError: (e) => { toast.error(mensagemDe(e)); setAnular(false) } })} />
    </>
  )
}
