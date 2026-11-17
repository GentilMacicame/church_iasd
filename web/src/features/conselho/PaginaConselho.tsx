/**
 * Mandatos, conselho e direcção (F-SEC-07, V31) · "Quem serve neste mandato, em que órgão, e até quando?"
 *
 *   Mandato (período com duração)
 *     ├── Conselho da igreja  → oficiais (cargo, membro, contacto)
 *     └── Direcção            → oficiais (cargo, membro, contacto)
 *
 * O mandato define o início e o fim dos oficiais (a base de dados copia-os e acompanha mudanças de datas);
 * o órgão vem do cargo e pode mudar-se. O conselho é a fonte das reuniões (presenças, presidente, secretário).
 */
import { useMemo, useState, type ReactNode } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import {
  ArrowRightLeft, Briefcase, CalendarPlus, Eye, CalendarRange, Link2, MoreHorizontal, Pencil, Phone, Plus, ShieldCheck, Trash2,
  UserMinus, UserPlus, Users, Vote,
} from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { Avatar, IconeTom, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { CampoEscolha } from '@/components/comum/CampoEscolha'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { Seleccao } from '@/components/comum/Seleccao'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { data, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { DialogoMandato } from './DialogoMandato'
import { ISO, anosInteiros, diaSeguinte, duracaoTexto } from './mandatos'
import {
  ROTULO_MANDATO, ROTULO_ORGAO, VARIANTE_MANDATO, useCargos, useConselho, useConselhoMut, useIgrejaDados, useMandatos,
  vigencia, type Mandato, type Oficial, type Orgao,
} from './api'

const SEM_MANDATO = 'sem'
const ORGAOS: { orgao: Orgao; icone: typeof Users; descricao: string }[] = [
  { orgao: 'CONSELHO', icone: Users, descricao: 'Administra a igreja entre as reuniões: decide, recomenda e vota' },
  { orgao: 'DIRECCAO', icone: Briefcase, descricao: 'Dirige os departamentos e ministérios da igreja' },
]

export default function PaginaConselho() {
  const { pode } = useSessao()
  const q = useConselho()
  const mandatos = useMandatos()
  const igreja = useIgrejaDados()
  const [params, setParams] = useSearchParams()
  const [novoMandato, setNovoMandato] = useState(false)
  const [editar, setEditar] = useState<Mandato | null>(null)
  // duração por defeito de um mandato novo: a do último mandato; senão a definida para a igreja
  const anos = (mandatos.data?.[0] && anosInteiros(mandatos.data[0].dataInicio, mandatos.data[0].dataFim)) || igreja.data?.mandatoAnos || 1

  const lista = useMemo(() => q.data ?? [], [q.data])
  const listaMandatos = useMemo(() => mandatos.data ?? [], [mandatos.data])
  const semMandato = lista.filter((o) => o.mandatoId == null)
  const porMandato = useMemo(() => {
    const m = new Map<number, Oficial[]>()
    for (const o of lista) if (o.mandatoId != null) m.set(o.mandatoId, [...(m.get(o.mandatoId) ?? []), o])
    return m
  }, [lista])

  // mandato escolhido: o do endereço; senão o actual; senão o próximo; senão o mais recente
  const pedido = params.get('mandato')
  const actual = listaMandatos.find((m) => ['ACTIVO', 'A_TERMINAR'].includes(vigencia(m)))
  const proximo = [...listaMandatos].reverse().find((m) => vigencia(m) === 'FUTURO')
  const escolhido = pedido === SEM_MANDATO && semMandato.length ? SEM_MANDATO
    : listaMandatos.find((m) => String(m.id) === pedido)?.id ?? actual?.id ?? proximo?.id ?? listaMandatos[0]?.id ?? (semMandato.length ? SEM_MANDATO : null)
  const escolher = (v: number | typeof SEM_MANDATO) => setParams((p) => { p.set('mandato', String(v)); return p }, { replace: true })
  const mandato = typeof escolhido === 'number' ? listaMandatos.find((m) => m.id === escolhido) ?? null : null
  const sugestaoInicio = listaMandatos.length ? diaSeguinte(listaMandatos[0].dataFim) : `${hojeIso().slice(0, 4)}-01-01`

  const aCarregar = q.isPending || mandatos.isPending
  const erro = q.error ?? mandatos.error

  return (
    <>
      <TituloPagina icone={ShieldCheck} titulo="Mandatos, conselho e direcção"
        descricao="Cada mandato tem o seu período; dentro dele, os oficiais servem no conselho da igreja ou na direcção"
        accoes={pode('secretaria.mandato.criar') && (
          <>
            <Button asChild variant="outline" className="alvo"><Link to="/conselho/eleicao"><Vote className="size-4" />Eleição de oficiais</Link></Button>
            <Button className="alvo" onClick={() => setNovoMandato(true)}><CalendarPlus className="size-4" />Novo mandato</Button>
          </>
        )} />

      {aCarregar ? (
        <div className="grid gap-4"><Barra className="h-24 w-full" /><Barra className="h-40 w-full" /><Barra className="h-72 w-full" /></div>
      ) : erro ? (
        <EstadoErro erro={erro} aoTentar={() => { void q.refetch(); void mandatos.refetch() }} />
      ) : escolhido == null ? (
        <section className="rounded-xl border bg-card shadow-card">
          <EstadoVazio icone={CalendarRange} titulo="Ainda não há mandatos"
            accao={pode('secretaria.mandato.criar') && <Button onClick={() => setNovoMandato(true)}><CalendarPlus className="size-4" />Criar o primeiro mandato</Button>}>
            Crie o mandato (por exemplo, 2027–2028) e depois acrescente os oficiais eleitos: uns no conselho da igreja, outros na direcção.
          </EstadoVazio>
        </section>
      ) : (
        <div className="grid gap-6">
          <LinhaMandatos mandatos={listaMandatos} porMandato={porMandato} semMandato={semMandato.length} escolhido={escolhido} aoEscolher={escolher}
            aoNovo={pode('secretaria.mandato.criar') ? () => setNovoMandato(true) : undefined} />
          {mandato
            ? <PainelMandato key={mandato.id} mandato={mandato} oficiais={porMandato.get(mandato.id) ?? []} aoEditar={() => setEditar(mandato)} />
            : <PainelSemMandato oficiais={semMandato} mandatos={listaMandatos} />}
        </div>
      )}

      {novoMandato && <DialogoMandato anosPadrao={anos} inicioSugerido={sugestaoInicio} aoFechar={() => setNovoMandato(false)} aoGravar={(id) => escolher(id)} />}
      {editar && <DialogoMandato mandato={editar} anosPadrao={anos} inicioSugerido={editar.dataInicio} aoFechar={() => setEditar(null)} />}
    </>
  )
}

/* ------------------------------------------------------------------ linha do tempo dos mandatos */

function LinhaMandatos({ mandatos, porMandato, semMandato, escolhido, aoEscolher, aoNovo }: {
  mandatos: Mandato[]; porMandato: Map<number, Oficial[]>; semMandato: number; escolhido: number | string
  aoEscolher: (v: number | typeof SEM_MANDATO) => void; aoNovo?: () => void
}) {
  return (
    <nav aria-label="Mandatos" className="-mx-4 overflow-x-auto px-4 pb-1 sm:mx-0 sm:px-0">
      <ol className="flex min-w-max gap-3">
        {mandatos.map((m) => {
          const v = vigencia(m)
          const n = (porMandato.get(m.id) ?? []).filter((o) => o.estadoMandato !== 'TERMINADO' || v === 'TERMINADO').length
          const activo = escolhido === m.id
          return (
            <li key={m.id}>
              <button type="button" onClick={() => aoEscolher(m.id)} aria-current={activo ? 'true' : undefined}
                className={cn('alvo flex w-60 flex-col items-start gap-1 rounded-xl border bg-card p-4 text-left shadow-card transition hover:border-primary/40',
                  activo && 'border-primary ring-1 ring-primary', v === 'TERMINADO' && !activo && 'opacity-75')}>
                <Pilula variante={VARIANTE_MANDATO[v]}>{v === 'ACTIVO' ? 'Actual' : ROTULO_MANDATO[v]}</Pilula>
                <span className="mt-1 font-semibold">{m.nome}</span>
                <span className="text-xs text-muted-foreground tabular-nums">{data(m.dataInicio)} → {data(m.dataFim)}</span>
                <span className="text-xs text-muted-foreground">{duracaoTexto(m.dataInicio, m.dataFim)} · {n} {n === 1 ? 'oficial' : 'oficiais'}</span>
              </button>
            </li>
          )
        })}
        {semMandato > 0 && (
          <li>
            <button type="button" onClick={() => aoEscolher(SEM_MANDATO)} aria-current={escolhido === SEM_MANDATO ? 'true' : undefined}
              className={cn('alvo flex h-full w-60 flex-col gap-1.5 rounded-xl border border-dashed border-warning/60 bg-tint-warning/40 p-4 text-left transition',
                escolhido === SEM_MANDATO && 'ring-1 ring-warning')}>
              <span className="font-semibold">Sem mandato</span>
              <span className="text-xs text-warning-text">{semMandato} {semMandato === 1 ? 'oficial por associar' : 'oficiais por associar'}</span>
            </button>
          </li>
        )}
        {aoNovo && (
          <li>
            <button type="button" onClick={aoNovo}
              className="alvo flex h-full w-44 flex-col items-center justify-center gap-1 rounded-xl border border-dashed p-4 text-sm font-medium text-muted-foreground transition hover:border-primary hover:text-primary">
              <Plus className="size-5" />Novo mandato
            </button>
          </li>
        )}
      </ol>
    </nav>
  )
}

/* ------------------------------------------------------------------ mandato escolhido: cabeçalho + hierarquia */

function PainelMandato({ mandato, oficiais, aoEditar }: { mandato: Mandato; oficiais: Oficial[]; aoEditar: () => void }) {
  const { pode } = useSessao()
  const { anularMandato } = useConselhoMut()
  const [verSaidos, setVerSaidos] = useState(false)
  const [novo, setNovo] = useState<Orgao | null>(null)
  const v = vigencia(mandato)
  const hoje = hojeIso()
  // quem saiu antes do fim do mandato (num mandato já terminado, todos aparecem)
  const saiu = (o: Oficial) => v !== 'TERMINADO' && o.estadoMandato === 'TERMINADO'
  const visiveis = oficiais.filter((o) => verSaidos || !saiu(o))
  const saidos = oficiais.filter(saiu).length

  const total = Date.parse(mandato.dataFim) - Date.parse(mandato.dataInicio)
  const passado = Math.min(Math.max(Date.parse(hoje) - Date.parse(mandato.dataInicio), 0), total)
  const pct = total > 0 ? Math.round((passado / total) * 100) : 0
  const diasFalta = Math.ceil((Date.parse(mandato.dataFim) - Date.parse(hoje)) / 86_400_000)
  const progresso = v === 'FUTURO' ? `Começa a ${data(mandato.dataInicio)}`
    : v === 'TERMINADO' ? `Terminou a ${data(mandato.dataFim)}`
    : diasFalta > 60 ? `Faltam ${Math.round(diasFalta / 30.44)} meses` : `Faltam ${diasFalta} dias`

  return (
    <div className="grid">
      {/* raiz da hierarquia: o mandato */}
      <section className="rounded-xl border bg-card shadow-card">
        <div className="flex flex-col gap-4 p-5 sm:flex-row sm:items-start sm:justify-between sm:p-6">
          <div className="flex min-w-0 items-start gap-3">
            <IconeTom icone={CalendarRange} tamanho="lg" />
            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <h2 className="text-xl font-semibold tracking-tight">{mandato.nome}</h2>
                <Pilula variante={VARIANTE_MANDATO[v]}>{v === 'ACTIVO' ? 'Mandato actual' : ROTULO_MANDATO[v]}</Pilula>
              </div>
              <p className="mt-1 text-sm text-muted-foreground tabular-nums">
                {data(mandato.dataInicio)} → {data(mandato.dataFim)} · <span className="font-medium text-foreground">{duracaoTexto(mandato.dataInicio, mandato.dataFim)}</span>
                {mandato.votoId ? ' · eleito por voto da igreja' : ''}
              </p>
              {mandato.observacoes && <p className="mt-1 text-sm text-muted-foreground">{mandato.observacoes}</p>}
            </div>
          </div>
          <div className="flex flex-none flex-wrap items-center gap-2">
            {pode('secretaria.oficial.criar') && v !== 'TERMINADO' && (
              <Button className="alvo" onClick={() => setNovo('CONSELHO')}><UserPlus className="size-4" />Acrescentar oficial</Button>
            )}
            {(pode('secretaria.mandato.alterar') || pode('secretaria.mandato.terminar')) && (
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" size="icon" className="alvo" aria-label="Mais acções do mandato"><MoreHorizontal className="size-4" /></Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  {pode('secretaria.mandato.alterar') && <DropdownMenuItem onSelect={aoEditar}><Pencil className="size-4" />Editar nome e datas</DropdownMenuItem>}
                  {pode('secretaria.mandato.terminar') && !oficiais.length && (
                    <DropdownMenuItem className="text-destructive-text" onSelect={() => {
                      anularMandato.mutate(mandato.id, { onSuccess: () => toast.success(`${mandato.nome} anulado.`) })
                    }}><Trash2 className="size-4" />Anular (criado por engano)</DropdownMenuItem>
                  )}
                </DropdownMenuContent>
              </DropdownMenu>
            )}
          </div>
        </div>
        <div className="border-t px-5 py-3 sm:px-6">
          <div className="flex items-center justify-between gap-3 text-xs text-muted-foreground">
            <span>{progresso}</span>
            <span className="tabular-nums">{pct}%</span>
          </div>
          <div className="mt-1.5 h-2 overflow-hidden rounded-full bg-muted" role="progressbar" aria-valuenow={pct} aria-valuemin={0} aria-valuemax={100} aria-label="Tempo do mandato decorrido">
            <div className={cn('h-full rounded-full', v === 'A_TERMINAR' ? 'bg-warning' : v === 'TERMINADO' ? 'bg-muted-foreground/40' : 'bg-primary')} style={{ width: `${pct}%` }} />
          </div>
        </div>
      </section>

      <SeparadoresOficiais mandato={mandato} oficiais={visiveis} terminado={v === 'TERMINADO'} aoAcrescentar={setNovo}
        rodape={saidos > 0 && (
          <button type="button" onClick={() => setVerSaidos((x) => !x)} className="alvo text-sm font-medium text-muted-foreground hover:text-foreground">
            {verSaidos ? 'Esconder' : 'Mostrar'} {saidos} {saidos === 1 ? 'oficial que saiu' : 'oficiais que saíram'} antes do fim do mandato
          </button>
        )} />

      {novo && <DialogoOficial mandato={mandato} orgaoInicial={novo} aoFechar={() => setNovo(null)} />}
    </div>
  )
}

type Separador = Orgao | 'TODOS'

/**
 * Os oficiais do mandato em separadores: Conselho da igreja, Direcção e Todos os oficiais; cada um é uma tabela
 * (nome, cargo, início, término, estado e acções).
 */
function SeparadoresOficiais({ mandato, oficiais, terminado, aoAcrescentar, rodape }: {
  mandato: Mandato; oficiais: Oficial[]; terminado: boolean; aoAcrescentar: (o: Orgao) => void; rodape?: ReactNode
}) {
  const { pode } = useSessao()
  const [aba, setAba] = useState<Separador>('CONSELHO')
  const conta = (s: Separador) => (s === 'TODOS' ? oficiais : oficiais.filter((o) => o.orgao === s)).length
  const podeAcrescentar = !terminado && pode('secretaria.oficial.criar')
  return (
    <section className="mt-6 rounded-xl border bg-card shadow-card">
      <Tabs value={aba} onValueChange={(x) => setAba(x as Separador)}>
        <div className="flex flex-wrap items-center justify-between gap-3 border-b px-4 py-3 sm:px-6">
          <TabsList className="max-w-full overflow-x-auto">
            {ORGAOS.map((g) => (
              <TabsTrigger key={g.orgao} value={g.orgao} className="alvo gap-1.5">
                <g.icone className="size-4" />{ROTULO_ORGAO[g.orgao]} <span className="tabular-nums text-muted-foreground">({conta(g.orgao)})</span>
              </TabsTrigger>
            ))}
            <TabsTrigger value="TODOS" className="alvo gap-1.5">
              <ShieldCheck className="size-4" />Todos os oficiais <span className="tabular-nums text-muted-foreground">({conta('TODOS')})</span>
            </TabsTrigger>
          </TabsList>
          {podeAcrescentar && aba !== 'TODOS' && (
            <Button variant="outline" size="sm" className="alvo" onClick={() => aoAcrescentar(aba)}>
              <Plus className="size-4" />Acrescentar {aba === 'CONSELHO' ? 'ao conselho' : 'à direcção'}
            </Button>
          )}
        </div>
        {ORGAOS.map((g) => (
          <TabsContent key={g.orgao} value={g.orgao} className="mt-0">
            <p className="px-4 pt-3 text-sm text-muted-foreground sm:px-6">{g.descricao}</p>
            <TabelaOficiais oficiais={oficiais.filter((o) => o.orgao === g.orgao)} mandato={mandato}
              vazio={`Ainda ninguém ${g.orgao === 'CONSELHO' ? 'no conselho' : 'na direcção'} deste mandato.`} />
          </TabsContent>
        ))}
        <TabsContent value="TODOS" className="mt-0">
          <TabelaOficiais oficiais={oficiais} mandato={mandato} comOrgao vazio="Ainda não há oficiais neste mandato." />
        </TabsContent>
      </Tabs>
      {rodape && <div className="border-t px-4 py-3 text-center sm:px-6">{rodape}</div>}
    </section>
  )
}

/** Tabela de oficiais: ordenada por cargo e nome; no telemóvel as datas passam para debaixo do nome. */
function TabelaOficiais({ oficiais, mandato, mandatos, comOrgao, vazio }: {
  oficiais: Oficial[]; mandato: Mandato | null; mandatos?: Mandato[]; comOrgao?: boolean; vazio: string
}) {
  const ordenados = useMemo(
    () => [...oficiais].sort((a, b) => Number(b.doConselho) - Number(a.doConselho) || a.cargo.localeCompare(b.cargo, 'pt') || a.membro.localeCompare(b.membro, 'pt')),
    [oficiais],
  )
  if (!ordenados.length) return <p className="mx-4 my-5 rounded-lg border border-dashed px-4 py-6 text-center text-sm text-muted-foreground sm:mx-6">{vazio}</p>
  return (
    <Tabela className="mt-3">
      <thead>
        <tr>
          <th className="sm:pl-6">Membro</th>
          <th>Cargo</th>
          {comOrgao && <th className="hidden md:table-cell">Órgão</th>}
          <th className="hidden sm:table-cell">Início</th>
          <th className="hidden sm:table-cell">Término</th>
          <th>Estado</th>
          <th className="w-12 sm:pr-6"><span className="sr-only">Acções</span></th>
        </tr>
      </thead>
      <tbody>
        {ordenados.map((o) => <LinhaOficial key={o.id} o={o} mandato={mandato} mandatos={mandatos} comOrgao={comOrgao} />)}
      </tbody>
    </Tabela>
  )
}

function LinhaOficial({ o, mandato, mandatos, comOrgao }: { o: Oficial; mandato: Mandato | null; mandatos?: Mandato[]; comOrgao?: boolean }) {
  const { pode } = useSessao()
  const { corrigir } = useConselhoMut()
  const [dialogo, setDialogo] = useState<'datas' | 'terminar' | 'associar' | null>(null)
  const fim = o.dataFim ?? o.fimPrevisto
  const outro: Orgao = o.orgao === 'CONSELHO' ? 'DIRECCAO' : 'CONSELHO'
  const podeAlterar = pode('secretaria.oficial.alterar') && o.estadoMandato !== 'TERMINADO'
  const mover = () => corrigir.mutate({ id: o.id, orgao: outro }, { onSuccess: () => toast.success(`${o.membro} passou para ${outro === 'CONSELHO' ? 'o conselho' : 'a direcção'}.`) })
  const saiu = o.estadoMandato === 'TERMINADO' && mandato != null && vigencia(mandato) !== 'TERMINADO'
  return (
    <tr className={cn(saiu && 'text-muted-foreground')}>
      <td className="sm:pl-6">
        <div className="flex items-center gap-3">
          <Avatar id={o.membroId} nome={o.membro.split(' ')[0]} apelido={o.membro.split(' ').slice(-1)[0]} tamanho={32} />
          <div className="min-w-0">
            <Link to={`/membros/${o.membroId}`} className="block truncate font-medium hover:text-primary" title="Abrir a ficha do membro">{o.membro}</Link>
            {o.contacto && <a href={`tel:${o.contacto.replace(/\s/g, '')}`} className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-primary"><Phone className="size-3" /><span className="num">{o.contacto}</span></a>}
            <span className="block text-xs text-muted-foreground tabular-nums sm:hidden">{data(o.dataInicio)} → {data(fim)}</span>
          </div>
        </div>
      </td>
      <td>{o.cargo}</td>
      {comOrgao && <td className="hidden md:table-cell">{ROTULO_ORGAO[o.orgao]}</td>}
      <td className="hidden tabular-nums sm:table-cell">{data(o.dataInicio)}</td>
      <td className="hidden tabular-nums sm:table-cell">{data(fim)}{o.dataFim && o.fimPrevisto && o.dataFim < o.fimPrevisto ? <span className="block text-xs text-muted-foreground">antes do fim</span> : null}</td>
      <td><Pilula variante={VARIANTE_MANDATO[o.estadoMandato]}>{saiu ? 'Saiu' : ROTULO_MANDATO[o.estadoMandato]}</Pilula></td>
      <td className="sm:pr-6">
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="alvo size-9 text-muted-foreground" aria-label={`Acções de ${o.membro}`}><MoreHorizontal className="size-4" /></Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem asChild><Link to={`/membros/${o.membroId}`}><Eye className="size-4" />Ver a ficha do membro</Link></DropdownMenuItem>
            {podeAlterar && (
              <>
                {mandatos && <DropdownMenuItem onSelect={() => setDialogo('associar')}><Link2 className="size-4" />Associar a um mandato</DropdownMenuItem>}
                <DropdownMenuItem onSelect={mover}><ArrowRightLeft className="size-4" />Passar para {outro === 'CONSELHO' ? 'o conselho' : 'a direcção'}</DropdownMenuItem>
                <DropdownMenuItem onSelect={() => setDialogo('datas')}><Pencil className="size-4" />Corrigir datas</DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem className="text-destructive-text" onSelect={() => setDialogo('terminar')}><UserMinus className="size-4" />Terminar antes do fim</DropdownMenuItem>
              </>
            )}
          </DropdownMenuContent>
        </DropdownMenu>
        {dialogo === 'datas' && <DialogoCorrigir o={o} aoFechar={() => setDialogo(null)} />}
        {dialogo === 'terminar' && <DialogoTerminar o={o} aoFechar={() => setDialogo(null)} />}
        {dialogo === 'associar' && mandatos && <DialogoAssociar o={o} mandatos={mandatos} aoFechar={() => setDialogo(null)} />}
      </td>
    </tr>
  )
}

/** Oficiais registados sem mandato (antes da V31, ou fora de uma eleição): associar cada um ao seu mandato. */
function PainelSemMandato({ oficiais, mandatos }: { oficiais: Oficial[]; mandatos: Mandato[] }) {
  return (
    <div className="grid gap-4">
      <p className="rounded-xl border border-warning/40 bg-tint-warning px-4 py-3 text-sm text-warning-text">
        Estes oficiais não pertencem a nenhum mandato. Use <strong>Associar a um mandato</strong> em cada um: passam a seguir as datas desse mandato.
      </p>
      <section className="rounded-xl border bg-card shadow-card">
        <TabelaOficiais oficiais={oficiais} mandato={null} mandatos={mandatos} comOrgao vazio="Nenhum." />
      </section>
    </div>
  )
}

/* ------------------------------------------------------------------ diálogos */

function DialogoOficial({ mandato, orgaoInicial, aoFechar }: { mandato: Mandato; orgaoInicial: Orgao; aoFechar: () => void }) {
  const cargos = useCargos()
  const basicos = useMembrosBasicos()
  const { registar } = useConselhoMut()
  const [membro, setMembro] = useState<number | null>(null)
  const [cargo, setCargo] = useState('')
  const [orgao, setOrgao] = useState<Orgao>(orgaoInicial)
  const [orgaoTocado, setOrgaoTocado] = useState(false)
  const [inicio, setInicio] = useState(mandato.dataInicio)
  const [erro, setErro] = useState<string | null>(null)
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }
  const lista = (cargos.data ?? []).filter((c) => !c.endDate).sort((a, b) => Number(!!b.conselho) - Number(!!a.conselho) || a.nome.localeCompare(b.nome, 'pt'))
  const mudarCargo = (v: string) => {
    setCargo(v)
    const c = lista.find((x) => String(x.id) === v)
    if (c && !orgaoTocado) setOrgao(c.conselho ? 'CONSELHO' : 'DIRECCAO')
  }
  const submeter = async () => {
    setErro(null)
    if (!membro || !cargo) return setErro('Escolha o membro e o cargo.')
    if (!ISO.test(inicio)) return setErro('Escreva a data de início como dd/mm/aaaa.')
    try {
      await registar.mutateAsync({ membroId: membro, cargoId: Number(cargo), mandatoId: mandato.id, orgao, dataInicio: inicio !== mandato.dataInicio ? inicio : undefined })
      toast.success(`${nomeDe(membro) ?? 'Oficial'} acrescentado ${orgao === 'CONSELHO' ? 'ao conselho' : 'à direcção'}.`)
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Acrescentar oficial</DialogTitle>
          <DialogDescription>{mandato.nome} · {data(mandato.dataInicio)} → {data(mandato.dataFim)}</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5"><label htmlFor="ofi-mem" className="text-sm font-medium">Membro <span className="text-destructive-text">*</span></label>
            <CampoMembro id="ofi-mem" valor={membro} aoMudar={setMembro} nomeDe={nomeDe} /></div>
          <div className="grid gap-1.5"><label htmlFor="ofi-car" className="text-sm font-medium">Cargo <span className="text-destructive-text">*</span></label>
            {cargos.isPending ? <Barra className="h-9 w-full" /> : <CampoEscolha id="ofi-car" valor={cargo} aoMudar={mudarCargo} vazio="Escolher o cargo…" pesquisar="Pesquisar cargo…"
              opcoes={lista.map((c) => ({ valor: String(c.id), rotulo: c.nome, detalhe: c.conselho ? 'normalmente no conselho' : 'normalmente na direcção' }))} />}</div>
          <fieldset className="grid gap-1.5">
            <legend className="mb-1.5 text-sm font-medium">Serve no</legend>
            <div role="radiogroup" aria-label="Órgão" className="grid grid-cols-2 gap-2">
              {ORGAOS.map((g) => (
                <button key={g.orgao} type="button" role="radio" aria-checked={orgao === g.orgao} onClick={() => { setOrgao(g.orgao); setOrgaoTocado(true) }}
                  className={cn('alvo flex items-center gap-2 rounded-lg border px-3 py-2.5 text-left text-sm font-medium transition',
                    orgao === g.orgao ? 'border-primary bg-primary/10 text-primary' : 'text-muted-foreground hover:border-primary/40')}>
                  <g.icone className="size-4 flex-none" />{ROTULO_ORGAO[g.orgao]}
                </button>
              ))}
            </div>
          </fieldset>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-1.5"><label htmlFor="ofi-ini" className="text-sm font-medium">Começa em</label>
              <CampoData id="ofi-ini" value={inicio} onChange={setInicio} className="alvo" /></div>
            <div className="grid gap-1.5"><span className="text-sm font-medium">Até</span>
              <p className="flex h-9 items-center rounded-md border border-dashed px-3 text-sm text-muted-foreground tabular-nums">{data(mandato.dataFim)}</p></div>
          </div>
          {inicio !== mandato.dataInicio && <p className="-mt-2 text-xs text-muted-foreground">Começa depois do mandato (por exemplo, para substituir alguém que saiu).</p>}
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={registar.isPending} onClick={submeter}>{registar.isPending ? t.comum.aGravar : 'Acrescentar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function DialogoAssociar({ o, mandatos, aoFechar }: { o: Oficial; mandatos: Mandato[]; aoFechar: () => void }) {
  const { corrigir } = useConselhoMut()
  const [escolha, setEscolha] = useState(String(mandatos.find((m) => m.dataInicio <= o.dataInicio && m.dataFim >= o.dataInicio)?.id ?? ''))
  const [erro, setErro] = useState<string | null>(null)
  const submeter = async () => {
    setErro(null)
    if (!escolha) return setErro('Escolha o mandato.')
    try {
      await corrigir.mutateAsync({ id: o.id, mandatoId: Number(escolha) })
      toast.success(`${o.membro} associado ao mandato.`)
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader><DialogTitle>Associar a um mandato</DialogTitle><DialogDescription>{o.membro} · {o.cargo}</DialogDescription></DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          {mandatos.length ? (
            <Seleccao aria-label="Mandato" value={escolha} onChange={(e) => setEscolha(e.target.value)}>
              <option value="">Escolher…</option>
              {mandatos.map((m) => <option key={m.id} value={m.id}>{m.nome} ({data(m.dataInicio)} → {data(m.dataFim)})</option>)}
            </Seleccao>
          ) : <p className="text-sm text-muted-foreground">Crie primeiro o mandato.</p>}
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={corrigir.isPending || !mandatos.length} onClick={submeter}>{corrigir.isPending ? t.comum.aGravar : 'Associar'}</Button>
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
      toast.success('Datas actualizadas.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader><DialogTitle>Datas de {o.membro}</DialogTitle><DialogDescription>{o.cargo}{o.mandato ? ` · ${o.mandato}` : ''}</DialogDescription></DialogHeader>
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
      toast.success(`${o.membro} deixou o cargo de ${o.cargo}.`)
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader><DialogTitle>Terminar antes do fim do mandato</DialogTitle><DialogDescription>{o.membro} · {o.cargo}. Fica no histórico.</DialogDescription></DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5"><label htmlFor="ter-fim" className="text-sm font-medium">Saiu em</label><CampoData id="ter-fim" value={fim} onChange={setFim} className="alvo" /></div>
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo bg-destructive text-white hover:bg-destructive/90" disabled={terminarMandato.isPending} onClick={submeter}>{terminarMandato.isPending ? t.comum.aGravar : 'Terminar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
