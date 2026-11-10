/**
 * Dados dos membros (TanStack Query). Tipos das tabelas gerados do contrato (Esquema<'Membro'>); as
 * vistas de relatório não têm esquema no contrato, por isso as suas linhas estão descritas aqui, com os
 * nomes de campo que a API usa (coluna sem prefixo, em camelCase).
 */
import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import type { paths } from '@/api/esquema'
import { useIgreja } from '@/auth/sessao'

/** A API devolve sempre o id e os campos obrigatórios; o esquema marca-os opcionais (servem também de corpo). */
export type Membro = Esquema<'Membro'> & { id: number; igrejaId: number; nome: string; apelido: string }
export type Contacto = Esquema<'Contacto'> & { id: number }
export type Baptismo = Esquema<'Baptismo'> & { id: number }
type Corpo<P extends keyof paths, M extends 'post' | 'patch'> = paths[P][M] extends { requestBody?: { content: { 'application/json': infer C } } } ? C : never
export type EstadoMembro = NonNullable<Membro['estado']>

/** Linha de GET /v1/secretaria/membros-basico (vista vw_membro_basico). */
export interface MembroBasico {
  id: number
  igrejaId: number
  familiaId: number | null
  nome: string
  apelido: string
  sexo: 'M' | 'F' | null
  estado: EstadoMembro
}

export interface FiltrosMembros {
  q?: string
  estado?: EstadoMembro
  validacao?: 'PENDENTE' | 'APROVADO' | 'REJEITADO'
}

export const chaves = {
  todos: (igreja: number) => ['membros', igreja] as const,
  lista: (igreja: number, f: FiltrosMembros) => ['membros', igreja, 'lista', f] as const,
  basicos: (igreja: number) => ['membros', igreja, 'basicos'] as const,
  um: (id: number) => ['membro', id] as const,
  contactos: (id: number) => ['membro', id, 'contactos'] as const,
  baptismos: (id: number) => ['membro', id, 'baptismos'] as const,
}

const LIMITE = 50

/** Lista paginada por cursor (50 de cada vez), com pesquisa e filtros feitos pela API. */
export function useListaMembros(filtros: FiltrosMembros) {
  const igreja = useIgreja()
  return useInfiniteQuery({
    queryKey: chaves.lista(igreja.id, filtros),
    initialPageParam: undefined as string | undefined,
    queryFn: ({ pageParam }) =>
      dados(api.GET('/v1/secretaria/membros', {
        params: { query: { igrejaId: igreja.id, limite: LIMITE, depois: pageParam, q: filtros.q || undefined, estado: filtros.estado, validacao: filtros.validacao } },
      })),
    getNextPageParam: (ultima) => ultima.proximo ?? undefined,
  })
}

/** Todos os membros da igreja em forma curta: contagens por estado e escolha de um membro. */
export function useMembrosBasicos() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: chaves.basicos(igreja.id),
    queryFn: async () =>
      (await dados(api.GET('/v1/secretaria/membros-basico', { params: { query: { igrejaId: igreja.id } } }))) as unknown as MembroBasico[],
    staleTime: 60_000,
  })
}

/** Quantos registos esperam aprovação (até 200; acima disso mostra "200+"). */
export function useContagemPorAprovar(): string | null {
  const igreja = useIgreja()
  const q = useQuery({
    queryKey: [...chaves.todos(igreja.id), 'por-aprovar'],
    queryFn: () => dados(api.GET('/v1/secretaria/membros', { params: { query: { igrejaId: igreja.id, validacao: 'PENDENTE', limite: 200 } } })),
  })
  if (!q.data || q.data.dados.length === 0) return null
  return q.data.proximo ? '200+' : String(q.data.dados.length)
}

export function useMembro(id: number) {
  return useQuery({
    enabled: id > 0,
    queryKey: chaves.um(id),
    queryFn: async () => (await dados(api.GET('/v1/secretaria/membros/{id}', { params: { path: { id } } }))) as Membro,
  })
}

export function useContactos(membroId: number) {
  return useQuery({
    queryKey: chaves.contactos(membroId),
    queryFn: async () => (await dados(api.GET('/v1/secretaria/contactos', { params: { query: { membroId, limite: 50 } } }))).dados as Contacto[],
  })
}

export function useBaptismos(membroId: number) {
  return useQuery({
    queryKey: chaves.baptismos(membroId),
    queryFn: async () => (await dados(api.GET('/v1/secretaria/baptismos', { params: { query: { membroId, limite: 20 } } }))).dados as Baptismo[],
  })
}

/** Depois de qualquer escrita: a lista, as contagens e a ficha voltam a ler da API. */
function useInvalidar() {
  const qc = useQueryClient()
  const igreja = useIgreja()
  return (id?: number) => {
    qc.invalidateQueries({ queryKey: chaves.todos(igreja.id) })
    qc.invalidateQueries({ queryKey: ['inicio', igreja.id] })
    if (id) qc.invalidateQueries({ queryKey: chaves.um(id) })
  }
}

type CorpoCriar = Corpo<'/v1/secretaria/membros', 'post'>
type CorpoAlterar = Corpo<'/v1/secretaria/membros/{id}', 'patch'>

export function useCriarMembro() {
  const invalidar = useInvalidar()
  return useMutation({
    mutationFn: async (corpo: CorpoCriar) => (await dados(api.POST('/v1/secretaria/membros', { body: corpo }))) as Membro,
    onSuccess: (m) => invalidar(m.id),
  })
}

export function useAlterarMembro(id: number) {
  const invalidar = useInvalidar()
  return useMutation({
    mutationFn: (corpo: CorpoAlterar) => dados(api.PATCH('/v1/secretaria/membros/{id}', { params: { path: { id } }, body: corpo })),
    onSuccess: () => invalidar(id),
  })
}

export function useValidarMembro(id: number) {
  const invalidar = useInvalidar()
  return useMutation({
    mutationFn: () => dados(api.POST('/v1/secretaria/membros/{id}/validar', { params: { path: { id } } })),
    onSuccess: () => invalidar(id),
  })
}

export function useTerminarMembro(id: number) {
  const invalidar = useInvalidar()
  return useMutation({
    mutationFn: () => dados(api.POST('/v1/secretaria/membros/{id}/terminar', { params: { path: { id } } })),
    onSuccess: () => invalidar(id),
  })
}

type CorpoContacto = Corpo<'/v1/secretaria/contactos', 'post'>
export function useCriarContacto(membroId: number) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (corpo: CorpoContacto) => dados(api.POST('/v1/secretaria/contactos', { body: corpo })),
    onSuccess: () => qc.invalidateQueries({ queryKey: chaves.contactos(membroId) }),
  })
}

type CorpoBaptismo = Corpo<'/v1/secretaria/baptismos', 'post'>
export function useCriarBaptismo(membroId: number) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (corpo: CorpoBaptismo) => dados(api.POST('/v1/secretaria/baptismos', { body: corpo })),
    onSuccess: () => qc.invalidateQueries({ queryKey: chaves.baptismos(membroId) }),
  })
}
