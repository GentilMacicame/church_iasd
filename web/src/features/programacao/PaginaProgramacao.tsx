/**
 * Programação de um dia (V44) · a folha como a igreja a afixa: o título (ex.: Sábado 14 de Novembro de 2026) e, para
 * cada parte (Escola Sabatina, Transição, Culto Divino, JA), o apresentador ao lado e os itens com as horas, a
 * actividade e o responsável; as linhas em destaque sombreadas. No ecrã, tocar numa linha edita-a; "Preencher pela
 * escala" volta a pôr os nomes da escala desse dia; "Imprimir" dá a folha A4.
 */
import { useMemo, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { ArrowLeft, ClipboardList, Pencil, Plus, Printer, RefreshCw, Trash2 } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { CampoEscolha } from '@/components/comum/CampoEscolha'
import { Seleccao } from '@/components/comum/Seleccao'
import { ErroApi, mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { useFamiliasResumo } from '@/features/secretaria/api'
import { useDepartamentosIgreja } from '@/features/actividades/api'
import { useColunas, type Coluna } from '@/features/escalas/api'
import { ESCALA, tituloDoDia, useProgramacao, useProgramacaoMut, type Item, type Parte } from './api'
import { qtd } from '@/lib/formatos'
import { CampoHora } from '@/components/comum/CampoHora'

const HORA = /^([01]\d|2[0-3]):[0-5]\d$/
type Tipo = 'membro' | 'familia' | 'departamento' | 'texto' | 'nenhum'

/** Os nomes para mostrar (membros, famílias, departamentos). */
function useNomes() {
  const basicos = useMembrosBasicos()
  const familias = useFamiliasResumo()
  const deps = useDepartamentosIgreja()
  const colES = useColunas('ESCOLA_SABATINA')
  const colJA = useColunas('JA')
  return useMemo(() => {
    const m = new Map((basicos.data ?? []).map((x) => [x.id, `${x.nome} ${x.apelido}`]))
    const f = new Map((familias.data ?? []).map((x) => [x.id, x.nome]))
    const d = new Map((deps.data?.daIgreja ?? []).map((x) => [x.id, x.nome]))
    return {
      membro: (id?: number | null) => (id ? m.get(id) : undefined),
      familia: (id?: number | null) => (id ? f.get(id) : undefined),
      departamento: (id?: number | null) => (id ? d.get(id) : undefined),
      familias: familias.data ?? [],
      departamentos: deps.data?.daIgreja ?? [],
      colunasES: colES.data ?? [] as Coluna[],
      colunasJA: colJA.data ?? [] as Coluna[],
      coluna: (id?: number | null) => (id ? [...(colES.data ?? []), ...(colJA.data ?? [])].find((c) => c.id === id) : undefined),
    }
  }, [basicos.data, familias.data, deps.data, colES.data, colJA.data])
}
type Nomes = ReturnType<typeof useNomes>

const responsavel = (i: Item, n: Nomes) =>
  n.membro(i.responsavelMembroId) ?? n.familia(i.responsavelFamiliaId) ?? n.departamento(i.responsavelDepartamentoIgrejaId) ?? i.responsavelTexto ?? ''
const apresentador = (p: Parte, n: Nomes) => n.membro(p.apresentadorMembroId) ?? n.familia(p.apresentadorFamiliaId) ?? p.apresentadorTexto ?? ''
/** De onde vem o nome: uma função do culto ou uma coluna da escala da ES/JA. */
const ligacao = (escala: string | null | undefined, coluna: number | null | undefined, n: Nomes) => {
  const c = n.coluna(coluna)
  return c ? `${c.tipo === 'JA' ? 'JA' : 'Escola Sabatina'}: ${c.nome}` : escala ? ESCALA[escala] : undefined
}
const valorLigacao = (escala?: string | null, coluna?: number | null) => (coluna ? `c:${coluna}` : escala ? `f:${escala}` : '')
const daLigacao = (v: string) => ({ escala: v.startsWith('f:') ? v.slice(2) : null, escalaColunaId: v.startsWith('c:') ? Number(v.slice(2)) : null })

/** Escolha da ligação à escala: as funções do culto e as colunas da ES e da JA que a igreja definiu. */
function CampoLigacao({ id, valor, aoMudar, nomes }: { id: string; valor: string; aoMudar: (v: string) => void; nomes: Nomes }) {
  return (
    <Seleccao id={id} value={valor} onChange={(e) => aoMudar(e.target.value)}>
      <option value="">Não (escreve-se aqui)</option>
      <optgroup label="Escala do Culto Divino">{Object.entries(ESCALA).map(([k, r]) => <option key={k} value={`f:${k}`}>{r}</option>)}</optgroup>
      {nomes.colunasES.length > 0 && <optgroup label="Escala da Escola Sabatina">{nomes.colunasES.map((c) => <option key={c.id} value={`c:${c.id}`}>{c.nome}</option>)}</optgroup>}
      {nomes.colunasJA.length > 0 && <optgroup label="Escala da JA">{nomes.colunasJA.map((c) => <option key={c.id} value={`c:${c.id}`}>{c.nome}</option>)}</optgroup>}
    </Seleccao>
  )
}
const horas = (i: Item) => [i.horaInicio, i.horaFim].filter(Boolean).join(' – ')

export default function PaginaProgramacao() {
  const id = Number(useParams().id)
  const igreja = useIgreja()
  const { pode } = useSessao()
  const q = useProgramacao(id)
  const mut = useProgramacaoMut(id)
  const n = useNomes()
  const [item, setItem] = useState<{ item: Item | null; parte: Parte } | null>(null)
  const [parte, setParte] = useState<Parte | 'nova' | null>(null)
  const [cabecalho, setCabecalho] = useState(false)
  const podeAlterar = pode('actividades.programa_item.alterar')

  if (q.isPending) return <div className="grid gap-4" aria-busy="true" aria-label="A carregar"><Barra className="h-8 w-72" /><Barra className="h-[32rem] w-full" /></div>
  if (q.isError) {
    return q.error instanceof ErroApi && q.error.naoEncontrado
      ? <div className="rounded-xl border bg-card shadow-card"><EstadoVazio icone={ClipboardList} titulo="Programação não encontrada">Não existe ou não é desta igreja.</EstadoVazio></div>
      : <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
  }
  const { programa, partes, itens } = q.data
  const titulo = programa.titulo || tituloDoDia(programa.data)
  const preencher = () => mut.preencher.mutate(undefined, {
    onSuccess: (r) => toast.success(r.mudaram ? `${qtd(r.mudaram, 'nome(s) actualizado(s)')} pela escala.` : 'Já estava tudo como na escala.'),
    onError: (e) => toast.error(mensagemDe(e)),
  })

  return (
    <>
      <style>{'@media print { @page { size: A4 portrait; margin: 10mm; } }'}</style>
      <div className="print:hidden">
        <Link to="/programacao" className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" /> Programação do dia
        </Link>
        <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div className="flex min-w-0 items-start gap-3">
            <span className="flex size-10 flex-none items-center justify-center rounded-lg bg-primary/10 text-primary" aria-hidden><ClipboardList className="size-5" /></span>
            <div className="min-w-0">
              <h1 className="text-2xl font-semibold tracking-tight">{titulo}</h1>
              <p className="mt-1 text-sm text-muted-foreground">{igreja.nome} · {qtd(partes.length, 'parte(s)')}, {qtd(itens.length, 'item(ns)')}{podeAlterar ? ' · toque numa linha para a alterar' : ''}</p>
            </div>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {podeAlterar && <Button variant="outline" className="alvo" disabled={mut.preencher.isPending} onClick={preencher}><RefreshCw className="size-4" />Preencher pela escala</Button>}
            {pode('actividades.programa_dia.alterar') && <Button variant="outline" className="alvo" onClick={() => setCabecalho(true)}><Pencil className="size-4" />Título e nota</Button>}
            <Button className="alvo" onClick={() => window.print()}><Printer className="size-4" />Imprimir</Button>
          </div>
        </div>
      </div>

      {/* a folha: no ecrã e na impressão */}
      <article className="mx-auto w-full max-w-[210mm] bg-white text-[10.5pt] text-neutral-900 shadow-card ring-1 ring-black/5 print:max-w-none print:shadow-none print:ring-0">
        <header className="bg-[#9ccc8f] px-4 py-3 text-center print:[-webkit-print-color-adjust:exact] print:[print-color-adjust:exact]">
          <h2 className="text-lg font-semibold sm:text-xl">{titulo}</h2>
        </header>
        <div className="grid gap-5 p-3 sm:p-4">
          {partes.map((pt) => {
            const daParte = itens.filter((i) => i.programaParteId === pt.id)
            const quem = apresentador(pt, n)
            return (
              <section key={pt.id} className="break-inside-avoid">
                <h3 className="mb-1 text-center text-[10pt] font-semibold tracking-wide uppercase">
                  {pode('actividades.programa_parte.alterar')
                    ? <button type="button" onClick={() => setParte(pt)} className="rounded px-1 hover:bg-neutral-100 print:hover:bg-transparent">{pt.titulo}</button>
                    : pt.titulo}
                </h3>
                <div className="overflow-x-auto">
                  <table className="w-full min-w-[34rem] border-collapse text-[10pt] print:min-w-0">
                    <thead>
                      <tr className="bg-[#cfe3f3] text-left print:[-webkit-print-color-adjust:exact] print:[print-color-adjust:exact]">
                        <th className="w-[19%] border border-neutral-500 px-2 py-1 font-semibold">{pt.rotulo}</th>
                        <th className="w-[17%] border border-neutral-500 px-2 py-1 font-semibold">Horas</th>
                        <th className="border border-neutral-500 px-2 py-1 font-semibold">Actividade</th>
                        <th className="w-[26%] border border-neutral-500 px-2 py-1 font-semibold">Responsável</th>
                      </tr>
                    </thead>
                    <tbody>
                      {daParte.length === 0 && (
                        <tr><td className="border border-neutral-500 px-2 py-1 text-center font-medium">{quem}</td><td colSpan={3} className="border border-neutral-500 px-2 py-2 text-neutral-500 italic">Sem itens.</td></tr>
                      )}
                      {daParte.map((i, idx) => {
                        const nome = responsavel(i, n)
                        return (
                          <tr key={i.id} onClick={podeAlterar ? () => setItem({ item: i, parte: pt }) : undefined}
                            className={cn(i.destaque && 'bg-[#c9dcc4] font-semibold print:[-webkit-print-color-adjust:exact] print:[print-color-adjust:exact]',
                              podeAlterar && 'cursor-pointer hover:bg-neutral-100 print:hover:bg-transparent')}>
                            {idx === 0 && (
                              <td rowSpan={daParte.length} className="border border-neutral-500 bg-white px-2 py-1 text-center align-middle font-medium">
                                {quem || <span className="text-neutral-400 print:hidden">{ligacao(pt.escala, pt.escalaColunaId, n) ? `(${ligacao(pt.escala, pt.escalaColunaId, n)})` : '—'}</span>}
                              </td>
                            )}
                            <td className="border border-neutral-500 px-2 py-0.5 whitespace-nowrap tabular-nums">{horas(i)}</td>
                            <td className="border border-neutral-500 px-2 py-0.5">{i.actividade}</td>
                            <td className="border border-neutral-500 px-2 py-0.5">
                              {nome || (ligacao(i.escala, i.escalaColunaId, n) ? <span className="font-normal text-neutral-400 print:invisible">({ligacao(i.escala, i.escalaColunaId, n)})</span> : '')}
                            </td>
                          </tr>
                        )
                      })}
                    </tbody>
                  </table>
                </div>
                {pode('actividades.programa_item.criar') && (
                  <Button type="button" variant="ghost" size="sm" className="mt-1 print:hidden" onClick={() => setItem({ item: null, parte: pt })}>
                    <Plus className="size-4" />Item em {pt.titulo}
                  </Button>
                )}
              </section>
            )
          })}
          {partes.length === 0 && <p className="py-8 text-center text-neutral-500">Ainda sem partes.</p>}
          {pode('actividades.programa_parte.criar') && (
            <Button type="button" variant="outline" className="justify-self-start print:hidden" onClick={() => setParte('nova')}><Plus className="size-4" />Parte (ex.: Programa da tarde)</Button>
          )}
          {programa.observacoes && <p className="text-[9pt] text-neutral-600 italic">© {programa.observacoes}</p>}
        </div>
      </article>

      {item && <DialogoItem item={item.item} parte={item.parte} ordem={Math.max(0, ...itens.filter((x) => x.programaParteId === item.parte.id).map((x) => x.ordem)) + 1}
        programaId={id} nomes={n} aoFechar={() => setItem(null)} />}
      {parte && <DialogoParte parte={parte === 'nova' ? null : parte} ordem={Math.max(0, ...partes.map((x) => x.ordem)) + 1} programaId={id} nomes={n} aoFechar={() => setParte(null)} />}
      {cabecalho && <DialogoCabecalho programaId={id} titulo={programa.titulo ?? ''} nota={programa.observacoes ?? ''} sugestao={tituloDoDia(programa.data)} aoFechar={() => setCabecalho(false)} />}
    </>
  )
}

/* ---------------------------------------------------------------- quem: membro, família, departamento ou texto */
function CampoQuem({ id, tipo, setTipo, valor, setValor, nomes, departamentos = true }: {
  id: string; tipo: Tipo; setTipo: (t: Tipo) => void; valor: string; setValor: (v: string) => void; nomes: Nomes; departamentos?: boolean
}) {
  const tipos: { v: Tipo; r: string }[] = [{ v: 'membro', r: 'Membro' }, { v: 'familia', r: 'Família' },
    ...(departamentos ? [{ v: 'departamento' as Tipo, r: 'Departamento' }] : []), { v: 'texto', r: 'Escrito' }, { v: 'nenhum', r: 'Ninguém' }]
  return (
    <div className="grid gap-2">
      <div role="radiogroup" aria-label="Tipo" className="flex flex-wrap gap-1 rounded-lg bg-muted p-1">
        {tipos.map((x) => (
          <button key={x.v} type="button" role="radio" aria-checked={tipo === x.v} onClick={() => { setTipo(x.v); setValor('') }}
            className={cn('alvo rounded-md px-3 py-1.5 text-xs font-medium text-muted-foreground', tipo === x.v && 'bg-card text-foreground shadow-sm')}>{x.r}</button>
        ))}
      </div>
      {tipo === 'membro' && <CampoMembro id={id} valor={valor ? Number(valor) : null} aoMudar={(m) => setValor(m ? String(m) : '')} nomeDe={(m) => nomes.membro(m)} />}
      {tipo === 'familia' && <CampoEscolha id={id} valor={valor} aoMudar={setValor} vazio="Escolher a família…" pesquisar="Pesquisar família…"
        opcoes={nomes.familias.map((f) => ({ valor: String(f.id), rotulo: f.nome }))} semOpcoes="Ainda não há famílias" />}
      {tipo === 'departamento' && <CampoEscolha id={id} valor={valor} aoMudar={setValor} vazio="Escolher o departamento…" pesquisar="Pesquisar…"
        opcoes={nomes.departamentos.map((d) => ({ valor: String(d.id), rotulo: d.nome }))} semOpcoes="Sem departamentos nesta igreja" />}
      {tipo === 'texto' && <Input id={id} value={valor} onChange={(e) => setValor(e.target.value)} maxLength={150} placeholder="ex.: Todos, Diáconos, Monitores, Pr. visitante" className="alvo" />}
    </div>
  )
}

function tipoInicial(m?: number | null, f?: number | null, d?: number | null, tx?: string | null): [Tipo, string] {
  if (m) return ['membro', String(m)]
  if (f) return ['familia', String(f)]
  if (d) return ['departamento', String(d)]
  if (tx) return ['texto', tx]
  return ['nenhum', '']
}

/* ---------------------------------------------------------------- item */
function DialogoItem({ item, parte, ordem, programaId, nomes, aoFechar }: {
  item: Item | null; parte: Parte; ordem: number; programaId: number; nomes: Nomes; aoFechar: () => void
}) {
  const mut = useProgramacaoMut(programaId)
  const { pode } = useSessao()
  const [ini, setIni] = useState(item?.horaInicio ?? '')
  const [fim, setFim] = useState(item?.horaFim ?? '')
  const [actividade, setActividade] = useState(item?.actividade ?? '')
  const [t0, v0] = tipoInicial(item?.responsavelMembroId, item?.responsavelFamiliaId, item?.responsavelDepartamentoIgrejaId, item?.responsavelTexto)
  const [tipo, setTipo] = useState<Tipo>(t0)
  const [valor, setValor] = useState(v0)
  const [escala, setEscala] = useState(valorLigacao(item?.escala, item?.escalaColunaId))
  const [destaque, setDestaque] = useState(item?.destaque ?? false)
  const [pos, setPos] = useState(String(item?.ordem ?? ordem))
  const [erro, setErro] = useState<string | null>(null)
  const gravar = async () => {
    setErro(null)
    if (!actividade.trim()) return setErro('Escreva a actividade (ex.: Hino inicial).')
    if ((ini && !HORA.test(ini)) || (fim && !HORA.test(fim))) return setErro('Escreva as horas como hh:mm (ex.: 10:30).')
    if (tipo !== 'nenhum' && !valor.trim()) return setErro('Escolha o responsável (ou "Ninguém").')
    try {
      await mut.gravarItem.mutateAsync({
        id: item?.id, programaParteId: parte.id, ordem: Number(pos) || ordem, horaInicio: ini || null, horaFim: fim || null,
        actividade: actividade.trim(), ...daLigacao(escala), destaque,
        responsavelMembroId: tipo === 'membro' ? Number(valor) : null, responsavelFamiliaId: tipo === 'familia' ? Number(valor) : null,
        responsavelDepartamentoIgrejaId: tipo === 'departamento' ? Number(valor) : null, responsavelTexto: tipo === 'texto' ? valor.trim() : null,
      } as never)
      toast.success(item ? 'Item actualizado.' : 'Item acrescentado.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  const tirar = () => item && mut.tirarItem.mutate(item.id, { onSuccess: () => { toast.success('Item retirado da programação.'); aoFechar() }, onError: (e) => setErro(mensagemDe(e)) })
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="max-h-[92dvh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{item ? item.actividade : 'Novo item'}</DialogTitle>
          <DialogDescription>{parte.titulo}</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid grid-cols-[1fr_1fr_5rem] gap-3">
            <div className="grid gap-1.5"><label htmlFor="pi-ini" className="text-sm font-medium">Início</label><CampoHora id="pi-ini" value={ini} onChange={(e) => setIni(e.target.value)} className="alvo num" /></div>
            <div className="grid gap-1.5"><label htmlFor="pi-fim" className="text-sm font-medium">Fim</label><CampoHora id="pi-fim" value={fim} onChange={(e) => setFim(e.target.value)} className="alvo num" /></div>
            <div className="grid gap-1.5"><label htmlFor="pi-ord" className="text-sm font-medium">Ordem</label><Input id="pi-ord" inputMode="numeric" value={pos} onChange={(e) => setPos(e.target.value.replace(/\D/g, ''))} className="alvo num" /></div>
          </div>
          <div className="grid gap-1.5"><label htmlFor="pi-act" className="text-sm font-medium">Actividade <span className="text-destructive-text">*</span></label>
            <Input id="pi-act" value={actividade} onChange={(e) => setActividade(e.target.value)} maxLength={200} placeholder="ex.: Hino inicial (H.A 509)" className="alvo" autoFocus={!item} /></div>
          <div className="grid gap-1.5"><span className="text-sm font-medium">Responsável</span>
            <CampoQuem id="pi-resp" tipo={tipo} setTipo={setTipo} valor={valor} setValor={setValor} nomes={nomes} /></div>
          <div className="grid gap-1.5"><label htmlFor="pi-esc" className="text-sm font-medium">Vem da escala</label>
            <CampoLigacao id="pi-esc" valor={escala} aoMudar={setEscala} nomes={nomes} />
            <p className="text-xs text-muted-foreground">Ligado à escala, "Preencher pela escala" põe aqui quem está escalado nesse dia.</p></div>
          <label className="alvo flex items-center gap-2 text-sm"><input type="checkbox" checked={destaque} onChange={(e) => setDestaque(e.target.checked)} className="size-4 accent-[var(--primary)]" />Linha em destaque na folha</label>
        </div>
        <DialogFooter className="gap-2 sm:justify-between">
          {item && pode('actividades.programa_item.terminar')
            ? <Button type="button" variant="ghost" className="alvo text-destructive-text" disabled={mut.tirarItem.isPending} onClick={tirar}><Trash2 className="size-4" />Retirar</Button> : <span />}
          <div className="flex gap-2">
            <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
            <Button type="button" className="alvo" disabled={mut.gravarItem.isPending} onClick={gravar}>{mut.gravarItem.isPending ? t.comum.aGravar : t.comum.guardar}</Button>
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/* ---------------------------------------------------------------- parte */
function DialogoParte({ parte, ordem, programaId, nomes, aoFechar }: { parte: Parte | null; ordem: number; programaId: number; nomes: Nomes; aoFechar: () => void }) {
  const mut = useProgramacaoMut(programaId)
  const { pode } = useSessao()
  const [titulo, setTitulo] = useState(parte?.titulo ?? '')
  const [rotulo, setRotulo] = useState(parte?.rotulo ?? 'Apresentador')
  const [t0, v0] = tipoInicial(parte?.apresentadorMembroId, parte?.apresentadorFamiliaId, null, parte?.apresentadorTexto)
  const [tipo, setTipo] = useState<Tipo>(t0)
  const [valor, setValor] = useState(v0)
  const [escala, setEscala] = useState(valorLigacao(parte?.escala, parte?.escalaColunaId))
  const [pos, setPos] = useState(String(parte?.ordem ?? ordem))
  const [erro, setErro] = useState<string | null>(null)
  const gravar = async () => {
    setErro(null)
    if (!titulo.trim()) return setErro('Escreva o título da parte (ex.: Programação do Culto Divino).')
    if (tipo !== 'nenhum' && !valor.trim()) return setErro('Escolha o apresentador (ou "Ninguém").')
    try {
      await mut.gravarParte.mutateAsync({
        id: parte?.id, titulo: titulo.trim(), rotulo: rotulo.trim() || 'Apresentador', ordem: Number(pos) || ordem, ...daLigacao(escala),
        apresentadorMembroId: tipo === 'membro' ? Number(valor) : null, apresentadorFamiliaId: tipo === 'familia' ? Number(valor) : null,
        apresentadorTexto: tipo === 'texto' ? valor.trim() : null,
      } as never)
      toast.success(parte ? 'Parte actualizada.' : 'Parte acrescentada.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  const tirar = () => parte && mut.tirarParte.mutate(parte.id, { onSuccess: () => { toast.success('Parte retirada da programação.'); aoFechar() }, onError: (e) => setErro(mensagemDe(e)) })
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="max-h-[92dvh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{parte ? parte.titulo : 'Nova parte'}</DialogTitle>
          <DialogDescription>O título que aparece na folha e quem apresenta esta parte.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid grid-cols-[1fr_5rem] gap-3">
            <div className="grid gap-1.5"><label htmlFor="pp-tit" className="text-sm font-medium">Título <span className="text-destructive-text">*</span></label>
              <Input id="pp-tit" value={titulo} onChange={(e) => setTitulo(e.target.value)} maxLength={100} placeholder="ex.: Programação do Culto Divino" className="alvo" /></div>
            <div className="grid gap-1.5"><label htmlFor="pp-ord" className="text-sm font-medium">Ordem</label>
              <Input id="pp-ord" inputMode="numeric" value={pos} onChange={(e) => setPos(e.target.value.replace(/\D/g, ''))} className="alvo num" /></div>
          </div>
          <div className="grid gap-1.5"><label htmlFor="pp-rot" className="text-sm font-medium">Cabeçalho da 1.ª coluna</label>
            <Input id="pp-rot" value={rotulo} onChange={(e) => setRotulo(e.target.value)} maxLength={30} placeholder="Apresentador" className="alvo" /></div>
          <div className="grid gap-1.5"><span className="text-sm font-medium">Apresentador</span>
            <CampoQuem id="pp-apr" tipo={tipo} setTipo={setTipo} valor={valor} setValor={setValor} nomes={nomes} departamentos={false} /></div>
          <div className="grid gap-1.5"><label htmlFor="pp-esc" className="text-sm font-medium">Vem da escala</label>
            <CampoLigacao id="pp-esc" valor={escala} aoMudar={setEscala} nomes={nomes} /></div>
        </div>
        <DialogFooter className="gap-2 sm:justify-between">
          {parte && pode('actividades.programa_parte.terminar')
            ? <Button type="button" variant="ghost" className="alvo text-destructive-text" disabled={mut.tirarParte.isPending} onClick={tirar}><Trash2 className="size-4" />Retirar a parte</Button> : <span />}
          <div className="flex gap-2">
            <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
            <Button type="button" className="alvo" disabled={mut.gravarParte.isPending} onClick={gravar}>{mut.gravarParte.isPending ? t.comum.aGravar : t.comum.guardar}</Button>
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/* ---------------------------------------------------------------- título e nota */
function DialogoCabecalho({ programaId, titulo: t1, nota: n1, sugestao, aoFechar }: { programaId: number; titulo: string; nota: string; sugestao: string; aoFechar: () => void }) {
  const mut = useProgramacaoMut(programaId)
  const [titulo, setTitulo] = useState(t1)
  const [nota, setNota] = useState(n1)
  const [erro, setErro] = useState<string | null>(null)
  const gravar = async () => {
    setErro(null)
    try {
      await mut.alterarPrograma.mutateAsync({ titulo: titulo.trim() || null, observacoes: nota.trim() || null } as never)
      toast.success('Programação actualizada.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader><DialogTitle>Título e nota</DialogTitle><DialogDescription>O que aparece no cimo e no fim da folha.</DialogDescription></DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5"><label htmlFor="pc-tit" className="text-sm font-medium">Título</label>
            <Input id="pc-tit" value={titulo} onChange={(e) => setTitulo(e.target.value)} maxLength={150} placeholder={sugestao} className="alvo" />
            <p className="text-xs text-muted-foreground">Vazio: {sugestao}</p></div>
          <div className="grid gap-1.5"><label htmlFor="pc-nota" className="text-sm font-medium">Nota no fim da folha</label>
            <Textarea id="pc-nota" rows={2} value={nota} onChange={(e) => setNota(e.target.value)} maxLength={500} placeholder="ex.: Passível de ajustes e simplificação" /></div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={mut.alterarPrograma.isPending} onClick={gravar}>{mut.alterarPrograma.isPending ? t.comum.aGravar : t.comum.guardar}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
