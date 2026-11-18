/**
 * Comunicados e anúncios (V37) · "O que a igreja, o distrito e a Missão querem que eu saiba?"
 * Mural: os comunicados publicados, em vigor, que se dirigem a mim (a base de dados decide). Gerir: rascunhos,
 * publicados e arquivados de quem publica (a igreja, o pastor do distrito, a Associação), com publicar e arquivar.
 */
import { useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Archive, Megaphone, MoreHorizontal, Pencil, Plus, Send, Trash2 } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { data, dataPorExtenso, hojeIso, hora, isoMaputo, partesMaputo } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useDistritoDaIgreja } from '@/features/actividades/api'
import {
  ROTULO_ESTADO, ROTULO_PUBLICO, emVigor, emissorDe, gravarDestinos, useComunicados, useComunicadosMut, useDestinos, useEntidadeDaIgreja,
  useIgrejasDaEntidade, type Comunicado, type Emissor,
} from './api'

const PERFIS_ASSOCIACAO = ['ADMIN_ASSOCIACAO', 'SECRETARIO_ASSOCIACAO']

/** Que emissores o utilizador pode usar e o nome de cada um (a base de dados confirma ao gravar). */
function useEmissores() {
  const { pode, usuario } = useSessao()
  const igreja = useIgreja()
  const distrito = useDistritoDaIgreja()
  const entidade = useEntidadeDaIgreja()
  const perfis = igreja.perfis ?? []
  const podeIgreja = pode('nucleo.comunicado.criar')
  const podeDistrito = !!distrito.data && (distrito.data.pastorUsuarioId === usuario?.id || pode('organizacao.distrito.alterar'))
  const podeAssociacao = perfis.some((p) => PERFIS_ASSOCIACAO.includes(p))
  const disponiveis: Emissor[] = [...(podeIgreja ? ['IGREJA' as const] : []), ...(podeDistrito ? ['DISTRITO' as const] : []), ...(podeAssociacao ? ['ASSOCIACAO' as const] : [])]
  const nome = (c: Comunicado) => {
    const e = emissorDe(c)
    if (e === 'IGREJA') return c.igrejaId === igreja.id ? igreja.nome : 'Outra igreja'
    if (e === 'DISTRITO') return distrito.data && distrito.data.id === c.distritoId ? distrito.data.nome : 'Distrito pastoral'
    return entidade.data && entidade.data.id === c.entidadeId ? entidade.data.nome : 'Associação/Missão'
  }
  /** Pode editar este comunicado (mostrar as acções). */
  const editavel = (c: Comunicado) => {
    const e = emissorDe(c)
    return (e === 'IGREJA' && podeIgreja && c.igrejaId === igreja.id) || (e === 'DISTRITO' && podeDistrito && c.distritoId === distrito.data?.id)
      || (e === 'ASSOCIACAO' && podeAssociacao && c.entidadeId === entidade.data?.id)
  }
  return { disponiveis, nome, editavel, distrito: distrito.data, entidade: entidade.data }
}

export default function PaginaComunicados() {
  const q = useComunicados()
  const emissores = useEmissores()
  const [params, setParams] = useSearchParams()
  const aba = params.get('ver') === 'gerir' ? 'gerir' : 'mural'
  const [editar, setEditar] = useState<Comunicado | 'novo' | null>(null)
  const lista = useMemo(() => q.data ?? [], [q.data])
  const mural = lista.filter((c) => emVigor(c))
  const geriveis = lista.filter(emissores.editavel)
  const podePublicar = emissores.disponiveis.length > 0

  return (
    <>
      <TituloPagina icone={Megaphone} titulo="Comunicados"
        descricao="Da igreja, do distrito e da Missão"
        accoes={podePublicar && <Button className="alvo" onClick={() => setEditar('novo')}><Plus className="size-4" />Novo comunicado</Button>} />

      {q.isPending ? <div className="grid gap-3"><Barra className="h-24 w-full" /><Barra className="h-24 w-full" /></div>
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
        : (
          <Tabs value={aba} onValueChange={(v) => setParams((p) => { const n = new URLSearchParams(p); if (v === 'gerir') n.set('ver', v); else n.delete('ver'); return n }, { replace: true })}>
            {podePublicar && (
              <TabsList className="mb-4">
                <TabsTrigger value="mural" className="alvo">Mural <span className="ml-1 tabular-nums text-muted-foreground">({mural.length})</span></TabsTrigger>
                <TabsTrigger value="gerir" className="alvo">Gerir <span className="ml-1 tabular-nums text-muted-foreground">({geriveis.length})</span></TabsTrigger>
              </TabsList>
            )}
            <TabsContent value="mural" className="mt-0">
              {!mural.length ? (
                <section className="rounded-xl border bg-card shadow-card">
                  <EstadoVazio icone={Megaphone} titulo="Sem comunicados em vigor">Quando a igreja, o distrito ou a Missão publicarem, aparecem aqui.</EstadoVazio>
                </section>
              ) : (
                <div className="grid gap-4">
                  {mural.map((c) => (
                    <article key={c.id} className="rounded-xl border bg-card p-5 shadow-card sm:p-6">
                      <header className="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground">
                        <span className="font-medium text-foreground">{emissores.nome(c)}</span>
                        <span>{dataPorExtenso(c.publicarEm)}</span>
                        {c.publico === 'LIDERANCA' && <Pilula variante="info">Só a liderança</Pilula>}
                        {c.validoAte && <span>até {data(c.validoAte)}</span>}
                      </header>
                      <h2 className="mt-2 text-lg font-semibold tracking-tight">{c.titulo}</h2>
                      <p className="mt-2 text-sm leading-relaxed whitespace-pre-line">{c.conteudo}</p>
                    </article>
                  ))}
                </div>
              )}
            </TabsContent>
            {podePublicar && (
              <TabsContent value="gerir" className="mt-0">
                <TabelaGerir lista={geriveis} nome={emissores.nome} aoEditar={setEditar} />
              </TabsContent>
            )}
          </Tabs>
        )}

      {editar && <DialogoComunicado comunicado={editar === 'novo' ? undefined : editar} aoFechar={() => setEditar(null)} />}
    </>
  )
}

function TabelaGerir({ lista, nome, aoEditar }: { lista: Comunicado[]; nome: (c: Comunicado) => string; aoEditar: (c: Comunicado) => void }) {
  const { alterar, terminar } = useComunicadosMut()
  const [apagar, setApagar] = useState<Comunicado | null>(null)
  const mudar = (c: Comunicado, estado: 'PUBLICADO' | 'ARQUIVADO') => alterar.mutate({ id: c.id, estado }, {
    onSuccess: () => toast.success(estado === 'PUBLICADO' ? 'Comunicado publicado.' : 'Comunicado arquivado.'),
    onError: (e) => toast.error(mensagemDe(e)),
  })
  if (!lista.length) {
    return <section className="rounded-xl border bg-card shadow-card"><EstadoVazio icone={Megaphone} titulo="Nada para gerir">Os comunicados que publicar aparecem aqui.</EstadoVazio></section>
  }
  const agora = Date.now()
  return (
    <section className="rounded-xl border bg-card shadow-card">
      <Tabela>
        <thead>
          <tr>
            <th className="sm:pl-6">Comunicado</th>
            <th className="hidden md:table-cell">Quem publica</th>
            <th className="hidden sm:table-cell">Público</th>
            <th className="hidden sm:table-cell">Publicar em</th>
            <th className="hidden lg:table-cell">Válido até</th>
            <th>Estado</th>
            <th className="w-12 sm:pr-6"><span className="sr-only">Acções</span></th>
          </tr>
        </thead>
        <tbody>
          {lista.map((c) => {
            const expirou = c.estado === 'PUBLICADO' && !!c.validoAte && Date.parse(c.validoAte) < agora
            const agendado = c.estado === 'PUBLICADO' && Date.parse(c.publicarEm) > agora
            return (
              <tr key={c.id} className={cn(c.estado === 'ARQUIVADO' && 'text-muted-foreground')}>
                <td className="sm:pl-6"><span className="font-medium">{c.titulo}</span><span className="block text-xs text-muted-foreground md:hidden">{nome(c)}</span></td>
                <td className="hidden md:table-cell">{nome(c)}</td>
                <td className="hidden sm:table-cell">{ROTULO_PUBLICO[(c.publico ?? 'MEMBROS') as keyof typeof ROTULO_PUBLICO]}</td>
                <td className="hidden tabular-nums sm:table-cell">{data(c.publicarEm)} {hora(c.publicarEm)}</td>
                <td className="hidden tabular-nums lg:table-cell">{c.validoAte ? data(c.validoAte) : '—'}</td>
                <td>
                  <Pilula variante={c.estado === 'PUBLICADO' ? (expirou ? 'secondary' : agendado ? 'info' : 'success') : c.estado === 'RASCUNHO' ? 'warning' : 'secondary'}>
                    {expirou ? 'Expirado' : agendado ? 'Agendado' : ROTULO_ESTADO[c.estado ?? 'RASCUNHO']}
                  </Pilula>
                </td>
                <td className="sm:pr-6">
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" size="icon" className="alvo size-9 text-muted-foreground" aria-label={`Acções de ${c.titulo}`}><MoreHorizontal className="size-4" /></Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem onSelect={() => aoEditar(c)}><Pencil className="size-4" />Editar</DropdownMenuItem>
                      {c.estado !== 'PUBLICADO' && <DropdownMenuItem onSelect={() => mudar(c, 'PUBLICADO')}><Send className="size-4" />Publicar</DropdownMenuItem>}
                      {c.estado === 'PUBLICADO' && <DropdownMenuItem onSelect={() => mudar(c, 'ARQUIVADO')}><Archive className="size-4" />Arquivar</DropdownMenuItem>}
                      <DropdownMenuSeparator />
                      <DropdownMenuItem className="text-destructive-text" onSelect={() => setApagar(c)}><Trash2 className="size-4" />Retirar</DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </td>
              </tr>
            )
          })}
        </tbody>
      </Tabela>
      <DialogoConfirmar aberto={!!apagar} aoMudar={(v) => !v && setApagar(null)} titulo={`Retirar «${apagar?.titulo ?? ''}»?`}
        texto="Deixa de aparecer em todo o lado. Fica no histórico (nada se apaga)." accao="Retirar" perigo aCorrer={terminar.isPending}
        aoConfirmar={() => apagar && terminar.mutate(apagar.id, { onSuccess: () => { toast.success('Comunicado retirado.'); setApagar(null) }, onError: (e) => { toast.error(mensagemDe(e)); setApagar(null) } })} />
    </section>
  )
}

const ROTULO_EMISSOR: Record<Emissor, string> = { IGREJA: 'Esta igreja', DISTRITO: 'Distrito pastoral', ASSOCIACAO: 'Associação/Missão' }

/** Escrever ou editar um comunicado: quem publica, a quem, para que público, quando, até quando. */
function DialogoComunicado({ comunicado, aoFechar }: { comunicado?: Comunicado; aoFechar: () => void }) {
  const igreja = useIgreja()
  const emissores = useEmissores()
  const { criar, alterar } = useComunicadosMut()
  const destinos = useDestinos(comunicado?.id ?? null)
  const [emissor, setEmissor] = useState<Emissor>(comunicado ? emissorDe(comunicado) : emissores.disponiveis[0] ?? 'IGREJA')
  const [titulo, setTitulo] = useState(comunicado?.titulo ?? '')
  const [conteudo, setConteudo] = useState(comunicado?.conteudo ?? '')
  const [publico, setPublico] = useState<'MEMBROS' | 'LIDERANCA'>((comunicado?.publico as 'MEMBROS' | 'LIDERANCA') ?? 'MEMBROS')
  const ini = partesMaputo(comunicado?.publicarEm)
  const [dataPub, setDataPub] = useState(ini.data || hojeIso())
  const [horaPub, setHoraPub] = useState(ini.hora || new Date().toTimeString().slice(0, 5))
  const [validoAte, setValidoAte] = useState(partesMaputo(comunicado?.validoAte).data)
  const [todas, setTodas] = useState(true)
  const [escolhidas, setEscolhidas] = useState<number[] | null>(null)
  const [erro, setErro] = useState<string | null>(null)
  const igrejas = useIgrejasDaEntidade(emissor === 'IGREJA' ? null : emissores.entidade?.id)
  const candidatas = (igrejas.data ?? []).filter((i) => emissor === 'ASSOCIACAO' || i.distritoId === emissores.distrito?.id)
  // ao editar: as igrejas já escolhidas (sem linhas = todas)
  const actuais = (destinos.data ?? []).filter((d) => !d.endDate)
  const seleccao = escolhidas ?? actuais.map((d) => d.igrejaId)
  const todasEfectivo = escolhidas == null ? (comunicado ? actuais.length === 0 : todas) : todas

  const gravar = async (estado: 'RASCUNHO' | 'PUBLICADO') => {
    setErro(null)
    if (!titulo.trim()) return setErro('Escreva o título.')
    if (!conteudo.trim()) return setErro('Escreva o comunicado.')
    if (emissor !== 'IGREJA' && !todasEfectivo && !seleccao.length) return setErro('Escolha pelo menos uma igreja (ou "Todas").')
    const publicarEm = isoMaputo(dataPub, horaPub)
    const corpo = {
      titulo: titulo.trim(), conteudo: conteudo.trim(), publico, publicarEm, estado,
      validoAte: validoAte ? isoMaputo(validoAte, '23:59') : null,
      igrejaId: emissor === 'IGREJA' ? igreja.id : null,
      distritoId: emissor === 'DISTRITO' ? emissores.distrito?.id ?? null : null,
      entidadeId: emissor === 'ASSOCIACAO' ? emissores.entidade?.id ?? null : null,
    }
    try {
      let id = comunicado?.id
      if (comunicado) await alterar.mutateAsync({ id: comunicado.id, ...corpo })
      else id = (await criar.mutateAsync(corpo)).id
      if (emissor !== 'IGREJA' && id) await gravarDestinos(id, actuais, todasEfectivo ? [] : seleccao)
      toast.success(estado === 'PUBLICADO' ? 'Comunicado publicado.' : 'Rascunho guardado.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  const aGravar = criar.isPending || alterar.isPending

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="max-h-[92vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{comunicado ? 'Editar comunicado' : 'Novo comunicado'}</DialogTitle>
          <DialogDescription>Fica em rascunho até publicar.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          {emissores.disponiveis.length > 1 && (
            <fieldset className="grid gap-1.5">
              <legend className="mb-1.5 text-sm font-medium">Quem publica</legend>
              <div role="radiogroup" className="grid gap-2 sm:grid-cols-3">
                {emissores.disponiveis.map((e) => (
                  <button key={e} type="button" role="radio" aria-checked={emissor === e} disabled={!!comunicado}
                    onClick={() => { setEmissor(e); setEscolhidas(null); setTodas(true) }}
                    className={cn('alvo rounded-lg border px-3 py-2 text-left text-sm font-medium disabled:cursor-not-allowed disabled:opacity-70',
                      emissor === e ? 'border-primary bg-primary/10 text-primary' : 'text-muted-foreground hover:border-primary/40')}>
                    {ROTULO_EMISSOR[e]}
                    <span className="block text-xs font-normal">{e === 'IGREJA' ? igreja.nome : e === 'DISTRITO' ? emissores.distrito?.nome : emissores.entidade?.nome}</span>
                  </button>
                ))}
              </div>
            </fieldset>
          )}
          {emissor !== 'IGREJA' && (
            <fieldset className="grid gap-2">
              <legend className="mb-1 text-sm font-medium">Para que igrejas</legend>
              <label className="alvo flex items-center gap-2 text-sm">
                <input type="checkbox" checked={todasEfectivo} onChange={(ev) => { setTodas(ev.target.checked); setEscolhidas(ev.target.checked ? [] : seleccao) }} className="size-4 accent-[var(--primary)]" />
                Todas as igrejas {emissor === 'DISTRITO' ? 'do distrito' : 'da Associação/Missão'}
              </label>
              {!todasEfectivo && (
                <div className="grid max-h-48 gap-1 overflow-y-auto rounded-lg border p-2 sm:grid-cols-2">
                  {igrejas.isPending ? <Barra className="h-8 w-full" /> : candidatas.map((i) => (
                    <label key={i.id} className="alvo flex items-center gap-2 rounded px-1 text-sm hover:bg-muted/50">
                      <input type="checkbox" checked={seleccao.includes(i.id)} className="size-4 accent-[var(--primary)]"
                        onChange={(ev) => setEscolhidas(ev.target.checked ? [...seleccao, i.id] : seleccao.filter((x) => x !== i.id))} />
                      {i.nome}
                    </label>
                  ))}
                </div>
              )}
            </fieldset>
          )}
          <div className="grid gap-1.5">
            <label htmlFor="cmc-titulo" className="text-sm font-medium">Título <span className="text-destructive-text">*</span></label>
            <Input id="cmc-titulo" value={titulo} onChange={(e) => setTitulo(e.target.value)} maxLength={200} className="alvo" autoFocus placeholder="ex.: Santa Ceia no próximo sábado" />
          </div>
          <div className="grid gap-1.5">
            <label htmlFor="cmc-conteudo" className="text-sm font-medium">Comunicado <span className="text-destructive-text">*</span></label>
            <Textarea id="cmc-conteudo" value={conteudo} onChange={(e) => setConteudo(e.target.value)} rows={6} />
          </div>
          <fieldset className="grid gap-1.5">
            <legend className="mb-1.5 text-sm font-medium">Público</legend>
            <div role="radiogroup" className="grid grid-cols-2 gap-2">
              {(['MEMBROS', 'LIDERANCA'] as const).map((p) => (
                <button key={p} type="button" role="radio" aria-checked={publico === p} onClick={() => setPublico(p)}
                  className={cn('alvo rounded-lg border px-3 py-2 text-left text-sm font-medium', publico === p ? 'border-primary bg-primary/10 text-primary' : 'text-muted-foreground hover:border-primary/40')}>
                  {ROTULO_PUBLICO[p]}
                </button>
              ))}
            </div>
          </fieldset>
          <div className="grid gap-3 sm:grid-cols-[1fr_7rem_1fr]">
            <div className="grid gap-1.5"><label htmlFor="cmc-data" className="text-sm font-medium">Publicar em</label><CampoData id="cmc-data" value={dataPub} onChange={setDataPub} className="alvo" /></div>
            <div className="grid gap-1.5"><label htmlFor="cmc-hora" className="text-sm font-medium">Hora</label><Input id="cmc-hora" type="time" value={horaPub} onChange={(e) => setHoraPub(e.target.value)} className="alvo num" /></div>
            <div className="grid gap-1.5"><label htmlFor="cmc-ate" className="text-sm font-medium">Válido até</label><CampoData id="cmc-ate" value={validoAte} onChange={setValidoAte} className="alvo" /></div>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button variant="outline" className="alvo" disabled={aGravar} onClick={() => gravar('RASCUNHO')}>Guardar rascunho</Button>
          <Button className="alvo" disabled={aGravar} onClick={() => gravar('PUBLICADO')}><Send className="size-4" />{aGravar ? t.comum.aGravar : 'Publicar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
