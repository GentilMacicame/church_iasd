/**
 * Comunicados e anúncios (V37): da igreja, do distrito pastoral ou da Associação/Missão. A base de dados decide quem
 * publica (e vê os rascunhos) e quem lê: a lista devolve só o que o utilizador pode ver.
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import { useIgreja } from '@/auth/sessao'

export type Comunicado = Esquema<'Comunicado'> & { id: number; titulo: string; conteudo: string; publicarEm: string }
export type Destino = Esquema<'ComunicadoIgreja'> & { id: number; comunicadoId: number; igrejaId: number }
export type Emissor = 'IGREJA' | 'DISTRITO' | 'ASSOCIACAO'

/** Linha de GET /v1/organizacao/directorio-igrejas (V37: com o distrito pastoral). */
export interface IgrejaDirectorio { id: number; nome: string; entidadeId: number; entidade: string; distritoId: number | null }

export const ROTULO_ESTADO = { RASCUNHO: 'Rascunho', PUBLICADO: 'Publicado', ARQUIVADO: 'Arquivado' } as const
export const ROTULO_PUBLICO = { MEMBROS: 'Todos os membros', LIDERANCA: 'Só a liderança' } as const

export const emissorDe = (c: Comunicado): Emissor => (c.igrejaId ? 'IGREJA' : c.distritoId ? 'DISTRITO' : 'ASSOCIACAO')

/** Publicado, já em vigor e ainda válido (o que aparece no mural). */
export function emVigor(c: Comunicado, agora = Date.now()) {
  return c.estado === 'PUBLICADO' && !c.endDate && Date.parse(c.publicarEm) <= agora && (!c.validoAte || Date.parse(c.validoAte) >= agora)
}

const k = { todos: ['comunicados'] as const }

export function useComunicados() {
  return useQuery({
    queryKey: k.todos,
    queryFn: async () => (await dados(api.GET('/v1/nucleo/comunicados', {
      params: { query: { limite: 200, ordem: '-publicarEm', incluirTerminados: false } },
    }))).dados as Comunicado[],
    staleTime: 60_000,
  })
}

export function useDestinos(comunicadoId: number | null) {
  return useQuery({
    enabled: !!comunicadoId,
    queryKey: [...k.todos, comunicadoId, 'destinos'],
    queryFn: async () => (await dados(api.GET('/v1/nucleo/comunicados-igrejas', { params: { query: { comunicadoId: comunicadoId!, limite: 200 } } }))).dados as Destino[],
  })
}

/** Igrejas de uma Associação (para escolher os destinatários de um comunicado do distrito ou da Associação). */
export function useIgrejasDaEntidade(entidadeId?: number | null) {
  return useQuery({
    enabled: !!entidadeId,
    queryKey: ['directorio', entidadeId],
    queryFn: async () => (await dados(api.GET('/v1/organizacao/directorio-igrejas', { params: { query: { entidadeId: entidadeId! } } }))) as unknown as IgrejaDirectorio[],
    staleTime: 10 * 60_000,
  })
}

/** A Associação/Missão da igreja escolhida (para publicar em nome dela). */
export function useEntidadeDaIgreja() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: ['igreja', igreja.id, 'entidade'],
    queryFn: async () => {
      const i = (await dados(api.GET('/v1/organizacao/igrejas/{id}', { params: { path: { id: igreja.id } } }))) as Esquema<'Igreja'>
      const e = (await dados(api.GET('/v1/organizacao/entidades/{id}', { params: { path: { id: i.entidadeId! } } }))) as Esquema<'Entidade'>
      return { id: i.entidadeId!, nome: e.nome ?? 'Associação/Missão' }
    },
    staleTime: 10 * 60_000,
  })
}

export function useComunicadosMut() {
  const qc = useQueryClient()
  const depois = () => qc.invalidateQueries({ queryKey: k.todos })
  return {
    criar: useMutation({
      mutationFn: async (c: Record<string, unknown>) => (await dados(api.POST('/v1/nucleo/comunicados', { body: c as never }))) as Comunicado,
      onSuccess: depois,
    }),
    alterar: useMutation({
      mutationFn: ({ id, ...c }: { id: number } & Record<string, unknown>) =>
        dados(api.PATCH('/v1/nucleo/comunicados/{id}', { params: { path: { id } }, body: c as never })),
      onSuccess: depois,
    }),
    terminar: useMutation({
      mutationFn: (id: number) => dados(api.POST('/v1/nucleo/comunicados/{id}/terminar', { params: { path: { id } } })),
      onSuccess: depois,
    }),
  }
}

/** Acerta os destinatários: junta as igrejas novas e termina as que saíram (nada se apaga). */
export async function gravarDestinos(comunicadoId: number, actuais: Destino[], escolhidas: number[]) {
  for (const d of actuais.filter((x) => !x.endDate && !escolhidas.includes(x.igrejaId))) {
    await dados(api.POST('/v1/nucleo/comunicados-igrejas/{id}/terminar', { params: { path: { id: d.id } } }))
  }
  for (const igrejaId of escolhidas.filter((i) => !actuais.some((x) => !x.endDate && x.igrejaId === i))) {
    await dados(api.POST('/v1/nucleo/comunicados-igrejas', { body: { comunicadoId, igrejaId } }))
  }
}
