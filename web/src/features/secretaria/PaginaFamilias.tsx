/**
 * Famílias (F-SEC-03): agrupar os membros que vivem na mesma casa — para visitas, envelopes de dízimo da família,
 * contagens e o relatório. Um membro está numa família de cada vez (secretaria.membro.mem_fam_id).
 */
import { useMemo, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { Home, Pencil, Plus, Search, UserMinus, UserPlus, Users } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Avatar, Cartao, Indicador, Pilula, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { ListaMembros } from '@/components/comum/EscolherMembro'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { useFamilias, useFamiliasMut, useFamiliasResumo, type Familia } from './api'

const normal = (s: string) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()

export default function PaginaFamilias() {
  const { pode } = useSessao()
  const familias = useFamilias()
  const resumo = useFamiliasResumo()
  const membros = useMembrosBasicos()
  const [params, setParams] = useSearchParams()
  const [pesquisa, setPesquisa] = useState('')
  const [editar, setEditar] = useState<Familia | 'nova' | null>(null)
  const selId = Number(params.get('familia')) || null
  const res = new Map((resumo.data ?? []).map((r) => [r.id, r]))
  const lista = useMemo(() => (familias.data ?? []).filter((f) => !f.endDate && (!pesquisa || normal(f.nome).includes(normal(pesquisa)))), [familias.data, pesquisa])
  const sel = (familias.data ?? []).find((f) => f.id === selId) ?? null
  const semFamilia = (membros.data ?? []).filter((m) => m.estado === 'ACTIVO' && !m.familiaId).length
  const escolher = (id: number | null) => setParams((p) => { const n = new URLSearchParams(p); if (id) n.set('familia', String(id)); else n.delete('familia'); return n })

  return (
    <>
      <TituloPagina icone={Home} titulo="Famílias" descricao="Os membros que vivem na mesma casa"
        accoes={pode('secretaria.familia.criar') && <Button className="alvo" onClick={() => setEditar('nova')}><Plus className="size-4" />Nova família</Button>} />
      {familias.isPending ? <Barra className="h-64 w-full" /> : familias.isError ? <EstadoErro erro={familias.error} aoTentar={() => familias.refetch()} /> : (
        <div className="grid gap-6">
          <div className="grid gap-3 sm:grid-cols-3">
            <Indicador rotulo="Famílias" valor={String((familias.data ?? []).filter((f) => !f.endDate).length)} icone={Home} />
            <Indicador rotulo="Membros activos em famílias" valor={String((resumo.data ?? []).reduce((s, r) => s + Number(r.membrosActivos), 0))} icone={Users} tom="success" />
            <Indicador rotulo="Membros activos sem família" valor={String(semFamilia)} icone={UserPlus} tom="warning" />
          </div>
          <div className="grid items-start gap-6 lg:grid-cols-12">
            <Cartao semMargem className="lg:col-span-5">
              <div className="border-b p-3">
                <div className="relative">
                  <Search aria-hidden className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
                  <Input value={pesquisa} onChange={(e) => setPesquisa(e.target.value)} placeholder="Pesquisar família…" aria-label="Pesquisar família" className="alvo pl-9" />
                </div>
              </div>
              {!lista.length ? (
                <EstadoVazio icone={Home} titulo={pesquisa ? 'Nenhuma família com esse nome' : 'Ainda não há famílias'}>
                  {pesquisa ? 'Experimente outro nome.' : 'Crie uma família (ex.: "Família Chirindza") e junte-lhe os membros da casa.'}
                </EstadoVazio>
              ) : (
                <ul className="max-h-[60dvh] divide-y overflow-y-auto">
                  {lista.map((f) => {
                    const r = res.get(f.id)
                    return (
                      <li key={f.id}>
                        <button type="button" onClick={() => escolher(f.id)} aria-current={f.id === selId}
                          className={cn('alvo flex w-full items-center justify-between gap-3 px-4 py-2.5 text-left hover:bg-muted/50', f.id === selId && 'bg-primary/5')}>
                          <span className="min-w-0">
                            <span className="block truncate font-medium">{f.nome}</span>
                            {f.morada && <span className="block truncate text-xs text-muted-foreground">{f.morada}</span>}
                          </span>
                          <Pilula variante="secondary">{r?.membrosActivos ?? 0} membro{Number(r?.membrosActivos) === 1 ? '' : 's'}</Pilula>
                        </button>
                      </li>
                    )
                  })}
                </ul>
              )}
            </Cartao>
            <div className="lg:col-span-7">
              {sel ? <DetalheFamilia f={sel} aoEditar={() => setEditar(sel)} /> : (
                <Cartao><EstadoVazio icone={Users} titulo="Escolha uma família">Veja e altere quem faz parte de cada família.</EstadoVazio></Cartao>
              )}
            </div>
          </div>
        </div>
      )}
      {editar && <DialogoFamilia f={editar === 'nova' ? null : editar} aoFechar={(id) => { setEditar(null); if (id) escolher(id) }} />}
    </>
  )
}

function DetalheFamilia({ f, aoEditar }: { f: Familia; aoEditar: () => void }) {
  const { pode } = useSessao()
  const membros = useMembrosBasicos()
  const { ligarMembro } = useFamiliasMut()
  const [juntar, setJuntar] = useState(false)
  const daFamilia = (membros.data ?? []).filter((m) => m.familiaId === f.id)
  const podeMudar = pode('secretaria.membro.alterar')
  const mudar = (membroId: number, familiaId: number | null, nome: string) => ligarMembro.mutate({ membroId, familiaId }, {
    onSuccess: () => toast.success(familiaId ? `${nome} juntou-se à ${f.nome}.` : `${nome} saiu da ${f.nome}.`),
    onError: (e) => toast.error(mensagemDe(e)),
  })
  return (
    <Cartao titulo={f.nome} descricao={f.morada || 'Sem morada'} icone={Home} semMargem
      accoes={(
        <div className="flex gap-2">
          {pode('secretaria.familia.alterar') && <Button size="sm" variant="ghost" className="alvo" onClick={aoEditar}><Pencil className="size-4" />Editar</Button>}
          {podeMudar && <Button size="sm" className="alvo" onClick={() => setJuntar(true)}><UserPlus className="size-4" />Juntar membro</Button>}
        </div>
      )}>
      {membros.isPending ? <Barra className="m-4 h-24" /> : !daFamilia.length ? (
        <EstadoVazio icone={Users} titulo="Família sem membros">Junte os membros que vivem nesta casa.</EstadoVazio>
      ) : (
        <ul className="divide-y">
          {daFamilia.map((m) => (
            <li key={m.id} className="flex items-center justify-between gap-3 px-4 py-2.5 sm:px-6">
              <Link to={`/membros/${m.id}`} className="flex min-w-0 items-center gap-3 hover:underline">
                <Avatar id={m.id} nome={m.nome} apelido={m.apelido} />
                <span className="min-w-0">
                  <span className="block truncate font-medium">{m.nome} {m.apelido}</span>
                  <span className="text-xs text-muted-foreground">{rotulos.estadoMembro[m.estado] ?? m.estado}</span>
                </span>
              </Link>
              {podeMudar && (
                <Button size="sm" variant="ghost" className="alvo text-muted-foreground" disabled={ligarMembro.isPending} onClick={() => mudar(m.id, null, `${m.nome} ${m.apelido}`)} aria-label={`Tirar ${m.nome} da família`}>
                  <UserMinus className="size-4" /><span className="hidden sm:inline">Tirar</span>
                </Button>
              )}
            </li>
          ))}
        </ul>
      )}
      {juntar && (
        <Dialog open onOpenChange={(v) => !v && setJuntar(false)}>
          <DialogContent className="sm:max-w-md">
            <DialogHeader>
              <DialogTitle>Juntar à {f.nome}</DialogTitle>
              <DialogDescription>Se o membro já estiver noutra família, passa para esta.</DialogDescription>
            </DialogHeader>
            <ListaMembros excluir={daFamilia.map((m) => m.id)} estados={['ACTIVO', 'INTERESSADO']}
              aoEscolher={(m) => { mudar(m.id, f.id, `${m.nome} ${m.apelido}`); setJuntar(false) }} />
          </DialogContent>
        </Dialog>
      )}
    </Cartao>
  )
}

function DialogoFamilia({ f, aoFechar }: { f: Familia | null; aoFechar: (id?: number) => void }) {
  const { criar, alterar } = useFamiliasMut()
  const [nome, setNome] = useState(f?.nome ?? 'Família ')
  const [morada, setMorada] = useState(f?.morada ?? '')
  const [erro, setErro] = useState<string | null>(null)
  const m = f ? alterar : criar
  const submeter = async () => {
    setErro(null)
    if (nome.trim().length < 3) return setErro('Escreva o nome da família.')
    try {
      if (f) { await alterar.mutateAsync({ id: f.id, nome: nome.trim(), morada: morada.trim() || null }); toast.success('Família actualizada.'); aoFechar() }
      else { const n = await criar.mutateAsync({ nome: nome.trim(), morada: morada.trim() || undefined }); toast.success('Família criada: junte-lhe os membros.'); aoFechar(n.id) }
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{f ? 'Editar família' : 'Nova família'}</DialogTitle>
          <DialogDescription>O nome com que a igreja conhece a casa e onde vive.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5">
            <label htmlFor="fam-nome" className="text-sm font-medium">Nome <span className="text-destructive-text">*</span></label>
            <Input id="fam-nome" value={nome} onChange={(e) => setNome(e.target.value)} className="alvo" maxLength={150} autoFocus placeholder="ex.: Família Chirindza" />
          </div>
          <div className="grid gap-1.5">
            <label htmlFor="fam-morada" className="text-sm font-medium">Morada</label>
            <Input id="fam-morada" value={morada} onChange={(e) => setMorada(e.target.value)} className="alvo" maxLength={255} placeholder="ex.: Bairro 3, quarteirão 12, casa 45" />
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={() => aoFechar()}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={m.isPending} onClick={submeter}>{m.isPending ? t.comum.aGravar : f ? 'Gravar' : 'Criar família'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
