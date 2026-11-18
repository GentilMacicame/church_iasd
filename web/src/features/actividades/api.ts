/**
 * Actividades dos departamentos (F-ACT, V34): programa anual com a execução financeira, ficha da actividade,
 * responsáveis, material e conflitos de calendário. Tipos das tabelas gerados do contrato; as linhas das vistas
 * (programa) e a resposta dos conflitos estão descritas aqui com os nomes de campo da API.
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import type { paths } from '@/api/esquema'
import { useIgreja } from '@/auth/sessao'

/** Local (departamentoIgrejaId) ou da área pastoral (distritoId), nunca as duas (V35). */
export type Actividade = Esquema<'Actividade'> & { id: number; departamentoIgrejaId: number | null; distritoId?: number | null; nome: string; dataInicio: string }
export type EstadoActividade = NonNullable<Actividade['estado']>
export type Responsavel = Esquema<'ActividadeResponsavel'> & { id: number; actividadeId: number; membroId: number }
export type Material = Esquema<'Material'> & { id: number; actividadeId: number; descricao: string }
export type DepartamentoIgreja = Esquema<'DepartamentoIgreja'> & { id: number; igrejaId: number; departamentoId: number }
export type Departamento = Esquema<'Departamento'> & { id: number; nome: string }
export type Conflitos = paths['/v1/actividades/conflitos']['get']['responses'][200]['content']['application/json']

/** Linha de GET /v1/actividades/programa (vista vw_actividades_execucao). */
export interface LinhaPrograma {
  id: number; igrejaId: number; departamentoIgrejaId: number | null; departamento: string; nome: string; descricao: string | null
  objectivos: string | null; local: string | null; dataInicio: string; dataFim: string | null; estado: EstadoActividade
  ano: number; mes: number; responsavelMembroId: number | null; responsavel: string | null; outrosResponsaveis: number
  valorPrevisto: string; materialPrevisto: string; despesasPedidas: string; despesasAprovadas: string; executado: string
  /** V35: IGREJA (de um departamento) ou AREA_PASTORAL (do distrito, em todas as igrejas dele) */
  origem: 'IGREJA' | 'AREA_PASTORAL'; distritoId: number | null; distrito: string | null
  /** V48: porque foi cancelada e quando mudou pela última vez */
  motivoCancelamento: string | null; actualizadaEm: string | null
}

export const ROTULO_ESTADO: Record<EstadoActividade, string> = { PLANEADA: 'Planeada', EM_CURSO: 'Em curso', CONCLUIDA: 'Concluída', CANCELADA: 'Cancelada' }
export const VARIANTE_ESTADO: Record<EstadoActividade, 'info' | 'warning' | 'success' | 'secondary'> = {
  PLANEADA: 'info', EM_CURSO: 'warning', CONCLUIDA: 'success', CANCELADA: 'secondary',
}

const k = {
  todos: (igreja: number) => ['actividades', igreja] as const,
  actividade: (id: number) => ['actividade', id] as const,
}

export function usePrograma(ano: number) {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'programa', ano],
    queryFn: async () => (await dados(api.GET('/v1/actividades/programa', { params: { query: { igrejaId: igreja.id, ano } } }))) as unknown as LinhaPrograma[],
  })
}

/** Departamentos a funcionar nesta igreja, com o nome (a lista de departamentos é comum a todas as igrejas). */
export function useDepartamentosIgreja() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'departamentos'],
    queryFn: async () => {
      const [daIgreja, todos] = await Promise.all([
        dados(api.GET('/v1/organizacao/departamentos-igreja', { params: { query: { igrejaId: igreja.id, limite: 200 } } })),
        dados(api.GET('/v1/organizacao/departamentos', { params: { query: { limite: 200 } } })),
      ])
      const nomes = new Map((todos.dados as Departamento[]).map((d) => [d.id, d.nome]))
      return {
        daIgreja: (daIgreja.dados as DepartamentoIgreja[]).map((d) => ({ ...d, nome: nomes.get(d.departamentoId) ?? 'Departamento' }))
          .sort((a, b) => a.nome.localeCompare(b.nome, 'pt')),
        todos: (todos.dados as Departamento[]).filter((d) => !d.endDate).sort((a, b) => a.nome.localeCompare(b.nome, 'pt')),
      }
    },
    staleTime: 5 * 60_000,
  })
}

/** O distrito pastoral da igreja escolhida (para as actividades da área pastoral) e se o utilizador é o pastor dele. */
export function useDistritoDaIgreja() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'distrito'],
    queryFn: async () => {
      const i = (await dados(api.GET('/v1/organizacao/igrejas/{id}', { params: { path: { id: igreja.id } } }))) as Esquema<'Igreja'>
      if (!i.distritoId) return null
      const d = (await dados(api.GET('/v1/organizacao/distritos/{id}', { params: { path: { id: i.distritoId } } }))) as Esquema<'Distrito'>
      // o nome do pastor, se o utilizador o puder ler (senão fica só a indicação de que há pastor)
      let pastorNome: string | null = null
      if (d.pastorUsuarioId) {
        try { pastorNome = ((await dados(api.GET('/v1/nucleo/usuarios/{id}', { params: { path: { id: d.pastorUsuarioId } } }))) as { nome?: string }).nome ?? null } catch { pastorNome = null }
      }
      return { id: i.distritoId, nome: d.nome ?? 'Distrito', pastorUsuarioId: d.pastorUsuarioId ?? null, pastorNome: pastorNome ?? (d.pastorUsuarioId ? 'Indicado' : null) }
    },
    staleTime: 10 * 60_000,
  })
}

export function useActividade(id: number) {
  return useQuery({
    enabled: id > 0,
    queryKey: k.actividade(id),
    queryFn: async () => (await dados(api.GET('/v1/actividades/actividades/{id}', { params: { path: { id } } }))) as Actividade,
  })
}

export function useResponsaveis(actividadeId: number, activo = true) {
  return useQuery({
    enabled: activo && actividadeId > 0,
    queryKey: [...k.actividade(actividadeId), 'responsaveis'],
    queryFn: async () => (await dados(api.GET('/v1/actividades/responsaveis-actividade', { params: { query: { actividadeId, limite: 100 } } }))).dados as Responsavel[],
  })
}

export function useMateriais(actividadeId: number, activo = true) {
  return useQuery({
    enabled: activo && actividadeId > 0,
    queryKey: [...k.actividade(actividadeId), 'materiais'],
    queryFn: async () => (await dados(api.GET('/v1/actividades/materiais', { params: { query: { actividadeId, limite: 200 } } }))).dados as Material[],
  })
}

/** Despesas pedidas para a actividade (só quem pode ler despesas: a base de dados decide). */
export function useDespesasActividade(actividadeId: number, activo: boolean) {
  const igreja = useIgreja()
  return useQuery({
    enabled: activo && actividadeId > 0,
    queryKey: [...k.actividade(actividadeId), 'despesas'],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/despesas', { params: { query: { igrejaId: igreja.id, actividadeId, limite: 100 } } }))).dados as (Esquema<'Despesa'> & { id: number })[],
  })
}

/** Conflitos de calendário e dias livres seguintes (só informa; a actividade grava-se na mesma se se confirmar). */
export async function procurarConflitos(igrejaId: number, inicio: string, fim: string | null, excluirId?: number) {
  return (await dados(api.GET('/v1/actividades/conflitos', {
    params: { query: { igrejaId, inicio, fim: fim ?? undefined, excluirId } },
  }))) as Conflitos
}

type Corpo<P extends keyof paths, M extends 'post' | 'patch'> = paths[P][M] extends { requestBody?: { content: { 'application/json': infer C } } } ? C : never

/** Gravações das actividades; cada uma volta a ler o programa e a ficha. */
export function useActividadesMut() {
  const qc = useQueryClient()
  const igreja = useIgreja()
  const depois = (id?: number) => {
    void qc.invalidateQueries({ queryKey: k.todos(igreja.id) })
    if (id) void qc.invalidateQueries({ queryKey: k.actividade(id) })
  }
  return {
    criar: useMutation({
      mutationFn: async (c: Corpo<'/v1/actividades/actividades', 'post'>) => (await dados(api.POST('/v1/actividades/actividades', { body: c }))) as Actividade,
      onSuccess: (a) => depois(a.id),
    }),
    alterar: useMutation({
      mutationFn: ({ id, ...c }: { id: number } & Corpo<'/v1/actividades/actividades/{id}', 'patch'>) =>
        dados(api.PATCH('/v1/actividades/actividades/{id}', { params: { path: { id } }, body: c })),
      onSuccess: (_r, v) => depois(v.id),
    }),
    terminar: useMutation({
      mutationFn: (id: number) => dados(api.POST('/v1/actividades/actividades/{id}/terminar', { params: { path: { id } } })),
      onSuccess: (_r, id) => depois(id),
    }),
    juntarResponsavel: useMutation({
      mutationFn: (c: { actividadeId: number; membroId: number; funcao?: string }) => dados(api.POST('/v1/actividades/responsaveis-actividade', { body: c })),
      onSuccess: (_r, v) => depois(v.actividadeId),
    }),
    tirarResponsavel: useMutation({
      mutationFn: (r: Responsavel) => dados(api.POST('/v1/actividades/responsaveis-actividade/{id}/terminar', { params: { path: { id: r.id } } })),
      onSuccess: (_r, v) => depois(v.actividadeId),
    }),
    juntarMaterial: useMutation({
      mutationFn: (c: { actividadeId: number; descricao: string; quantidade: string; precoUnitario: string }) =>
        dados(api.POST('/v1/actividades/materiais', { body: c as never })),
      onSuccess: (_r, v) => depois(v.actividadeId),
    }),
    tirarMaterial: useMutation({
      mutationFn: (m: Material) => dados(api.POST('/v1/actividades/materiais/{id}/terminar', { params: { path: { id: m.id } } })),
      onSuccess: (_r, v) => depois(v.actividadeId),
    }),
    activarDepartamento: useMutation({
      mutationFn: (departamentoId: number) => dados(api.POST('/v1/organizacao/departamentos-igreja', { body: { igrejaId: igreja.id, departamentoId } })),
      onSuccess: () => depois(),
    }),
  }
}
