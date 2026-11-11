/**
 * Igrejas (F-ORG-01, P-13) · "Que igrejas usam a plataforma, e quem administra cada uma?"
 * Para o super-administrador e a administração da Associação/Missão: registar uma igreja (com o seu administrador),
 * ver todas, e dar um administrador às que não têm. O administrador de cada igreja gere depois os utilizadores dela
 * ("Utilizadores e perfis"). Quem pode registar decide-o a base de dados (V25).
 */
import { useMemo, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { ArrowRight, Building2, Church, Landmark, Loader2, MapPin, Network, Plus, ShieldAlert, UserPlus, Users, X } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { Seleccao } from '@/components/comum/Seleccao'
import { CampoEscolha } from '@/components/comum/CampoEscolha'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { cn } from '@/lib/utils'
import { TIPO_ENTIDADE, TIPO_IGREJA, useAdministradores, useOrganizacaoMut, useDistritos, useDistritosAdministrativos, useEntidadesOrg, useIgrejas, useIgrejasMut, useProvincias, type Igreja, type NovoAdministrador, type TipoIgreja } from './api'

export default function PaginaIgrejas() {
  const { pode, escolherIgreja, recarregar } = useSessao()
  const navigate = useNavigate()
  const igrejas = useIgrejas()
  const entidades = useEntidadesOrg()
  const distritos = useDistritos()
  const admins = useAdministradores((igrejas.data ?? []).filter((i) => !i.endDate).map((i) => i.id))
  const [nova, setNova] = useState(false)
  const [paraAdmin, setParaAdmin] = useState<Igreja | null>(null)
  const provincias = useProvincias()
  const dads = useDistritosAdministrativos()
  const [busca, setBusca] = useState('')
  const [fEnt, setFEnt] = useState('')
  const [fPrv, setFPrv] = useState('')
  const [fDad, setFDad] = useState('')
  const [fTipo, setFTipo] = useState('')
  const [soSemAdmin, setSoSemAdmin] = useState(false)
  const nomeEnt = (id?: number | null) => entidades.data?.find((e) => e.id === id)?.nome ?? '—'
  const nomeDst = (id?: number | null) => distritos.data?.find((d) => d.id === id)?.nome
  const nomePrv = (id?: number | null) => provincias.data?.find((p) => p.id === id)?.nome
  const nomeDad = (id?: number | null) => dads.data?.find((d) => d.id === id)?.nome
  const activas = (igrejas.data ?? []).filter((i) => !i.endDate)
  const comFiltros = !!(busca || fEnt || fPrv || fDad || fTipo || soSemAdmin)
  const limparFiltros = () => { setBusca(''); setFEnt(''); setFPrv(''); setFDad(''); setFTipo(''); setSoSemAdmin(false) }
  const lista = useMemo(() => activas
    .filter((i) => !busca || `${i.nome} ${i.localidade ?? ''} ${i.endereco ?? ''}`.toLowerCase().includes(busca.toLowerCase()))
    .filter((i) => !fEnt || String(i.entidadeId) === fEnt)
    .filter((i) => !fPrv || String(i.provinciaId) === fPrv)
    .filter((i) => !fDad || String(i.distritoAdministrativoId) === fDad)
    .filter((i) => !fTipo || (i.tipo ?? 'IGREJA_ORGANIZADA') === fTipo)
    .filter((i) => !soSemAdmin || !(admins.data?.get(i.id)?.length))
    .sort((a, b) => a.nome.localeCompare(b.nome)),
  // eslint-disable-next-line react-hooks/exhaustive-deps
  [igrejas.data, busca, fEnt, fPrv, fDad, fTipo, soSemAdmin, admins.data])
  const entidadesComIgrejas = (entidades.data ?? []).filter((e) => activas.some((i) => i.entidadeId === e.id))
  const provinciasComIgrejas = (provincias.data ?? []).filter((p) => activas.some((i) => i.provinciaId === p.id))
  const dadsDoFiltro = (dads.data ?? []).filter((d) => (!fPrv || String(d.provinciaId) === fPrv) && activas.some((i) => i.distritoAdministrativoId === d.id))
  const semAdmin = (igrejas.data ?? []).filter((i) => !i.endDate && !(admins.data?.get(i.id)?.length)).length
  const totalAdmins = [...(admins.data?.values() ?? [])].reduce((s, l) => s + l.length, 0)
  const podeCriarUtilizadores = pode('nucleo.usuario.criar')
  const [params, setParams] = useSearchParams()
  const aba = (params.get('ver') ?? 'igrejas') as 'igrejas' | 'associacoes' | 'distritos'
  const mudarAba = (v: string) => setParams((x) => { const n = new URLSearchParams(x); if (v === 'igrejas') n.delete('ver'); else n.set('ver', v); return n }, { replace: true })
  const [novaEnt, setNovaEnt] = useState(false)
  const [novoDst, setNovoDst] = useState(false)

  const [aAbrir, setAAbrir] = useState<number | null>(null)
  const abrir = async (id: number) => {
    setAAbrir(id)
    try {
      await recarregar()
      escolherIgreja(id)
      navigate('/')
    } finally {
      setAAbrir(null)
    }
  }

  return (
    <>
      <TituloPagina icone={Building2} titulo="Igrejas" descricao="As igrejas que usam a plataforma, as Associações/Missões e os distritos pastorais"
        accoes={aba === 'igrejas' ? (pode('organizacao.igreja.criar') && <Button className="alvo" onClick={() => setNova(true)}><Plus className="size-4" />Registar igreja</Button>)
          : aba === 'associacoes' ? (pode('organizacao.entidade.criar') && <Button className="alvo" onClick={() => setNovaEnt(true)}><Plus className="size-4" />Registar Associação / Missão</Button>)
          : (pode('organizacao.distrito.criar') && <Button className="alvo" onClick={() => setNovoDst(true)}><Plus className="size-4" />Registar distrito pastoral</Button>)} />
      <div role="tablist" aria-label="O que ver" className="mb-6 inline-flex flex-wrap gap-1 rounded-lg bg-muted p-1">
        {[{ v: 'igrejas', r: 'Igrejas', I: Church, n: activas.length }, { v: 'associacoes', r: 'Associações / Missões', I: Landmark, n: (entidades.data ?? []).filter((e) => !e.endDate).length },
          { v: 'distritos', r: 'Distritos pastorais', I: Network, n: (distritos.data ?? []).filter((d) => !d.endDate).length }].map((o) => (
          <button key={o.v} type="button" role="tab" aria-selected={aba === o.v} onClick={() => mudarAba(o.v)}
            className={cn('alvo flex items-center gap-2 rounded-md px-3 py-1.5 text-sm font-medium text-muted-foreground', aba === o.v && 'bg-card text-foreground shadow-sm')}>
            <o.I className="size-4" />{o.r}<span className="rounded-full bg-muted px-1.5 text-xs tabular-nums">{o.n}</span>
          </button>
        ))}
      </div>
      {aba === 'associacoes' && <ListaAssociacoes />}
      {aba === 'distritos' && <ListaDistritos />}
      {novaEnt && <DialogoEntidade aoFechar={() => setNovaEnt(false)} />}
      {novoDst && <DialogoDistrito aoFechar={() => setNovoDst(false)} />}
      <div className={cn('grid gap-6', aba !== 'igrejas' && 'hidden')}>
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4 [&>*:last-child]:col-span-2 sm:[&>*:last-child]:col-span-1">
          <Indicador rotulo="Igrejas" valor={(igrejas.data ?? []).filter((i) => !i.endDate).length} nota="registadas na plataforma" icone={Church} aCarregar={igrejas.isPending} />
          <Indicador rotulo="Administradores" valor={totalAdmins} nota="com o perfil ADMIN" icone={Users} tom="info" aCarregar={admins.isPending} />
          <Indicador rotulo="Sem administrador" valor={semAdmin} nota="ninguém as administra ainda" icone={ShieldAlert} tom={semAdmin ? 'warning' : 'success'} aCarregar={igrejas.isPending || admins.isPending} />
        </div>

        <Cartao titulo="Todas as igrejas" descricao={comFiltros ? `${lista.length} de ${activas.length} igreja(s)` : `${activas.length} igreja(s)`} icone={Church} semMargem>
          <div className="grid gap-2 border-y bg-muted/30 px-4 py-3 sm:grid-cols-2 sm:px-6 lg:grid-cols-[1.4fr_1fr_1fr_1fr_1fr_auto]">
            <Input value={busca} onChange={(e) => setBusca(e.target.value)} placeholder="Procurar por nome ou localidade…" className="alvo h-9" aria-label="Procurar igreja" />
            <CampoEscolha valor={fEnt} aoMudar={setFEnt} vazio="Associação" permitirLimpar
              opcoes={entidadesComIgrejas.map((e) => ({ valor: String(e.id), rotulo: e.nome }))} />
            <CampoEscolha valor={fPrv} aoMudar={(v) => { setFPrv(v); setFDad('') }} vazio="Província" permitirLimpar
              opcoes={provinciasComIgrejas.map((x) => ({ valor: String(x.id), rotulo: x.nome }))} />
            <CampoEscolha valor={fDad} aoMudar={setFDad} vazio="Distrito" permitirLimpar
              opcoes={dadsDoFiltro.map((d) => ({ valor: String(d.id), rotulo: d.nome, detalhe: nomePrv(d.provinciaId) }))} />
            <Seleccao aria-label="Tipo" value={fTipo} onChange={(e) => setFTipo(e.target.value)} className="h-9">
              <option value="">Tipo</option>
              {Object.entries(TIPO_IGREJA).map(([k, r]) => <option key={k} value={k}>{r}</option>)}
            </Seleccao>
            <div className="flex items-center gap-2">
              <button type="button" aria-pressed={soSemAdmin} onClick={() => setSoSemAdmin((v) => !v)}
                className={cn('alvo h-9 rounded-md border px-3 text-sm whitespace-nowrap', soSemAdmin ? 'border-warning/40 bg-tint-warning text-warning-text' : 'bg-card hover:bg-muted/50')}>
                Sem administrador
              </button>
              {comFiltros && <Button variant="ghost" size="sm" className="alvo h-9 px-2" onClick={limparFiltros} aria-label="Limpar filtros"><X className="size-4" /></Button>}
            </div>
          </div>
          {igrejas.isPending ? <LinhasACarregar linhas={4} />
            : igrejas.isError ? <EstadoErro erro={igrejas.error} aoTentar={() => igrejas.refetch()} className="mx-6 mb-6" />
            : !lista.length ? (comFiltros
              ? <EstadoVazio icone={Church} titulo="Nenhuma igreja com estes filtros" accao={<Button variant="outline" className="alvo" onClick={limparFiltros}>Limpar filtros</Button>}>Mude ou limpe os filtros.</EstadoVazio>
              : <EstadoVazio icone={Church} titulo="Ainda não há igrejas">Registe a primeira igreja e o seu administrador.</EstadoVazio>)
            : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Igreja</th><th className="hidden md:table-cell">Localização</th><th className="hidden xl:table-cell">Associação / distrito pastoral</th><th>Administrador</th><th className="sm:pr-6"><span className="sr-only">Acções</span></th></tr></thead>
                <tbody>
                  {lista.map((i) => {
                    const a = admins.data?.get(i.id) ?? []
                    return (
                      <tr key={i.id}>
                        <td className="sm:pl-6">
                          <p className="font-medium">{i.nome}</p>
                          <p className="text-xs text-muted-foreground">{TIPO_IGREJA[(i.tipo ?? 'IGREJA_ORGANIZADA') as TipoIgreja]}</p>
                        </td>
                        <td className="hidden text-sm md:table-cell">
                          {nomePrv(i.provinciaId) ? (
                            <>
                              <p className="flex items-center gap-1"><MapPin className="size-3.5 flex-none text-muted-foreground" />{[nomeDad(i.distritoAdministrativoId), nomePrv(i.provinciaId)].filter(Boolean).join(', ')}</p>
                              {(i.localidade || i.endereco) && <p className="text-xs text-muted-foreground">{i.localidade ?? i.endereco}</p>}
                            </>
                          ) : <span className="text-xs text-muted-foreground">{i.endereco ?? 'por indicar'}</span>}
                        </td>
                        <td className="hidden text-sm xl:table-cell">
                          <p>{nomeEnt(i.entidadeId)}</p>
                          {nomeDst(i.distritoId) && <p className="text-xs text-muted-foreground">{nomeDst(i.distritoId)}</p>}
                        </td>
                        <td>
                          {admins.isPending ? <span className="text-xs text-muted-foreground">…</span>
                            : a.length ? <span className="text-sm">{a.join(', ')}</span>
                            : <Pilula variante="warning">sem administrador</Pilula>}
                        </td>
                        <td className="sm:pr-6">
                          <div className="flex justify-end gap-2">
                            {podeCriarUtilizadores && (
                              <Button size="sm" variant={a.length ? 'ghost' : 'outline'} className="alvo" onClick={() => setParaAdmin(i)}>
                                <UserPlus className="size-4" /><span className="hidden lg:inline">{a.length ? 'Outro administrador' : 'Dar administrador'}</span>
                              </Button>
                            )}
                            <Button size="sm" variant="ghost" className="alvo min-w-24" disabled={aAbrir != null} onClick={() => abrir(i.id)} aria-label={`Abrir ${i.nome}`} aria-busy={aAbrir === i.id}>
                              {aAbrir === i.id
                                ? <><Loader2 className="size-4 animate-spin" /><span className="hidden sm:inline">A abrir…</span></>
                                : <><span className="hidden sm:inline">Abrir</span><ArrowRight className="size-4" /></>}
                            </Button>
                          </div>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </Tabela>
            )}
        </Cartao>
      </div>
      {nova && <DialogoIgreja aoFechar={() => setNova(false)} aoCriar={async (id) => { await recarregar(); setNova(false); toast.message('Pode abrir a igreja nova na lista.', { action: { label: 'Abrir', onClick: () => abrir(id) } }) }} />}
      {paraAdmin && <DialogoAdministrador igreja={paraAdmin} aoFechar={() => setParaAdmin(null)} />}
    </>
  )
}

/* -------------------------------------------------------------------- campos do administrador */
function CamposAdministrador({ v, set, prefixo }: { v: NovoAdministrador; set: (v: NovoAdministrador) => void; prefixo: string }) {
  return (
    <div className="grid gap-3 sm:grid-cols-2">
      <div className="grid gap-1.5 sm:col-span-2">
        <label htmlFor={`${prefixo}-nome`} className="text-sm font-medium">Nome</label>
        <Input id={`${prefixo}-nome`} value={v.nome} onChange={(e) => set({ ...v, nome: e.target.value })} maxLength={150} placeholder="ex.: Gabriel Langa" className="alvo" />
      </div>
      <div className="grid gap-1.5">
        <label htmlFor={`${prefixo}-tel`} className="text-sm font-medium">Telefone</label>
        <Input id={`${prefixo}-tel`} value={v.telefone} onChange={(e) => set({ ...v, telefone: e.target.value })} inputMode="tel" placeholder="+258 84 000 0000" className="alvo num" />
      </div>
      <div className="grid gap-1.5">
        <label htmlFor={`${prefixo}-email`} className="text-sm font-medium">E-mail</label>
        <Input id={`${prefixo}-email`} value={v.email} onChange={(e) => set({ ...v, email: e.target.value })} inputMode="email" placeholder="opcional" className="alvo" />
      </div>
      <label className="alvo flex items-center gap-2 text-sm sm:col-span-2">
        <input type="checkbox" checked={v.enviarCodigo} onChange={(e) => set({ ...v, enviarCodigo: e.target.checked })} className="size-4 accent-[var(--primary)]" />
        Enviar já o código por SMS para definir a senha
      </label>
    </div>
  )
}
const ADMIN_VAZIO: NovoAdministrador = { nome: '', email: '', telefone: '', enviarCodigo: true }
const telefoneValido = (t: string) => !t || /^\+?[\d\s]{9,16}$/.test(t)
const normalizarTelefone = (t: string) => { const d = t.replace(/\s/g, ''); return d && !d.startsWith('+') ? (d.startsWith('258') ? `+${d}` : `+258${d}`) : d }

function validarAdmin(a: NovoAdministrador): string | null {
  if (a.nome.trim().length < 3) return 'Escreva o nome do administrador.'
  if (!a.telefone.trim() && !a.email.trim()) return 'O administrador precisa de telefone ou e-mail para entrar.'
  if (!telefoneValido(a.telefone.trim())) return 'Telefone inválido (ex.: +258 84 000 0000).'
  if (a.email.trim() && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(a.email.trim())) return 'E-mail inválido.'
  return null
}
const limpar = (a: NovoAdministrador): NovoAdministrador => ({ ...a, nome: a.nome.trim(), email: a.email.trim(), telefone: normalizarTelefone(a.telefone.trim()) })

/* -------------------------------------------------------------------- registar igreja */
function DialogoIgreja({ aoFechar, aoCriar }: { aoFechar: () => void; aoCriar: (id: number) => void }) {
  const entidades = useEntidadesOrg()
  const distritos = useDistritos()
  const igrejas = useIgrejas()
  const { registar } = useIgrejasMut()
  const campos = (entidades.data ?? []).filter((e) => ['ASSOCIACAO', 'MISSAO', 'CAMPO'].includes(e.tipo) && !e.endDate)
  const [nome, setNome] = useState('')
  const [tipo, setTipo] = useState<TipoIgreja>('IGREJA_ORGANIZADA')
  const [entidadeId, setEntidadeId] = useState('')
  const [distritoId, setDistritoId] = useState('')
  const [maeId, setMaeId] = useState('')
  const [endereco, setEndereco] = useState('')
  const provincias = useProvincias()
  const dads = useDistritosAdministrativos()
  const [prvId, setPrvId] = useState('')
  const [dadId, setDadId] = useState('')
  const [localidade, setLocalidade] = useState('')
  const dadsDaProvincia = (dads.data ?? []).filter((d) => String(d.provinciaId) === prvId && !d.endDate).sort((a, b) => a.nome.localeCompare(b.nome, 'pt'))
  const [codigo, setCodigo] = useState('')
  const [dataOrg, setDataOrg] = useState('')
  const [comAdmin, setComAdmin] = useState(true)
  const [admin, setAdmin] = useState<NovoAdministrador>(ADMIN_VAZIO)
  const [erro, setErro] = useState<string | null>(null)
  const ent = entidadeId || String(campos[0]?.id ?? '')
  const dstDaEnt = (distritos.data ?? []).filter((d) => String(d.entidadeId) === ent && !d.endDate)
  const maes = (igrejas.data ?? []).filter((i) => !i.endDate && String(i.entidadeId) === ent && i.tipo === 'IGREJA_ORGANIZADA')

  const submeter = async () => {
    setErro(null)
    if (nome.trim().length < 3) return setErro('Escreva o nome da igreja.')
    if (!ent) return setErro('Escolha a Associação/Missão.')
    if (tipo !== 'IGREJA_ORGANIZADA' && !maeId) return setErro('Um grupo ou filial precisa da igreja-mãe.')
    if (!prvId || !dadId) return setErro('Indique a província e o distrito onde fica a igreja.')
    if (localidade.trim().length < 2) return setErro('Indique a localidade (ou o bairro).')
    if (comAdmin) { const e = validarAdmin(admin); if (e) return setErro(e) }
    try {
      const { igreja, erroAdmin } = await registar.mutateAsync({
        igreja: {
          nome: nome.trim(), tipo, entidadeId: Number(ent), distritoId: distritoId ? Number(distritoId) : undefined,
          maeIgrejaId: tipo !== 'IGREJA_ORGANIZADA' && maeId ? Number(maeId) : undefined,
          provinciaId: Number(prvId), distritoAdministrativoId: Number(dadId), localidade: localidade.trim(),
          endereco: endereco.trim() || undefined, codigoAcms: codigo.trim() || undefined, dataOrganizacao: dataOrg || undefined,
        },
        administrador: comAdmin ? limpar(admin) : undefined,
      })
      if (erroAdmin) toast.warning(`Igreja "${igreja.nome}" registada, mas o administrador não foi criado`, { description: `${mensagemDe(erroAdmin)} Use "Dar administrador" na lista.` })
      else toast.success(comAdmin ? `Igreja "${igreja.nome}" registada, com o administrador ${admin.nome.trim()}.` : `Igreja "${igreja.nome}" registada.`)
      aoCriar(igreja.id)
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="max-h-[92dvh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>Registar igreja</DialogTitle>
          <DialogDescription>A igreja passa a usar a plataforma; o administrador gere depois os utilizadores dela.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-5">
          <ErroFormulario mensagem={erro} />
          <fieldset className="grid gap-3">
            <legend className="mb-1 text-xs font-semibold tracking-wider text-muted-foreground uppercase">1. A igreja</legend>
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="grid gap-1.5 sm:col-span-2">
                <label htmlFor="igr-nome" className="text-sm font-medium">Nome <span className="text-destructive-text">*</span></label>
                <Input id="igr-nome" value={nome} onChange={(e) => setNome(e.target.value)} maxLength={150} placeholder="ex.: Igreja de Nwamatibjana" className="alvo" autoFocus />
              </div>
              <div className="grid gap-1.5">
                <label htmlFor="igr-tipo" className="text-sm font-medium">Tipo</label>
                <Seleccao id="igr-tipo" value={tipo} onChange={(e) => setTipo(e.target.value as TipoIgreja)}>
                  {Object.entries(TIPO_IGREJA).map(([k, r]) => <option key={k} value={k}>{r}</option>)}
                </Seleccao>
              </div>
              <div className="grid gap-1.5">
                <label htmlFor="igr-ent" className="text-sm font-medium">Associação / Missão <span className="text-destructive-text">*</span></label>
                <CampoEscolha id="igr-ent" valor={ent} aoMudar={(v) => { setEntidadeId(v); setDistritoId(''); setMaeId('') }} pesquisar="Pesquisar Associação…"
                  semOpcoes="Registe primeiro a Associação/Missão" opcoes={campos.map((e) => ({ valor: String(e.id), rotulo: e.nome, detalhe: [TIPO_ENTIDADE[e.tipo], e.sigla].filter(Boolean).join(' · ') }))} />
              </div>
              <div className="grid gap-1.5">
                <label htmlFor="igr-dst" className="text-sm font-medium">Distrito pastoral</label>
                <CampoEscolha id="igr-dst" valor={distritoId} aoMudar={setDistritoId} permitirLimpar pesquisar="Pesquisar distrito pastoral…"
                  vazio="Sem distrito pastoral" semOpcoes="Esta Associação ainda não tem distritos"
                  opcoes={dstDaEnt.map((d) => ({ valor: String(d.id), rotulo: d.nome }))} />
              </div>
              {tipo !== 'IGREJA_ORGANIZADA' && (
                <div className="grid gap-1.5">
                  <label htmlFor="igr-mae" className="text-sm font-medium">Igreja-mãe <span className="text-destructive-text">*</span></label>
                  <CampoEscolha id="igr-mae" valor={maeId} aoMudar={setMaeId} pesquisar="Pesquisar igreja…" semOpcoes="Não há igrejas organizadas nesta Associação"
                    opcoes={maes.map((m) => ({ valor: String(m.id), rotulo: m.nome }))} />
                </div>
              )}
              <div className="grid gap-1.5">
                <label htmlFor="igr-data" className="text-sm font-medium">Organizada em</label>
                <CampoData id="igr-data" value={dataOrg} onChange={setDataOrg} className="alvo" />
              </div>
              <div className="grid gap-1.5">
                <label htmlFor="igr-cod" className="text-sm font-medium">Código ACMS</label>
                <Input id="igr-cod" value={codigo} onChange={(e) => setCodigo(e.target.value)} maxLength={30} placeholder="opcional" className="alvo" />
              </div>
            </div>
          </fieldset>
          <fieldset className="grid gap-3">
            <legend className="mb-1 text-xs font-semibold tracking-wider text-muted-foreground uppercase">2. Onde fica</legend>
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="grid gap-1.5">
                <label htmlFor="igr-prv" className="text-sm font-medium">Província <span className="text-destructive-text">*</span></label>
                <CampoEscolha id="igr-prv" valor={prvId} aoMudar={(v) => { setPrvId(v); setDadId('') }} pesquisar="Pesquisar província…"
                  opcoes={(provincias.data ?? []).filter((x) => !x.endDate).map((x) => ({ valor: String(x.id), rotulo: x.nome }))} />
              </div>
              <div className="grid gap-1.5">
                <label htmlFor="igr-dad" className="text-sm font-medium">Distrito <span className="text-destructive-text">*</span></label>
                <CampoEscolha id="igr-dad" valor={dadId} aoMudar={setDadId} disabled={!prvId} pesquisar="Pesquisar distrito…"
                  vazio={prvId ? 'Escolher…' : 'Escolha primeiro a província'}
                  opcoes={dadsDaProvincia.map((d) => ({ valor: String(d.id), rotulo: d.nome }))} />
              </div>
              <div className="grid gap-1.5">
                <label htmlFor="igr-loc" className="text-sm font-medium">Localidade / bairro <span className="text-destructive-text">*</span></label>
                <Input id="igr-loc" value={localidade} onChange={(e) => setLocalidade(e.target.value)} maxLength={120} placeholder="ex.: Bairro de Nwamatibjana" className="alvo" />
              </div>
              <div className="grid gap-1.5">
                <label htmlFor="igr-end" className="text-sm font-medium">Endereço</label>
                <Input id="igr-end" value={endereco} onChange={(e) => setEndereco(e.target.value)} maxLength={255} placeholder="ex.: Rua 4, quarteirão 12" className="alvo" />
              </div>
            </div>
          </fieldset>
          <fieldset className="grid gap-3 rounded-lg border p-4">
            <legend className="px-1 text-xs font-semibold tracking-wider text-muted-foreground uppercase">3. O administrador da igreja</legend>
            <label className="alvo flex items-center gap-2 text-sm">
              <input type="checkbox" checked={comAdmin} onChange={(e) => setComAdmin(e.target.checked)} className="size-4 accent-[var(--primary)]" />
              Criar já o administrador (perfil ADMIN nesta igreja)
            </label>
            {comAdmin && <CamposAdministrador v={admin} set={setAdmin} prefixo="nova" />}
          </fieldset>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={registar.isPending} onClick={submeter}>{registar.isPending ? t.comum.aGravar : 'Registar igreja'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/* -------------------------------------------------------------------- dar administrador a uma igreja */
function DialogoAdministrador({ igreja, aoFechar }: { igreja: Igreja; aoFechar: () => void }) {
  const { administrador } = useIgrejasMut()
  const [admin, setAdmin] = useState<NovoAdministrador>(ADMIN_VAZIO)
  const [erro, setErro] = useState<string | null>(null)
  const submeter = async () => {
    setErro(null)
    const e = validarAdmin(admin); if (e) return setErro(e)
    try {
      await administrador.mutateAsync({ igrejaId: igreja.id, administrador: limpar(admin) })
      toast.success(`${admin.nome.trim()} é administrador(a) de ${igreja.nome}.${admin.enviarCodigo ? ' O código para definir a senha foi enviado.' : ''}`)
      aoFechar()
    } catch (err) {
      setErro(mensagemDe(err))
    }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Administrador de {igreja.nome}</DialogTitle>
          <DialogDescription>Recebe o perfil ADMIN nesta igreja: regista os utilizadores e gere a igreja.</DialogDescription>
        </DialogHeader>
        <div className={cn('grid gap-4')}>
          <ErroFormulario mensagem={erro} />
          <CamposAdministrador v={admin} set={setAdmin} prefixo="adm" />
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={administrador.isPending} onClick={submeter}>{administrador.isPending ? t.comum.aGravar : 'Criar administrador'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/* -------------------------------------------------------------------- Associações / Missões */
function ListaAssociacoes() {
  const entidades = useEntidadesOrg()
  const igrejas = useIgrejas()
  const distritos = useDistritos()
  const [busca, setBusca] = useState('')
  const nomeDe = (id?: number | null) => entidades.data?.find((e) => e.id === id)?.nome
  const lista = (entidades.data ?? []).filter((e) => !e.endDate)
    .filter((e) => !busca || `${e.nome} ${e.sigla ?? ''}`.toLowerCase().includes(busca.toLowerCase()))
    .sort((a, b) => a.nome.localeCompare(b.nome, 'pt'))
  return (
    <Cartao titulo="Associações / Missões" descricao="Os campos a que as igrejas pertencem (e os níveis acima)" icone={Landmark} semMargem
      accoes={<Input value={busca} onChange={(e) => setBusca(e.target.value)} placeholder="Procurar…" className="alvo h-9 w-44 sm:w-60" aria-label="Procurar Associação" />}>
      {entidades.isPending ? <LinhasACarregar linhas={3} />
        : entidades.isError ? <EstadoErro erro={entidades.error} aoTentar={() => entidades.refetch()} className="mx-6 mb-6" />
        : !lista.length ? <EstadoVazio icone={Landmark} titulo="Ainda não há Associações">Registe a Associação ou Missão a que as igrejas pertencem.</EstadoVazio>
        : (
          <Tabela>
            <thead><tr><th className="sm:pl-6">Nome</th><th>Tipo</th><th className="hidden md:table-cell">Pertence a</th><th className="num">Distritos</th><th className="num sm:pr-6">Igrejas</th></tr></thead>
            <tbody>
              {lista.map((e) => (
                <tr key={e.id}>
                  <td className="sm:pl-6"><p className="font-medium">{e.nome}</p>{e.sigla && <p className="text-xs text-muted-foreground">{e.sigla}</p>}</td>
                  <td><Pilula variante={['ASSOCIACAO', 'MISSAO', 'CAMPO'].includes(e.tipo) ? 'info' : 'secondary'}>{TIPO_ENTIDADE[e.tipo] ?? e.tipo}</Pilula></td>
                  <td className="hidden text-sm text-muted-foreground md:table-cell">{nomeDe(e.paiEntidadeId) ?? '—'}</td>
                  <td className="num">{(distritos.data ?? []).filter((d) => !d.endDate && d.entidadeId === e.id).length}</td>
                  <td className="num sm:pr-6">{(igrejas.data ?? []).filter((i) => !i.endDate && i.entidadeId === e.id).length}</td>
                </tr>
              ))}
            </tbody>
          </Tabela>
        )}
    </Cartao>
  )
}

function DialogoEntidade({ aoFechar }: { aoFechar: () => void }) {
  const entidades = useEntidadesOrg()
  const { entidade } = useOrganizacaoMut()
  const [tipo, setTipo] = useState('MISSAO')
  const [nome, setNome] = useState('')
  const [sigla, setSigla] = useState('')
  const [paiId, setPaiId] = useState('')
  const [fundos, setFundos] = useState(true)
  const [pct, setPct] = useState('50')
  const [erro, setErro] = useState<string | null>(null)
  const ehCampo = ['ASSOCIACAO', 'MISSAO', 'CAMPO'].includes(tipo)
  const submeter = async () => {
    setErro(null)
    if (nome.trim().length < 3) return setErro('Escreva o nome (ex.: Missão Sul de Moçambique).')
    if (ehCampo && fundos && !/^\d{1,3}(\.\d{1,2})?$/.test(pct.replace(',', '.'))) return setErro('A parte da Missão na oferta combinada é uma percentagem (ex.: 50).')
    try {
      const r = await entidade.mutateAsync({ tipo, nome: nome.trim(), sigla: sigla.trim().toUpperCase(), paiId: paiId ? Number(paiId) : undefined,
        fundos: ehCampo && fundos ? { percentagemOfertaCombinada: pct.replace(',', '.') } : undefined })
      if (r.erroFundos) toast.warning(`${r.entidade.nome} registada, mas os fundos não foram criados`, { description: mensagemDe(r.erroFundos) })
      else toast.success(`${r.entidade.nome} registada${ehCampo && fundos ? ', com os fundos (dízimo, ofertas, Escola Sabatina)' : ''}.`)
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Registar Associação / Missão</DialogTitle>
          <DialogDescription>O campo a que as igrejas pertencem e para onde vão o dízimo e a parte da Missão nas ofertas.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="grid gap-1.5 sm:col-span-2">
              <label htmlFor="ent-nome" className="text-sm font-medium">Nome <span className="text-destructive-text">*</span></label>
              <Input id="ent-nome" value={nome} onChange={(e) => setNome(e.target.value)} maxLength={150} placeholder="ex.: Missão Sul de Moçambique" className="alvo" autoFocus />
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="ent-tipo" className="text-sm font-medium">Tipo</label>
              <Seleccao id="ent-tipo" value={tipo} onChange={(e) => setTipo(e.target.value)}>
                {Object.entries(TIPO_ENTIDADE).map(([k, r]) => <option key={k} value={k}>{r}</option>)}
              </Seleccao>
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="ent-sigla" className="text-sm font-medium">Sigla</label>
              <Input id="ent-sigla" value={sigla} onChange={(e) => setSigla(e.target.value)} maxLength={10} placeholder="ex.: MSM" className="alvo uppercase" />
            </div>
            <div className="grid gap-1.5 sm:col-span-2">
              <label htmlFor="ent-pai" className="text-sm font-medium">Pertence a</label>
              <CampoEscolha id="ent-pai" valor={paiId} aoMudar={setPaiId} permitirLimpar vazio="Nenhuma (nível de topo)" pesquisar="Pesquisar União, Divisão…"
                opcoes={(entidades.data ?? []).filter((e) => !e.endDate).map((e) => ({ valor: String(e.id), rotulo: e.nome, detalhe: TIPO_ENTIDADE[e.tipo] }))} />
            </div>
          </div>
          {ehCampo && (
            <fieldset className="grid gap-3 rounded-lg border p-4">
              <label className="alvo flex items-center gap-2 text-sm">
                <input type="checkbox" checked={fundos} onChange={(e) => setFundos(e.target.checked)} className="size-4 accent-[var(--primary)]" />
                Criar já os fundos (dízimo, ofertas missionárias, Escola Sabatina, oferta combinada)
              </label>
              {fundos && (
                <div className="grid gap-1.5 sm:max-w-xs">
                  <label htmlFor="ent-pct" className="text-sm font-medium">Parte da Missão na oferta combinada (%)</label>
                  <Input id="ent-pct" value={pct} onChange={(e) => setPct(e.target.value)} inputMode="decimal" className="alvo num" />
                  <p className="text-xs text-muted-foreground">O resto fica na igreja. O dízimo vai sempre 100% para a Missão.</p>
                </div>
              )}
            </fieldset>
          )}
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={entidade.isPending} onClick={submeter}>{entidade.isPending ? t.comum.aGravar : 'Registar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/* -------------------------------------------------------------------- distritos pastorais */
function ListaDistritos() {
  const entidades = useEntidadesOrg()
  const distritos = useDistritos()
  const igrejas = useIgrejas()
  const [fEnt, setFEnt] = useState('')
  const nomeEnt = (id?: number | null) => entidades.data?.find((e) => e.id === id)?.nome ?? '—'
  const lista = (distritos.data ?? []).filter((d) => !d.endDate && (!fEnt || String(d.entidadeId) === fEnt))
    .sort((a, b) => nomeEnt(a.entidadeId).localeCompare(nomeEnt(b.entidadeId), 'pt') || a.nome.localeCompare(b.nome, 'pt'))
  return (
    <Cartao titulo="Distritos pastorais" descricao="Os distritos de cada Associação/Missão (cada um com o seu pastor)" icone={Network} semMargem
      accoes={<div className="w-52 sm:w-64"><CampoEscolha valor={fEnt} aoMudar={setFEnt} vazio="Todas as Associações" permitirLimpar
        opcoes={(entidades.data ?? []).filter((e) => !e.endDate).map((e) => ({ valor: String(e.id), rotulo: e.nome }))} /></div>}>
      {distritos.isPending ? <LinhasACarregar linhas={3} />
        : distritos.isError ? <EstadoErro erro={distritos.error} aoTentar={() => distritos.refetch()} className="mx-6 mb-6" />
        : !lista.length ? <EstadoVazio icone={Network} titulo="Ainda não há distritos pastorais">Registe os distritos da Associação; depois escolha-os ao registar as igrejas.</EstadoVazio>
        : (
          <Tabela>
            <thead><tr><th className="sm:pl-6">Distrito pastoral</th><th>Associação / Missão</th><th className="num sm:pr-6">Igrejas</th></tr></thead>
            <tbody>
              {lista.map((d) => (
                <tr key={d.id}>
                  <td className="font-medium sm:pl-6">{d.nome}</td>
                  <td className="text-sm text-muted-foreground">{nomeEnt(d.entidadeId)}</td>
                  <td className="num sm:pr-6">{(igrejas.data ?? []).filter((i) => !i.endDate && i.distritoId === d.id).length}</td>
                </tr>
              ))}
            </tbody>
          </Tabela>
        )}
    </Cartao>
  )
}

function DialogoDistrito({ aoFechar }: { aoFechar: () => void }) {
  const entidades = useEntidadesOrg()
  const { distrito } = useOrganizacaoMut()
  const campos = (entidades.data ?? []).filter((e) => !e.endDate && ['ASSOCIACAO', 'MISSAO', 'CAMPO'].includes(e.tipo))
  const [entId, setEntId] = useState('')
  const [nome, setNome] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const ent = entId || String(campos[0]?.id ?? '')
  const submeter = async () => {
    setErro(null)
    if (!ent) return setErro('Registe primeiro a Associação/Missão.')
    if (nome.trim().length < 3) return setErro('Escreva o nome do distrito (ex.: Distrito de Xai-Xai).')
    try {
      await distrito.mutateAsync({ entidadeId: Number(ent), nome: nome.trim() })
      toast.success(`Distrito "${nome.trim()}" registado.`)
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Registar distrito pastoral</DialogTitle>
          <DialogDescription>Um grupo de igrejas acompanhadas pelo mesmo pastor, dentro da Associação/Missão.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5">
            <label htmlFor="dst-ent" className="text-sm font-medium">Associação / Missão <span className="text-destructive-text">*</span></label>
            <CampoEscolha id="dst-ent" valor={ent} aoMudar={setEntId} pesquisar="Pesquisar Associação…" semOpcoes="Registe primeiro a Associação/Missão"
              opcoes={campos.map((e) => ({ valor: String(e.id), rotulo: e.nome, detalhe: TIPO_ENTIDADE[e.tipo] }))} />
          </div>
          <div className="grid gap-1.5">
            <label htmlFor="dst-nome" className="text-sm font-medium">Nome <span className="text-destructive-text">*</span></label>
            <Input id="dst-nome" value={nome} onChange={(e) => setNome(e.target.value)} maxLength={100} placeholder="ex.: Distrito de Xai-Xai" className="alvo" autoFocus />
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={distrito.isPending} onClick={submeter}>{distrito.isPending ? t.comum.aGravar : 'Registar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
