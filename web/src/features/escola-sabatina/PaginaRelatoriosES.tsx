/**
 * Relatórios da Escola Sabatina (F-ES-07, F-ES-08), como os quadros do trimestre:
 *  1. Resumo do trimestre por classe: médias de M.M. e M.P., % presença, % estudo diário, visitantes, filiais,
 *     ofertas e alvo, 13.º sábado, baptismos e alvo; desactivadas a cinzento e fora da média.
 *  2. Classificação: pontuação de 0 a 100, posição, lugar (1.º dourado, 2.º prateado, 3.º bronze) e gráfico.
 *  3. Quadro comparativo: cada classe comparada com a média (presença, estudo, ofertas, pontos atrás do 1.º).
 *  4. Evolução sábado a sábado: os números da igreja em cada sábado do trimestre.
 *  5. Por divisão: o relatório consolidado para a Associação.
 * Tudo vem das vistas da base de dados (vw_resumo_classe, vw_classificacao, vw_relatorio_associacao) e dos relatórios
 * do sábado; imprimir sai em A4 deitado; exportar descarrega o PDF/CSV da API.
 */
import { useMemo } from 'react'
import { useSearchParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { BarChart3, CalendarRange, FileBarChart, Layers, Printer, Scale, Trophy } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Cartao, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { Exportar } from '@/components/comum/Exportar'
import { useIgreja } from '@/auth/sessao'
import { api, dados } from '@/api/cliente'
import { rotulos } from '@/i18n/pt-MZ'
import { data } from '@/lib/formatos'
import { imprimirComo } from '@/lib/documentos'
import { cn } from '@/lib/utils'
import {
  chavesES, lerRelatoriosSabado, nomeTrimestre, trimestreActual, useClassesTrimestre, useClassificacao, usePesos, useResumoClasses, useSabados,
  useTrimestres, type LinhaClassificacao, type LinhaResumoClasse, type Trimestre,
} from './api'
import { BarraDados, CelulaPct, Diferenca, EscolherTrimestre, Folha, Lugar, corPontuacao, fr, textoMT, textoNum, textoPct } from './componentes'

type Aba = 'resumo' | 'classificacao' | 'comparativo' | 'evolucao' | 'divisao'
const ABAS: { k: Aba; rotulo: string; icone: typeof Trophy }[] = [
  { k: 'resumo', rotulo: 'Resumo por classe', icone: FileBarChart },
  { k: 'classificacao', rotulo: 'Classificação', icone: Trophy },
  { k: 'comparativo', rotulo: 'Quadro comparativo', icone: Scale },
  { k: 'evolucao', rotulo: 'Sábado a sábado', icone: CalendarRange },
  { k: 'divisao', rotulo: 'Por divisão', icone: Layers },
]

const media = (l: number[]) => (l.length ? l.reduce((s, x) => s + x, 0) / l.length : null)
const nomeOrd = (a: { classe: string }, b: { classe: string }) => a.classe.localeCompare(b.classe, 'pt', { numeric: true })

export default function PaginaRelatoriosES() {
  const igreja = useIgreja()
  const [params, setParams] = useSearchParams()
  const trimestres = useTrimestres()
  const trimestre = trimestres.data?.find((x) => x.id === Number(params.get('trimestre'))) ?? trimestreActual(trimestres.data ?? [])
  const aba = (ABAS.find((a) => a.k === params.get('ver'))?.k ?? 'resumo') as Aba
  const definir = (k: string, v: string) => setParams((p) => { const n = new URLSearchParams(p); n.set(k, v); return n }, { replace: true })
  const actual = ABAS.find((a) => a.k === aba)!
  const nomeFicheiro = `${actual.rotulo} ${trimestre ? nomeTrimestre(trimestre) : ''} ${igreja.nome}`

  return (
    <>
      <TituloPagina
        icone={BarChart3}
        titulo="Relatórios da Escola Sabatina"
        descricao={trimestre ? `${igreja.nome} · ${nomeTrimestre(trimestre)}${trimestre.temaLicao ? ` · ${trimestre.temaLicao}` : ''}` : igreja.nome}
        accoes={<>
          <EscolherTrimestre trimestres={trimestres.data ?? []} valor={trimestre?.id} aoMudar={(v) => definir('trimestre', v)} className="print:hidden" />
          <Button variant="outline" className="alvo print:hidden" onClick={() => imprimirComo(nomeFicheiro)}><Printer className="size-4" />Imprimir</Button>
        </>}
      />
      <div role="tablist" aria-label="Relatórios" className="mb-5 flex gap-1 overflow-x-auto border-b print:hidden">
        {ABAS.map(({ k, rotulo, icone: I }) => (
          <button key={k} type="button" role="tab" aria-selected={aba === k} onClick={() => definir('ver', k)}
            className={cn('alvo -mb-px inline-flex flex-none items-center gap-2 border-b-2 px-3 py-2.5 text-sm font-medium whitespace-nowrap transition-colors',
              aba === k ? 'border-primary text-foreground' : 'border-transparent text-muted-foreground hover:text-foreground')}>
            <I className="size-4" />{rotulo}
          </button>
        ))}
      </div>
      {trimestres.isError ? <EstadoErro erro={trimestres.error} aoTentar={() => trimestres.refetch()} />
        : trimestres.isPending ? <Cartao><LinhasACarregar linhas={6} /></Cartao>
        : !trimestre ? <Cartao><EstadoVazio icone={BarChart3} titulo="Ainda não há trimestres">A Associação cria os trimestres e os sábados da lição.</EstadoVazio></Cartao>
        : aba === 'resumo' ? <Resumo trimestre={trimestre} />
        : aba === 'classificacao' ? <Classificacao trimestre={trimestre} />
        : aba === 'comparativo' ? <Comparativo trimestre={trimestre} />
        : aba === 'evolucao' ? <Evolucao trimestre={trimestre} />
        : <PorDivisao trimestre={trimestre} />}
    </>
  )
}

function Cabeca({ n, titulo, nota, exportar }: { n: number; titulo: string; nota: string; exportar?: { caminho: string; nome: string; trimestre: Trimestre } }) {
  const igreja = useIgreja()
  return (
    <div className="mb-3 flex flex-wrap items-end justify-between gap-3">
      <div>
        <h2 className="text-base font-semibold tracking-tight uppercase">{n}. {titulo}</h2>
        <p className="mt-0.5 text-xs text-muted-foreground italic">{nota}</p>
      </div>
      {exportar && <span className="print:hidden"><Exportar caminho={exportar.caminho} query={{ igrejaId: igreja.id, trimestreId: exportar.trimestre.id }} nome={exportar.nome} /></span>}
    </div>
  )
}

/* ===================================================================== 1. resumo do trimestre por classe */
function Resumo({ trimestre }: { trimestre: Trimestre }) {
  const q = useResumoClasses(trimestre.id)
  const linhas = useMemo(() => {
    const l = q.data ?? []
    return [...l.filter((r) => r.activa).sort(nomeOrd), ...l.filter((r) => !r.activa).sort(nomeOrd)]
  }, [q.data])
  const activas = linhas.filter((r) => r.activa && r.sabadosRegistados > 0)
  const max = (f: (r: LinhaResumoClasse) => number) => Math.max(0, ...activas.map(f))
  const maxVis = max((r) => r.visitantes), maxOf = max((r) => Number(r.ofertas)), maxBap = max((r) => Number(r.baptismos))
  const m = (f: (r: LinhaResumoClasse) => number | null) => media(activas.map(f).filter((x): x is number => x != null && !Number.isNaN(x)))
  const somaBap = activas.reduce((s, r) => s + Number(r.baptismos), 0), somaAlvoBap = activas.reduce((s, r) => s + Number(r.alvoBaptismos), 0)

  return (
    <Cartao>
      <Cabeca n={1} titulo="Resumo do trimestre por classe" nota="Valores trazidos das folhas de cada classe. Classes desactivadas aparecem a cinzento e ficam fora das médias."
        exportar={{ caminho: '/v1/escola-sabatina/resumo-classes', nome: `resumo-classes-${trimestre.ano}-${trimestre.numero}`, trimestre }} />
      {q.isPending ? <LinhasACarregar linhas={6} /> : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
        : !linhas.length ? <EstadoVazio>Nenhuma classe configurada neste trimestre.</EstadoVazio> : (
          <Folha minimo="min-w-[78rem]">
            <thead>
              <tr>
                <th className="min-w-44 text-left">Classe</th><th className="min-w-36 text-left">Professor / líder</th>
                <th className="num">Membros (média M.M.)</th><th className="num">Presentes (média M.P.)</th><th className="num">% Presença</th>
                <th className="num">% Estudo diário</th><th className="num w-28">Visitantes</th><th className="num">Filiais (média)</th>
                <th className="num w-32">Ofertas (MT)</th><th className="num">Alvo de ofertas (MT)</th><th className="num">% do alvo</th>
                <th className="num">13.º sábado (MT)</th><th className="num w-24">Baptismos</th><th className="num">Alvo de baptismos</th><th className="num">% alvo baptismos</th>
              </tr>
            </thead>
            <tbody>
              {linhas.map((r) => {
                const cinza = !r.activa || r.sabadosRegistados === 0
                const pctBap = Number(r.alvoBaptismos) ? Number(r.baptismos) / Number(r.alvoBaptismos) : null
                if (!r.activa) {
                  return (
                    <tr key={r.id} className="text-muted-foreground italic [&_td]:bg-muted/50">
                      <td className="font-semibold">{r.classe} (desactivado)</td><td>{r.professor ?? 'Ir. ________'}</td><td colSpan={13} />
                    </tr>
                  )
                }
                return (
                  <tr key={r.id} className={cn(cinza && 'text-muted-foreground')}>
                    <td className="font-semibold">{r.classe}<span className="block text-[11px] font-normal text-muted-foreground">{rotulos.divisao[r.divisao]} · {r.sabadosRegistados} sáb.</span></td>
                    <td>{r.professor ?? <span className="text-muted-foreground">Ir. ________</span>}</td>
                    <td className="num tabular-nums">{textoNum(r.mediaMatriculados)}</td>
                    <td className="num tabular-nums">{textoNum(r.mediaPresentes)}</td>
                    <CelulaPct v={r.pctPresenca} />
                    <CelulaPct v={r.pctEstudoDiario} />
                    <td className="num p-1!"><BarraDados v={r.visitantes} max={maxVis}>{r.visitantes}</BarraDados></td>
                    <td className="num tabular-nums">{textoNum(r.mediaFiliais)}</td>
                    <td className="num p-1!"><BarraDados v={Number(r.ofertas)} max={maxOf}>{textoMT(r.ofertas)}</BarraDados></td>
                    <td className="num tabular-nums">{textoMT(r.alvoOfertas)}</td>
                    <CelulaPct v={r.pctAlvoOfertas} tipo="alvo" />
                    <td className="num tabular-nums">{textoMT(r.oferta13Sabado)}</td>
                    <td className="num p-1!"><BarraDados v={Number(r.baptismos)} max={maxBap}>{Number(r.baptismos) || '—'}</BarraDados></td>
                    <td className="num tabular-nums">{r.alvoBaptismos}</td>
                    <CelulaPct v={pctBap} tipo="alvo" />
                  </tr>
                )
              })}
            </tbody>
            {activas.length > 0 && (
              <tfoot>
                <tr>
                  <td colSpan={2}>Média das classes activas</td>
                  <td className="num tabular-nums">{textoNum(m((r) => fr(r.mediaMatriculados)))}</td>
                  <td className="num tabular-nums">{textoNum(m((r) => fr(r.mediaPresentes)))}</td>
                  <CelulaPct v={m((r) => fr(r.pctPresenca))} />
                  <CelulaPct v={m((r) => fr(r.pctEstudoDiario))} />
                  <td className="num tabular-nums">{textoNum(m((r) => r.visitantes), 0)}</td>
                  <td className="num tabular-nums">{textoNum(m((r) => fr(r.mediaFiliais)))}</td>
                  <td className="num tabular-nums">{textoMT(m((r) => fr(r.ofertas)))}</td>
                  <td className="num tabular-nums">{textoMT(m((r) => fr(r.alvoOfertas)))}</td>
                  <CelulaPct v={m((r) => fr(r.pctAlvoOfertas))} tipo="alvo" />
                  <td className="num tabular-nums">{textoMT(activas.reduce((s, r) => s + Number(r.oferta13Sabado), 0))}</td>
                  <td className="num tabular-nums">{somaBap}</td>
                  <td className="num tabular-nums">{somaAlvoBap}</td>
                  <CelulaPct v={somaAlvoBap ? somaBap / somaAlvoBap : null} tipo="alvo" />
                </tr>
              </tfoot>
            )}
          </Folha>
        )}
      <p className="mt-2 text-[11px] text-muted-foreground">Na linha final: médias por classe; 13.º sábado, baptismos e alvo de baptismos são somas.</p>
    </Cartao>
  )
}

/* ===================================================================== 2. classificação */
function useClassificacaoCompleta(trimestre: Trimestre) {
  const cl = useClassificacao(trimestre.id)
  const res = useResumoClasses(trimestre.id)
  const linhas = useMemo(() => {
    const porId = new Map((cl.data ?? []).map((c) => [c.id, c]))
    return [...(res.data ?? [])].sort(nomeOrd).sort((a, b) => Number(b.activa) - Number(a.activa))
      .map((r) => ({ r, c: porId.get(r.id) as LinhaClassificacao | undefined }))
  }, [cl.data, res.data])
  return { linhas, q: cl.isError ? cl : res, aCarregar: cl.isPending || res.isPending }
}

function Classificacao({ trimestre }: { trimestre: Trimestre }) {
  const { linhas, q, aCarregar } = useClassificacaoCompleta(trimestre)
  const pesos = usePesos()
  const p = pesos.data?.find((x) => x.trimestreId === trimestre.id) ?? pesos.data?.find((x) => x.trimestreId == null)
  const pc = (v?: string) => `${Math.round(Number(v ?? 0) * 100)}%`
  return (
    <Cartao>
      <Cabeca n={2} titulo="Classificação das classes" nota="1.º lugar a dourado, 2.º a prateado, 3.º a bronze. Em caso de empate, fica à frente a classe que aparece primeiro."
        exportar={{ caminho: '/v1/escola-sabatina/classificacao', nome: `classificacao-${trimestre.ano}-${trimestre.numero}`, trimestre }} />
      {aCarregar ? <LinhasACarregar linhas={6} /> : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
        : !linhas.length ? <EstadoVazio icone={Trophy}>Nenhuma classe configurada neste trimestre.</EstadoVazio> : (
          <Folha minimo="min-w-[52rem]" className="[&_thead_th]:bg-[#9a7612] dark:[&_thead_th]:bg-[#5c470b]">
            <thead>
              <tr><th className="min-w-44 text-left">Classe</th><th className="num w-36">Pontuação (0–100)</th><th className="centro w-24">Posição</th><th className="centro w-32">Lugar</th><th className="text-left">Gráfico da pontuação</th></tr>
            </thead>
            <tbody>
              {linhas.map(({ r, c }) => {
                const medalha = c && c.lugar <= 3 ? ['bg-[#fdf6dc]! dark:bg-[#3a2f0c]!', 'bg-[#f1f3f6]! dark:bg-[#262b33]!', 'bg-[#fbeee4]! dark:bg-[#3a2416]!'][c.lugar - 1] : ''
                if (!r.activa || !c) {
                  return (
                    <tr key={r.id} className="text-muted-foreground [&_td]:bg-muted/40">
                      <td className="font-medium">{r.classe}{!r.activa ? ' (desactivado)' : ''}</td>
                      <td className="num">—</td><td className="centro">—</td><td className="centro">{r.activa ? <span className="text-xs">sem relatórios</span> : '—'}</td><td />
                    </tr>
                  )
                }
                const v = Number(c.pontuacao)
                return (
                  <tr key={r.id}>
                    <td className={cn('font-semibold', medalha)}>{r.classe}</td>
                    <td className={cn('num text-base font-bold tabular-nums', medalha)}>{textoNum(v)}</td>
                    <td className={cn('centro font-semibold tabular-nums', medalha)}>{c.lugar}</td>
                    <td className={cn('centro', medalha)}><Lugar n={c.lugar} /></td>
                    <td className={medalha}>
                      <span className="flex items-center gap-2">
                        <span className="h-4 flex-1 overflow-hidden rounded-sm bg-muted">
                          <span className="block h-full rounded-sm" style={{ width: `${Math.max(0, Math.min(100, v))}%`, background: corPontuacao(c.lugar) }} />
                        </span>
                        <span className="w-10 text-right text-xs font-semibold tabular-nums" style={{ color: c.lugar <= 3 ? corPontuacao(c.lugar) : undefined }}>{textoNum(v)}</span>
                      </span>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </Folha>
        )}
      {p && (
        <p className="mt-3 text-xs text-muted-foreground">
          Pontuação = presença {pc(p.pesoPresenca)} + estudo diário {pc(p.pesoEstudo)} + ofertas face ao alvo {pc(p.pesoOfertas)} (conta até {pc(p.limiteOfertas)} do alvo)
          + visitantes {pc(p.pesoVisitantes)} (face à classe com mais visitantes).
        </p>
      )}
    </Cartao>
  )
}

/* ===================================================================== 3. quadro comparativo */
function Comparativo({ trimestre }: { trimestre: Trimestre }) {
  const { linhas, q, aCarregar } = useClassificacaoCompleta(trimestre)
  const activas = linhas.filter(({ r, c }) => r.activa && c)
  const mediaOf = media(activas.map(({ r }) => Number(r.ofertas)))
  return (
    <Cartao>
      <Cabeca n={3} titulo="Quadro comparativo · cada classe comparada com a média" nota="Números positivos (verde) = acima da média das classes activas; negativos (vermelho) = abaixo." />
      {aCarregar ? <LinhasACarregar linhas={6} /> : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
        : !activas.length ? <EstadoVazio icone={Scale}>As classes aparecem aqui depois do primeiro relatório do sábado.</EstadoVazio> : (
          <Folha minimo="min-w-[60rem]" className="[&_thead_th]:bg-[#2c5aa0] dark:[&_thead_th]:bg-[#1d3a68]">
            <thead>
              <tr>
                <th className="min-w-44 text-left">Classe</th><th className="num">% Presença</th><th className="num">Diferença vs. média</th><th className="num">% Estudo diário</th>
                <th className="num">Diferença vs. média</th><th className="num">Ofertas (MT)</th><th className="num">Diferença vs. média (MT)</th><th className="num">Pontos atrás do 1.º</th><th className="text-left">Situação geral</th>
              </tr>
            </thead>
            <tbody>
              {activas.map(({ r, c }) => {
                const acima = c!.situacao === 'Acima da média'
                const atras = Number(c!.pontosAtrasDo1o)
                return (
                  <tr key={r.id}>
                    <td className="font-semibold">{r.classe}</td>
                    <td className="num tabular-nums">{textoPct(r.pctPresenca)}</td>
                    <td className={cn('num', Number(c!.difPresencaMedia) >= 0 ? 'bg-tint-success/70' : 'bg-tint-destructive/70')}><Diferenca v={c!.difPresencaMedia} tipo="pp" /></td>
                    <td className="num tabular-nums">{textoPct(r.pctEstudoDiario)}</td>
                    <td className={cn('num', Number(c!.difEstudoMedia) >= 0 ? 'bg-tint-success/70' : 'bg-tint-destructive/70')}><Diferenca v={c!.difEstudoMedia} tipo="pp" /></td>
                    <td className="num tabular-nums">{textoMT(r.ofertas)}</td>
                    <td className={cn('num', Number(c!.difOfertasMedia) >= 0 ? 'bg-tint-success/70' : 'bg-tint-destructive/70')}><Diferenca v={c!.difOfertasMedia} tipo="mt" /></td>
                    <td className="num tabular-nums">{atras === 0 ? '—' : textoNum(atras)}</td>
                    <td className={cn('font-semibold whitespace-nowrap', acima ? 'text-success-text' : 'text-destructive-text')}>{acima ? '▲' : '▼'} {c!.situacao}</td>
                  </tr>
                )
              })}
            </tbody>
            <tfoot>
              <tr>
                <td>Média das classes activas</td>
                <td className="num tabular-nums">{textoPct(media(activas.map(({ r }) => Number(r.pctPresenca ?? 0))))}</td><td />
                <td className="num tabular-nums">{textoPct(media(activas.map(({ r }) => Number(r.pctEstudoDiario ?? 0))))}</td><td />
                <td className="num tabular-nums">{textoMT(mediaOf)}</td><td /><td /><td />
              </tr>
            </tfoot>
          </Folha>
        )}
    </Cartao>
  )
}

/* ===================================================================== 4. sábado a sábado */
function Evolucao({ trimestre }: { trimestre: Trimestre }) {
  const igreja = useIgreja()
  const sabados = useSabados(trimestre.id)
  const cts = useClassesTrimestre(trimestre.id)
  const activas = useMemo(() => new Set((cts.data ?? []).filter((c) => c.estado === 'ACTIVO').map((c) => c.id)), [cts.data])
  const alvo = (cts.data ?? []).filter((c) => c.estado === 'ACTIVO').reduce((s, c) => s + Number(c.alvoOfertaSabado ?? 0), 0)
  const q = useQuery({
    enabled: !!sabados.data?.length,
    queryKey: [...chavesES.todos(igreja.id), 'evolucao-sabados', trimestre.id],
    queryFn: async () => Object.fromEntries(await Promise.all((sabados.data ?? []).filter((s) => s.data <= new Date().toISOString().slice(0, 10))
      .map(async (s) => [s.id, await lerRelatoriosSabado(igreja.id, s.id)] as const))),
  })
  const linhas = (sabados.data ?? []).map((s) => {
    const rs = (q.data?.[s.id] ?? []).filter((r) => activas.has(r.classeTrimestreId))
    const t = (f: (r: (typeof rs)[number]) => number) => rs.reduce((x, r) => x + f(r), 0)
    return { s, n: rs.length, mm: t((r) => r.membrosMatriculados), mp: t((r) => r.membrosPresentes), ed: t((r) => r.estudoDiario), vis: t((r) => r.visitantes),
      fil: t((r) => r.filiais), of: t((r) => Number(r.oferta)), o13: t((r) => Number(r.oferta13Sabado)), desp: t((r) => Number(r.ofertaDespesas)) }
  })
  const com = linhas.filter((l) => l.n > 0)
  const T = (f: (l: (typeof linhas)[number]) => number) => com.reduce((x, l) => x + f(l), 0)
  let acum = 0
  return (
    <Cartao>
      <Cabeca n={4} titulo="Evolução da igreja sábado a sábado" nota={`Soma das classes activas em cada sábado (${activas.size} classes). O alvo é a soma dos alvos de ofertas por sábado.`}
        exportar={{ caminho: '/v1/escola-sabatina/evolucao', nome: `evolucao-${trimestre.ano}-${trimestre.numero}`, trimestre }} />
      {sabados.isPending || cts.isPending || q.isPending ? <LinhasACarregar linhas={8} />
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} /> : (
          <Folha minimo="min-w-[64rem]">
            <thead>
              <tr>
                <th className="centro w-14">Sáb.</th><th className="text-left">Data</th><th className="num">Classes</th><th className="num">M.M.</th><th className="num">M.P.</th><th className="num">% Presença</th>
                <th className="num">E.D.</th><th className="num">% E.D.</th><th className="num">Visit.</th><th className="num">Ofertas</th><th className="num">Alvo</th><th className="num">Acumulado</th>
                <th className="num">% do alvo</th><th className="num">13.º sáb.</th><th className="num">Despesas ES</th><th className="num">Fil.</th>
              </tr>
            </thead>
            <tbody>
              {linhas.map((l) => {
                acum += l.of
                const vazio = l.n === 0
                return (
                  <tr key={l.s.id} className={cn(vazio && 'text-muted-foreground')}>
                    <td className="centro font-semibold tabular-nums">{String(l.s.numero).padStart(2, '0')}{l.s.decimoTerceiro && <span className="ml-1 rounded bg-tint-warning px-1 text-[10px] text-warning-text">13.º</span>}</td>
                    <td className="tabular-nums">{data(l.s.data)}</td>
                    <td className="num tabular-nums">{vazio ? '—' : `${l.n}/${activas.size}`}</td>
                    <td className="num tabular-nums">{vazio ? '—' : l.mm}</td><td className="num tabular-nums">{vazio ? '—' : l.mp}</td>
                    {vazio ? <td className="num">—</td> : <CelulaPct v={l.mm ? l.mp / l.mm : null} />}
                    <td className="num tabular-nums">{vazio ? '—' : l.ed}</td>
                    {vazio ? <td className="num">—</td> : <CelulaPct v={l.mp ? l.ed / l.mp : null} />}
                    <td className="num tabular-nums">{vazio ? '—' : l.vis}</td>
                    <td className="num tabular-nums">{vazio ? '—' : textoMT(l.of)}</td>
                    <td className="num tabular-nums text-muted-foreground">{textoMT(alvo)}</td>
                    <td className="num tabular-nums">{vazio ? '—' : textoMT(acum)}</td>
                    {vazio ? <td className="num">—</td> : <CelulaPct v={alvo ? l.of / alvo : null} tipo="alvo" />}
                    <td className="num tabular-nums">{vazio ? '—' : textoMT(l.o13)}</td>
                    <td className="num tabular-nums">{vazio ? '—' : textoMT(l.desp)}</td>
                    <td className="num tabular-nums">{vazio ? '—' : l.fil}</td>
                  </tr>
                )
              })}
            </tbody>
            <tfoot>
              <tr>
                <td colSpan={2}>Total / média</td><td className="num">{com.length} sáb.</td>
                <td className="num tabular-nums">{textoNum(media(com.map((l) => l.mm)))}</td><td className="num tabular-nums">{textoNum(media(com.map((l) => l.mp)))}</td>
                <CelulaPct v={T((l) => l.mm) ? T((l) => l.mp) / T((l) => l.mm) : null} />
                <td className="num tabular-nums">{textoNum(media(com.map((l) => l.ed)))}</td>
                <CelulaPct v={T((l) => l.mp) ? T((l) => l.ed) / T((l) => l.mp) : null} />
                <td className="num tabular-nums">{T((l) => l.vis)}</td>
                <td className="num tabular-nums">{textoMT(T((l) => l.of))}</td>
                <td className="num tabular-nums">{textoMT(alvo * linhas.length)}</td>
                <td className="num tabular-nums">{textoMT(T((l) => l.of))}</td>
                <CelulaPct v={alvo ? T((l) => l.of) / (alvo * linhas.length) : null} tipo="alvo" />
                <td className="num tabular-nums">{textoMT(T((l) => l.o13))}</td>
                <td className="num tabular-nums">{textoMT(T((l) => l.desp))}</td>
                <td className="num tabular-nums">{textoNum(media(com.map((l) => l.fil)))}</td>
              </tr>
            </tfoot>
          </Folha>
        )}
    </Cartao>
  )
}

/* ===================================================================== 5. por divisão (Associação) */
interface LinhaDivisao { divisao: string; igrejas: number; classes: number; matriculados: string; presentes: string; ofertasMissionarias: string; oferta13Sabado: string; baptismos: string }

function PorDivisao({ trimestre }: { trimestre: Trimestre }) {
  const igreja = useIgreja()
  const q = useQuery({
    queryKey: [...chavesES.todos(igreja.id), 'vista', 'relatorio-associacao', trimestre.id],
    queryFn: async () => (await dados(api.GET('/v1/escola-sabatina/relatorio-associacao', { params: { query: { igrejaId: igreja.id, trimestreId: trimestre.id } } }))) as unknown as LinhaDivisao[],
  })
  const l = q.data ?? []
  const S = (f: (x: LinhaDivisao) => number) => l.reduce((s, x) => s + f(x), 0)
  return (
    <Cartao>
      <Cabeca n={5} titulo="Relatório por divisão (Associação / Missão)" nota="Consolidado das igrejas da Associação que esta igreja integra, por divisão da Escola Sabatina (médias do trimestre)."
        exportar={{ caminho: '/v1/escola-sabatina/relatorio-associacao', nome: `es-por-divisao-${trimestre.ano}-${trimestre.numero}`, trimestre }} />
      {q.isPending ? <LinhasACarregar linhas={5} /> : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
        : !l.length ? <EstadoVazio icone={Layers}>Sem relatórios neste trimestre.</EstadoVazio> : (
          <Folha minimo="min-w-[48rem]">
            <thead>
              <tr><th className="text-left">Divisão</th><th className="num">Igrejas</th><th className="num">Classes</th><th className="num">Matriculados</th><th className="num">Presentes</th><th className="num">% Presença</th><th className="num">Ofertas missionárias</th><th className="num">13.º sábado</th><th className="num">Baptismos</th></tr>
            </thead>
            <tbody>
              {l.map((x) => (
                <tr key={x.divisao}>
                  <td className="font-semibold">{rotulos.divisao[x.divisao] ?? x.divisao}</td>
                  <td className="num tabular-nums">{x.igrejas}</td><td className="num tabular-nums">{x.classes}</td>
                  <td className="num tabular-nums">{textoNum(x.matriculados)}</td><td className="num tabular-nums">{textoNum(x.presentes)}</td>
                  <CelulaPct v={Number(x.matriculados) ? Number(x.presentes) / Number(x.matriculados) : null} />
                  <td className="num tabular-nums">{textoMT(x.ofertasMissionarias)}</td><td className="num tabular-nums">{textoMT(x.oferta13Sabado)}</td>
                  <td className="num tabular-nums">{Number(x.baptismos)}</td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr>
                <td>Total</td><td /><td className="num tabular-nums">{S((x) => x.classes)}</td>
                <td className="num tabular-nums">{textoNum(S((x) => Number(x.matriculados)))}</td><td className="num tabular-nums">{textoNum(S((x) => Number(x.presentes)))}</td>
                <CelulaPct v={S((x) => Number(x.matriculados)) ? S((x) => Number(x.presentes)) / S((x) => Number(x.matriculados)) : null} />
                <td className="num tabular-nums">{textoMT(S((x) => Number(x.ofertasMissionarias)))}</td><td className="num tabular-nums">{textoMT(S((x) => Number(x.oferta13Sabado)))}</td>
                <td className="num tabular-nums">{S((x) => Number(x.baptismos))}</td>
              </tr>
            </tfoot>
          </Folha>
        )}
    </Cartao>
  )
}
