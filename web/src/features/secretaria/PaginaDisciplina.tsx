/**
 * Disciplina (F-SEC-07, P-03): censura votada pela igreja (reunião regular ou assembleia), de 1 a 12 meses. Ao
 * aplicá-la o membro deixa os cargos; se for menor, os pais ou o encarregado têm de ser avisados; durante a
 * censura não recebe carta de transferência. A remoção por disciplina é um movimento do livro de membros (voto em
 * assembleia administrativa) e faz-se na ficha do membro. O motivo é dado sensível: só o vê quem pode.
 */
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { Gavel, Plus, ShieldAlert, X } from 'lucide-react'
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
import { data, diasAte, hojeIso, idade } from '@/lib/formatos'
import { useMembro, useMembrosBasicos } from '@/features/membros/api'
import { CampoVoto } from '@/features/livro/CampoVoto'
import { useDisciplinaMut, useDisciplinas, type Disciplina } from './api'

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
  const hoje = hojeIso()
  const nomeDe = (id: number) => { const m = membros.data?.find((x) => x.id === id); return m ? `${m.nome} ${m.apelido}` : `Membro n.º ${id}` }
  const lista = useMemo(() => (q.data ?? []).filter((d) => !d.endDate), [q.data])
  const activas = lista.filter((d) => d.dataInicio <= hoje && hoje < d.dataFim)
  const futuras = lista.filter((d) => d.dataInicio > hoje)
  const estado = (d: Disciplina) => d.dataInicio > hoje ? { r: 'A começar', v: 'info' as const } : hoje < d.dataFim ? { r: 'Em censura', v: 'warning' as const } : { r: 'Cumprida', v: 'secondary' as const }

  return (
    <>
      <TituloPagina icone={Gavel} titulo="Disciplina" descricao="Censuras votadas pela igreja (1 a 12 meses)"
        accoes={pode('secretaria.disciplina.criar') && <Button className="alvo" onClick={() => setNova(true)}><Plus className="size-4" />Aplicar censura</Button>} />
      {q.isPending ? <Barra className="h-64 w-full" /> : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} /> : (
        <div className="grid gap-6">
          <div className="grid gap-3 sm:grid-cols-3">
            <Indicador rotulo="Em censura agora" valor={String(activas.length)} icone={ShieldAlert} tom="warning" />
            <Indicador rotulo="A começar" valor={String(futuras.length)} icone={Gavel} tom="info" />
            <Indicador rotulo="Registadas" valor={String(lista.length)} icone={Gavel} tom="primary" />
          </div>
          <Cartao semMargem>
            {!lista.length ? (
              <EstadoVazio icone={Gavel} titulo="Nenhuma censura registada">
                A censura é votada em reunião regular ou assembleia administrativa e dura de 1 a 12 meses.
              </EstadoVazio>
            ) : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Membro</th><th>Período</th><th className="hidden lg:table-cell">Motivo</th><th>Estado</th><th className="sm:pr-6"><span className="sr-only">Acções</span></th></tr></thead>
                <tbody>
                  {lista.map((d) => {
                    const e = estado(d)
                    const dias = diasAte(d.dataFim)
                    return (
                      <tr key={d.id}>
                        <td className="sm:pl-6"><Link to={`/membros/${d.membroId}`} className="font-medium hover:underline">{nomeDe(d.membroId)}</Link></td>
                        <td className="tabular-nums">
                          <p>{data(d.dataInicio)} a {data(d.dataFim)}</p>
                          {e.r === 'Em censura' && <p className="text-xs text-muted-foreground">termina dentro de {dias} dia{dias === 1 ? '' : 's'}</p>}
                        </td>
                        <td className="hidden max-w-72 truncate text-muted-foreground lg:table-cell" title={d.motivo ?? undefined}>{d.motivo || '—'}</td>
                        <td><Pilula variante={e.v}>{e.r}</Pilula></td>
                        <td className="text-right sm:pr-6">
                          {pode('secretaria.disciplina.terminar') && e.r !== 'Cumprida' && (
                            <Button size="sm" variant="ghost" className="alvo text-muted-foreground" onClick={() => setAAnular(d)}><X className="size-4" />Anular</Button>
                          )}
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </Tabela>
            )}
          </Cartao>
          <p className="text-sm text-muted-foreground">
            A remoção de um membro por disciplina (voto em assembleia administrativa) regista-se na ficha do membro, no cartão <b>Livro de membros › Registar saída do livro</b>.
          </p>
        </div>
      )}
      {nova && <DialogoCensura aoFechar={() => setNova(false)} />}
      <DialogoConfirmar aberto={!!aAnular} aoMudar={(v) => !v && setAAnular(null)} perigo titulo="Anular esta censura?" accao="Anular"
        texto="Use só para corrigir um registo errado. Os cargos que o membro deixou não voltam automaticamente." aCorrer={anular.isPending}
        aoConfirmar={() => aAnular && anular.mutate(aAnular.id, { onSuccess: () => { setAAnular(null); toast.success('Censura anulada.') }, onError: (e) => toast.error(mensagemDe(e)) })} />
    </>
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
