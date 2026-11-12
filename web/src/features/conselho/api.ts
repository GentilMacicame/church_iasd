/**
 * Conselho da igreja (F-SEC-07): os oficiais com o cargo, o contacto e o estado do mandato (vista vw_conselho),
 * a duração dos mandatos da igreja (igr_mandato_anos) e o registo de oficiais. O fim previsto de cada mandato é
 * calculado pela base de dados; a vigência (ACTIVO, A_TERMINAR, TERMINADO, FUTURO) também.
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import { useIgreja } from '@/auth/sessao'

export type EstadoMandato = 'ACTIVO' | 'A_TERMINAR' | 'TERMINADO' | 'FUTURO'
/** Órgão em que o oficial serve dentro do mandato (V31): o conselho da igreja ou a direcção (departamentos). */
export type Orgao = 'CONSELHO' | 'DIRECCAO'
/** Linha de GET /v1/secretaria/conselho. */
export interface Oficial {
  id: number; igrejaId: number; membroId: number; membro: string; cargoId: number; cargo: string; doConselho: boolean
  dataInicio: string; fimPrevisto: string | null; dataFim: string | null; contacto: string | null; estadoMandato: EstadoMandato
  mandatoId: number | null; mandato: string | null; orgao: Orgao
}
/** Mandato da igreja (V31): o período em que servem os oficiais eleitos. */
export interface Mandato {
  id: number; igrejaId: number; nome: string; dataInicio: string; dataFim: string; votoId?: number | null; observacoes?: string | null; endDate?: string | null
}
export type Cargo = Esquema<'Cargo'> & { id: number; nome: string; conselho?: boolean }

const k = { todos: (igreja: number) => ['conselho', igreja] as const }

export function useConselho() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'oficiais'],
    queryFn: async () => (await dados(api.GET('/v1/secretaria/conselho', { params: { query: { igrejaId: igreja.id } } }))) as unknown as Oficial[],
  })
}

/** Quem está em exercício e faz parte do conselho (para presenças, presidente e secretário). */
export const emExercicio = (o: Oficial) => o.orgao === 'CONSELHO' && (o.estadoMandato === 'ACTIVO' || o.estadoMandato === 'A_TERMINAR')

/** O secretário das reuniões: o secretário da junta em exercício, senão o secretário da igreja. */
export function secretarioOficial(l: Oficial[] = []): Oficial | undefined {
  const activos = l.filter((o) => o.estadoMandato === 'ACTIVO' || o.estadoMandato === 'A_TERMINAR')
  return activos.find((o) => /secret[aá]rio\(a\) da junta/i.test(o.cargo)) ?? activos.find((o) => /secret[aá]rio\(a\) da igreja/i.test(o.cargo))
}

/** Mandatos da igreja escolhida, do mais recente para o mais antigo. */
export function useMandatos() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'mandatos'],
    queryFn: async () => ((await dados(api.GET('/v1/secretaria/mandatos', { params: { query: { igrejaId: igreja.id, limite: 200 } } }))).dados as Mandato[])
      .filter((m) => !m.endDate).sort((a, b) => b.dataInicio.localeCompare(a.dataInicio)),
  })
}

/** Vigência de um mandato em relação a hoje. */
export function vigencia(m: Pick<Mandato, 'dataInicio' | 'dataFim'>, hoje = new Date().toISOString().slice(0, 10)): EstadoMandato {
  if (m.dataInicio > hoje) return 'FUTURO'
  if (m.dataFim < hoje) return 'TERMINADO'
  const limite = new Date(Date.parse(hoje + 'T12:00:00Z') + 60 * 86_400_000).toISOString().slice(0, 10)
  return m.dataFim < limite ? 'A_TERMINAR' : 'ACTIVO'
}

/** Último dia de um mandato que começa em `inicio` e dura `anos` (o mesmo cálculo da base de dados). */
export function fimDoMandato(inicio: string, anos: number) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(inicio)) return ''
  const d = new Date(`${inicio}T12:00:00Z`)
  d.setUTCFullYear(d.getUTCFullYear() + anos)
  d.setUTCDate(d.getUTCDate() - 1)
  return d.toISOString().slice(0, 10)
}

export function useCargos() {
  return useQuery({
    queryKey: ['organizacao', 'cargos'],
    queryFn: async () => (await dados(api.GET('/v1/organizacao/cargos', { params: { query: { limite: 200 } } }))).dados as Cargo[],
    staleTime: 30 * 60_000,
  })
}

/** A igreja escolhida (para a duração dos mandatos). */
export function useIgrejaDados() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'igreja'],
    queryFn: async () => (await dados(api.GET('/v1/organizacao/igrejas/{id}', { params: { path: { id: igreja.id } } }))) as Esquema<'Igreja'> & { mandatoAnos?: number },
  })
}

export function useConselhoMut() {
  const qc = useQueryClient()
  const igreja = useIgreja()
  const invalidar = () => qc.invalidateQueries({ queryKey: k.todos(igreja.id) })
  const registar = useMutation({
    mutationFn: (c: { membroId: number; cargoId: number; dataInicio?: string; fimPrevisto?: string | null; votoId?: number; mandatoId?: number; orgao?: Orgao }) =>
      dados(api.POST('/v1/secretaria/oficiais', { body: { ...c, igrejaId: igreja.id, fimPrevisto: c.fimPrevisto || undefined } as never })),
    onSuccess: invalidar,
  })
  /** Terminar o mandato na data indicada (o registo fica no histórico). */
  const terminarMandato = useMutation({
    mutationFn: ({ id, dataFim }: { id: number; dataFim: string }) =>
      dados(api.PATCH('/v1/secretaria/oficiais/{id}', { params: { path: { id } }, body: { dataFim } as never })),
    onSuccess: invalidar,
  })
  const corrigir = useMutation({
    mutationFn: ({ id, ...corpo }: { id: number; dataInicio?: string; fimPrevisto?: string | null; orgao?: Orgao; mandatoId?: number }) =>
      dados(api.PATCH('/v1/secretaria/oficiais/{id}', { params: { path: { id } }, body: corpo as never })),
    onSuccess: invalidar,
  })
  /** Registo feito por engano: termina-o (nada se apaga). */
  const anular = useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/secretaria/oficiais/{id}/terminar', { params: { path: { id } } })),
    onSuccess: invalidar,
  })
  const duracao = useMutation({
    mutationFn: (mandatoAnos: number) => dados(api.PATCH('/v1/organizacao/igrejas/{id}', { params: { path: { id: igreja.id } }, body: { mandatoAnos } as never })),
    onSuccess: invalidar,
  })
  const criarMandato = useMutation({
    mutationFn: async (c: { nome: string; dataInicio: string; dataFim: string; votoId?: number; observacoes?: string }) =>
      (await dados(api.POST('/v1/secretaria/mandatos', { body: { ...c, igrejaId: igreja.id } as never }))) as unknown as Mandato,
    onSuccess: invalidar,
  })
  const alterarMandato = useMutation({
    mutationFn: ({ id, ...corpo }: { id: number; nome?: string; dataInicio?: string; dataFim?: string; votoId?: number | null; observacoes?: string | null }) =>
      dados(api.PATCH('/v1/secretaria/mandatos/{id}', { params: { path: { id } }, body: corpo as never })),
    onSuccess: invalidar,
  })
  /** Mandato criado por engano (sem oficiais): termina-o (nada se apaga). */
  const anularMandato = useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/secretaria/mandatos/{id}/terminar', { params: { path: { id } } })),
    onSuccess: invalidar,
  })
  return { registar, terminarMandato, corrigir, anular, duracao, criarMandato, alterarMandato, anularMandato }
}

export const ROTULO_ORGAO: Record<Orgao, string> = { CONSELHO: 'Conselho da igreja', DIRECCAO: 'Direcção' }
export const ROTULO_MANDATO: Record<EstadoMandato, string> = { ACTIVO: 'Em exercício', A_TERMINAR: 'A terminar', TERMINADO: 'Terminado', FUTURO: 'Ainda não começou' }
export const VARIANTE_MANDATO: Record<EstadoMandato, 'success' | 'warning' | 'secondary' | 'info'> = { ACTIVO: 'success', A_TERMINAR: 'warning', TERMINADO: 'secondary', FUTURO: 'info' }
