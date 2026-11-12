/**
 * Relatório de uma classe num sábado (P-05; F-ES-04, F-ES-05, F-ES-06) · pensado para o telemóvel e sem rede.
 * Números (M.M., M.P., E.D., visitantes, filiais), chamada com botões grandes, visitantes e as três ofertas.
 * Tudo fica no telemóvel; "Guardar" envia (ou deixa na fila até haver rede). Com o relatório na base de dados:
 * o tesoureiro lança as ofertas (P-05 passo 5) e o secretário fecha (passo 6); só o director reabre.
 */
import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useQueryClient } from '@tanstack/react-query'
import {
  ArrowLeft, BookOpen, Check, CheckCheck, Coins, Landmark, Lock, LockOpen, Minus, Plus, Trash2, UserPlus, Users,
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
import { centimos, data, deCentimos } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { useContasIgreja } from '@/features/tesouraria/api'
import { useFecharRelatorio, useLancarOfertas, useReabrirRelatorio, type Relatorio } from './api'
import {
  chaveRelatorio, contarChamada, descartarRascunho, enviarRascunho, gravarRascunho, lerRascunho, rascunhoDoPacote, useEmLinha, usePacote,
  type Numeros, type PacoteRelatorio, type Rascunho,
} from './offline'
import { AvisosRede } from './PaginaSabado'

/** Número com botões − e + grandes (alvos de 44px), para o polegar. */
function Contador({ rotulo, sigla, valor, aoMudar, desactivado, ajuda, max }: {
  rotulo: string; sigla?: string; valor: number; aoMudar: (v: number) => void; desactivado?: boolean; ajuda?: ReactNode; max?: number
}) {
  const id = `n-${rotulo.replace(/\W/g, '')}`
  return (
    <div className="grid gap-1.5">
      <label htmlFor={id} className="text-sm font-medium">
        {rotulo}{sigla && <span className="ml-1 text-xs font-normal text-muted-foreground">({sigla})</span>}
      </label>
      <div className="flex items-center gap-2">
        <Button type="button" variant="outline" size="icon" className="size-11 flex-none" aria-label={`Menos ${rotulo.toLowerCase()}`}
          disabled={desactivado || valor <= 0} onClick={() => aoMudar(Math.max(0, valor - 1))}><Minus className="size-4" /></Button>
        <Input id={id} inputMode="numeric" value={String(valor)} disabled={desactivado}
          onChange={(e) => { const n = Number(e.target.value.replace(/\D/g, '') || 0); aoMudar(Math.min(n, 9999)) }}
          className="num h-11 min-w-0 text-center text-lg font-semibold" />
        <Button type="button" variant="outline" size="icon" className="size-11 flex-none" aria-label={`Mais ${rotulo.toLowerCase()}`}
          disabled={desactivado || (max != null && valor >= max)} onClick={() => aoMudar(valor + 1)}><Plus className="size-4" /></Button>
      </div>
      {ajuda && <p className="text-xs text-muted-foreground">{ajuda}</p>}
    </div>
  )
}

/** Botão grande de ligar/desligar (chamada). */
function Alternar({ ligado, aoMudar, children, desactivado, tom = 'primary' }: {
  ligado: boolean; aoMudar: (v: boolean) => void; children: ReactNode; desactivado?: boolean; tom?: 'primary' | 'success'
}) {
  return (
    <button type="button" aria-pressed={ligado} disabled={desactivado} onClick={() => aoMudar(!ligado)}
      className={cn(
        'alvo inline-flex min-h-11 min-w-[6.5rem] items-center justify-center gap-1.5 rounded-lg border px-3 text-sm font-medium transition-colors disabled:opacity-40',
        ligado
          ? tom === 'success' ? 'border-success/40 bg-tint-success text-success-text' : 'border-primary bg-primary text-primary-foreground'
          : 'border-input bg-card text-muted-foreground hover:bg-muted',
      )}>
      {ligado && <Check className="size-4" aria-hidden />}{children}
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
        toast.error(t.es.recusado)
      }
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

  return (
    <div className="mx-auto grid max-w-3xl gap-4 pb-24">
      <TituloPagina
        antes={<Link to={`/escola-sabatina/sabado?trimestre=${p.trimestre.id}&sabado=${p.sabado.id}`} className="alvo mb-3 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" />{t.es.sabado}</Link>}
        icone={BookOpen}
        titulo={p.classe.nome}
        descricao={<>
          {rotulos.divisao[p.classe.divisao]} · {p.sabado.numero}.º sábado · {data(p.sabado.data)}
          {p.sabado.decimoTerceiro && <> · <strong className="font-medium text-foreground">13.º sábado</strong></>}
        </>}
        accoes={<span className="flex flex-wrap gap-1.5">
          {r.erro ? <Pilula variante="destructive">Recusado</Pilula> : r.porEnviar ? <Pilula variante="info">Por enviar</Pilula> : alterado ? <Pilula variante="warning">Por guardar</Pilula> : null}
          {rel ? <Pilula variante={fechado ? 'success' : 'warning'}>{rotulos.estadoRelatorio[rel.estado]}</Pilula> : <Pilula variante="outline">Novo</Pilula>}
        </span>}
      />
      <AvisosRede />
      {r.erro && <ErroFormulario mensagem={r.erro} />}
      {fechado && (
        <div role="status" className="flex items-start gap-2 rounded-lg border border-success/20 bg-tint-success px-4 py-3 text-sm text-success-text">
          <Lock className="mt-0.5 size-4 flex-none" aria-hidden />
          <p>Relatório fechado: as ofertas estão conferidas com a tesouraria. Para corrigir, o director da ES reabre-o.</p>
        </div>
      )}

      <Cartao titulo="Números do sábado" icone={Users}>
        <div className="grid gap-5 sm:grid-cols-2">
          <div className="grid gap-1.5">
            <Contador rotulo="Membros matriculados" sigla="M.M." valor={matriculados} desactivado={fechado || r.numeros.membrosMatriculados == null}
              aoMudar={(v) => mudarNumero('membrosMatriculados', v)} />
            {!fechado && (
              <button type="button" className="alvo justify-self-start text-xs font-medium text-primary hover:underline"
                onClick={() => mudarNumero('membrosMatriculados', r.numeros.membrosMatriculados == null ? p.alunos.length : null)}>
                {r.numeros.membrosMatriculados == null ? `Calculado pelas matrículas (${p.alunos.length}) · indicar à mão` : 'Usar as matrículas'}
              </button>
            )}
          </div>
          <Contador rotulo="Membros presentes" sigla="M.P." valor={presentes} desactivado={fechado || !!chamada}
            aoMudar={(v) => mudarNumero('membrosPresentes', v)} ajuda={chamada ? 'Contado pela chamada' : undefined} />
          <Contador rotulo="Estudo diário" sigla="E.D." valor={estudaram} desactivado={fechado || !!chamada} max={presentes}
            aoMudar={(v) => mudarNumero('estudoDiario', v)} ajuda={chamada ? 'Contado pela chamada' : 'Quantos estudaram a lição todos os dias'} />
          <Contador rotulo="Visitantes" valor={r.numeros.visitantes} desactivado={fechado} aoMudar={(v) => mudarNumero('visitantes', v)} />
          <Contador rotulo="Filiais" valor={r.numeros.filiais} desactivado={fechado} aoMudar={(v) => mudarNumero('filiais', v)} ajuda="Escolas sabatinas filiais dirigidas pela classe" />
        </div>
        {presentes > matriculados && (
          <p className="mt-4 text-xs font-medium text-warning-text">Há mais presentes do que matriculados: a base de dados não aceita. Corrija o M.M. ou os presentes.</p>
        )}
      </Cartao>

      <Chamada p={p} r={r} fechado={fechado} mudar={mudar} />

      <Visitantes p={p} r={r} fechado={fechado} mudar={mudar} />

      <Cartao titulo="Ofertas" descricao={t.es.separadas} icone={Coins}>
        <div className="grid gap-4 sm:grid-cols-3">
          {([['oferta', t.es.oferta], ['oferta13Sabado', t.es.oferta13], ['ofertaDespesas', t.es.ofertaDespesas]] as const).map(([k, rotulo]) => (
            <CampoFormulario key={k} rotulo={rotulo}>
              {(a) => <CampoDinheiro {...a} value={r.numeros[k]} disabled={fechado} onChange={(v) => mudarNumero(k, v)} className="h-11 text-base" />}
            </CampoFormulario>
          ))}
        </div>
        <p className="mt-4 flex justify-between border-t pt-3 text-sm"><span className="text-muted-foreground">Total</span><Dinheiro valor={deCentimos(totalOfertas)} className="font-semibold" /></p>
        <CampoFormulario rotulo="Observações" className="mt-4">
          {(a) => <Textarea {...a} rows={2} maxLength={500} value={r.numeros.observacoes} disabled={fechado} onChange={(e) => mudarNumero('observacoes', e.target.value)} />}
        </CampoFormulario>
      </Cartao>

      {rel && <Tesouraria rel={rel} emLinha={emLinha} porGuardar={alterado || r.porEnviar} />}

      {!fechado && (
        <div className="fixed inset-x-0 bottom-0 z-20 border-t bg-background/95 px-4 py-3 backdrop-blur lg:left-[var(--sidebar-width)]">
          <div className="mx-auto flex max-w-3xl items-center justify-end gap-2">
            {(alterado || r.porEnviar) && (
              <Button type="button" variant="ghost" className="alvo mr-auto" onClick={() => void desfazer()}>Desfazer alterações</Button>
            )}
            <Button type="button" className="alvo h-11 min-w-40" disabled={aEnviar} onClick={() => void guardar()}>
              {aEnviar ? t.comum.aGravar : emLinha ? 'Guardar relatório' : 'Guardar no telemóvel'}
            </Button>
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
    <Cartao titulo="Chamada" icone={CheckCheck}
      descricao={chamada ? `${contagem!.presentes} presentes · ${contagem!.estudaram} estudaram a lição` : 'Opcional: marca quem veio e quem estudou; os números contam-se sozinhos.'}
      accoes={!fechado && chamada && p.presencas.length === 0 && (
        <Button type="button" variant="ghost" size="sm" onClick={() => setConfirmarTirar(true)}>Sem chamada</Button>
      )}>
      {p.alunos.length === 0 ? (
        <p className="text-sm text-muted-foreground">
          A classe não tem alunos matriculados neste sábado. <Link to={`/escola-sabatina/classes/${p.classe.id}`} className="font-medium text-primary hover:underline">Matricular alunos</Link>
        </p>
      ) : !chamada ? (
        <Button type="button" variant="outline" className="alvo justify-self-start" disabled={fechado} onClick={comecar}>
          <CheckCheck className="size-4" />Fazer a chamada ({p.alunos.length} alunos)
        </Button>
      ) : (
        <>
          {!fechado && <Button type="button" variant="outline" size="sm" className="alvo mb-3 justify-self-start" onClick={todos}>Marcar todos presentes</Button>}
          <ul className="-mx-5 divide-y border-y sm:-mx-6">
            {p.alunos.map((a) => {
              const v = chamada[a.membroId] ?? { presente: false, estudouLicao: false }
              return (
                <li key={a.membroId} className="flex flex-wrap items-center gap-x-3 gap-y-2 px-5 py-2.5 sm:px-6">
                  <span className="flex min-w-0 flex-1 basis-40 items-center gap-2.5">
                    <Avatar id={a.membroId} nome={a.nome} apelido={a.apelido} tamanho={30} />
                    <span className="truncate text-sm font-medium">{a.nome} {a.apelido}</span>
                  </span>
                  <span className="flex gap-2">
                    <Alternar ligado={v.presente} desactivado={fechado} aoMudar={(x) => marcar(a.membroId, 'presente', x)}>Presente</Alternar>
                    <Alternar ligado={v.estudouLicao} desactivado={fechado} tom="success" aoMudar={(x) => marcar(a.membroId, 'estudouLicao', x)}>Estudou</Alternar>
                  </span>
                </li>
              )
            })}
          </ul>
        </>
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
    <Cartao titulo="Visitantes" icone={UserPlus} descricao="Nome e contacto para o seguimento (anonimizados ao fim de 12 meses se não se tornarem membros).">
      {total > 0 && (
        <ul className="-mx-5 mb-4 divide-y border-y sm:-mx-6">
          {p.visitantes.map((v) => (
            <li key={v.id} className="flex items-center gap-3 px-5 py-2.5 text-sm sm:px-6">
              <span className="min-w-0 flex-1"><span className="font-medium">{v.nome}</span>{v.telefone && <span className="text-muted-foreground"> · {v.telefone}</span>}</span>
              {v.convidadoPorMembroId && <span className="hidden text-xs text-muted-foreground sm:inline">convidado por {nomeDe(v.convidadoPorMembroId) ?? '—'}</span>}
            </li>
          ))}
          {novos.map((v) => (
            <li key={v.local} className="flex items-center gap-3 px-5 py-2.5 text-sm sm:px-6">
              <span className="min-w-0 flex-1"><span className="font-medium">{v.nome}</span>{v.telefone && <span className="text-muted-foreground"> · {v.telefone}</span>}</span>
              <Pilula variante="info">Por enviar</Pilula>
              {!fechado && (
                <Button type="button" variant="ghost" size="icon" className="size-11" aria-label={`Tirar ${v.nome}`}
                  onClick={() => mudar((x) => ({ ...x, visitantesNovos: x.visitantesNovos.filter((y) => y.local !== v.local) }))}>
                  <Trash2 className="size-4" />
                </Button>
              )}
            </li>
          ))}
        </ul>
      )}
      {!fechado && (
        <div className="grid gap-3">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-3 sm:grid-cols-2">
            <CampoFormulario rotulo="Nome do visitante">
              {(a) => <Input {...a} value={nome} onChange={(e) => setNome(e.target.value)} maxLength={150} className="h-11" />}
            </CampoFormulario>
            <CampoFormulario rotulo="Telefone">
              {(a) => <Input {...a} value={telefone} onChange={(e) => setTelefone(e.target.value)} inputMode="tel" maxLength={20} className="h-11" />}
            </CampoFormulario>
            <CampoFormulario rotulo="Convidado por" className="sm:col-span-2">
              {(a) => <CampoMembro id={a.id} valor={convidou} aoMudar={setConvidou} nomeDe={nomeDe} vazio="Ninguém / não sabe" />}
            </CampoFormulario>
          </div>
          <Button type="button" variant="outline" className="alvo justify-self-start" onClick={juntar}><Plus className="size-4" />Juntar visitante</Button>
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
