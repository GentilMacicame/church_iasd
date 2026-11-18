/**
 * Painel geral das igrejas · "Como estão as igrejas que acompanho, no período que escolho?"
 * Para a direcção: a Associação/Missão vê as suas igrejas, o pastor do distrito só as do seu distrito, o
 * super-administrador todas. Quem decide o que cada um vê é a base de dados (V30 e V38, security invoker);
 * o ecrã só soma e compara o que recebe.
 *
 *  1. Período: este mês, este ano, o ano anterior ou um intervalo de datas.
 *  2. Indicadores do período: membros, activos e inactivos (sem participação há 6 meses), fidelidade contributiva
 *     (contribuintes / membros), dízimos com as ofertas, reavivamento; e, à data de hoje, saldo e depósitos em falta.
 *  3. Gráficos dos últimos 12 meses: dízimos e ofertas, entradas e saídas, movimento de membros; comparativo de uma medida.
 *  4. Quadro comparativo das igrejas (ordenável) com as colunas do período.
 */
import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import {
  ArrowDown, ArrowUp, ArrowUpDown, Building2, UserPlus, UserX, ChartColumn, Church, Flame, Wine, HandCoins, HeartHandshake, Landmark, Printer, Search, UserCheck, Users, Wallet,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Cartao, Indicador, Pilula, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { GraficoBarras } from '@/components/comum/graficos'
import { Seleccao } from '@/components/comum/Seleccao'
import { CampoData } from '@/components/comum/CampoData'
import { Exportar } from '@/components/comum/Exportar'
import { api, dados } from '@/api/cliente'
import { useSessao } from '@/auth/sessao'
import { imprimirComo } from '@/lib/documentos'
import { data as dataEcra, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { CelulaPct, Folha, textoMT, textoPct } from '@/features/escola-sabatina/componentes'
import { useHistoricoSantaCeia } from '@/features/santa-ceia/api'

/** Linha de GET /v1/organizacao/painel-igrejas (V30): a situação de hoje (saldo, por depositar). DECIMAL chega como texto. */
interface LinhaHoje { id: number; saldo: string; porRemeter: string; provincia: string | null; transfPendentes: number }
/** Linha de GET /v1/organizacao/painel-periodo (V38): o período escolhido. */
interface LinhaPeriodo {
  id: number; nome: string; entidadeId: number; entidade: string; distritoPastoralId: number | null; distritoPastoral: string | null
  veMembros: boolean; veTesouraria: boolean; membros: number; activos: number; inactivos: number; interessados: number
  dizimos: string; ofertas: string; reavivamento: string; contribuintes: number; entradasMembros: number; perdasMembros: number
}
/** Linha de GET /v1/organizacao/painel-igrejas-mensal (últimos 12 meses). */
interface LinhaMes {
  id: number; ano: number; mes: number; entradas: string; saidas: string; dizimos: string; ofertas: string; reavivamento: string
  admissoes: number; transfEntrada: number; transfSaida: number; outrasSaidas?: number
}
/** Linha de GET /v1/organizacao/painel-membros (V46): a composição dos membros (no livro como activos) de cada igreja. */
interface LinhaMembros {
  id: number; membros: number; interessados: number; homens: number; mulheres: number; activosSemFamilia: number
  menores: number; jovens: number; adultos: number; idosos: number; idadeDesconhecida: number
  casados: number; uniaoFacto: number; solteiros: number; viuvos: number; viuvas: number; divorciados: number; noivos: number; estadoCivilVazio: number
}
/** Uma igreja no quadro: o período e a situação de hoje. */
type Linha = LinhaPeriodo & { saldo: number; porRemeter: number; provincia: string | null; pctActivos: number | null; fidelidade: number | null; semFamilia: number }

const MESES = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']
const n = (v?: string | number | null) => Number(v ?? 0) || 0
const inteiro = (v: number) => v.toLocaleString('pt-PT').replace(/[\u00a0\u202f]/g, ' ')
const mtCurto = (v: number) => (Math.abs(v) >= 1_000_000 ? `${(v / 1_000_000).toLocaleString('pt-PT', { maximumFractionDigits: 1 })} M MT`
  : Math.abs(v) >= 10_000 ? `${Math.round(v / 1000).toLocaleString('pt-PT')} mil MT` : textoMT(v))
const razao = (a: number, b: number) => (b > 0 ? a / b : null)

type Periodo = 'mes' | 'ano' | 'anterior' | 'intervalo'
function intervaloDe(p: Periodo, de: string, ate: string): { de: string; ate: string; rotulo: string } {
  const hoje = hojeIso(), ano = Number(hoje.slice(0, 4))
  if (p === 'mes') return { de: `${hoje.slice(0, 7)}-01`, ate: hoje, rotulo: 'este mês' }
  if (p === 'ano') return { de: `${ano}-01-01`, ate: hoje, rotulo: `${ano} até hoje` }
  if (p === 'anterior') return { de: `${ano - 1}-01-01`, ate: `${ano - 1}-12-31`, rotulo: String(ano - 1) }
  return { de, ate, rotulo: `${dataEcra(de)} a ${dataEcra(ate)}` }
}

type Medida = 'membros' | 'activos' | 'pctActivos' | 'fidelidade' | 'dizimos' | 'ofertas' | 'reavivamento' | 'saldo' | 'porRemeter'
const MEDIDAS: { k: Medida; rotulo: string; dinheiro?: boolean; pct?: boolean; tesouraria?: boolean }[] = [
  { k: 'membros', rotulo: 'Membros' },
  { k: 'activos', rotulo: 'Membros activos' },
  { k: 'pctActivos', rotulo: '% de membros activos', pct: true },
  { k: 'fidelidade', rotulo: 'Fidelidade contributiva', pct: true, tesouraria: true },
  { k: 'dizimos', rotulo: 'Dízimos', dinheiro: true, tesouraria: true },
  { k: 'ofertas', rotulo: 'Ofertas', dinheiro: true, tesouraria: true },
  { k: 'reavivamento', rotulo: 'Reavivamento', dinheiro: true, tesouraria: true },
  { k: 'saldo', rotulo: 'Saldo nas contas (hoje)', dinheiro: true, tesouraria: true },
  { k: 'porRemeter', rotulo: 'Por depositar à Missão (hoje)', dinheiro: true, tesouraria: true },
]

type Coluna = 'nome' | 'membros' | 'activos' | 'inactivos' | 'pctActivos' | 'dizimos' | 'ofertas' | 'reavivamento' | 'fidelidade'
  | 'semFamilia' | 'entradasMembros' | 'perdasMembros' | 'saldo' | 'porRemeter'
const COLUNAS: { k: Coluna; rotulo: string; tipo: 'texto' | 'int' | 'mt' | 'pct'; area?: 'membros' | 'tesouraria' }[] = [
  { k: 'nome', rotulo: 'Igreja', tipo: 'texto' },
  { k: 'membros', rotulo: 'Membros', tipo: 'int', area: 'membros' },
  { k: 'activos', rotulo: 'Activos', tipo: 'int', area: 'membros' },
  { k: 'inactivos', rotulo: 'Inactivos', tipo: 'int', area: 'membros' },
  { k: 'pctActivos', rotulo: '% activos', tipo: 'pct', area: 'membros' },
  { k: 'dizimos', rotulo: 'Dízimos', tipo: 'mt', area: 'tesouraria' },
  { k: 'ofertas', rotulo: 'Ofertas', tipo: 'mt', area: 'tesouraria' },
  { k: 'reavivamento', rotulo: 'Reavivamento', tipo: 'mt', area: 'tesouraria' },
  { k: 'fidelidade', rotulo: 'Fidelidade', tipo: 'pct', area: 'tesouraria' },
  { k: 'semFamilia', rotulo: 'Sem família', tipo: 'int', area: 'membros' },
  { k: 'entradasMembros', rotulo: 'Entradas de membros', tipo: 'int', area: 'membros' },
  { k: 'perdasMembros', rotulo: 'Perdas de membros', tipo: 'int', area: 'membros' },
  { k: 'saldo', rotulo: 'Saldo (hoje)', tipo: 'mt', area: 'tesouraria' },
  { k: 'porRemeter', rotulo: 'Por depositar', tipo: 'mt', area: 'tesouraria' },
]

function usePainelHoje() {
  return useQuery({
    queryKey: ['painel-geral', 'igrejas'],
    queryFn: async () => (await dados(api.GET('/v1/organizacao/painel-igrejas', {}))) as unknown as LinhaHoje[],
    staleTime: 2 * 60_000,
  })
}
function usePainelPeriodo(de: string, ate: string) {
  return useQuery({
    enabled: /^\d{4}-\d{2}-\d{2}$/.test(de) && /^\d{4}-\d{2}-\d{2}$/.test(ate) && de <= ate,
    queryKey: ['painel-geral', 'periodo', de, ate],
    queryFn: async () => (await dados(api.GET('/v1/organizacao/painel-periodo', { params: { query: { inicio: de, fim: ate } } }))) as unknown as LinhaPeriodo[],
    staleTime: 2 * 60_000,
  })
}
function usePainelMembros() {
  return useQuery({
    queryKey: ['painel-geral', 'membros'],
    queryFn: async () => (await dados(api.GET('/v1/organizacao/painel-membros', {}))) as unknown as LinhaMembros[],
    staleTime: 2 * 60_000,
  })
}
function usePainelMensal() {
  return useQuery({
    queryKey: ['painel-geral', 'mensal'],
    queryFn: async () => (await dados(api.GET('/v1/organizacao/painel-igrejas-mensal', {}))) as unknown as LinhaMes[],
    staleTime: 2 * 60_000,
  })
}

export default function PaginaPainelGeral({ distritoFixo, titulo: tituloFixo }: { distritoFixo?: number; titulo?: string } = {}) {
  const navigate = useNavigate()
  const { igrejas, escolherIgreja } = useSessao()
  const [periodo, setPeriodo] = useState<Periodo>('ano')
  const [de, setDe] = useState(`${hojeIso().slice(0, 4)}-01-01`)
  const [ate, setAte] = useState(hojeIso())
  const intervalo = intervaloDe(periodo, de, ate)
  const qp = usePainelPeriodo(intervalo.de, intervalo.ate)
  const qh = usePainelHoje()
  const qm = usePainelMensal()
  const qs = useHistoricoSantaCeia(true)
  const qc = usePainelMembros()
  const [entidade, setEntidade] = useState('')
  const [distrito, setDistrito] = useState(distritoFixo ? String(distritoFixo) : '')
  const [texto, setTexto] = useState('')
  const [medida, setMedida] = useState<Medida>('membros')
  const [ordem, setOrdem] = useState<{ k: Coluna; desc: boolean }>({ k: 'membros', desc: true })

  const todas: Linha[] = useMemo(() => {
    const hoje = new Map((qh.data ?? []).map((h) => [h.id, h]))
    const comp = new Map((qc.data ?? []).map((c) => [c.id, c]))
    return (qp.data ?? []).map((p) => {
      const h = hoje.get(p.id)
      return { ...p, saldo: n(h?.saldo), porRemeter: n(h?.porRemeter), provincia: h?.provincia ?? null,
        pctActivos: razao(p.activos, p.membros), fidelidade: razao(p.contribuintes, p.membros), semFamilia: comp.get(p.id)?.activosSemFamilia ?? 0 }
    })
  }, [qp.data, qh.data, qc.data])
  const entidades = useMemo(() => [...new Map(todas.map((l) => [l.entidadeId, l.entidade])).entries()].sort((a, b) => a[1].localeCompare(b[1], 'pt')), [todas])
  const distritos = useMemo(() => [...new Map(todas.filter((l) => l.distritoPastoralId && (!entidade || String(l.entidadeId) === entidade))
    .map((l) => [l.distritoPastoralId!, l.distritoPastoral!])).entries()].sort((a, b) => a[1].localeCompare(b[1], 'pt')), [todas, entidade])
  const normal = (s: string) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()
  const linhas = todas.filter((l) => (!entidade || String(l.entidadeId) === entidade) && (!distrito || String(l.distritoPastoralId) === distrito)
    && (!texto.trim() || normal(l.nome).includes(normal(texto.trim()))))
  const ids = new Set(linhas.map((l) => l.id))
  const comTes = linhas.filter((l) => l.veTesouraria)
  const comMem = linhas.filter((l) => l.veMembros)
  const S = (l: Linha[], f: (x: Linha) => number) => l.reduce((s, x) => s + f(x), 0)
  const membros = S(comMem, (l) => l.membros), activos = S(comMem, (l) => l.activos), inactivos = S(comMem, (l) => l.inactivos)
  const ambas = comTes.filter((l) => l.veMembros)
  const contribuintes = S(ambas, (l) => l.contribuintes), membrosComTes = S(ambas, (l) => l.membros)
  const dizimos = S(comTes, (l) => n(l.dizimos)), ofertas = S(comTes, (l) => n(l.ofertas)), reavivamento = S(comTes, (l) => n(l.reavivamento))
  // V39: Santa Ceia realizada no período, nas igrejas filtradas
  const ceias = (qs.data ?? []).filter((s) => s.estado === 'REALIZADA' && ids.has(s.igrejaId) && s.data >= intervalo.de && s.data <= intervalo.ate)
  const participantesCeia = ceias.reduce((s, x) => s + x.total, 0)
  // V46: composição dos membros das igrejas filtradas (só as que o utilizador vê)
  const composicao = (qc.data ?? []).filter((c) => ids.has(c.id))
  const C = (f: (c: LinhaMembros) => number) => composicao.reduce((s, c) => s + f(c), 0)
  const semFamilia = C((c) => c.activosSemFamilia)
  const entradasM = S(comMem, (l) => l.entradasMembros), perdasM = S(comMem, (l) => l.perdasMembros)

  // séries dos últimos 12 meses (soma das igrejas filtradas)
  const meses = useMemo(() => {
    const m = new Map<string, { ano: number; mes: number; entradas: number; saidas: number; dizimos: number; ofertas: number; reav: number; admissoes: number; te: number; ts: number; os: number }>()
    for (const r of qm.data ?? []) {
      if (!ids.has(r.id)) continue
      const k = `${r.ano}-${String(r.mes).padStart(2, '0')}`
      const x = m.get(k) ?? { ano: r.ano, mes: r.mes, entradas: 0, saidas: 0, dizimos: 0, ofertas: 0, reav: 0, admissoes: 0, te: 0, ts: 0, os: 0 }
      x.entradas += n(r.entradas); x.saidas += n(r.saidas); x.dizimos += n(r.dizimos); x.ofertas += n(r.ofertas); x.reav += n(r.reavivamento)
      x.admissoes += r.admissoes; x.te += r.transfEntrada; x.ts += r.transfSaida; x.os += r.outrasSaidas ?? 0
      m.set(k, x)
    }
    return [...m.entries()].sort((a, b) => a[0].localeCompare(b[0])).map(([, v]) => v)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [qm.data, linhas.map((l) => l.id).join(',')])
  const categorias = meses.map((m) => `${MESES[m.mes - 1]}${m.mes === 1 ? ` ${String(m.ano).slice(2)}` : ''}`)

  const ordenadas = [...linhas].sort((a, b) => {
    const r = ordem.k === 'nome' ? a.nome.localeCompare(b.nome, 'pt') : n(a[ordem.k] as number) - n(b[ordem.k] as number)
    return ordem.desc ? -r : r
  })
  const ordenar = (k: Coluna) => setOrdem((o) => ({ k, desc: o.k === k ? !o.desc : k !== 'nome' }))
  const med = MEDIDAS.find((x) => x.k === medida)!
  const comparativo = linhas.filter((l) => (!med.tesouraria || l.veTesouraria) && l.veMembros).map((l) => ({ l, v: n(l[medida] as number) }))
    .sort((a, b) => b.v - a.v)
  const maxComp = Math.max(0, ...comparativo.map((c) => c.v))
  const mediaComp = comparativo.length ? comparativo.reduce((s, c) => s + c.v, 0) / comparativo.length : 0
  const formatar = (v: number) => (med.pct ? textoPct(v) : med.dinheiro ? textoMT(v) : inteiro(v))
  const abrir = (id: number) => {
    if (!igrejas.some((i) => i.id === id)) return
    escolherIgreja(id)
    navigate('/')
  }
  const aCarregar = qp.isPending
  const erro = qp.error ?? qh.error

  if (erro) return <EstadoErro erro={erro} aoTentar={() => { void qp.refetch(); void qh.refetch() }} />

  return (
    <>
      <TituloPagina
        icone={ChartColumn}
        titulo={tituloFixo ?? 'Painel geral das igrejas'}
        descricao={aCarregar ? 'A carregar…' : `${linhas.length} igreja(s)${distrito ? ` do ${distritos.find(([id]) => String(id) === distrito)?.[1]}` : entidade ? ` da ${entidades.find(([id]) => String(id) === entidade)?.[1]}` : ' a seu cargo'} · ${intervalo.rotulo}`}
        accoes={<>
          <Exportar caminho="/v1/organizacao/painel-igrejas" query={{ entidadeId: entidade || undefined, distritoId: distrito || undefined }} nome="painel-geral-igrejas" />
          <Button variant="outline" className="alvo print:hidden" onClick={() => imprimirComo('Painel geral das igrejas')}><Printer className="size-4" />Imprimir</Button>
        </>}
      />

      <div className="mb-5 grid gap-3 rounded-xl border bg-card p-3 shadow-card print:hidden">
        <div className="flex flex-wrap items-end gap-2">
          <div role="radiogroup" aria-label="Período" className="flex flex-wrap gap-1 rounded-lg border bg-muted/40 p-1">
            {([['mes', 'Este mês'], ['ano', 'Este ano'], ['anterior', 'Ano anterior'], ['intervalo', 'Intervalo']] as const).map(([k, r]) => (
              <button key={k} type="button" role="radio" aria-checked={periodo === k} onClick={() => setPeriodo(k)}
                className={cn('alvo rounded-md px-3 text-sm font-medium', periodo === k ? 'bg-card text-foreground shadow-sm' : 'text-muted-foreground hover:text-foreground')}>
                {r}
              </button>
            ))}
          </div>
          {periodo === 'intervalo' && (
            <div className="flex flex-wrap items-center gap-2">
              <CampoData aria-label="De" value={de} onChange={setDe} className="alvo w-36" />
              <span className="text-sm text-muted-foreground">a</span>
              <CampoData aria-label="Até" value={ate} onChange={setAte} className="alvo w-36" />
              {de > ate && <span className="text-xs text-destructive-text">O fim tem de ser depois do início.</span>}
            </div>
          )}
        </div>
        <div className={cn('grid gap-3 sm:grid-cols-[1fr_1fr_1.2fr]', distritoFixo && 'hidden')}>
          <Seleccao aria-label="Associação / Missão" value={entidade} onChange={(e) => { setEntidade(e.target.value); setDistrito('') }} disabled={entidades.length < 2}>
            <option value="">{entidades.length === 1 ? entidades[0][1] : 'Todas as Associações / Missões'}</option>
            {entidades.length > 1 && entidades.map(([id, nome]) => <option key={id} value={id}>{nome}</option>)}
          </Seleccao>
          <Seleccao aria-label="Distrito pastoral" value={distrito} onChange={(e) => setDistrito(e.target.value)} disabled={!distritos.length}>
            <option value="">{distritos.length ? 'Todos os distritos pastorais' : 'Sem distritos pastorais'}</option>
            {distritos.map(([id, nome]) => <option key={id} value={id}>{nome}</option>)}
          </Seleccao>
          <div className="relative">
            <Search aria-hidden className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
            <Input value={texto} onChange={(e) => setTexto(e.target.value)} placeholder="Procurar igreja" aria-label="Procurar igreja" className="h-9 pl-9" />
          </div>
        </div>
      </div>

      {!aCarregar && !todas.length ? (
        <Cartao><EstadoVazio icone={Church} titulo="Sem igrejas a seu cargo">O painel geral mostra as igrejas da sua Associação ou do seu distrito pastoral.</EstadoVazio></Cartao>
      ) : (
        <div className="grid gap-6">
          <section aria-label="Membros" className="grid gap-3">
            <h2 className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Membros</h2>
            <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
              <Indicador rotulo="Igrejas" valor={linhas.length} nota={`${new Set(linhas.map((l) => l.distritoPastoralId).filter(Boolean)).size} distrito(s) pastoral(is)`} icone={Building2} aCarregar={aCarregar} />
              <Indicador rotulo="Total de membros" valor={inteiro(membros)} icone={Users} aCarregar={aCarregar}
                nota={`${inteiro(S(comMem, (l) => l.interessados))} interessados a preparar`} />
              <Indicador rotulo="Membros activos" valor={inteiro(activos)} icone={UserCheck} tom="success" aCarregar={aCarregar}
                nota={`${textoPct(razao(activos, membros))} de ${inteiro(membros)} membros`} />
              <Indicador rotulo="Membros inactivos" valor={inteiro(inactivos)} icone={UserX} tom="warning" aCarregar={aCarregar}
                nota={`${textoPct(razao(inactivos, membros))} · sem participação há 6 meses`} />
              <Indicador rotulo="Sem família" valor={inteiro(semFamilia)} icone={UserPlus} tom={semFamilia ? 'destructive' : 'success'} destaque={semFamilia > 0}
                aCarregar={qc.isPending} nota={`${textoPct(razao(semFamilia, C((c) => c.membros)))} dos membros sem família associada`} />
              <Indicador rotulo="Entradas e perdas" valor={`+${inteiro(entradasM)} / −${inteiro(perdasM)}`} icone={ArrowUpDown} aCarregar={aCarregar}
                nota={`membros no período · saldo ${entradasM - perdasM >= 0 ? '+' : ''}${inteiro(entradasM - perdasM)}`} />
              <Indicador rotulo="Santa Ceia" valor={ceias.length} icone={Wine} aCarregar={aCarregar || qs.isPending}
                nota={ceias.length ? `${inteiro(participantesCeia)} participantes · média ${inteiro(Math.round(participantesCeia / ceias.length))}` : `nenhuma registada · ${intervalo.rotulo}`} />
              <Indicador rotulo="Fidelidade contributiva" valor={textoPct(razao(contribuintes, membrosComTes))} icone={HeartHandshake} tom="info" aCarregar={aCarregar}
                nota={`${inteiro(contribuintes)} de ${inteiro(membrosComTes)} membros contribuíram · ${intervalo.rotulo}`} />
            </div>
          </section>

          {composicao.length > 0 && (
            <section aria-label="Composição dos membros" className="grid gap-3">
              <h2 className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Composição dos membros</h2>
              <div className="grid gap-4 md:grid-cols-3">
                <Cartao titulo="Sexo" descricao="Membros, hoje">
                  <Barras itens={[{ r: 'Mulheres', v: C((c) => c.mulheres) }, { r: 'Homens', v: C((c) => c.homens) }]} />
                </Cartao>
                <Cartao titulo="Idades" descricao="Membros, hoje">
                  <Barras itens={[{ r: 'Menores (até 17)', v: C((c) => c.menores) }, { r: 'Jovens (18–35)', v: C((c) => c.jovens) },
                    { r: 'Adultos (36–59)', v: C((c) => c.adultos) }, { r: 'Idosos (60 ou mais)', v: C((c) => c.idosos) },
                    { r: 'Sem data de nascimento', v: C((c) => c.idadeDesconhecida), fraco: true }]} />
                </Cartao>
                <Cartao titulo="Estado civil" descricao="Membros, hoje">
                  <Barras itens={[{ r: 'Casados', v: C((c) => c.casados) }, { r: 'União de facto', v: C((c) => c.uniaoFacto) },
                    { r: 'Solteiros', v: C((c) => c.solteiros) }, { r: 'Noivos', v: C((c) => c.noivos) }, { r: 'Viúvos', v: C((c) => c.viuvos) },
                    { r: 'Viúvas', v: C((c) => c.viuvas) }, { r: 'Divorciados', v: C((c) => c.divorciados) },
                    { r: 'Sem estado civil', v: C((c) => c.estadoCivilVazio), fraco: true }]} />
                </Cartao>
              </div>
            </section>
          )}

          <section aria-label="Situação financeira" className="grid gap-3">
            <h2 className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Contribuições e finanças {comTes.length < linhas.length && <span className="font-normal normal-case">· {comTes.length} de {linhas.length} igrejas com acesso à tesouraria</span>}</h2>
            <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
              <Indicador rotulo="Dízimos" valor={mtCurto(dizimos)} nota={`ofertas: ${mtCurto(ofertas)} · ${intervalo.rotulo}`} icone={HandCoins} tom="info" aCarregar={aCarregar} />
              <Indicador rotulo="Reavivamento" valor={mtCurto(reavivamento)} nota={`${comTes.filter((l) => n(l.reavivamento) > 0).length} igreja(s) contribuíram · ${intervalo.rotulo}`} icone={Flame} tom="warning" aCarregar={aCarregar} />
              <Indicador rotulo="Saldo nas contas" valor={mtCurto(S(comTes, (l) => l.saldo))} nota="hoje: caixa, M-Pesa e bancos das igrejas" icone={Wallet} aCarregar={aCarregar || qh.isPending} />
              <Indicador rotulo="Por depositar à Missão" valor={mtCurto(S(comTes, (l) => l.porRemeter))} icone={Landmark} aCarregar={aCarregar || qh.isPending}
                tom={S(comTes, (l) => l.porRemeter) > 0 ? 'destructive' : 'primary'}
                nota={`hoje: ${comTes.filter((l) => l.porRemeter > 0).length} igreja(s) com depósito em falta`} />
            </div>
          </section>

          <div className="grid gap-6 lg:grid-cols-2">
            <Cartao titulo="Evolução das contribuições" descricao="Dízimos, ofertas e reavivamento nos últimos 12 meses">
              {qm.isPending ? <LinhasACarregar linhas={4} /> : qm.isError ? <EstadoErro erro={qm.error} aoTentar={() => qm.refetch()} /> : (
                <GraficoBarras rotulo="Contribuições por mês" categorias={categorias} destaque={categorias.length - 1}
                  series={[{ nome: 'Dízimos', slot: 3, valores: meses.map((m) => m.dizimos) }, { nome: 'Ofertas', slot: 1, valores: meses.map((m) => m.ofertas) },
                    { nome: 'Reavivamento', slot: 2, valores: meses.map((m) => m.reav) }]} formatar={(v) => textoMT(v)} />
              )}
            </Cartao>
            <Cartao titulo="Entradas e saídas de membros" descricao="Admissões, transferências e outras saídas (falecimento, remoção), últimos 12 meses">
              {qm.isPending ? <LinhasACarregar linhas={4} /> : qm.isError ? <EstadoErro erro={qm.error} /> : (
                <GraficoBarras rotulo="Movimento de membros por mês" categorias={categorias} destaque={categorias.length - 1} inteiros
                  series={[{ nome: 'Admissões', slot: 1, valores: meses.map((m) => m.admissoes) }, { nome: 'Transf. entradas', slot: 3, valores: meses.map((m) => m.te) },
                    { nome: 'Transf. saídas', slot: 2, valores: meses.map((m) => m.ts) }, { nome: 'Outras saídas', slot: 'neutra', valores: meses.map((m) => m.os) }]} formatar={(v) => inteiro(v)} />
              )}
            </Cartao>
            <Cartao titulo="Entradas e saídas de dinheiro" descricao="Últimos 12 meses, contas das igrejas filtradas">
              {qm.isPending ? <LinhasACarregar linhas={4} /> : qm.isError ? <EstadoErro erro={qm.error} /> : (
                <GraficoBarras rotulo="Entradas e saídas por mês" categorias={categorias} destaque={categorias.length - 1}
                  series={[{ nome: 'Entradas', slot: 1, valores: meses.map((m) => m.entradas) }, { nome: 'Saídas', slot: 2, valores: meses.map((m) => m.saidas) }]}
                  formatar={(v) => textoMT(v)} />
              )}
            </Cartao>
            <Cartao titulo="Comparativo entre igrejas" descricao={`${med.rotulo} · a linha marca a média (${formatar(mediaComp)})`}
              accoes={<div className="w-56 print:hidden"><Seleccao aria-label="Medida a comparar" value={medida} onChange={(e) => setMedida(e.target.value as Medida)}>
                {MEDIDAS.map((x) => <option key={x.k} value={x.k}>{x.rotulo}</option>)}
              </Seleccao></div>}>
              {aCarregar ? <LinhasACarregar linhas={5} /> : !comparativo.length ? <EstadoVazio>Sem dados para comparar.</EstadoVazio> : (
                <ol className="grid max-h-80 gap-2 overflow-y-auto pr-1">
                  {comparativo.map(({ l, v }, i) => (
                    <li key={l.id} className="grid grid-cols-[1.5rem_minmax(0,9rem)_1fr_auto] items-center gap-2 text-sm">
                      <span className="text-right text-xs tabular-nums text-muted-foreground">{i + 1}</span>
                      <span className="truncate" title={l.nome}>{l.nome}</span>
                      <span className="relative h-5 rounded-sm bg-muted">
                        <span className={cn('absolute inset-y-0 left-0 rounded-sm', v >= mediaComp ? 'bg-primary' : 'bg-primary/45')} style={{ width: `${maxComp ? (v / maxComp) * 100 : 0}%` }} />
                        {maxComp > 0 && <span aria-hidden className="absolute inset-y-[-3px] w-0.5 bg-foreground/50" style={{ left: `${(mediaComp / maxComp) * 100}%` }} />}
                      </span>
                      <span className="w-24 text-right font-medium tabular-nums">{formatar(v)}</span>
                    </li>
                  ))}
                </ol>
              )}
            </Cartao>
          </div>

          <Cartao titulo="Quadro comparativo das igrejas" descricao={`${intervalo.rotulo} · clique no título de uma coluna para ordenar; numa igreja para a abrir`}>
            {aCarregar ? <LinhasACarregar linhas={6} /> : !linhas.length ? <EstadoVazio>Nenhuma igreja com esse filtro.</EstadoVazio> : (
              <Folha minimo="min-w-[86rem]">
                <thead>
                  <tr>
                    {COLUNAS.map((c) => (
                      <th key={c.k} className={cn(c.tipo === 'texto' ? 'min-w-56 text-left' : 'num')}>
                        <button type="button" onClick={() => ordenar(c.k)} className={cn('inline-flex items-center gap-1 uppercase', c.tipo !== 'texto' && 'flex-row-reverse')}>
                          {c.rotulo}
                          {ordem.k === c.k ? (ordem.desc ? <ArrowDown className="size-3" /> : <ArrowUp className="size-3" />) : <ArrowUpDown className="size-3 opacity-40" />}
                        </button>
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {ordenadas.map((l) => (
                    <tr key={l.id} onClick={() => abrir(l.id)} className={cn(igrejas.some((i) => i.id === l.id) && 'cursor-pointer')}>
                      {COLUNAS.map((c) => {
                        if (c.k === 'nome') {
                          return (
                            <td key={c.k}>
                              <span className="block font-semibold">{l.nome}</span>
                              <span className="block text-xs text-muted-foreground">{[l.distritoPastoral, l.provincia].filter(Boolean).join(' · ') || l.entidade}</span>
                            </td>
                          )
                        }
                        const sem = (c.area === 'tesouraria' && !l.veTesouraria) || (c.area === 'membros' && !l.veMembros) || (c.k === 'fidelidade' && !l.veMembros)
                        if (sem) return <td key={c.k} className="num text-xs text-muted-foreground">sem acesso</td>
                        if (c.tipo === 'pct') return <CelulaPct key={c.k} v={l[c.k] as number | null} tipo="presenca" />
                        const v = n(l[c.k] as number | string)
                        return (
                          <td key={c.k} className={cn('num tabular-nums', c.k === 'porRemeter' && v > 0 && 'font-semibold text-destructive-text',
                            c.k === 'saldo' && v < 0 && 'text-destructive-text', c.k === 'inactivos' && v > 0 && 'text-warning-text')}>
                            {c.tipo === 'mt' ? textoMT(v) : inteiro(v)}
                          </td>
                        )
                      })}
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr>
                    <td>Total ({linhas.length} igrejas)</td>
                    {COLUNAS.slice(1).map((c) => {
                      if (c.k === 'pctActivos') return <CelulaPct key={c.k} v={razao(activos, membros)} />
                      if (c.k === 'fidelidade') return <CelulaPct key={c.k} v={razao(contribuintes, membrosComTes)} />
                      const base = c.area === 'tesouraria' ? comTes : comMem
                      const v = S(base, (l) => n(l[c.k] as number | string))
                      return <td key={c.k} className="num tabular-nums">{c.tipo === 'mt' ? textoMT(v) : inteiro(v)}</td>
                    })}
                  </tr>
                </tfoot>
              </Folha>
            )}
            <p className="mt-3 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
              <Pilula variante="outline">{intervalo.rotulo}</Pilula>
              Membros = estado activo no livro; inactivos = sem presença na Escola Sabatina nem contribuição há 6 meses. Fidelidade = membros que
              contribuíram (eles ou a família) no período ÷ membros. Ofertas = as outras entradas, sem o dízimo nem o reavivamento. Saldo e
              depósitos em falta são de hoje.
            </p>
          </Cartao>
        </div>
      )}
    </>
  )
}

/** Uma lista de quantidades com a barra proporcional e a percentagem (composição dos membros). */
function Barras({ itens }: { itens: { r: string; v: number; fraco?: boolean }[] }) {
  const total = itens.reduce((s, x) => s + x.v, 0)
  const maior = Math.max(1, ...itens.map((x) => x.v))
  return (
    <ul className="grid gap-2.5">
      {itens.map((x) => (
        <li key={x.r} className={cn('grid gap-1 text-sm', x.fraco && 'text-muted-foreground')}>
          <div className="flex items-baseline justify-between gap-3">
            <span>{x.r}</span>
            <span className="tabular-nums"><strong className="font-semibold">{inteiro(x.v)}</strong> <span className="text-xs text-muted-foreground">{textoPct(razao(x.v, total))}</span></span>
          </div>
          <div className="h-1.5 overflow-hidden rounded-full bg-muted" aria-hidden>
            <div className={cn('h-full rounded-full', x.fraco ? 'bg-muted-foreground/40' : 'bg-[var(--serie-1)]')} style={{ width: `${(x.v / maior) * 100}%` }} />
          </div>
        </li>
      ))}
    </ul>
  )
}
