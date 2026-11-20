/**
 * Fluxos de aprovação (V54) · "Quem aprecia, quem confere e quem aprova cada coisa nesta igreja?"
 * Para cada natureza de processo, os fluxos que se aplicam (por valor) e as etapas pela ordem: quem decide (um perfil,
 * quem tem uma permissão, ou um órgão que vota em reunião) e o que faz. Todos vêem; configura quem tem a permissão
 * (administrador e pastor). A igreja usa os modelos da Associação até criar o seu próprio fluxo para esse processo.
 */
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft, Building2, Copy, Pencil, Plus, Route, Trash2, Undo2 } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Pilula, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { Seleccao } from '@/components/comum/Seleccao'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { dinheiro } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { usePerfis, usePermissoes } from '@/features/acessos/api'
import { ACCOES, ORGAOS, PROCESSOS, RESPONSAVEIS, useEtapasFluxos, useFluxos, useFluxosMut, type AccaoEtapa, type Etapa, type Fluxo, type Processo, type ResponsavelEtapa, type TipoReuniao } from './api'

/** Permissões que fazem sentido como responsável de uma etapa. */
const PERMISSOES_ETAPA: Record<string, string> = {
  'tesouraria.despesa.aprovar': 'Quem aprova despesas (pastor, ancião)',
  'tesouraria.transacao.aprovar': 'Quem aprova saídas (pastor, ancião)',
  'tesouraria.orcamento.aprovar': 'Quem aprova o orçamento',
  'tesouraria.contagem_numerario.alterar': 'Quem altera contagens (tesouraria)',
  'secretaria.movimento_membro.criar': 'Quem regista no livro de membros',
}

export default function PaginaFluxos() {
  const { pode } = useSessao()
  const igreja = useIgreja()
  const fluxos = useFluxos()
  const etapas = useEtapasFluxos()
  const perfis = usePerfis()
  const permissoes = usePermissoes()
  const podeConfigurar = pode('nucleo.fluxo_aprovacao.criar')
  const nomePerfil = (id?: number | null) => {
    const p = perfis.data?.find((x) => x.id === id)
    return p ? rotulos.perfil[p.codigo ?? ''] ?? p.nome : '—'
  }
  const nomePermissao = (id?: number | null) => {
    const p = permissoes.data?.find((x) => x.id === id)
    return p ? PERMISSOES_ETAPA[p.codigo] ?? p.descricao ?? p.codigo : '—'
  }
  const quem = (e: Etapa) => e.responsavel === 'PERFIL' ? nomePerfil(e.perfilId) : e.responsavel === 'PERMISSAO' ? nomePermissao(e.permissaoId)
    : e.orgao ? ORGAOS[e.orgao as TipoReuniao] : '—'

  const carregando = fluxos.isPending || etapas.isPending
  return (
    <>
      <TituloPagina icone={Route} titulo="Fluxos de aprovação" descricao="Quem aprecia, confere e aprova cada processo, por ordem e por valor"
        antes={<Button asChild variant="ghost" size="sm" className="alvo -ml-2 w-fit"><Link to="/aprovacoes"><ArrowLeft className="size-4" />Aprovações</Link></Button>} />
      {carregando ? <div className="grid gap-4">{[0, 1, 2].map((i) => <Barra key={i} className="h-32 w-full rounded-xl" />)}</div>
        : fluxos.isError ? <EstadoErro erro={fluxos.error} aoTentar={() => fluxos.refetch()} />
        : (
          <div className="grid gap-6">
            {(Object.keys(PROCESSOS) as Processo[]).map((proc) => (
              <BlocoProcesso key={proc} processo={proc} igrejaId={igreja.id} podeConfigurar={podeConfigurar}
                fluxos={fluxos.data ?? []} etapas={etapas.data ?? []} quem={quem} />
            ))}
          </div>
        )}
    </>
  )
}

function BlocoProcesso({ processo, igrejaId, podeConfigurar, fluxos, etapas, quem }: {
  processo: Processo; igrejaId: number; podeConfigurar: boolean; fluxos: Fluxo[]; etapas: Etapa[]; quem: (e: Etapa) => string
}) {
  const mut = useFluxosMut()
  const [voltar, setVoltar] = useState(false)
  const [novoFluxo, setNovoFluxo] = useState(false)
  const daIgreja = fluxos.filter((f) => f.processo === processo && f.igrejaId === igrejaId)
  const modelos = fluxos.filter((f) => f.processo === processo && f.igrejaId == null)
  const aplicam = (daIgreja.length ? daIgreja : modelos).sort((a, b) => Number(a.valorMinimo) - Number(b.valorMinimo))
  const proprios = daIgreja.length > 0
  const [copiando, setCopiando] = useState(false)

  /** Copia os modelos da Associação para a igreja (fluxos e etapas), para os poder mudar. */
  const copiar = async () => {
    setCopiando(true)
    try {
      for (const m of modelos) {
        const f = await mut.criarFluxo.mutateAsync({ igrejaId, processo, nome: m.nome, valorMinimo: m.valorMinimo, descricao: m.descricao ?? undefined } as never)
        for (const e of etapas.filter((x) => x.fluxoAprovacaoId === m.id)) {
          await mut.criarEtapa.mutateAsync({
            fluxoAprovacaoId: f.id, ordem: e.ordem, nome: e.nome, accao: e.accao, responsavel: e.responsavel,
            perfilId: e.perfilId ?? undefined, permissaoId: e.permissaoId ?? undefined, orgao: e.orgao ?? undefined, outraPessoa: e.outraPessoa,
          } as never)
        }
      }
      toast.success('Fluxo da igreja criado a partir do modelo: já o pode mudar.')
    } catch (e) {
      toast.error(mensagemDe(e))
    } finally {
      setCopiando(false)
    }
  }
  const voltarAosModelos = async () => {
    try {
      for (const f of daIgreja) await mut.terminarFluxo.mutateAsync(f.id)
      toast.success('A igreja volta a usar os modelos da Associação.')
    } catch (e) {
      toast.error(mensagemDe(e))
    }
    setVoltar(false)
  }

  return (
    <Cartao titulo={PROCESSOS[processo].plural} icone={Route}
      descricao={proprios ? 'Fluxo próprio desta igreja' : 'Modelo da Associação/Missão (a igreja ainda não tem fluxo próprio)'}
      accoes={podeConfigurar && (proprios ? (
        <div className="flex flex-wrap gap-2">
          <Button size="sm" variant="outline" className="alvo" onClick={() => setNovoFluxo(true)}><Plus className="size-4" />Fluxo para outro valor</Button>
          <Button size="sm" variant="ghost" className="alvo text-muted-foreground" onClick={() => setVoltar(true)}><Undo2 className="size-4" />Voltar ao modelo</Button>
        </div>
      ) : modelos.length > 0 && (
        <Button size="sm" variant="outline" className="alvo" disabled={copiando} onClick={copiar}><Copy className="size-4" />{copiando ? t.comum.aGravar : 'Adaptar para esta igreja'}</Button>
      ))}>
      {aplicam.length === 0 ? (
        <p className="text-sm text-muted-foreground">Sem fluxo: vale a regra antiga (uma só aprovação, por quem tem a permissão).</p>
      ) : (
        <div className="grid gap-4">
          {aplicam.map((f, i) => {
            const proximo = aplicam[i + 1]
            return (
              <FluxoComEtapas key={f.id} f={f} editavel={podeConfigurar && f.igrejaId === igrejaId} quem={quem}
                etapas={etapas.filter((e) => e.fluxoAprovacaoId === f.id)}
                faixa={proximo ? `De ${dinheiro(f.valorMinimo)} até menos de ${dinheiro(proximo.valorMinimo)}` : Number(f.valorMinimo) > 0 ? `A partir de ${dinheiro(f.valorMinimo)}` : processo === 'DESPESA' || processo === 'SAIDA' ? 'Qualquer valor' : null} />
            )
          })}
        </div>
      )}
      {novoFluxo && <DialogoFluxo processo={processo} igrejaId={igrejaId} aoFechar={() => setNovoFluxo(false)} />}
      <DialogoConfirmar aberto={voltar} aoMudar={setVoltar} titulo="Voltar ao modelo da Associação?"
        texto="Os fluxos próprios desta igreja para este processo terminam; os processos novos seguem o modelo da Associação. Os que já estão em curso continuam no fluxo em que começaram."
        accao="Voltar ao modelo" perigo aCorrer={mut.terminarFluxo.isPending} aoConfirmar={voltarAosModelos} />
    </Cartao>
  )
}

function FluxoComEtapas({ f, etapas, editavel, quem, faixa }: { f: Fluxo; etapas: Etapa[]; editavel: boolean; quem: (e: Etapa) => string; faixa: string | null }) {
  const mut = useFluxosMut()
  const [etapa, setEtapa] = useState<Etapa | 'nova' | null>(null)
  const [editarFluxo, setEditarFluxo] = useState(false)
  const [tirar, setTirar] = useState<Etapa | null>(null)
  return (
    <div className="rounded-lg border">
      <div className="flex flex-wrap items-center justify-between gap-2 border-b bg-muted/30 px-3 py-2">
        <div className="min-w-0">
          <p className="text-sm font-semibold">{f.nome} {f.igrejaId == null ? <Pilula variante="secondary" className="ml-1"><Building2 className="mr-1 inline size-3" />Associação</Pilula> : null}</p>
          <p className="text-xs text-muted-foreground">{[faixa, f.descricao].filter(Boolean).join(' · ')}</p>
        </div>
        {editavel && (
          <div className="flex gap-1">
            <Button size="sm" variant="ghost" className="alvo" aria-label={`Alterar ${f.nome}`} onClick={() => setEditarFluxo(true)}><Pencil className="size-4" /></Button>
            <Button size="sm" variant="outline" className="alvo" onClick={() => setEtapa('nova')}><Plus className="size-4" />Etapa</Button>
          </div>
        )}
      </div>
      <ol className="divide-y">
        {etapas.map((e) => (
          <li key={e.id} className="flex flex-wrap items-center gap-3 px-3 py-2">
            <span className="flex size-6 flex-none items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">{e.ordem}</span>
            <span className="min-w-0 flex-1">
              <span className="block text-sm font-medium">{e.nome}</span>
              <span className="block text-xs text-muted-foreground">
                {ACCOES[e.accao as AccaoEtapa]}: {quem(e)}{e.responsavel === 'ORGAO' ? ' (voto em reunião)' : ''}{e.outraPessoa && e.responsavel !== 'ORGAO' ? ' · outra pessoa (nem quem pediu nem quem já decidiu)' : ''}
              </span>
            </span>
            {editavel && (
              <span className="flex gap-1">
                <Button size="sm" variant="ghost" className="alvo" aria-label={`Alterar ${e.nome}`} onClick={() => setEtapa(e)}><Pencil className="size-4" /></Button>
                <Button size="sm" variant="ghost" className="alvo text-muted-foreground" aria-label={`Tirar ${e.nome}`} onClick={() => setTirar(e)}><Trash2 className="size-4" /></Button>
              </span>
            )}
          </li>
        ))}
        {etapas.length === 0 && <li className="px-3 py-2 text-sm text-muted-foreground">Sem etapas: este fluxo não se aplica até ter pelo menos uma.</li>}
      </ol>
      {etapa && <DialogoEtapa f={f} etapa={etapa === 'nova' ? null : etapa} proxima={Math.max(0, ...etapas.map((x) => x.ordem)) + 1} aoFechar={() => setEtapa(null)} />}
      {editarFluxo && <DialogoFluxo processo={f.processo} igrejaId={f.igrejaId!} fluxo={f} aoFechar={() => setEditarFluxo(false)} />}
      <DialogoConfirmar aberto={!!tirar} aoMudar={(v) => !v && setTirar(null)} titulo="Tirar esta etapa do fluxo?"
        texto={<>“{tirar?.nome}” deixa de ser pedida. Os processos que estão nessa etapa passam à seguinte.</>} accao="Tirar etapa" perigo
        aCorrer={mut.terminarEtapa.isPending}
        aoConfirmar={() => tirar && mut.terminarEtapa.mutate(tirar.id, {
          onSuccess: () => { toast.success('Etapa tirada.'); setTirar(null) }, onError: (e) => { toast.error(mensagemDe(e)); setTirar(null) },
        })} />
    </div>
  )
}

function DialogoFluxo({ processo, igrejaId, fluxo, aoFechar }: { processo: Processo; igrejaId: number; fluxo?: Fluxo; aoFechar: () => void }) {
  const mut = useFluxosMut()
  const [nome, setNome] = useState(fluxo?.nome ?? '')
  const [valor, setValor] = useState(fluxo?.valorMinimo ?? '')
  const [descricao, setDescricao] = useState(fluxo?.descricao ?? '')
  const [erro, setErro] = useState<string | null>(null)
  const gravar = async () => {
    setErro(null)
    if (nome.trim().length < 3) return setErro('Dê um nome ao fluxo.')
    try {
      const corpo = { nome: nome.trim(), valorMinimo: valor || '0.00', descricao: descricao.trim() || null }
      if (fluxo) await mut.alterarFluxo.mutateAsync({ id: fluxo.id, ...corpo } as never)
      else await mut.criarFluxo.mutateAsync({ igrejaId, processo, ...corpo } as never)
      toast.success(fluxo ? 'Fluxo alterado.' : 'Fluxo criado: acrescente as etapas.')
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{fluxo ? 'Alterar o fluxo' : 'Novo fluxo'}</DialogTitle>
          <DialogDescription>{PROCESSOS[processo].plural}: aplica-se a partir do valor mínimo (o de maior valor mínimo que não passe o valor).</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5"><label htmlFor="flx-nome" className="text-sm font-medium">Nome</label>
            <Input id="flx-nome" className="alvo" value={nome} onChange={(e) => setNome(e.target.value)} placeholder="ex.: Despesa do Conselho" /></div>
          <div className="grid gap-1.5"><label htmlFor="flx-valor" className="text-sm font-medium">A partir de (valor mínimo)</label>
            <CampoDinheiro id="flx-valor" value={valor} onChange={setValor} className="alvo" /></div>
          <div className="grid gap-1.5"><label htmlFor="flx-desc" className="text-sm font-medium">Descrição</label>
            <Input id="flx-desc" className="alvo" value={descricao} onChange={(e) => setDescricao(e.target.value)} placeholder="opcional" /></div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={mut.criarFluxo.isPending || mut.alterarFluxo.isPending} onClick={gravar}>{t.comum.guardar}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function DialogoEtapa({ f, etapa, proxima, aoFechar }: { f: Fluxo; etapa: Etapa | null; proxima: number; aoFechar: () => void }) {
  const mut = useFluxosMut()
  const perfis = usePerfis()
  const permissoes = usePermissoes()
  const [ordem, setOrdem] = useState(String(etapa?.ordem ?? proxima))
  const [nome, setNome] = useState(etapa?.nome ?? '')
  const [accao, setAccao] = useState<AccaoEtapa>((etapa?.accao as AccaoEtapa) ?? 'APROVAR')
  const [responsavel, setResponsavel] = useState<ResponsavelEtapa>(etapa?.responsavel ?? 'PERFIL')
  const [perfil, setPerfil] = useState(String(etapa?.perfilId ?? ''))
  const [permissao, setPermissao] = useState(String(etapa?.permissaoId ?? ''))
  const [orgao, setOrgao] = useState<string>(etapa?.orgao ?? 'JUNTA_DIRECTIVA')
  const [outra, setOutra] = useState(etapa?.outraPessoa ?? true)
  const [erro, setErro] = useState<string | null>(null)
  const perfisIgreja = useMemo(() => (perfis.data ?? []).filter((p) => !p.endDate && p.ambito === 'IGREJA' && p.codigo !== 'MEMBRO'), [perfis.data])
  const permissoesEtapa = useMemo(() => (permissoes.data ?? []).filter((p) => p.codigo in PERMISSOES_ETAPA), [permissoes.data])

  const gravar = async () => {
    setErro(null)
    if (nome.trim().length < 3) return setErro('Dê um nome à etapa (ex.: Apreciação do tesoureiro).')
    if (responsavel === 'PERFIL' && !perfil) return setErro('Escolha o perfil que decide.')
    if (responsavel === 'PERMISSAO' && !permissao) return setErro('Escolha a permissão de quem decide.')
    const corpo = {
      ordem: Number(ordem), nome: nome.trim(), accao, responsavel, outraPessoa: outra,
      perfilId: responsavel === 'PERFIL' ? Number(perfil) : null, permissaoId: responsavel === 'PERMISSAO' ? Number(permissao) : null,
      orgao: responsavel === 'ORGAO' ? orgao : null,
    }
    try {
      if (etapa) await mut.alterarEtapa.mutateAsync({ id: etapa.id, ...corpo } as never)
      else await mut.criarEtapa.mutateAsync({ fluxoAprovacaoId: f.id, ...corpo } as never)
      toast.success(etapa ? 'Etapa alterada.' : 'Etapa acrescentada.')
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{etapa ? 'Alterar a etapa' : 'Nova etapa'}</DialogTitle>
          <DialogDescription>Fluxo «{f.nome}». As etapas decidem-se pela ordem; um processo só fica aprovado depois da última.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid grid-cols-[5rem_1fr] gap-3">
            <div className="grid gap-1.5"><label htmlFor="eta-ordem" className="text-sm font-medium">Ordem</label>
              <Input id="eta-ordem" type="number" min={1} max={20} className="alvo" value={ordem} onChange={(e) => setOrdem(e.target.value)} /></div>
            <div className="grid gap-1.5"><label htmlFor="eta-nome" className="text-sm font-medium">Nome</label>
              <Input id="eta-nome" className="alvo" value={nome} onChange={(e) => setNome(e.target.value)} placeholder="ex.: Voto do Conselho da Igreja" /></div>
          </div>
          <div className="grid gap-1.5"><label htmlFor="eta-accao" className="text-sm font-medium">O que faz</label>
            <Seleccao id="eta-accao" className="alvo" value={accao} onChange={(e) => setAccao(e.target.value as AccaoEtapa)}>
              {(Object.keys(ACCOES) as AccaoEtapa[]).map((a) => <option key={a} value={a}>{ACCOES[a]}</option>)}
            </Seleccao></div>
          <div className="grid gap-1.5"><label htmlFor="eta-resp" className="text-sm font-medium">Quem decide</label>
            <Seleccao id="eta-resp" className="alvo" value={responsavel} onChange={(e) => setResponsavel(e.target.value as ResponsavelEtapa)}>
              {(Object.keys(RESPONSAVEIS) as ResponsavelEtapa[]).map((r) => <option key={r} value={r}>{RESPONSAVEIS[r]}</option>)}
            </Seleccao></div>
          {responsavel === 'PERFIL' && (
            <Seleccao aria-label="Perfil" className="alvo" value={perfil} onChange={(e) => setPerfil(e.target.value)}>
              <option value="">Escolher o perfil…</option>
              {perfisIgreja.map((p) => <option key={p.id} value={p.id}>{rotulos.perfil[p.codigo ?? ''] ?? p.nome}</option>)}
            </Seleccao>
          )}
          {responsavel === 'PERMISSAO' && (
            <Seleccao aria-label="Permissão" className="alvo" value={permissao} onChange={(e) => setPermissao(e.target.value)}>
              <option value="">Escolher a permissão…</option>
              {permissoesEtapa.map((p) => <option key={p.id} value={p.id}>{PERMISSOES_ETAPA[p.codigo]}</option>)}
            </Seleccao>
          )}
          {responsavel === 'ORGAO' && (
            <Seleccao aria-label="Órgão" className="alvo" value={orgao} onChange={(e) => setOrgao(e.target.value)}>
              {(Object.keys(ORGAOS) as TipoReuniao[]).map((o) => <option key={o} value={o}>{ORGAOS[o]}</option>)}
            </Seleccao>
          )}
          {responsavel !== 'ORGAO' && (
            <label className={cn('flex items-start gap-2 text-sm')}>
              <input type="checkbox" className="mt-1 size-4" checked={outra} onChange={(e) => setOutra(e.target.checked)} />
              <span>Tem de ser outra pessoa <span className="block text-xs text-muted-foreground">Quem pediu e quem já decidiu outra etapa não decide esta.</span></span>
            </label>
          )}
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={mut.criarEtapa.isPending || mut.alterarEtapa.isPending} onClick={gravar}>{t.comum.guardar}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
