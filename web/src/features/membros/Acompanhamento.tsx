/**
 * Na ficha do membro · "Como está a vida espiritual desta pessoa e o que precisa de acompanhamento?"
 * Fidelidade no dízimo (os últimos 12 meses), ofertas e reavivamento do ano, Santa Ceia, Escola Sabatina, disciplina
 * e os sinais de alerta. Cada parte só aparece a quem tem a permissão desses dados (a base de dados decide o resto).
 */
import { useQuery } from '@tanstack/react-query'
import { AlertTriangle, BookOpen, CircleCheck, Gavel, HandCoins, HeartPulse, Wine } from 'lucide-react'
import { Cartao, Pilula } from '@/components/comum/elementos'
import { Barra } from '@/components/comum/estados'
import { api, dados } from '@/api/cliente'
import { useIgreja, useSessao } from '@/auth/sessao'
import { centimos, data, deCentimos, dinheiro, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useFundos } from '@/features/tesouraria/api'
import { useDisciplinas } from '@/features/secretaria/api'
import { useParticipacao, type Membro } from './api'

const MESES = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']

interface Contribuicao { dataHora: string; fundoId: number; fundo: string; valor: string; periodoAno: number; periodoMes: number; estorno?: boolean }
interface Reavivamento { quota: string | null; contribuido: string | null; falta: string | null }
interface SantaCeia { celebracoes: number; participacoes: number; faltas: number; ultima: string | null }
interface Presenca { presente: boolean; endDate?: string | null }

/** Um pedido a um relatório, só quando há permissão. */
function useRelatorio<T>(chave: unknown[], caminho: string, query: Record<string, unknown>, activo: boolean) {
  return useQuery({
    enabled: activo,
    queryKey: ['acompanhamento', ...chave],
    queryFn: async () => (await dados(api.GET(caminho as never, { params: { query } } as never))) as unknown as T,
    staleTime: 60_000,
  })
}

export function AcompanhamentoMembro({ m }: { m: Membro }) {
  const { pode } = useSessao()
  const igreja = useIgreja()
  const ano = Number(hojeIso().slice(0, 4))
  const veDinheiro = pode('tesouraria.transacao.ler')
  const veReavivamento = pode('tesouraria.quota_reavivamento.ler')
  const veCeia = pode('actividades.santa_ceia_participante.ler')
  const veES = pode('escola_sabatina.presenca.ler')
  const veDisciplina = pode('secretaria.disciplina.ler')

  const contrib = useRelatorio<Contribuicao[]>(['contrib', m.id], '/v1/tesouraria/contribuicoes', { igrejaId: igreja.id, membroId: m.id }, veDinheiro)
  const fundos = useFundos()
  const reav = useRelatorio<Reavivamento[]>(['reav', m.id, ano], '/v1/tesouraria/reavivamento-pessoas', { igrejaId: igreja.id, ano, membroId: m.id }, veReavivamento)
  const ceia = useRelatorio<SantaCeia[]>(['ceia', m.id, ano], '/v1/actividades/santa-ceia-participacao', { igrejaId: igreja.id, ano, membroId: m.id }, veCeia)
  const pres = useRelatorio<{ dados: Presenca[] }>(['pres', m.id], '/v1/escola-sabatina/presencas', { igrejaId: igreja.id, membroId: m.id, limite: 13, ordem: '-id' }, veES)
  const disc = useDisciplinas()
  const participacao = useParticipacao(pode('secretaria.membro.ler'))

  if (!veDinheiro && !veCeia && !veES && !veDisciplina) return null

  // ---------------------------------------------------------------- dízimo: os últimos 12 meses
  const tipoDe = new Map((fundos.data ?? []).map((f) => [f.id, f.tipo]))
  const linhas = (contrib.data ?? []).filter((c) => !c.estorno)
  const hoje = new Date()
  const meses = Array.from({ length: 12 }, (_, i) => {
    const d = new Date(hoje.getFullYear(), hoje.getMonth() - 11 + i, 1)
    const doMes = linhas.filter((c) => c.periodoAno === d.getFullYear() && c.periodoMes === d.getMonth() + 1)
    const dizimo = doMes.filter((c) => tipoDe.get(c.fundoId) === 'DIZIMO').reduce((s, c) => s + centimos(c.valor), 0)
    const outras = doMes.filter((c) => tipoDe.get(c.fundoId) !== 'DIZIMO').reduce((s, c) => s + centimos(c.valor), 0)
    return { ano: d.getFullYear(), mes: d.getMonth(), dizimo, outras }
  })
  const comDizimo = meses.filter((x) => x.dizimo > 0).length
  let semDizimo = 0
  for (let i = meses.length - 1; i >= 0 && meses[i].dizimo === 0; i--) semDizimo++
  const doAno = linhas.filter((c) => c.periodoAno === ano)
  const somar = (f: (t: string | undefined) => boolean) => doAno.filter((c) => f(tipoDe.get(c.fundoId))).reduce((s, c) => s + centimos(c.valor), 0)
  const dizimosAno = somar((t) => t === 'DIZIMO')
  const reavAno = somar((t) => t === 'REAVIVAMENTO')
  const ofertasAno = somar((t) => t !== 'DIZIMO' && t !== 'REAVIVAMENTO')
  const ultimoDizimo = linhas.filter((c) => tipoDe.get(c.fundoId) === 'DIZIMO').map((c) => c.dataHora).sort().at(-1)

  // ---------------------------------------------------------------- outros dados
  const r = reav.data?.[0]
  const sc = ceia.data?.[0]
  const chamadas = (pres.data?.dados ?? []).filter((p) => !p.endDate)
  const presentes = chamadas.filter((p) => p.presente).length
  const disciplinas = (disc.data ?? []).filter((d) => d.membroId === m.id).sort((a, b) => b.dataInicio.localeCompare(a.dataInicio))
  const censura = disciplinas.find((d) => d.dataFim >= hojeIso())
  const minha = participacao.data?.find((p) => p.membroId === m.id)

  // ---------------------------------------------------------------- sinais para quem acompanha
  const sinais: { texto: string; tom: 'destructive' | 'warning' | 'info' }[] = []
  if (censura) sinais.push({ texto: `Sob censura até ${data(censura.dataFim)}`, tom: 'destructive' })
  if (minha?.inactivo) sinais.push({ texto: 'Inactivo: sem participação nos últimos meses', tom: 'warning' })
  if (veDinheiro && contrib.data && semDizimo >= 3) sinais.push({ texto: semDizimo >= 12 ? 'Sem dízimo nos últimos 12 meses' : `Sem dízimo há ${semDizimo} meses`, tom: 'warning' })
  if (sc && sc.celebracoes > 0 && sc.participacoes === 0) sinais.push({ texto: `Não participou em nenhuma Santa Ceia de ${ano}`, tom: 'warning' })
  if (chamadas.length >= 4 && presentes / chamadas.length < 0.5) sinais.push({ texto: `Faltou a ${chamadas.length - presentes} das últimas ${chamadas.length} chamadas da Escola Sabatina`, tom: 'warning' })
  if (r && centimos(r.falta ?? '0') > 0) sinais.push({ texto: `Falta ${dinheiro(r.falta)} do reavivamento de ${ano}`, tom: 'info' })
  const aCarregar = (veDinheiro && (contrib.isPending || fundos.isPending)) || (veCeia && ceia.isPending)

  const bloco = (icone: typeof Wine, titulo: string, conteudo: React.ReactNode, className?: string) => {
    const I = icone
    return (
      <section className={cn('grid content-start gap-2 rounded-[2px] border bg-background/40 p-4', className)}>
        <h3 className="flex items-center gap-2 text-sm font-semibold"><I className="size-4 text-muted-foreground" aria-hidden />{titulo}</h3>
        {conteudo}
      </section>
    )
  }

  return (
    <Cartao titulo="Acompanhamento espiritual" descricao="Fidelidade, comunhão e participação: o que precisa de atenção" icone={HeartPulse} className="mb-6 print:break-inside-avoid">
      {aCarregar ? <Barra className="h-32 w-full" /> : (
        <div className="grid gap-4">
          <div className="flex flex-wrap gap-2" aria-label="Sinais">
            {sinais.length ? sinais.map((s) => <Pilula key={s.texto} variante={s.tom} className="max-w-full whitespace-normal"><AlertTriangle className="size-3" />{s.texto}</Pilula>)
              : <Pilula variante="success"><CircleCheck className="size-3" />Sem sinais de alerta</Pilula>}
          </div>

          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
            {veDinheiro && bloco(HandCoins, 'Dízimo · últimos 12 meses', (
              <>
                <div className="grid grid-cols-12 gap-1" role="img" aria-label={`Dízimo em ${comDizimo} dos últimos 12 meses`}>
                  {meses.map((x) => (
                    <span key={`${x.ano}-${x.mes}`} className="grid justify-items-center gap-1" title={`${MESES[x.mes]} ${x.ano}: ${x.dizimo ? `dízimo ${dinheiro(deCentimos(x.dizimo))}` : x.outras ? 'só ofertas' : 'sem contribuição'}`}>
                      <span className={cn('h-7 w-full rounded-[2px]', x.dizimo ? 'bg-success' : x.outras ? 'bg-warning/60' : 'bg-muted-foreground/15')} />
                      <span className="text-[10px] leading-none text-muted-foreground">{MESES[x.mes][0].toUpperCase()}</span>
                    </span>
                  ))}
                </div>
                <p className="text-sm"><strong className="font-semibold tabular-nums">{comDizimo} de 12</strong> meses com dízimo</p>
                <p className="text-xs text-muted-foreground">{ultimoDizimo ? `Último: ${data(ultimoDizimo)}` : 'Sem dízimo registado'}</p>
                <p className="flex flex-wrap gap-x-3 text-xs text-muted-foreground">
                  <span className="inline-flex items-center gap-1"><span className="size-2.5 rounded-[2px] bg-success" />dízimo</span>
                  <span className="inline-flex items-center gap-1"><span className="size-2.5 rounded-[2px] bg-warning/60" />só ofertas</span>
                  <span className="inline-flex items-center gap-1"><span className="size-2.5 rounded-[2px] bg-muted-foreground/15" />nada</span>
                </p>
              </>
            ))}
            {veDinheiro && bloco(HandCoins, `Contribuições de ${ano}`, (
              <dl className="grid gap-1.5 text-sm">
                <div className="flex justify-between gap-2"><dt className="text-muted-foreground">Dízimos</dt><dd className="font-medium tabular-nums">{dinheiro(deCentimos(dizimosAno))}</dd></div>
                <div className="flex justify-between gap-2"><dt className="text-muted-foreground">Ofertas</dt><dd className="font-medium tabular-nums">{dinheiro(deCentimos(ofertasAno))}</dd></div>
                <div className="flex justify-between gap-2"><dt className="text-muted-foreground">Reavivamento</dt><dd className="font-medium tabular-nums">{dinheiro(deCentimos(reavAno))}</dd></div>
                {r?.quota != null && (
                  <div className="mt-1 grid gap-1">
                    <div className="flex justify-between text-xs text-muted-foreground"><span>Quota do reavivamento</span><span className="tabular-nums">{dinheiro(r.quota)}</span></div>
                    <span className="block h-1.5 overflow-hidden rounded-[2px] bg-muted"><span className="block h-full bg-primary" style={{ width: `${Math.min(100, centimos(r.quota) ? (centimos(r.contribuido ?? '0') / centimos(r.quota)) * 100 : 0)}%` }} /></span>
                  </div>
                )}
              </dl>
            ))}
            {veCeia && bloco(Wine, `Santa Ceia · ${ano}`, sc ? (
              <>
                <p className="text-sm"><strong className="font-semibold tabular-nums">{sc.participacoes} de {sc.celebracoes}</strong> celebraç{sc.celebracoes === 1 ? 'ão' : 'ões'}</p>
                <p className="text-xs text-muted-foreground">{sc.ultima ? `Última: ${data(sc.ultima)}` : 'Ainda não participou este ano'}</p>
                {sc.faltas > 0 && sc.participacoes > 0 && <Pilula variante="warning" className="justify-self-start">Faltou a {sc.faltas}</Pilula>}
              </>
            ) : <p className="text-sm text-muted-foreground">Sem celebrações com os participantes registados pelo nome este ano.</p>)}
            {veES && bloco(BookOpen, 'Escola Sabatina', chamadas.length ? (
              <>
                <p className="text-sm"><strong className="font-semibold tabular-nums">{presentes} de {chamadas.length}</strong> últimas chamadas presente</p>
                <span className="block h-1.5 overflow-hidden rounded-[2px] bg-muted"><span className={cn('block h-full', presentes / chamadas.length >= 0.75 ? 'bg-success' : presentes / chamadas.length >= 0.5 ? 'bg-warning' : 'bg-destructive')} style={{ width: `${(presentes / chamadas.length) * 100}%` }} /></span>
                {minha?.ultimaParticipacao && <p className="text-xs text-muted-foreground">Última participação: {data(minha.ultimaParticipacao)}</p>}
              </>
            ) : <p className="text-sm text-muted-foreground">Sem chamada nominal registada.</p>)}
          </div>

          {veDisciplina && (
            <section className="flex flex-wrap items-start gap-x-4 gap-y-2 rounded-[2px] border bg-background/40 p-4">
              <h3 className="flex items-center gap-2 text-sm font-semibold"><Gavel className="size-4 text-muted-foreground" aria-hidden />Disciplina</h3>
              {disc.isPending ? <Barra className="h-5 w-48" /> : disciplinas.length ? (
                <ul className="flex flex-wrap gap-2 text-sm">
                  {disciplinas.map((d) => (
                    <li key={d.id}><Pilula variante={d.dataFim >= hojeIso() ? 'destructive' : 'secondary'}>Censura de {data(d.dataInicio)} a {data(d.dataFim)}{d.dataFim >= hojeIso() ? ' · em curso' : ''}</Pilula></li>
                  ))}
                </ul>
              ) : <p className="text-sm text-muted-foreground">Nunca foi disciplinado.</p>}
            </section>
          )}
        </div>
      )}
    </Cartao>
  )
}
