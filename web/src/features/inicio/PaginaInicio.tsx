/**
 * Início · "Como está a igreja e o que precisa de mim esta semana?"
 * Painel de direcção em três faixas, cada bloco só para quem o pode ler:
 *  1. indicadores-chave (membros, dinheiro do mês, o que está por resolver);
 *  2. "Precisa de atenção" (tudo o que espera uma acção, da secretaria e da tesouraria, num só sítio) e o próximo
 *     sábado (a escala do dia);
 *  3. tesouraria (entradas e saídas, onde está o dinheiro) e membros (livro do ano, composição).
 * Tudo vem das vistas da base de dados.
 */
import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import {
  ArrowRight, BarChart3, BellRing, BookOpen, CalendarDays, CircleCheck, ClipboardCheck, HandCoins,
  LayoutDashboard, Mic, Plus, Sprout, Users, Wallet,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Cartao, Dinheiro, Indicador, Pilula, TituloPagina } from '@/components/comum/elementos'
import { GraficoBarras } from '@/components/comum/graficos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { api, dados } from '@/api/cliente'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { centimos, data, dataPorExtenso, deCentimos, diasAte, dinheiro, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useContagemPorAprovar, useMembrosBasicos } from '@/features/membros/api'
import { emVigor, usePlanos } from '@/features/escalas/api'
import { useResumoMensal } from '@/features/tesouraria/api'
import { useAlertas, type Alerta } from '@/features/alertas/loja'
import { TomAlerta } from '@/features/alertas/Sino'

/* Linhas das vistas (nomes de campo como a API os devolve). */
interface LinhaEscala { id: number; data: string; funcao: keyof typeof rotulos.funcaoEscala; membro: string; estado: string }
interface LinhaMensal { ano: number; mes: number; baptismos: number; rebaptismos: number; profissoesDeFe: number; transferenciasEntrada: number; transferenciasSaida: number; falecimentos: number; remocoes: number; desaparecidos: number }
interface LinhaSaldo { id: number; nome: string; tipo: string; moeda: string; saldo: string; entidadeId: number | null }

/** Lê uma vista de relatório da igreja escolhida (só se o utilizador a puder ler). */
function useRelatorio<T>(caminho: string, permissao: string) {
  const igreja = useIgreja()
  const { pode } = useSessao()
  return useQuery({
    queryKey: ['inicio', igreja.id, caminho],
    enabled: pode(permissao),
    queryFn: async () =>
      (await dados(api.GET(caminho as '/v1/secretaria/membros-basico', { params: { query: { igrejaId: igreja.id } } }))) as unknown as T[],
  })
}

/** O sábado desta semana (hoje, se hoje for sábado). */
function proximoSabado(): string {
  const hoje = new Date(`${hojeIso()}T12:00:00+02:00`)
  hoje.setUTCDate(hoje.getUTCDate() + ((6 - hoje.getUTCDay() + 7) % 7))
  return hoje.toISOString().slice(0, 10)
}
const quandoFalta = (d: number) => (d === 0 ? 'hoje' : d === 1 ? 'amanhã' : `daqui a ${d} dias`)
const ORDEM_FUNCOES = ['PREGADOR', 'TRADUTOR', 'ANCIAO_DO_DIA', 'ACOMPANHANTE_VISITAS', 'ACOMPANHANTE_OFERTAS', 'ACOMPANHANTE_BOAS_VINDAS', 'DIRECTOR_ES', 'PROFESSOR_ES', 'DIACONO', 'DIACONISA', 'RECEPCAO', 'MUSICA', 'SONOPLASTIA', 'LIMPEZA', 'OUTRA']
const MESES_CURTOS = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']
const mt = (v: number) => dinheiro(deCentimos(Math.round(v * 100)))

function useEscalaDoSabado() {
  const q = useRelatorio<LinhaEscala>('/v1/actividades/escalas-proximas', 'actividades.escala.ler')
  const sabado = proximoSabado()
  const doDia = (q.data ?? []).filter((l) => l.data === sabado).sort((a, b) => ORDEM_FUNCOES.indexOf(a.funcao) - ORDEM_FUNCOES.indexOf(b.funcao))
  const seguinte = (q.data ?? []).map((l) => l.data).filter((d) => d > sabado).sort()[0]
  return { q, sabado, doDia, seguinte }
}

/* ===================================================================== 1. o que precisa de atenção */
/**
 * Os alertas do sino (features/alertas) agrupados por assunto: uma linha por tipo ("Saídas por aprovar · 2"),
 * a mais grave primeiro. Com um só assunto, leva directamente a ele; com vários, à lista onde se resolvem.
 * O detalhe de cada um fica no sino.
 */
const GRUPOS: Record<string, { rotulo: string; lista: string }> = {
  membro: { rotulo: 'Registos de membros por aprovar', lista: '/membros?validacao=PENDENTE' },
  menor: { rotulo: 'Menores com a ficha incompleta', lista: '/secretaria/relatorio' },
  carta: { rotulo: 'Cartas de transferência por emitir', lista: '/transferencias?aba=saidas' },
  aceitar: { rotulo: 'Transferências por aceitar', lista: '/transferencias?aba=entradas' },
  mandatos: { rotulo: 'Mandatos a terminar', lista: '/conselho' },
  acta: { rotulo: 'Actas por aprovar', lista: '/reunioes' },
  realizada: { rotulo: 'Reuniões por concluir', lista: '/reunioes' },
  reunioes: { rotulo: 'Reuniões por concluir', lista: '/reunioes' },
  aprovar: { rotulo: 'Saídas por aprovar', lista: '/tesouraria/movimentos?ver=pendentes' },
  confirmar: { rotulo: 'Movimentos por confirmar', lista: '/tesouraria/movimentos?ver=pendentes' },
  movimentos: { rotulo: 'Movimentos por confirmar', lista: '/tesouraria/movimentos?ver=pendentes' },
  despesa: { rotulo: 'Despesas por decidir', lista: '/tesouraria/despesas' },
  despesas: { rotulo: 'Despesas por tratar', lista: '/tesouraria/despesas' },
  pagar: { rotulo: 'Despesas aprovadas por pagar', lista: '/tesouraria/despesas' },
  contagem: { rotulo: 'Contagens por conferir', lista: '/tesouraria/contagens' },
  deposito: { rotulo: 'Depósito à Missão em falta', lista: '/tesouraria/remessas' },
  remessa: { rotulo: 'Depósitos por confirmar', lista: '/tesouraria/remessas' },
  orcamento: { rotulo: 'Orçamento por aprovar', lista: '/tesouraria/orcamento' },
  fecho: { rotulo: 'Mês por fechar', lista: '/tesouraria/fechos' },
  'es-lancar': { rotulo: 'Ofertas da Escola Sabatina por lançar', lista: '/escola-sabatina' },
  'es-diferente': { rotulo: 'Ofertas da ES diferentes do lançado', lista: '/escola-sabatina' },
  'es-fechar': { rotulo: 'Relatórios do sábado por fechar', lista: '/escola-sabatina' },
  'es-ofertas': { rotulo: 'Relatórios do sábado por tratar', lista: '/escola-sabatina' },
  'es-falta': { rotulo: 'Relatórios do sábado em falta', lista: '/escola-sabatina/sabado' },
  'es-enviar': { rotulo: 'Relatórios guardados no telemóvel', lista: '/escola-sabatina/sabado' },
  escala: { rotulo: 'Escalas por publicar', lista: '/escalas' },
}
const PESO_TOM: Record<string, number> = { destructive: 0, warning: 1, info: 2 }

interface Grupo { chave: string; rotulo: string; modulo: string; n: number; para: string; primeiro: Alerta; tom: Alerta['tom'] }

function agrupar(alertas: Alerta[]): Grupo[] {
  const m = new Map<string, { itens: Alerta[]; extra: number }>()
  for (const a of alertas) {
    const pfx = a.chave.split(':')[0]
    const g = m.get(GRUPOS[pfx]?.rotulo ?? pfx) ?? { itens: [], extra: 0 }
    // "E mais N…" conta como N assuntos
    const resto = a.chave.endsWith(':resto') ? Number(/(\d+)/.exec(a.titulo)?.[1] ?? 1) : 0
    if (resto) g.extra += resto; else g.itens.push(a)
    m.set(GRUPOS[pfx]?.rotulo ?? pfx, g)
  }
  return [...m.entries()].map(([rotulo, g]) => {
    const primeiro = g.itens[0] ?? alertas.find((a) => (GRUPOS[a.chave.split(':')[0]]?.rotulo ?? '') === rotulo)!
    const n = g.itens.length + g.extra
    const pfx = primeiro.chave.split(':')[0]
    const tom = [...g.itens].sort((a, b) => PESO_TOM[a.tom] - PESO_TOM[b.tom])[0]?.tom ?? primeiro.tom
    return { chave: rotulo, rotulo, modulo: primeiro.modulo, n, primeiro, tom, para: n === 1 ? primeiro.para : GRUPOS[pfx]?.lista ?? primeiro.para }
  }).sort((a, b) => PESO_TOM[a.tom] - PESO_TOM[b.tom] || b.n - a.n)
}

function ListaAtencao() {
  const { alertas, aCarregar } = useAlertas()
  const grupos = agrupar(alertas)
  // os 7 mais urgentes; o resto com "Mostrar mais" (o cartão fica à altura do próximo sábado)
  const [todos, setTodos] = useState(false)
  const visiveis = todos ? grupos : grupos.slice(0, 7)
  return (
    <Cartao titulo="Precisa de atenção" icone={ClipboardCheck} semMargem className="h-full lg:col-span-7"
      descricao={aCarregar && !alertas.length ? 'A verificar…' : alertas.length ? `${alertas.length} assunto(s) em ${grupos.length} tipo(s) · o detalhe está no sino` : 'Nada à espera'}>
      {aCarregar && !alertas.length ? (
        <div className="grid gap-3 px-5 pb-5 sm:px-6" aria-busy="true" aria-label="A carregar">{[0, 1, 2].map((i) => <Barra key={i} className="h-12 w-full" />)}</div>
      ) : !alertas.length ? (
        <EstadoVazio icone={CircleCheck} titulo="Tudo em dia">Não há registos por aprovar, movimentos por confirmar, despesas por decidir nem relatórios por fechar.</EstadoVazio>
      ) : (
        <>
        <ul className="divide-y border-t">
          {visiveis.map((g) => (
            <li key={g.chave}>
              <Link to={g.para} className="alvo group flex items-center gap-3 px-5 py-2.5 hover:bg-muted/50 sm:px-6">
                <TomAlerta alerta={{ ...g.primeiro, tom: g.tom }} />
                <span className="min-w-0 flex-1">
                  <span className="block text-sm font-medium">{g.rotulo}</span>
                  <span className="block truncate text-xs text-muted-foreground">
                    {g.modulo} · {g.n === 1 ? g.primeiro.titulo : `${g.primeiro.titulo} e mais ${g.n - 1}`}
                  </span>
                </span>
                <Pilula variante={g.tom === 'destructive' ? 'destructive' : g.tom === 'warning' ? 'warning' : 'info'} className="min-w-7 justify-center tabular-nums">{g.n}</Pilula>
                <ArrowRight aria-hidden className="size-4 flex-none text-muted-foreground transition-transform group-hover:translate-x-0.5" />
              </Link>
            </li>
          ))}
        </ul>
        {grupos.length > 7 && (
          <button type="button" onClick={() => setTodos((x) => !x)}
            className="alvo mt-auto w-full border-t px-5 py-2.5 text-left text-sm font-medium text-primary hover:bg-muted/50 sm:px-6">
            {todos ? 'Mostrar menos' : `Mostrar mais ${grupos.length - 7} tipo(s)`}
          </button>
        )}
        </>
      )}
    </Cartao>
  )
}

/* ===================================================================== 2. o próximo sábado */
function ProximoSabado() {
  const { q, sabado, doDia, seguinte } = useEscalaDoSabado()
  const { pode } = useSessao()
  const planos = usePlanos()
  const vigor = (planos.data ?? []).find(emVigor)
  const pregador = doDia.find((l) => l.funcao === 'PREGADOR')
  const outros = doDia.filter((l) => l !== pregador)
  const quando = dataPorExtenso(sabado)
  return (
    <Cartao
      titulo={t.inicio.proximoSabado}
      descricao={`${quando.charAt(0).toUpperCase()}${quando.slice(1)} · ${quandoFalta(diasAte(sabado))}`}
      icone={CalendarDays}
      className="flex h-full flex-col lg:col-span-5"
      semMargem
      accoes={pode('actividades.escala_plano.ler') && (
        <Button asChild variant="ghost" size="sm"><Link to={vigor ? `/escalas/${vigor.id}` : '/escalas'}>{t.inicio.verEscala}</Link></Button>
      )}
    >
      <div className="flex-1">
        {q.isPending && q.fetchStatus !== 'idle' ? (
          <div className="grid gap-3 px-5 pb-5 sm:px-6" aria-busy="true" aria-label="A carregar">{[0, 1, 2, 3].map((i) => <Barra key={i} className="h-5 w-full" />)}</div>
        ) : q.isError ? (
          <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="mx-6 mb-6" />
        ) : doDia.length === 0 ? (
          <EstadoVazio icone={CalendarDays} titulo={t.inicio.semEscala}>
            {seguinte ? `A próxima escala com nomes é a de ${data(seguinte)}.` : 'Elabore a escala do trimestre para que apareça aqui.'}
          </EstadoVazio>
        ) : (
          <>
            {pregador && (
              <div className="mx-5 mb-3 flex items-center gap-3 rounded-lg bg-accent px-4 py-3 sm:mx-6">
                <span className="flex size-9 flex-none items-center justify-center rounded-lg bg-primary text-primary-foreground" aria-hidden><Mic className="size-[18px]" /></span>
                <div className="min-w-0">
                  <p className="text-xs font-medium text-accent-foreground/80">Prega neste sábado</p>
                  <p className="truncate text-base font-semibold text-accent-foreground">{pregador.membro}</p>
                </div>
              </div>
            )}
            <dl className="divide-y border-t">
              {outros.map((l) => (
                <div key={l.id} className="flex items-center justify-between gap-3 px-5 py-2.5 text-sm sm:px-6">
                  <dt className="text-muted-foreground">{rotulos.funcaoEscala[l.funcao] ?? l.funcao}</dt>
                  <dd className="truncate text-right font-medium">
                    {l.membro}
                    {l.estado === 'SUBSTITUIDA' && <Pilula variante="secondary" className="ml-2">substituto</Pilula>}
                  </dd>
                </div>
              ))}
            </dl>
          </>
        )}
      </div>
      <p className="flex items-start gap-2 border-t px-5 py-3 text-xs text-muted-foreground sm:px-6">
        <BellRing aria-hidden className="mt-px size-3.5 shrink-0" /> {t.inicio.lembretes}
      </p>
    </Cartao>
  )
}

/* ===================================================================== 3. tesouraria */
function useFinancas() {
  const resumo = useResumoMensal(6)
  const saldos = useRelatorio<LinhaSaldo>('/v1/tesouraria/saldos-contas', 'tesouraria.conta_financeira.ler')
  const contas = (saldos.data ?? []).filter((c) => c.entidadeId == null).sort((a, b) => centimos(b.saldo) - centimos(a.saldo))
  const total = contas.reduce((s, c) => s + centimos(c.saldo), 0)
  const n = resumo.entradas.length
  return { resumo, saldos, contas, total, entradasMes: resumo.entradas[n - 1] ?? 0, entradasAntes: resumo.entradas[n - 2] ?? 0, saidasMes: resumo.saidas[n - 1] ?? 0 }
}

function Financas() {
  const { resumo, saldos, contas, total, entradasMes, saidasMes } = useFinancas()
  const maior = Math.max(1, ...contas.map((c) => Math.max(0, centimos(c.saldo))))
  return (
    <>
      <Cartao titulo="Entradas e saídas" descricao="Últimos 6 meses, confirmadas nas contas da igreja" icone={BarChart3} className="h-full lg:col-span-8"
        accoes={<Button asChild variant="ghost" size="sm"><Link to="/tesouraria">Tesouraria</Link></Button>}>
        {resumo.aCarregar ? <Barra className="h-56 w-full" />
          : resumo.erro ? <EstadoErro erro={resumo.erro} />
          : <GraficoBarras rotulo="Entradas e saídas confirmadas por mês" altura={220} categorias={resumo.categorias} destaque={resumo.categorias.length - 1}
              series={[{ nome: 'Entradas', slot: 1, valores: resumo.entradas }, { nome: 'Saídas', slot: 2, valores: resumo.saidas }]} formatar={mt} />}
      </Cartao>
      <Cartao titulo="Onde está o dinheiro" descricao={<>Total da igreja: <strong className="text-foreground"><Dinheiro valor={deCentimos(total)} /></strong></>} icone={Wallet} className="flex h-full flex-col lg:col-span-4"
        accoes={<Button asChild variant="ghost" size="sm"><Link to="/tesouraria/contas">Contas</Link></Button>}>
        <div className="flex flex-1 flex-col">
        {saldos.isPending ? <Barra className="h-40 w-full" />
          : saldos.isError ? <EstadoErro erro={saldos.error} aoTentar={() => saldos.refetch()} />
          : !contas.length ? <EstadoVazio icone={Wallet}>Ainda não há contas registadas.</EstadoVazio>
          : (
            <ul className="grid gap-4">
              {contas.map((c) => (
                <li key={c.id}>
                  <div className="flex items-baseline justify-between gap-3 text-sm">
                    <span className="truncate">{c.nome}</span>
                    <span className={cn('num font-medium', centimos(c.saldo) < 0 && 'text-destructive-text')}><Dinheiro valor={c.saldo} /></span>
                  </div>
                  <div className="mt-1.5 h-1.5 overflow-hidden rounded-full bg-muted" aria-hidden>
                    <div className="h-full rounded-full bg-[var(--serie-1)]" style={{ width: `${(Math.max(0, centimos(c.saldo)) / maior) * 100}%` }} />
                  </div>
                </li>
              ))}
            </ul>
          )}
        {!resumo.aCarregar && (
          <dl className="mt-auto grid grid-cols-3 gap-2 border-t pt-4 text-xs">
            <div><dt className="text-muted-foreground">Entradas do mês</dt><dd className="num mt-0.5 text-sm font-semibold text-success-text">{mt(entradasMes)}</dd></div>
            <div><dt className="text-muted-foreground">Saídas do mês</dt><dd className="num mt-0.5 text-sm font-semibold">{mt(saidasMes)}</dd></div>
            <div><dt className="text-muted-foreground">Resultado</dt><dd className={cn('num mt-0.5 text-sm font-semibold', entradasMes - saidasMes < 0 && 'text-destructive-text')}>{mt(entradasMes - saidasMes)}</dd></div>
          </dl>
        )}
        </div>
      </Cartao>
    </>
  )
}

/* ===================================================================== 4. membros */
function LivroDoAno({ className }: { className?: string }) {
  const q = useRelatorio<LinhaMensal>('/v1/secretaria/relatorio-mensal', 'secretaria.movimento_membro.ler')
  if (q.fetchStatus === 'idle' && !q.data) return null
  const ano = Number(hojeIso().slice(0, 4))
  const mesActual = Number(hojeIso().slice(5, 7))
  const linhas = (q.data ?? []).filter((l) => l.ano === ano)
  const doMes = (m: number) => linhas.find((l) => l.mes === m)
  const n = (l: LinhaMensal | undefined, ks: (keyof LinhaMensal)[]) => (l ? ks.reduce((s, k) => s + Number(l[k] ?? 0), 0) : 0)
  const meses = Array.from({ length: mesActual }, (_, i) => i + 1)
  const entradas = meses.map((m) => n(doMes(m), ['baptismos', 'rebaptismos', 'profissoesDeFe', 'transferenciasEntrada']))
  const saidas = meses.map((m) => n(doMes(m), ['transferenciasSaida', 'falecimentos', 'remocoes', 'desaparecidos']))
  const somaE = entradas.reduce((a, b) => a + b, 0), somaS = saidas.reduce((a, b) => a + b, 0)
  return (
    <Cartao titulo={`Livro de membros em ${ano}`} descricao={`${somaE} entrada(s) e ${somaS} saída(s), com o voto da igreja`} icone={BookOpen} className={cn('h-full', className)}
      accoes={<Button asChild variant="ghost" size="sm"><Link to="/livro">{t.comum.verTodos}</Link></Button>}>
      {q.isPending ? <Barra className="h-48 w-full" />
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
        : <GraficoBarras rotulo={`Entradas e saídas do livro de membros em ${ano}`} altura={200} categorias={meses.map((m) => MESES_CURTOS[m - 1])} destaque={mesActual - 1}
            series={[{ nome: 'Entradas', slot: 1, valores: entradas }, { nome: 'Saídas', slot: 2, valores: saidas }]} formatar={(v) => String(v)} inteiros />}
    </Cartao>
  )
}

/** Composição do livro: barra empilhada por estado e por sexo (números exactos ao lado). */
function Composicao({ className }: { className?: string }) {
  const q = useMembrosBasicos()
  const l = q.data ?? []
  const conta = (f: (m: (typeof l)[number]) => boolean) => l.filter(f).length
  const activos = conta((m) => m.estado === 'ACTIVO'), interessados = conta((m) => m.estado === 'INTERESSADO')
  const outros = l.length - activos - interessados
  const mulheres = conta((m) => m.estado === 'ACTIVO' && m.sexo === 'F'), homens = conta((m) => m.estado === 'ACTIVO' && m.sexo === 'M')
  const pct = (v: number, de: number) => (de ? `${Math.round((v / de) * 100)}%` : '0%')
  const Linha = ({ cor, rotulo, v, de }: { cor: string; rotulo: string; v: number; de: number }) => (
    <li className="flex items-center justify-between gap-3 text-sm">
      <span className="flex items-center gap-2"><span className="size-2.5 rounded-[3px]" style={{ background: cor }} aria-hidden />{rotulo}</span>
      <span className="tabular-nums"><strong className="font-semibold">{v}</strong> <span className="text-xs text-muted-foreground">{pct(v, de)}</span></span>
    </li>
  )
  return (
    <Cartao titulo="Membros" descricao={`${l.length} no livro desta igreja`} icone={Users} className={cn('h-full', className)}
      accoes={<Button asChild variant="ghost" size="sm"><Link to="/membros">{t.comum.verTodos}</Link></Button>}>
      {q.isPending ? <Barra className="h-40 w-full" />
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
        : (
          <div className="grid gap-5">
            <div>
              <div className="flex h-2.5 overflow-hidden rounded-full bg-muted" role="img" aria-label={`${activos} activos, ${interessados} interessados, ${outros} outros`}>
                <div style={{ width: pct(activos, l.length), background: 'var(--serie-1)' }} />
                <div style={{ width: pct(interessados, l.length), background: 'var(--serie-3)' }} />
              </div>
              <ul className="mt-3 grid gap-2">
                <Linha cor="var(--serie-1)" rotulo="Activos" v={activos} de={l.length} />
                <Linha cor="var(--serie-3)" rotulo="Interessados" v={interessados} de={l.length} />
                <Linha cor="var(--muted-foreground)" rotulo="Outros (saídas)" v={outros} de={l.length} />
              </ul>
            </div>
            <div className="border-t pt-4">
              <p className="mb-2 text-xs font-semibold tracking-wider text-muted-foreground uppercase">Activos por sexo</p>
              <div className="flex h-2.5 overflow-hidden rounded-full bg-muted" role="img" aria-label={`${mulheres} mulheres e ${homens} homens`}>
                <div style={{ width: pct(mulheres, activos), background: 'var(--serie-4, var(--serie-2))' }} />
                <div style={{ width: pct(homens, activos), background: 'var(--serie-5, var(--serie-1))' }} />
              </div>
              <ul className="mt-3 grid gap-2">
                <Linha cor="var(--serie-4, var(--serie-2))" rotulo="Mulheres" v={mulheres} de={activos} />
                <Linha cor="var(--serie-5, var(--serie-1))" rotulo="Homens" v={homens} de={activos} />
              </ul>
            </div>
          </div>
        )}
    </Cartao>
  )
}

/* ===================================================================== página */
function Indicadores({ comTesouraria }: { comTesouraria: boolean }) {
  const { pode } = useSessao()
  const basicos = useMembrosBasicos()
  const porAprovar = useContagemPorAprovar()
  const { doDia, q: escala } = useEscalaDoSabado()
  const n = (e: string) => (basicos.data ?? []).filter((m) => m.estado === e).length
  const podeMembros = pode('secretaria.membro.ler')
  return (
    <div className="grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-4">
      {podeMembros && <Indicador rotulo="Membros activos" valor={n('ACTIVO')} nota={`${n('INTERESSADO')} interessado(s) a preparar`} icone={Users} para="/membros?estado=ACTIVO" aCarregar={basicos.isPending} />}
      {comTesouraria ? <IndicadoresTesouraria /> : (
        <>
          {podeMembros && <Indicador rotulo="Interessados" valor={n('INTERESSADO')} nota="a preparar para o baptismo" icone={Sprout} tom="info" para="/membros?estado=INTERESSADO" aCarregar={basicos.isPending} />}
          {podeMembros && <Indicador rotulo="Por aprovar" valor={porAprovar ?? 0} nota="registos à espera do secretário" icone={ClipboardCheck} tom="warning" para="/membros?validacao=PENDENTE" aCarregar={basicos.isPending} />}
        </>
      )}
      <Indicador rotulo="Escalados no sábado" valor={doDia.length} nota="pessoas com uma função" icone={CalendarDays} tom="success" aCarregar={escala.isPending && escala.fetchStatus !== 'idle'} />
    </div>
  )
}

function IndicadoresTesouraria() {
  const { resumo, saldos, total, entradasMes, entradasAntes, saidasMes } = useFinancas()
  const variacao = entradasAntes ? Math.round(((entradasMes - entradasAntes) / entradasAntes) * 100) : null
  return (
    <>
      <Indicador rotulo="Saldo da igreja" valor={<Dinheiro valor={deCentimos(total)} />} nota="em todas as contas da igreja" icone={Wallet} tom="info" para="/tesouraria" aCarregar={saldos.isPending} />
      <Indicador rotulo="Entradas do mês" valor={mt(entradasMes)} icone={HandCoins} tom="success" para="/tesouraria/movimentos?ver=entradas" aCarregar={resumo.aCarregar}
        nota={variacao == null ? <>saídas: {mt(saidasMes)}</> : <>{variacao >= 0 ? '+' : ''}{variacao}% face ao mês passado · saídas {mt(saidasMes)}</>} />
    </>
  )
}

export default function PaginaInicio() {
  const igreja = useIgreja()
  const { pode, usuario } = useSessao()
  const comTesouraria = pode('tesouraria.transacao.ler') && pode('tesouraria.conta_financeira.ler')
  const podeMembros = pode('secretaria.membro.ler')
  const comLivro = pode('secretaria.movimento_membro.ler')
  const nome = usuario?.nome?.split(' ')[0]

  return (
    <>
      <TituloPagina
        icone={LayoutDashboard}
        titulo={igreja.nome}
        descricao={`${nome ? `Olá, ${nome}. ` : ''}Semana até ${dataPorExtenso(proximoSabado())}.`}
        accoes={<>
          {comTesouraria && pode('tesouraria.transacao.criar') && (
            <Button asChild variant="outline" className="alvo"><Link to="/tesouraria/entrada"><HandCoins className="size-4" />Lançar entrada</Link></Button>
          )}
          {pode('secretaria.membro.criar') && (
            <Button asChild className="alvo"><Link to="/membros/novo"><Plus className="size-4" />{t.membros.registar}</Link></Button>
          )}
        </>}
      />
      <div className="grid gap-6">
        <Indicadores comTesouraria={comTesouraria} />

        <div className="grid items-stretch gap-6 lg:grid-cols-12">
          <ListaAtencao />
          <ProximoSabado />
        </div>

        {comTesouraria && (
          <section aria-label="Tesouraria" className="grid gap-3">
            <h2 className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Tesouraria</h2>
            <div className="grid items-stretch gap-6 lg:grid-cols-12"><Financas /></div>
          </section>
        )}

        {(podeMembros || comLivro) && (
          <section aria-label="Membros" className="grid gap-3">
            <h2 className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Membros</h2>
            <div className="grid items-stretch gap-6 lg:grid-cols-12">
              {comLivro && <LivroDoAno className={podeMembros ? 'lg:col-span-8' : 'lg:col-span-12'} />}
              {podeMembros && <Composicao className={comLivro ? 'lg:col-span-4' : 'lg:col-span-12'} />}
            </div>
          </section>
        )}
      </div>
    </>
  )
}
