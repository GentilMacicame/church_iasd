/**
 * Orçamento anual (F-TES-11): o tesoureiro prepara o previsto por categoria (receitas e despesas), a igreja aprova
 * em reunião (voto) e, durante o ano, vê-se o realizado ao lado do previsto (vista vw_execucao_orcamento: só
 * movimentos confirmados do ano). Aprovar exige a permissão tesouraria.orcamento.aprovar — a base de dados decide.
 */
import { useEffect, useMemo, useRef, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Check, ChevronRight, CircleCheck, ClipboardList, Copy, Loader2, Pencil, Printer, Plus, Tags, Trash2 } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Dinheiro, Indicador, Pilula, Segmentos, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
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
  const { criar, linha } = useOrcamentoMut()
  const [params, setParams] = useSearchParams()
  const daIgreja = (orcs.data ?? []).filter((o) => !o.endDate && !o.departamentoIgrejaId).sort((a, b) => b.ano - a.ano)
  const anoActual = new Date().getFullYear()
  const primeiro = Math.min(anoActual, ...daIgreja.map((o) => o.ano))
  const ultimo = anoActual + 1
  const anoPedido = Number(params.get('ano')) || null
  const ano = anoPedido ?? (daIgreja.some((o) => o.ano === anoActual) ? anoActual : daIgreja[0]?.ano ?? anoActual)
  const sel = daIgreja.find((o) => o.ano === ano)
  const anterior = daIgreja.find((o) => o.ano === ano - 1)
  const linhasAnterior = useLinhasOrcamento(!sel && anterior ? anterior.id : null)
  const [aPreparar, setAPreparar] = useState(false)
  const irPara = (a: number) => setParams({ ano: String(a) })

  /** Cria o orçamento do ano; com copiar, começa com os valores previstos do ano anterior. */
  const preparar = async (copiar: boolean) => {
    setAPreparar(true)
    try {
      const novo = await criar.mutateAsync({ igrejaId: igreja.id, ano })
      if (copiar) for (const l of (linhasAnterior.data ?? []).filter((x) => !x.endDate)) await linha.mutateAsync({ orcamentoId: novo.id, categoriaId: l.categoriaId, valorPrevisto: l.valorPrevisto })
      toast.success(copiar ? `Orçamento de ${ano} criado com os valores de ${ano - 1}.` : `Orçamento de ${ano} criado: preencha o previsto de cada categoria.`)
    } catch (e) { toast.error(mensagemDe(e)) } finally { setAPreparar(false) }
  }

  // os anos com orçamento, mais o ano corrente e o seguinte (para preparar)
  const anos = [...new Set([...daIgreja.map((o) => o.ano), anoActual, ultimo])].filter((a) => a >= primeiro).sort((a, b) => a - b)
  const navegador = (
    <div role="tablist" aria-label="Ano do orçamento" className="mb-6 flex flex-wrap gap-2 print:hidden">
      {anos.map((a) => {
        const o = daIgreja.find((x) => x.ano === a)
        const activo = a === ano
        const est = o ? ESTADO[o.estado] ?? ESTADO.RASCUNHO : null
        return (
          <button key={a} type="button" role="tab" aria-selected={activo} onClick={() => irPara(a)}
            className={cn('alvo flex min-w-32 flex-col items-start gap-0.5 rounded-[2px] border px-4 py-2 text-left transition-colors',
              activo ? 'border-primary bg-primary/5 ring-1 ring-primary' : o ? 'bg-card hover:border-foreground/30' : 'border-dashed bg-transparent text-muted-foreground hover:border-primary hover:text-primary')}>
            <span className={cn('text-lg leading-6 font-semibold tabular-nums', activo && 'text-primary')}>{o ? a : <span className="inline-flex items-center gap-1"><Plus className="size-4" />{a}</span>}</span>
            <span className={cn('text-xs', !o && 'text-muted-foreground', est?.v === 'success' && 'text-success-text', est?.v === 'warning' && 'text-warning-text')}>{est ? est.r : 'Por preparar'}</span>
          </button>
        )
      })}
    </div>
  )

  return (
    <>
      <TituloPagina icone={ClipboardList} titulo="Orçamento anual" descricao="Previsto e realizado no ano"
        accoes={sel && (
          <>
            <Exportar caminho="/v1/tesouraria/execucao-orcamento" query={{ igrejaId: igreja.id }} nome="execucao-do-orcamento" />
            <Button variant="outline" className="alvo print:hidden" onClick={() => imprimirComo(`Orçamento ${sel.ano} - ${igreja.nome}`)}><Printer className="size-4" />Imprimir / guardar PDF</Button>
          </>
        )} />
      {orcs.isPending ? <Barra className="h-64 w-full" />
        : orcs.isError ? <EstadoErro erro={orcs.error} aoTentar={() => orcs.refetch()} />
        : sel ? <>{navegador}<Detalhe key={sel.id} o={sel} /></>
        : (
          <div>
            {navegador}
            <Cartao>
              <EstadoVazio icone={ClipboardList} titulo={`Ainda não há orçamento de ${ano}`}
                accao={pode('tesouraria.orcamento.criar') && ano >= anoActual && (
                  <div className="flex flex-wrap justify-center gap-2">
                    {anterior && (linhasAnterior.data ?? []).some((l) => !l.endDate) && (
                      <Button variant="outline" className="alvo" disabled={aPreparar} onClick={() => preparar(true)}><Copy className="size-4" />Começar com os valores de {ano - 1}</Button>
                    )}
                    <Button className="alvo" disabled={aPreparar} onClick={() => preparar(false)}><Plus className="size-4" />{aPreparar ? t.comum.aGravar : `Preparar o orçamento de ${ano}`}</Button>
                  </div>
                )}>
                {ano >= anoActual ? 'Prepare o previsto de receitas e despesas; depois a igreja aprova-o em reunião.' : 'Este ano não teve orçamento registado.'}
              </EstadoVazio>
            </Cartao>
          </div>
        )}
    </>
  )
}

/** Os três passos do orçamento, com o actual em destaque. */
function Passos({ estado }: { estado: Orcamento['estado'] }) {
  const actual = estado === 'RASCUNHO' ? 0 : estado === 'APROVADO' ? 2 : 3
  const passos = ['Preparar o previsto', 'Votar na igreja e aprovar', 'Acompanhar o realizado']
  return (
    <ol className="flex flex-wrap items-center gap-x-2 gap-y-1 text-sm print:hidden" aria-label="Passos do orçamento">
      {passos.map((p, i) => (
        <li key={p} className="flex items-center gap-2">
          {i > 0 && <ChevronRight className="size-4 text-muted-foreground/60" aria-hidden />}
          <span className={cn('flex size-6 items-center justify-center rounded-full text-xs font-semibold',
            i < actual ? 'bg-success/15 text-success-text' : i === actual ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground')}>
            {i < actual ? <Check className="size-3.5" /> : i + 1}
          </span>
          <span className={cn(i === actual ? 'font-medium text-foreground' : 'text-muted-foreground')}>{p}</span>
        </li>
      ))}
    </ol>
  )
}

function Detalhe({ o }: { o: Orcamento }) {
  const { pode } = useSessao()
  const categorias = useCategorias()
  const linhas = useLinhasOrcamento(o.id)
  const execucao = useExecucaoOrcamento()
  const { linha, mudarLinha, tirarLinha } = useOrcamentoMut()
  const catMut = useCategoriasMut()
  const [valores, setValores] = useState<Record<number, string>>({})
  const [aprovar, setAprovar] = useState(false)
  const [gravadas, setGravadas] = useState<Set<number>>(new Set())
  const [categoriasAberto, setCategoriasAberto] = useState(false)
  const [estadoGravar, setEstadoGravar] = useState<'parado' | 'a-gravar' | 'gravado'>('parado')
  const [nova, setNova] = useState<{ tipo: 'RECEITA' | 'DESPESA'; nome: string } | null>(null)
  const pendentes = useRef(new Set<number>())
  const editavel = o.estado === 'RASCUNHO' && pode('tesouraria.orcamento_linha.criar')
  const activas = useMemo(() => (linhas.data ?? []).filter((l) => !l.endDate), [linhas.data])
  const porCat = useMemo(() => new Map(activas.map((l) => [l.categoriaId, l])), [activas])
  const realizado = useMemo(() => new Map((execucao.data ?? []).filter((e) => e.id === o.id).map((e) => [e.codigo, e])), [execucao.data, o.id])
  // o que vem da base substitui os valores, menos os que estão a ser escritos
  useEffect(() => {
    setValores((x) => {
      const n: Record<number, string> = Object.fromEntries(activas.map((l) => [l.categoriaId, l.valorPrevisto]))
      for (const k of pendentes.current) n[k] = x[k] ?? ''
      return n
    })
  }, [activas])

  if (categorias.isPending || linhas.isPending) return <Barra className="h-64 w-full" />
  if (linhas.isError) return <EstadoErro erro={linhas.error} aoTentar={() => linhas.refetch()} />
  const cats = (categorias.data ?? []).filter((c) => !c.endDate)
  // a preparar: todas as categorias (vazio = fora do orçamento); depois de aprovado: só as que têm previsto
  const visiveis = (tipo: 'RECEITA' | 'DESPESA') => cats.filter((c) => c.tipo === tipo && (editavel || porCat.has(c.id))).sort((a, b) => a.nome.localeCompare(b.nome, 'pt'))
  const total = (tipo: 'RECEITA' | 'DESPESA') => visiveis(tipo).reduce((s, c) => s + centimos((editavel ? valores[c.id] : porCat.get(c.id)?.valorPrevisto) || '0'), 0)
  const totalReal = (tipo: 'RECEITA' | 'DESPESA') => visiveis(tipo).reduce((s, c) => s + centimos(realizado.get(c.codigo)?.realizado ?? '0'), 0)

  /** Grava uma linha quando o valor mudou (ao sair do campo). */
  const gravarLinha = async (c: Categoria) => {
    const l = porCat.get(c.id)
    const v = valores[c.id] || ''
    if (centimos(l?.valorPrevisto || '0') === centimos(v || '0')) { pendentes.current.delete(c.id); return }
    setEstadoGravar('a-gravar')
    try {
      if (l && !centimos(v || '0')) await tirarLinha.mutateAsync(l.id)
      else if (l) await mudarLinha.mutateAsync({ id: l.id, valorPrevisto: v })
      else if (centimos(v || '0') > 0) await linha.mutateAsync({ orcamentoId: o.id, categoriaId: c.id, valorPrevisto: v })
      pendentes.current.delete(c.id)
      setGravadas((x) => new Set(x).add(c.id))
      setEstadoGravar('gravado')
    } catch (e) {
      setEstadoGravar('parado')
      toast.error(mensagemDe(e))
    }
  }
  /** Cria a categoria nova e põe-na logo no orçamento. */
  const criarCategoria = () => {
    if (!nova?.nome.trim()) return
    const p = nova.tipo === 'RECEITA' ? 'R' : 'D'
    const usados = (categorias.data ?? []).map((c) => c.codigo).filter((c) => c.startsWith(p)).map((c) => Number(c.slice(1)) || 0)
    catMut.criar.mutate({ codigo: `${p}${Math.max(9, ...usados) + 1}`, nome: nova.nome.trim(), tipo: nova.tipo }, {
      onSuccess: (c) => { setNova(null); const id = (c as { id?: number })?.id; if (id) setTimeout(() => document.getElementById(`orc-cat-${id}`)?.focus(), 300) },
      onError: (e) => toast.error(mensagemDe(e)),
    })
  }

  const receitas = total('RECEITA'), despesas = total('DESPESA')
  const tabela = (tipo: 'RECEITA' | 'DESPESA') => {
    const palavra = tipo === 'RECEITA' ? 'receita' : 'despesa'
    return (
      <Cartao titulo={tipo === 'RECEITA' ? 'Receitas' : 'Despesas'} semMargem descricao={editavel ? 'Escreva o valor previsto de cada categoria' : undefined}>
        <Tabela procurar={false}>
          <thead>
            <tr><th className="sm:pl-6">Categoria</th><th className="num">Previsto</th>{o.estado !== 'RASCUNHO' && <><th className="num">Realizado</th><th className="num sm:pr-6">%</th></>}</tr>
          </thead>
          <tbody>
            {visiveis(tipo).map((c) => {
              const r = realizado.get(c.codigo)
              const pct = r?.pctExecucao != null ? Number(r.pctExecucao) : null
              return (
                <tr key={c.id}>
                  <td className={cn('sm:pl-6', editavel && !centimos(valores[c.id] || '0') && 'text-muted-foreground')}>{c.nome}</td>
                  <td className={cn('num', o.estado === 'RASCUNHO' && 'sm:pr-6')}>
                    {editavel
                      ? (
                        <span className="flex items-center justify-end gap-1">
                          <CampoDinheiro id={`orc-cat-${c.id}`} aria-label={`Previsto para ${c.nome}`} value={valores[c.id] ?? ''}
                            onChange={(v) => { pendentes.current.add(c.id); setGravadas((x) => { const n = new Set(x); n.delete(c.id); return n }); setValores((x) => ({ ...x, [c.id]: v })) }}
                            onBlur={() => void gravarLinha(c)} className="alvo w-28 text-right sm:w-36" />
                          <span className="flex size-6 flex-none items-center justify-center" aria-hidden>{gravadas.has(c.id) && !pendentes.current.has(c.id) && <Check className="size-4 text-success-text" />}</span>
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
              <tr data-fixa className="hover:bg-transparent!">
                <td colSpan={2} className="sm:px-6">
                  {nova?.tipo === tipo ? (
                    <form className="flex flex-wrap items-center gap-2" onSubmit={(e) => { e.preventDefault(); criarCategoria() }}>
                      <Input autoFocus value={nova.nome} onChange={(e) => setNova({ tipo, nome: e.target.value })} maxLength={100} placeholder={`Nome da nova ${palavra}`} aria-label={`Nome da nova ${palavra}`} className="alvo min-w-0 flex-1 sm:max-w-80" />
                      <Button type="submit" className="alvo" disabled={!nova.nome.trim() || catMut.criar.isPending}>Criar</Button>
                      <Button type="button" variant="ghost" className="alvo" onClick={() => setNova(null)}>{t.comum.cancelar}</Button>
                    </form>
                  ) : (
                    pode('tesouraria.categoria.criar') && (
                      <Button type="button" variant="ghost" className="alvo -ml-2 text-primary" onClick={() => setNova({ tipo, nome: '' })}><Plus className="size-4" />Nova {palavra}</Button>
                    )
                  )}
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
  }

  const est = ESTADO[o.estado] ?? ESTADO.RASCUNHO
  return (
    <div className="grid gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex flex-wrap items-center gap-3">
          <h2 className="text-lg font-semibold tabular-nums">Orçamento de {o.ano}</h2>
          <Pilula variante={est.v}>{est.r}</Pilula>
          {editavel && (
            <span className="inline-flex items-center gap-1 text-xs text-muted-foreground print:hidden" role="status">
              {estadoGravar === 'parado' ? <><Check className="size-3.5" />Grava sozinho ao sair de cada valor</> : estadoGravar === 'a-gravar' ? <><Loader2 className="size-3.5 animate-spin" />A gravar…</> : <><Check className="size-3.5 text-success-text" />Tudo gravado</>}
            </span>
          )}
        </div>
        <div className="flex flex-wrap gap-2 print:hidden">
          {pode('tesouraria.categoria.criar') && <Button variant="outline" className="alvo" onClick={() => setCategoriasAberto(true)}><Tags className="size-4" />Gerir categorias</Button>}
          {o.estado === 'RASCUNHO' && pode('tesouraria.orcamento.aprovar') && (
            <Button className="alvo" disabled={!activas.length || estadoGravar === 'a-gravar'} onClick={() => setAprovar(true)}><CircleCheck className="size-4" />Aprovar com o voto da igreja</Button>
          )}
        </div>
      </div>
      <Passos estado={o.estado} />
      <div className="grid gap-3 sm:grid-cols-3">
        <Indicador rotulo="Receitas previstas" valor={<Dinheiro valor={mt(receitas)} />} tom="success" nota={o.estado !== 'RASCUNHO' ? <>realizado <Dinheiro valor={mt(totalReal('RECEITA'))} /></> : undefined} />
        <Indicador rotulo="Despesas previstas" valor={<Dinheiro valor={mt(despesas)} />} tom="destructive" nota={o.estado !== 'RASCUNHO' ? <>realizado <Dinheiro valor={mt(totalReal('DESPESA'))} /></> : undefined} />
        <Indicador rotulo={receitas - despesas >= 0 ? 'Saldo previsto' : 'Défice previsto'} valor={<Dinheiro valor={mt(Math.abs(receitas - despesas))} />} tom={receitas - despesas >= 0 ? 'primary' : 'warning'} />
      </div>
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
          <div className="campo-flutuante grid gap-1.5">
            <label htmlFor="orc-voto" className="text-sm font-medium">Voto</label>
            <CampoVoto id="orc-voto" valor={voto} aoMudar={setVoto} reunioes={['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA', 'JUNTA_DIRECTIVA']} preferir="FINANCEIRO" />
          </div>
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
          <DialogTitle>Gerir categorias</DialogTitle>
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
                      <span className="flex gap-0.5">
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
