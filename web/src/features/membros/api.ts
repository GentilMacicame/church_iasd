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
  /** V33 */
  estadoCivil: NonNullable<Membro['estadoCivil']> | null
  dataNascimento: string | null
  conjugeMembroId: number | null
}

/** Linha de GET /v1/secretaria/membros-parecidos (V33): possível duplicado, com os motivos. */
export type MembroParecido = NonNullable<paths['/v1/secretaria/membros-parecidos']['get']['responses'][200]['content']['application/json']>[number]

export interface FiltrosMembros {
  q?: string
  estado?: EstadoMembro
  validacao?: 'PENDENTE' | 'APROVADO' | 'REJEITADO'
  sexo?: 'M' | 'F'
  estadoCivil?: NonNullable<Membro['estadoCivil']>
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
        params: { query: { igrejaId: igreja.id, limite: LIMITE, depois: pageParam, q: filtros.q || undefined, estado: filtros.estado, validacao: filtros.validacao, sexo: filtros.sexo, estadoCivil: filtros.estadoCivil } },
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
    enabled: membroId > 0,
    queryKey: chaves.contactos(membroId),
    queryFn: async () => (await dados(api.GET('/v1/secretaria/contactos', { params: { query: { membroId, limite: 50 } } }))).dados as Contacto[],
  })
}

export function useBaptismos(membroId: number) {
  return useQuery({
    enabled: membroId > 0,
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

/**
 * V33: membros parecidos (mesmo documento, ou nome parecido com a mesma data/local de nascimento). Só avisa; a
 * base de dados compara apenas com os membros que o utilizador vê. Procura quando há nome e apelido.
 */
export function useParecidos(p: { nome: string; apelido: string; dataNascimento?: string; naturalidade?: string; numeroIdentificacao?: string; excluirId?: number | null }) {
  const nome = p.nome.trim()
  const apelido = p.apelido.trim()
  const query = {
    nome, apelido,
    dataNascimento: /^\d{4}-\d{2}-\d{2}$/.test(p.dataNascimento ?? '') ? p.dataNascimento : undefined,
    naturalidade: p.naturalidade?.trim() || undefined,
    numeroIdentificacao: p.numeroIdentificacao?.trim() || undefined,
    excluirId: p.excluirId ?? undefined,
  }
  return useQuery({
    enabled: nome.length >= 2 && apelido.length >= 2,
    queryKey: ['membros', 'parecidos', query],
    queryFn: async () => (await dados(api.GET('/v1/secretaria/membros-parecidos', { params: { query } }))) as MembroParecido[],
    staleTime: 30_000,
  })
}

/** Os três contactos que o formulário da ficha edita: telemóvel (recebe os SMS), telefone fixo e e-mail. */
export const CONTACTOS_FICHA = ['TELEFONE', 'TELEFONE_FIXO', 'EMAIL'] as const
export type TipoContactoFicha = (typeof CONTACTOS_FICHA)[number]

/** O contacto de cada tipo que o formulário mostra: o principal, senão o mais antigo. */
export function contactoDoTipo(lista: Contacto[], tipo: TipoContactoFicha): Contacto | undefined {
  return lista.filter((c) => c.tipo === tipo).sort((a, b) => Number(b.principal) - Number(a.principal) || a.id - b.id)[0]
}

/**
 * Grava os contactos da ficha: o que mudou termina o antigo (nada se apaga; fica no histórico) e cria o novo; o que
 * ficou vazio termina o antigo. O primeiro telemóvel do membro fica como principal (recebe os SMS).
 */
export async function gravarContactosFicha(membroId: number, igrejaId: number, existentes: Contacto[], novos: Record<TipoContactoFicha, string>) {
  const temPrincipal = existentes.some((c) => c.principal)
  for (const tipo of CONTACTOS_FICHA) {
    const antigo = contactoDoTipo(existentes, tipo)
    const valor = novos[tipo].replace(/\s+/g, tipo === 'EMAIL' ? '' : ' ').trim()
    if ((antigo?.valor ?? '') === valor) continue
    if (antigo) await dados(api.POST('/v1/secretaria/contactos/{id}/terminar', { params: { path: { id: antigo.id } } }))
    if (valor) {
      const principal = tipo === 'TELEFONE' && (antigo?.principal || !temPrincipal)
      await dados(api.POST('/v1/secretaria/contactos', { body: { membroId, igrejaId, tipo, valor, principal } }))
    }
  }
}

export interface BaptismoFicha { data: string; localIgrejaId: number | null; local: string; oficiante: string }

/**
 * Grava o baptismo (e, num ex-membro, o baptismo anterior) a partir do formulário: o que não existe cria-se; o que
 * existe e mudou altera-se. Num ex-membro o baptismo anterior é o registo sem rebaptismo e o actual é o rebaptismo.
 */
export async function gravarBaptismosFicha(membroId: number, existentes: Baptismo[], exMembro: boolean, actual: BaptismoFicha, anterior: string) {
  let original = existentes.find((b) => !b.rebaptismo)
  let rebaptismo = existentes.find((b) => b.rebaptismo)
  const corpo = (b: BaptismoFicha) => ({ data: b.data, localIgrejaId: b.localIgrejaId, local: b.local || null, oficiante: b.oficiante || null })
  const mudou = (x: Baptismo, b: BaptismoFicha) =>
    x.data !== b.data || (x.localIgrejaId ?? null) !== b.localIgrejaId || (x.local ?? '') !== b.local || (x.oficiante ?? '') !== b.oficiante

  if (exMembro && anterior) {
    // marcado como ex-membro depois de ter o baptismo registado: esse registo é o actual e passa a rebaptismo
    // (só um registo sem rebaptismo por membro), para o anterior ficar no seu lugar
    if (original && !rebaptismo && original.data !== anterior) {
      await dados(api.PATCH('/v1/secretaria/baptismos/{id}', { params: { path: { id: original.id } }, body: { rebaptismo: true } }))
      rebaptismo = { ...original, rebaptismo: true }
      original = undefined
    }
    if (!original) {
      await dados(api.POST('/v1/secretaria/baptismos', { body: { membroId, data: anterior, rebaptismo: false } }))
    } else if (original.data !== anterior) {
      await dados(api.PATCH('/v1/secretaria/baptismos/{id}', { params: { path: { id: original.id } }, body: { data: anterior } }))
    }
  }
  if (!actual.data) return
  // ex-membro sem baptismo anterior indicado: o registo existente continua a ser o actual
  const alvo = exMembro ? rebaptismo ?? (anterior ? undefined : original) : original
  if (!alvo) {
    await dados(api.POST('/v1/secretaria/baptismos', { body: { membroId, ...corpo(actual), rebaptismo: exMembro } as never }))
  } else if (mudou(alvo, actual)) {
    await dados(api.PATCH('/v1/secretaria/baptismos/{id}', { params: { path: { id: alvo.id } }, body: corpo(actual) as never }))
  }
}

/** Depois de gravar a ficha a partir do formulário: contactos e baptismos voltam a ler da API. */
export function useInvalidarFicha() {
  const qc = useQueryClient()
  return (id: number) => {
    qc.invalidateQueries({ queryKey: ['membro', id] })
    qc.invalidateQueries({ queryKey: ['membros'] })
  }
}

/** Cargos do membro (oficiais), para mostrar os actuais na ficha. */
export function useCargosDoMembro(membroId: number, igrejaId: number, activo: boolean) {
  return useQuery({
    enabled: activo && membroId > 0,
    queryKey: ['membro', membroId, 'cargos'],
    queryFn: async () => (await dados(api.GET('/v1/secretaria/oficiais', { params: { query: { igrejaId, membroId, limite: 50 } } }))).dados as (Esquema<'Oficial'> & { id: number })[],
  })
}

/** Matrículas do membro nas classes da Escola Sabatina (a activa não tem data de saída). */
export function useMatriculasDoMembro(membroId: number, activo: boolean) {
  return useQuery({
    enabled: activo && membroId > 0,
    queryKey: ['membro', membroId, 'matriculas'],
    queryFn: async () => (await dados(api.GET('/v1/escola-sabatina/matriculas', { params: { query: { membroId, limite: 20 } } }))).dados as (Esquema<'Matricula'> & { id: number })[],
  })
}
