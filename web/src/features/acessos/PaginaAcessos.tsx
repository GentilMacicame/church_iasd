/**
 * Utilizadores e perfis (F-NUC-03, P-13) · "Quem entra no sistema e o que pode fazer?"
 * Três separadores, como na gestão de contas do SGMS: Utilizadores (lista, estado, perfis nesta igreja),
 * Perfis (lista e detalhes) e Permissões (matriz por módulo: ver, criar, alterar, terminar + acções próprias).
 * As regras e a segurança são da base de dados; aqui só se mostra e se pede.
 */
import { Fragment, useMemo, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import {
  Check, ChevronDown, CornerDownRight, KeyRound, ListTree, Lock, Pencil, Plus, Search, Send, ShieldCheck, UserCheck, UserPlus, Users,
} from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { Seleccao } from '@/components/comum/Seleccao'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import {
  ACCOES, MODULOS, ROTULO_ACCAO, nomeDoRecurso, useEnviarCodigo, usePerfis, usePerfisDaIgreja, usePerfisMut, usePerfisPermissoes,
  usePermissoes, useUsuarios, type Perfil, type Permissao, type Usuario,
} from './api'

type Aba = 'utilizadores' | 'perfis' | 'permissoes'
const ABAS: { k: Aba; rotulo: string }[] = [
  { k: 'utilizadores', rotulo: 'Utilizadores' }, { k: 'perfis', rotulo: 'Perfis' }, { k: 'permissoes', rotulo: 'Permissões' },
]

export const nomePerfil = (p?: { nome: string } | null) => (p ? rotulos.perfil[p.nome] ?? p.nome : '—')
const pct = (parte: number, total: number) => (total ? `${String(Math.round((parte / total) * 1000) / 10).replace('.', ',')}% do total` : '0% do total')

export type EstadoUtilizador = 'activo' | 'por_entrar' | 'inactivo'
export function estadoDe(u: Usuario): EstadoUtilizador {
  if (u.endDate || u.estado === 'INACTIVO') return 'inactivo'
  return u.ultimoLogin ? 'activo' : 'por_entrar'
}
export function PilulaUtilizador({ u }: { u: Usuario }) {
  const e = estadoDe(u)
  if (e === 'inactivo') return <Pilula variante="secondary">Desactivado</Pilula>
  if (e === 'por_entrar') return <Pilula variante="info">Ainda não entrou</Pilula>
  return <Pilula variante="success">Activo</Pilula>
}

export default function PaginaAcessos() {
  const { pode } = useSessao()
  const [params, setParams] = useSearchParams()
  const aba = (params.get('tab') as Aba) || 'utilizadores'
  const mudar = (k: Aba, extra?: Record<string, string>) => setParams((p) => {
    const n = new URLSearchParams(p); n.set('tab', k)
    for (const [c, v] of Object.entries(extra ?? {})) n.set(c, v)
    return n
  }, { replace: true })

  // sem permissão a base de dados só mostraria a própria conta: diz-se logo que a página não é para si
  if (!pode('nucleo.usuario.ler') && !pode('nucleo.usuario_igreja.ler')) {
    return (
      <>
        <TituloPagina icone={KeyRound} titulo="Utilizadores e perfis" />
        <div className="rounded-xl border bg-card shadow-card">
          <EstadoVazio icone={Lock} titulo="Sem acesso a esta página">A gestão de utilizadores e perfis é do administrador da igreja. Peça-lhe o que precisa.</EstadoVazio>
        </div>
      </>
    )
  }

  return (
    <>
      <TituloPagina icone={KeyRound} titulo="Utilizadores e perfis" descricao="Quem entra no sistema, os perfis de acesso nesta igreja e as permissões de cada perfil" />
      <section className="min-w-0 rounded-xl border bg-card shadow-card">
        <nav role="tablist" aria-label="Secções" className="flex gap-6 overflow-x-auto border-b px-4 sm:px-6">
          {ABAS.map((a) => (
            <button key={a.k} type="button" role="tab" aria-selected={aba === a.k} onClick={() => mudar(a.k)}
              className={cn('alvo -mb-px border-b-2 border-transparent py-4 text-sm font-medium whitespace-nowrap text-muted-foreground hover:text-foreground',
                aba === a.k && 'border-primary text-primary')}>
              {a.rotulo}
            </button>
          ))}
        </nav>
        <div className="p-4 sm:p-6">
          {aba === 'utilizadores' && <AbaUtilizadores />}
          {aba === 'perfis' && <AbaPerfis aoVerPermissoes={(id) => mudar('permissoes', { perfil: String(id) })} />}
          {aba === 'permissoes' && <AbaPermissoes />}
        </div>
      </section>
    </>
  )
}

/* ================================================================== Utilizadores */
type Filtro = 'todos' | EstadoUtilizador

function AbaUtilizadores() {
  const { pode, usuario: eu } = useSessao()
  const navigate = useNavigate()
  const usuarios = useUsuarios()
  const ligacoes = usePerfisDaIgreja()
  const perfis = usePerfis()
  const basicos = useMembrosBasicos()
  const enviar = useEnviarCodigo()
  const [filtro, setFiltro] = useState<Filtro>('todos')
  const [q, setQ] = useState('')
  const perfilPorId = useMemo(() => new Map((perfis.data ?? []).map((p) => [p.id, p])), [perfis.data])
  const nomesMembros = useMemo(() => new Map((basicos.data ?? []).map((m) => [m.id, `${m.nome} ${m.apelido}`])), [basicos.data])
  const perfisDe = (uid: number) => (ligacoes.data ?? []).filter((l) => l.usuarioId === uid && !l.endDate).map((l) => perfilPorId.get(l.perfilId)).filter(Boolean) as Perfil[]

  const lista = usuarios.data ?? []
  const n = (e: EstadoUtilizador) => lista.filter((u) => estadoDe(u) === e).length
  const perfisEmUso = new Set((ligacoes.data ?? []).filter((l) => !l.endDate).map((l) => l.perfilId)).size
  const visiveis = lista.filter((u) => {
    if (filtro !== 'todos' && estadoDe(u) !== filtro) return false
    const texto = `${u.nome} ${u.email ?? ''} ${u.telefone ?? ''} ${perfisDe(u.id).map(nomePerfil).join(' ')}`.toLowerCase()
    return !q || texto.includes(q.trim().toLowerCase())
  }).sort((a, b) => Number(!!a.endDate) - Number(!!b.endDate) || a.nome.localeCompare(b.nome))

  const mandarCodigo = (u: Usuario) => enviar.mutate(u.email || u.telefone || '', {
    onSuccess: () => toast.success(`Código enviado por SMS para ${u.telefone ?? 'o telemóvel'} de ${u.nome}.`),
    onError: (e) => toast.error(mensagemDe(e)),
  })

  return (
    <div className="grid gap-6">
      <div className="grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-4">
        <Indicador rotulo="Utilizadores activos" valor={n('activo')} nota={pct(n('activo'), lista.length)} icone={UserCheck} tom="success" aCarregar={usuarios.isPending}
          aoClicar={() => setFiltro('activo')} activo={filtro === 'activo'} />
        <Indicador rotulo="Ainda não entraram" valor={n('por_entrar')} nota="sem senha definida" icone={UserPlus} tom="info" aCarregar={usuarios.isPending}
          aoClicar={() => setFiltro('por_entrar')} activo={filtro === 'por_entrar'} />
        <Indicador rotulo="Perfis em uso" valor={perfisEmUso} nota="nesta igreja" icone={ShieldCheck} aCarregar={ligacoes.isPending} />
        <Indicador rotulo="Total de utilizadores" valor={lista.length} nota={`${n('inactivo')} desactivado(s)`} icone={Users} aCarregar={usuarios.isPending}
          aoClicar={() => setFiltro('todos')} activo={filtro === 'todos'} />
      </div>

      <div className="min-w-0 rounded-lg border">
        <div className="flex flex-col gap-3 border-b p-4 sm:p-5 lg:flex-row lg:items-end lg:justify-between">
          <div className="grid gap-3">
            <div>
              <h2 className="font-semibold">Utilizadores do sistema</h2>
              <p className="text-sm text-muted-foreground">Registe utilizadores, dê-lhes perfis nesta igreja e acompanhe quem já entrou.</p>
            </div>
            <div role="group" aria-label="Filtrar por estado" className="flex flex-wrap gap-1">
              {([['todos', 'Todos'], ['activo', 'Activos'], ['por_entrar', 'Ainda não entraram'], ['inactivo', 'Desactivados']] as [Filtro, string][]).map(([k, r]) => (
                <button key={k} type="button" aria-pressed={filtro === k} onClick={() => setFiltro(k)}
                  className={cn('alvo h-8 rounded-md px-3 text-sm font-medium text-muted-foreground hover:text-foreground', filtro === k && 'bg-primary text-primary-foreground hover:text-primary-foreground')}>
                  {r}
                </button>
              ))}
            </div>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row">
            <label className="relative block sm:w-64">
              <span className="sr-only">Pesquisar utilizador</span>
              <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input type="search" value={q} onChange={(e) => setQ(e.target.value)} placeholder="Pesquisar utilizador…" className="alvo pl-9" />
            </label>
            {pode('nucleo.usuario.criar') && <Button asChild className="alvo"><Link to="/acessos/utilizadores/novo"><Plus className="size-4" />Novo utilizador</Link></Button>}
          </div>
        </div>
        {usuarios.isPending || ligacoes.isPending ? <LinhasACarregar linhas={4} />
          : usuarios.isError ? <EstadoErro erro={usuarios.error} aoTentar={() => usuarios.refetch()} className="m-4" />
          : !visiveis.length ? <EstadoVazio icone={Users}>{lista.length ? 'Nenhum utilizador corresponde ao filtro.' : 'Ainda não há utilizadores.'}</EstadoVazio>
          : (
            <Tabela>
              <thead><tr><th className="sm:pl-5">Nome</th><th className="hidden md:table-cell">Contacto</th><th>Perfis nesta igreja</th><th className="hidden lg:table-cell">Membro</th><th>Estado</th><th className="sm:pr-5"><span className="sr-only">Acções</span></th></tr></thead>
              <tbody>
                {visiveis.map((u) => {
                  const ps = perfisDe(u.id)
                  return (
                    <tr key={u.id} className={cn('cursor-pointer', u.endDate && 'opacity-60')} onClick={() => navigate(`/acessos/utilizadores/${u.id}`)}>
                      <td className="sm:pl-5">
                        <Link to={`/acessos/utilizadores/${u.id}`} onClick={(e) => e.stopPropagation()} className="font-medium hover:text-primary">{u.nome}</Link>
                        {u.superAdmin && <Pilula variante="destructive" className="ml-2">Super-administrador</Pilula>}
                        {u.id === eu?.id && <span className="ml-2 text-xs text-muted-foreground">(você)</span>}
                        <p className="text-xs text-muted-foreground md:hidden">{u.email ?? u.telefone}</p>
                      </td>
                      <td className="hidden md:table-cell"><p>{u.email ?? '—'}</p><p className="num text-xs text-muted-foreground">{u.telefone}</p></td>
                      <td>
                        <div className="flex flex-wrap gap-1">
                          {ps.length ? ps.map((p, i) => <Pilula key={p.id} variante={i === 0 ? 'info' : 'secondary'} className={cn(p.endDate && 'line-through')}>{nomePerfil(p)}</Pilula>)
                            : <span className="text-sm text-muted-foreground">{u.superAdmin ? 'Acesso total' : 'Sem perfil'}</span>}
                        </div>
                      </td>
                      <td className="hidden text-muted-foreground lg:table-cell">{u.membroId ? nomesMembros.get(u.membroId) ?? `Membro ${u.membroId}` : '—'}</td>
                      <td><PilulaUtilizador u={u} /></td>
                      <td className="sm:pr-5" onClick={(e) => e.stopPropagation()}>
                        <div className="flex justify-end gap-1.5">
                          {estadoDe(u) === 'por_entrar' && u.telefone && (
                            <Button variant="outline" size="icon" className="alvo size-9" title="Enviar código de acesso por SMS" aria-label={`Enviar código de acesso a ${u.nome}`}
                              disabled={enviar.isPending} onClick={() => mandarCodigo(u)}><Send className="size-4" /></Button>
                          )}
                          <Button asChild variant="outline" size="icon" className="alvo size-9" title="Ver e editar"><Link to={`/acessos/utilizadores/${u.id}`} aria-label={`Editar ${u.nome}`}><Pencil className="size-4" /></Link></Button>
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </Tabela>
          )}
      </div>
    </div>
  )
}

/* ================================================================== Perfis */
function AbaPerfis({ aoVerPermissoes }: { aoVerPermissoes: (id: number) => void }) {
  const { pode } = useSessao()
  const [params, setParams] = useSearchParams()
  const perfis = usePerfis()
  const ligacoes = usePerfisDaIgreja()
  const matriz = usePerfisPermissoes()
  const permissoes = usePermissoes()
  const { estado } = usePerfisMut()
  const [q, setQ] = useState('')
  const [novo, setNovo] = useState(false)
  const [editar, setEditar] = useState<Perfil | null>(null)
  const [alternar, setAlternar] = useState<Perfil | null>(null)
  const [detalhe, setDetalhe] = useState<'geral' | 'permissoes'>('geral')

  const lista = perfis.data ?? []
  const utilizadoresDe = (pid: number) => (ligacoes.data ?? []).filter((l) => l.perfilId === pid && !l.endDate).length
  const permissoesDe = (pid: number) => (matriz.data ?? []).filter((l) => l.perfilId === pid && !l.endDate)
  const seleccionado = lista.find((p) => String(p.id) === params.get('perfil')) ?? lista[0]
  const activos = lista.filter((p) => !p.endDate)
  const visiveis = lista.filter((p) => !q || `${p.nome} ${nomePerfil(p)} ${p.descricao ?? ''}`.toLowerCase().includes(q.trim().toLowerCase()))
  const prmPorId = useMemo(() => new Map((permissoes.data ?? []).map((p) => [p.id, p])), [permissoes.data])
  const gerir = pode('nucleo.perfil.alterar')

  return (
    <div className="grid gap-6">
      <div className="grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-4">
        <Indicador rotulo="Total de perfis" valor={lista.length} nota={`${lista.filter((p) => p.ambito === 'IGREJA').length} da igreja · ${lista.filter((p) => p.ambito === 'ENTIDADE').length} da Missão`} icone={Users} aCarregar={perfis.isPending} />
        <Indicador rotulo="Perfis activos" valor={activos.length} nota={pct(activos.length, lista.length)} icone={ShieldCheck} tom="success" aCarregar={perfis.isPending} />
        <Indicador rotulo="Perfis inactivos" valor={lista.length - activos.length} nota={pct(lista.length - activos.length, lista.length)} icone={Lock} aCarregar={perfis.isPending} />
        <Indicador rotulo="Utilizadores associados" valor={(ligacoes.data ?? []).filter((l) => !l.endDate).length} nota="soma por perfil, nesta igreja" icone={KeyRound} aCarregar={ligacoes.isPending} />
      </div>

      <div className="grid items-start gap-6 xl:grid-cols-[minmax(0,1fr)_320px]">
        <div className="grid min-w-0 gap-4">
          <div className="flex flex-col gap-3 rounded-lg border p-4 sm:flex-row">
            <label className="relative block flex-1">
              <span className="sr-only">Pesquisar perfil</span>
              <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input type="search" value={q} onChange={(e) => setQ(e.target.value)} placeholder="Pesquisar perfil…" className="alvo bg-muted/50 pl-9" />
            </label>
            {pode('nucleo.perfil.criar') && <Button className="alvo" onClick={() => setNovo(true)}><Plus className="size-4" />Novo perfil</Button>}
          </div>
          <div className="min-w-0 rounded-lg border">
            {perfis.isPending ? <LinhasACarregar linhas={6} />
              : perfis.isError ? <EstadoErro erro={perfis.error} aoTentar={() => perfis.refetch()} className="m-4" />
              : (
                <Tabela>
                  <thead><tr><th className="sm:pl-5">Perfil</th><th className="hidden md:table-cell">Descrição</th><th className="num">Utilizadores</th><th>Estado</th><th className="sm:pr-5"><span className="sr-only">Acções</span></th></tr></thead>
                  <tbody>
                    {visiveis.map((p) => (
                      <tr key={p.id} className={cn('cursor-pointer', p.id === seleccionado?.id && 'bg-primary/5', p.endDate && 'opacity-60')}
                        onClick={() => setParams((x) => { const n = new URLSearchParams(x); n.set('perfil', String(p.id)); return n }, { replace: true })}>
                        <td className="sm:pl-5">
                          <span className="flex items-center gap-3">
                            <span className="flex size-8 flex-none items-center justify-center rounded-full bg-muted text-sm font-semibold text-muted-foreground">{nomePerfil(p).charAt(0)}</span>
                            <span><span className="font-medium">{nomePerfil(p)}</span><span className="block text-xs text-muted-foreground">{p.ambito === 'ENTIDADE' ? 'Associação/Missão' : 'Igreja'}</span></span>
                          </span>
                        </td>
                        <td className="hidden max-w-md text-muted-foreground md:table-cell">{p.descricao ?? '—'}</td>
                        <td className="num">{p.ambito === 'IGREJA' ? utilizadoresDe(p.id) : '—'}</td>
                        <td>{p.endDate ? <Pilula variante="secondary">Inactivo</Pilula> : <Pilula variante="success">Activo</Pilula>}</td>
                        <td className="sm:pr-5" onClick={(e) => e.stopPropagation()}>
                          <div className="flex justify-end gap-1">
                            {gerir && <Button variant="ghost" size="icon" className="alvo size-9" title="Editar perfil" aria-label={`Editar ${nomePerfil(p)}`} onClick={() => setEditar(p)}><Pencil className="size-4" /></Button>}
                            <Button variant="ghost" size="icon" className="alvo size-9" title="Permissões" aria-label={`Permissões de ${nomePerfil(p)}`} onClick={() => aoVerPermissoes(p.id)}><KeyRound className="size-4" /></Button>
                          </div>
                        </td>
                      </tr>
                    ))}
                    {!visiveis.length && <tr><td colSpan={5} className="py-10 text-center text-muted-foreground">Nenhum perfil encontrado.</td></tr>}
                  </tbody>
                </Tabela>
              )}
          </div>
        </div>

        {seleccionado && (
          <aside className="h-fit rounded-lg border p-5 xl:sticky xl:top-[calc(var(--header-height)+1.5rem)]">
            <p className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Detalhes do perfil</p>
            <div className="mt-4 flex items-center gap-4 border-b pb-4">
              <span className="flex size-12 flex-none items-center justify-center rounded-lg bg-muted text-lg font-semibold text-muted-foreground">{nomePerfil(seleccionado).charAt(0)}</span>
              <div className="min-w-0"><p className="truncate font-semibold">{nomePerfil(seleccionado)}</p><code className="text-xs text-muted-foreground">{seleccionado.nome}</code></div>
            </div>
            <div role="tablist" className="mt-3 flex gap-5 border-b">
              {(['geral', 'permissoes'] as const).map((k) => (
                <button key={k} type="button" role="tab" aria-selected={detalhe === k} onClick={() => setDetalhe(k)}
                  className={cn('alvo -mb-px border-b-2 border-transparent pb-2 text-sm font-medium text-muted-foreground hover:text-foreground', detalhe === k && 'border-primary text-primary')}>
                  {k === 'geral' ? 'Geral' : 'Permissões'}
                </button>
              ))}
            </div>
            {detalhe === 'geral' ? (
              <dl className="mt-4 grid gap-4 text-sm">
                <div><dt className="text-muted-foreground">Descrição</dt><dd>{seleccionado.descricao ?? '—'}</dd></div>
                <div><dt className="text-muted-foreground">Âmbito</dt><dd>{seleccionado.ambito === 'ENTIDADE' ? 'Associação/Missão (todas as igrejas abaixo dela)' : 'Uma igreja'}</dd></div>
                {seleccionado.ambito === 'IGREJA' && <div><dt className="text-muted-foreground">Utilizadores nesta igreja</dt><dd>{utilizadoresDe(seleccionado.id)} atribuído(s)</dd></div>}
                <div><dt className="text-muted-foreground">Permissões</dt><dd>{permissoesDe(seleccionado.id).length} de {(permissoes.data ?? []).length}</dd></div>
                <div><dt className="text-muted-foreground">Estado</dt><dd>{seleccionado.endDate ? <Pilula variante="secondary">Inactivo</Pilula> : <Pilula variante="success">Activo</Pilula>}</dd></div>
                {pode('nucleo.perfil.terminar') && (
                  <div className="border-t pt-4">
                    <Button variant="outline" className={cn('alvo w-full', !seleccionado.endDate && 'text-destructive-text hover:text-destructive-text')} onClick={() => setAlternar(seleccionado)}>
                      {seleccionado.endDate ? 'Activar perfil' : 'Desactivar perfil'}
                    </Button>
                  </div>
                )}
              </dl>
            ) : (
              <div className="mt-4">
                <ul className="grid max-h-80 gap-1.5 overflow-y-auto text-sm">
                  {permissoesDe(seleccionado.id).map((l) => prmPorId.get(l.permissaoId)).filter(Boolean).sort((a, b) => a!.codigo.localeCompare(b!.codigo)).map((p) => (
                    <li key={p!.id} className="flex items-start gap-2"><Check className="mt-0.5 size-3.5 flex-none text-success-text" /><span>{p!.descricao ?? p!.codigo}</span></li>
                  ))}
                  {!permissoesDe(seleccionado.id).length && <li className="text-muted-foreground">Sem permissões atribuídas.</li>}
                </ul>
                <Button variant="outline" size="sm" className="alvo mt-4" onClick={() => aoVerPermissoes(seleccionado.id)}>{pode('nucleo.perfil_permissao.criar') ? 'Editar permissões' : 'Ver na matriz'}</Button>
              </div>
            )}
          </aside>
        )}
      </div>

      {novo && <DialogoPerfil aoFechar={() => setNovo(false)} />}
      {editar && <DialogoPerfil perfil={editar} aoFechar={() => setEditar(null)} />}
      <DialogoConfirmar aberto={!!alternar} aoMudar={(v) => !v && setAlternar(null)}
        titulo={alternar?.endDate ? `Activar o perfil ${nomePerfil(alternar)}?` : `Desactivar o perfil ${nomePerfil(alternar)}?`}
        texto={alternar?.endDate ? 'O perfil volta a poder ser atribuído e as suas permissões voltam a valer.' : 'As permissões deste perfil deixam de valer para quem o tem. Fica no histórico e pode ser activado de novo.'}
        accao={alternar?.endDate ? 'Activar' : 'Desactivar'} perigo={!alternar?.endDate} aCorrer={estado.isPending}
        aoConfirmar={() => alternar && estado.mutate({ id: alternar.id, activar: !!alternar.endDate }, {
          onSuccess: () => { toast.success(alternar.endDate ? 'Perfil activado.' : 'Perfil desactivado.'); setAlternar(null) },
          onError: (e) => { toast.error(mensagemDe(e)); setAlternar(null) },
        })} />
    </div>
  )
}

function DialogoPerfil({ perfil, aoFechar }: { perfil?: Perfil; aoFechar: () => void }) {
  const { criar, alterar } = usePerfisMut()
  const [nome, setNome] = useState(perfil?.nome ?? '')
  const [descricao, setDescricao] = useState(perfil?.descricao ?? '')
  const [ambito, setAmbito] = useState<string>(perfil?.ambito ?? 'IGREJA')
  const [erro, setErro] = useState<string | null>(null)
  const ocupado = criar.isPending || alterar.isPending
  const submeter = async () => {
    setErro(null)
    const codigo = nome.trim().toUpperCase().replace(/\s+/g, '_')
    if (!perfil && !/^[A-Z][A-Z0-9_]{1,39}$/.test(codigo)) return setErro('O nome técnico usa só letras, números e _ (ex.: TESOUREIRO_ADJUNTO).')
    try {
      if (perfil) await alterar.mutateAsync({ id: perfil.id, descricao: descricao.trim() })
      else await criar.mutateAsync({ nome: codigo, descricao: descricao.trim(), ambito })
      toast.success(perfil ? 'Perfil actualizado.' : 'Perfil criado. Dê-lhe as permissões no separador Permissões.')
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{perfil ? `Editar perfil ${nomePerfil(perfil)}` : 'Novo perfil'}</DialogTitle>
          <DialogDescription>{perfil ? 'O nome técnico não muda (as regras da base de dados usam-no).' : 'Um conjunto de permissões que se dá a utilizadores.'}</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          {!perfil && (
            <>
              <div className="grid gap-1.5">
                <label htmlFor="per-nome" className="text-sm font-medium">Nome técnico <span className="text-destructive-text">*</span></label>
                <Input id="per-nome" value={nome} onChange={(e) => setNome(e.target.value)} placeholder="ex.: TESOUREIRO_ADJUNTO" className="alvo uppercase" maxLength={40} autoFocus />
                <p className="text-xs text-muted-foreground">Sem espaços nem acentos.</p>
              </div>
              <div className="grid gap-1.5">
                <label htmlFor="per-ambito" className="text-sm font-medium">Âmbito</label>
                <Seleccao id="per-ambito" value={ambito} onChange={(e) => setAmbito(e.target.value)}>
                  <option value="IGREJA">Uma igreja</option>
                  <option value="ENTIDADE">Associação/Missão</option>
                </Seleccao>
              </div>
            </>
          )}
          <div className="grid gap-1.5">
            <label htmlFor="per-desc" className="text-sm font-medium">Descrição</label>
            <Input id="per-desc" value={descricao} onChange={(e) => setDescricao(e.target.value)} placeholder="O que este perfil faz" className="alvo" maxLength={255} />
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={ocupado} onClick={submeter}>{ocupado ? t.comum.aGravar : perfil ? t.comum.guardar : 'Criar perfil'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/* ================================================================== Permissões */
interface Recurso { chave: string; nome: string; colunas: Record<string, Permissao | undefined>; extras: Permissao[] }

function AbaPermissoes() {
  const { pode } = useSessao()
  const [params, setParams] = useSearchParams()
  const perfis = usePerfis()
  const permissoes = usePermissoes()
  const matriz = usePerfisPermissoes()
  const { permissoes: aplicar } = usePerfisMut()
  const lista = perfis.data ?? []
  const perfil = lista.find((p) => String(p.id) === params.get('perfil')) ?? lista[0]
  const editavel = pode('nucleo.perfil_permissao.criar') && pode('nucleo.perfil_permissao.terminar')
  const [marcadas, setMarcadas] = useState<Set<number> | null>(null)
  const [abertos, setAbertos] = useState<Set<string>>(new Set())
  const [especificas, setEspecificas] = useState(false)
  const [fechados, setFechados] = useState<Set<string>>(new Set())

  // módulo → recursos (tabelas) com as 4 acções e as acções próprias
  const modulos = useMemo(() => {
    const porRecurso = new Map<string, Recurso>()
    for (const p of permissoes.data ?? []) {
      if (p.endDate) continue
      const partes = p.codigo.split('.')
      const accao = partes.pop()!
      const chave = partes.join('.')
      const r = porRecurso.get(chave) ?? { chave, nome: '', colunas: {}, extras: [] }
      if ((ACCOES as readonly string[]).includes(accao)) {
        r.colunas[accao] = p
        if (accao === 'ler' || !r.nome) r.nome = nomeDoRecurso(p.descricao, partes[1])
      } else r.extras.push(p)
      porRecurso.set(chave, r)
    }
    const out = new Map<string, Recurso[]>()
    for (const r of porRecurso.values()) {
      const m = r.chave.split('.')[0]
      out.set(m, [...(out.get(m) ?? []), r])
    }
    return Object.keys(MODULOS).filter((m) => out.has(m)).map((m) => ({ chave: m, nome: MODULOS[m], recursos: out.get(m)!.sort((a, b) => a.nome.localeCompare(b.nome)) }))
  }, [permissoes.data])

  const ligacoes = (matriz.data ?? []).filter((l) => l.perfilId === perfil?.id && !l.endDate)
  const inicial = useMemo(() => new Set(ligacoes.map((l) => l.permissaoId)), [ligacoes])
  const actual = marcadas ?? inicial
  const alterado = [...actual].some((id) => !inicial.has(id)) || [...inicial].some((id) => !actual.has(id))
  const trocar = (id: number) => setMarcadas((s) => { const n = new Set(s ?? inicial); if (n.has(id)) n.delete(id); else n.add(id); return n })
  const escolherPerfil = (id: string) => { setMarcadas(null); setParams((x) => { const n = new URLSearchParams(x); n.set('perfil', id); return n }, { replace: true }) }
  const contar = (rs: Recurso[]) => rs.flatMap((r) => [...Object.values(r.colunas), ...r.extras]).filter(Boolean)
  const guardar = () => {
    if (!perfil) return
    const dar = [...actual].filter((id) => !inicial.has(id))
    const tirar = ligacoes.filter((l) => !actual.has(l.permissaoId))
    aplicar.mutate({ perfilId: perfil.id, dar, tirar }, {
      onSuccess: () => { toast.success(`Permissões de ${nomePerfil(perfil)} actualizadas: ${dar.length} dada(s), ${tirar.length} retirada(s).`); setMarcadas(null) },
      onError: (e) => { toast.error(mensagemDe(e)); setMarcadas(null) },
    })
  }

  if (perfis.isPending || permissoes.isPending || matriz.isPending) return <LinhasACarregar linhas={8} />
  const falha = perfis.error ?? permissoes.error ?? matriz.error
  if (falha) return <EstadoErro erro={falha} aoTentar={() => { perfis.refetch(); permissoes.refetch(); matriz.refetch() }} />

  return (
    <div className="grid gap-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div className="grid gap-1.5 sm:w-96">
          <label htmlFor="perm-perfil" className="text-sm font-medium">Seleccionar perfil</label>
          <Seleccao id="perm-perfil" value={perfil ? String(perfil.id) : ''} onChange={(e) => escolherPerfil(e.target.value)}>
            {lista.map((p) => <option key={p.id} value={p.id}>{nomePerfil(p)}{p.endDate ? ' (inactivo)' : ''}{p.ambito === 'ENTIDADE' ? ' · Missão' : ''}</option>)}
          </Seleccao>
        </div>
        <Button variant="outline" size="sm" className="alvo" aria-expanded={especificas} onClick={() => setEspecificas((v) => !v)}>
          <ListTree className="size-4" />{especificas ? 'Ocultar acções específicas' : 'Mostrar acções específicas'}
        </Button>
      </div>
      {perfil?.endDate && <p className="rounded-lg border border-warning/30 bg-tint-warning px-4 py-3 text-sm text-warning-text">Este perfil está inactivo: as permissões abaixo não valem até ser activado.</p>}
      {!editavel && <p className="rounded-lg border border-info/30 bg-tint-info px-4 py-3 text-sm text-info-text">Só o super-administrador altera as permissões dos perfis. Aqui pode consultá-las.</p>}

      <div className="min-w-0 overflow-x-auto rounded-lg border">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 text-xs font-semibold tracking-wider text-muted-foreground uppercase">
            <tr>
              <th className="min-w-56 px-4 py-3 text-left">Módulos e recursos</th>
              {ACCOES.map((a) => <th key={a} className="w-20 px-2 py-3 text-center">{ROTULO_ACCAO[a]}</th>)}
            </tr>
          </thead>
          {modulos.map((m) => {
            const todas = contar(m.recursos)
            const dadas = todas.filter((p) => actual.has(p!.id)).length
            const fechado = fechados.has(m.chave)
            return (
              <tbody key={m.chave} className="border-t">
                <tr className="bg-muted/30">
                  <td colSpan={5} className="px-4 py-2">
                    <button type="button" aria-expanded={!fechado} onClick={() => setFechados((s) => { const n = new Set(s); if (n.has(m.chave)) n.delete(m.chave); else n.add(m.chave); return n })}
                      className="alvo flex w-full items-center justify-between gap-3 text-left font-semibold">
                      <span>{m.nome}</span>
                      <span className="flex items-center gap-2 text-xs font-medium text-muted-foreground"><span className="num">{dadas}/{todas.length}</span><ChevronDown className={cn('size-4 transition-transform', !fechado && 'rotate-180')} /></span>
                    </button>
                  </td>
                </tr>
                {!fechado && m.recursos.map((r) => {
                  const aberto = especificas || abertos.has(r.chave)
                  return (
                    <Fragment key={r.chave}>
                      <tr className="border-t">
                        <td className="px-4 py-2">
                          <div className="flex items-center justify-between gap-3">
                            <span className="font-medium">{r.nome}</span>
                            {r.extras.length > 0 && (
                              <button type="button" aria-expanded={aberto} onClick={() => setAbertos((s) => { const n = new Set(s); if (n.has(r.chave)) n.delete(r.chave); else n.add(r.chave); return n })}
                                className="inline-flex flex-none items-center gap-1 rounded px-1.5 py-0.5 text-xs font-medium text-muted-foreground hover:bg-muted">
                                {r.extras.filter((p) => actual.has(p.id)).length}/{r.extras.length} específicas<ChevronDown className={cn('size-3.5 transition-transform', aberto && 'rotate-180')} />
                              </button>
                            )}
                          </div>
                        </td>
                        {ACCOES.map((a) => {
                          const p = r.colunas[a]
                          return (
                            <td key={a} className="px-2 py-2 text-center">
                              {p ? <input type="checkbox" className="size-4 accent-[var(--primary)]" checked={actual.has(p.id)} disabled={!editavel || aplicar.isPending}
                                onChange={() => trocar(p.id)} title={p.descricao ?? p.codigo} aria-label={`${ROTULO_ACCAO[a]} — ${r.nome}`} />
                                : <span className="text-border" aria-label="Não aplicável">—</span>}
                            </td>
                          )
                        })}
                      </tr>
                      {aberto && r.extras.map((p) => (
                        <tr key={p.id} className="bg-muted/30">
                          <td className="py-2 pr-4 pl-8 text-muted-foreground"><span className="inline-flex items-center gap-2"><CornerDownRight className="size-3.5 opacity-60" />{p.descricao ?? p.codigo}</span></td>
                          <td colSpan={4} className="px-2 py-2 text-center">
                            <input type="checkbox" className="size-4 accent-[var(--primary)]" checked={actual.has(p.id)} disabled={!editavel || aplicar.isPending}
                              onChange={() => trocar(p.id)} aria-label={p.descricao ?? p.codigo} />
                          </td>
                        </tr>
                      ))}
                    </Fragment>
                  )
                })}
              </tbody>
            )
          })}
        </table>
      </div>
      {editavel && (
        <div className="sticky bottom-0 flex justify-end gap-3 border-t bg-card/95 py-3 backdrop-blur">
          <span className="mr-auto self-center text-sm text-muted-foreground">{actual.size} permissão(ões) marcada(s)</span>
          <Button variant="outline" className="alvo" disabled={!alterado || aplicar.isPending} onClick={() => setMarcadas(null)}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={!alterado || aplicar.isPending} onClick={guardar}>{aplicar.isPending ? t.comum.aGravar : 'Aplicar'}</Button>
        </div>
      )}
    </div>
  )
}
