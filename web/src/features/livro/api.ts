/**
 * Livro de membros (P-01): reuniões, votos em acta e movimentos (entradas e saídas com o voto que as
 * autoriza). A base de dados decide se o voto serve (tipo de reunião, aprovado, mesma igreja) e aplica o
 * movimento ao membro (estado, data e modo de entrada); aqui só se lê e grava.
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import type { paths } from '@/api/esquema'
import { useIgreja } from '@/auth/sessao'

export type Reuniao = Esquema<'Reuniao'> & { id: number; tipo: TipoReuniao; data: string }
export type Voto = Esquema<'Voto'> & { id: number; reuniaoId: number; numero: string; tipo: TipoVoto; assunto: string }
export type Movimento = Esquema<'Movimento'> & { id: number; membroId: number; tipo: TipoMovimento; data: string }
export type TipoReuniao = NonNullable<Esquema<'Reuniao'>['tipo']>
export type TipoVoto = NonNullable<Esquema<'Voto'>['tipo']>
export type TipoMovimento = NonNullable<Esquema<'Movimento'>['tipo']>
type Corpo<P extends keyof paths, M extends 'post' | 'patch'> = paths[P][M] extends { requestBody?: { content: { 'application/json': infer C } } } ? C : never

/** Que reuniões podem votar cada movimento (Manual da Igreja; a base de dados confirma). */
export const REUNIOES_QUE_VOTAM: Partial<Record<TipoMovimento, TipoReuniao[]>> = {
  BAPTISMO: ['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA'],
  REBAPTISMO: ['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA'],
  PROFISSAO_FE: ['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA'],
  REMOCAO_PEDIDO: ['JUNTA_DIRECTIVA', 'REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA'],
  REMOCAO_DISCIPLINA: ['ASSEMBLEIA_ADMINISTRATIVA'],
  DESAPARECIDO: ['ASSEMBLEIA_ADMINISTRATIVA'],
}
export const ENTRADAS: TipoMovimento[] = ['BAPTISMO', 'PROFISSAO_FE', 'REBAPTISMO']
export const SAIDAS: TipoMovimento[] = ['FALECIMENTO', 'REMOCAO_PEDIDO', 'REMOCAO_DISCIPLINA', 'DESAPARECIDO']
export const eEntrada = (t: TipoMovimento) => ['BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE', 'TRANSFERENCIA_ENTRADA'].includes(t)

const chaves = {
  reunioes: (igreja: number) => ['livro', igreja, 'reunioes'] as const,
  reuniao: (id: number) => ['reuniao', id] as const,
  votos: (igreja: number) => ['livro', igreja, 'votos'] as const,
  movimentos: (igreja: number) => ['livro', igreja, 'movimentos'] as const,
  doMembro: (id: number) => ['membro', id, 'movimentos'] as const,
}

/** Lê todas as páginas de uma listagem (até ao fim do cursor). */
async function todas<T>(pedir: (depois?: string) => Promise<{ dados: unknown[]; proximo?: string | null }>): Promise<T[]> {
  const out: T[] = []
  let depois: string | undefined
  do {
    const r = await pedir(depois)
    out.push(...(r.dados as T[]))
    depois = r.proximo ?? undefined
  } while (depois)
  return out
}

export function useReunioes() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: chaves.reunioes(igreja.id),
    queryFn: () => todas<Reuniao>((depois) => dados(api.GET('/v1/secretaria/reunioes', { params: { query: { igrejaId: igreja.id, limite: 200, ordem: '-data', depois } } }))),
  })
}

export function useReuniao(id: number) {
  return useQuery({
    enabled: id > 0,
    queryKey: chaves.reuniao(id),
    queryFn: async () => (await dados(api.GET('/v1/secretaria/reunioes/{id}', { params: { path: { id } } }))) as Reuniao,
  })
}

/** Todos os votos visíveis (das reuniões das igrejas a que o utilizador tem acesso). */
export function useVotos() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: chaves.votos(igreja.id),
    queryFn: () => todas<Voto>((depois) => dados(api.GET('/v1/secretaria/votos', { params: { query: { limite: 200, depois } } }))),
  })
}

export function useMovimentos() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: chaves.movimentos(igreja.id),
    queryFn: () => todas<Movimento>((depois) => dados(api.GET('/v1/secretaria/movimentos-membro', { params: { query: { igrejaId: igreja.id, limite: 200, ordem: '-data', depois } } }))),
  })
}

export function useMovimentosDoMembro(membroId: number) {
  const igreja = useIgreja()
  return useQuery({
    queryKey: chaves.doMembro(membroId),
    queryFn: async () => (await dados(api.GET('/v1/secretaria/movimentos-membro', { params: { query: { igrejaId: igreja.id, membroId, limite: 50, ordem: '-data' } } }))).dados as Movimento[],
  })
}

export function useCriarReuniao() {
  const qc = useQueryClient()
  const igreja = useIgreja()
  return useMutation({
    mutationFn: async (corpo: Corpo<'/v1/secretaria/reunioes', 'post'>) => (await dados(api.POST('/v1/secretaria/reunioes', { body: corpo }))) as Reuniao,
    onSuccess: () => qc.invalidateQueries({ queryKey: chaves.reunioes(igreja.id) }),
  })
}

export function useCriarVoto() {
  const qc = useQueryClient()
  const igreja = useIgreja()
  return useMutation({
    mutationFn: async (corpo: Corpo<'/v1/secretaria/votos', 'post'>) => (await dados(api.POST('/v1/secretaria/votos', { body: corpo }))) as Voto,
    onSuccess: () => qc.invalidateQueries({ queryKey: chaves.votos(igreja.id) }),
  })
}

/** Regista o movimento: a base de dados aplica-o ao membro (estado, data e modo de entrada). */
export function useCriarMovimento(membroId: number) {
  const qc = useQueryClient()
  const igreja = useIgreja()
  return useMutation({
    mutationFn: async (corpo: Corpo<'/v1/secretaria/movimentos-membro', 'post'>) => dados(api.POST('/v1/secretaria/movimentos-membro', { body: corpo })),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: chaves.doMembro(membroId) })
      qc.invalidateQueries({ queryKey: chaves.movimentos(igreja.id) })
      qc.invalidateQueries({ queryKey: ['membro', membroId] })
      qc.invalidateQueries({ queryKey: ['membros', igreja.id] })
      qc.invalidateQueries({ queryKey: ['inicio', igreja.id] })
    },
  })
}

/* ===================================================================== conselho: presenças e agenda (V22) */
export type Presenca = Esquema<'ReuniaoPresenca'> & { id: number; reuniaoId: number; membroId: number; presente: boolean }
export type EstadoPonto = 'PENDENTE' | 'APROVADO' | 'REJEITADO' | 'ADIADO' | 'INFORMATIVO'
export type Ponto = Esquema<'ReuniaoPonto'> & { id: number; reuniaoId: number; ordem: number; assunto: string; estado: EstadoPonto }

export function usePresencas(reuniaoId: number) {
  return useQuery({
    enabled: reuniaoId > 0,
    queryKey: [...chaves.reuniao(reuniaoId), 'presencas'],
    queryFn: () => todas<Presenca>((depois) => dados(api.GET('/v1/secretaria/presencas-reuniao', { params: { query: { reuniaoId, limite: 200, depois } } }))),
  })
}

export function usePontos(reuniaoId: number) {
  return useQuery({
    enabled: reuniaoId > 0,
    queryKey: [...chaves.reuniao(reuniaoId), 'pontos'],
    queryFn: async () => (await todas<Ponto>((depois) => dados(api.GET('/v1/secretaria/pontos-agenda', { params: { query: { reuniaoId, limite: 200, depois } } }))))
      .sort((a, b) => a.ordem - b.ordem || a.id - b.id),
  })
}

/** Presenças, pontos da agenda e dados da reunião (a acta aprovada fica fechada pela base de dados). */
export function useReuniaoMut(reuniaoId: number) {
  const qc = useQueryClient()
  const igreja = useIgreja()
  const invalidar = () => {
    qc.invalidateQueries({ queryKey: chaves.reuniao(reuniaoId) })
    qc.invalidateQueries({ queryKey: chaves.reunioes(igreja.id) })
  }
  /** Marca presente/ausente: cria a linha da pessoa ou altera a que existe. */
  const marcar = useMutation({
    mutationFn: async (p: { existente?: Presenca; membroId: number; presente: boolean; funcao?: string | null; justificacao?: string | null }) =>
      p.existente
        ? dados(api.PATCH('/v1/secretaria/presencas-reuniao/{id}', { params: { path: { id: p.existente.id } }, body: { presente: p.presente, justificacao: p.presente ? null : p.justificacao ?? null } as never }))
        : dados(api.POST('/v1/secretaria/presencas-reuniao', { body: { reuniaoId, membroId: p.membroId, presente: p.presente, funcao: p.funcao ?? null, justificacao: p.justificacao ?? null } as never })),
    onSuccess: invalidar,
  })
  const retirarPresenca = useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/secretaria/presencas-reuniao/{id}/terminar', { params: { path: { id } } })),
    onSuccess: invalidar,
  })
  const gravarPonto = useMutation({
    mutationFn: async ({ id, ...corpo }: Partial<Ponto> & { id?: number }) =>
      id
        ? dados(api.PATCH('/v1/secretaria/pontos-agenda/{id}', { params: { path: { id } }, body: corpo as never }))
        : dados(api.POST('/v1/secretaria/pontos-agenda', { body: { ...corpo, reuniaoId } as never })),
    onSuccess: invalidar,
  })
  const retirarPonto = useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/secretaria/pontos-agenda/{id}/terminar', { params: { path: { id } } })),
    onSuccess: invalidar,
  })
  const alterarReuniao = useMutation({
    mutationFn: (corpo: Partial<Reuniao>) => dados(api.PATCH('/v1/secretaria/reunioes/{id}', { params: { path: { id: reuniaoId } }, body: corpo as never })),
    onSuccess: invalidar,
  })
  return { marcar, retirarPresenca, gravarPonto, retirarPonto, alterarReuniao }
}
