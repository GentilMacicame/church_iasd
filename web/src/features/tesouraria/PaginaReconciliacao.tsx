/**
 * Reconciliação com o extracto (F-TES-10): importar o extracto do banco ou do M-Pesa (CSV) e ligar cada linha ao
 * movimento registado na tesouraria. O que fica por ligar é dinheiro que o banco viu e a tesouraria não (ou o
 * contrário): comissões, depósitos esquecidos, erros de valor. Sugere-se o movimento da mesma conta, com o mesmo
 * valor e direcção, até 5 dias de diferença; a escolha é sempre do tesoureiro.
 */
import { useMemo, useRef, useState } from 'react'
import { ArrowDownLeft, ArrowUpRight, FileCheck2, Link2, Upload } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Dinheiro, Indicador, Pilula, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoEscolha } from '@/components/comum/CampoEscolha'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { centimos, data, deCentimos } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { Exportar } from '@/components/comum/Exportar'
import { useContasIgreja, useExtractosMut, useMovimentos, usePorReconciliar, type PorReconciliar, type Transacao } from './api'

const DIA = 86_400_000
const somarDias = (iso: string, n: number) => new Date(Date.parse(iso + 'T12:00:00Z') + n * DIA).toISOString().slice(0, 10)

/** Efeito de um movimento numa conta, em cêntimos (+ entra, − sai), ou null se não mexe nela. */
function efeito(m: Transacao, conta: number): number | null {
  const v = centimos(m.valorTotal)
  if (m.tipo === 'TRANSFERENCIA') return m.destinoContaId === conta ? v : m.contaId === conta ? -v : null
  if (m.contaId !== conta) return null
  return m.tipo === 'ENTRADA' ? v : -v
}

export default function PaginaReconciliacao() {
  const { pode } = useSessao()
  const igreja = useIgreja()
  const linhas = usePorReconciliar()
  const contas = useContasIgreja()
  const [importar, setImportar] = useState(false)
  const [escolher, setEscolher] = useState<PorReconciliar | null>(null)
  const { reconciliar } = useExtractosMut()
  const lista = linhas.data ?? []
  const datas = lista.map((l) => l.data).sort()
  const desde = datas.length ? somarDias(datas[0], -10) : ''
  const ate = datas.length ? somarDias(datas[datas.length - 1], 10) : ''
  const movs = useMovimentos({ desde: desde || undefined, ate: ate || undefined, estado: 'CONFIRMADA' } as never)
  const confirmados = useMemo(() => (movs.data ?? []).filter((m) => m.estado === 'CONFIRMADA'), [movs.data])
  const [ligados, setLigados] = useState<number[]>([])

  const sugestoes = (l: PorReconciliar) => {
    const alvo = centimos(l.valor)
    const t0 = Date.parse(l.data + 'T12:00:00Z')
    return confirmados
      .filter((m) => !ligados.includes(m.id) && efeito(m, l.contaId) === alvo && Math.abs(Date.parse(m.dataHora) - t0) <= 5.5 * DIA)
      .sort((a, b) => Math.abs(Date.parse(a.dataHora) - t0) - Math.abs(Date.parse(b.dataHora) - t0))
      .slice(0, 3)
  }
  const ligar = (l: PorReconciliar, m: Transacao) => reconciliar.mutate({ id: l.id, transacaoId: m.id }, {
    onSuccess: () => { setLigados((x) => [...x, m.id]); setEscolher(null); toast.success(`Linha de ${data(l.data)} ligada ao movimento n.º ${m.id}.`) },
    onError: (e) => toast.error(mensagemDe(e)),
  })

  const entradas = lista.filter((l) => centimos(l.valor) > 0).reduce((s, l) => s + centimos(l.valor), 0)
  const saidas = lista.filter((l) => centimos(l.valor) < 0).reduce((s, l) => s - centimos(l.valor), 0)

  return (
    <>
      <TituloPagina icone={FileCheck2} titulo="Reconciliação com o extracto" descricao="Confirmar que cada linha do extracto do banco ou do M-Pesa está registada na tesouraria"
        accoes={(
          <>
            {lista.length > 0 && <Exportar caminho="/v1/tesouraria/extractos-por-reconciliar" query={{ igrejaId: igreja.id }} nome="extracto-por-reconciliar" />}
            {pode('tesouraria.extrato_linha.criar') && <Button className="alvo" onClick={() => setImportar(true)}><Upload className="size-4" />Importar extracto</Button>}
          </>
        )} />

      {linhas.isPending ? <Barra className="h-64 w-full" />
        : linhas.isError ? <EstadoErro erro={linhas.error} aoTentar={() => linhas.refetch()} />
        : !lista.length ? (
          <Cartao>
            <EstadoVazio icone={FileCheck2} titulo="Nada por reconciliar"
              accao={pode('tesouraria.extrato_linha.criar') && <Button variant="outline" className="alvo" onClick={() => setImportar(true)}><Upload className="size-4" />Importar o extracto do mês</Button>}>
              Todas as linhas importadas estão ligadas a um movimento. Importe o extracto do banco ou do M-Pesa para conferir o mês.
            </EstadoVazio>
          </Cartao>
        ) : (
          <div className="grid gap-6">
            <div className="grid gap-3 sm:grid-cols-3">
              <Indicador rotulo="Linhas por ligar" valor={String(lista.length)} icone={Link2} tom="warning" />
              <Indicador rotulo="Créditos por ligar" valor={<Dinheiro valor={deCentimos(entradas)} />} icone={ArrowDownLeft} tom="success" />
              <Indicador rotulo="Débitos por ligar" valor={<Dinheiro valor={deCentimos(saidas)} />} icone={ArrowUpRight} tom="destructive" />
            </div>
            <Cartao titulo="Linhas do extracto por ligar" descricao="Para cada linha, ligue o movimento sugerido ou escolha outro. Se não houver movimento, registe-o primeiro (ex.: comissão do banco como saída)." semMargem>
              <ul className="divide-y">
                {lista.map((l) => {
                  const v = centimos(l.valor)
                  const sug = movs.isPending ? null : sugestoes(l)
                  return (
                    <li key={l.id} className="grid gap-3 px-4 py-3 sm:px-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.3fr)] lg:items-center">
                      <div className="flex min-w-0 items-start gap-3">
                        <span className={cn('mt-0.5 flex size-8 flex-none items-center justify-center rounded-full', v >= 0 ? 'bg-success/10 text-success-text' : 'bg-destructive/10 text-destructive-text')} aria-hidden>
                          {v >= 0 ? <ArrowDownLeft className="size-4" /> : <ArrowUpRight className="size-4" />}
                        </span>
                        <div className="min-w-0">
                          <p className="flex flex-wrap items-baseline gap-x-2">
                            <span className={cn('num font-semibold', v < 0 && 'text-destructive-text')}>{v < 0 && '−'}<Dinheiro valor={deCentimos(Math.abs(v))} /></span>
                            <span className="text-sm tabular-nums text-muted-foreground">{data(l.data)}</span>
                          </p>
                          <p className="truncate text-sm">{l.descricao || '—'}</p>
                          <p className="text-xs text-muted-foreground">{l.conta}{l.referencia ? ` · ref. ${l.referencia}` : ''}</p>
                        </div>
                      </div>
                      <div className="flex min-w-0 flex-wrap items-center gap-2 lg:justify-end">
                        {sug == null ? <Barra className="h-8 w-48" />
                          : sug.length ? sug.map((m) => (
                            <Button key={m.id} size="sm" variant="outline" className="alvo h-auto max-w-full overflow-hidden py-1.5 text-left" disabled={!pode('tesouraria.extrato_linha.alterar') || reconciliar.isPending} onClick={() => ligar(l, m)}>
                              <Link2 className="size-4 flex-none" />
                              <span className="min-w-0 truncate">n.º {m.id} · {data(m.dataHora.slice(0, 10))} · {m.descricao || m.beneficiario || rotulos.tipoTransacao?.[m.tipo] || m.tipo}</span>
                            </Button>
                          ))
                          : <Pilula variante="warning">Sem movimento igual</Pilula>}
                        {pode('tesouraria.extrato_linha.alterar') && <Button size="sm" variant="ghost" className="alvo" onClick={() => setEscolher(l)}>Escolher outro…</Button>}
                      </div>
                    </li>
                  )
                })}
              </ul>
            </Cartao>
          </div>
        )}
      {importar && <DialogoImportar contas={contas.data ?? []} aoFechar={() => setImportar(false)} />}
      {escolher && <DialogoEscolher linha={escolher} movimentos={confirmados.filter((m) => !ligados.includes(m.id) && efeito(m, escolher.contaId) != null)} aCorrer={reconciliar.isPending}
        aoLigar={(m) => ligar(escolher, m)} aoFechar={() => setEscolher(null)} />}
    </>
  )
}

function DialogoEscolher({ linha, movimentos, aoLigar, aoFechar, aCorrer }: {
  linha: PorReconciliar; movimentos: Transacao[]; aoLigar: (m: Transacao) => void; aoFechar: () => void; aCorrer: boolean
}) {
  const [id, setId] = useState('')
  const m = movimentos.find((x) => String(x.id) === id)
  const diferente = m && efeito(m, linha.contaId) !== centimos(linha.valor)
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Ligar a um movimento</DialogTitle>
          <DialogDescription>Linha de {data(linha.data)} em {linha.conta}: <Dinheiro valor={linha.valor} />{linha.descricao ? ` — ${linha.descricao}` : ''}</DialogDescription>
        </DialogHeader>
        <div className="grid gap-2">
          <label htmlFor="rec-mov" className="text-sm font-medium">Movimento confirmado desta conta (até 10 dias antes ou depois)</label>
          <CampoEscolha id="rec-mov" valor={id} aoMudar={setId} vazio="Escolher o movimento…" pesquisar="Pesquisar pelo n.º, descrição ou valor…" semOpcoes="Não há movimentos desta conta no período"
            opcoes={movimentos.map((x) => {
              const e = efeito(x, linha.contaId) ?? 0
              return { valor: String(x.id), rotulo: `n.º ${x.id} · ${e < 0 ? '−' : '+'}${deCentimos(Math.abs(e)).replace('.', ',')} MT`, detalhe: `${data(x.dataHora.slice(0, 10))} · ${x.descricao || x.beneficiario || x.tipo}` }
            })} />
          {diferente && <p className="text-sm text-warning-text">Atenção: o valor do movimento é diferente do da linha do extracto.</p>}
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={!m || aCorrer} onClick={() => m && aoLigar(m)}>{aCorrer ? t.comum.aGravar : 'Ligar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function DialogoImportar({ contas, aoFechar }: { contas: { id: number; nome: string; tipo?: string | null }[]; aoFechar: () => void }) {
  const { importar } = useExtractosMut()
  const [conta, setConta] = useState(() => String(contas.find((c) => c.tipo !== 'CAIXA')?.id ?? ''))
  const [csv, setCsv] = useState('')
  const [ficheiro, setFicheiro] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const entrada = useRef<HTMLInputElement>(null)
  const linhas = csv.split(/\r?\n/).filter((l) => l.trim()).length

  const ler = async (f: File | undefined) => {
    if (!f) return
    if (f.size > 2_000_000) return setErro('O ficheiro é grande demais (máximo 2 MB). Divida o extracto por meses.')
    setFicheiro(f.name)
    setCsv((await f.text()).replace(/^﻿/, ''))
  }
  const submeter = () => {
    setErro(null)
    if (!conta) return setErro('Escolha a conta do extracto.')
    if (!csv.trim()) return setErro('Escolha o ficheiro ou cole as linhas do extracto.')
    importar.mutate({ contaId: Number(conta), csv }, {
      onSuccess: (r) => { toast.success(`${r.importadas} linha(s) importada(s)${r.repetidas ? `; ${r.repetidas} já estavam importadas` : ''}.`); aoFechar() },
      onError: (e) => setErro(mensagemDe(e)),
    })
  }

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-xl">
        <DialogHeader>
          <DialogTitle>Importar extracto</DialogTitle>
          <DialogDescription>Um ficheiro CSV do banco ou do M-Pesa com as colunas <span className="font-mono text-xs">data;descricao;referencia;valor</span>. Créditos com valor positivo, débitos com valor negativo. Linhas já importadas são ignoradas.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5">
            <label htmlFor="imp-conta" className="text-sm font-medium">Conta</label>
            <CampoEscolha id="imp-conta" valor={conta} aoMudar={setConta} opcoes={contas.map((c) => ({ valor: String(c.id), rotulo: c.nome }))} vazio="Escolher a conta…" />
          </div>
          <div className="grid gap-1.5">
            <span className="text-sm font-medium">Ficheiro</span>
            <input ref={entrada} type="file" accept=".csv,.txt,text/csv,text/plain" className="sr-only" onChange={(e) => ler(e.target.files?.[0])} aria-label="Escolher o ficheiro do extracto" />
            <Button type="button" variant="outline" className="alvo justify-start" onClick={() => entrada.current?.click()}>
              <Upload className="size-4" />{ficheiro || 'Escolher ficheiro CSV…'}
            </Button>
          </div>
          <div className="grid gap-1.5">
            <label htmlFor="imp-csv" className="text-sm font-medium">Ou cole as linhas {linhas > 0 && <span className="font-normal text-muted-foreground">({linhas} linha{linhas === 1 ? '' : 's'})</span>}</label>
            <textarea id="imp-csv" value={csv} onChange={(e) => setCsv(e.target.value)} rows={6} spellCheck={false}
              placeholder={'data;descricao;referencia;valor\n02/11/2026;Depósito numerário;004512;12 500,00\n05/11/2026;Comissão de manutenção;;-150,00'}
              className="w-full rounded-md border border-input bg-card px-3 py-2 font-mono text-xs focus-visible:ring-2 focus-visible:ring-ring/50 focus-visible:outline-none" />
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={importar.isPending} onClick={submeter}>{importar.isPending ? 'A importar…' : 'Importar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
