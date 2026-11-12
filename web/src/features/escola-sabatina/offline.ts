/**
 * Relatório do sábado sem rede (P-05; especificação 6.4 "Sem rede"): o relatório, a chamada e os visitantes ficam
 * no telemóvel e são enviados quando a rede volta.
 *
 *  - Pacote: tudo o que o ecrã da classe precisa (classe, sábado, alunos matriculados, relatório, chamada,
 *    visitantes), lido da API e guardado; sem rede, abre-se a última cópia.
 *  - Rascunho: o relatório como o secretário o deixou. "Guardar" põe-no na fila; a fila é enviada logo, ao voltar
 *    a rede (evento "online") e ao abrir a aplicação. O envio é retomável: cada passo feito fica gravado
 *    (relatório criado → id; visitante enviado → marcado), por isso repetir nunca duplica.
 *  - Uma recusa da base de dados (ex.: presentes acima dos matriculados) não se repete sozinha: fica no rascunho
 *    com a mensagem, para o secretário corrigir.
 */
import { useEffect, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { api, dados } from '@/api/cliente'
import { ErroApi, mensagemDe } from '@/api/erros'
import {
  lerMatriculas, lerPresencas, lerVisitantesRelatorio, matriculadoEm,
  type Classe, type ClasseTrimestre, type Presenca, type Relatorio, type Sabado, type Trimestre, type Visitante,
} from './api'
import { apagar, comCache, gravar, ler, semRede, todos } from './armazem'

export interface Aluno { membroId: number; nome: string; apelido: string }

export interface PacoteRelatorio {
  igrejaId: number
  classeTrimestre: ClasseTrimestre
  classe: Classe
  trimestre: Trimestre
  sabado: Sabado
  relatorio: Relatorio | null
  presencas: Presenca[]
  visitantes: Visitante[]
  alunos: Aluno[]
  lidoEm: string
}

export interface VisitanteNovo { local: string; nome: string; telefone?: string; convidadoPorMembroId?: number; enviado?: boolean }

export interface Numeros {
  /** null = calculado pela base de dados a partir das matrículas */
  membrosMatriculados: number | null
  membrosPresentes: number
  estudoDiario: number
  visitantes: number
  filiais: number
  oferta: string
  oferta13Sabado: string
  ofertaDespesas: string
  observacoes: string
}

export interface Rascunho {
  chave: string
  igrejaId: number
  classeTrimestreId: number
  sabadoId: number
  /** rótulos para a lista "por enviar" sem ter de ler o pacote */
  classeNome: string
  sabadoData: string
  relatorioId?: number
  /** alunos matriculados nesse sábado (M.M. "pelas matrículas" num relatório que já existe) */
  matriculadosPelasMatriculas: number
  numeros: Numeros
  /** chamada nominal: membroId → presença; null = sem chamada nominal (números à mão) */
  chamada: Record<string, { presente: boolean; estudouLicao: boolean }> | null
  visitantesNovos: VisitanteNovo[]
  /** true = o secretário carregou em Guardar e ainda não chegou à base de dados */
  porEnviar: boolean
  actualizadoEm: string
  erro?: string
  /** Idempotency-Key do POST que cria o relatório (repetir depois de a resposta se perder não duplica) */
  chaveCriar?: string
  /** modificadoEm do relatório em que este rascunho se baseou: se mudou na base, outra pessoa alterou-o */
  baseModificadoEm?: string
  /** outra pessoa alterou (ou criou) o relatório entretanto: o envio espera pela decisão do secretário */
  conflito?: boolean
  /** o secretário decidiu gravar por cima do que outra pessoa gravou */
  forcar?: boolean
}

export const chaveRelatorio = (classeTrimestre: number, sabado: number) => `${classeTrimestre}:${sabado}`

// ------------------------------------------------------------------ pacote

async function lerMembros(igreja: number) {
  const r = await dados(api.GET('/v1/secretaria/membros-basico', { params: { query: { igrejaId: igreja } } }))
  return r as unknown as { id: number; nome: string; apelido: string }[]
}

/** Membros da igreja (nomes dos alunos), lidos uma vez para todas as classes do sábado. */
let membrosEmCurso: { igreja: number; promessa: Promise<{ id: number; nome: string; apelido: string }[]>; em: number } | null = null
function membrosDaIgreja(igreja: number) {
  if (!membrosEmCurso || membrosEmCurso.igreja !== igreja || Date.now() - membrosEmCurso.em > 60_000) {
    membrosEmCurso = { igreja, promessa: lerMembros(igreja), em: Date.now() }
    membrosEmCurso.promessa.catch(() => (membrosEmCurso = null))
  }
  return membrosEmCurso.promessa
}

export async function lerPacote(igreja: number, classeTrimestreId: number, sabadoId: number): Promise<PacoteRelatorio> {
  return comCache(`pacote:${chaveRelatorio(classeTrimestreId, sabadoId)}`, async () => {
    const ct = (await dados(api.GET('/v1/escola-sabatina/classes-trimestre/{id}', { params: { path: { id: classeTrimestreId } } }))) as ClasseTrimestre
    const [classe, trimestre, sabado, matriculas, relatorios, membros] = await Promise.all([
      dados(api.GET('/v1/escola-sabatina/classes/{id}', { params: { path: { id: ct.classeId } } })) as Promise<Classe>,
      dados(api.GET('/v1/escola-sabatina/trimestres/{id}', { params: { path: { id: ct.trimestreId } } })) as Promise<Trimestre>,
      dados(api.GET('/v1/escola-sabatina/sabados/{id}', { params: { path: { id: sabadoId } } })) as Promise<Sabado>,
      lerMatriculas(ct.classeId),
      dados(api.GET('/v1/escola-sabatina/relatorios-sabado', {
        params: { query: { igrejaId: igreja, classeTrimestreId, sabadoId, limite: 5 } },
      })).then((r) => r.dados as Relatorio[]),
      membrosDaIgreja(igreja).catch(() => []),
    ])
    const relatorio = relatorios[0] ?? null
    const [presencas, visitantes] = relatorio
      ? await Promise.all([lerPresencas(igreja, relatorio.id), lerVisitantesRelatorio(relatorio.id)])
      : [[], []]
    const nomes = new Map(membros.map((m) => [m.id, m]))
    const ids = new Set(matriculas.filter((m) => matriculadoEm(m, sabado.data)).map((m) => m.membroId))
    // quem já está na chamada também aparece (ex.: saiu da classe depois deste sábado)
    for (const p of presencas) ids.add(p.membroId)
    const alunos = [...ids].map((id) => ({ membroId: id, nome: nomes.get(id)?.nome ?? `Membro n.º ${id}`, apelido: nomes.get(id)?.apelido ?? '' }))
      .sort((a, b) => `${a.nome} ${a.apelido}`.localeCompare(`${b.nome} ${b.apelido}`, 'pt'))
    return { igrejaId: igreja, classeTrimestre: ct, classe, trimestre, sabado, relatorio, presencas, visitantes, alunos, lidoEm: new Date().toISOString() }
  })
}

export function usePacote(igreja: number, classeTrimestreId: number, sabadoId: number) {
  return useQuery({
    enabled: classeTrimestreId > 0 && sabadoId > 0,
    queryKey: ['es-pacote', classeTrimestreId, sabadoId],
    queryFn: () => lerPacote(igreja, classeTrimestreId, sabadoId),
    networkMode: 'always',
    staleTime: 15_000,
  })
}

// ------------------------------------------------------------------ rascunho

export function rascunhoDoPacote(p: PacoteRelatorio): Rascunho {
  const r = p.relatorio
  const chamada = p.presencas.length
    ? Object.fromEntries(p.presencas.map((x) => [String(x.membroId), { presente: x.presente, estudouLicao: x.estudouLicao }]))
    : null
  return {
    chave: chaveRelatorio(p.classeTrimestre.id, p.sabado.id),
    igrejaId: p.igrejaId,
    classeTrimestreId: p.classeTrimestre.id,
    sabadoId: p.sabado.id,
    classeNome: p.classe.nome,
    sabadoData: p.sabado.data,
    relatorioId: r?.id,
    matriculadosPelasMatriculas: p.alunos.length,
    numeros: {
      membrosMatriculados: r ? r.membrosMatriculados : null,
      membrosPresentes: r?.membrosPresentes ?? 0,
      estudoDiario: r?.estudoDiario ?? 0,
      visitantes: r?.visitantes ?? 0,
      filiais: r?.filiais ?? 0,
      oferta: r?.oferta ?? '0.00',
      oferta13Sabado: r?.oferta13Sabado ?? '0.00',
      ofertaDespesas: r?.ofertaDespesas ?? '0.00',
      observacoes: r?.observacoes ?? '',
    },
    chamada,
    visitantesNovos: [],
    porEnviar: false,
    actualizadoEm: new Date().toISOString(),
    chaveCriar: crypto.randomUUID(),
    baseModificadoEm: r?.modificadoEm,
  }
}

export const lerRascunho = (chave: string) => ler<Rascunho>('rascunhos', chave)

export async function gravarRascunho(r: Rascunho) {
  await gravar('rascunhos', r.chave, { ...r, actualizadoEm: new Date().toISOString() })
  avisarFila()
}

export async function descartarRascunho(chave: string) {
  await apagar('rascunhos', chave)
  avisarFila()
}

export async function porEnviar(): Promise<Rascunho[]> {
  return (await todos<Rascunho>('rascunhos')).filter((r) => r.porEnviar)
}

function avisarFila() {
  window.dispatchEvent(new Event('es:fila'))
}

/** Rascunhos na fila (para o aviso "por enviar"); actualiza-se a cada mudança. */
export function usePorEnviar(): Rascunho[] {
  const [lista, setLista] = useState<Rascunho[]>([])
  useEffect(() => {
    let vivo = true
    const actualizar = () => void porEnviar().then((l) => vivo && setLista(l))
    actualizar()
    window.addEventListener('es:fila', actualizar)
    return () => { vivo = false; window.removeEventListener('es:fila', actualizar) }
  }, [])
  return lista
}

/** Há rede? (navigator.onLine e os eventos online/offline) */
export function useEmLinha(): boolean {
  const [ligado, setLigado] = useState(() => (typeof navigator === 'undefined' ? true : navigator.onLine))
  useEffect(() => {
    const on = () => setLigado(true), off = () => setLigado(false)
    window.addEventListener('online', on)
    window.addEventListener('offline', off)
    return () => { window.removeEventListener('online', on); window.removeEventListener('offline', off) }
  }, [])
  return ligado
}

// ------------------------------------------------------------------ envio

export type ResultadoEnvio = 'enviado' | 'sem-rede' | 'recusado'
const aEnviar = new Map<string, Promise<ResultadoEnvio>>()

/** Presentes e estudo diário a partir da chamada (a base de dados recalcula-os da mesma forma). */
export function contarChamada(chamada: NonNullable<Rascunho['chamada']>) {
  const v = Object.values(chamada)
  return { presentes: v.filter((x) => x.presente).length, estudaram: v.filter((x) => x.presente && x.estudouLicao).length }
}

function corpoNumeros(r: Rascunho, criar: boolean) {
  const n = r.numeros
  const contagem = r.chamada ? contarChamada(r.chamada) : null
  // M.M. vazio: ao criar, a base de dados conta as matrículas; ao alterar, envia-se a contagem das matrículas
  const mm = n.membrosMatriculados ?? (criar ? null : r.matriculadosPelasMatriculas)
  return {
    ...(mm != null ? { membrosMatriculados: mm } : {}),
    membrosPresentes: contagem?.presentes ?? n.membrosPresentes,
    estudoDiario: contagem?.estudaram ?? n.estudoDiario,
    visitantes: n.visitantes,
    filiais: n.filiais,
    oferta: n.oferta || '0.00',
    oferta13Sabado: n.oferta13Sabado || '0.00',
    ofertaDespesas: n.ofertaDespesas || '0.00',
    observacoes: n.observacoes.trim() || undefined,
  }
}

const CONFLITO = 'Outra pessoa alterou este relatório depois de o abrir neste telemóvel. Grave por cima ou descarte as suas alterações.'
const CONFLITO_CRIADO = 'Outra pessoa já registou o relatório desta classe neste sábado. Grave por cima ou descarte as suas alterações.'

async function passos(chave: string): Promise<ResultadoEnvio> {
  let r = await lerRascunho(chave)
  if (!r || !r.porEnviar) return 'enviado'
  if (r.conflito && !r.forcar) return 'recusado'
  const guardar = async (mudanca: Partial<Rascunho>) => {
    r = { ...r!, ...mudanca }
    await gravar('rascunhos', chave, r)
  }
  const relatorioDaBase = async (id: number) =>
    (await dados(api.GET('/v1/escola-sabatina/relatorios-sabado/{id}', { params: { path: { id } } }))) as Relatorio
  const alterar = async (id: number) => {
    const rel = (await dados(api.PATCH('/v1/escola-sabatina/relatorios-sabado/{id}', { params: { path: { id } }, body: corpoNumeros(r!, false) as never }))) as Relatorio
    await guardar({ baseModificadoEm: rel.modificadoEm })
  }
  try {
    if (!r.chaveCriar) await guardar({ chaveCriar: crypto.randomUUID() })
    // 1. o relatório: criar (o M.M. vazio é calculado pelas matrículas) ou alterar
    if (!r.relatorioId) {
      try {
        const criado = (await dados(api.POST('/v1/escola-sabatina/relatorios-sabado', {
          params: { header: { 'Idempotency-Key': r.chaveCriar! } },
          body: { classeTrimestreId: r.classeTrimestreId, sabadoId: r.sabadoId, ...corpoNumeros(r, true) } as never,
        }))) as Relatorio
        await guardar({ relatorioId: criado.id, baseModificadoEm: criado.modificadoEm })
      } catch (erro) {
        // outro telemóvel já o registou: só se grava por cima com a decisão do secretário
        if (!(erro instanceof ErroApi && erro.estado === 409)) throw erro
        const existentes = (await dados(api.GET('/v1/escola-sabatina/relatorios-sabado', {
          params: { query: { igrejaId: r.igrejaId, classeTrimestreId: r.classeTrimestreId, sabadoId: r.sabadoId, limite: 5 } },
        }))).dados as Relatorio[]
        if (!existentes[0]) throw erro
        if (!r.forcar) {
          await guardar({ conflito: true, erro: CONFLITO_CRIADO })
          return 'recusado'
        }
        await guardar({ relatorioId: existentes[0].id })
        await alterar(existentes[0].id)
      }
    } else {
      if (!r.forcar && r.baseModificadoEm) {
        const actual = await relatorioDaBase(r.relatorioId)
        if (actual.modificadoEm !== r.baseModificadoEm) {
          await guardar({ conflito: true, erro: CONFLITO })
          return 'recusado'
        }
      }
      await alterar(r.relatorioId)
    }
    const id = r.relatorioId!
    // 2. a chamada inteira de uma vez (a base recalcula M.P. e E.D.)
    if (r.chamada && Object.keys(r.chamada).length) {
      const lista = Object.entries(r.chamada).map(([m, p]) => ({ membroId: Number(m), presente: p.presente, estudouLicao: p.presente && p.estudouLicao }))
      const rel = (await dados(api.PUT('/v1/escola-sabatina/relatorios-sabado/{id}/presencas', { params: { path: { id } }, body: lista }))) as Relatorio
      await guardar({ baseModificadoEm: rel.modificadoEm })
    }
    // 3. os visitantes novos, um a um, cada um com a sua Idempotency-Key (repetir não duplica)
    for (const v of r.visitantesNovos.filter((x) => !x.enviado)) {
      await dados(api.POST('/v1/escola-sabatina/relatorios-sabado/{id}/visitantes', {
        params: { path: { id }, header: { 'Idempotency-Key': v.local } },
        body: { nome: v.nome, telefone: v.telefone || undefined, convidadoPorMembroId: v.convidadoPorMembroId } as never,
      }))
      await guardar({ visitantesNovos: r.visitantesNovos.map((x) => (x.local === v.local ? { ...x, enviado: true } : x)) })
    }
    await apagar('rascunhos', chave)
    window.dispatchEvent(new CustomEvent('es:enviado', { detail: chave }))
    return 'enviado'
  } catch (erro) {
    if (semRede(erro)) return 'sem-rede'
    // 401 sem sessão: tenta-se outra vez depois de entrar; o resto é a base de dados a recusar
    if (erro instanceof ErroApi && erro.estado === 401) return 'sem-rede'
    await guardar({ erro: mensagemDe(erro) })
    return 'recusado'
  } finally {
    avisarFila()
  }
}

/** Envia um rascunho que está na fila (um envio de cada vez por relatório). */
export function enviarRascunho(chave: string): Promise<ResultadoEnvio> {
  let p = aEnviar.get(chave)
  if (!p) {
    p = passos(chave).finally(() => aEnviar.delete(chave))
    aEnviar.set(chave, p)
  }
  return p
}

/** Envia toda a fila (menos os recusados, que esperam correcção). Chamado ao voltar a rede e ao abrir a aplicação. */
export async function sincronizarTudo(): Promise<void> {
  if (typeof navigator !== 'undefined' && !navigator.onLine) return
  for (const r of await porEnviar()) {
    if (r.erro || r.conflito) continue
    if ((await enviarRascunho(r.chave)) === 'sem-rede') return
  }
}
