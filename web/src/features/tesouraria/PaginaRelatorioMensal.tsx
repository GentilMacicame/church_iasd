/**
 * Relatório mensal para a Missão (P-09 passo 4) · "O que se entrega à Missão com o depósito do mês?"
 * Por fundo da Missão: quanto entrou, quanto lhe cabe (dízimo 100%, oferta combinada 50%, ...), o que os membros
 * pagaram directamente na conta da Missão, o que foi depositado e o que falta. Depois, a lista dos recibos: cada
 * membro, o recibo e o valor em cada fundo; as ofertas sem nome (salva) numa linha. Imprime-se em A4 e segue com
 * o talão do depósito.
 */
import { useMemo } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { ChevronLeft, ChevronRight, FileText, Printer } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Cartao, Dinheiro, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { useIgreja } from '@/auth/sessao'
import { centimos, data, deCentimos, dinheiro, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { useContribuicoesDoMes, useEntidades, useFundos, useRemessas, useRemessasDevidas, useTransacao } from './api'
import { parteDoFundo } from './comum'
import { nomeMes } from './PaginaRemessas'
import type { RemessaComLinhas } from './api'

/** Um depósito do mês na conta da Missão, com o talão (a referência da saída). */
function Deposito({ remessa, entidade, complementar }: { remessa: RemessaComLinhas; entidade: string; complementar: boolean }) {
  const tr = useTransacao(remessa.transacaoId ?? 0)
  const total = deCentimos(remessa.linhas.filter((l) => !l.endDate).reduce((s, l) => s + centimos(l.valor), 0))
  return (
    <p className="mb-1">
      {complementar ? 'Depósito complementar' : 'Depositado'} em {data(remessa.enviadaEm)} na conta de {entidade}: <strong className="num">{dinheiro(total)}</strong>
      {tr.data?.referencia ? <> · talão n.º <strong className="num">{tr.data.referencia}</strong></> : null}
      {' '}<Pilula variante={remessa.estado === 'CONFIRMADA' ? 'success' : 'info'} className="ml-1 print:hidden">{remessa.estado === 'CONFIRMADA' ? 'Confirmada pela Missão' : 'Enviada'}</Pilula>
    </p>
  )
}

function mudarMes(mes: string, d: number) {
  const [a, m] = mes.split('-').map(Number)
  const n = new Date(Date.UTC(a, m - 1 + d, 1))
  return `${n.getUTCFullYear()}-${String(n.getUTCMonth() + 1).padStart(2, '0')}`
}

export default function PaginaRelatorioMensal() {
  const igreja = useIgreja()
  const [params, setParams] = useSearchParams()
  const anterior = mudarMes(hojeIso().slice(0, 7), -1)
  const mes = params.get('mes') ?? anterior
  const [ano, m] = mes.split('-').map(Number)
  const devidas = useRemessasDevidas()
  const contrib = useContribuicoesDoMes(ano, m)
  const remessas = useRemessas()
  const fundos = useFundos()
  const entidades = useEntidades()
  const basicos = useMembrosBasicos()
  const nomes = useMemo(() => new Map((basicos.data ?? []).map((x) => [x.id, `${x.nome} ${x.apelido}`])), [basicos.data])

  const resumo = (devidas.data ?? []).filter((d) => d.ano === ano && d.mes === m)
  const idsMissao = new Set(resumo.map((d) => d.fundoId))
  const colunas = resumo.map((d) => ({ id: d.fundoId, nome: d.fundoNome }))
  const depositos = (remessas.data ?? []).filter((r) => !r.endDate && r.ano === ano && r.mes === m && r.estado !== 'PREPARADA')
    .sort((a, b) => a.id - b.id)
  const entidadeNome = entidades.data?.find((e) => e.id === resumo[0]?.entidadeId)?.nome ?? 'Missão'

  // uma linha por contribuição (recibo), só com os fundos da Missão
  const linhas = useMemo(() => {
    const porTra = new Map<number, { id: number; membroId: number | null; data: string; recibo: string | null; naMissao: boolean; referencia: string | null; estorno: boolean; valores: Map<number, number> }>()
    for (const c of contrib.data ?? []) {
      if (!idsMissao.has(c.fundoId)) continue
      const l = porTra.get(c.id) ?? { id: c.id, membroId: c.membroId, data: c.dataHora, recibo: c.numero ? `${c.numero}/${c.ano}` : null, naMissao: !!c.pagoNaMissao, referencia: c.referencia, estorno: c.estorno, valores: new Map() }
      l.valores.set(c.fundoId, (l.valores.get(c.fundoId) ?? 0) + centimos(c.valor))
      porTra.set(c.id, l)
    }
    return [...porTra.values()].sort((a, b) => a.data.localeCompare(b.data) || a.id - b.id)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [contrib.data, devidas.data, ano, m])
  const somaNomeados = (fid: number) => linhas.reduce((s, l) => s + (l.valores.get(fid) ?? 0), 0)
  const anonimas = colunas.map((c) => centimos(resumo.find((d) => d.fundoId === c.id)?.recebido ?? '0') - somaNomeados(c.id))
  const temAnonimas = anonimas.some((v) => v !== 0)
  const total = (l: Map<number, number>) => [...l.values()].reduce((s, v) => s + v, 0)
  const soma = (campo: 'recebido' | 'devido' | 'pagoDirecto' | 'remetido' | 'emFalta') => deCentimos(resumo.reduce((s, d) => s + centimos(d[campo]), 0))
  const valor = (c: number) => (c === 0 ? '—' : dinheiro(deCentimos(c)))
  const aCarregar = devidas.isPending || contrib.isPending || fundos.isPending
  const falha = devidas.error ?? contrib.error

  return (
    <>
      <div className="print:hidden">
        <TituloPagina icone={FileText} titulo="Relatório mensal para a Missão" descricao="Segue com o depósito do mês: o resumo por fundo e os recibos de cada membro"
          accoes={<Button className="alvo" onClick={() => window.print()} disabled={aCarregar || !resumo.length}><Printer className="size-4" />Imprimir</Button>} />
        <div className="mb-6 flex items-center gap-1">
          <Button variant="outline" size="icon" className="alvo size-9" aria-label="Mês anterior" onClick={() => setParams({ mes: mudarMes(mes, -1) })}><ChevronLeft className="size-4" /></Button>
          <span className="min-w-40 text-center text-sm font-medium first-letter:uppercase">{nomeMes(ano, m)}</span>
          <Button variant="outline" size="icon" className="alvo size-9" aria-label="Mês seguinte" disabled={mes >= hojeIso().slice(0, 7)} onClick={() => setParams({ mes: mudarMes(mes, 1) })}><ChevronRight className="size-4" /></Button>
        </div>
      </div>

      {aCarregar ? <Barra className="h-80 w-full" />
        : falha ? <EstadoErro erro={falha} aoTentar={() => { devidas.refetch(); contrib.refetch() }} />
        : !resumo.length ? (
          <div className="rounded-xl border bg-card shadow-card">
            <EstadoVazio icone={FileText} titulo="Sem dízimos nem ofertas da Missão neste mês">Escolha outro mês ou lance as entradas do mês.</EstadoVazio>
          </div>
        ) : (
          <div className="grid gap-6 print:block print:text-black">
            {/* cabeçalho impresso */}
            <div className="hidden print:mb-4 print:block">
              <p className="text-sm">Igreja Adventista do Sétimo Dia · {entidadeNome}</p>
              <p className="text-lg font-bold">{igreja.nome} — relatório da tesouraria de {nomeMes(ano, m)}</p>
            </div>

            <Cartao titulo="Resumo por fundo" descricao={`O que cabe a ${entidadeNome} de ${nomeMes(ano, m)}`} semMargem className="print:border-0 print:shadow-none">
              <Tabela>
                <thead><tr><th className="sm:pl-6">Fundo</th><th className="num">Entrou</th><th className="num">Cabe à Missão</th><th className="num">Pago na Missão</th><th className="num">Depositado</th><th className="num sm:pr-6">Em falta</th></tr></thead>
                <tbody>
                  {resumo.map((d) => (
                    <tr key={d.fundoId}>
                      <td className="sm:pl-6"><span className="font-medium">{d.fundoNome}</span><span className="block text-xs text-muted-foreground">{parteDoFundo(fundos.data?.find((f) => f.id === d.fundoId) ?? {})}</span></td>
                      <td className="num"><Dinheiro valor={d.recebido} /></td>
                      <td className="num font-medium"><Dinheiro valor={d.devido} /></td>
                      <td className="num text-muted-foreground"><Dinheiro valor={d.pagoDirecto} /></td>
                      <td className="num text-muted-foreground"><Dinheiro valor={d.remetido} /></td>
                      <td className={cn('num font-medium sm:pr-6', centimos(d.emFalta) !== 0 && (centimos(d.emFalta) < 0 ? 'text-info-text' : 'text-warning-text'))}><Dinheiro valor={d.emFalta} /></td>
                    </tr>
                  ))}
                  <tr className="bg-muted/30 font-semibold">
                    <td className="sm:pl-6">Total</td><td className="num"><Dinheiro valor={soma('recebido')} /></td><td className="num"><Dinheiro valor={soma('devido')} /></td>
                    <td className="num"><Dinheiro valor={soma('pagoDirecto')} /></td><td className="num"><Dinheiro valor={soma('remetido')} /></td><td className="num sm:pr-6"><Dinheiro valor={soma('emFalta')} /></td>
                  </tr>
                </tbody>
              </Tabela>
              <div className="border-t px-4 py-3 text-sm sm:px-6">
                {depositos.length ? depositos.map((r, i) => (
                  <Deposito key={r.id} remessa={r} entidade={entidadeNome} complementar={i > 0} />
                )) : (
                  <p className="text-warning-text">Ainda não foi depositada a remessa deste mês. <Link to="/tesouraria/remessas" className="font-medium text-primary hover:underline print:hidden">Enviar remessa</Link></p>
                )}
                {centimos(soma('emFalta')) < 0 && <p className="mt-1 text-info-text">Os membros pagaram na Missão mais do que lhe cabia: a diferença é da igreja.</p>}
              </div>
            </Cartao>

            <Cartao titulo="Recibos do mês" descricao="Cada contribuição com nome, nos fundos da Missão" semMargem className="print:mt-6 print:border-0 print:shadow-none">
              {!linhas.length && !temAnonimas ? <EstadoVazio icone={FileText}>Sem contribuições com nome neste mês.</EstadoVazio> : (
                <Tabela>
                  <thead>
                    <tr>
                      <th className="sm:pl-6">Data</th><th>Membro</th><th>Recibo</th>
                      {colunas.map((c) => <th key={c.id} className="num">{c.nome.split(' / ')[0]}</th>)}
                      <th className="num sm:pr-6">Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    {linhas.map((l) => (
                      <tr key={l.id}>
                        <td className="tabular-nums whitespace-nowrap sm:pl-6">{data(l.data)}</td>
                        <td>
                          <Link to={`/tesouraria/movimentos/${l.id}`} className="font-medium hover:text-primary print:no-underline">{l.membroId ? nomes.get(l.membroId) ?? `Membro ${l.membroId}` : 'Família'}</Link>
                          {l.naMissao && <span className="block text-xs text-info-text">pago na Missão{l.referencia ? ` · ${l.referencia}` : ''}</span>}
                          {l.estorno && <span className="block text-xs text-destructive-text">estorno</span>}
                        </td>
                        <td className="num whitespace-nowrap">{l.recibo ?? '—'}</td>
                        {colunas.map((c) => <td key={c.id} className="num">{valor(l.valores.get(c.id) ?? 0)}</td>)}
                        <td className="num font-medium sm:pr-6">{valor(total(l.valores))}</td>
                      </tr>
                    ))}
                    {temAnonimas && (
                      <tr>
                        <td className="sm:pl-6" />
                        <td className="text-muted-foreground" colSpan={2}>Ofertas sem nome (salva)</td>
                        {anonimas.map((v, i) => <td key={colunas[i].id} className="num">{valor(v)}</td>)}
                        <td className="num font-medium sm:pr-6">{valor(anonimas.reduce((s, v) => s + v, 0))}</td>
                      </tr>
                    )}
                    <tr className="bg-muted/30 font-semibold">
                      <td className="sm:pl-6" colSpan={3}>Total ({linhas.length} recibo{linhas.length === 1 ? '' : 's'})</td>
                      {resumo.map((d) => <td key={d.fundoId} className="num"><Dinheiro valor={d.recebido} /></td>)}
                      <td className="num sm:pr-6"><Dinheiro valor={soma('recebido')} /></td>
                    </tr>
                  </tbody>
                </Tabela>
              )}
            </Cartao>

            <div className="hidden print:mt-16 print:grid print:grid-cols-2 print:gap-16">
              <div className="border-t border-black pt-1 text-center text-sm">O(A) Tesoureiro(a)</div>
              <div className="border-t border-black pt-1 text-center text-sm">O Pastor / O Primeiro Ancião</div>
            </div>
          </div>
        )}
    </>
  )
}
