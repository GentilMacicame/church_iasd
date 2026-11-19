/**
 * Famílias (F-SEC-03): agrupar os membros que vivem na mesma casa — para visitas, envelopes de dízimo da família,
 * contagens e o relatório. Um membro está numa família de cada vez (secretaria.membro.mem_fam_id).
 */
import { useMemo, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { ChevronRight, Home, Pencil, Plus, Search, UserMinus, UserPlus, Users } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Sheet, SheetContent, SheetDescription, SheetTitle } from '@/components/ui/sheet'
import { Avatar, Cartao, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Seleccao } from '@/components/comum/Seleccao'
import { idade, qtd } from '@/lib/formatos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { ListaMembros } from '@/components/comum/EscolherMembro'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
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
            <Indicador rotulo="Membros activos nas famílias" valor={String((resumo.data ?? []).reduce((s, r) => s + Number(r.membrosActivos), 0))} icone={Users} tom="success" />
            <Indicador rotulo="Membros activos sem família" valor={String(semFamilia)} icone={UserPlus} tom="warning" destaque={semFamilia > 0} />
          </div>
          <Cartao semMargem>
            <div className="flex flex-wrap items-center justify-between gap-3 border-b px-4 py-3 sm:px-6">
              <div className="relative w-full sm:w-80">
                <Search aria-hidden className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
                <Input value={pesquisa} onChange={(e) => setPesquisa(e.target.value)} placeholder="Pesquisar família…" aria-label="Pesquisar família" className="alvo pl-9" />
              </div>
              <span className="text-sm text-muted-foreground">{qtd(lista.length, 'família(s)')}</span>
            </div>
            {!lista.length ? (
              <EstadoVazio icone={Home} titulo={pesquisa ? 'Nenhuma família com esse nome' : 'Ainda não há famílias'}>
                {pesquisa ? 'Experimente outro nome.' : 'Crie uma família e junte-lhe os membros da casa.'}
              </EstadoVazio>
            ) : (
              <Tabela porPagina={15} procurar={false}>
                <thead><tr><th className="sm:pl-6">Família</th><th className="hidden md:table-cell">Chefe</th><th>Membros</th><th className="w-10 sm:pr-6"><span className="sr-only">Abrir</span></th></tr></thead>
                <tbody>
                  {lista.map((f) => {
                    const da = (membros.data ?? []).filter((m) => m.familiaId === f.id)
                    const chefe = da.find((m) => m.parentesco === 'CHEFE')
                    return (
                      <tr key={f.id} onClick={() => escolher(f.id)} className="cursor-pointer">
                        <td className="sm:pl-6">
                          <span className="block font-medium">{f.nome}</span>
                          {f.morada && <span className="block text-xs text-muted-foreground">{f.morada}</span>}
                        </td>
                        <td className="hidden md:table-cell">{chefe ? `${chefe.nome} ${chefe.apelido}` : <span className="text-muted-foreground">—</span>}</td>
                        <td>
                          <span className="flex items-center gap-2">
                            <span className="flex -space-x-2">
                              {da.slice(0, 4).map((m) => <Avatar key={m.id} id={m.id} nome={m.nome} apelido={m.apelido} tamanho={28} className="ring-2 ring-card" />)}
                            </span>
                            <span className="text-sm text-muted-foreground">{da.length}</span>
                          </span>
                        </td>
                        <td className="text-right text-muted-foreground sm:pr-6"><ChevronRight className="ml-auto size-4" /></td>
                      </tr>
                    )
                  })}
                </tbody>
              </Tabela>
            )}
          </Cartao>
        </div>
      )}
      <Sheet open={!!sel} onOpenChange={(v) => !v && escolher(null)}>
        <SheetContent className="w-full overflow-y-auto p-0 sm:max-w-2xl">
          <SheetTitle className="sr-only">{sel?.nome ?? 'Família'}</SheetTitle>
          <SheetDescription className="sr-only">Membros da família</SheetDescription>
          {sel && <div className="p-5 sm:p-6"><DetalheFamilia f={sel} aoEditar={() => setEditar(sel)} /></div>}
        </SheetContent>
      </Sheet>
      {editar && <DialogoFamilia f={editar === 'nova' ? null : editar} aoFechar={(id) => { setEditar(null); if (id) escolher(id) }} />}
    </>
  )
}

const ORDEM_PARENTESCO = ['CHEFE', 'CONJUGE', 'FILHO', 'PAI_MAE', 'IRMAO', 'NETO', 'OUTRO']

/** A família: os membros em tabela (parentesco, idade, sexo, estado civil, estado) e as relações que o sistema conhece. */
function DetalheFamilia({ f, aoEditar }: { f: Familia; aoEditar: () => void }) {
  const { pode } = useSessao()
  const membros = useMembrosBasicos()
  const { ligarMembro, parentesco } = useFamiliasMut()
  const [juntar, setJuntar] = useState(false)
  const todos = membros.data ?? []
  const daFamilia = todos.filter((m) => m.familiaId === f.id).sort((a, b) =>
    (ORDEM_PARENTESCO.indexOf(a.parentesco ?? '') + 1 || 99) - (ORDEM_PARENTESCO.indexOf(b.parentesco ?? '') + 1 || 99)
    || (a.dataNascimento ?? '9').localeCompare(b.dataNascimento ?? '9'))
  const podeMudar = pode('secretaria.membro.alterar')
  const mudar = (membroId: number, familiaId: number | null, nome: string) => ligarMembro.mutate({ membroId, familiaId }, {
    onSuccess: () => toast.success(familiaId ? `${nome} juntou-se à ${f.nome}.` : `${nome} saiu da ${f.nome}.`),
    onError: (e) => toast.error(mensagemDe(e)),
  })
  const mudarParentesco = (membroId: number, valor: string) => parentesco.mutate({ membroId, parentesco: valor || null }, {
    onError: (e) => toast.error(mensagemDe(e)),
  })
  const nome = (id: number) => { const m = todos.find((x) => x.id === id); return m ? `${m.nome} ${m.apelido}` : 'Membro' }
  // relações que o sistema conhece: casais (cônjuges ligados na ficha) e menores
  const casais = daFamilia.filter((m) => m.conjugeMembroId && (m.id < m.conjugeMembroId || !daFamilia.some((x) => x.id === m.conjugeMembroId)))
  const menores = daFamilia.filter((m) => { const a = idade(m.dataNascimento); return a != null && a < 18 })
  return (
    <div className="grid gap-6">
      <header className="flex flex-wrap items-start justify-between gap-3 pr-8">
        <div className="flex min-w-0 items-start gap-3">
          <span className="flex size-11 flex-none items-center justify-center rounded-xl bg-accent text-accent-foreground"><Home className="size-5" /></span>
          <div className="min-w-0">
            <h2 className="text-lg font-semibold tracking-tight">{f.nome}</h2>
            <p className="text-sm text-muted-foreground">{[f.morada || 'Sem morada', `${daFamilia.length} ${daFamilia.length === 1 ? 'membro' : 'membros'}`].join(' · ')}</p>
          </div>
        </div>
        <div className="flex gap-2">
          {pode('secretaria.familia.alterar') && <Button size="sm" variant="outline" className="alvo" onClick={aoEditar}><Pencil className="size-4" />Editar</Button>}
          {podeMudar && <Button size="sm" className="alvo" onClick={() => setJuntar(true)}><UserPlus className="size-4" />Juntar membro</Button>}
        </div>
      </header>
      {membros.isPending ? <Barra className="m-4 h-24" /> : !daFamilia.length ? (
        <EstadoVazio icone={Users} titulo="Família sem membros">Junte os membros que vivem nesta casa.</EstadoVazio>
      ) : (
        <>
          <ul className="grid gap-2">
            {daFamilia.map((m) => (
              <li key={m.id} className="flex flex-wrap items-center gap-3 rounded-xl border bg-card px-3 py-3 sm:flex-nowrap">
                <Link to={`/membros/${m.id}`} className="flex min-w-0 flex-1 items-center gap-3 hover:text-primary">
                  <Avatar id={m.id} nome={m.nome} apelido={m.apelido} tamanho={40} />
                  <span className="min-w-0">
                    <span className="flex items-center gap-2">
                      <span className="truncate font-medium">{m.nome} {m.apelido}</span>
                      {m.parentesco === 'CHEFE' && <Pilula variante="info">Chefe</Pilula>}
                    </span>
                    <span className="block truncate text-xs text-muted-foreground">
                      {[idade(m.dataNascimento) != null && `${idade(m.dataNascimento)} anos`, m.estadoCivil && rotulos.estadoCivil[m.estadoCivil], rotulos.estadoMembro[m.estado] ?? m.estado].filter(Boolean).join(' · ')}
                    </span>
                  </span>
                </Link>
                {podeMudar ? (
                  <Seleccao aria-label={`Parentesco de ${m.nome}`} value={m.parentesco ?? ''} onChange={(e) => mudarParentesco(m.id, e.target.value)} className="h-9 w-36">
                    <option value="">Parentesco…</option>
                    {ORDEM_PARENTESCO.map((k) => <option key={k} value={k}>{rotulos.parentesco[k]}</option>)}
                  </Seleccao>
                ) : <span className="text-sm text-muted-foreground">{m.parentesco ? rotulos.parentesco[m.parentesco] : '—'}</span>}
                {podeMudar && (
                  <Button size="icon" variant="ghost" className="alvo size-9 text-muted-foreground hover:text-destructive-text" disabled={ligarMembro.isPending}
                    onClick={() => mudar(m.id, null, `${m.nome} ${m.apelido}`)} aria-label={`Tirar ${m.nome} da família`} title="Tirar da família">
                    <UserMinus className="size-4" />
                  </Button>
                )}
              </li>
            ))}
          </ul>
          {(casais.length > 0 || menores.length > 0) && (
            <div className="grid gap-4 rounded-xl border bg-muted/30 p-4 text-sm sm:grid-cols-2">
              {casais.length > 0 && (
                <div>
                  <p className="mb-1 text-xs font-semibold tracking-wider text-muted-foreground uppercase">Casais</p>
                  <ul className="grid gap-1">
                    {casais.map((m) => <li key={m.id}>{m.nome} {m.apelido} <span className="text-muted-foreground">e</span> {nome(m.conjugeMembroId!)}</li>)}
                  </ul>
                </div>
              )}
              {menores.length > 0 && (
                <div>
                  <p className="mb-1 text-xs font-semibold tracking-wider text-muted-foreground uppercase">Menores ({menores.length})</p>
                  <ul className="grid gap-1">
                    {menores.map((m) => <li key={m.id}>{m.nome} {m.apelido} <span className="text-muted-foreground">· {idade(m.dataNascimento)} anos</span></li>)}
                  </ul>
                </div>
              )}
            </div>
          )}
        </>
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
    </div>
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
          <div className="campo-flutuante grid gap-1.5">
            <label htmlFor="fam-nome" className="text-sm font-medium">Nome <span className="text-destructive-text">*</span></label>
            <Input id="fam-nome" value={nome} onChange={(e) => setNome(e.target.value)} className="alvo" maxLength={150} autoFocus placeholder="ex.: Família Chirindza" />
          </div>
          <div className="campo-flutuante grid gap-1.5">
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
