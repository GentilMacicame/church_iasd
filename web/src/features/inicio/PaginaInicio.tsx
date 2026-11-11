/**
 * Início · "O que precisa de mim esta semana?"
 * Indicadores do livro de membros; o próximo sábado (a escala do dia); os pendentes da secretaria; os
 * movimentos do ano e os saldos. Tudo vem das vistas da base de dados; cada bloco só aparece a quem o pode ler.
 */
import { Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import {
  ArrowRight, BarChart3, BellRing, BookOpen, CalendarDays, ClipboardCheck, ClipboardList, LayoutDashboard, Mic, Plus, Sprout, Users, Wallet,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Cartao, Dinheiro, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Donut, GraficoBarras, curto, type FatiaDonut, type Slot } from '@/components/comum/graficos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { api, dados } from '@/api/cliente'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { centimos, data, dataPorExtenso, deCentimos, diasAte, dinheiro, hojeIso } from '@/lib/formatos'
import { useContagemPorAprovar, useMembrosBasicos } from '@/features/membros/api'
import { emVigor, usePlanos } from '@/features/escalas/api'
import { useResumoMensal } from '@/features/tesouraria/api'

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

function useEscalaDoSabado() {
  const q = useRelatorio<LinhaEscala>('/v1/actividades/escalas-proximas', 'actividades.escala.ler')
  const sabado = proximoSabado()
  const doDia = (q.data ?? []).filter((l) => l.data === sabado).sort((a, b) => ORDEM_FUNCOES.indexOf(a.funcao) - ORDEM_FUNCOES.indexOf(b.funcao))
  const seguinte = (q.data ?? []).map((l) => l.data).filter((d) => d > sabado).sort()[0]
  return { q, sabado, doDia, seguinte }
}

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
      className="lg:col-span-7"
      semMargem
      accoes={pode('actividades.escala_plano.ler') && (
        <Button asChild variant="outline" size="sm"><Link to={vigor ? `/escalas/${vigor.id}` : '/escalas'}>{t.inicio.verEscala}</Link></Button>
      )}
    >
      {q.isPending ? (
        <div className="grid gap-3 px-6 pb-6" aria-busy="true" aria-label="A carregar">{[0, 1, 2, 3].map((i) => <Barra key={i} className="h-5 w-full" />)}</div>
      ) : q.isError ? (
        <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="mx-6 mb-6" />
      ) : doDia.length === 0 ? (
        <EstadoVazio icone={CalendarDays} titulo={t.inicio.semEscala}>
          {seguinte ? `A próxima escala com nomes é a de ${data(seguinte)}.` : 'Elabore a escala do trimestre para que apareça aqui.'}
        </EstadoVazio>
      ) : (
        <>
          {pregador && (
            <div className="mx-5 mb-4 flex items-center gap-3 rounded-lg bg-accent px-4 py-3 sm:mx-6">
              <span className="flex size-9 flex-none items-center justify-center rounded-lg bg-primary text-primary-foreground" aria-hidden><Mic className="size-[18px]" /></span>
              <div className="min-w-0">
                <p className="text-xs font-medium text-accent-foreground/80">Prega neste sábado</p>
                <p className="truncate text-base font-semibold text-accent-foreground">{pregador.membro}</p>
              </div>
            </div>
          )}
          <Tabela>
            <thead><tr><th className="sm:pl-6">Função</th><th className="sm:pr-6">Escalado</th></tr></thead>
            <tbody>
              {outros.map((l) => (
                <tr key={l.id}>
                  <td className="text-muted-foreground sm:pl-6">{rotulos.funcaoEscala[l.funcao] ?? l.funcao}</td>
                  <td className="font-medium sm:pr-6">
                    {l.membro}
                    {l.estado === 'SUBSTITUIDA' && <Pilula variante="secondary" className="ml-2">substituto</Pilula>}
                  </td>
                </tr>
              ))}
            </tbody>
          </Tabela>
        </>
      )}
      <p className="flex items-start gap-2 border-t px-5 py-3 text-xs text-muted-foreground sm:px-6">
        <BellRing aria-hidden className="mt-px size-3.5 shrink-0" /> {t.inicio.lembretes}
      </p>
    </Cartao>
  )
}

function Grupo({ titulo, n, para, children }: { titulo: string; n: number; para?: string; children: React.ReactNode }) {
  return (
    <div className="py-3 first:pt-0 last:pb-0">
      <div className="mb-1 flex items-center justify-between gap-3">
        <h3 className="flex items-center gap-2 text-sm font-medium">{titulo} <Pilula variante="secondary">{n}</Pilula></h3>
        {para && <Link to={para} className="flex-none text-xs font-medium text-primary hover:underline">{t.comum.verTodos}</Link>}
      </div>
      <ul className="text-sm">{children}</ul>
    </div>
  )
}

function Pendentes() {
  const igreja = useIgreja()
  const { pode } = useSessao()
  const porAprovar = useQuery({
    queryKey: ['inicio', igreja.id, 'por-aprovar'],
    enabled: pode('secretaria.membro.ler'),
    queryFn: () => dados(api.GET('/v1/secretaria/membros', { params: { query: { igrejaId: igreja.id, validacao: 'PENDENTE', limite: 5 } } })),
  })
  const menores = useRelatorio<LinhaMenor>('/v1/secretaria/menores-pendentes', 'secretaria.membro.ler')
  const cartas = useRelatorio<LinhaCarta>('/v1/secretaria/cartas-pendentes', 'secretaria.transferencia_membro.ler')
  const mandatos = useRelatorio<LinhaMandato>('/v1/secretaria/mandatos-a-terminar', 'secretaria.oficial.ler')
  const consultas = [porAprovar, menores, cartas, mandatos].filter((x) => x.fetchStatus !== 'idle' || x.isSuccess || x.isError)
  const aCarregar = consultas.some((x) => x.isPending && x.fetchStatus !== 'idle')
  const erro = consultas.find((x) => x.isError)
  const aprovar = porAprovar.data?.dados ?? []
  const vazio = !aCarregar && !aprovar.length && !menores.data?.length && !cartas.data?.length && !mandatos.data?.length

  return (
    <Cartao titulo={t.inicio.pendentes} descricao="O que espera uma acção da secretaria" icone={ClipboardList} className="lg:col-span-5">
      {aCarregar ? (
        <div className="grid gap-3" aria-busy="true" aria-label="A carregar">{[0, 1, 2].map((i) => <Barra key={i} className="h-4 w-full" />)}</div>
      ) : erro ? (
        <EstadoErro erro={erro.error} aoTentar={() => consultas.forEach((x) => x.refetch())} />
      ) : vazio ? (
        <EstadoVazio icone={ClipboardCheck} className="py-6">{t.inicio.semPendentes}</EstadoVazio>
      ) : (
        <div className="divide-y">
          {aprovar.length > 0 && (
            <Grupo titulo={t.inicio.porAprovar} n={aprovar.length} para="/membros?validacao=PENDENTE">
              {aprovar.map((m) => (
                <li key={m.id}>
                  <Link to={`/membros/${m.id}`} className="alvo -mx-2 flex min-h-9 items-center justify-between gap-3 rounded-md px-2 hover:bg-muted">
                    <span className="truncate">{m.nome} {m.apelido}</span>
                    <ArrowRight aria-hidden className="size-4 shrink-0 text-muted-foreground" />
                  </Link>
                </li>
              ))}
            </Grupo>
          )}
          {!!menores.data?.length && (
            <Grupo titulo={t.inicio.menores} n={menores.data.length}>
              {menores.data.slice(0, 4).map((m) => (
                <li key={m.id}>
                  <Link to={`/membros/${m.id}`} className="alvo -mx-2 flex min-h-9 items-center justify-between gap-3 rounded-md px-2 hover:bg-muted">
                    <span className="truncate">{m.nome} {m.apelido}</span>
                    <Pilula variante="warning">{m.faltaEncarregado ? 'sem encarregado' : 'sem consentimento'}</Pilula>
                  </Link>
                </li>
              ))}
            </Grupo>
          )}
          {!!cartas.data?.length && (
            <Grupo titulo={t.inicio.cartas} n={cartas.data.length}>
              {cartas.data.slice(0, 4).map((c) => (
                <li key={c.id} className="flex min-h-9 items-center justify-between gap-3">
                  <span className="truncate">{c.membro}</span>
                  <Pilula variante={c.expirada ? 'destructive' : 'secondary'}>{c.expirada ? 'expirou' : 'válida até'} {data(c.validaAte)}</Pilula>
                </li>
              ))}
            </Grupo>
          )}
          {!!mandatos.data?.length && (
            <Grupo titulo={t.inicio.mandatos} n={mandatos.data.length}>
              {mandatos.data.slice(0, 4).map((o) => (
                <li key={o.id} className="flex min-h-9 items-center justify-between gap-3">
                  <span className="truncate">{o.membro} <span className="text-muted-foreground">· {o.cargo}</span></span>
                  <span className="num text-xs text-muted-foreground">{data(o.fimPrevisto)}</span>
                </li>
              ))}
            </Grupo>
          )}
        </div>
      )}
    </Cartao>
  )
}

const MESES_CURTOS = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']

/** Entradas e saídas do livro de membros, mês a mês, neste ano (vista vw_relatorio_mensal_membros). */
function LivroDoAno() {
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
    <Cartao titulo={`Livro de membros em ${ano}`} descricao={`${somaE} entrada(s) e ${somaS} saída(s), com o voto da igreja`} icone={BookOpen} className="lg:col-span-7"
      accoes={<Button asChild variant="ghost" size="sm"><Link to="/livro">{t.comum.verTodos}</Link></Button>}>
      {q.isPending ? <Barra className="h-48 w-full" />
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
        : <GraficoBarras rotulo={`Entradas e saídas do livro de membros em ${ano}`} altura={200} categorias={meses.map((m) => MESES_CURTOS[m - 1])} destaque={mesActual - 1}
            series={[{ nome: 'Entradas', slot: 1, valores: entradas }, { nome: 'Saídas', slot: 2, valores: saidas }]} formatar={(v) => String(v)} inteiros />}
    </Cartao>
  )
}

/** Composição do livro: activos, interessados e o resto (transferidos, falecidos...), e a divisão por sexo. */
function Composicao() {
  const { pode } = useSessao()
  const q = useMembrosBasicos()
  if (!pode('secretaria.membro.ler')) return null
  const l = q.data ?? []
  const conta = (f: (m: (typeof l)[number]) => boolean) => l.filter(f).length
  const activos = conta((m) => m.estado === 'ACTIVO'), interessados = conta((m) => m.estado === 'INTERESSADO')
  const mulheres = conta((m) => m.estado === 'ACTIVO' && m.sexo === 'F'), homens = conta((m) => m.estado === 'ACTIVO' && m.sexo === 'M')
  return (
    <Cartao titulo="Membros" descricao="Quem está no livro desta igreja" icone={Users} className="lg:col-span-5"
      accoes={<Button asChild variant="ghost" size="sm"><Link to="/membros">{t.comum.verTodos}</Link></Button>}>
      {q.isPending ? <Barra className="h-40 w-full" />
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
        : (
          <>
            <Donut lado rotulo="Membros por estado" formatar={(v) => String(v)}
              fatias={[{ nome: 'Activos', valor: activos, slot: 1 }, { nome: 'Interessados', valor: interessados, slot: 3 }, { nome: 'Outros (saídas)', valor: l.length - activos - interessados, slot: 'neutra' }]} />
            <p className="mt-4 border-t pt-3 text-xs text-muted-foreground">Membros activos: {mulheres} mulheres e {homens} homens{activos - mulheres - homens ? ` (${activos - mulheres - homens} sem sexo indicado)` : ''}.</p>
          </>
        )}
    </Cartao>
  )
}

/** Finanças em resumo: entradas e saídas dos últimos 6 meses e onde está o dinheiro (sem a conta da Missão). */
function Financas() {
  const { pode } = useSessao()
  const resumo = useResumoMensal(6)
  const q = useRelatorio<LinhaSaldo>('/v1/tesouraria/saldos-contas', 'tesouraria.conta_financeira.ler')
  if (!pode('tesouraria.transacao.ler') || !pode('tesouraria.conta_financeira.ler')) return null
  const contas = (q.data ?? []).filter((c) => c.entidadeId == null).sort((a, b) => centimos(b.saldo) - centimos(a.saldo))
  const total = deCentimos(contas.reduce((s, c) => s + centimos(c.saldo), 0))
  const fatias: FatiaDonut[] = [
    ...contas.slice(0, 3).map((c, i) => ({ nome: c.nome, valor: Math.max(0, centimos(c.saldo)) / 100, slot: (i + 1) as Slot })),
    ...(contas.length > 3 ? [{ nome: 'Outras', valor: contas.slice(3).reduce((s, c) => s + Math.max(0, centimos(c.saldo)), 0) / 100, slot: 'neutra' as Slot }] : []),
  ]
  const mt = (v: number) => dinheiro(deCentimos(Math.round(v * 100)))
  return (
    <>
      <Cartao titulo="Entradas e saídas" descricao="Últimos 6 meses, nas contas da igreja" icone={BarChart3} className="lg:col-span-7"
        accoes={<Button asChild variant="ghost" size="sm"><Link to="/tesouraria">Tesouraria</Link></Button>}>
        {resumo.aCarregar ? <Barra className="h-48 w-full" />
          : resumo.erro ? <EstadoErro erro={resumo.erro} />
          : <GraficoBarras rotulo="Entradas e saídas confirmadas por mês" altura={200} categorias={resumo.categorias} destaque={resumo.categorias.length - 1}
              series={[{ nome: 'Entradas', slot: 1, valores: resumo.entradas }, { nome: 'Saídas', slot: 2, valores: resumo.saidas }]} formatar={mt} />}
      </Cartao>
      <Cartao titulo={t.inicio.saldos} descricao={<>Total da igreja: <Dinheiro valor={total} /></>} icone={Wallet} className="lg:col-span-5">
        {q.isPending ? <Barra className="h-40 w-full" />
          : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
          : !contas.length ? <EstadoVazio icone={Wallet}>Ainda não há contas registadas.</EstadoVazio>
          : <Donut rotulo="Saldo por conta" centro={curto(centimos(total) / 100)} formatar={mt} fatias={fatias} />}
      </Cartao>
    </>
  )
}

export default function PaginaInicio() {
  const igreja = useIgreja()
  const { pode } = useSessao()
  const basicos = useMembrosBasicos()
  const porAprovar = useContagemPorAprovar()
  const { doDia, q: escala } = useEscalaDoSabado()
  const n = (e: string) => (basicos.data ?? []).filter((m) => m.estado === e).length
  const podeMembros = pode('secretaria.membro.ler')

  return (
    <>
      <TituloPagina
        icone={LayoutDashboard}
        titulo={igreja.nome}
        descricao={`Painel da semana até ${dataPorExtenso(proximoSabado())}`}
        accoes={pode('secretaria.membro.criar') && (
          <Button asChild className="alvo"><Link to="/membros/novo"><Plus className="size-4" />{t.membros.registar}</Link></Button>
        )}
      />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-4">
          {podeMembros && <Indicador rotulo="Membros activos" valor={n('ACTIVO')} nota="no livro desta igreja" icone={Users} para="/membros?estado=ACTIVO" aCarregar={basicos.isPending} />}
          {podeMembros && <Indicador rotulo="Interessados" valor={n('INTERESSADO')} nota="a preparar para o baptismo" icone={Sprout} tom="info" para="/membros?estado=INTERESSADO" aCarregar={basicos.isPending} />}
          {podeMembros && <Indicador rotulo="Por aprovar" valor={porAprovar ?? 0} nota="registos à espera do secretário" icone={ClipboardCheck} tom="warning" para="/membros?validacao=PENDENTE" aCarregar={basicos.isPending} />}
          <Indicador rotulo="Escalados no sábado" valor={doDia.length} nota="pessoas com uma função" icone={CalendarDays} tom="success" aCarregar={escala.isPending && escala.fetchStatus !== 'idle'} />
        </div>
        <div className="grid items-start gap-6 lg:grid-cols-12">
          <ProximoSabado />
          <Pendentes />
          <LivroDoAno />
          <Composicao />
          <Financas />
        </div>
      </div>
    </>
  )
}
