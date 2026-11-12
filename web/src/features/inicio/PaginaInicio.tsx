/**
 * Início · "Como está a igreja e o que precisa de mim esta semana?"
 * Painel de direcção em três faixas, cada bloco só para quem o pode ler:
 *  1. indicadores-chave (membros, dinheiro do mês, o que está por resolver);
 *  2. "Precisa de atenção" (tudo o que espera uma acção, da secretaria e da tesouraria, num só sítio) e o próximo
 *     sábado (a escala do dia);
 *  3. tesouraria (entradas e saídas, onde está o dinheiro) e membros (livro do ano, composição).
 * Tudo vem das vistas da base de dados.
 */
import { type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import {
  ArrowRight, BarChart3, BellRing, BookOpen, Calculator, CalendarDays, CircleCheck, ClipboardCheck, ClipboardList, HandCoins,
  Landmark, LayoutDashboard, Mail, Mic, Plus, ReceiptText, ShieldAlert, Sprout, UserCheck, Users, Wallet,
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
import { useContagens, useDespesas, useMovimentos, useRemessasDevidas, useResumoMensal } from '@/features/tesouraria/api'
import { Paginada } from '@/components/comum/Paginacao'

/* Linhas das vistas (nomes de campo como a API os devolve). */
interface LinhaEscala { id: number; data: string; funcao: keyof typeof rotulos.funcaoEscala; membro: string; estado: string }
interface LinhaMensal { ano: number; mes: number; baptismos: number; rebaptismos: number; profissoesDeFe: number; transferenciasEntrada: number; transferenciasSaida: number; falecimentos: number; remocoes: number; desaparecidos: number }
interface LinhaMenor { id: number; nome: string; apelido: string; faltaEncarregado: boolean; faltaConsentimento: boolean }
interface LinhaCarta { id: number; membro: string; validaAte: string; expirada: boolean }
interface LinhaMandato { id: number; cargo: string; membro: string; fimPrevisto: string }
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
const mesAnterior = () => { const [a, m] = hojeIso().split('-').map(Number); return m === 1 ? { ano: a - 1, mes: 12 } : { ano: a, mes: m - 1 } }

function useEscalaDoSabado() {
  const q = useRelatorio<LinhaEscala>('/v1/actividades/escalas-proximas', 'actividades.escala.ler')
  const sabado = proximoSabado()
  const doDia = (q.data ?? []).filter((l) => l.data === sabado).sort((a, b) => ORDEM_FUNCOES.indexOf(a.funcao) - ORDEM_FUNCOES.indexOf(b.funcao))
  const seguinte = (q.data ?? []).map((l) => l.data).filter((d) => d > sabado).sort()[0]
  return { q, sabado, doDia, seguinte }
}

/* ===================================================================== 1. o que precisa de atenção */
interface Item { chave: string; icone: typeof Users; titulo: string; detalhe: ReactNode; n: number; para: string; tom: 'warning' | 'destructive' | 'info' }

/** Pendentes da secretaria (só quem a lê). */
function useAtencaoSecretaria(): { itens: Item[]; aCarregar: boolean } {
  const igreja = useIgreja()
  const { pode } = useSessao()
  const porAprovar = useQuery({
    queryKey: ['inicio', igreja.id, 'por-aprovar'],
    enabled: pode('secretaria.membro.ler'),
    queryFn: () => dados(api.GET('/v1/secretaria/membros', { params: { query: { igrejaId: igreja.id, validacao: 'PENDENTE', limite: 50 } } })),
  })
  const menores = useRelatorio<LinhaMenor>('/v1/secretaria/menores-pendentes', 'secretaria.membro.ler')
  const cartas = useRelatorio<LinhaCarta>('/v1/secretaria/cartas-pendentes', 'secretaria.transferencia_membro.ler')
  const mandatos = useRelatorio<LinhaMandato>('/v1/secretaria/mandatos-a-terminar', 'secretaria.oficial.ler')
  const aprovar = porAprovar.data?.dados ?? []
  const itens: Item[] = []
  if (aprovar.length) itens.push({ chave: 'aprovar', icone: UserCheck, titulo: 'Registos de membros por aprovar', n: aprovar.length, para: '/membros?validacao=PENDENTE', tom: 'warning',
    detalhe: aprovar.slice(0, 3).map((m) => `${m.nome} ${m.apelido}`).join(', ') + (aprovar.length > 3 ? '…' : '') })
  if (menores.data?.length) itens.push({ chave: 'menores', icone: ShieldAlert, titulo: 'Menores sem encarregado ou consentimento', n: menores.data.length, para: '/membros', tom: 'warning',
    detalhe: menores.data.slice(0, 3).map((m) => `${m.nome} ${m.apelido}`).join(', ') })
  if (cartas.data?.length) {
    const expiradas = cartas.data.filter((c) => c.expirada).length
    itens.push({ chave: 'cartas', icone: Mail, titulo: 'Cartas de transferência pendentes', n: cartas.data.length, para: '/membros', tom: expiradas ? 'destructive' : 'info',
      detalhe: expiradas ? `${expiradas} já expirada(s)` : cartas.data.slice(0, 2).map((c) => c.membro).join(', ') })
  }
  if (mandatos.data?.length) itens.push({ chave: 'mandatos', icone: CalendarDays, titulo: 'Mandatos a terminar nos próximos 60 dias', n: mandatos.data.length, para: '/conselho', tom: 'info',
    detalhe: `O primeiro termina a ${data([...mandatos.data].sort((a, b) => a.fimPrevisto.localeCompare(b.fimPrevisto))[0].fimPrevisto)}` })
  const aCarregar = [porAprovar, menores, cartas, mandatos].some((x) => x.isPending && x.fetchStatus !== 'idle')
  return { itens, aCarregar }
}

/** Pendentes da tesouraria: só se monta para quem lê a tesouraria (os pedidos não correm para os outros). */
function AtencaoTesouraria({ aoTer }: { aoTer: (itens: Item[], aCarregar: boolean) => ReactNode }) {
  const { pode } = useSessao()
  const desde = (() => { const d = new Date(); return new Date(Date.UTC(d.getFullYear(), d.getMonth() - 5, 1)).toISOString().slice(0, 10) })()
  const movs = useMovimentos({ desde, ate: new Date().toISOString().slice(0, 10) })
  const despesas = useDespesas()
  const contagens = useContagens()
  const devidas = useRemessasDevidas()
  const itens: Item[] = []
  const pendentes = (movs.data ?? []).filter((x) => !x.endDate && x.estado === 'PENDENTE')
  const saidasPorAprovar = pendentes.filter((x) => x.tipo === 'SAIDA' && !x.aprovadoPorUsuarioId)
  if (pendentes.length) itens.push({ chave: 'movs', icone: ReceiptText, titulo: 'Movimentos por confirmar', n: pendentes.length, para: '/tesouraria/movimentos', tom: 'warning',
    detalhe: saidasPorAprovar.length ? `${saidasPorAprovar.length} saída(s) à espera de aprovação` : 'Confirme-os para entrarem nos saldos' })
  const porDecidir = (despesas.data ?? []).filter((d) => !d.endDate && d.estado === 'SUBMETIDA')
  if (porDecidir.length && pode('tesouraria.despesa.aprovar')) itens.push({ chave: 'despesas', icone: ClipboardList, titulo: 'Despesas por decidir', n: porDecidir.length, para: '/tesouraria/despesas', tom: 'warning',
    detalhe: <>Total pedido: <Dinheiro valor={deCentimos(porDecidir.reduce((s, d) => s + centimos(d.valorSolicitado), 0))} /></> })
  const porPagar = (despesas.data ?? []).filter((d) => !d.endDate && d.estado === 'APROVADA')
  if (porPagar.length && pode('tesouraria.transacao.criar')) itens.push({ chave: 'pagar', icone: HandCoins, titulo: 'Despesas aprovadas por pagar', n: porPagar.length, para: '/tesouraria/despesas', tom: 'info',
    detalhe: <><Dinheiro valor={deCentimos(porPagar.reduce((s, d) => s + centimos(d.valorAprovado ?? d.valorSolicitado), 0))} /> a pagar</> })
  const abertas = (contagens.data ?? []).filter((c) => !c.endDate && c.estado === 'ABERTA')
  if (abertas.length) itens.push({ chave: 'contagens', icone: Calculator, titulo: 'Contagens por conferir', n: abertas.length, para: '/tesouraria/contagens', tom: 'warning',
    detalhe: `A mais antiga é de ${data([...abertas].sort((a, b) => a.data.localeCompare(b.data))[0].data)}` })
  const ant = mesAnterior()
  const emFalta = (devidas.data ?? []).filter((d) => (d.ano < ant.ano || (d.ano === ant.ano && d.mes <= ant.mes)) && centimos(d.emFalta) > 0)
  if (emFalta.length) itens.push({ chave: 'remessa', icone: Landmark, titulo: 'Depósito à Missão em falta', n: new Set(emFalta.map((d) => `${d.ano}-${d.mes}`)).size, para: '/tesouraria/remessas', tom: 'destructive',
    detalhe: <>Falta depositar <Dinheiro valor={deCentimos(emFalta.reduce((s, d) => s + centimos(d.emFalta), 0))} /> de meses anteriores</> })
  return <>{aoTer(itens, [movs, despesas, contagens, devidas].some((x) => x.isPending))}</>
}

function ListaAtencao({ itens, aCarregar }: { itens: Item[]; aCarregar: boolean }) {
  const total = itens.reduce((s, i) => s + i.n, 0)
  return (
    <Cartao titulo="Precisa de atenção" descricao={aCarregar ? 'A verificar…' : total ? `${total} assunto(s) à espera de uma acção` : 'Nada à espera'} icone={ClipboardCheck} semMargem className="h-full lg:col-span-7">
      {aCarregar && !itens.length ? (
        <div className="grid gap-3 px-5 pb-5 sm:px-6" aria-busy="true" aria-label="A carregar">{[0, 1, 2].map((i) => <Barra key={i} className="h-12 w-full" />)}</div>
      ) : !itens.length ? (
        <EstadoVazio icone={CircleCheck} titulo="Tudo em dia">Não há registos por aprovar, movimentos por confirmar nem despesas por decidir.</EstadoVazio>
      ) : (
        <Paginada itens={itens}>{(vis) => (
        <ul className="divide-y border-t">
          {vis.map((i) => (
            <li key={i.chave}>
              <Link to={i.para} className="alvo group flex items-center gap-3 px-5 py-3 hover:bg-muted/50 sm:px-6">
                <span className={cn('flex size-9 flex-none items-center justify-center rounded-lg',
                  i.tom === 'destructive' ? 'bg-tint-destructive text-destructive-text' : i.tom === 'warning' ? 'bg-tint-warning text-warning-text' : 'bg-tint-info text-info-text')}>
                  <i.icone className="size-[18px]" aria-hidden />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-sm font-medium">{i.titulo}</span>
                  <span className="block truncate text-xs text-muted-foreground">{i.detalhe}</span>
                </span>
                <Pilula variante={i.tom === 'destructive' ? 'destructive' : i.tom === 'warning' ? 'warning' : 'info'} className="tabular-nums">{i.n}</Pilula>
                <ArrowRight aria-hidden className="size-4 flex-none text-muted-foreground transition-transform group-hover:translate-x-0.5" />
              </Link>
            </li>
          ))}
        </ul>
        )}</Paginada>
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
  const secretaria = useAtencaoSecretaria()
  const podeMembros = pode('secretaria.membro.ler')
  const comLivro = pode('secretaria.movimento_membro.ler')
  const nome = usuario?.nome?.split(' ')[0]

  const atencao = (extra: Item[] = [], aCarregarExtra = false) => (
    <ListaAtencao itens={[...extra.filter((i) => i.tom === 'destructive'), ...secretaria.itens, ...extra.filter((i) => i.tom !== 'destructive')]}
      aCarregar={secretaria.aCarregar || aCarregarExtra} />
  )

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
          {comTesouraria ? <AtencaoTesouraria aoTer={(itens, aCarregar) => atencao(itens, aCarregar)} /> : atencao()}
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
