/**
 * Conselho da igreja (F-SEC-07) · "Quem está no conselho, com que cargo, e até quando?"
 * A fonte central para as reuniões (presenças, presidente, secretário). A duração dos mandatos é da igreja e o fim
 * previsto de cada mandato, e o seu estado, vêm da base de dados.
 */
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { CalendarClock, Hourglass, Pencil, Phone, Plus, Search, Settings2, ShieldCheck, UserMinus, Users, Vote } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Avatar, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { Seleccao } from '@/components/comum/Seleccao'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { data, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { ROTULO_MANDATO, VARIANTE_MANDATO, useCargos, useConselho, useConselhoMut, useIgrejaDados, type Oficial } from './api'

type Filtro = 'exercicio' | 'terminar' | 'terminados' | 'todos'

/** Fim previsto que a base de dados vai calcular (só para mostrar antes de gravar). */
function fimPrevisto(inicio: string, anos: number) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(inicio)) return ''
  const d = new Date(`${inicio}T12:00:00Z`)
  d.setUTCFullYear(d.getUTCFullYear() + anos)
  d.setUTCDate(d.getUTCDate() - 1)
  return d.toISOString().slice(0, 10)
}

export default function PaginaConselho() {
  const { pode } = useSessao()
  const q = useConselho()
  const igreja = useIgrejaDados()
  const [filtro, setFiltro] = useState<Filtro>('exercicio')
  const [busca, setBusca] = useState('')
  const [novo, setNovo] = useState(false)
  const [terminar, setTerminar] = useState<Oficial | null>(null)
  const [corrigir, setCorrigir] = useState<Oficial | null>(null)
  const [config, setConfig] = useState(false)
  const anos = igreja.data?.mandatoAnos ?? 1

  const lista = q.data ?? []
  const emExercicio = lista.filter((o) => o.estadoMandato === 'ACTIVO' || o.estadoMandato === 'A_TERMINAR')
  const conselho = emExercicio.filter((o) => o.doConselho)
  const aTerminar = lista.filter((o) => o.estadoMandato === 'A_TERMINAR')
  const terminados = lista.filter((o) => o.estadoMandato === 'TERMINADO')
  const visiveis = useMemo(() => lista
    .filter((o) => filtro === 'todos' || (filtro === 'exercicio' ? o.estadoMandato === 'ACTIVO' || o.estadoMandato === 'A_TERMINAR' || o.estadoMandato === 'FUTURO'
      : filtro === 'terminar' ? o.estadoMandato === 'A_TERMINAR' : o.estadoMandato === 'TERMINADO'))
    .filter((o) => !busca || `${o.membro} ${o.cargo}`.toLowerCase().includes(busca.trim().toLowerCase()))
    .sort((a, b) => Number(b.doConselho) - Number(a.doConselho) || a.cargo.localeCompare(b.cargo, 'pt') || a.membro.localeCompare(b.membro, 'pt')),
  [lista, filtro, busca])

  return (
    <>
      <TituloPagina icone={ShieldCheck} titulo="Conselho da igreja" descricao="Oficiais, cargos e mandatos: a base das reuniões, das presenças e das actas"
        accoes={pode('secretaria.oficial.criar') && (
          <>
            <Button asChild variant="outline" className="alvo"><Link to="/conselho/eleicao"><Vote className="size-4" />Eleição de oficiais</Link></Button>
            <Button className="alvo" onClick={() => setNovo(true)}><Plus className="size-4" />Registar oficial</Button>
          </>
        )} />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-4">
          <Indicador rotulo="No conselho" valor={new Set(conselho.map((o) => o.membroId)).size} nota="membros em exercício" icone={Users} aCarregar={q.isPending}
            aoClicar={() => setFiltro('exercicio')} activo={filtro === 'exercicio'} />
          <Indicador rotulo="Mandatos a terminar" valor={aTerminar.length} nota="nos próximos 60 dias" icone={Hourglass} tom="warning" aCarregar={q.isPending}
            aoClicar={() => setFiltro('terminar')} activo={filtro === 'terminar'} />
          <Indicador rotulo="Mandatos terminados" valor={terminados.length} nota="no histórico" icone={CalendarClock} aCarregar={q.isPending}
            aoClicar={() => setFiltro('terminados')} activo={filtro === 'terminados'} />
          <Indicador rotulo="Duração dos mandatos" valor={`${anos} ${anos === 1 ? 'ano' : 'anos'}`} nota={pode('organizacao.igreja.alterar') ? 'nesta igreja · alterar' : 'definida pela igreja'}
            icone={Settings2} tom="info" aCarregar={igreja.isPending} aoClicar={pode('organizacao.igreja.alterar') ? () => setConfig(true) : undefined} />
        </div>

        <section className="min-w-0 rounded-xl border bg-card shadow-card">
          <div className="flex flex-col gap-3 border-b px-4 py-3 sm:px-6 lg:flex-row lg:items-center lg:justify-between">
            <div role="tablist" aria-label="Filtrar" className="flex flex-wrap gap-1 rounded-lg bg-muted p-1">
              {([['exercicio', 'Em exercício'], ['terminar', 'A terminar'], ['terminados', 'Terminados'], ['todos', 'Todos']] as [Filtro, string][]).map(([k, r]) => (
                <button key={k} type="button" role="tab" aria-selected={filtro === k} onClick={() => setFiltro(k)}
                  className={cn('alvo rounded-md px-3 py-1.5 text-xs font-medium text-muted-foreground', filtro === k && 'bg-card text-foreground shadow-sm')}>{r}</button>
              ))}
            </div>
            <label className="relative block lg:w-64">
              <span className="sr-only">Pesquisar</span>
              <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input type="search" value={busca} onChange={(e) => setBusca(e.target.value)} placeholder="Pesquisar nome ou cargo…" className="alvo pl-9" />
            </label>
          </div>
          {q.isPending ? <LinhasACarregar linhas={5} />
            : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="m-4" />
            : !visiveis.length ? (
              <EstadoVazio icone={ShieldCheck} titulo={lista.length ? 'Nada com este filtro' : 'Ainda não há oficiais registados'}
                accao={!lista.length && pode('secretaria.oficial.criar') && <Button size="sm" onClick={() => setNovo(true)}><Plus className="size-4" />Registar oficial</Button>}>
                {lista.length ? 'Mude o filtro ou a pesquisa.' : 'Registe os oficiais eleitos (anciãos, secretário, tesoureiro, directores): as reuniões usam esta lista.'}
              </EstadoVazio>
            ) : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Oficial</th><th className="hidden md:table-cell">Contacto</th><th className="hidden sm:table-cell">Mandato</th><th>Estado</th><th className="sm:pr-6"><span className="sr-only">Acções</span></th></tr></thead>
                <tbody>
                  {visiveis.map((o) => (
                    <tr key={o.id} className={cn(o.estadoMandato === 'TERMINADO' && 'opacity-70')}>
                      <td className="sm:pl-6">
                        <div className="flex items-center gap-3">
                          <Avatar id={o.membroId} nome={o.membro.split(' ')[0]} apelido={o.membro.split(' ').slice(-1)[0]} tamanho={34} />
                          <div className="min-w-0">
                            <Link to={`/membros/${o.membroId}`} className="font-medium hover:text-primary">{o.membro}</Link>
                            <p className="text-xs text-muted-foreground">{o.cargo}{!o.doConselho && ' · fora do conselho'}</p>
                            <p className="text-xs text-muted-foreground sm:hidden">{data(o.dataInicio)} → {data(o.dataFim ?? o.fimPrevisto)}</p>
                          </div>
                        </div>
                      </td>
                      <td className="hidden md:table-cell">{o.contacto ? <a href={`tel:${o.contacto.replace(/\s/g, '')}`} className="inline-flex items-center gap-1.5 text-sm hover:text-primary"><Phone className="size-3.5 text-muted-foreground" /><span className="num">{o.contacto}</span></a> : <span className="text-muted-foreground">—</span>}</td>
                      <td className="hidden tabular-nums whitespace-nowrap text-muted-foreground sm:table-cell">{data(o.dataInicio)} → {data(o.dataFim ?? o.fimPrevisto)}</td>
                      <td><Pilula variante={VARIANTE_MANDATO[o.estadoMandato]}>{ROTULO_MANDATO[o.estadoMandato]}</Pilula></td>
                      <td className="sm:pr-6">
                        <div className="flex justify-end gap-1">
                          {pode('secretaria.oficial.alterar') && o.estadoMandato !== 'TERMINADO' && (
                            <>
                              <Button variant="ghost" size="icon" className="alvo size-9" title="Corrigir datas" aria-label={`Corrigir o mandato de ${o.membro}`} onClick={() => setCorrigir(o)}><Pencil className="size-4" /></Button>
                              <Button variant="ghost" size="icon" className="alvo size-9 text-muted-foreground" title="Terminar mandato" aria-label={`Terminar o mandato de ${o.membro}`} onClick={() => setTerminar(o)}><UserMinus className="size-4" /></Button>
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </Tabela>
            )}
        </section>
      </div>

      {novo && <DialogoOficial anos={anos} aoFechar={() => setNovo(false)} />}
      {corrigir && <DialogoCorrigir o={corrigir} aoFechar={() => setCorrigir(null)} />}
      {terminar && <DialogoTerminar o={terminar} aoFechar={() => setTerminar(null)} />}
      {config && <DialogoDuracao anos={anos} aoFechar={() => setConfig(false)} />}
    </>
  )
}

function DialogoOficial({ anos, aoFechar }: { anos: number; aoFechar: () => void }) {
  const cargos = useCargos()
  const basicos = useMembrosBasicos()
  const { registar } = useConselhoMut()
  const [membro, setMembro] = useState<number | null>(null)
  const [cargo, setCargo] = useState('')
  const [inicio, setInicio] = useState(`${hojeIso().slice(0, 4)}-01-01`)
  const [erro, setErro] = useState<string | null>(null)
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }
  const lista = (cargos.data ?? []).filter((c) => !c.endDate).sort((a, b) => Number(!!b.conselho) - Number(!!a.conselho) || a.nome.localeCompare(b.nome, 'pt'))
  const submeter = async () => {
    setErro(null)
    if (!membro || !cargo) return setErro('Escolha o membro e o cargo.')
    if (!/^\d{4}-\d{2}-\d{2}$/.test(inicio)) return setErro('Escreva a data de início como dd/mm/aaaa.')
    try {
      await registar.mutateAsync({ membroId: membro, cargoId: Number(cargo), dataInicio: inicio })
      toast.success('Oficial registado.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Registar oficial</DialogTitle>
          <DialogDescription>Membro eleito para um cargo. O mandato dura {anos} {anos === 1 ? 'ano' : 'anos'}, como definido para esta igreja.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5"><label htmlFor="ofi-mem" className="text-sm font-medium">Membro <span className="text-destructive-text">*</span></label>
            <CampoMembro id="ofi-mem" valor={membro} aoMudar={setMembro} nomeDe={nomeDe} /></div>
          <div className="grid gap-1.5"><label htmlFor="ofi-car" className="text-sm font-medium">Cargo <span className="text-destructive-text">*</span></label>
            <Seleccao id="ofi-car" value={cargo} onChange={(e) => setCargo(e.target.value)}>
              <option value="">Escolher…</option>
              <optgroup label="Conselho da igreja">{lista.filter((c) => c.conselho).map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}</optgroup>
              <optgroup label="Outros cargos">{lista.filter((c) => !c.conselho).map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}</optgroup>
            </Seleccao></div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-1.5"><label htmlFor="ofi-ini" className="text-sm font-medium">Início do mandato</label>
              <CampoData id="ofi-ini" value={inicio} onChange={setInicio} className="alvo" /></div>
            <div className="grid gap-1.5"><span className="text-sm font-medium">Fim previsto</span>
              <p className="flex h-9 items-center rounded-md border border-dashed px-3 text-sm text-muted-foreground tabular-nums">{fimPrevisto(inicio, anos) ? data(fimPrevisto(inicio, anos)) : '—'}</p></div>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={registar.isPending} onClick={submeter}>{registar.isPending ? t.comum.aGravar : 'Registar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function DialogoCorrigir({ o, aoFechar }: { o: Oficial; aoFechar: () => void }) {
  const { corrigir } = useConselhoMut()
  const [inicio, setInicio] = useState(o.dataInicio)
  const [fim, setFim] = useState(o.fimPrevisto ?? '')
  const [erro, setErro] = useState<string | null>(null)
  const submeter = async () => {
    setErro(null)
    try {
      await corrigir.mutateAsync({ id: o.id, dataInicio: inicio, fimPrevisto: fim || null })
      toast.success('Mandato actualizado.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader><DialogTitle>Mandato de {o.membro}</DialogTitle><DialogDescription>{o.cargo}</DialogDescription></DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-1.5"><label htmlFor="cor-ini" className="text-sm font-medium">Início</label><CampoData id="cor-ini" value={inicio} onChange={setInicio} className="alvo" /></div>
            <div className="grid gap-1.5"><label htmlFor="cor-fim" className="text-sm font-medium">Fim previsto</label><CampoData id="cor-fim" value={fim} onChange={setFim} className="alvo" /></div>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={corrigir.isPending} onClick={submeter}>{corrigir.isPending ? t.comum.aGravar : t.comum.guardar}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function DialogoTerminar({ o, aoFechar }: { o: Oficial; aoFechar: () => void }) {
  const { terminarMandato } = useConselhoMut()
  const [fim, setFim] = useState(hojeIso())
  const [erro, setErro] = useState<string | null>(null)
  const submeter = async () => {
    setErro(null)
    try {
      await terminarMandato.mutateAsync({ id: o.id, dataFim: fim })
      toast.success(`Mandato de ${o.membro} terminado.`)
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader><DialogTitle>Terminar o mandato</DialogTitle><DialogDescription>{o.membro} · {o.cargo}. Fica no histórico do conselho.</DialogDescription></DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5"><label htmlFor="ter-fim" className="text-sm font-medium">Terminou em</label><CampoData id="ter-fim" value={fim} onChange={setFim} className="alvo" /></div>
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo bg-destructive text-white hover:bg-destructive/90" disabled={terminarMandato.isPending} onClick={submeter}>{terminarMandato.isPending ? t.comum.aGravar : 'Terminar mandato'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function DialogoDuracao({ anos, aoFechar }: { anos: number; aoFechar: () => void }) {
  const { duracao } = useConselhoMut()
  const [valor, setValor] = useState(String(anos))
  const [erro, setErro] = useState<string | null>(null)
  const submeter = async () => {
    setErro(null)
    try {
      await duracao.mutateAsync(Number(valor))
      toast.success(`Os novos mandatos passam a durar ${valor} ${valor === '1' ? 'ano' : 'anos'}.`)
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader><DialogTitle>Duração dos mandatos</DialogTitle><DialogDescription>Vale para os oficiais registados a partir de agora; os mandatos em curso mantêm o fim previsto (pode corrigi-lo em cada um).</DialogDescription></DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div role="radiogroup" aria-label="Duração" className="grid grid-cols-5 gap-2">
            {['1', '2', '3', '4', '5'].map((n) => (
              <button key={n} type="button" role="radio" aria-checked={valor === n} onClick={() => setValor(n)}
                className={cn('alvo rounded-lg border py-2 text-sm font-semibold', valor === n ? 'border-primary bg-primary/10 text-primary' : 'text-muted-foreground')}>
                {n}<span className="block text-[11px] font-normal">{n === '1' ? 'ano' : 'anos'}</span>
              </button>
            ))}
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={duracao.isPending} onClick={submeter}>{duracao.isPending ? t.comum.aGravar : t.comum.guardar}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
