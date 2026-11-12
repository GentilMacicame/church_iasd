/**
 * Relatório do sábado (P-05) · "Que classes já entregaram o relatório deste sábado?"
 * Escolhe-se o trimestre e o sábado (por defeito, o de hoje ou o último que passou); cada classe abre o seu ecrã.
 * Com rede, prepara logo no telemóvel o ecrã de cada classe, para funcionar mesmo que a rede caia na igreja.
 */
import { useEffect, useMemo } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { useQueryClient } from '@tanstack/react-query'
import { BookOpenCheck, ChevronRight, CloudOff, CloudUpload, Settings2 } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Cartao, Pilula, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { Seleccao } from '@/components/comum/Seleccao'
import { useIgreja, useSessao } from '@/auth/sessao'
import { f, rotulos, t } from '@/i18n/pt-MZ'
import { data, dinheiro, deCentimos, centimos } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import {
  nomeTrimestre, sabadoActual, trimestreActual, useClasses, useClassesTrimestre, useRelatoriosSabado, useSabados, useTrimestres,
  type Relatorio,
} from './api'
import { chaveRelatorio, lerPacote, porEnviar, sincronizarTudo, useEmLinha, usePorEnviar, type Rascunho } from './offline'

/** Aviso de rede e da fila de envio, partilhado pelos ecrãs do sábado. */
export function AvisosRede() {
  const emLinha = useEmLinha()
  const fila = usePorEnviar()
  const recusados = fila.filter((r) => r.erro)
  return (
    <div className="grid gap-3 empty:hidden">
      {!emLinha && (
        <div role="status" className="flex items-start gap-2 rounded-lg border border-warning/30 bg-tint-warning px-4 py-3 text-sm text-warning-text">
          <CloudOff className="mt-0.5 size-4 flex-none" aria-hidden />
          <p>{t.es.semRede}</p>
        </div>
      )}
      {fila.length > 0 && (
        <div role="status" className="flex flex-wrap items-center gap-3 rounded-lg border border-info/20 bg-tint-info px-4 py-3 text-sm text-info-text">
          <CloudUpload className="size-4 flex-none" aria-hidden />
          <p className="min-w-0 flex-1">
            {f(t.es.porEnviar, { n: fila.length })}
            {recusados.length > 0 && <> · {recusados.length} recusado(s): abra-o(s) para corrigir</>}
          </p>
          {emLinha && (
            <Button size="sm" variant="outline" className="alvo" onClick={() => void sincronizarTudo().then(async () => { const resta = await porEnviar(); if (resta.length) toast.warning(`${resta.length} relatório(s) ainda por enviar.`); else toast.success('Relatórios enviados.') })}>
              {t.es.enviarAgora}
            </Button>
          )}
        </div>
      )}
    </div>
  )
}

function EstadoClasse({ rel, rascunho }: { rel?: Relatorio; rascunho?: Rascunho }) {
  if (rascunho?.erro) return <Pilula variante="destructive">Recusado</Pilula>
  if (rascunho?.porEnviar) return <Pilula variante="info">Por enviar</Pilula>
  if (!rel) return <Pilula variante="outline">Por fazer</Pilula>
  return rel.estado === 'FECHADO' ? <Pilula variante="success">Fechado</Pilula> : <Pilula variante="warning">Aberto</Pilula>
}

export default function PaginaSabado() {
  const igreja = useIgreja()
  const { pode } = useSessao()
  const qc = useQueryClient()
  const emLinha = useEmLinha()
  const [params, setParams] = useSearchParams()
  const trimestres = useTrimestres()
  const trimestre = trimestres.data?.find((x) => x.id === Number(params.get('trimestre'))) ?? trimestreActual(trimestres.data ?? [])
  const sabados = useSabados(trimestre?.id)
  const sabado = sabados.data?.find((x) => x.id === Number(params.get('sabado'))) ?? sabadoActual(sabados.data ?? [])
  const classes = useClasses()
  const cts = useClassesTrimestre(trimestre?.id)
  const relatorios = useRelatoriosSabado(sabado?.id)
  const fila = usePorEnviar()

  const linhas = useMemo(() => {
    const nomes = new Map((classes.data ?? []).map((c) => [c.id, c]))
    return (cts.data ?? [])
      .map((ct) => ({ ct, classe: nomes.get(ct.classeId), rel: relatorios.data?.find((r) => r.classeTrimestreId === ct.id) }))
      .filter((l) => l.classe)
      .sort((a, b) => a.classe!.nome.localeCompare(b.classe!.nome, 'pt'))
  }, [classes.data, cts.data, relatorios.data])
  const activas = linhas.filter((l) => l.ct.estado !== 'INACTIVO')
  const inactivas = linhas.filter((l) => l.ct.estado === 'INACTIVO')

  // com rede: deixa no telemóvel o ecrã de cada classe deste sábado
  const idsActivas = activas.map((l) => l.ct.id).join(',')
  const sabadoId = sabado?.id
  useEffect(() => {
    if (!emLinha || !sabadoId || !idsActivas) return
    // o código do ecrã da classe também (o service worker guarda-o), para abrir sem rede
    void import('./PaginaRelatorioClasse').catch(() => {})
    for (const ct of idsActivas.split(',').map(Number)) {
      void qc.prefetchQuery({
        queryKey: ['es-pacote', ct, sabadoId],
        queryFn: () => lerPacote(igreja.id, ct, sabadoId),
        staleTime: 60_000,
        networkMode: 'always',
      })
    }
  }, [emLinha, sabadoId, idsActivas, qc, igreja.id])

  const mudar = (chave: 'trimestre' | 'sabado', valor: string) => {
    const p = new URLSearchParams(params)
    p.set(chave, valor)
    if (chave === 'trimestre') p.delete('sabado')
    setParams(p, { replace: true })
  }

  const feitos = activas.filter((l) => l.rel).length
  const total = activas.reduce((s, l) => s + (l.rel ? centimos(l.rel.oferta) + centimos(l.rel.oferta13Sabado) + centimos(l.rel.ofertaDespesas) : 0), 0)
  const erro = trimestres.error ?? sabados.error ?? cts.error ?? classes.error ?? relatorios.error
  const aCarregar = trimestres.isPending || (trimestre && (sabados.isPending || cts.isPending)) || classes.isPending

  return (
    <>
      <TituloPagina
        icone={BookOpenCheck}
        titulo={t.es.sabado}
        descricao="Números, chamada, visitantes e as três ofertas de cada classe"
        accoes={pode('escola_sabatina.classe_trimestre.criar') && (
          <Button asChild variant="outline" className="alvo"><Link to="/escola-sabatina/classes"><Settings2 className="size-4" />Classes</Link></Button>
        )}
      />
      <div className="grid gap-4">
        <AvisosRede />
        <div className="grid gap-3 sm:grid-cols-2">
          <Seleccao aria-label="Trimestre" value={trimestre?.id ?? ''} onChange={(e) => mudar('trimestre', e.target.value)} disabled={!trimestres.data?.length}>
            {(trimestres.data ?? []).map((x) => <option key={x.id} value={x.id}>{nomeTrimestre(x)}{x.temaLicao ? ` · ${x.temaLicao}` : ''}</option>)}
          </Seleccao>
          <Seleccao aria-label="Sábado" value={sabado?.id ?? ''} onChange={(e) => mudar('sabado', e.target.value)} disabled={!sabados.data?.length}>
            {(sabados.data ?? []).map((s) => <option key={s.id} value={s.id}>{s.numero}.º sábado · {data(s.data)}{s.decimoTerceiro ? ' · 13.º sábado' : ''}</option>)}
          </Seleccao>
        </div>

        {erro ? <EstadoErro erro={erro} aoTentar={() => { void trimestres.refetch(); void cts.refetch(); void relatorios.refetch() }} />
          : aCarregar ? <Cartao><LinhasACarregar linhas={4} /></Cartao>
          : !trimestre ? (
            <Cartao><EstadoVazio icone={BookOpenCheck} titulo="Ainda não há trimestres">
              A Associação cria os trimestres e os sábados da lição. Depois de criados, aparecem aqui.
            </EstadoVazio></Cartao>
          ) : activas.length === 0 ? (
            <Cartao><EstadoVazio icone={Settings2} titulo="Nenhuma classe neste trimestre"
              accao={pode('escola_sabatina.classe_trimestre.criar') && <Button asChild size="sm"><Link to="/escola-sabatina/classes">Configurar as classes</Link></Button>}>
              Configure cada classe para o trimestre (professor, secretário e alvos) para poder registar o relatório do sábado.
            </EstadoVazio></Cartao>
          ) : (
            <Cartao
              titulo={sabado ? `${sabado.numero}.º sábado · ${data(sabado.data)}` : 'Sábado'}
              descricao={`${feitos} de ${activas.length} classes com relatório · ofertas ${dinheiro(deCentimos(total))}`}
              semMargem
            >
              <ul className="divide-y border-t">
                {activas.map(({ ct, classe, rel }) => {
                  const rascunho = sabado ? fila.find((r) => r.chave === chaveRelatorio(ct.id, sabado.id)) : undefined
                  return (
                    <li key={ct.id}>
                      <Link to={`/escola-sabatina/sabado/${ct.id}/${sabado?.id}`}
                        className="alvo flex min-h-16 items-center gap-3 px-5 py-3 hover:bg-muted/50 sm:px-6">
                        <span className="min-w-0 flex-1">
                          <span className="block truncate font-medium">{classe!.nome}</span>
                          <span className="block truncate text-xs text-muted-foreground">
                            {rotulos.divisao[classe!.divisao]}
                            {rel && <> · {rel.membrosPresentes}/{rel.membrosMatriculados} presentes · {dinheiro(deCentimos(centimos(rel.oferta) + centimos(rel.oferta13Sabado) + centimos(rel.ofertaDespesas)))}</>}
                          </span>
                        </span>
                        <EstadoClasse rel={rel} rascunho={rascunho} />
                        <ChevronRight aria-hidden className="size-4 flex-none text-muted-foreground" />
                      </Link>
                    </li>
                  )
                })}
              </ul>
              {inactivas.length > 0 && (
                <p className={cn('border-t px-5 py-3 text-xs text-muted-foreground sm:px-6')}>
                  Desactivadas neste trimestre: {inactivas.map((l) => l.classe!.nome).join(', ')}
                </p>
              )}
            </Cartao>
          )}
      </div>
    </>
  )
}
