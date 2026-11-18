/**
 * Disciplina (F-SEC-07, P-03): censura votada pela igreja (reunião regular ou assembleia), de 1 a 12 meses. Ao
 * aplicá-la o membro deixa os cargos; se for menor, os pais ou o encarregado têm de ser avisados; durante a
 * censura não recebe carta de transferência. A remoção por disciplina é um movimento do livro de membros (voto em
 * assembleia administrativa) e faz-se na ficha do membro. O motivo é dado sensível: só o vê quem pode.
 */
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { Eye, Gavel, Plus, ShieldAlert, UserX, X } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { Seleccao } from '@/components/comum/Seleccao'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { data, diasAte, hojeIso, hora, idade } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembro, useMembrosBasicos } from '@/features/membros/api'
import { CampoVoto } from '@/features/livro/CampoVoto'
import { DialogoMovimento } from '@/features/livro/MovimentosMembro'
import { lerMotivoCensura, useAcessosConfidenciais, useDisciplinaMut, useDisciplinas, useRemovidos, type Disciplina } from './api'
import { useUsuarios } from '@/features/acessos/api'
import { useQuery } from '@tanstack/react-query'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

/** Data + n meses (aaaa-mm-dd), como o PostgreSQL faz com INTERVAL. */
export function somarMeses(iso: string, n: number): string {
  const [a, m, d] = iso.split('-').map(Number)
  const alvo = new Date(Date.UTC(a, m - 1 + n, 1))
  const ultimo = new Date(Date.UTC(alvo.getUTCFullYear(), alvo.getUTCMonth() + 1, 0)).getUTCDate()
  alvo.setUTCDate(Math.min(d, ultimo))
  return alvo.toISOString().slice(0, 10)
}

export default function PaginaDisciplina() {
  const { pode } = useSessao()
  const q = useDisciplinas()
  const membros = useMembrosBasicos()
  const { anular } = useDisciplinaMut()
  const [nova, setNova] = useState(false)
  const [aAnular, setAAnular] = useState<Disciplina | null>(null)
  const [motivoDe, setMotivoDe] = useState<Disciplina | null>(null)
  const [aba, setAba] = useState('censuras')
  const veAcessos = pode('nucleo.acesso_confidencial.ler')
  const [remover, setRemover] = useState(false)
  const removidos = useRemovidos(pode('secretaria.movimento_membro.ler'))
  const acessos = useAcessosConfidenciais(veAcessos && aba === 'acessos')
  const hoje = hojeIso()
  const ano = hoje.slice(0, 4)
  const nomeDe = (id: number) => { const m = membros.data?.find((x) => x.id === id); return m ? `${m.nome} ${m.apelido}` : `Membro n.º ${id}` }
  const lista = useMemo(() => (q.data ?? []).filter((d) => !d.endDate), [q.data])
  const activas = lista.filter((d) => d.dataInicio <= hoje && hoje < d.dataFim)
  const aTerminar = activas.filter((d) => diasAte(d.dataFim) <= 30)
  const doAno = lista.filter((d) => d.dataInicio.startsWith(ano))
  const removidosAno = (removidos.data ?? []).filter((m) => !m.endDate && m.data.startsWith(ano))
  const estado = (d: Disciplina) => d.dataInicio > hoje ? { r: 'A começar', v: 'info' as const } : hoje < d.dataFim ? { r: 'Em censura', v: 'warning' as const } : { r: 'Cumprida', v: 'secondary' as const }
  const progresso = (d: Disciplina) => {
    const total = Date.parse(d.dataFim) - Date.parse(d.dataInicio)
    const feito = Math.min(Math.max(Date.parse(hoje) - Date.parse(d.dataInicio), 0), total)
    return total > 0 ? Math.round((feito / total) * 100) : 0
  }
  const ordenadas = [...lista].sort((a, b) => Number(estado(b).r === 'Em censura') - Number(estado(a).r === 'Em censura') || b.dataInicio.localeCompare(a.dataInicio))

  return (
    <>
      <TituloPagina icone={Gavel} titulo="Disciplina" descricao="Censuras votadas pela igreja (1 a 12 meses) e remoções do livro · informação confidencial"
        accoes={(
          <>
            {pode('secretaria.movimento_membro.criar') && <Button variant="outline" className="alvo" onClick={() => setRemover(true)}><UserX className="size-4" />Registar remoção</Button>}
            {pode('secretaria.disciplina.criar') && <Button className="alvo" onClick={() => setNova(true)}><Plus className="size-4" />Aplicar censura</Button>}
          </>
        )} />
      {q.isPending ? <Barra className="h-64 w-full" /> : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} /> : (
        <div className="grid gap-6">
          <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
            <Indicador rotulo="Em censura agora" valor={String(activas.length)} icone={ShieldAlert} tom="warning" destaque={activas.length > 0} />
            <Indicador rotulo="Terminam em 30 dias" valor={String(aTerminar.length)} icone={Gavel} tom="info" nota="voltam à situação regular" />
            <Indicador rotulo={`Censuras em ${ano}`} valor={String(doAno.length)} icone={Gavel} nota={`${lista.length} registadas no total`} />
            <Indicador rotulo={`Removidos em ${ano}`} valor={removidos.isPending ? '—' : String(removidosAno.length)} icone={UserX} tom="destructive"
              nota={`${removidosAno.filter((m) => m.tipo === 'REMOCAO_DISCIPLINA').length} por disciplina · ${removidosAno.filter((m) => m.tipo === 'REMOCAO_PEDIDO').length} a pedido`} />
          </div>
          <Tabs value={aba} onValueChange={setAba}>
            <TabsList className="mb-4">
              <TabsTrigger value="censuras" className="alvo">Censuras</TabsTrigger>
              <TabsTrigger value="removidos" className="alvo">Removidos</TabsTrigger>
              {veAcessos && <TabsTrigger value="acessos" className="alvo">Registo de acessos</TabsTrigger>}
            </TabsList>
            <TabsContent value="censuras" className="mt-0">
              <Cartao semMargem>
                {!lista.length ? (
                  <EstadoVazio icone={Gavel} titulo="Nenhuma censura registada">
                    A censura é votada em reunião regular ou assembleia administrativa e dura de 1 a 12 meses.
                  </EstadoVazio>
                ) : (
                  <Tabela>
                    <thead><tr><th className="sm:pl-6">Membro</th><th>Período</th><th className="hidden md:table-cell">Tempo cumprido</th><th>Estado</th><th className="sm:pr-6"><span className="sr-only">Acções</span></th></tr></thead>
                    <tbody>
                      {ordenadas.map((d) => {
                        const e = estado(d)
                        const dias = diasAte(d.dataFim)
                        const pct = progresso(d)
                        return (
                          <tr key={d.id}>
                            <td className="sm:pl-6"><Link to={`/membros/${d.membroId}`} className="font-medium hover:underline">{nomeDe(d.membroId)}</Link></td>
                            <td className="tabular-nums">
                              <p>{data(d.dataInicio)} a {data(d.dataFim)}</p>
                              {e.r === 'Em censura' && <p className="text-xs text-muted-foreground">faltam {dias} dia{dias === 1 ? '' : 's'}</p>}
                              {e.r === 'A começar' && <p className="text-xs text-muted-foreground">começa dentro de {diasAte(d.dataInicio)} dia(s)</p>}
                            </td>
                            <td className="hidden w-48 md:table-cell">
                              <div className="flex items-center gap-2">
                                <span className="h-2 flex-1 overflow-hidden rounded-full bg-muted" role="progressbar" aria-valuenow={pct} aria-valuemin={0} aria-valuemax={100} aria-label="Tempo cumprido">
                                  <span className={cn('block h-full rounded-full', e.r === 'Cumprida' ? 'bg-muted-foreground/40' : 'bg-warning')} style={{ width: `${pct}%` }} />
                                </span>
                                <span className="w-10 text-right text-xs tabular-nums text-muted-foreground">{pct}%</span>
                              </div>
                            </td>
                            <td><Pilula variante={e.v}>{e.r}</Pilula></td>
                            <td className="text-right whitespace-nowrap sm:pr-6">
                              <Button size="sm" variant="ghost" className="alvo text-muted-foreground" onClick={() => setMotivoDe(d)}><Eye className="size-4" /><span className="hidden sm:inline">Motivo</span></Button>
                              {pode('secretaria.disciplina.terminar') && e.r !== 'Cumprida' && (
                                <Button size="sm" variant="ghost" className="alvo text-muted-foreground" onClick={() => setAAnular(d)}><X className="size-4" /><span className="hidden sm:inline">Anular</span></Button>
                              )}
                            </td>
                          </tr>
                        )
                      })}
                    </tbody>
                  </Tabela>
                )}
              </Cartao>
            </TabsContent>
            <TabsContent value="removidos" className="mt-0">
              <Cartao semMargem>
                {removidos.isPending ? <Barra className="m-4 h-24" /> : removidos.isError ? <EstadoErro erro={removidos.error} className="m-4" /> : !(removidos.data ?? []).length ? (
                  <EstadoVazio icone={UserX} titulo="Nenhuma remoção registada"
                    accao={pode('secretaria.movimento_membro.criar') && <Button variant="outline" className="alvo" onClick={() => setRemover(true)}>Registar remoção</Button>}>
                    A remoção (por disciplina ou a pedido) regista-se com o voto da igreja.
                  </EstadoVazio>
                ) : (
                  <Tabela>
                    <thead><tr><th className="sm:pl-6">Membro</th><th>Data</th><th>Motivo da saída</th><th className="hidden md:table-cell sm:pr-6">Observações</th></tr></thead>
                    <tbody>
                      {[...(removidos.data ?? [])].filter((m) => !m.endDate).sort((a, b) => b.data.localeCompare(a.data)).map((m) => (
                        <tr key={m.id}>
                          <td className="sm:pl-6"><Link to={`/membros/${m.membroId}`} className="font-medium hover:underline">{nomeDe(m.membroId)}</Link></td>
                          <td className="tabular-nums">{data(m.data)}</td>
                          <td><Pilula variante={m.tipo === 'REMOCAO_DISCIPLINA' ? 'destructive' : 'secondary'}>{m.tipo === 'REMOCAO_DISCIPLINA' ? 'Por disciplina' : 'A pedido'}</Pilula></td>
                          <td className="hidden text-muted-foreground md:table-cell sm:pr-6">{m.observacoes || '—'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </Tabela>
                )}
              </Cartao>
            </TabsContent>
            {veAcessos && (
              <TabsContent value="acessos" className="mt-0">
                <RegistoAcessos acessos={acessos} nomeDe={nomeDe} disciplinas={lista} />
              </TabsContent>
            )}
          </Tabs>
          <p className="text-sm text-muted-foreground">
            O motivo de cada censura é confidencial: não aparece nas listas e cada consulta fica registada (quem, quando). O histórico de alterações guarda só que o motivo mudou.
          </p>
        </div>
      )}
      {nova && <DialogoCensura aoFechar={() => setNova(false)} />}
      {motivoDe && <DialogoMotivo d={motivoDe} nome={nomeDe(motivoDe.membroId)} aoFechar={() => setMotivoDe(null)} />}
      <DialogoConfirmar aberto={!!aAnular} aoMudar={(v) => !v && setAAnular(null)} perigo titulo="Anular esta censura?" accao="Anular"
        texto="Use só para corrigir um registo errado. Os cargos que o membro deixou não voltam automaticamente." aCorrer={anular.isPending}
        aoConfirmar={() => aAnular && anular.mutate(aAnular.id, { onSuccess: () => { setAAnular(null); toast.success('Censura anulada.') }, onError: (e) => toast.error(mensagemDe(e)) })} />
      {remover && <DialogoMovimento m={null} sentido="saida" aberto tipos={['REMOCAO_DISCIPLINA', 'REMOCAO_PEDIDO']} aoMudar={(v) => !v && setRemover(false)} />}
    </>
  )
}

/** O motivo só se lê aqui, a pedido: a base de dados regista a consulta. */
function DialogoMotivo({ d, nome, aoFechar }: { d: Disciplina; nome: string; aoFechar: () => void }) {
  const [ver, setVer] = useState(false)
  const q = useQuery({ enabled: ver, queryKey: ['motivo-censura', d.id], queryFn: () => lerMotivoCensura(d.id), staleTime: 0, gcTime: 0 })
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Motivo da censura</DialogTitle>
          <DialogDescription>{nome} · {data(d.dataInicio)} a {data(d.dataFim)}</DialogDescription>
        </DialogHeader>
        {!ver ? (
          <p className="rounded-lg border border-warning/40 bg-tint-warning px-3 py-2 text-sm text-warning-text">
            Informação confidencial. A consulta fica registada com o seu nome, a data e a hora.
          </p>
        ) : q.isPending ? <Barra className="h-16 w-full" /> : q.isError ? <EstadoErro erro={q.error} /> : (
          <p className="text-sm whitespace-pre-line">{q.data || 'Sem motivo registado.'}</p>
        )}
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.fechar ?? 'Fechar'}</Button>
          {!ver && <Button className="alvo" onClick={() => setVer(true)}><Eye className="size-4" />Ver o motivo</Button>}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function RegistoAcessos({ acessos, nomeDe, disciplinas }: {
  acessos: ReturnType<typeof useAcessosConfidenciais>; nomeDe: (id: number) => string; disciplinas: Disciplina[]
}) {
  const usuarios = useUsuarios()
  const quem = (id?: number | null) => (id ? usuarios.data?.find((u) => u.id === id)?.nome ?? `Utilizador n.º ${id}` : 'Sistema')
  const deQuem = (registo: number) => { const d = disciplinas.find((x) => x.id === registo); return d ? nomeDe(d.membroId) : `Censura n.º ${registo}` }
  return (
    <Cartao semMargem>
      {acessos.isPending ? <Barra className="m-4 h-24" /> : acessos.isError ? <EstadoErro erro={acessos.error} className="m-4" /> : !(acessos.data ?? []).length ? (
        <EstadoVazio icone={Eye} titulo="Ninguém consultou dados confidenciais">Cada consulta ao motivo de uma censura aparece aqui.</EstadoVazio>
      ) : (
        <Tabela>
          <thead><tr><th className="sm:pl-6">Quando</th><th>Quem consultou</th><th>O quê</th><th className="sm:pr-6">Registo</th></tr></thead>
          <tbody>
            {(acessos.data ?? []).map((a) => (
              <tr key={a.id}>
                <td className="tabular-nums sm:pl-6">{data(a.criadoEm)} {hora(a.criadoEm)}</td>
                <td className="font-medium">{quem(a.usuarioId)}</td>
                <td>{a.accao === 'LER_MOTIVO' ? 'Motivo de censura' : a.accao}</td>
                <td className="sm:pr-6">{a.tabela === 'secretaria.disciplina' ? deQuem(a.registoId) : `${a.tabela} n.º ${a.registoId}`}</td>
              </tr>
            ))}
          </tbody>
        </Tabela>
      )}
    </Cartao>
  )
}

function DialogoCensura({ aoFechar }: { aoFechar: () => void }) {
  const membros = useMembrosBasicos()
  const { aplicar } = useDisciplinaMut()
  const [membro, setMembro] = useState<number | null>(null)
  const ficha = useMembro(membro ?? 0)
  const [voto, setVoto] = useState('')
  const [inicio, setInicio] = useState(hojeIso())
  const [meses, setMeses] = useState('3')
  const [avisado, setAvisado] = useState(false)
  const [motivo, setMotivo] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const nomeDe = (id: number) => { const m = membros.data?.find((x) => x.id === id); return m ? `${m.nome} ${m.apelido}` : undefined }
  const anos = membro && ficha.data ? idade(ficha.data.dataNascimento) : null
  const menor = anos != null && anos < 18
  const fim = /^\d{4}-\d{2}-\d{2}$/.test(inicio) ? somarMeses(inicio, Number(meses)) : null

  const submeter = () => {
    setErro(null)
    if (!membro) return setErro('Escolha o membro.')
    if (!voto) return setErro('Escolha o voto da igreja.')
    if (!fim) return setErro('Escreva a data de início como dd/mm/aaaa.')
    if (menor && !avisado) return setErro('O membro é menor: confirme que os pais ou o encarregado foram avisados.')
    aplicar.mutate({ membroId: membro, votoId: Number(voto), dataInicio: inicio, dataFim: fim, encarregadoNotificado: avisado, motivo: motivo.trim() || undefined }, {
      onSuccess: () => { toast.success('Censura registada. O membro deixou os cargos que tinha.'); aoFechar() }, onError: (e) => setErro(mensagemDe(e)),
    })
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Aplicar censura</DialogTitle>
          <DialogDescription>Votada pela igreja em reunião regular ou assembleia administrativa. O membro deixa os cargos e não recebe carta de transferência durante a censura.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5">
            <label htmlFor="dsc-membro" className="text-sm font-medium">Membro <span className="text-destructive-text">*</span></label>
            <CampoMembro id="dsc-membro" valor={membro} aoMudar={setMembro} nomeDe={nomeDe} />
          </div>
          <div className="grid gap-1.5">
            <label htmlFor="dsc-voto" className="text-sm font-medium">Voto <span className="text-destructive-text">*</span></label>
            <CampoVoto id="dsc-voto" valor={voto} aoMudar={setVoto} reunioes={['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA']} preferir="DISCIPLINA" />
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="grid gap-1.5">
              <label htmlFor="dsc-ini" className="text-sm font-medium">Início</label>
              <CampoData id="dsc-ini" value={inicio} onChange={setInicio} className="alvo" />
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="dsc-meses" className="text-sm font-medium">Duração</label>
              <Seleccao id="dsc-meses" value={meses} onChange={(e) => setMeses(e.target.value)}>
                {Array.from({ length: 12 }, (_, i) => i + 1).map((n) => <option key={n} value={n}>{n} {n === 1 ? 'mês' : 'meses'}</option>)}
              </Seleccao>
            </div>
          </div>
          {fim && <p className="-mt-2 text-xs text-muted-foreground">Termina a {data(fim)}.</p>}
          {menor && (
            <label className="flex items-start gap-3 rounded-lg border border-warning/40 bg-warning/5 px-3 py-2.5 text-sm">
              <input type="checkbox" checked={avisado} onChange={(e) => setAvisado(e.target.checked)} className="mt-0.5 size-4 accent-[var(--color-primary)]" />
              <span><b>O membro tem {anos} anos.</b> Confirmo que os pais ou o encarregado foram avisados.</span>
            </label>
          )}
          <div className="grid gap-1.5">
            <label htmlFor="dsc-motivo" className="text-sm font-medium">Motivo <span className="font-normal text-muted-foreground">(confidencial)</span></label>
            <textarea id="dsc-motivo" value={motivo} onChange={(e) => setMotivo(e.target.value)} rows={3} maxLength={1000}
              className="w-full rounded-md border border-input bg-card px-3 py-2 text-sm focus-visible:ring-2 focus-visible:ring-ring/50 focus-visible:outline-none" />
            <p className="text-xs text-muted-foreground">Só o secretário, o pastor e os anciãos o vêem.</p>
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={aplicar.isPending} onClick={submeter}>{aplicar.isPending ? t.comum.aGravar : 'Registar censura'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
