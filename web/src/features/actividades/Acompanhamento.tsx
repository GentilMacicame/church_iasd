/**
 * Acompanhamento das actividades (F-ACT; V48) · "O programa está a ser cumprido e dentro do orçamento?"
 * Serve a igreja (comparação entre departamentos, com a área pastoral) e o distrito (comparação entre igrejas):
 *  - o progresso do ano: realizadas, em curso, por realizar, atrasadas (a data passou e ainda está planeada), canceladas;
 *  - o orçamento: previsto (actividades não canceladas), despesas aprovadas e executado (saídas da tesouraria);
 *  - mês a mês: programadas, realizadas e canceladas;
 *  - a comparação por departamento ou por igreja; as atrasadas (para agir) e as canceladas, com o motivo.
 */
import { Link } from 'react-router-dom'
import { AlarmClock, CircleCheck, CircleSlash, Coins, ListChecks, PlayCircle } from 'lucide-react'
import { Cartao, Indicador, Pilula, Tabela } from '@/components/comum/elementos'
import { EstadoVazio } from '@/components/comum/estados'
import { GraficoBarras } from '@/components/comum/graficos'
import { data, dinheiro, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import type { LinhaPrograma } from './api'

const MESES = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']
const n = (v?: string | number | null) => Number(v ?? 0) || 0
const pct = (a: number, b: number) => (b > 0 ? `${Math.round((a / b) * 100)}%` : '—')
const mt = (v: number) => dinheiro(v.toFixed(2))

export type LinhaAcompanhamento = LinhaPrograma & { grupo: string }

/** Atrasada: a data já passou e continua planeada (nem começou, nem foi cancelada). */
const atrasada = (x: LinhaPrograma, hoje = hojeIso()) => x.estado === 'PLANEADA' && (x.dataFim ?? x.dataInicio).slice(0, 10) < hoje

function resumo(l: LinhaPrograma[]) {
  const hoje = hojeIso()
  const validas = l.filter((x) => x.estado !== 'CANCELADA')
  return {
    total: l.length,
    concluidas: l.filter((x) => x.estado === 'CONCLUIDA').length,
    emCurso: l.filter((x) => x.estado === 'EM_CURSO').length,
    atrasadas: l.filter((x) => atrasada(x, hoje)).length,
    porRealizar: l.filter((x) => x.estado === 'PLANEADA' && !atrasada(x, hoje)).length,
    canceladas: l.filter((x) => x.estado === 'CANCELADA').length,
    previsto: validas.reduce((s, x) => s + n(x.valorPrevisto), 0),
    aprovado: validas.reduce((s, x) => s + n(x.despesasAprovadas), 0),
    executado: l.reduce((s, x) => s + n(x.executado), 0),
  }
}

export function Acompanhamento({ linhas, rotuloGrupo, ano }: { linhas: LinhaAcompanhamento[]; rotuloGrupo?: string; ano: number }) {
  if (!linhas.length) return <Cartao><EstadoVazio icone={ListChecks} titulo="Sem actividades">Ainda não há actividades programadas em {ano}.</EstadoVazio></Cartao>
  const r = resumo(linhas)
  const validas = r.total - r.canceladas
  const hoje = hojeIso()
  const atrasadas = linhas.filter((x) => atrasada(x, hoje)).sort((a, b) => a.dataInicio.localeCompare(b.dataInicio))
  const canceladas = linhas.filter((x) => x.estado === 'CANCELADA').sort((a, b) => b.dataInicio.localeCompare(a.dataInicio))
  const grupos = rotuloGrupo ? [...new Set(linhas.map((x) => x.grupo))].map((g) => ({ g, ...resumo(linhas.filter((x) => x.grupo === g)) }))
    .sort((a, b) => b.total - a.total) : []
  const porMes = MESES.map((_, i) => linhas.filter((x) => x.mes === i + 1))
  const partes = [
    { r: 'Realizadas', v: r.concluidas, cor: 'bg-success' }, { r: 'Em curso', v: r.emCurso, cor: 'bg-[var(--serie-1)]' },
    { r: 'Por realizar', v: r.porRealizar, cor: 'bg-[var(--serie-3)]' }, { r: 'Atrasadas', v: r.atrasadas, cor: 'bg-warning' },
    { r: 'Canceladas', v: r.canceladas, cor: 'bg-muted-foreground/40' },
  ]

  return (
    <div className="grid gap-6">
      <div className="grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-4">
        <Indicador rotulo="Realizadas" valor={`${r.concluidas} de ${validas}`} icone={CircleCheck} tom="success" nota={`${pct(r.concluidas, validas)} do programa (sem as canceladas)`} />
        <Indicador rotulo="Atrasadas" valor={r.atrasadas} icone={AlarmClock} tom={r.atrasadas ? 'destructive' : 'success'} destaque={r.atrasadas > 0}
          nota={r.atrasadas ? 'a data passou e continuam planeadas' : 'nenhuma em atraso'} />
        <Indicador rotulo="Canceladas" valor={r.canceladas} icone={CircleSlash} tom="warning" nota={`${pct(r.canceladas, r.total)} das programadas · ${r.emCurso} em curso`} />
        <Indicador rotulo="Orçamento executado" valor={pct(r.executado, r.previsto)} icone={Coins} tom="info"
          nota={`${mt(r.executado)} de ${mt(r.previsto)} · aprovado ${mt(r.aprovado)}`} />
      </div>

      <Cartao titulo={`Progresso do programa · ${ano}`} descricao={`${r.total} actividades programadas`} icone={PlayCircle}>
        <div className="flex h-3 overflow-hidden rounded-full bg-muted" role="img" aria-label={partes.map((p) => `${p.v} ${p.r.toLowerCase()}`).join(', ')}>
          {partes.map((p) => p.v > 0 && <div key={p.r} className={p.cor} style={{ width: `${(p.v / r.total) * 100}%` }} />)}
        </div>
        <ul className="mt-3 flex flex-wrap gap-x-5 gap-y-1.5 text-sm">
          {partes.map((p) => (
            <li key={p.r} className="flex items-center gap-1.5"><span className={cn('size-2.5 rounded-[3px]', p.cor)} />{p.r} <strong className="tabular-nums">{p.v}</strong></li>
          ))}
        </ul>
        <div className="mt-5">
          <GraficoBarras rotulo="Actividades por mês" altura={200} inteiros categorias={MESES} formatar={(v) => String(v)}
            destaque={Number(hoje.slice(0, 4)) === ano ? Number(hoje.slice(5, 7)) - 1 : undefined}
            series={[{ nome: 'Programadas', slot: 1, valores: porMes.map((l) => l.filter((x) => x.estado !== 'CANCELADA').length) },
              { nome: 'Realizadas', slot: 3, valores: porMes.map((l) => l.filter((x) => x.estado === 'CONCLUIDA').length) },
              { nome: 'Canceladas', slot: 'neutra', valores: porMes.map((l) => l.filter((x) => x.estado === 'CANCELADA').length) }]} />
        </div>
      </Cartao>

      {grupos.length > 1 && (
        <Cartao titulo={`Comparação por ${rotuloGrupo}`} descricao="Cumprimento do programa e execução do orçamento" semMargem>
          <Tabela>
            <thead>
              <tr>
                <th className="sm:pl-6">{rotuloGrupo === 'igreja' ? 'Igreja' : 'Departamento'}</th><th className="num">Actividades</th><th>Realizadas</th>
                <th className="num">Atrasadas</th><th className="num hidden md:table-cell">Canceladas</th>
                <th className="num hidden lg:table-cell">Previsto</th><th className="num hidden lg:table-cell">Executado</th><th className="sm:pr-6">Orçamento</th>
              </tr>
            </thead>
            <tbody>
              {grupos.map((x) => (
                <tr key={x.g}>
                  <td className="font-medium sm:pl-6">{x.g}</td>
                  <td className="num">{x.total}</td>
                  <td><Barra v={x.concluidas} de={x.total - x.canceladas} cor="bg-success" /></td>
                  <td className={cn('num', x.atrasadas > 0 && 'font-semibold text-destructive-text')}>{x.atrasadas}</td>
                  <td className="num hidden md:table-cell">{x.canceladas}</td>
                  <td className="num hidden lg:table-cell">{mt(x.previsto)}</td>
                  <td className="num hidden lg:table-cell">{mt(x.executado)}</td>
                  <td className="sm:pr-6"><Barra v={x.executado} de={x.previsto} cor={x.executado > x.previsto ? 'bg-destructive' : 'bg-[var(--serie-1)]'} /></td>
                </tr>
              ))}
            </tbody>
          </Tabela>
        </Cartao>
      )}

      <div className="grid gap-6 lg:grid-cols-2">
        <Cartao titulo="Atrasadas" descricao="A data passou e continuam planeadas" icone={AlarmClock} semMargem>
          {!atrasadas.length ? <EstadoVazio icone={CircleCheck}>Nenhuma actividade em atraso.</EstadoVazio> : (
            <ul className="divide-y">
              {atrasadas.slice(0, 8).map((x) => (
                <li key={`${x.id}-${x.grupo}`} className="flex items-center gap-3 px-4 py-2.5 sm:px-6">
                  <Link to={`/actividades/${x.id}`} className="min-w-0 flex-1 truncate font-medium hover:text-primary">{x.nome}</Link>
                  <span className="text-xs text-muted-foreground">{x.grupo} · {data(x.dataInicio)}</span>
                </li>
              ))}
            </ul>
          )}
        </Cartao>
        <Cartao titulo="Canceladas" descricao="Com o motivo" icone={CircleSlash} semMargem>
          {!canceladas.length ? <EstadoVazio icone={CircleCheck}>Nenhuma actividade cancelada.</EstadoVazio> : (
            <ul className="divide-y">
              {canceladas.slice(0, 8).map((x) => (
                <li key={`${x.id}-${x.grupo}`} className="grid gap-0.5 px-4 py-2.5 sm:px-6">
                  <span className="flex items-center gap-2">
                    <Link to={`/actividades/${x.id}`} className="min-w-0 flex-1 truncate font-medium hover:text-primary">{x.nome}</Link>
                    <Pilula variante="secondary">{data(x.dataInicio)}</Pilula>
                  </span>
                  <span className="text-xs text-muted-foreground">{x.grupo} · {x.motivoCancelamento ?? 'sem motivo registado'}</span>
                </li>
              ))}
            </ul>
          )}
        </Cartao>
      </div>
    </div>
  )
}

function Barra({ v, de, cor }: { v: number; de: number; cor: string }) {
  return (
    <span className="flex items-center gap-2">
      <span className="h-1.5 w-20 overflow-hidden rounded-full bg-muted" aria-hidden>
        <span className={cn('block h-full rounded-full', cor)} style={{ width: `${de > 0 ? Math.min(100, (v / de) * 100) : 0}%` }} />
      </span>
      <span className="w-10 text-right text-xs tabular-nums">{pct(v, de)}</span>
    </span>
  )
}
