/**
 * Aprovações e conferências (V54) · "O que está por decidir, em que etapa está e quem é o responsável?"
 * Todos os processos da igreja que o utilizador pode ver (despesas, saídas, contagens, orçamentos, admissões e
 * remoções de membros), com a etapa em curso, quem a decide (com os nomes), as etapas já decididas e as que faltam.
 * "Para eu decidir" são os que esperam por uma decisão do próprio utilizador.
 */
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowRight, ChevronDown, CircleCheck, Gavel, Hourglass, ListChecks, Route, Users } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Dinheiro, Indicador, Pilula, Segmentos, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { Seleccao } from '@/components/comum/Seleccao'
import { useSessao } from '@/auth/sessao'
import { data, qtd } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { ESTADOS, PROCESSOS, useAprovacoes, type Processo, type ProcessoAprovacao } from './api'
import { DialogoDecidirEtapa, EtapasAprovacao, LinhaEtapa, QuemDecide } from './EtapasAprovacao'

type Aba = 'meus' | 'curso' | 'concluidos'

/** Onde se vê o objecto do processo. */
function ligacao(p: ProcessoAprovacao): { para: string; rotulo: string } | null {
  if (p.despesaId) return { para: `/tesouraria/despesas?despesa=${p.despesaId}`, rotulo: 'Ver a despesa' }
  if (p.transacaoId) return { para: `/tesouraria/movimentos/${p.transacaoId}`, rotulo: 'Ver a saída' }
  if (p.contagemId) return { para: '/tesouraria/contagens', rotulo: 'Ver as contagens' }
  if (p.orcamentoId) return { para: '/tesouraria/orcamento', rotulo: 'Ver o orçamento' }
  if (p.membroId) return { para: `/membros/${p.membroId}`, rotulo: 'Ver a ficha' }
  return null
}

export default function PaginaAprovacoes() {
  const q = useAprovacoes()
  const [aba, setAba] = useState<Aba>('meus')
  const [processo, setProcesso] = useState<Processo | ''>('')
  const [decidir, setDecidir] = useState<ProcessoAprovacao | null>(null)
  const lista = useMemo(() => (q.data ?? []).filter((p) => !processo || p.processo === processo), [q.data, processo])
  const meus = lista.filter((p) => p.podeDecidir)
  const emCurso = lista.filter((p) => p.estado === 'EM_CURSO')
  const concluidos = lista.filter((p) => p.estado !== 'EM_CURSO')
  const visiveis = aba === 'meus' ? meus : aba === 'curso' ? emCurso : concluidos
  const presentes = [...new Set((q.data ?? []).map((p) => p.processo))]

  return (
    <>
      <TituloPagina icone={ListChecks} titulo="Aprovações e conferências" descricao="O que está por decidir, em que etapa está e quem decide"
        accoes={<Button asChild variant="outline" className="alvo"><Link to="/aprovacoes/fluxos"><Route className="size-4" />Como se aprova cada processo</Link></Button>} />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4 [&>*:last-child]:col-span-2 sm:[&>*:last-child]:col-span-1">
          <Indicador rotulo="Para eu decidir" valor={meus.length} nota="esperam por uma decisão sua" icone={Gavel} tom={meus.length ? 'warning' : 'success'}
            aCarregar={q.isPending} aoClicar={() => setAba('meus')} activo={aba === 'meus'} />
          <Indicador rotulo="Em curso" valor={emCurso.length} nota="em alguma etapa do fluxo" icone={Hourglass} tom="info"
            aCarregar={q.isPending} aoClicar={() => setAba('curso')} activo={aba === 'curso'} />
          <Indicador rotulo="Concluídos" valor={concluidos.length} nota="aprovados, rejeitados ou cancelados" icone={CircleCheck} tom="success"
            aCarregar={q.isPending} aoClicar={() => setAba('concluidos')} activo={aba === 'concluidos'} />
        </div>

        <div className="flex flex-wrap items-center justify-between gap-3">
          <Segmentos rotulo="Mostrar" valor={aba} aoMudar={setAba} opcoes={[
            { valor: 'meus', rotulo: 'Para eu decidir', contagem: meus.length },
            { valor: 'curso', rotulo: 'Em curso', contagem: emCurso.length },
            { valor: 'concluidos', rotulo: 'Concluídos', contagem: concluidos.length },
          ]} />
          {presentes.length > 1 && (
            <Seleccao aria-label="Natureza do processo" className="alvo w-full sm:w-64" value={processo} onChange={(e) => setProcesso(e.target.value as Processo | '')}>
              <option value="">Todas as naturezas</option>
              {presentes.map((x) => <option key={x} value={x}>{PROCESSOS[x].plural}</option>)}
            </Seleccao>
          )}
        </div>

        {q.isPending ? <div className="grid gap-3">{[0, 1, 2].map((i) => <Barra key={i} className="h-24 w-full rounded-xl" />)}</div>
          : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
          : visiveis.length === 0 ? (
            <div className="rounded-xl border bg-card shadow-card">
              <EstadoVazio icone={aba === 'meus' ? CircleCheck : ListChecks} titulo={aba === 'meus' ? 'Nada à sua espera' : aba === 'curso' ? 'Nenhum processo em curso' : 'Ainda não há processos concluídos'}>
                {aba === 'meus' ? 'Quando uma despesa, saída, contagem ou admissão chegar a uma etapa que é sua, aparece aqui.'
                  : 'Os processos começam sozinhos quando se pede uma despesa, se regista uma saída ou uma contagem, ou se vota uma admissão.'}
              </EstadoVazio>
            </div>
          ) : (
            <div className="grid gap-3">
              {visiveis.map((p) => <CartaoProcesso key={p.id} p={p} aoDecidir={() => setDecidir(p)} />)}
              <p className="text-xs text-muted-foreground">{qtd(visiveis.length, 'processo(s)')}</p>
            </div>
          )}
      </div>
      {decidir && <DialogoDecidirEtapa p={decidir} aoFechar={() => setDecidir(null)} />}
    </>
  )
}

function CartaoProcesso({ p, aoDecidir }: { p: ProcessoAprovacao; aoDecidir: () => void }) {
  const { igrejas } = useSessao()
  const [aberto, setAberto] = useState(false)
  const ver = ligacao(p)
  const est = ESTADOS[p.estado]
  return (
    <section className={cn('relative min-w-0 overflow-hidden rounded-2xl border bg-card shadow-card',
      'before:absolute before:inset-y-0 before:left-0 before:w-1',
      p.estado === 'EM_CURSO' ? (p.podeDecidir ? 'before:bg-warning' : 'before:bg-primary') : p.estado === 'APROVADO' ? 'before:bg-success' : p.estado === 'REJEITADO' ? 'before:bg-destructive' : 'before:bg-muted')}>
      <button type="button" onClick={() => setAberto((x) => !x)} aria-expanded={aberto}
        className="alvo flex w-full flex-wrap items-start justify-between gap-3 px-5 py-4 text-left sm:px-6">
        <span className="grid min-w-0 flex-1 gap-1">
          <span className="flex flex-wrap items-center gap-2">
            <Pilula variante="secondary">{PROCESSOS[p.processo].rotulo}</Pilula>
            <Pilula variante={est.variante}>{est.rotulo}</Pilula>
            {igrejas.length > 1 && <span className="text-xs text-muted-foreground">{p.igreja}</span>}
          </span>
          <span className="truncate text-base font-semibold">{p.assunto}</span>
          <LinhaEtapa p={p} />
          {p.estado === 'EM_CURSO' && (
            <span className="flex min-w-0 items-start gap-1.5 text-sm">
              <Users className="mt-0.5 size-4 flex-none text-muted-foreground" aria-hidden />
              <span className="min-w-0"><span className="text-muted-foreground">Próxima acção: </span><QuemDecide p={p} /></span>
            </span>
          )}
          <span className="text-xs text-muted-foreground">
            Fluxo «{p.fluxo}» · iniciado em {data(p.criadoEm)}{p.pedidoPor ? ` por ${p.pedidoPor}` : ''}{p.concluidoEm ? ` · concluído em ${data(p.concluidoEm)}` : ''}
          </span>
        </span>
        <span className="flex items-center gap-4">
          {p.valor && <span className="num text-lg font-semibold tracking-tight"><Dinheiro valor={p.valor} /></span>}
          <ChevronDown className={cn('size-5 text-muted-foreground transition-transform duration-200', aberto && 'rotate-180')} aria-hidden />
        </span>
      </button>
      {aberto && <EtapasAprovacao aprovacaoId={p.id} className="mx-5 mb-4 rounded-lg border bg-muted/20 p-3 sm:mx-6" />}
      {(p.podeDecidir || ver) && (
        <footer className="flex flex-wrap items-center justify-end gap-2 border-t bg-muted/30 px-5 py-3 sm:px-6">
          {ver && <Button asChild size="sm" variant="ghost" className="alvo"><Link to={ver.para}>{ver.rotulo}<ArrowRight className="size-4" /></Link></Button>}
          {p.podeDecidir && <Button size="sm" className="alvo" onClick={aoDecidir}><Gavel className="size-4" />Decidir esta etapa</Button>}
        </footer>
      )}
    </section>
  )
}
