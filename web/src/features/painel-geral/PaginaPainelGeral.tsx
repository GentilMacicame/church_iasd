/**
 * Painel geral das igrejas · "Como estão as igrejas que acompanho?"
 * Para a direcção: a Associação/Missão vê as suas igrejas, o pastor do distrito só as do seu distrito, o
 * super-administrador todas. Quem decide o que cada um vê é a base de dados (vistas V30 com security_invoker);
 * o ecrã só soma e compara o que recebe.
 *
 *  1. Indicadores: igrejas, membros activos, transferidos no ano, dizimistas, situação financeira.
 *  2. Gráficos: entradas e saídas, dízimos e movimento de membros nos últimos 12 meses.
 *  3. Comparativo: gráfico de uma medida igreja a igreja e o quadro de todas as igrejas (ordenável).
 */
import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import {
  ArrowDown, ArrowLeftRight, ArrowUp, ArrowUpDown, Building2, ChartColumn, Church, HandCoins, Landmark, Printer, Search, Users, Wallet,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Cartao, Indicador, Pilula, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { GraficoBarras } from '@/components/comum/graficos'
import { Seleccao } from '@/components/comum/Seleccao'
import { Exportar } from '@/components/comum/Exportar'
import { api, dados } from '@/api/cliente'
import { useSessao } from '@/auth/sessao'
import { imprimirComo } from '@/lib/documentos'
import { cn } from '@/lib/utils'
import { CelulaPct, Folha, textoMT, textoPct } from '@/features/escola-sabatina/componentes'

/** Linha de GET /v1/organizacao/painel-igrejas (vista organizacao.vw_painel_igrejas, V30). DECIMAL chega como texto. */
interface LinhaIgreja {
  id: number; nome: string; tipo: string; entidadeId: number; entidade: string; distritoPastoralId: number | null; distritoPastoral: string | null
  provincia: string | null; veMembros: boolean; veTesouraria: boolean
  membrosActivos: number; interessados: number; mulheres: number; homens: number; transferidos: number
  transfSaidaAno: number; transfEntradaAno: number; transfPendentes: number; admissoesAno: number; outrasSaidasAno: number
  dizimistas: number; familiasDizimistas: number; pctDizimistas: string | null; dizimosAno: string; dizimosMes: string
  entradasMes: string; saidasMes: string; entradasAno: string; saidasAno: string; resultadoAno: string; saldo: string; porRemeter: string
}
/** Linha de GET /v1/organizacao/painel-igrejas-mensal (últimos 12 meses). */
interface LinhaMes {
  id: number; nome: string; entidadeId: number; distritoPastoralId: number | null; ano: number; mes: number
  entradas: string; saidas: string; dizimos: string; dizimistas: number; admissoes: number; transfEntrada: number; transfSaida: number
}

const MESES = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']
const n = (v?: string | number | null) => Number(v ?? 0) || 0
const inteiro = (v: number) => v.toLocaleString('pt-PT').replace(/[\u00a0\u202f]/g, ' ')
const mtCurto = (v: number) => (Math.abs(v) >= 1_000_000 ? `${(v / 1_000_000).toLocaleString('pt-PT', { maximumFractionDigits: 1 })} M MT`
  : Math.abs(v) >= 10_000 ? `${Math.round(v / 1000).toLocaleString('pt-PT')} mil MT` : textoMT(v))

type Medida = 'membrosActivos' | 'pctDizimistas' | 'dizimistas' | 'dizimosAno' | 'entradasAno' | 'saldo' | 'transfSaidaAno' | 'porRemeter'
const MEDIDAS: { k: Medida; rotulo: string; dinheiro?: boolean; pct?: boolean; tesouraria?: boolean }[] = [
  { k: 'membrosActivos', rotulo: 'Membros activos' },
  { k: 'dizimistas', rotulo: 'Dizimistas', tesouraria: true },
  { k: 'pctDizimistas', rotulo: '% de dizimistas', pct: true, tesouraria: true },
  { k: 'dizimosAno', rotulo: 'Dízimos do ano', dinheiro: true, tesouraria: true },
  { k: 'entradasAno', rotulo: 'Entradas do ano', dinheiro: true, tesouraria: true },
  { k: 'saldo', rotulo: 'Saldo nas contas', dinheiro: true, tesouraria: true },
  { k: 'porRemeter', rotulo: 'Por depositar à Missão', dinheiro: true, tesouraria: true },
  { k: 'transfSaidaAno', rotulo: 'Transferidos (saídas) no ano' },
]

type Coluna = keyof LinhaIgreja
const COLUNAS: { k: Coluna; rotulo: string; tipo: 'texto' | 'int' | 'mt' | 'pct'; area?: 'membros' | 'tesouraria' }[] = [
  { k: 'nome', rotulo: 'Igreja', tipo: 'texto' },
  { k: 'membrosActivos', rotulo: 'Membros activos', tipo: 'int', area: 'membros' },
  { k: 'interessados', rotulo: 'Interessados', tipo: 'int', area: 'membros' },
  { k: 'transfSaidaAno', rotulo: 'Transf. saídas (ano)', tipo: 'int', area: 'membros' },
  { k: 'transfEntradaAno', rotulo: 'Transf. entradas (ano)', tipo: 'int', area: 'membros' },
  { k: 'dizimistas', rotulo: 'Dizimistas', tipo: 'int', area: 'tesouraria' },
  { k: 'pctDizimistas', rotulo: '% dizimistas', tipo: 'pct', area: 'tesouraria' },
  { k: 'dizimosAno', rotulo: 'Dízimos (ano)', tipo: 'mt', area: 'tesouraria' },
  { k: 'entradasAno', rotulo: 'Entradas (ano)', tipo: 'mt', area: 'tesouraria' },
  { k: 'saidasAno', rotulo: 'Saídas (ano)', tipo: 'mt', area: 'tesouraria' },
  { k: 'saldo', rotulo: 'Saldo', tipo: 'mt', area: 'tesouraria' },
  { k: 'porRemeter', rotulo: 'Por depositar', tipo: 'mt', area: 'tesouraria' },
]

function usePainel() {
  return useQuery({
    queryKey: ['painel-geral', 'igrejas'],
    queryFn: async () => (await dados(api.GET('/v1/organizacao/painel-igrejas', {}))) as unknown as LinhaIgreja[],
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

export default function PaginaPainelGeral() {
  const navigate = useNavigate()
  const { igrejas, escolherIgreja } = useSessao()
  const q = usePainel()
  const qm = usePainelMensal()
  const [entidade, setEntidade] = useState('')
  const [distrito, setDistrito] = useState('')
  const [texto, setTexto] = useState('')
  const [medida, setMedida] = useState<Medida>('membrosActivos')
  const [ordem, setOrdem] = useState<{ k: Coluna; desc: boolean }>({ k: 'membrosActivos', desc: true })

  const todas = useMemo(() => q.data ?? [], [q.data])
  const entidades = useMemo(() => [...new Map(todas.map((l) => [l.entidadeId, l.entidade])).entries()].sort((a, b) => a[1].localeCompare(b[1], 'pt')), [todas])
  const distritos = useMemo(() => [...new Map(todas.filter((l) => l.distritoPastoralId && (!entidade || String(l.entidadeId) === entidade))
    .map((l) => [l.distritoPastoralId!, l.distritoPastoral!])).entries()].sort((a, b) => a[1].localeCompare(b[1], 'pt')), [todas, entidade])
  const normal = (s: string) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()
  const linhas = todas.filter((l) => (!entidade || String(l.entidadeId) === entidade) && (!distrito || String(l.distritoPastoralId) === distrito)
    && (!texto.trim() || normal(l.nome).includes(normal(texto.trim()))))
  const ids = new Set(linhas.map((l) => l.id))
  const comTes = linhas.filter((l) => l.veTesouraria)
  const comMem = linhas.filter((l) => l.veMembros)
  const S = (l: LinhaIgreja[], f: (x: LinhaIgreja) => number) => l.reduce((s, x) => s + f(x), 0)
  const activos = S(comMem, (l) => l.membrosActivos)
  const dizimistas = S(comTes, (l) => l.dizimistas)
  const activosComTes = S(comTes.filter((l) => l.veMembros), (l) => l.membrosActivos)

  // séries dos últimos 12 meses (soma das igrejas filtradas)
  const meses = useMemo(() => {
    const m = new Map<string, { ano: number; mes: number; entradas: number; saidas: number; dizimos: number; dizimistas: number; admissoes: number; te: number; ts: number }>()
    for (const r of qm.data ?? []) {
      if (!ids.has(r.id)) continue
      const k = `${r.ano}-${String(r.mes).padStart(2, '0')}`
      const x = m.get(k) ?? { ano: r.ano, mes: r.mes, entradas: 0, saidas: 0, dizimos: 0, dizimistas: 0, admissoes: 0, te: 0, ts: 0 }
      x.entradas += n(r.entradas); x.saidas += n(r.saidas); x.dizimos += n(r.dizimos); x.dizimistas += r.dizimistas
      x.admissoes += r.admissoes; x.te += r.transfEntrada; x.ts += r.transfSaida
      m.set(k, x)
    }
    return [...m.entries()].sort((a, b) => a[0].localeCompare(b[0])).map(([, v]) => v)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [qm.data, linhas.map((l) => l.id).join(',')])
  const categorias = meses.map((m) => `${MESES[m.mes - 1]}${m.mes === 1 ? ` ${String(m.ano).slice(2)}` : ''}`)

  const ordenadas = [...linhas].sort((a, b) => {
    const va = a[ordem.k], vb = b[ordem.k]
    const r = ordem.k === 'nome' ? String(va).localeCompare(String(vb), 'pt') : n(va as string) - n(vb as string)
    return ordem.desc ? -r : r
  })
  const ordenar = (k: Coluna) => setOrdem((o) => ({ k, desc: o.k === k ? !o.desc : k !== 'nome' }))
  const med = MEDIDAS.find((x) => x.k === medida)!
  const comparativo = [...linhas].filter((l) => !med.tesouraria || l.veTesouraria).map((l) => ({ l, v: n(l[medida] as string) }))
    .sort((a, b) => b.v - a.v)
  const maxComp = Math.max(0, ...comparativo.map((c) => c.v))
  const mediaComp = comparativo.length ? comparativo.reduce((s, c) => s + c.v, 0) / comparativo.length : 0
  const formatar = (v: number) => (med.pct ? textoPct(v) : med.dinheiro ? textoMT(v) : inteiro(v))
  const abrir = (id: number) => {
    if (!igrejas.some((i) => i.id === id)) return
    escolherIgreja(id)
    navigate('/')
  }

  if (q.isError) return <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />

  return (
    <>
      <TituloPagina
        icone={ChartColumn}
        titulo="Painel geral das igrejas"
        descricao={q.isPending ? 'A carregar…' : `${linhas.length} igreja(s)${distrito ? ` do ${distritos.find(([id]) => String(id) === distrito)?.[1]}` : entidade ? ` da ${entidades.find(([id]) => String(id) === entidade)?.[1]}` : ' a seu cargo'} · ano de ${new Date().getFullYear()}`}
        accoes={<>
          <Exportar caminho="/v1/organizacao/painel-igrejas" query={{ entidadeId: entidade || undefined, distritoId: distrito || undefined }} nome="painel-geral-igrejas" />
          <Button variant="outline" className="alvo print:hidden" onClick={() => imprimirComo('Painel geral das igrejas')}><Printer className="size-4" />Imprimir</Button>
        </>}
      />

      <div className="mb-5 grid gap-3 rounded-xl border bg-card p-3 shadow-card sm:grid-cols-[1fr_1fr_1.2fr] print:hidden">
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

      {!q.isPending && !todas.length ? (
        <Cartao><EstadoVazio icone={Church} titulo="Sem igrejas a seu cargo">O painel geral mostra as igrejas da sua Associação ou do seu distrito pastoral.</EstadoVazio></Cartao>
      ) : (
        <div className="grid gap-6">
          <section aria-label="Membros" className="grid gap-3">
            <h2 className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Membros</h2>
            <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
              <Indicador rotulo="Igrejas" valor={linhas.length} nota={`${new Set(linhas.map((l) => l.distritoPastoralId).filter(Boolean)).size} distrito(s) pastoral(is)`} icone={Building2} aCarregar={q.isPending} />
              <Indicador rotulo="Membros activos" valor={inteiro(activos)} nota={`${inteiro(S(comMem, (l) => l.interessados))} interessados · ${inteiro(S(comMem, (l) => l.admissoesAno))} admitidos no ano`} icone={Users} tom="success" aCarregar={q.isPending} />
              <Indicador rotulo="Transferidos no ano" valor={inteiro(S(comMem, (l) => l.transfSaidaAno))} icone={ArrowLeftRight} tom="warning" aCarregar={q.isPending}
                nota={`${inteiro(S(comMem, (l) => l.transfEntradaAno))} recebidos · ${inteiro(S(comMem, (l) => l.transfPendentes))} cartas pendentes`} />
              <Indicador rotulo="Dizimistas" valor={inteiro(dizimistas)} icone={HandCoins} tom="info" aCarregar={q.isPending}
                nota={`${textoPct(activosComTes ? dizimistas / activosComTes : null)} dos membros activos · este ano`} />
            </div>
          </section>

          <section aria-label="Situação financeira" className="grid gap-3">
            <h2 className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Situação financeira {comTes.length < linhas.length && <span className="font-normal normal-case">· {comTes.length} de {linhas.length} igrejas com acesso à tesouraria</span>}</h2>
            <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
              <Indicador rotulo="Saldo nas contas" valor={mtCurto(S(comTes, (l) => n(l.saldo)))} nota="caixa, M-Pesa e bancos das igrejas" icone={Wallet} aCarregar={q.isPending} />
              <Indicador rotulo="Entradas do ano" valor={mtCurto(S(comTes, (l) => n(l.entradasAno)))} nota={`saídas: ${mtCurto(S(comTes, (l) => n(l.saidasAno)))}`} icone={ArrowUpDown} tom="success" aCarregar={q.isPending} />
              <Indicador rotulo="Dízimos do ano" valor={mtCurto(S(comTes, (l) => n(l.dizimosAno)))} nota={`este mês: ${mtCurto(S(comTes, (l) => n(l.dizimosMes)))}`} icone={HandCoins} tom="info" aCarregar={q.isPending} />
              <Indicador rotulo="Por depositar à Missão" valor={mtCurto(S(comTes, (l) => n(l.porRemeter)))} icone={Landmark} aCarregar={q.isPending}
                tom={S(comTes, (l) => n(l.porRemeter)) > 0 ? 'destructive' : 'primary'}
                nota={`${comTes.filter((l) => n(l.porRemeter) > 0).length} igreja(s) com depósito em falta`} />
            </div>
          </section>

          <div className="grid gap-6 lg:grid-cols-2">
            <Cartao titulo="Entradas e saídas" descricao="Últimos 12 meses, todas as igrejas filtradas (contas das igrejas)">
              {qm.isPending ? <LinhasACarregar linhas={4} /> : qm.isError ? <EstadoErro erro={qm.error} aoTentar={() => qm.refetch()} /> : (
                <GraficoBarras rotulo="Entradas e saídas por mês" categorias={categorias} destaque={categorias.length - 1}
                  series={[{ nome: 'Entradas', slot: 1, valores: meses.map((m) => m.entradas) }, { nome: 'Saídas', slot: 2, valores: meses.map((m) => m.saidas) }]}
                  formatar={(v) => textoMT(v)} />
              )}
            </Cartao>
            <Cartao titulo="Dízimos" descricao="Últimos 12 meses · dizimistas no mês por baixo de cada barra (na tabela)">
              {qm.isPending ? <LinhasACarregar linhas={4} /> : qm.isError ? <EstadoErro erro={qm.error} /> : (
                <GraficoBarras rotulo="Dízimos por mês" categorias={categorias} destaque={categorias.length - 1}
                  series={[{ nome: 'Dízimos', slot: 3, valores: meses.map((m) => m.dizimos) }]} formatar={(v) => textoMT(v)} />
              )}
            </Cartao>
            <Cartao titulo="Movimento de membros" descricao="Admissões (baptismo, profissão de fé) e transferências, últimos 12 meses">
              {qm.isPending ? <LinhasACarregar linhas={4} /> : qm.isError ? <EstadoErro erro={qm.error} /> : (
                <GraficoBarras rotulo="Movimento de membros por mês" categorias={categorias} destaque={categorias.length - 1} inteiros
                  series={[{ nome: 'Admissões', slot: 1, valores: meses.map((m) => m.admissoes) }, { nome: 'Transf. entradas', slot: 3, valores: meses.map((m) => m.te) },
                    { nome: 'Transf. saídas', slot: 2, valores: meses.map((m) => m.ts) }]} formatar={(v) => inteiro(v)} />
              )}
            </Cartao>
            <Cartao titulo="Comparativo entre igrejas" descricao={`${med.rotulo} · a linha marca a média (${formatar(mediaComp)})`}
              accoes={<div className="w-52 print:hidden"><Seleccao aria-label="Medida a comparar" value={medida} onChange={(e) => setMedida(e.target.value as Medida)}>
                {MEDIDAS.map((x) => <option key={x.k} value={x.k}>{x.rotulo}</option>)}
              </Seleccao></div>}>
              {q.isPending ? <LinhasACarregar linhas={5} /> : !comparativo.length ? <EstadoVazio>Sem dados para comparar.</EstadoVazio> : (
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

          <Cartao titulo="Quadro comparativo das igrejas" descricao="Clique no título de uma coluna para ordenar; numa igreja para a abrir">
            {q.isPending ? <LinhasACarregar linhas={6} /> : !linhas.length ? <EstadoVazio>Nenhuma igreja com esse filtro.</EstadoVazio> : (
              <Folha minimo="min-w-[78rem]">
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
                        const sem = (c.area === 'tesouraria' && !l.veTesouraria) || (c.area === 'membros' && !l.veMembros)
                        if (sem) return <td key={c.k} className="num text-xs text-muted-foreground">sem acesso</td>
                        if (c.tipo === 'pct') return <CelulaPct key={c.k} v={l.pctDizimistas} tipo="presenca" />
                        const v = n(l[c.k] as string)
                        return (
                          <td key={c.k} className={cn('num tabular-nums', c.k === 'porRemeter' && v > 0 && 'font-semibold text-destructive-text', c.k === 'saldo' && v < 0 && 'text-destructive-text')}>
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
                      const base = c.area === 'tesouraria' ? comTes : comMem
                      if (c.tipo === 'pct') return <CelulaPct key={c.k} v={activosComTes ? dizimistas / activosComTes : null} />
                      const v = S(base, (l) => n(l[c.k] as string))
                      return <td key={c.k} className="num tabular-nums">{c.tipo === 'mt' ? textoMT(v) : inteiro(v)}</td>
                    })}
                  </tr>
                </tfoot>
              </Folha>
            )}
            <p className="mt-3 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
              <Pilula variante="outline">ano de {new Date().getFullYear()}</Pilula>
              Dizimistas = membros com dízimo confirmado este ano (também os pagos directamente na Missão). Saldo = contas da igreja, sem a conta da Missão.
              Por depositar = parte da Missão dos meses já terminados que ainda não foi depositada.
            </p>
          </Cartao>
        </div>
      )}
    </>
  )
}
