/**
 * Orçamento anual (F-TES-11): o tesoureiro prepara o previsto por categoria (receitas e despesas), a igreja aprova
 * em reunião (voto) e, durante o ano, vê-se o realizado ao lado do previsto (vista vw_execucao_orcamento: só
 * movimentos confirmados do ano). Aprovar exige a permissão tesouraria.orcamento.aprovar — a base de dados decide.
 */
import { useEffect, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { CircleCheck, ClipboardList, Printer, Plus, Save } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Dinheiro, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { centimos, deCentimos } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { CampoVoto } from '@/features/livro/CampoVoto'
import { useCategorias, useExecucaoOrcamento, useLinhasOrcamento, useOrcamentoMut, useOrcamentos, type Categoria, type Orcamento } from './api'

const ESTADO = { RASCUNHO: { r: 'Em preparação', v: 'warning' as const }, APROVADO: { r: 'Aprovado', v: 'success' as const }, ENCERRADO: { r: 'Encerrado', v: 'secondary' as const } }
const mt = (c: number) => deCentimos(c)

export default function PaginaOrcamento() {
  const { pode } = useSessao()
  const igreja = useIgreja()
  const orcs = useOrcamentos()
  const { criar } = useOrcamentoMut()
  const [params, setParams] = useSearchParams()
  const daIgreja = (orcs.data ?? []).filter((o) => !o.endDate && !o.departamentoIgrejaId).sort((a, b) => b.ano - a.ano)
  const anoActual = new Date().getFullYear()
  const anoPedido = Number(params.get('ano')) || null
  const sel = daIgreja.find((o) => o.ano === anoPedido) ?? daIgreja.find((o) => o.ano === anoActual) ?? daIgreja[0]
  const anosEmFalta = [anoActual, anoActual + 1].filter((a) => !daIgreja.some((o) => o.ano === a))

  const preparar = (ano: number) => criar.mutate({ igrejaId: igreja.id, ano }, {
    onSuccess: () => { toast.success(`Orçamento de ${ano} criado: preencha o previsto de cada categoria.`); setParams({ ano: String(ano) }) },
    onError: (e) => toast.error(mensagemDe(e)),
  })

  return (
    <>
      <TituloPagina icone={ClipboardList} titulo="Orçamento anual" descricao="O previsto para o ano, aprovado pela igreja, e o realizado ao longo do ano"
        accoes={(
          <>
            {sel && <Button variant="outline" className="alvo print:hidden" onClick={() => window.print()}><Printer className="size-4" />Imprimir</Button>}
            {pode('tesouraria.orcamento.criar') && anosEmFalta.map((a) => (
              <Button key={a} variant={sel ? 'outline' : 'default'} className="alvo print:hidden" disabled={criar.isPending} onClick={() => preparar(a)}><Plus className="size-4" />Orçamento de {a}</Button>
            ))}
          </>
        )} />
      {orcs.isPending ? <Barra className="h-64 w-full" />
        : orcs.isError ? <EstadoErro erro={orcs.error} aoTentar={() => orcs.refetch()} />
        : !sel ? (
          <Cartao>
            <EstadoVazio icone={ClipboardList} titulo="Ainda não há orçamento"
              accao={pode('tesouraria.orcamento.criar') && <Button className="alvo" disabled={criar.isPending} onClick={() => preparar(anoActual)}><Plus className="size-4" />Preparar o orçamento de {anoActual}</Button>}>
              O tesoureiro prepara o previsto de receitas e despesas por categoria; depois a igreja aprova-o em reunião.
            </EstadoVazio>
          </Cartao>
        ) : (
          <>
            {daIgreja.length > 1 && (
              <div role="tablist" aria-label="Ano" className="mb-4 flex flex-wrap gap-2 print:hidden">
                {daIgreja.map((o) => (
                  <button key={o.id} role="tab" aria-selected={o.id === sel.id} onClick={() => setParams({ ano: String(o.ano) })}
                    className={cn('alvo rounded-full border px-4 text-sm font-medium tabular-nums', o.id === sel.id ? 'border-primary bg-primary text-primary-foreground' : 'bg-card text-muted-foreground hover:text-foreground')}>
                    {o.ano}
                  </button>
                ))}
              </div>
            )}
            <Detalhe key={sel.id} o={sel} />
          </>
        )}
    </>
  )
}

function Detalhe({ o }: { o: Orcamento }) {
  const { pode } = useSessao()
  const categorias = useCategorias()
  const linhas = useLinhasOrcamento(o.id)
  const execucao = useExecucaoOrcamento()
  const { linha, mudarLinha, tirarLinha } = useOrcamentoMut()
  const [valores, setValores] = useState<Record<number, string>>({})
  const [aprovar, setAprovar] = useState(false)
  const [aGravar, setAGravar] = useState(false)
  const editavel = o.estado === 'RASCUNHO' && pode('tesouraria.orcamento_linha.criar')
  const activas = useMemo(() => (linhas.data ?? []).filter((l) => !l.endDate), [linhas.data])
  const porCat = useMemo(() => new Map(activas.map((l) => [l.categoriaId, l])), [activas])
  const realizado = useMemo(() => new Map((execucao.data ?? []).filter((e) => e.id === o.id).map((e) => [e.codigo, e])), [execucao.data, o.id])
  useEffect(() => { setValores(Object.fromEntries(activas.map((l) => [l.categoriaId, l.valorPrevisto]))) }, [activas])

  if (categorias.isPending || linhas.isPending) return <Barra className="h-64 w-full" />
  if (linhas.isError) return <EstadoErro erro={linhas.error} aoTentar={() => linhas.refetch()} />
  const cats = (categorias.data ?? []).filter((c) => !c.endDate)
  const visiveis = (tipo: 'RECEITA' | 'DESPESA') => cats.filter((c) => c.tipo === tipo && (editavel || porCat.has(c.id))).sort((a, b) => a.codigo.localeCompare(b.codigo, 'pt', { numeric: true }))
  const previsto = (c: Categoria) => centimos(valores[c.id] || '0')
  const total = (tipo: 'RECEITA' | 'DESPESA') => visiveis(tipo).reduce((s, c) => s + (editavel ? previsto(c) : centimos(porCat.get(c.id)?.valorPrevisto ?? '0')), 0)
  const totalReal = (tipo: 'RECEITA' | 'DESPESA') => visiveis(tipo).reduce((s, c) => s + centimos(realizado.get(c.codigo)?.realizado ?? '0'), 0)
  const mudancas = cats.filter((c) => {
    const antes = porCat.get(c.id)?.valorPrevisto ?? ''
    const agora = valores[c.id] ?? ''
    return centimos(antes || '0') !== centimos(agora || '0')
  })

  const gravar = async () => {
    setAGravar(true)
    try {
      for (const c of mudancas) {
        const l = porCat.get(c.id)
        const v = valores[c.id] || ''
        if (l && !centimos(v || '0')) await tirarLinha.mutateAsync(l.id)
        else if (l) await mudarLinha.mutateAsync({ id: l.id, valorPrevisto: v })
        else if (centimos(v || '0') > 0) await linha.mutateAsync({ orcamentoId: o.id, categoriaId: c.id, valorPrevisto: v })
      }
      toast.success('Orçamento gravado.')
    } catch (e) {
      toast.error(mensagemDe(e))
    } finally {
      setAGravar(false)
    }
  }

  const receitas = total('RECEITA'), despesas = total('DESPESA')
  const tabela = (tipo: 'RECEITA' | 'DESPESA') => (
    <Cartao titulo={tipo === 'RECEITA' ? 'Receitas' : 'Despesas'} semMargem>
      <Tabela>
        <thead>
          <tr><th className="sm:pl-6">Categoria</th><th className="num">Previsto</th>{o.estado !== 'RASCUNHO' && <><th className="num">Realizado</th><th className="num sm:pr-6">%</th></>}</tr>
        </thead>
        <tbody>
          {visiveis(tipo).map((c) => {
            const r = realizado.get(c.codigo)
            const pct = r?.pctExecucao != null ? Number(r.pctExecucao) : null
            return (
              <tr key={c.id}>
                <td className="sm:pl-6"><span className="mr-2 text-xs text-muted-foreground tabular-nums">{c.codigo}</span>{c.nome}</td>
                <td className={cn('num', o.estado === 'RASCUNHO' && 'sm:pr-6')}>
                  {editavel
                    ? <CampoDinheiro aria-label={`Previsto para ${c.nome}`} value={valores[c.id] ?? ''} onChange={(v) => setValores((x) => ({ ...x, [c.id]: v }))} className="alvo ml-auto w-36 text-right" />
                    : <Dinheiro valor={porCat.get(c.id)?.valorPrevisto ?? '0.00'} />}
                </td>
                {o.estado !== 'RASCUNHO' && (
                  <>
                    <td className="num"><Dinheiro valor={r?.realizado ?? '0.00'} /></td>
                    <td className={cn('num sm:pr-6', pct != null && pct > 100 && tipo === 'DESPESA' && 'font-semibold text-destructive-text')}>{pct != null ? `${String(pct).replace('.', ',')}%` : '—'}</td>
                  </>
                )}
              </tr>
            )
          })}
          <tr className="bg-muted/30 font-semibold">
            <td className="sm:pl-6">Total</td>
            <td className={cn('num', o.estado === 'RASCUNHO' && 'sm:pr-6')}><Dinheiro valor={mt(tipo === 'RECEITA' ? receitas : despesas)} /></td>
            {o.estado !== 'RASCUNHO' && <><td className="num"><Dinheiro valor={mt(totalReal(tipo))} /></td><td className="sm:pr-6" /></>}
          </tr>
        </tbody>
      </Tabela>
    </Cartao>
  )

  const est = ESTADO[o.estado] ?? ESTADO.RASCUNHO
  return (
    <div className="grid gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <h2 className="text-lg font-semibold tabular-nums">Orçamento de {o.ano}</h2>
          <Pilula variante={est.v}>{est.r}</Pilula>
        </div>
        <div className="flex flex-wrap gap-2 print:hidden">
          {editavel && <Button variant={mudancas.length ? 'default' : 'outline'} className="alvo" disabled={!mudancas.length || aGravar} onClick={gravar}><Save className="size-4" />{aGravar ? t.comum.aGravar : `Gravar${mudancas.length ? ` (${mudancas.length})` : ''}`}</Button>}
          {o.estado === 'RASCUNHO' && pode('tesouraria.orcamento.aprovar') && (
            <Button className="alvo" variant="outline" disabled={!activas.length || mudancas.length > 0} onClick={() => setAprovar(true)}><CircleCheck className="size-4" />Aprovar com o voto da igreja</Button>
          )}
        </div>
      </div>
      <div className="grid gap-3 sm:grid-cols-3">
        <Indicador rotulo="Receitas previstas" valor={<Dinheiro valor={mt(receitas)} />} tom="success" nota={o.estado !== 'RASCUNHO' ? <>realizado <Dinheiro valor={mt(totalReal('RECEITA'))} /></> : undefined} />
        <Indicador rotulo="Despesas previstas" valor={<Dinheiro valor={mt(despesas)} />} tom="destructive" nota={o.estado !== 'RASCUNHO' ? <>realizado <Dinheiro valor={mt(totalReal('DESPESA'))} /></> : undefined} />
        <Indicador rotulo={receitas - despesas >= 0 ? 'Saldo previsto' : 'Défice previsto'} valor={<Dinheiro valor={mt(Math.abs(receitas - despesas))} />} tom={receitas - despesas >= 0 ? 'primary' : 'warning'} />
      </div>
      {o.estado === 'RASCUNHO' && (
        <p className="rounded-lg border border-dashed px-4 py-3 text-sm text-muted-foreground print:hidden">
          {editavel ? 'Escreva o previsto em cada categoria e grave. Categorias a zero ficam fora do orçamento. ' : ''}
          Depois de votado na reunião da igreja, aprove-o aqui com o voto: a partir daí não se muda e mostra o realizado.
        </p>
      )}
      <div className="grid items-start gap-6 xl:grid-cols-2">
        {tabela('RECEITA')}
        {tabela('DESPESA')}
      </div>
      {aprovar && <DialogoAprovar o={o} aoFechar={() => setAprovar(false)} />}
    </div>
  )
}

function DialogoAprovar({ o, aoFechar }: { o: Orcamento; aoFechar: () => void }) {
  const { aprovar } = useOrcamentoMut()
  const [voto, setVoto] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const submeter = () => {
    setErro(null)
    if (!voto) return setErro('Escolha o voto que aprovou o orçamento.')
    aprovar.mutate({ id: o.id, votoId: Number(voto) }, {
      onSuccess: () => { toast.success(`Orçamento de ${o.ano} aprovado.`); aoFechar() }, onError: (e) => setErro(mensagemDe(e)),
    })
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Aprovar o orçamento de {o.ano}</DialogTitle>
          <DialogDescription>Indique o voto da igreja que aprovou o orçamento. Depois de aprovado, o previsto não se muda.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-2">
          <ErroFormulario mensagem={erro} />
          <label htmlFor="orc-voto" className="text-sm font-medium">Voto</label>
          <CampoVoto id="orc-voto" valor={voto} aoMudar={setVoto} reunioes={['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA', 'JUNTA_DIRECTIVA']} preferir="FINANCEIRO" />
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={aprovar.isPending} onClick={submeter}>{aprovar.isPending ? t.comum.aGravar : 'Aprovar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
