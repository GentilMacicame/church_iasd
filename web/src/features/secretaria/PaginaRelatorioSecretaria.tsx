/**
 * Relatório da secretaria (F-SEC-10) · "Quantos entraram, quantos saíram, e o que falta resolver?"
 * O que o secretário envia à Associação/Missão:
 *  1. o ano num relance: membros no início do ano, entradas, saídas, activos hoje e o crescimento;
 *  2. entradas e saídas mês a mês (gráfico) e de onde vieram / para onde foram (por tipo);
 *  3. o quadro do livro de membros mês a mês, com entradas e saídas agrupadas e o total;
 *  4. membros por estado e o que está pendente (transferências, censuras, menores).
 * Tudo vem do livro de membros (vistas da base de dados). Imprime-se com as assinaturas.
 */
import { useMemo, type ComponentType } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { AlertTriangle, ArrowDownLeft, ArrowUpRight, BarChart3, ChevronRight, Gavel, Mail, Printer, ShieldAlert, TrendingUp, UserMinus, UserPlus, Users } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Cartao, Indicador, Pilula, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro } from '@/components/comum/estados'
import { Seleccao } from '@/components/comum/Seleccao'
import { GraficoBarras } from '@/components/comum/graficos'
import { CabecalhoDocumento } from '@/components/layout/Marca'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos } from '@/i18n/pt-MZ'
import { data, idade } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { imprimirComo } from '@/lib/documentos'
import { Exportar } from '@/components/comum/Exportar'
import { useMembrosBasicos } from '@/features/membros/api'
import { Folha } from '@/features/escola-sabatina/componentes'
import { useCensurasActivas, useMenoresPendentes, useRelatorioMensalSecretaria, useTransferencias, type LinhaRelatorioMensal } from './api'

const MESES = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro']
type Campo = keyof LinhaRelatorioMensal
const ENTRADAS: { campo: Campo; r: string }[] = [
  { campo: 'baptismos', r: 'Baptismos' },
  { campo: 'rebaptismos', r: 'Rebaptismos' },
  { campo: 'profissoesDeFe', r: 'Profissões de fé' },
  { campo: 'transferenciasEntrada', r: 'Transf. recebidas' },
]
const SAIDAS: { campo: Campo; r: string }[] = [
  { campo: 'transferenciasSaida', r: 'Transf. enviadas' },
  { campo: 'falecimentos', r: 'Falecimentos' },
  { campo: 'remocoes', r: 'Remoções' },
  { campo: 'desaparecidos', r: 'Desaparecidos' },
]
const CORES_ESTADO: Record<string, string> = {
  ACTIVO: 'bg-primary', INTERESSADO: 'bg-success', TRANSFERIDO: 'bg-info', FALECIDO: 'bg-muted-foreground', REMOVIDO: 'bg-destructive', DESAPARECIDO: 'bg-warning',
}

/** Lista de barras horizontais (por tipo), com o número e a fatia do total. */
function Barras({ itens, tom }: { itens: { r: string; n: number }[]; tom: 'success' | 'destructive' }) {
  const total = itens.reduce((s, x) => s + x.n, 0)
  const max = Math.max(1, ...itens.map((x) => x.n))
  return (
    <ul className="grid gap-3">
      {itens.map((x) => (
        <li key={x.r} className="grid gap-1">
          <div className="flex items-baseline justify-between gap-3 text-sm">
            <span className={cn(!x.n && 'text-muted-foreground')}>{x.r}</span>
            <span className="tabular-nums"><strong className="font-semibold">{x.n}</strong>{total > 0 && <span className="ml-1.5 text-xs text-muted-foreground">{Math.round((x.n / total) * 100)}%</span>}</span>
          </div>
          <div className="h-2 overflow-hidden rounded-full bg-muted">
            <div className={cn('h-full rounded-full', tom === 'success' ? 'bg-success' : 'bg-destructive')} style={{ width: `${(x.n / max) * 100}%` }} />
          </div>
        </li>
      ))}
    </ul>
  )
}

function LinhaPendente({ icone: I, rotulo, n, para, tom = 'warning' }: { icone: ComponentType<{ className?: string }>; rotulo: string; n: number | null; para?: string; tom?: 'warning' | 'destructive' }) {
  const conteudo = (
    <>
      <span className={cn('flex size-8 flex-none items-center justify-center rounded-lg', n ? (tom === 'destructive' ? 'bg-tint-destructive text-destructive-text' : 'bg-tint-warning text-warning-text') : 'bg-muted text-muted-foreground')}>
        <I className="size-4" />
      </span>
      <span className="min-w-0 flex-1 text-sm">{rotulo}</span>
      <span className={cn('text-lg font-bold tabular-nums', !n && 'text-muted-foreground')}>{n ?? '—'}</span>
      {para && <ChevronRight className="size-4 text-muted-foreground" aria-hidden />}
    </>
  )
  return para
    ? <Link to={para} className="alvo flex items-center gap-3 px-5 py-3 hover:bg-muted/50 sm:px-6">{conteudo}</Link>
    : <div className="flex items-center gap-3 px-5 py-3 sm:px-6">{conteudo}</div>
}

export default function PaginaRelatorioSecretaria() {
  const igreja = useIgreja()
  const { pode } = useSessao()
  const rel = useRelatorioMensalSecretaria()
  const membros = useMembrosBasicos()
  const menores = useMenoresPendentes()
  const censuras = useCensurasActivas()
  const transf = useTransferencias()
  const [params, setParams] = useSearchParams()
  const anoActual = new Date().getFullYear()
  const mesActual = new Date().getMonth()
  const ano = Number(params.get('ano')) || anoActual
  const anos = useMemo(() => [...new Set([anoActual, ...(rel.data ?? []).map((l) => l.ano)])].sort((a, b) => b - a), [rel.data, anoActual])

  const doAno = new Map((rel.data ?? []).filter((l) => l.ano === ano).map((l) => [l.mes, l]))
  const valor = (mes: number, c: Campo) => Number(doAno.get(mes)?.[c] ?? 0)
  const total = (c: Campo) => [...doAno.values()].reduce((s, l) => s + Number(l[c] ?? 0), 0)
  const entradasMes = (m: number) => ENTRADAS.reduce((s, c) => s + valor(m, c.campo), 0)
  const saidasMes = (m: number) => SAIDAS.reduce((s, c) => s + valor(m, c.campo), 0)
  const entradas = ENTRADAS.reduce((s, c) => s + total(c.campo), 0)
  const saidas = SAIDAS.reduce((s, c) => s + total(c.campo), 0)
  const lista = membros.data ?? []
  const activos = lista.filter((m) => m.estado === 'ACTIVO')
  // membros no início do ano = activos hoje − variação desde 1 de Janeiro desse ano (o estado só muda pelo livro)
  const variacaoDesde = (rel.data ?? []).filter((l) => l.ano >= ano).reduce((s, l) => s + Number(l.variacao), 0)
  const inicioAno = activos.length - variacaoDesde
  const fimAno = inicioAno + entradas - saidas
  const crescimento = inicioAno > 0 ? (entradas - saidas) / inicioAno : null
  const porEstado = Object.entries(lista.reduce<Record<string, number>>((a, m) => ({ ...a, [m.estado]: (a[m.estado] ?? 0) + 1 }), {})).sort((a, b) => b[1] - a[1])
  const homens = activos.filter((m) => m.sexo === 'M').length, mulheres = activos.filter((m) => m.sexo === 'F').length
  const porConcluir = (transf.data ?? []).filter((x) => x.estado === 'PEDIDA' || x.estado === 'CARTA_EMITIDA')
  const ultimoMes = ano === anoActual ? mesActual + 1 : 12
  const sinal = (n: number) => (n > 0 ? `+${n}` : n < 0 ? `−${Math.abs(n)}` : '0')

  if (rel.isPending || membros.isPending) return <Barra className="h-96 w-full" />
  if (rel.isError) return <EstadoErro erro={rel.error} aoTentar={() => rel.refetch()} />

  return (
    <div className="documento-relatorio">
      <TituloPagina icone={BarChart3} titulo="Relatório da secretaria" descricao={`Livro de membros de ${ano}: quem entrou, quem saiu e o que falta resolver`}
        accoes={(
          <div className="flex items-center gap-2 print:hidden">
            <Seleccao aria-label="Ano" value={String(ano)} onChange={(e) => setParams({ ano: e.target.value })} className="w-28">
              {anos.map((a) => <option key={a} value={a}>{a}</option>)}
            </Seleccao>
            <Exportar caminho="/v1/secretaria/relatorio-mensal" query={{ igrejaId: igreja.id, ano }} nome={`movimento-do-livro-${ano}`} />
            <Button variant="outline" className="alvo" onClick={() => imprimirComo(`Relatório da secretaria ${ano} - ${igreja.nome}`)}><Printer className="size-4" />Imprimir</Button>
          </div>
        )} />
      <CabecalhoDocumento titulo={`${igreja.nome} — Relatório da secretaria de ${ano}`} linha="Secretaria" className="mb-6 hidden print:flex" />

      <div className="grid gap-6">
        {/* 1. o ano num relance */}
        <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
          <Indicador rotulo={`Membros a 1 de Janeiro`} valor={String(inicioAno)} icone={Users} nota={`início de ${ano}, pelo livro`} />
          <Indicador rotulo="Entraram" valor={sinal(entradas)} icone={UserPlus} tom="success" nota={`${total('baptismos') + total('rebaptismos')} baptismos · ${total('transferenciasEntrada')} transferências`} />
          <Indicador rotulo="Saíram" valor={saidas ? `−${saidas}` : '0'} icone={UserMinus} tom="destructive" nota={`${total('transferenciasSaida')} transferências · ${total('falecimentos')} falecimentos`} />
          <Indicador rotulo={ano === anoActual ? 'Membros activos hoje' : `Membros no fim de ${ano}`} valor={String(ano === anoActual ? activos.length : fimAno)} icone={TrendingUp}
            tom={crescimento != null && crescimento < 0 ? 'warning' : 'primary'}
            nota={<>{crescimento != null && <strong className={cn('font-semibold', crescimento >= 0 ? 'text-success-text' : 'text-destructive-text')}>{crescimento >= 0 ? '+' : ''}{(crescimento * 100).toLocaleString('pt-PT', { maximumFractionDigits: 1 })}% no ano</strong>}{ano === anoActual && <> · {homens} H · {mulheres} M</>}</>} />
        </div>

        {/* 2. mês a mês e por tipo */}
        <div className="grid items-stretch gap-6 lg:grid-cols-12">
          <Cartao className="lg:col-span-7" titulo="Entradas e saídas, mês a mês" descricao={`Livro de membros de ${ano}`}>
            <GraficoBarras rotulo={`Entradas e saídas do livro de membros em ${ano}`} inteiros altura={420}
              categorias={MESES.map((m) => m.slice(0, 3).toLowerCase())} destaque={ano === anoActual ? mesActual : undefined}
              series={[{ nome: 'Entradas', slot: 1, valores: MESES.map((_, i) => entradasMes(i + 1)) }, { nome: 'Saídas', slot: 2, valores: MESES.map((_, i) => saidasMes(i + 1)) }]}
              formatar={(v) => String(v)} />
          </Cartao>
          <div className="grid gap-6 lg:col-span-5">
            <Cartao titulo="De onde vieram" descricao={`${entradas} entrada(s) com o voto da igreja`} icone={ArrowDownLeft}>
              <Barras tom="success" itens={ENTRADAS.map((c) => ({ r: c.r, n: total(c.campo) }))} />
            </Cartao>
            <Cartao titulo="Para onde foram" descricao={`${saidas} saída(s)`} icone={ArrowUpRight}>
              <Barras tom="destructive" itens={SAIDAS.map((c) => ({ r: c.r, n: total(c.campo) }))} />
            </Cartao>
          </div>
        </div>

        {/* 3. o quadro do livro mês a mês */}
        <Cartao titulo={`Livro de membros em ${ano}, mês a mês`} descricao="O quadro que se envia à Associação/Missão">
          <Folha minimo="min-w-[56rem]" className="[&_tbody_td]:px-2.5! [&_thead_th]:px-2.5! [&_tfoot_td]:px-2.5!">
            <thead>
              <tr>
                <th rowSpan={2} className="text-left">Mês</th>
                <th colSpan={ENTRADAS.length + 1} className="centro">Entradas</th>
                <th colSpan={SAIDAS.length + 1} className="centro">Saídas</th>
                <th rowSpan={2} className="num">Saldo</th>
              </tr>
              <tr>
                {ENTRADAS.map((c) => <th key={c.campo} className="num">{c.r}</th>)}
                <th className="num">Total</th>
                {SAIDAS.map((c) => <th key={c.campo} className="num">{c.r}</th>)}
                <th className="num">Total</th>
              </tr>
            </thead>
            <tbody>
              {MESES.map((nome, i) => {
                const m = i + 1
                const futuro = m > ultimoMes
                const e = entradasMes(m), s = saidasMes(m)
                const n = (v: number) => (v ? v : <span className="text-muted-foreground/40">—</span>)
                return (
                  <tr key={nome} className={cn(futuro && 'text-muted-foreground/60')}>
                    <td className="font-medium">{nome}</td>
                    {ENTRADAS.map((c) => <td key={c.campo} className="num tabular-nums">{n(valor(m, c.campo))}</td>)}
                    <td className={cn('num font-semibold tabular-nums', e > 0 && 'bg-tint-success/60 text-success-text')}>{n(e)}</td>
                    {SAIDAS.map((c) => <td key={c.campo} className="num tabular-nums">{n(valor(m, c.campo))}</td>)}
                    <td className={cn('num font-semibold tabular-nums', s > 0 && 'bg-tint-destructive/60 text-destructive-text')}>{n(s)}</td>
                    <td className={cn('num font-semibold tabular-nums', e - s > 0 && 'text-success-text', e - s < 0 && 'text-destructive-text')}>{futuro && !e && !s ? '' : sinal(e - s)}</td>
                  </tr>
                )
              })}
            </tbody>
            <tfoot>
              <tr>
                <td>Total</td>
                {ENTRADAS.map((c) => <td key={c.campo} className="num tabular-nums">{total(c.campo)}</td>)}
                <td className={cn('num tabular-nums', entradas > 0 && 'text-success-text')}>{entradas}</td>
                {SAIDAS.map((c) => <td key={c.campo} className="num tabular-nums">{total(c.campo)}</td>)}
                <td className={cn('num tabular-nums', saidas > 0 && 'text-destructive-text')}>{saidas}</td>
                <td className={cn('num tabular-nums', entradas - saidas > 0 && 'text-success-text', entradas - saidas < 0 && 'text-destructive-text')}>{sinal(entradas - saidas)}</td>
              </tr>
            </tfoot>
          </Folha>
          <p className="mt-3 text-xs text-muted-foreground">
            Membros a 1 de Janeiro: {inicioAno} · entraram {entradas} · saíram {saidas} · {ano === anoActual ? 'hoje' : `a 31 de Dezembro`}: {ano === anoActual ? activos.length : fimAno}.
            Cada entrada e saída está no livro de membros com o voto que a autoriza.
          </p>
        </Cartao>

        {/* 4. estado e pendentes */}
        <div className="grid items-start gap-6 lg:grid-cols-2">
          <Cartao titulo="Membros por estado" descricao={`${lista.length} registo(s) no livro desta igreja`} icone={Users}>
            <div className="mb-4 flex h-3 overflow-hidden rounded-full bg-muted" aria-hidden>
              {porEstado.map(([e, n]) => <div key={e} className={cn('h-full', CORES_ESTADO[e] ?? 'bg-muted-foreground')} style={{ width: `${(n / Math.max(1, lista.length)) * 100}%` }} />)}
            </div>
            <ul className="grid gap-2 text-sm">
              {porEstado.map(([e, n]) => (
                <li key={e} className="flex items-center gap-2">
                  <span className={cn('size-2.5 flex-none rounded-sm', CORES_ESTADO[e] ?? 'bg-muted-foreground')} aria-hidden />
                  <span className="flex-1">{rotulos.estadoMembroPlural?.[e as never] ?? rotulos.estadoMembro[e as never] ?? e}</span>
                  <strong className="font-semibold tabular-nums">{n}</strong>
                  <span className="w-12 text-right text-xs tabular-nums text-muted-foreground">{Math.round((n / Math.max(1, lista.length)) * 100)}%</span>
                </li>
              ))}
            </ul>
          </Cartao>
          <Cartao titulo="Pendentes" descricao="O que a secretaria tem de resolver" icone={AlertTriangle} semMargem>
            <div className="divide-y border-t">
              <LinhaPendente icone={Mail} rotulo="Transferências por concluir" n={pode('secretaria.transferencia_membro.ler') ? porConcluir.length : null} para={pode('secretaria.transferencia_membro.ler') ? '/transferencias' : undefined} />
              <LinhaPendente icone={Gavel} rotulo="Membros em censura" n={pode('secretaria.disciplina.ler') ? censuras.data?.length ?? null : null} para={pode('secretaria.disciplina.ler') ? '/disciplina' : undefined} tom="destructive" />
              <LinhaPendente icone={ShieldAlert} rotulo="Menores sem encarregado ou consentimento" n={menores.data?.length ?? null} />
              {!!menores.data?.length && (
                <ul className="grid gap-1.5 bg-muted/20 px-5 py-3 text-sm sm:px-6">
                  {menores.data.slice(0, 8).map((m) => (
                    <li key={m.id} className="flex flex-wrap items-center justify-between gap-2">
                      <Link to={`/membros/${m.id}`} className="hover:text-primary hover:underline">{m.nome} {m.apelido} <span className="text-xs text-muted-foreground">({idade(m.dataNascimento)} anos, {data(m.dataNascimento)})</span></Link>
                      <span className="flex gap-1">
                        {m.faltaEncarregado && <Pilula variante="warning">sem encarregado</Pilula>}
                        {m.faltaConsentimento && <Pilula variante="warning">sem consentimento</Pilula>}
                      </span>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </Cartao>
        </div>
        <div className="mt-6 hidden grid-cols-2 gap-16 text-center text-sm print:grid">
          <div className="border-t border-black pt-1">O secretário da igreja</div>
          <div className="border-t border-black pt-1">O pastor</div>
        </div>
      </div>
    </div>
  )
}
