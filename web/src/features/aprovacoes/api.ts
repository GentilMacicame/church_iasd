/**
 * Aprovações e conferências (V54). Cada despesa, saída de dinheiro, contagem, orçamento, admissão e remoção de membro
 * segue um fluxo de etapas (quem aprecia, quem confere, que órgão vota), configurável por natureza e por valor.
 * Quem decide cada etapa, a ordem e "tem de ser outra pessoa" são da base de dados (nucleo.fn_aprovacao_decidir);
 * o ecrã só mostra o estado, quem é o responsável da próxima acção e as etapas que faltam.
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import type { paths } from '@/api/esquema'
import { useIgreja } from '@/auth/sessao'

export type Processo = Esquema<'EnumProcessoAprovacao'>
export type EstadoAprovacao = Esquema<'EnumEstadoAprovacao'>
export type AccaoEtapa = Esquema<'EnumAccaoEtapa'>
export type ResponsavelEtapa = Esquema<'EnumResponsavelEtapa'>
export type TipoReuniao = NonNullable<Esquema<'Reuniao'>['tipo']>
export type Fluxo = Esquema<'FluxoAprovacao'> & { id: number; processo: Processo; nome: string; valorMinimo: string }
export type Etapa = Esquema<'FluxoEtapa'> & { id: number; fluxoAprovacaoId: number; ordem: number; nome: string; responsavel: ResponsavelEtapa }

/** Uma linha de nucleo.vw_aprovacoes: o processo, a etapa em curso e quem a decide. */
export interface ProcessoAprovacao {
  id: number; igrejaId: number; igreja: string; processo: Processo; assunto: string; valor: string | null; estado: EstadoAprovacao
  fluxoId: number; fluxo: string; etapa: number; totalEtapas: number
  etapaId: number | null; etapaNome: string | null; etapaAccao: AccaoEtapa | null; responsavelTipo: ResponsavelEtapa | null
  orgao: TipoReuniao | null; responsavel: string | null; responsaveis: string | null; podeDecidir: boolean
  despesaId: number | null; transacaoId: number | null; contagemId: number | null; orcamentoId: number | null; membroId: number | null
  pedidoPor: string | null; criadoEm: string; concluidoEm: string | null
}

/** Uma linha de nucleo.vw_aprovacao_etapas. */
export interface EtapaProcesso {
  aprovacaoId: number; etapaId: number; ordem: number; nome: string; accao: AccaoEtapa; responsavelTipo: ResponsavelEtapa
  orgao: TipoReuniao | null; responsavel: string | null; situacao: 'APROVADA' | 'REJEITADA' | 'EM_CURSO' | 'PENDENTE' | 'NAO_DECIDIDA'
  responsaveis: string | null; decididoPor: string | null; decididoEm: string | null; votoNumero: string | null; votoId: number | null
  motivo: string | null; valorAprovado: string | null
}

export const PROCESSOS: Record<Processo, { rotulo: string; plural: string; ler: string }> = {
  DESPESA: { rotulo: 'Despesa', plural: 'Despesas', ler: 'tesouraria.despesa.ler' },
  SAIDA: { rotulo: 'Saída de dinheiro', plural: 'Saídas de dinheiro', ler: 'tesouraria.transacao.ler' },
  CONTAGEM: { rotulo: 'Conferência da contagem', plural: 'Contagens', ler: 'tesouraria.contagem_numerario.ler' },
  ORCAMENTO: { rotulo: 'Orçamento', plural: 'Orçamentos', ler: 'tesouraria.orcamento.ler' },
  ADMISSAO_MEMBRO: { rotulo: 'Admissão de membro', plural: 'Admissões de membros', ler: 'secretaria.movimento_membro.ler' },
  REMOCAO_MEMBRO: { rotulo: 'Remoção de membro', plural: 'Remoções de membros', ler: 'secretaria.movimento_membro.ler' },
}
export { PERMISSOES_APROVACOES } from './permissoes'

export const ACCOES: Record<AccaoEtapa, string> = {
  APRECIAR: 'Aprecia', CONFERIR: 'Confere', RECOMENDAR: 'Recomenda', APROVAR: 'Aprova', VOTAR: 'Vota',
}
export const ESTADOS: Record<EstadoAprovacao, { rotulo: string; variante: 'warning' | 'success' | 'destructive' | 'secondary' }> = {
  EM_CURSO: { rotulo: 'Em curso', variante: 'warning' }, APROVADO: { rotulo: 'Aprovado', variante: 'success' },
  REJEITADO: { rotulo: 'Rejeitado', variante: 'destructive' }, CANCELADO: { rotulo: 'Cancelado', variante: 'secondary' },
}
export const RESPONSAVEIS: Record<ResponsavelEtapa, string> = {
  PERFIL: 'Um perfil', PERMISSAO: 'Quem tem uma permissão', ORGAO: 'Um órgão, por voto em reunião',
}
/** Órgãos que votam (tipos de reunião). */
export const ORGAOS: Record<TipoReuniao, string> = {
  JUNTA_DIRECTIVA: 'Conselho da Igreja (junta directiva)', REUNIAO_REGULAR: 'Igreja em reunião regular',
  ASSEMBLEIA_ADMINISTRATIVA: 'Igreja em reunião administrativa', COMISSAO_NOMEACOES: 'Comissão de nomeações',
  CONSELHO_ES: 'Conselho da Escola Sabatina',
}

const k = { todos: (igreja: number) => ['aprovacoes', igreja] as const }

type Filtro = Partial<Record<'despesaId' | 'transacaoId' | 'contagemId' | 'orcamentoId' | 'membroId', number>>

/** Os processos da igreja (em curso primeiro). Com um filtro, só os desse objecto (o último é o mais recente). */
export function useAprovacoes(filtro: Filtro = {}, activo = true) {
  const igreja = useIgreja()
  return useQuery({
    enabled: activo,
    queryKey: [...k.todos(igreja.id), 'lista', filtro],
    queryFn: async () => (await dados(api.GET('/v1/nucleo/acompanhamento-aprovacoes', {
      params: { query: { igrejaId: igreja.id, ...filtro } as never },
    }))) as unknown as ProcessoAprovacao[],
  })
}

/** O processo mais recente de um objecto (o em curso, se houver). */
export function useAprovacaoDe(filtro: Filtro, activo = true) {
  const q = useAprovacoes(filtro, activo)
  const lista = q.data ?? []
  return { ...q, data: lista.find((p) => p.estado === 'EM_CURSO') ?? lista[0] ?? null }
}

export function useEtapasProcesso(aprovacaoId: number | null | undefined) {
  const igreja = useIgreja()
  return useQuery({
    enabled: !!aprovacaoId,
    queryKey: [...k.todos(igreja.id), 'etapas', aprovacaoId],
    queryFn: async () => (await dados(api.GET('/v1/nucleo/etapas-aprovacao', {
      params: { query: { aprovacaoId } as never },
    }))) as unknown as EtapaProcesso[],
  })
}

/** Decide a etapa em curso. Etapas de um órgão: o voto da reunião (a decisão é o resultado do voto). */
export function useDecidir() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, ...corpo }: { id: number; aprovar?: boolean; votoId?: number; motivo?: string; valor?: string }) =>
      dados(api.POST('/v1/nucleo/aprovacoes/{id}/decidir', { params: { path: { id } }, body: corpo })) as Promise<{ estado: EstadoAprovacao }>,
    // a decisão final muda o objecto (despesa aprovada, contagem conferida, ...): actualiza tudo o que está no ecrã
    onSuccess: () => qc.invalidateQueries(),
  })
}

/* ===================================================================== configuração dos fluxos */
type Corpo<P extends keyof paths, M extends 'post' | 'patch'> = paths[P][M] extends { requestBody?: { content: { 'application/json': infer B } } } ? B : never

/** Os fluxos que se aplicam à igreja: os dela e os modelos da Associação (igrejaId vazio). */
export function useFluxos() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: ['fluxos-aprovacao', igreja.id],
    queryFn: async () => (await dados(api.GET('/v1/nucleo/fluxos-aprovacao', { params: { query: { limite: 200 } as never } }))).dados as Fluxo[],
    select: (l: Fluxo[]) => l.filter((f) => !f.endDate && (f.igrejaId == null || f.igrejaId === igreja.id)),
  })
}

export function useEtapasFluxos() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: ['fluxos-aprovacao', igreja.id, 'etapas'],
    queryFn: async () => (await dados(api.GET('/v1/nucleo/etapas-fluxo', { params: { query: { limite: 200 } as never } }))).dados as Etapa[],
    select: (l: Etapa[]) => l.filter((e) => !e.endDate && (e.igrejaId == null || e.igrejaId === igreja.id)).sort((a, b) => a.ordem - b.ordem),
  })
}

export function useFluxosMut() {
  const qc = useQueryClient()
  const actualizar = () => qc.invalidateQueries({ queryKey: ['fluxos-aprovacao'] })
  const criarFluxo = useMutation({
    mutationFn: (corpo: Corpo<'/v1/nucleo/fluxos-aprovacao', 'post'>) => dados(api.POST('/v1/nucleo/fluxos-aprovacao', { body: corpo })) as Promise<Fluxo>,
    onSuccess: actualizar,
  })
  const alterarFluxo = useMutation({
    mutationFn: ({ id, ...corpo }: { id: number } & Corpo<'/v1/nucleo/fluxos-aprovacao/{id}', 'patch'>) =>
      dados(api.PATCH('/v1/nucleo/fluxos-aprovacao/{id}', { params: { path: { id } }, body: corpo })),
    onSuccess: actualizar,
  })
  const terminarFluxo = useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/nucleo/fluxos-aprovacao/{id}/terminar', { params: { path: { id } } })),
    onSuccess: actualizar,
  })
  const criarEtapa = useMutation({
    mutationFn: (corpo: Corpo<'/v1/nucleo/etapas-fluxo', 'post'>) => dados(api.POST('/v1/nucleo/etapas-fluxo', { body: corpo })) as Promise<Etapa>,
    onSuccess: actualizar,
  })
  const alterarEtapa = useMutation({
    mutationFn: ({ id, ...corpo }: { id: number } & Corpo<'/v1/nucleo/etapas-fluxo/{id}', 'patch'>) =>
      dados(api.PATCH('/v1/nucleo/etapas-fluxo/{id}', { params: { path: { id } }, body: corpo })),
    onSuccess: actualizar,
  })
  const terminarEtapa = useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/nucleo/etapas-fluxo/{id}/terminar', { params: { path: { id } } })),
    onSuccess: actualizar,
  })
  return { criarFluxo, alterarFluxo, terminarFluxo, criarEtapa, alterarEtapa, terminarEtapa }
}
