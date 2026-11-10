/**
 * Dados das escalas (F-ACT-03): planos (a escala de um período), dias (um por sábado) e as pessoas escaladas.
 * As regras (data e igreja vêm do dia, só escalas publicadas geram lembretes, quem pode elaborar) são da base
 * de dados; aqui só se lê e grava.
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import type { paths } from '@/api/esquema'
import { useIgreja } from '@/auth/sessao'
import { hojeIso } from '@/lib/formatos'

export type Plano = Esquema<'EscalaPlano'> & { id: number; titulo: string; dataInicio: string; dataFim: string }
export type Dia = Esquema<'EscalaDia'> & { id: number; data: string; escalaPlanoId: number }
export type Escalado = Esquema<'Escala'> & { id: number; funcao: FuncaoEscala; membroId: number }
export type FuncaoEscala = NonNullable<Esquema<'Escala'>['funcao']>
type Corpo<P extends keyof paths, M extends 'post' | 'patch'> = paths[P][M] extends { requestBody?: { content: { 'application/json': infer C } } } ? C : never

/** A escala cobre hoje? */
export function emVigor(p: Plano) {
  const hoje = hojeIso()
  return p.dataInicio <= hoje && hoje <= p.dataFim
}

/** As colunas da escala de pregação (como na escala em papel). */
export const COLUNAS: FuncaoEscala[] = ['PREGADOR', 'TRADUTOR', 'ACOMPANHANTE_VISITAS', 'ACOMPANHANTE_OFERTAS', 'ACOMPANHANTE_BOAS_VINDAS']

const chaves = {
  planos: (igreja: number) => ['escalas', igreja, 'planos'] as const,
  plano: (id: number) => ['escala', id] as const,
  dias: (id: number) => ['escala', id, 'dias'] as const,
  escalados: (id: number) => ['escala', id, 'escalados'] as const,
}

export function usePlanos() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: chaves.planos(igreja.id),
    queryFn: async () =>
      (await dados(api.GET('/v1/actividades/planos-escala', { params: { query: { igrejaId: igreja.id, limite: 100, ordem: '-dataInicio' } } }))).dados as Plano[],
  })
}

export function usePlano(id: number) {
  return useQuery({
    enabled: id > 0,
    queryKey: chaves.plano(id),
    queryFn: async () => (await dados(api.GET('/v1/actividades/planos-escala/{id}', { params: { path: { id } } }))) as Plano,
  })
}

export function useDias(planoId: number) {
  return useQuery({
    enabled: planoId > 0,
    queryKey: chaves.dias(planoId),
    queryFn: async () =>
      ((await dados(api.GET('/v1/actividades/dias-escala', { params: { query: { escalaPlanoId: planoId, limite: 200, ordem: 'data' } } }))).dados as Dia[]),
  })
}

/** Todas as pessoas escaladas nos dias do plano (lê página a página). */
export function useEscalados(plano: Plano | undefined) {
  const igreja = useIgreja()
  return useQuery({
    enabled: !!plano,
    queryKey: chaves.escalados(plano?.id ?? 0),
    queryFn: async () => {
      const todos: Escalado[] = []
      let depois: string | undefined
      do {
        const r = await dados(api.GET('/v1/actividades/escalas', {
          params: { query: { igrejaId: igreja.id, desde: plano!.dataInicio, ate: plano!.dataFim, limite: 200, depois } },
        }))
        todos.push(...(r.dados as Escalado[]))
        depois = r.proximo ?? undefined
      } while (depois)
      return todos.filter((e) => e.escalaDiaId != null)
    },
  })
}

function useInvalidar(planoId: number) {
  const qc = useQueryClient()
  const igreja = useIgreja()
  return () => {
    qc.invalidateQueries({ queryKey: chaves.plano(planoId) })
    qc.invalidateQueries({ queryKey: chaves.planos(igreja.id) })
    qc.invalidateQueries({ queryKey: ['inicio', igreja.id] })
  }
}

/** Cria a escala e gera logo um dia por sábado do período. */
export function useCriarPlano() {
  const qc = useQueryClient()
  const igreja = useIgreja()
  return useMutation({
    mutationFn: async (corpo: Corpo<'/v1/actividades/planos-escala', 'post'>) => {
      const p = (await dados(api.POST('/v1/actividades/planos-escala', { body: corpo }))) as Plano
      await dados(api.POST('/v1/actividades/planos-escala/{id}/gerar-dias', { params: { path: { id: p.id } }, body: { diaSemana: 6 } }))
      return p
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: chaves.planos(igreja.id) }),
  })
}

export function useAlterarPlano(id: number) {
  const invalidar = useInvalidar(id)
  return useMutation({
    mutationFn: (corpo: Corpo<'/v1/actividades/planos-escala/{id}', 'patch'>) =>
      dados(api.PATCH('/v1/actividades/planos-escala/{id}', { params: { path: { id } }, body: corpo })),
    onSuccess: invalidar,
  })
}

export function useGerarDias(id: number) {
  const invalidar = useInvalidar(id)
  return useMutation({
    mutationFn: () => dados(api.POST('/v1/actividades/planos-escala/{id}/gerar-dias', { params: { path: { id } }, body: { diaSemana: 6 } })),
    onSuccess: invalidar,
  })
}

export function useAlterarDia(planoId: number) {
  const invalidar = useInvalidar(planoId)
  return useMutation({
    mutationFn: ({ id, corpo }: { id: number; corpo: Corpo<'/v1/actividades/dias-escala/{id}', 'patch'> }) =>
      dados(api.PATCH('/v1/actividades/dias-escala/{id}', { params: { path: { id } }, body: corpo })),
    onSuccess: invalidar,
  })
}

export function useEscalar(planoId: number) {
  const invalidar = useInvalidar(planoId)
  return useMutation({
    mutationFn: (corpo: { escalaDiaId: number; funcao: FuncaoEscala; membroId: number }) =>
      dados(api.POST('/v1/actividades/escalas', { body: corpo as Corpo<'/v1/actividades/escalas', 'post'> })),
    onSuccess: invalidar,
  })
}

export function useTrocar(planoId: number) {
  const invalidar = useInvalidar(planoId)
  return useMutation({
    mutationFn: ({ id, membroId }: { id: number; membroId: number }) =>
      dados(api.PATCH('/v1/actividades/escalas/{id}', { params: { path: { id } }, body: { membroId } })),
    onSuccess: invalidar,
  })
}

export function useRetirar(planoId: number) {
  const invalidar = useInvalidar(planoId)
  return useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/actividades/escalas/{id}/terminar', { params: { path: { id } } })),
    onSuccess: invalidar,
  })
}
