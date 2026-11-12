/**
 * Escola Sabatina · painel e classificação (F-ES-07, F-ES-08) · "Como vai a Escola Sabatina neste trimestre?"
 * Indicadores do trimestre, lugar de cada classe com a diferença para a média, presença sábado a sábado,
 * relatórios em falta e ofertas por conferir com a tesouraria. Tudo vem das vistas da base de dados
 * (a pontuação usa os pesos configurados: presença 30%, estudo 30%, ofertas 25%, visitantes 15%).
 */
import { useMemo } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { AlertTriangle, BookOpenCheck, Coins, GraduationCap, HandHeart, Trophy, UserPlus, Users } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Cartao, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { Seleccao } from '@/components/comum/Seleccao'
import { GraficoBarras } from '@/components/comum/graficos'
import { Exportar } from '@/components/comum/Exportar'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { data, dinheiro } from '@/lib/formatos'
import {
  nomeTrimestre, pct, trimestreActual, useClasses, useClassesTrimestre, useClassificacao, useSabados, useConferencia, useEmFalta, useEvolucao, usePainel, useResumoClasses, useTrimestres,
} from './api'

function Diferenca({ v, percentagem }: { v: string | null; percentagem?: boolean }) {
  if (v == null) return <span className="text-muted-foreground">—</span>
  const n = Number(v)
  const texto = percentagem ? `${n >= 0 ? '+' : ''}${(n * 100).toLocaleString('pt-PT', { maximumFractionDigits: 0 })} p.p.` : `${n >= 0 ? '+' : ''}${dinheiro(v)}`
  return <span className={n >= 0 ? 'text-success-text' : 'text-destructive-text'}>{texto}</span>
}

export default function PaginaEscolaSabatina() {
  const igreja = useIgreja()
  const { pode } = useSessao()
  const [params, setParams] = useSearchParams()
  const trimestres = useTrimestres()
  const trimestre = trimestres.data?.find((x) => x.id === Number(params.get('trimestre'))) ?? trimestreActual(trimestres.data ?? [])
  const painel = usePainel(trimestre?.id)
  const classificacao = useClassificacao(trimestre?.id)
  const resumo = useResumoClasses(trimestre?.id)
  const evolucao = useEvolucao(trimestre?.id)
  const emFalta = useEmFalta()
  const conferencia = useConferencia()
  const p = painel.data?.[0]

  // presença média da igreja em cada sábado (média das classes)
  const porSabado = useMemo(() => {
    const m = new Map<number, { data: string; soma: number; n: number }>()
    for (const l of evolucao.data ?? []) {
      if (l.pctPresenca == null) continue
      const x = m.get(l.sabado) ?? { data: l.data, soma: 0, n: 0 }
      x.soma += Number(l.pctPresenca); x.n++
      m.set(l.sabado, x)
    }
    return [...m.entries()].sort((a, b) => a[0] - b[0])
  }, [evolucao.data])

  const porConferir = (conferencia.data ?? []).filter((l) => l.situacao !== 'Conferido' && l.situacao !== 'Sem oferta')
  const faltaTrimestre = (emFalta.data ?? []).filter((l) => !trimestre || (l.data >= trimestre.dataInicio && l.data <= trimestre.dataFim))
  const alunosPorClasse = new Map((resumo.data ?? []).map((r) => [r.id, r]))
  // relatório em falta → ecrã da classe nesse sábado (o nome da classe é único na igreja)
  const sabados = useSabados(trimestre?.id)
  const classes = useClasses()
  const cts = useClassesTrimestre(trimestre?.id)
  const ligacaoEmFalta = (classe: string, numero: number) => {
    const cl = classes.data?.find((c) => c.nome === classe)
    const ct = cl && cts.data?.find((c) => c.classeId === cl.id)
    const sb = sabados.data?.find((x) => x.numero === numero)
    return ct && sb ? `/escola-sabatina/sabado/${ct.id}/${sb.id}` : undefined
  }

  return (
    <>
      <TituloPagina
        icone={GraduationCap}
        titulo={t.es.titulo}
        descricao={trimestre ? `${nomeTrimestre(trimestre)}${trimestre.temaLicao ? ` · ${trimestre.temaLicao}` : ''}` : 'Painel do trimestre e classificação das classes'}
        accoes={<>
          {(trimestres.data?.length ?? 0) > 0 && (
            <div className="w-56">
              <Seleccao aria-label="Trimestre" value={trimestre?.id ?? ''} onChange={(e) => setParams({ trimestre: e.target.value }, { replace: true })}>
                {(trimestres.data ?? []).map((x) => <option key={x.id} value={x.id}>{nomeTrimestre(x)}</option>)}
              </Seleccao>
            </div>
          )}
          {pode('escola_sabatina.relatorio_sabado.criar') && (
            <Button asChild className="alvo"><Link to="/escola-sabatina/sabado"><BookOpenCheck className="size-4" />{t.es.sabado}</Link></Button>
          )}
        </>}
      />

      {trimestres.isError ? <EstadoErro erro={trimestres.error} aoTentar={() => trimestres.refetch()} />
        : !trimestres.isPending && !trimestre ? (
          <Cartao><EstadoVazio icone={GraduationCap} titulo="Ainda não há trimestres">A Associação cria os trimestres e os sábados da lição; depois aparece aqui o painel.</EstadoVazio></Cartao>
        ) : (
          <div className="grid gap-6">
            <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
              <Indicador rotulo="Classes activas" valor={p?.classesActivas ?? 0} nota={p ? `${Number(p.membros).toLocaleString('pt-PT')} matriculados (média)` : 'sem relatórios ainda'} icone={Users} aCarregar={painel.isPending} />
              <Indicador rotulo="Presença média" valor={pct(p?.presencaMedia)} nota={`estudo diário ${pct(p?.estudoDiarioMedio)}`} icone={BookOpenCheck} tom="success" aCarregar={painel.isPending} />
              <Indicador rotulo="Ofertas missionárias" valor={dinheiro(p?.ofertasMissionarias ?? '0.00')} nota={`13.º sábado ${dinheiro(p?.oferta13Sabado ?? '0.00')}`} icone={Coins} tom="info" aCarregar={painel.isPending} />
              <Indicador rotulo="Visitantes" valor={Number(p?.visitantes ?? 0)} nota={`baptismos ${Number(p?.baptismos ?? 0)} de ${Number(p?.alvoBaptismos ?? 0)}`} icone={UserPlus} tom="warning" aCarregar={painel.isPending} />
            </div>

            <div className="grid gap-6 lg:grid-cols-12">
              <Cartao className="lg:col-span-8" titulo="Classificação" icone={Trophy}
                descricao="Pontuação de 0 a 100: presença, estudo diário, ofertas face ao alvo e visitantes"
                accoes={trimestre && <Exportar caminho="/v1/escola-sabatina/classificacao" query={{ igrejaId: igreja.id, trimestreId: trimestre.id }} nome={`classificacao-es-${trimestre.ano}-${trimestre.numero}`} />}
                semMargem>
                {classificacao.isPending ? <LinhasACarregar linhas={4} />
                  : classificacao.isError ? <EstadoErro erro={classificacao.error} aoTentar={() => classificacao.refetch()} className="mx-6 mb-6" />
                  : !classificacao.data?.length ? <EstadoVazio icone={Trophy}>As classes aparecem aqui depois do primeiro relatório do sábado.</EstadoVazio>
                  : (
                    <Tabela>
                      <thead><tr><th className="w-12 sm:pl-6">Lugar</th><th>Classe</th><th className="num">Pontos</th><th className="hidden md:table-cell num">Presença</th><th className="hidden md:table-cell num">Estudo</th><th className="hidden sm:table-cell sm:pr-6">Situação</th></tr></thead>
                      <tbody>
                        {classificacao.data.map((l) => {
                          const r = alunosPorClasse.get(l.id)
                          return (
                            <tr key={l.id}>
                              <td className="sm:pl-6"><span className={l.lugar === 1 ? 'inline-flex size-7 items-center justify-center rounded-full bg-tint-warning font-semibold text-warning-text' : 'pl-2 tabular-nums'}>{l.lugar}</span></td>
                              <td>
                                <span className="block font-medium">{l.classe}</span>
                                <span className="block text-xs text-muted-foreground">{rotulos.divisao[l.divisao]}{l.professor ? ` · ${l.professor}` : ''}</span>
                              </td>
                              <td className="num">
                                <span className="font-semibold tabular-nums">{Number(l.pontuacao).toLocaleString('pt-PT', { minimumFractionDigits: 1 })}</span>
                                <span className="mt-1 ml-auto block h-1.5 w-16 overflow-hidden rounded-full bg-muted"><span className="block h-full rounded-full bg-primary" style={{ width: `${Math.min(100, Number(l.pontuacao))}%` }} /></span>
                              </td>
                              <td className="hidden md:table-cell num">{pct(r?.pctPresenca)}<span className="block text-xs"><Diferenca v={l.difPresencaMedia} percentagem /></span></td>
                              <td className="hidden md:table-cell num">{pct(r?.pctEstudoDiario)}<span className="block text-xs"><Diferenca v={l.difEstudoMedia} percentagem /></span></td>
                              <td className="hidden sm:table-cell sm:pr-6"><Pilula variante={l.situacao === 'Acima da média' ? 'success' : 'warning'}>{l.situacao}</Pilula></td>
                            </tr>
                          )
                        })}
                      </tbody>
                    </Tabela>
                  )}
              </Cartao>

              <div className="grid content-start gap-6 lg:col-span-4">
                <Cartao titulo="Relatórios em falta" icone={AlertTriangle} descricao="Sábados que já passaram sem relatório" semMargem>
                  {emFalta.isPending ? <LinhasACarregar linhas={3} />
                    : emFalta.isError ? <EstadoErro erro={emFalta.error} className="mx-6 mb-6" />
                    : faltaTrimestre.length === 0 ? <EstadoVazio icone={BookOpenCheck}>Todos os relatórios estão feitos.</EstadoVazio>
                    : (
                      <ul className="divide-y border-t text-sm">
                        {faltaTrimestre.slice(0, 8).map((l, i) => {
                          const para = pode('escola_sabatina.relatorio_sabado.criar') ? ligacaoEmFalta(l.classe, l.sabado) : undefined
                          const conteudo = <>
                            <span className="truncate font-medium">{l.classe}</span>
                            <span className="flex-none text-xs tabular-nums text-muted-foreground">{l.sabado}.º · {data(l.data)}</span>
                          </>
                          return (
                            <li key={i}>
                              {para
                                ? <Link to={para} className="alvo flex items-center justify-between gap-3 px-5 py-2.5 hover:bg-muted/50 sm:px-6">{conteudo}</Link>
                                : <span className="flex items-center justify-between gap-3 px-5 py-2.5 sm:px-6">{conteudo}</span>}
                            </li>
                          )
                        })}
                        {faltaTrimestre.length > 8 && <li className="px-5 py-2.5 text-xs text-muted-foreground sm:px-6">e mais {faltaTrimestre.length - 8}</li>}
                      </ul>
                    )}
                </Cartao>
                <Cartao titulo="Ofertas por conferir" icone={HandHeart} descricao="Relatórios cujas ofertas ainda não batem com a tesouraria" semMargem>
                  {conferencia.isPending ? <LinhasACarregar linhas={3} />
                    : conferencia.isError ? <EstadoErro erro={conferencia.error} className="mx-6 mb-6" />
                    : porConferir.length === 0 ? <EstadoVazio icone={Coins}>Nada por conferir.</EstadoVazio>
                    : (
                      <ul className="divide-y border-t text-sm">
                        {porConferir.slice(0, 8).map((l) => (
                          <li key={l.id}>
                            <Link to={`/escola-sabatina/relatorios/${l.id}`} className="alvo flex items-center justify-between gap-3 px-5 py-2.5 hover:bg-muted/50 sm:px-6">
                              <span className="min-w-0"><span className="block truncate font-medium">{l.classe}</span><span className="block text-xs text-muted-foreground">{data(l.data)} · {dinheiro(l.ofertaRelatorio)}</span></span>
                              <Pilula variante={l.situacao === 'Valores diferentes' ? 'destructive' : 'warning'}>{l.situacao}</Pilula>
                            </Link>
                          </li>
                        ))}
                      </ul>
                    )}
                </Cartao>
              </div>
            </div>

            <Cartao titulo="Presença sábado a sábado" descricao="Média das classes activas">
              {evolucao.isPending ? <LinhasACarregar linhas={3} />
                : evolucao.isError ? <EstadoErro erro={evolucao.error} aoTentar={() => evolucao.refetch()} />
                : porSabado.length === 0 ? <EstadoVazio>Sem relatórios neste trimestre.</EstadoVazio>
                : (
                  <GraficoBarras rotulo="Presença média por sábado"
                    categorias={porSabado.map(([n]) => `${n}.º`)}
                    series={[{ nome: 'Presença', slot: 1, valores: porSabado.map(([, x]) => Math.round((x.soma / x.n) * 100)) }]}
                    formatar={(v) => `${v}%`} inteiros />
                )}
            </Cartao>

            <Cartao titulo="Resumo das classes" descricao="Médias do trimestre e alvos" semMargem
              accoes={trimestre && <Exportar caminho="/v1/escola-sabatina/resumo-classes" query={{ igrejaId: igreja.id, trimestreId: trimestre.id }} nome={`resumo-classes-es-${trimestre.ano}-${trimestre.numero}`} />}>
              {resumo.isPending ? <LinhasACarregar linhas={4} />
                : resumo.isError ? <EstadoErro erro={resumo.error} aoTentar={() => resumo.refetch()} className="mx-6 mb-6" />
                : !resumo.data?.length ? <EstadoVazio>Nenhuma classe configurada neste trimestre.</EstadoVazio>
                : (
                  <Tabela>
                    <thead><tr><th className="sm:pl-6">Classe</th><th className="num">Sábados</th><th className="num">M.M.</th><th className="num hidden sm:table-cell">Presença</th><th className="num hidden md:table-cell">E.D.</th><th className="num hidden md:table-cell">Visitantes</th><th className="num">Ofertas</th><th className="num hidden lg:table-cell sm:pr-6">% do alvo</th></tr></thead>
                    <tbody>
                      {resumo.data.map((r) => (
                        <tr key={r.id} className={r.activa ? undefined : 'opacity-60'}>
                          <td className="sm:pl-6"><span className="block font-medium">{r.classe}</span><span className="block text-xs text-muted-foreground">{r.activa ? rotulos.divisao[r.divisao] : 'Desactivada'}</span></td>
                          <td className="num">{r.sabadosRegistados}</td>
                          <td className="num">{r.mediaMatriculados ? Number(r.mediaMatriculados).toLocaleString('pt-PT', { maximumFractionDigits: 1 }) : '—'}</td>
                          <td className="num hidden sm:table-cell">{pct(r.pctPresenca)}</td>
                          <td className="num hidden md:table-cell">{pct(r.pctEstudoDiario)}</td>
                          <td className="num hidden md:table-cell">{r.visitantes}</td>
                          <td className="num">{dinheiro(r.ofertas)}</td>
                          <td className="num hidden lg:table-cell sm:pr-6">{pct(r.pctAlvoOfertas)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </Tabela>
                )}
            </Cartao>
          </div>
        )}
    </>
  )
}
