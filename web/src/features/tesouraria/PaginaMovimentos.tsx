/** Movimentos · "O que entrou e saiu neste mês, e o que falta confirmar ou aprovar?" */
import { useMemo } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { ArrowDownRight, ArrowUpRight, Banknote, ChevronLeft, ChevronRight, HandCoins, ListOrdered, ShieldAlert } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Dinheiro, Indicador, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { centimos, data, deCentimos, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { useContas, useMovimentos, type Transacao } from './api'
import { PilulaEstado, Valor, quem } from './comum'

const MESES = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro']

function limitesDoMes(mes: string) {
  const [a, m] = mes.split('-').map(Number)
  const ultimo = new Date(Date.UTC(a, m, 0)).getUTCDate()
  return { desde: `${mes}-01`, ate: `${mes}-${String(ultimo).padStart(2, '0')}`, nome: `${MESES[m - 1]} de ${a}` }
}
function mudarMes(mes: string, d: number) {
  const [a, m] = mes.split('-').map(Number)
  const n = new Date(Date.UTC(a, m - 1 + d, 1))
  return `${n.getUTCFullYear()}-${String(n.getUTCMonth() + 1).padStart(2, '0')}`
}

type Filtro = 'todos' | 'entradas' | 'saidas' | 'pendentes'

export default function PaginaMovimentos() {
  const { pode } = useSessao()
  const navigate = useNavigate()
  const [params, setParams] = useSearchParams()
  const mes = params.get('mes') ?? hojeIso().slice(0, 7)
  const filtro = (params.get('ver') as Filtro) ?? 'todos'
  const { desde, ate, nome } = limitesDoMes(mes)
  const q = useMovimentos({ desde, ate })
  const basicos = useMembrosBasicos()
  const contas = useContas()
  const nomes = useMemo(() => new Map((basicos.data ?? []).map((m) => [m.id, `${m.nome} ${m.apelido}`])), [basicos.data])
  const contaDe = useMemo(() => new Map((contas.data ?? []).map((c) => [c.id, c.nome])), [contas.data])

  const validos = (q.data ?? []).filter((tr) => !tr.endDate)
  const confirmados = validos.filter((tr) => tr.estado === 'CONFIRMADA')
  const soma = (l: Transacao[]) => deCentimos(l.reduce((s, tr) => s + centimos(tr.valorTotal), 0))
  const entradas = confirmados.filter((tr) => tr.tipo === 'ENTRADA')
  const saidas = confirmados.filter((tr) => tr.tipo === 'SAIDA')
  const pendentes = validos.filter((tr) => tr.estado === 'PENDENTE')
  const lista = (q.data ?? []).filter((tr) =>
    filtro === 'entradas' ? tr.tipo === 'ENTRADA' : filtro === 'saidas' ? tr.tipo === 'SAIDA' : filtro === 'pendentes' ? tr.estado === 'PENDENTE' && !tr.endDate : true)

  const definir = (k: string, v?: string) => setParams((p) => { const n = new URLSearchParams(p); if (v) n.set(k, v); else n.delete(k); return n })
  const abas: { k: Filtro; rotulo: string; n: number }[] = [
    { k: 'todos', rotulo: 'Todos', n: (q.data ?? []).length }, { k: 'entradas', rotulo: 'Entradas', n: (q.data ?? []).filter((x) => x.tipo === 'ENTRADA').length },
    { k: 'saidas', rotulo: 'Saídas', n: (q.data ?? []).filter((x) => x.tipo === 'SAIDA').length }, { k: 'pendentes', rotulo: 'Por confirmar', n: pendentes.length },
  ]

  return (
    <>
      <TituloPagina icone={ListOrdered} titulo={t.tesouraria.movimentos} descricao={`Entradas e saídas de ${nome}`}
        accoes={pode('tesouraria.transacao.criar') && (
          <>
            <Button asChild variant="outline" className="alvo"><Link to="/tesouraria/saida"><Banknote className="size-4" />{t.tesouraria.saida}</Link></Button>
            <Button asChild className="alvo"><Link to="/tesouraria/entrada"><HandCoins className="size-4" />{t.tesouraria.entrada}</Link></Button>
          </>
        )} />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4">
          <Indicador rotulo="Entradas" valor={<Dinheiro valor={soma(entradas)} />} nota={`${entradas.length} confirmada(s)`} icone={ArrowDownRight} tom="success" aCarregar={q.isPending} />
          <Indicador rotulo="Saídas" valor={<Dinheiro valor={soma(saidas)} />} nota={`${saidas.length} confirmada(s)`} icone={ArrowUpRight} tom="destructive" aCarregar={q.isPending} />
          <Indicador rotulo="Por confirmar" valor={pendentes.length} nota="pendentes ou por aprovar" icone={ShieldAlert} tom="warning" aCarregar={q.isPending}
            aoClicar={() => definir('ver', 'pendentes')} activo={filtro === 'pendentes'} />
        </div>

        <section className="min-w-0 rounded-xl border bg-card shadow-card">
          <div className="flex flex-wrap items-center gap-3 border-b px-4 py-3 sm:px-6">
            <div className="flex items-center gap-1">
              <Button variant="outline" size="icon" className="alvo size-9" aria-label="Mês anterior" onClick={() => definir('mes', mudarMes(mes, -1))}><ChevronLeft className="size-4" /></Button>
              <span className="min-w-36 text-center text-sm font-medium first-letter:uppercase">{nome}</span>
              <Button variant="outline" size="icon" className="alvo size-9" aria-label="Mês seguinte" disabled={mes >= hojeIso().slice(0, 7)} onClick={() => definir('mes', mudarMes(mes, 1))}><ChevronRight className="size-4" /></Button>
            </div>
            <div role="tablist" aria-label="Filtrar" className="flex flex-wrap gap-1 rounded-lg bg-muted p-1">
              {abas.map((a) => (
                <button key={a.k} role="tab" aria-selected={filtro === a.k} type="button" onClick={() => definir('ver', a.k === 'todos' ? undefined : a.k)}
                  className={cn('alvo rounded-md px-3 py-1.5 text-xs font-medium text-muted-foreground', filtro === a.k && 'bg-card text-foreground shadow-sm')}>
                  {a.rotulo} <span className="num ml-1 opacity-70">{a.n}</span>
                </button>
              ))}
            </div>
          </div>
          {q.isPending ? <LinhasACarregar linhas={6} />
            : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="m-4" />
            : lista.length === 0 ? <EstadoVazio icone={ListOrdered} titulo="Sem movimentos">{filtro === 'todos' ? `Nada registado em ${nome}.` : 'Nada com este filtro neste mês.'}</EstadoVazio>
            : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Data</th><th>Movimento</th><th className="hidden md:table-cell">Conta</th><th>Estado</th><th className="num sm:pr-6">Valor</th></tr></thead>
                <tbody>
                  {lista.map((tr) => (
                    <tr key={tr.id} onClick={() => navigate(`/tesouraria/movimentos/${tr.id}`)} className={cn('cursor-pointer', tr.endDate && 'opacity-60')}>
                      <td className="tabular-nums whitespace-nowrap text-muted-foreground sm:pl-6">{data(tr.dataHora)}</td>
                      <td>
                        <Link to={`/tesouraria/movimentos/${tr.id}`} onClick={(e) => e.stopPropagation()} className="font-medium hover:text-primary">{quem(tr, (id) => nomes.get(id))}</Link>
                        <p className="text-xs text-muted-foreground">{rotulos.tipoTransacao[tr.tipo]} · {rotulos.metodo[tr.metodo ?? ''] ?? tr.metodo}{tr.descricao ? ` · ${tr.descricao}` : ''}</p>
                      </td>
                      <td className="hidden text-muted-foreground md:table-cell">{tr.contaId ? contaDe.get(tr.contaId) : '—'}</td>
                      <td><PilulaEstado tr={tr} /></td>
                      <td className="num sm:pr-6"><Valor tr={tr} /></td>
                    </tr>
                  ))}
                </tbody>
              </Tabela>
            )}
        </section>
      </div>
    </>
  )
}
