/**
 * Orçamento anual (F-TES-11): o tesoureiro prepara o previsto por categoria (receitas e despesas), a igreja aprova
 * em reunião (voto) e, durante o ano, vê-se o realizado ao lado do previsto (vista vw_execucao_orcamento: só
 * movimentos confirmados do ano). Aprovar exige a permissão tesouraria.orcamento.aprovar — a base de dados decide.
 */
import { useEffect, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { CircleCheck, ClipboardList, Pencil, Printer, Plus, Save, Tags, Trash2, X } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Dinheiro, Indicador, Pilula, Segmentos, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { Seleccao } from '@/components/comum/Seleccao'
import { Input } from '@/components/ui/input'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { centimos, deCentimos } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { imprimirComo } from '@/lib/documentos'
import { Exportar } from '@/components/comum/Exportar'
import { CampoVoto } from '@/features/livro/CampoVoto'
import { useCategorias, useCategoriasMut, useExecucaoOrcamento, useLinhasOrcamento, useOrcamentoMut, useOrcamentos, type Categoria, type Orcamento } from './api'

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
      <TituloPagina icone={ClipboardList} titulo="Orçamento anual" descricao="Previsto e realizado no ano"
        accoes={(
          <>
            {sel && <Exportar caminho="/v1/tesouraria/execucao-orcamento" query={{ igrejaId: igreja.id }} nome="execucao-do-orcamento" />}
            {sel && <Button variant="outline" className="alvo print:hidden" onClick={() => imprimirComo(`Orçamento ${sel.ano} - ${igreja.nome}`)}><Printer className="size-4" />Imprimir / guardar PDF</Button>}
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
              <Segmentos rotulo="Ano" valor={String(sel.id)} aoMudar={(v) => setParams({ ano: String(daIgreja.find((o) => String(o.id) === v)?.ano) })} className="mb-4 print:hidden"
                opcoes={daIgreja.map((o) => ({ valor: String(o.id), rotulo: String(o.ano) }))} />
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
  const [extra, setExtra] = useState<Set<number>>(new Set())
  const [categoriasAberto, setCategoriasAberto] = useState(false)
  const editavel = o.estado === 'RASCUNHO' && pode('tesouraria.orcamento_linha.criar')
  const activas = useMemo(() => (linhas.data ?? []).filter((l) => !l.endDate), [linhas.data])
  const porCat = useMemo(() => new Map(activas.map((l) => [l.categoriaId, l])), [activas])
  const realizado = useMemo(() => new Map((execucao.data ?? []).filter((e) => e.id === o.id).map((e) => [e.codigo, e])), [execucao.data, o.id])
  useEffect(() => { setValores(Object.fromEntries(activas.map((l) => [l.categoriaId, l.valorPrevisto]))) }, [activas])

  if (categorias.isPending || linhas.isPending) return <Barra className="h-64 w-full" />
  if (linhas.isError) return <EstadoErro erro={linhas.error} aoTentar={() => linhas.refetch()} />
  const cats = (categorias.data ?? []).filter((c) => !c.endDate)
  const visiveis = (tipo: 'RECEITA' | 'DESPESA') => cats.filter((c) => c.tipo === tipo && (porCat.has(c.id) || (editavel && extra.has(c.id)))).sort((a, b) => a.codigo.localeCompare(b.codigo, 'pt', { numeric: true }))
  const livres = (tipo: 'RECEITA' | 'DESPESA') => cats.filter((c) => c.tipo === tipo && !porCat.has(c.id) && !extra.has(c.id))
  const juntar = (id: string) => id && setExtra((x) => new Set(x).add(Number(id)))
  const retirar = (c: Categoria) => { setValores((x) => ({ ...x, [c.id]: '' })); setExtra((x) => { const n = new Set(x); n.delete(c.id); return n }) }
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
      setExtra(new Set())
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
                <td className="sm:pl-6">{c.nome}</td>
                <td className={cn('num', o.estado === 'RASCUNHO' && 'sm:pr-6')}>
                  {editavel
                    ? (
                      <span className="flex items-center justify-end gap-1">
                        <CampoDinheiro aria-label={`Previsto para ${c.nome}`} value={valores[c.id] ?? ''} onChange={(v) => setValores((x) => ({ ...x, [c.id]: v }))} className="alvo w-36 text-right" />
                        <Button type="button" variant="ghost" size="icon" className="size-8 text-muted-foreground" aria-label={`Retirar ${c.nome}`} onClick={() => retirar(c)}><X className="size-4" /></Button>
                      </span>
                    )
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
          {editavel && (
            <tr className="hover:bg-transparent!">
              <td colSpan={2} className="sm:px-6">
                {livres(tipo).length ? (
                  <Seleccao aria-label={`Acrescentar categoria de ${tipo === 'RECEITA' ? 'receita' : 'despesa'}`} value="" onChange={(e) => juntar(e.target.value)} className="sm:w-80">
                    <option value="">+ Acrescentar {tipo === 'RECEITA' ? 'receita' : 'despesa'}…</option>
                    {livres(tipo).map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
                  </Seleccao>
                ) : <span className="text-sm text-muted-foreground">Todas as categorias já estão no orçamento.</span>}
              </td>
            </tr>
          )}
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
          {pode('tesouraria.categoria.criar') && <Button variant="outline" className="alvo" onClick={() => setCategoriasAberto(true)}><Tags className="size-4" />Categorias</Button>}
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
          Depois de votado pela igreja, aprove-o com o voto: a partir daí mostra o realizado.
        </p>
      )}
      <div className="grid items-start gap-6 xl:grid-cols-2">
        {tabela('RECEITA')}
        {tabela('DESPESA')}
      </div>
      {aprovar && <DialogoAprovar o={o} aoFechar={() => setAprovar(false)} />}
      {categoriasAberto && <DialogoCategorias aoFechar={() => setCategoriasAberto(false)} />}
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
          <DialogDescription>O voto da igreja que aprovou o orçamento.</DialogDescription>
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

/** As categorias de receita e de despesa (plano de contas): registar, mudar o nome e retirar. */
function DialogoCategorias({ aoFechar }: { aoFechar: () => void }) {
  const categorias = useCategorias()
  const { criar, renomear, terminar } = useCategoriasMut()
  const [tipo, setTipo] = useState<'RECEITA' | 'DESPESA'>('DESPESA')
  const [nome, setNome] = useState('')
  const [aEditar, setAEditar] = useState<{ id: number; nome: string } | null>(null)
  const todas = (categorias.data ?? []).filter((c) => !c.endDate)
  const lista = todas.filter((c) => c.tipo === tipo).sort((a, b) => a.nome.localeCompare(b.nome, 'pt'))
  // código seguinte: R10, R11… ou D10, D11… (o código é interno; o que se vê é o nome)
  const proximoCodigo = () => {
    const p = tipo === 'RECEITA' ? 'R' : 'D'
    const usados = (categorias.data ?? []).map((c) => c.codigo).filter((c) => c.startsWith(p)).map((c) => Number(c.slice(1)) || 0)
    return `${p}${Math.max(9, ...usados) + 1}`
  }
  const registar = () => {
    if (!nome.trim()) return
    criar.mutate({ codigo: proximoCodigo(), nome: nome.trim(), tipo }, {
      onSuccess: () => { setNome(''); toast.success('Categoria registada.') }, onError: (e) => toast.error(mensagemDe(e)),
    })
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Categorias</DialogTitle>
          <DialogDescription className="sr-only">Receitas e despesas</DialogDescription>
        </DialogHeader>
        <Segmentos rotulo="Tipo" valor={tipo} aoMudar={setTipo} className="justify-self-start"
          opcoes={[{ valor: 'RECEITA', rotulo: 'Receitas', contagem: todas.filter((c) => c.tipo === 'RECEITA').length }, { valor: 'DESPESA', rotulo: 'Despesas', contagem: todas.filter((c) => c.tipo === 'DESPESA').length }] as const} />
        <div className="overflow-hidden rounded-xl border">
          <ul className="max-h-[50dvh] divide-y overflow-y-auto">
            {categorias.isPending ? <li className="p-4"><Barra className="h-6 w-full" /></li> : lista.map((c) => (
              <li key={c.id} className="group flex min-h-11 items-center gap-2 px-3 py-1.5 transition-colors hover:bg-muted/40">
                {aEditar?.id === c.id ? (
                  <form className="flex flex-1 gap-2" onSubmit={(e) => { e.preventDefault(); if (aEditar.nome.trim()) renomear.mutate({ id: c.id, nome: aEditar.nome.trim() }, { onSuccess: () => setAEditar(null), onError: (er) => toast.error(mensagemDe(er)) }) }}>
                    <Input autoFocus value={aEditar.nome} onChange={(e) => setAEditar({ id: c.id, nome: e.target.value })} maxLength={100} className="alvo h-8" />
                    <Button type="submit" size="sm" disabled={renomear.isPending}>Guardar</Button>
                    <Button type="button" size="sm" variant="ghost" onClick={() => setAEditar(null)}>{t.comum.cancelar}</Button>
                  </form>
                ) : (
                  <>
                    <span className="min-w-0 flex-1 truncate text-sm">{c.nome}</span>
                    {c.eRemessa ? <Pilula variante="secondary">Sistema</Pilula> : (
                      <span className="flex gap-0.5 opacity-0 transition-opacity group-hover:opacity-100 focus-within:opacity-100">
                        <Button type="button" variant="ghost" size="icon" className="size-8 text-muted-foreground" aria-label={`Mudar o nome de ${c.nome}`} onClick={() => setAEditar({ id: c.id, nome: c.nome })}><Pencil className="size-4" /></Button>
                        <Button type="button" variant="ghost" size="icon" className="size-8 text-muted-foreground hover:text-destructive-text" aria-label={`Retirar ${c.nome}`} disabled={terminar.isPending}
                          onClick={() => terminar.mutate(c.id, { onSuccess: () => toast.success('Categoria retirada.'), onError: (e) => toast.error(mensagemDe(e)) })}><Trash2 className="size-4" /></Button>
                      </span>
                    )}
                  </>
                )}
              </li>
            ))}
          </ul>
          <form className="flex items-center gap-2 border-t bg-muted/30 px-3 py-2" onSubmit={(e) => { e.preventDefault(); registar() }}>
            <Plus className="size-4 flex-none text-muted-foreground" aria-hidden />
            <Input value={nome} onChange={(e) => setNome(e.target.value)} placeholder={tipo === 'RECEITA' ? 'Nova receita…' : 'Nova despesa…'} maxLength={100}
              className="alvo h-9 border-0 bg-transparent shadow-none focus-visible:ring-0" aria-label="Nome da nova categoria" />
            <Button type="submit" size="sm" className="alvo" disabled={!nome.trim() || criar.isPending}>Registar</Button>
          </form>
        </div>
        <DialogFooter><Button type="button" variant="outline" className="alvo" onClick={aoFechar}>Fechar</Button></DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
