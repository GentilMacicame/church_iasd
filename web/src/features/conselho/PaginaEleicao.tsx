/**
 * Eleição de oficiais (P-04, F-SEC-08):
 *   1. a comissão de nomeações prepara a lista (cargo → membro) e imprime o relatório para ler à igreja;
 *   2. a igreja vota o relatório (voto do tipo ELEICAO, em reunião regular ou assembleia administrativa);
 *   3. o secretário regista todos os mandatos com esse voto e, se quiser, termina os mandatos anteriores desses cargos.
 * A lista fica guardada neste aparelho até ser registada (a comissão reúne-se semanas antes do voto). A base de dados
 * recusa membros que não estejam activos nesta igreja ou que estejam sob censura, e explica porquê em cada linha.
 */
import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { CheckCircle2, ListPlus, Printer, Trash2, Vote, XCircle } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Cartao, Indicador, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { CampoEscolha } from '@/components/comum/CampoEscolha'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { CabecalhoDocumento } from '@/components/layout/Marca'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { data, dataCompleta, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { imprimirComo } from '@/lib/documentos'
import { useMembrosBasicos } from '@/features/membros/api'
import { CampoVoto } from '@/features/livro/CampoVoto'
import { useCargos, useConselho, useConselhoMut, useIgrejaDados } from './api'
import { Paginada } from '@/components/comum/Paginacao'

interface Linha { chave: string; cargoId: string; membroId: number | null; resultado?: { ok: boolean; texto: string } }
const nova = (cargoId = '', membroId: number | null = null): Linha => ({ chave: crypto.randomUUID(), cargoId, membroId })
const vesperaDe = (iso: string) => new Date(Date.parse(iso + 'T12:00:00Z') - 86_400_000).toISOString().slice(0, 10)

/** Rascunho da comissão, por igreja, neste aparelho (falha em silêncio se o navegador não guardar). */
function useRascunho(igrejaId: number) {
  const chave = `eleicao.rascunho.${igrejaId}`
  const ler = (): { linhas: Linha[]; inicio: string } | null => { try { return JSON.parse(localStorage.getItem(chave) ?? 'null') } catch { return null } }
  const gravar = (v: { linhas: Linha[]; inicio: string } | null) => { try { if (v) localStorage.setItem(chave, JSON.stringify(v)); else localStorage.removeItem(chave) } catch { /* sem armazenamento */ } }
  return { ler, gravar }
}

export default function PaginaEleicao() {
  const igreja = useIgreja()
  const { pode } = useSessao()
  const cargos = useCargos()
  const membros = useMembrosBasicos()
  const conselho = useConselho()
  const dadosIgreja = useIgrejaDados()
  const { registar, terminarMandato } = useConselhoMut()
  const rascunho = useRascunho(igreja.id)
  const [linhas, setLinhas] = useState<Linha[]>(() => rascunho.ler()?.linhas.map((l) => ({ ...l, resultado: undefined })) ?? [])
  const [inicio, setInicio] = useState(() => rascunho.ler()?.inicio ?? `${new Date().getFullYear() + 1}-01-01`)
  const [voto, setVoto] = useState('')
  const [terminarAnteriores, setTerminarAnteriores] = useState(true)
  const [aRegistar, setARegistar] = useState(false)
  const [erro, setErro] = useState<string | null>(null)
  useEffect(() => { rascunho.gravar(linhas.length ? { linhas: linhas.map(({ resultado: _r, ...l }) => l), inicio } : null) }, [linhas, inicio]) // eslint-disable-line react-hooks/exhaustive-deps

  const listaCargos = useMemo(() => (cargos.data ?? []).filter((c) => !c.endDate)
    .sort((a, b) => Number(!!b.conselho) - Number(!!a.conselho) || a.nome.localeCompare(b.nome, 'pt')), [cargos.data])
  const nomeCargo = (id: string) => listaCargos.find((c) => String(c.id) === id)?.nome ?? '—'
  const nomeDe = (id: number) => { const m = membros.data?.find((x) => x.id === id); return m ? `${m.nome} ${m.apelido}` : undefined }
  const emExercicio = (conselho.data ?? []).filter((o) => o.estadoMandato === 'ACTIVO' || o.estadoMandato === 'A_TERMINAR' || o.estadoMandato === 'FUTURO')
  const anos = dadosIgreja.data?.mandatoAnos ?? 1
  const mudar = (chave: string, m: Partial<Linha>) => setLinhas((l) => l.map((x) => x.chave === chave ? { ...x, ...m, resultado: undefined } : x))
  const porRegistar = linhas.filter((l) => !l.resultado?.ok)
  const completas = linhas.filter((l) => l.cargoId && l.membroId)

  const comecarPelosActuais = () => {
    setLinhas(emExercicio.length
      ? [...emExercicio].sort((a, b) => a.cargo.localeCompare(b.cargo, 'pt')).map((o) => nova(String(o.cargoId), null))
      : listaCargos.filter((c) => c.conselho).map((c) => nova(String(c.id))))
  }

  const registarTudo = async () => {
    setErro(null)
    if (!voto) return setErro('Escolha o voto da igreja que aprovou o relatório da comissão.')
    if (!/^\d{4}-\d{2}-\d{2}$/.test(inicio)) return setErro('Escreva o início dos mandatos como dd/mm/aaaa.')
    const aFazer = porRegistar.filter((l) => l.cargoId && l.membroId)
    if (!aFazer.length) return setErro('Não há eleitos por registar: escolha o membro de cada cargo.')
    setARegistar(true)
    const novos = new Set<number>()
    const cargosEleitos = new Set<number>()
    const resultados = new Map<string, { ok: boolean; texto: string }>()
    for (const l of aFazer) {
      try {
        const r = await registar.mutateAsync({ membroId: l.membroId!, cargoId: Number(l.cargoId), dataInicio: inicio, votoId: Number(voto) }) as { id: number }
        novos.add(r.id); cargosEleitos.add(Number(l.cargoId))
        resultados.set(l.chave, { ok: true, texto: 'Registado' })
      } catch (e) {
        resultados.set(l.chave, { ok: false, texto: mensagemDe(e) })
      }
    }
    let terminados = 0
    if (terminarAnteriores) {
      // os mandatos anteriores destes cargos acabam na véspera do início dos novos
      for (const o of emExercicio.filter((x) => cargosEleitos.has(x.cargoId) && !novos.has(x.id) && x.dataInicio < inicio && (x.dataFim ?? x.fimPrevisto ?? '9999') >= inicio)) {
        try { await terminarMandato.mutateAsync({ id: o.id, dataFim: vesperaDe(inicio) }); terminados++ } catch (e) { toast.error(`${o.membro} (${o.cargo}): ${mensagemDe(e)}`) }
      }
    }
    setLinhas((ls) => ls.map((l) => resultados.has(l.chave) ? { ...l, resultado: resultados.get(l.chave) } : l))
    setARegistar(false)
    const ok = [...resultados.values()].filter((r) => r.ok).length, falhas = resultados.size - ok
    if (falhas) toast.error(`${ok} registado(s); ${falhas} recusado(s) — veja o motivo em cada linha.`)
    else {
      toast.success(`${ok} oficial(is) registado(s)${terminados ? `; ${terminados} mandato(s) anterior(es) terminado(s)` : ''}.`)
      setLinhas([]); rascunho.gravar(null); setVoto('')
    }
  }

  if (cargos.isPending || membros.isPending || conselho.isPending) return <Barra className="h-96 w-full" />
  const podeRegistar = pode('secretaria.oficial.criar')

  return (
    <>
      <div className="print:hidden">
      <TituloPagina icone={Vote} titulo="Eleição de oficiais" descricao="Proposta da comissão de nomeações, voto da igreja e registo dos mandatos"
        antes={<Link to="/conselho" className="text-sm text-muted-foreground hover:underline print:hidden">← Conselho da igreja</Link>}
        accoes={linhas.length > 0 && <Button variant="outline" className="alvo print:hidden" onClick={() => imprimirComo(`Relatório da comissão de nomeações - ${igreja.nome}`)}><Printer className="size-4" />Imprimir / guardar PDF</Button>} />
      </div>

      <div className="grid gap-6 print:hidden">
        <div className="grid gap-3 sm:grid-cols-3">
          <Indicador rotulo="Cargos na proposta" valor={String(linhas.length)} icone={ListPlus} />
          <Indicador rotulo="Com membro escolhido" valor={`${completas.length} de ${linhas.length}`} icone={CheckCircle2} tom={completas.length === linhas.length && linhas.length ? 'success' : 'warning'} />
          <Indicador rotulo="Mandatos de" valor={`${anos} ${anos === 1 ? 'ano' : 'anos'}`} nota={/^\d{4}-\d{2}-\d{2}$/.test(inicio) ? `a partir de ${data(inicio)}` : undefined} icone={Vote} tom="info" />
        </div>

        <Cartao titulo="1. Proposta da comissão de nomeações" descricao="Um cargo por linha (repita o cargo para vários anciãos ou diaconisas). Fica guardada neste aparelho até ao registo." semMargem
          accoes={(
            <div className="flex flex-wrap gap-2">
              {!linhas.length && <Button size="sm" variant="outline" className="alvo" onClick={comecarPelosActuais}>Começar pelos cargos actuais</Button>}
              <Button size="sm" className="alvo" onClick={() => setLinhas((l) => [...l, nova()])}><ListPlus className="size-4" />Juntar cargo</Button>
            </div>
          )}>
          {!linhas.length ? (
            <EstadoVazio icone={ListPlus} titulo="A proposta está vazia">
              Comece pelos cargos em exercício (para eleger os sucessores) ou junte os cargos um a um.
            </EstadoVazio>
          ) : (
            <Paginada itens={linhas}>{(vis, ini) => (
            <ul className="divide-y">
              {vis.map((l, iLocal) => { const i = ini + iLocal; return (
                <li key={l.chave} className={cn('grid gap-2 px-4 py-3 sm:grid-cols-[2rem_minmax(0,1fr)_minmax(0,1fr)_auto] sm:items-center sm:px-6', l.resultado?.ok && 'bg-success/5')}>
                  <span className="hidden text-sm text-muted-foreground tabular-nums sm:block">{i + 1}.</span>
                  <CampoEscolha id={`ele-car-${l.chave}`} valor={l.cargoId} aoMudar={(v) => mudar(l.chave, { cargoId: v })} vazio="Cargo…" pesquisar="Pesquisar cargo…" disabled={l.resultado?.ok}
                    opcoes={listaCargos.map((c) => ({ valor: String(c.id), rotulo: c.nome, detalhe: c.conselho ? 'conselho da igreja' : undefined }))} />
                  <div className="min-w-0">
                    {l.resultado?.ok
                      ? <p className="flex h-9 items-center rounded-md border bg-muted/40 px-3 text-sm">{l.membroId ? nomeDe(l.membroId) : '—'}</p>
                      : <CampoMembro id={`ele-mem-${l.chave}`} valor={l.membroId} aoMudar={(v) => mudar(l.chave, { membroId: v })} nomeDe={nomeDe} vazio="Membro proposto…" />}
                    {l.cargoId && emExercicio.some((o) => String(o.cargoId) === l.cargoId) && !l.resultado && (
                      <p className="mt-1 truncate text-xs text-muted-foreground">Actual: {emExercicio.filter((o) => String(o.cargoId) === l.cargoId).map((o) => o.membro).join(', ')}</p>
                    )}
                    {l.resultado && (
                      <p className={cn('mt-1 flex items-center gap-1 text-xs', l.resultado.ok ? 'text-success-text' : 'text-destructive-text')} role={l.resultado.ok ? undefined : 'alert'}>
                        {l.resultado.ok ? <CheckCircle2 className="size-3.5" /> : <XCircle className="size-3.5" />}{l.resultado.texto}
                      </p>
                    )}
                  </div>
                  <Button size="icon" variant="ghost" className="alvo justify-self-end text-muted-foreground" aria-label={`Tirar a linha ${i + 1}`} onClick={() => setLinhas((x) => x.filter((y) => y.chave !== l.chave))}>
                    <Trash2 className="size-4" />
                  </Button>
                </li>
              ) })}
            </ul>
            )}</Paginada>
          )}
        </Cartao>

        {podeRegistar && linhas.length > 0 && (
          <Cartao titulo="2. Voto da igreja e registo" descricao="Depois de a igreja votar o relatório (reunião regular ou assembleia administrativa), registe os eleitos com esse voto.">
            <div className="grid gap-4">
              <ErroFormulario mensagem={erro} />
              <div className="grid gap-4 md:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]">
                <div className="grid gap-1.5">
                  <label htmlFor="ele-voto" className="text-sm font-medium">Voto que aprovou o relatório</label>
                  <CampoVoto id="ele-voto" valor={voto} aoMudar={setVoto} reunioes={['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA']} preferir="ELEICAO" />
                </div>
                <div className="grid gap-1.5">
                  <label htmlFor="ele-ini" className="text-sm font-medium">Início dos mandatos</label>
                  <CampoData id="ele-ini" value={inicio} onChange={setInicio} className="alvo" />
                </div>
              </div>
              <label className="flex items-start gap-3 text-sm">
                <input type="checkbox" checked={terminarAnteriores} onChange={(e) => setTerminarAnteriores(e.target.checked)} className="mt-0.5 size-4 accent-[var(--color-primary)]" />
                <span>Terminar os mandatos actuais destes cargos na véspera ({/^\d{4}-\d{2}-\d{2}$/.test(inicio) ? data(vesperaDe(inicio)) : '—'})</span>
              </label>
              <div className="flex justify-end">
                <Button className="alvo" disabled={aRegistar || !completas.length} onClick={registarTudo}>
                  <Vote className="size-4" />{aRegistar ? 'A registar…' : `Registar ${porRegistar.filter((l) => l.cargoId && l.membroId).length} eleito(s)`}
                </Button>
              </div>
            </div>
          </Cartao>
        )}
      </div>

      {/* relatório da comissão para ler e votar na igreja */}
      <article className="documento-a4 hidden gap-5 text-[11pt] text-black print:grid">
        <CabecalhoDocumento titulo={igreja.nome} linha="Comissão de nomeações" />
        <h2 className="text-center text-base font-bold uppercase">Relatório da comissão de nomeações</h2>
        <p>A comissão de nomeações propõe à igreja os seguintes irmãos para os cargos indicados, para mandatos de {anos} {anos === 1 ? 'ano' : 'anos'} a partir de {/^\d{4}-\d{2}-\d{2}$/.test(inicio) ? dataCompleta(inicio) : '—'}:</p>
        <table className="w-full border-collapse text-[10.5pt]">
          <thead><tr><th className="border-b border-black py-1 text-left">Cargo</th><th className="border-b border-black py-1 text-left">Proposto(a)</th></tr></thead>
          <tbody>
            {linhas.map((l) => <tr key={l.chave}><td className="border-b border-gray-300 py-1">{nomeCargo(l.cargoId)}</td><td className="border-b border-gray-300 py-1">{l.membroId ? nomeDe(l.membroId) : '—'}</td></tr>)}
          </tbody>
        </table>
        <p className="text-sm">Data: {dataCompleta(hojeIso())}</p>
        <div className="mt-10 grid grid-cols-2 gap-16 text-center text-sm">
          <div className="border-t border-black pt-1">O presidente da comissão</div>
          <div className="border-t border-black pt-1">O secretário da comissão</div>
        </div>
      </article>
    </>
  )
}
