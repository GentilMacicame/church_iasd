/**
 * Notificações · "Os SMS saíram?" — o histórico da fila: o recibo da contribuição com o resumo por fundo (V42), os
 * lembretes de escala e o resto. Cada mensagem com o estado, as tentativas e o erro do fornecedor; as que falharam
 * (5 tentativas) podem reenviar-se. Reenviar não cria outra mensagem nem mexe no registo financeiro.
 */
import { useMemo } from 'react'
import { useSearchParams } from 'react-router-dom'
import { BellRing, RotateCcw } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { Seleccao } from '@/components/comum/Seleccao'
import { Paginada } from '@/components/comum/Paginacao'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { data, hora } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { ROTULO_CANAL, ROTULO_ESTADO, ROTULO_ORIGEM, useNotificacoes, useReenviar, type EstadoNotificacao } from './api'

const ABAS: { k: EstadoNotificacao | 'todas'; r: string }[] = [
  { k: 'todas', r: 'Todas' }, { k: 'FALHADA', r: 'Falharam' }, { k: 'PENDENTE', r: 'Por enviar' }, { k: 'ENVIADA', r: 'Enviadas' },
]

/** O número sem os dígitos do meio: +258 84 ••• 2233. */
const mascarar = (d: string) => (d.includes('@') ? d.replace(/^(.).*(@.*)$/, '$1•••$2') : d.length > 6 ? `${d.slice(0, -7)}•••${d.slice(-4)}` : d)

export default function PaginaNotificacoes() {
  const { pode } = useSessao()
  const [params, setParams] = useSearchParams()
  const estado = (params.get('estado') as EstadoNotificacao | null) ?? undefined
  const canal = params.get('canal') ?? undefined
  const q = useNotificacoes({ estado, canal })
  const reenviar = useReenviar()
  const basicos = useMembrosBasicos()
  const nomes = useMemo(() => new Map((basicos.data ?? []).map((m) => [m.id, `${m.nome} ${m.apelido}`])), [basicos.data])
  const definir = (k: string, v?: string) => setParams((p) => { const n = new URLSearchParams(p); if (v) n.set(k, v); else n.delete(k); return n })
  const podeReenviar = pode('nucleo.notificacao.alterar')
  const lista = q.data ?? []

  const reenviarUma = (id: number) => reenviar.mutate(id, {
    onSuccess: () => toast.success('Volta a ser enviada no próximo minuto.'),
    onError: (e) => toast.error(mensagemDe(e)),
  })

  return (
    <>
      <TituloPagina icone={BellRing} titulo="Notificações" descricao="SMS enviados: recibos, lembretes e comunicados" />
      <section className="min-w-0 rounded-xl border bg-card shadow-card">
        <div className="flex flex-wrap items-center gap-3 border-b px-4 py-3 sm:px-6">
          <div role="tablist" aria-label="Estado" className="flex flex-wrap gap-1 rounded-lg bg-muted p-1">
            {ABAS.map((a) => {
              const sel = (estado ?? 'todas') === a.k
              return (
                <button key={a.k} role="tab" aria-selected={sel} type="button" onClick={() => definir('estado', a.k === 'todas' ? undefined : a.k)}
                  className={cn('alvo rounded-md px-3 py-1.5 text-xs font-medium text-muted-foreground', sel && 'bg-card text-foreground shadow-sm')}>
                  {a.r}
                </button>
              )
            })}
          </div>
          <Seleccao aria-label="Canal" value={canal ?? ''} onChange={(e) => definir('canal', e.target.value || undefined)} className="h-9 w-40">
            <option value="">Todos os canais</option>
            {Object.entries(ROTULO_CANAL).map(([k, r]) => <option key={k} value={k}>{r}</option>)}
          </Seleccao>
        </div>
        {q.isPending ? <LinhasACarregar linhas={6} />
          : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="m-4" />
          : lista.length === 0 ? (
            <EstadoVazio icone={BellRing} titulo="Sem notificações">
              {estado === 'FALHADA' ? 'Nenhuma mensagem falhou.' : 'Ainda não há mensagens com este filtro.'}
            </EstadoVazio>
          ) : (
            <Paginada itens={lista}>{(vis) => (
              <Tabela>
                <thead>
                  <tr>
                    <th className="hidden sm:table-cell sm:pl-6">Criada</th><th>Mensagem</th><th className="hidden md:table-cell">Para</th>
                    <th>Estado</th>{podeReenviar && <th className="sm:pr-6"><span className="sr-only">Acções</span></th>}
                  </tr>
                </thead>
                <tbody>
                  {vis.map((n) => {
                    const est = ROTULO_ESTADO[n.estado] ?? ROTULO_ESTADO.PENDENTE
                    return (
                      <tr key={n.id}>
                        <td className="hidden tabular-nums whitespace-nowrap text-muted-foreground sm:table-cell sm:pl-6">{data(n.criadoEm)}<span className="block text-xs">{hora(n.criadoEm)}</span></td>
                        <td className="max-w-md">
                          <p className="font-medium">{n.assunto ?? ROTULO_ORIGEM[n.origemTabela ?? ''] ?? 'Mensagem'}</p>
                          <p className="line-clamp-2 text-xs text-muted-foreground">{n.mensagem}</p>
                          <p className="text-xs text-muted-foreground md:hidden">{n.membroId ? nomes.get(n.membroId) : ''} · {ROTULO_CANAL[n.canal]} {mascarar(n.destino)}</p>
                        </td>
                        <td className="hidden md:table-cell">
                          <p>{n.membroId ? nomes.get(n.membroId) ?? '—' : '—'}</p>
                          <p className="num text-xs text-muted-foreground">{ROTULO_CANAL[n.canal]} · {mascarar(n.destino)}</p>
                        </td>
                        <td>
                          <Pilula variante={est.v}>{est.r}</Pilula>
                          <p className="mt-1 text-xs text-muted-foreground">
                            {n.estado === 'ENVIADA' && n.enviadaEm ? `${data(n.enviadaEm)} ${hora(n.enviadaEm)}` : `${n.tentativas ?? 0} tentativa(s)`}
                          </p>
                          {n.erro && n.estado !== 'ENVIADA' && <p className="line-clamp-2 max-w-56 text-xs text-destructive-text" title={n.erro}>{n.erro}</p>}
                        </td>
                        {podeReenviar && (
                          <td className="w-px whitespace-nowrap text-right sm:pr-6">
                            {(n.estado === 'FALHADA' || n.estado === 'CANCELADA') && (
                              <Button size="sm" variant="outline" className="alvo" disabled={reenviar.isPending} onClick={() => reenviarUma(n.id)}>
                                <RotateCcw className="size-4" />Reenviar
                              </Button>
                            )}
                          </td>
                        )}
                      </tr>
                    )
                  })}
                </tbody>
              </Tabela>
            )}</Paginada>
          )}
      </section>
    </>
  )
}
