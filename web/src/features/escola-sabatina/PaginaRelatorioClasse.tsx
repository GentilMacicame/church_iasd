/**
 * Relatório de uma classe num sábado (P-05; F-ES-04, F-ES-05, F-ES-06) · no computador e no telemóvel, sem rede.
 * M.M. (membros matriculados), M.P. (membros presentes), E.D. (estudo diário), visitantes e filiais; chamada nominal
 * em tabela; as três ofertas; visitantes; e ao lado o resumo do sábado (como a linha do quadro) com as acções.
 * Tudo fica no telemóvel; "Guardar" envia (ou deixa na fila até haver rede). Com o relatório na base de dados:
 * o tesoureiro lança as ofertas (P-05 passo 5) e o secretário fecha (passo 6); só o director reabre.
 */
import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useQueryClient } from '@tanstack/react-query'
import {
  AlertTriangle, ArrowLeft, BarChart3, BookOpen, Check, CheckCheck, Coins, Landmark, Lock, LockOpen, Plus, Save, Table2, Trash2,
} from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Avatar, Cartao, Dinheiro, Pilula, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, LinhasACarregar } from '@/components/comum/estados'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { CampoFormulario, ErroFormulario } from '@/components/comum/formulario'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { Seleccao } from '@/components/comum/Seleccao'
import { useIgreja, useSessao } from '@/auth/sessao'
import { mensagemDe } from '@/api/erros'
import { rotulos, t } from '@/i18n/pt-MZ'
import { centimos, data, deCentimos, dinheiro } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { useContasIgreja } from '@/features/tesouraria/api'
import { nomeTrimestre, useFecharRelatorio, useLancarOfertas, useReabrirRelatorio, type Relatorio } from './api'
import { textoMT, textoPct, tomPct } from './componentes'
import {
  chaveRelatorio, contarChamada, descartarRascunho, enviarRascunho, gravarRascunho, lerRascunho, rascunhoDoPacote, useEmLinha, usePacote,
  type Numeros, type PacoteRelatorio, type Rascunho,
} from './offline'
import { AvisosRede } from './PaginaSabado'

/**
 * Um número do sábado (M.M., M.P., E.D., visitantes, filiais): o nome por extenso com a sigla por cima, um campo
 * grande e igual para todos, e uma linha de ajuda (a % ou a origem do valor). Só de leitura quando fechado ou
 * contado pela chamada (mesma altura, fundo cinzento).
 */
function Numero({ sigla, rotulo, valor, aoMudar, so, ajuda }: {
  sigla: string; rotulo: string; valor: number; aoMudar?: (v: number) => void; so?: boolean; ajuda?: ReactNode
}) {
  const id = `n-${sigla.replace(/\W/g, '')}`
  return (
    <div className="grid min-w-0 content-start gap-1.5">
      <label htmlFor={id} className="min-w-0">
        <span className="block text-xs font-bold tracking-wide text-primary">{sigla}</span>
        <span className="block truncate text-sm font-medium">{rotulo}</span>
      </label>
      {so || !aoMudar ? (
        <div id={id} className="flex h-12 items-center justify-center rounded-md border bg-muted/50 text-2xl font-bold tabular-nums text-foreground/80">{valor}</div>
      ) : (
        <input id={id} inputMode="numeric" value={String(valor)} onFocus={(e) => e.target.select()}
          onChange={(e) => aoMudar(Math.min(Number(e.target.value.replace(/\D/g, '') || 0), 9999))}
          className="h-12 w-full min-w-0 rounded-md border border-input bg-card text-center text-2xl font-bold tabular-nums shadow-sm outline-none focus:border-ring focus:ring-2 focus:ring-ring/30" />
      )}
      <div className="flex min-h-5 items-center justify-center text-xs text-muted-foreground">{ajuda}</div>
    </div>
  )
}

/** Título de um passo do relatório ("1 Números do sábado"). */
function Passo({ n, children }: { n: number; children: ReactNode }) {
  return (
    <span className="flex items-center gap-2.5">
      <span className="flex size-6 flex-none items-center justify-center rounded-full bg-primary text-xs font-bold text-primary-foreground">{n}</span>
      {children}
    </span>
  )
}

/** Percentagem pequena a cores (ao lado dos números e no resumo). */
function PctPilula({ v, tipo = 'presenca' }: { v: number | null; tipo?: 'presenca' | 'alvo' }) {
  return <span className={cn('rounded px-1.5 py-0.5 text-[11px] font-semibold tabular-nums', v == null ? 'text-muted-foreground' : tomPct(v, tipo))}>{textoPct(v)}</span>
}

/** Caixa de marcar da chamada (alvo de 44px; só um ✓ quando o relatório está fechado). */
function Marca({ ligado, aoMudar, so, rotulo, tom = 'primary' }: { ligado: boolean; aoMudar: (v: boolean) => void; so?: boolean; rotulo: string; tom?: 'primary' | 'success' }) {
  if (so) return ligado ? <Check className={cn('mx-auto size-5', tom === 'success' ? 'text-success-text' : 'text-primary')} aria-label={`${rotulo}: sim`} /> : <span className="block text-center text-muted-foreground" aria-label={`${rotulo}: não`}>—</span>
  return (
    <button type="button" role="checkbox" aria-checked={ligado} aria-label={rotulo} onClick={() => aoMudar(!ligado)}
      className="alvo mx-auto flex size-11 items-center justify-center rounded-md hover:bg-muted">
      <span className={cn('flex size-6 items-center justify-center rounded-md border-2 transition-colors',
        ligado ? (tom === 'success' ? 'border-success bg-success text-white' : 'border-primary bg-primary text-primary-foreground') : 'border-input bg-card')}>
        {ligado && <Check className="size-4" strokeWidth={3} />}
      </span>
    </button>
  )
}

export default function PaginaRelatorioClasse() {
  const { ect, esa } = useParams()
  const ctId = Number(ect), sabadoId = Number(esa)
  const igreja = useIgreja()
  const qc = useQueryClient()
  const emLinha = useEmLinha()
  const pacote = usePacote(igreja.id, ctId, sabadoId)
  const chave = chaveRelatorio(ctId, sabadoId)
  const [r, setR] = useState<Rascunho | null>(null)
  const [alterado, setAlterado] = useState(false)
  const [aEnviar, setAEnviar] = useState(false)

  // rascunho guardado no telemóvel, ou o relatório da base de dados
  const iniciar = useCallback(async (p: PacoteRelatorio) => {
    const guardado = await lerRascunho(chave)
    setR(guardado ? { ...guardado, matriculadosPelasMatriculas: p.alunos.length } : rascunhoDoPacote(p))
    setAlterado(!!guardado && !guardado.porEnviar)
  }, [chave])
  const pacoteIniciado = useRef<string | null>(null)
  useEffect(() => {
    if (!pacote.data) return
    // reinicia quando chega um pacote novo e não há nada por guardar neste ecrã
    if (pacoteIniciado.current === pacote.data.lidoEm) return
    if (pacoteIniciado.current && alterado) return
    pacoteIniciado.current = pacote.data.lidoEm
    void iniciar(pacote.data)
  }, [pacote.data, alterado, iniciar])

  // enviado (por este ecrã ou pela fila): volta a ler da base de dados
  useEffect(() => {
    const aoEnviar = (e: Event) => {
      if ((e as CustomEvent<string>).detail !== chave) return
      void qc.invalidateQueries({ queryKey: ['es-pacote', ctId, sabadoId] })
      void qc.invalidateQueries({ queryKey: ['es'] })
    }
    window.addEventListener('es:enviado', aoEnviar)
    return () => window.removeEventListener('es:enviado', aoEnviar)
  }, [chave, ctId, sabadoId, qc])

  // cada alteração fica logo no telemóvel (não se perde se o telefone desligar)
  const mudar = (fn: (x: Rascunho) => Rascunho) => {
    setR((x) => {
      if (!x) return x
      const novo = { ...fn(x), erro: undefined }
      void gravarRascunho({ ...novo, porEnviar: x.porEnviar })
      return novo
    })
    setAlterado(true)
  }
  const mudarNumero = <K extends keyof Numeros>(k: K, v: Numeros[K]) => mudar((x) => ({ ...x, numeros: { ...x.numeros, [k]: v } }))

  const guardar = async () => {
    if (!r) return
    setAEnviar(true)
    try {
      await gravarRascunho({ ...r, porEnviar: true, erro: undefined })
      const res = await enviarRascunho(chave)
      if (res === 'enviado') { toast.success(t.es.enviado); setAlterado(false); pacoteIniciado.current = null }
      else if (res === 'sem-rede') { toast.info(t.es.guardadoTelemovel); setAlterado(false); setR((x) => x && { ...x, porEnviar: true }) }
      else {
        const depois = await lerRascunho(chave)
        if (depois) setR(depois)
        if (depois?.conflito) toast.warning('Outra pessoa alterou este relatório: escolha se grava por cima.')
        else toast.error(t.es.recusado)
      }
    } finally {
      setAEnviar(false)
    }
  }

  // outra pessoa alterou o relatório: o secretário decide gravar por cima
  const gravarPorCima = async () => {
    if (!r) return
    setAEnviar(true)
    try {
      await gravarRascunho({ ...r, porEnviar: true, forcar: true, conflito: false, erro: undefined })
      const res = await enviarRascunho(chave)
      if (res === 'enviado') { toast.success(t.es.enviado); setAlterado(false); pacoteIniciado.current = null }
      else if (res === 'sem-rede') { toast.info(t.es.guardadoTelemovel); setR((x) => x && { ...x, porEnviar: true, forcar: true, conflito: false, erro: undefined }) }
      else { const depois = await lerRascunho(chave); if (depois) setR(depois); toast.error(t.es.recusado) }
    } finally {
      setAEnviar(false)
    }
  }

  const desfazer = async () => {
    await descartarRascunho(chave)
    setAlterado(false)
    if (pacote.data) setR(rascunhoDoPacote(pacote.data))
  }

  if (pacote.isError) return <EstadoErro erro={pacote.error} aoTentar={() => pacote.refetch()} />
  if (pacote.isPending || !r) return <Cartao><LinhasACarregar linhas={6} /></Cartao>
  const p = pacote.data
  const rel = p.relatorio
  const fechado = rel?.estado === 'FECHADO'
  const chamada = r.chamada
  const contagem = chamada ? contarChamada(chamada) : null
  const presentes = contagem?.presentes ?? r.numeros.membrosPresentes
  const estudaram = contagem?.estudaram ?? r.numeros.estudoDiario
  const matriculados = r.numeros.membrosMatriculados ?? p.alunos.length
  const totalOfertas = ['oferta', 'oferta13Sabado', 'ofertaDespesas'].reduce((s, k) => s + (centimos(r.numeros[k as 'oferta'] || '0') || 0), 0)

  const alvo = Number(p.classeTrimestre.alvoOfertaSabado ?? 0)
  const oferta = (centimos(r.numeros.oferta || '0') || 0) / 100
  const pctPres = matriculados ? presentes / matriculados : null
  const pctEd = presentes ? estudaram / presentes : null
  const porGuardar = alterado || r.porEnviar
  const resumo: [string, ReactNode][] = [
    ['M.M. · membros matriculados', matriculados],
    ['M.P. · membros presentes', presentes],
    ['% Presença', <PctPilula key="p" v={pctPres} />],
    ['E.D. · estudo diário', estudaram],
    ['% E.D.', <PctPilula key="e" v={pctEd} />],
    ['Visitantes', r.numeros.visitantes],
    ['Filiais', r.numeros.filiais],
  ]
  const botaoGuardar = (classe?: string) => (
    <Button type="button" className={cn('alvo h-11', classe)} disabled={aEnviar} onClick={() => void guardar()}>
      <Save className="size-4" />{aEnviar ? t.comum.aGravar : emLinha ? 'Guardar relatório' : 'Guardar no telemóvel'}
    </Button>
  )

  return (
    <div className="pb-24 lg:pb-6">
      <TituloPagina
        antes={<Link to={`/escola-sabatina/sabado?trimestre=${p.trimestre.id}&sabado=${p.sabado.id}`} className="alvo mb-3 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" />{t.es.sabado}</Link>}
        icone={BookOpen}
        titulo={p.classe.nome}
        descricao={<>
          {rotulos.divisao[p.classe.divisao]} · {p.sabado.numero}.º sábado · {data(p.sabado.data)} · {nomeTrimestre(p.trimestre)}
          {p.sabado.decimoTerceiro && <> · <strong className="font-semibold text-warning-text">13.º sábado</strong></>}
        </>}
        accoes={<span className="flex flex-wrap items-center gap-1.5">
          {r.conflito ? <Pilula variante="warning">Conflito</Pilula> : r.erro ? <Pilula variante="destructive">Recusado</Pilula> : r.porEnviar ? <Pilula variante="info">Por enviar</Pilula> : alterado ? <Pilula variante="warning">Por guardar</Pilula> : null}
          {rel ? <Pilula variante={fechado ? 'success' : 'warning'}>{fechado && <Lock className="size-3" />}{rotulos.estadoRelatorio[rel.estado]}</Pilula> : <Pilula variante="warning">Por registar</Pilula>}
          <Button asChild variant="ghost" size="sm" className="print:hidden"><Link to={`/escola-sabatina/classes/${p.classe.id}?trimestre=${p.trimestre.id}`}><Table2 className="size-4" />Folha da classe</Link></Button>
        </span>}
      />

      <div className="grid gap-3">
        <AvisosRede />
        {r.conflito ? (
          <div role="alert" className="grid gap-3 rounded-lg border border-warning/40 bg-tint-warning px-4 py-3 text-sm text-warning-text">
            <p className="flex items-start gap-2"><AlertTriangle className="mt-0.5 size-4 flex-none" aria-hidden />{r.erro ?? 'Outra pessoa alterou este relatório.'}</p>
            <div className="flex flex-wrap gap-2">
              <Button size="sm" className="alvo" disabled={aEnviar || !emLinha} onClick={() => void gravarPorCima()}>Gravar por cima</Button>
              <Button size="sm" variant="outline" className="alvo" disabled={aEnviar} onClick={() => void desfazer()}>Descartar as minhas alterações</Button>
            </div>
          </div>
        ) : r.erro && <ErroFormulario mensagem={r.erro} />}
        {fechado && (
          <div role="status" className="flex items-center gap-2 rounded-lg border border-success/20 bg-tint-success px-4 py-2.5 text-sm text-success-text">
            <Lock className="size-4 flex-none" aria-hidden />
            <p>Relatório fechado: as ofertas estão conferidas com a tesouraria. Para corrigir, o director da ES reabre-o.</p>
          </div>
        )}
      </div>

      <div className="mt-4 grid items-start gap-5 lg:grid-cols-[minmax(0,1fr)_20rem]">
        <div className="grid min-w-0 gap-5">
          <Cartao titulo={<Passo n={1}>Números do sábado</Passo>} descricao={chamada ? 'M.P. e E.D. contam-se pela chamada nominal (passo 2).' : 'Quantos estavam matriculados, presentes, estudaram a lição todos os dias, visitantes e filiais.'}>
            <div className="grid grid-cols-2 gap-x-4 gap-y-3 sm:grid-cols-3 xl:grid-cols-5">
              <Numero sigla="M.M." rotulo="Membros matriculados" valor={matriculados} so={fechado || r.numeros.membrosMatriculados == null}
                aoMudar={(v) => mudarNumero('membrosMatriculados', v)}
                ajuda={fechado ? undefined : (
                  <button type="button" className="font-medium text-primary hover:underline"
                    onClick={() => mudarNumero('membrosMatriculados', r.numeros.membrosMatriculados == null ? p.alunos.length : null)}>
                    {r.numeros.membrosMatriculados == null ? 'Pelas matrículas · alterar' : 'Usar as matrículas'}
                  </button>
                )} />
              <Numero sigla="M.P." rotulo="Membros presentes" valor={presentes} so={fechado || !!chamada}
                aoMudar={(v) => mudarNumero('membrosPresentes', v)} ajuda={<span className="inline-flex items-center gap-1 whitespace-nowrap">Presença <PctPilula v={pctPres} /></span>} />
              <Numero sigla="E.D." rotulo="Estudo diário" valor={estudaram} so={fechado || !!chamada}
                aoMudar={(v) => mudarNumero('estudoDiario', v)} ajuda={<span className="inline-flex items-center gap-1 whitespace-nowrap">Estudo <PctPilula v={pctEd} /></span>} />
              <Numero sigla="Visit." rotulo="Visitantes" valor={r.numeros.visitantes} so={fechado} aoMudar={(v) => mudarNumero('visitantes', v)} />
              <Numero sigla="Fil." rotulo="Filiais" valor={r.numeros.filiais} so={fechado} aoMudar={(v) => mudarNumero('filiais', v)} />
            </div>
            {presentes > matriculados && (
              <p className="mt-3 flex items-center gap-1.5 text-xs font-medium text-warning-text"><AlertTriangle className="size-3.5" />Há mais presentes do que matriculados: a base de dados não aceita. Corrija o M.M. ou o M.P.</p>
            )}
          </Cartao>

          <Chamada p={p} r={r} fechado={fechado} mudar={mudar} />

          <Cartao titulo={<Passo n={3}>Ofertas</Passo>} descricao={t.es.separadas}>
            {p.sabado.decimoTerceiro && !fechado && (
              <p className="mb-4 rounded-lg border border-warning/30 bg-tint-warning px-4 py-2.5 text-sm text-warning-text">
                Hoje é o 13.º sábado: anote a oferta do 13.º sábado separada da oferta missionária.
              </p>
            )}
            <div className="grid gap-4 sm:grid-cols-3">
              {([['oferta', t.es.oferta, alvo ? `Alvo do sábado: ${textoMT(alvo)}` : undefined], ['oferta13Sabado', t.es.oferta13, undefined], ['ofertaDespesas', t.es.ofertaDespesas, 'Fica na Escola Sabatina local']] as const).map(([k, rotulo, ajuda]) => (
                <CampoFormulario key={k} rotulo={rotulo} ajuda={ajuda}>
                  {(a) => fechado
                    ? <p className="h-10 rounded-md border bg-muted/40 px-3 text-right text-base leading-10 font-semibold tabular-nums">{dinheiro(r.numeros[k])}</p>
                    : <CampoDinheiro {...a} value={r.numeros[k]} onChange={(v) => mudarNumero(k, v)} className="h-10 text-base font-semibold" />}
                </CampoFormulario>
              ))}
            </div>
            <div className="mt-4 flex items-center justify-between border-t pt-3 text-sm">
              <span className="text-muted-foreground">Total das três ofertas</span>
              <Dinheiro valor={deCentimos(totalOfertas)} className="text-base font-bold" />
            </div>
            <CampoFormulario rotulo="Observações" className="mt-4">
              {(a) => <Textarea {...a} rows={2} maxLength={500} value={r.numeros.observacoes} disabled={fechado} onChange={(e) => mudarNumero('observacoes', e.target.value)} placeholder="Opcional" />}
            </CampoFormulario>
          </Cartao>

          <Visitantes p={p} r={r} fechado={fechado} mudar={mudar} />
        </div>

        <aside className="grid gap-5 lg:sticky lg:top-[calc(var(--header-height)+1rem)]">
          <Cartao titulo="Resumo do sábado" icone={BarChart3} semMargem>
            <dl className="divide-y border-t text-sm">
              {resumo.map(([rot, v]) => (
                <div key={rot} className="flex items-center justify-between gap-3 px-5 py-2">
                  <dt className="text-muted-foreground">{rot}</dt><dd className="font-semibold tabular-nums">{v}</dd>
                </div>
              ))}
              <div className="flex items-center justify-between gap-3 bg-muted/30 px-5 py-2">
                <dt className="text-muted-foreground">Oferta missionária</dt>
                <dd className="flex items-center gap-2 font-semibold tabular-nums">{alvo > 0 && <PctPilula v={oferta / alvo} tipo="alvo" />}{textoMT(oferta)}</dd>
              </div>
              <div className="flex items-center justify-between gap-3 px-5 py-2.5">
                <dt className="font-medium">Total das ofertas</dt><dd className="text-base font-bold tabular-nums"><Dinheiro valor={deCentimos(totalOfertas)} /></dd>
              </div>
            </dl>
            {!fechado && (
              <div className="hidden gap-2 border-t p-4 lg:grid">
                {botaoGuardar('w-full')}
                {porGuardar && <Button type="button" variant="ghost" size="sm" onClick={() => void desfazer()}>Desfazer alterações</Button>}
              </div>
            )}
          </Cartao>
          {rel && <Tesouraria rel={rel} emLinha={emLinha} porGuardar={porGuardar} />}
        </aside>
      </div>

      {!fechado && (
        <div className="fixed inset-x-0 bottom-0 z-20 border-t bg-background/95 px-4 py-3 backdrop-blur lg:hidden">
          <div className="flex items-center justify-end gap-2">
            {porGuardar && <Button type="button" variant="ghost" className="alvo mr-auto" onClick={() => void desfazer()}>Desfazer</Button>}
            {botaoGuardar('min-w-40')}
          </div>
        </div>
      )}
    </div>
  )
}

function Chamada({ p, r, fechado, mudar }: { p: PacoteRelatorio; r: Rascunho; fechado: boolean; mudar: (fn: (x: Rascunho) => Rascunho) => void }) {
  const chamada = r.chamada
  const [confirmarTirar, setConfirmarTirar] = useState(false)
  const marcar = (membro: number, campo: 'presente' | 'estudouLicao', v: boolean) => mudar((x) => {
    const c = { ...(x.chamada ?? {}) }
    const actual = c[membro] ?? { presente: false, estudouLicao: false }
    c[membro] = campo === 'presente' ? { presente: v, estudouLicao: v && actual.estudouLicao } : { presente: actual.presente || v, estudouLicao: v }
    return { ...x, chamada: c }
  })
  const comecar = () => mudar((x) => ({ ...x, chamada: Object.fromEntries(p.alunos.map((a) => [String(a.membroId), { presente: false, estudouLicao: false }])) }))
  const todos = () => mudar((x) => ({ ...x, chamada: Object.fromEntries(p.alunos.map((a) => [String(a.membroId), { presente: true, estudouLicao: x.chamada?.[a.membroId]?.estudouLicao ?? false }])) }))
  const contagem = chamada ? contarChamada(chamada) : null

  return (
    <Cartao titulo={<Passo n={2}>Chamada nominal <span className="text-sm font-normal text-muted-foreground">(opcional)</span></Passo>} semMargem
      descricao={chamada ? `${contagem!.presentes} de ${p.alunos.length} presentes · ${contagem!.estudaram} estudaram a lição` : 'Opcional: marque quem veio e quem estudou; M.P. e E.D. contam-se sozinhos.'}
      accoes={!fechado && chamada && (
        <span className="flex gap-1">
          <Button type="button" variant="outline" size="sm" onClick={todos}>Todos presentes</Button>
          {p.presencas.length === 0 && <Button type="button" variant="ghost" size="sm" onClick={() => setConfirmarTirar(true)}>Sem chamada</Button>}
        </span>
      )}>
      {p.alunos.length === 0 ? (
        <p className="px-5 pb-5 text-sm text-muted-foreground sm:px-6">
          A classe não tem alunos matriculados neste sábado. <Link to={`/escola-sabatina/classes/${p.classe.id}?aba=matriculas`} className="font-medium text-primary hover:underline">Matricular alunos</Link>
        </p>
      ) : !chamada ? (
        <div className="px-5 pb-5 sm:px-6">
          <Button type="button" variant="outline" className="alvo" disabled={fechado} onClick={comecar}><CheckCheck className="size-4" />Fazer a chamada ({p.alunos.length} alunos)</Button>
        </div>
      ) : (
        <table className="w-full border-t text-sm">
          <thead>
            <tr className="bg-muted/50 text-xs text-muted-foreground">
              <th className="w-14 py-2 pl-5 text-left font-medium sm:pl-6">N.º</th>
              <th className="py-2 pl-1 text-left font-medium">Aluno</th>
              <th className="w-24 py-2 text-center font-medium">Presente</th>
              <th className="w-28 py-2 pr-3 text-center font-medium sm:pr-4">Estudou a lição</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {p.alunos.map((a, i) => {
              const v = chamada[a.membroId] ?? { presente: false, estudouLicao: false }
              return (
                <tr key={a.membroId} className={cn('hover:bg-muted/40', !v.presente && 'text-muted-foreground')}>
                  <td className="py-1 pl-5 tabular-nums sm:pl-6">{i + 1}</td>
                  <td className="py-1 pl-1">
                    <span className="flex min-w-0 items-center gap-2.5">
                      <Avatar id={a.membroId} nome={a.nome} apelido={a.apelido} tamanho={28} />
                      <span className={cn('truncate', v.presente && 'font-medium text-foreground')}>{a.nome} {a.apelido}</span>
                    </span>
                  </td>
                  <td className="py-1"><Marca ligado={v.presente} so={fechado} rotulo={`${a.nome} ${a.apelido} presente`} aoMudar={(x) => marcar(a.membroId, 'presente', x)} /></td>
                  <td className="py-1 pr-3 sm:pr-4"><Marca ligado={v.estudouLicao} so={fechado} tom="success" rotulo={`${a.nome} ${a.apelido} estudou a lição`} aoMudar={(x) => marcar(a.membroId, 'estudouLicao', x)} /></td>
                </tr>
              )
            })}
          </tbody>
          <tfoot>
            <tr className="border-t bg-muted/30 text-sm font-semibold">
              <td className="py-2 pl-5 sm:pl-6" colSpan={2}>Total</td>
              <td className="py-2 text-center tabular-nums">{contagem!.presentes}</td>
              <td className="py-2 pr-3 text-center tabular-nums sm:pr-4">{contagem!.estudaram}</td>
            </tr>
          </tfoot>
        </table>
      )}
      <DialogoConfirmar aberto={confirmarTirar} aoMudar={setConfirmarTirar} titulo="Registar sem chamada?"
        texto="As marcações desta chamada perdem-se e os presentes e o estudo diário passam a ser escritos à mão." accao="Sem chamada"
        aoConfirmar={() => { mudar((x) => ({ ...x, chamada: null })); setConfirmarTirar(false) }} />
    </Cartao>
  )
}

function Visitantes({ p, r, fechado, mudar }: { p: PacoteRelatorio; r: Rascunho; fechado: boolean; mudar: (fn: (x: Rascunho) => Rascunho) => void }) {
  const basicos = useMembrosBasicos()
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }
  const [nome, setNome] = useState('')
  const [telefone, setTelefone] = useState('')
  const [convidou, setConvidou] = useState<number | null>(null)
  const [erro, setErro] = useState<string | null>(null)
  const novos = r.visitantesNovos.filter((v) => !v.enviado)
  const total = p.visitantes.length + novos.length

  const juntar = () => {
    if (!nome.trim()) { setErro('Escreva o nome do visitante.'); return }
    if (telefone && !/^\+?[\d\s]{7,20}$/.test(telefone.trim())) { setErro('Telefone inválido (só números, ex.: 84 123 4567).'); return }
    setErro(null)
    mudar((x) => ({
      ...x,
      visitantesNovos: [...x.visitantesNovos, { local: crypto.randomUUID(), nome: nome.trim(), telefone: telefone.replace(/\s/g, '') || undefined, convidadoPorMembroId: convidou ?? undefined }],
      // o número de visitantes acompanha a lista com nome
      numeros: { ...x.numeros, visitantes: Math.max(x.numeros.visitantes, total + 1) },
    }))
    setNome(''); setTelefone(''); setConvidou(null)
  }

  return (
    <Cartao titulo={<Passo n={4}>Visitantes</Passo>} semMargem
      descricao={`${total} com nome e contacto · para o seguimento (anonimizados ao fim de 12 meses se não se tornarem membros)`}>
      {total > 0 && (
        <table className="w-full border-t text-sm">
          <thead>
            <tr className="bg-muted/50 text-xs text-muted-foreground">
              <th className="py-2 pl-5 text-left font-medium sm:pl-6">Nome</th>
              <th className="py-2 text-left font-medium">Telefone</th>
              <th className="hidden py-2 text-left font-medium sm:table-cell">Convidado por</th>
              <th className="w-24 py-2 pr-5 sm:pr-6"><span className="sr-only">Estado</span></th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {p.visitantes.map((v) => (
              <tr key={v.id}>
                <td className="py-2.5 pl-5 font-medium sm:pl-6">{v.anonimizadoEm ? <span className="text-muted-foreground">(anonimizado)</span> : v.nome}</td>
                <td className="py-2.5 tabular-nums text-muted-foreground">{v.telefone ?? '—'}</td>
                <td className="hidden py-2.5 text-muted-foreground sm:table-cell">{v.convidadoPorMembroId ? nomeDe(v.convidadoPorMembroId) ?? '—' : '—'}</td>
                <td className="py-2.5 pr-5 text-right sm:pr-6"><Pilula variante="success">Registado</Pilula></td>
              </tr>
            ))}
            {novos.map((v) => (
              <tr key={v.local}>
                <td className="py-1.5 pl-5 font-medium sm:pl-6">{v.nome}</td>
                <td className="py-1.5 tabular-nums text-muted-foreground">{v.telefone ?? '—'}</td>
                <td className="hidden py-1.5 text-muted-foreground sm:table-cell">{v.convidadoPorMembroId ? nomeDe(v.convidadoPorMembroId) ?? '—' : '—'}</td>
                <td className="py-1.5 pr-3 text-right sm:pr-4">
                  <span className="inline-flex items-center gap-1">
                    <Pilula variante="info">Por enviar</Pilula>
                    {!fechado && (
                      <Button type="button" variant="ghost" size="icon" className="size-9" aria-label={`Tirar ${v.nome}`}
                        onClick={() => mudar((x) => ({ ...x, visitantesNovos: x.visitantesNovos.filter((y) => y.local !== v.local) }))}>
                        <Trash2 className="size-4" />
                      </Button>
                    )}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
      {!fechado && (
        <div className="grid gap-3 border-t bg-muted/20 px-5 py-4 sm:px-6">
          <ErroFormulario mensagem={erro} />
          <div className="grid items-end gap-3 sm:grid-cols-[1.4fr_1fr_1.4fr_auto]">
            <CampoFormulario rotulo="Nome do visitante">
              {(a) => <Input {...a} value={nome} onChange={(e) => setNome(e.target.value)} maxLength={150} onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); juntar() } }} />}
            </CampoFormulario>
            <CampoFormulario rotulo="Telefone">
              {(a) => <Input {...a} value={telefone} onChange={(e) => setTelefone(e.target.value)} inputMode="tel" maxLength={20} placeholder="84 123 4567" />}
            </CampoFormulario>
            <CampoFormulario rotulo="Convidado por">
              {(a) => <CampoMembro id={a.id} valor={convidou} aoMudar={setConvidou} nomeDe={nomeDe} vazio="Ninguém / não sabe" />}
            </CampoFormulario>
            <Button type="button" variant="outline" className="alvo" onClick={juntar}><Plus className="size-4" />Juntar</Button>
          </div>
        </div>
      )}
    </Cartao>
  )
}

/** P-05 passos 5 e 6: lançar as ofertas na tesouraria, fechar e reabrir (precisam de rede). */
function Tesouraria({ rel, emLinha, porGuardar }: { rel: Relatorio; emLinha: boolean; porGuardar: boolean }) {
  const { pode } = useSessao()
  const fechar = useFecharRelatorio()
  const reabrir = useReabrirRelatorio()
  const [lancar, setLancar] = useState(false)
  const [erro, setErro] = useState<string | null>(null)
  const fechado = rel.estado === 'FECHADO'
  const total = centimos(rel.oferta) + centimos(rel.oferta13Sabado) + centimos(rel.ofertaDespesas)
  const qc = useQueryClient()
  const recarregar = () => qc.invalidateQueries({ queryKey: ['es-pacote', rel.classeTrimestreId, rel.sabadoId] })

  const accao = async (fn: () => Promise<unknown>, ok: string) => {
    setErro(null)
    try { await fn(); toast.success(ok); await recarregar() } catch (e) { setErro(mensagemDe(e)) }
  }

  return (
    <Cartao titulo="Tesouraria e fecho" icone={Landmark}
      descricao={total === 0 ? 'Sem ofertas neste sábado: pode fechar-se logo.'
        : rel.transacaoId ? 'Ofertas lançadas na tesouraria. Depois de confirmadas, o relatório pode fechar-se.'
        : 'O tesoureiro lança as ofertas na tesouraria (uma linha por fundo); depois fecha-se o relatório.'}>
      <div className="grid gap-3">
        <ErroFormulario mensagem={erro} />
        {!emLinha && <p className="text-sm text-muted-foreground">Precisa de rede para lançar, fechar ou reabrir.</p>}
        {porGuardar && !fechado && <p className="text-sm text-warning-text">Guarde o relatório antes de lançar as ofertas ou de o fechar.</p>}
        <div className="flex flex-wrap gap-2">
          {rel.transacaoId && pode('tesouraria.transacao.ler') && (
            <Button asChild variant="outline" className="alvo"><Link to={`/tesouraria/movimentos/${rel.transacaoId}`}>Ver o movimento</Link></Button>
          )}
          {!fechado && total > 0 && !rel.transacaoId && pode('tesouraria.transacao.criar') && (
            <Button type="button" variant="outline" className="alvo" disabled={!emLinha || porGuardar} onClick={() => setLancar(true)}>
              <Coins className="size-4" />Lançar ofertas na tesouraria
            </Button>
          )}
          {!fechado && pode('escola_sabatina.relatorio_sabado.fechar') && (
            <Button type="button" className="alvo" disabled={!emLinha || porGuardar || fechar.isPending}
              onClick={() => void accao(() => fechar.mutateAsync(rel.id), 'Relatório fechado.')}>
              <Lock className="size-4" />{fechar.isPending ? 'A fechar…' : 'Fechar relatório'}
            </Button>
          )}
          {fechado && pode('escola_sabatina.relatorio_sabado.reabrir') && (
            <Button type="button" variant="outline" className="alvo" disabled={!emLinha || reabrir.isPending}
              onClick={() => void accao(() => reabrir.mutateAsync(rel.id), 'Relatório reaberto.')}>
              <LockOpen className="size-4" />{reabrir.isPending ? 'A reabrir…' : 'Reabrir'}
            </Button>
          )}
        </div>
      </div>
      {lancar && <DialogoLancar rel={rel} aoFechar={() => setLancar(false)} aoLancar={recarregar} />}
    </Cartao>
  )
}

function DialogoLancar({ rel, aoFechar, aoLancar }: { rel: Relatorio; aoFechar: () => void; aoLancar: () => void }) {
  const contas = useContasIgreja()
  const lancar = useLancarOfertas(rel.id)
  const [chave] = useState(() => crypto.randomUUID())
  const [conta, setConta] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const caixa = contas.data?.find((c) => c.tipo === 'CAIXA')
  useEffect(() => { if (!conta && (caixa ?? contas.data?.[0])) setConta(String((caixa ?? contas.data![0]).id)) }, [caixa, contas.data, conta])

  const submeter = async () => {
    setErro(null)
    try {
      await lancar.mutateAsync({ chave, corpo: { contaId: Number(conta), missoes: rel.oferta, decimoTerceiro: rel.oferta13Sabado, despesas: rel.ofertaDespesas } })
      toast.success('Ofertas lançadas e confirmadas na tesouraria.')
      aoLancar()
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }
  const linhas: [string, string][] = [[t.es.oferta, rel.oferta], [t.es.oferta13, rel.oferta13Sabado], [t.es.ofertaDespesas, rel.ofertaDespesas]]

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Lançar as ofertas na tesouraria</DialogTitle>
          <DialogDescription>Uma entrada confirmada com uma linha por fundo (ES missões, 13.º sábado, despesas da ES), ligada a este relatório.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <dl className="grid gap-2 rounded-lg border p-3 text-sm">
            {linhas.map(([rot, v]) => <div key={rot} className="flex justify-between gap-3"><dt className="text-muted-foreground">{rot}</dt><dd><Dinheiro valor={v} /></dd></div>)}
          </dl>
          <CampoFormulario rotulo="Conta onde entra o dinheiro">
            {(a) => (
              <Seleccao {...a} value={conta} onChange={(e) => setConta(e.target.value)} disabled={contas.isPending}>
                {(contas.data ?? []).map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
              </Seleccao>
            )}
          </CampoFormulario>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button onClick={() => void submeter()} disabled={!conta || lancar.isPending}>{lancar.isPending ? t.comum.aGravar : 'Lançar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
