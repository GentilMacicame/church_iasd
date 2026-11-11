/**
 * Conselho da igreja (F-SEC-07): os oficiais com o cargo, o contacto e o estado do mandato (vista vw_conselho),
 * a duração dos mandatos da igreja (igr_mandato_anos) e o registo de oficiais. O fim previsto de cada mandato é
 * calculado pela base de dados; a vigência (ACTIVO, A_TERMINAR, TERMINADO, FUTURO) também.
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import { useIgreja } from '@/auth/sessao'

export type EstadoMandato = 'ACTIVO' | 'A_TERMINAR' | 'TERMINADO' | 'FUTURO'
/** Linha de GET /v1/secretaria/conselho. */
export interface Oficial {
  id: number; igrejaId: number; membroId: number; membro: string; cargoId: number; cargo: string; doConselho: boolean
  dataInicio: string; fimPrevisto: string | null; dataFim: string | null; contacto: string | null; estadoMandato: EstadoMandato
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
export const emExercicio = (o: Oficial) => o.doConselho && (o.estadoMandato === 'ACTIVO' || o.estadoMandato === 'A_TERMINAR')

/** O secretário das reuniões: o secretário da junta em exercício, senão o secretário da igreja. */
export function secretarioOficial(l: Oficial[] = []): Oficial | undefined {
  const activos = l.filter((o) => o.estadoMandato === 'ACTIVO' || o.estadoMandato === 'A_TERMINAR')
  return activos.find((o) => /secret[aá]rio\(a\) da junta/i.test(o.cargo)) ?? activos.find((o) => /secret[aá]rio\(a\) da igreja/i.test(o.cargo))
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
    mutationFn: (c: { membroId: number; cargoId: number; dataInicio: string; fimPrevisto?: string | null }) =>
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
    mutationFn: ({ id, ...corpo }: { id: number; dataInicio?: string; fimPrevisto?: string | null }) =>
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
  return { registar, terminarMandato, corrigir, anular, duracao }
}

export const ROTULO_MANDATO: Record<EstadoMandato, string> = { ACTIVO: 'Em exercício', A_TERMINAR: 'A terminar', TERMINADO: 'Terminado', FUTURO: 'Ainda não começou' }
export const VARIANTE_MANDATO: Record<EstadoMandato, 'success' | 'warning' | 'secondary' | 'info'> = { ACTIVO: 'success', A_TERMINAR: 'warning', TERMINADO: 'secondary', FUTURO: 'info' }
