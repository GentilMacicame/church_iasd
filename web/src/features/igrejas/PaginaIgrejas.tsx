/**
 * Igrejas (F-ORG-01, P-13) · "Que igrejas usam a plataforma, e quem administra cada uma?"
 * Para o super-administrador e a administração da Associação/Missão: registar uma igreja (com o seu administrador),
 * ver todas, e dar um administrador às que não têm. O administrador de cada igreja gere depois os utilizadores dela
 * ("Utilizadores e perfis"). Quem pode registar decide-o a base de dados (V25).
 */
import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowRight, Building2, Church, Plus, ShieldAlert, UserPlus, Users } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { Seleccao } from '@/components/comum/Seleccao'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { cn } from '@/lib/utils'
import { TIPO_IGREJA, useAdministradores, useDistritos, useEntidadesOrg, useIgrejas, useIgrejasMut, type Igreja, type NovoAdministrador, type TipoIgreja } from './api'

export default function PaginaIgrejas() {
  const { pode, escolherIgreja, recarregar } = useSessao()
  const navigate = useNavigate()
  const igrejas = useIgrejas()
  const entidades = useEntidadesOrg()
  const distritos = useDistritos()
  const admins = useAdministradores((igrejas.data ?? []).filter((i) => !i.endDate).map((i) => i.id))
  const [nova, setNova] = useState(false)
  const [paraAdmin, setParaAdmin] = useState<Igreja | null>(null)
  const [busca, setBusca] = useState('')
  const nomeEnt = (id?: number | null) => entidades.data?.find((e) => e.id === id)?.nome ?? '—'
  const nomeDst = (id?: number | null) => distritos.data?.find((d) => d.id === id)?.nome
  const lista = useMemo(() => (igrejas.data ?? []).filter((i) => !i.endDate)
    .filter((i) => !busca || i.nome.toLowerCase().includes(busca.toLowerCase()))
    .sort((a, b) => a.nome.localeCompare(b.nome)), [igrejas.data, busca])
  const semAdmin = (igrejas.data ?? []).filter((i) => !i.endDate && !(admins.data?.get(i.id)?.length)).length
  const totalAdmins = [...(admins.data?.values() ?? [])].reduce((s, l) => s + l.length, 0)
  const podeCriarUtilizadores = pode('nucleo.usuario.criar')

  const abrir = async (id: number) => {
    await recarregar()
    escolherIgreja(id)
    navigate('/')
  }

  return (
    <>
      <TituloPagina icone={Building2} titulo="Igrejas" descricao="As igrejas que usam a plataforma e quem administra cada uma"
        accoes={pode('organizacao.igreja.criar') && <Button className="alvo" onClick={() => setNova(true)}><Plus className="size-4" />Registar igreja</Button>} />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4 [&>*:last-child]:col-span-2 sm:[&>*:last-child]:col-span-1">
          <Indicador rotulo="Igrejas" valor={(igrejas.data ?? []).filter((i) => !i.endDate).length} nota="registadas na plataforma" icone={Church} aCarregar={igrejas.isPending} />
          <Indicador rotulo="Administradores" valor={totalAdmins} nota="com o perfil ADMIN" icone={Users} tom="info" aCarregar={admins.isPending} />
          <Indicador rotulo="Sem administrador" valor={semAdmin} nota="ninguém as administra ainda" icone={ShieldAlert} tom={semAdmin ? 'warning' : 'success'} aCarregar={igrejas.isPending || admins.isPending} />
        </div>

        <Cartao titulo="Todas as igrejas" icone={Church} semMargem
          accoes={<Input value={busca} onChange={(e) => setBusca(e.target.value)} placeholder="Procurar igreja…" className="alvo h-9 w-44 sm:w-60" aria-label="Procurar igreja" />}>
          {igrejas.isPending ? <LinhasACarregar linhas={4} />
            : igrejas.isError ? <EstadoErro erro={igrejas.error} aoTentar={() => igrejas.refetch()} className="mx-6 mb-6" />
            : !lista.length ? <EstadoVazio icone={Church} titulo={busca ? 'Nenhuma igreja com esse nome' : 'Ainda não há igrejas'}>Registe a primeira igreja e o seu administrador.</EstadoVazio>
            : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Igreja</th><th className="hidden md:table-cell">Associação / distrito</th><th>Administrador</th><th className="sm:pr-6"><span className="sr-only">Acções</span></th></tr></thead>
                <tbody>
                  {lista.map((i) => {
                    const a = admins.data?.get(i.id) ?? []
                    return (
                      <tr key={i.id}>
                        <td className="sm:pl-6">
                          <p className="font-medium">{i.nome}</p>
                          <p className="text-xs text-muted-foreground">{TIPO_IGREJA[(i.tipo ?? 'IGREJA_ORGANIZADA') as TipoIgreja]}{i.endereco ? ` · ${i.endereco}` : ''}</p>
                        </td>
                        <td className="hidden text-sm md:table-cell">
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
                            <Button size="sm" variant="ghost" className="alvo" onClick={() => abrir(i.id)} aria-label={`Abrir ${i.nome}`}>
                              <span className="hidden sm:inline">Abrir</span><ArrowRight className="size-4" />
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
        <p className="text-sm text-muted-foreground">
          O administrador de cada igreja entra com o seu e-mail ou telefone e define a senha com o código enviado por SMS
          ("Esqueci-me da senha"). Depois regista os outros utilizadores da igreja (secretário, tesoureiro, ...) em "Utilizadores e perfis".
        </p>
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
    if (comAdmin) { const e = validarAdmin(admin); if (e) return setErro(e) }
    try {
      const { igreja, erroAdmin } = await registar.mutateAsync({
        igreja: {
          nome: nome.trim(), tipo, entidadeId: Number(ent), distritoId: distritoId ? Number(distritoId) : undefined,
          maeIgrejaId: tipo !== 'IGREJA_ORGANIZADA' && maeId ? Number(maeId) : undefined,
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
                <Seleccao id="igr-ent" value={ent} onChange={(e) => { setEntidadeId(e.target.value); setDistritoId(''); setMaeId('') }}>
                  {campos.map((e) => <option key={e.id} value={e.id}>{e.nome}</option>)}
                </Seleccao>
              </div>
              <div className="grid gap-1.5">
                <label htmlFor="igr-dst" className="text-sm font-medium">Distrito</label>
                <Seleccao id="igr-dst" value={distritoId} onChange={(e) => setDistritoId(e.target.value)}>
                  <option value="">{dstDaEnt.length ? 'Sem distrito' : 'Não há distritos nesta Associação'}</option>
                  {dstDaEnt.map((d) => <option key={d.id} value={d.id}>{d.nome}</option>)}
                </Seleccao>
              </div>
              {tipo !== 'IGREJA_ORGANIZADA' && (
                <div className="grid gap-1.5">
                  <label htmlFor="igr-mae" className="text-sm font-medium">Igreja-mãe <span className="text-destructive-text">*</span></label>
                  <Seleccao id="igr-mae" value={maeId} onChange={(e) => setMaeId(e.target.value)}>
                    <option value="">Escolher…</option>
                    {maes.map((m) => <option key={m.id} value={m.id}>{m.nome}</option>)}
                  </Seleccao>
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
              <div className="grid gap-1.5 sm:col-span-2">
                <label htmlFor="igr-end" className="text-sm font-medium">Endereço</label>
                <Input id="igr-end" value={endereco} onChange={(e) => setEndereco(e.target.value)} maxLength={255} placeholder="ex.: Bairro de Nwamatibjana, Maputo" className="alvo" />
              </div>
            </div>
          </fieldset>
          <fieldset className="grid gap-3 rounded-lg border p-4">
            <legend className="px-1 text-xs font-semibold tracking-wider text-muted-foreground uppercase">2. O administrador da igreja</legend>
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
