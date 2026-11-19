/**
 * Santa Ceia (V39): agendamento e participantes. O histórico vem da vista vw_santa_ceia (com o total); as gravações
 * vão à tabela. As regras (uma por dia, realizada só depois do dia, números obrigatórios) são da base de dados.
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados } from '@/api/cliente'
import { useIgreja } from '@/auth/sessao'

export type EstadoSantaCeia = 'AGENDADA' | 'REALIZADA' | 'CANCELADA'
/** Linha de GET /v1/actividades/santa-ceia-historico. */
export interface SantaCeia {
  stcId: number; igrejaId: number; igreja: string; data: string; hora: string | null; local: string | null; estado: EstadoSantaCeia
  ano: number; responsavel: string | null; homens: number | null; mulheres: number | null; visitantes: number | null; total: number
  /** V52: quantos participantes têm nome */
  nomeados?: number
}
export const ROTULO_ESTADO: Record<EstadoSantaCeia, string> = { AGENDADA: 'Agendada', REALIZADA: 'Realizada', CANCELADA: 'Cancelada' }

/** O histórico de uma igreja (a escolhida) ou, sem igreja, de todas as que o utilizador vê (painel geral). */
export function useHistoricoSantaCeia(todas = false, activo = true) {
  const igreja = useIgreja()
  return useQuery({
    enabled: activo,
    queryKey: ['santa-ceia', todas ? 'todas' : igreja.id],
    // a coluna stc_id da vista chega como "id" (a API tira o prefixo da tabela): fica também em stcId
    queryFn: async () => ((await dados(api.GET('/v1/actividades/santa-ceia-historico', {
      params: { query: todas ? {} : { igrejaId: igreja.id } },
    }))) as unknown as (SantaCeia & { id?: number })[]).map((s) => ({ ...s, stcId: s.stcId ?? s.id ?? 0 })),
    staleTime: 60_000,
  })
}

export function useSantaCeiaMut() {
  const qc = useQueryClient()
  const depois = () => qc.invalidateQueries({ queryKey: ['santa-ceia'] })
  return {
    criar: useMutation({
      mutationFn: (c: Record<string, unknown>) => dados(api.POST('/v1/actividades/santas-ceias', { body: c as never })),
      onSuccess: depois,
    }),
    alterar: useMutation({
      mutationFn: ({ id, ...c }: { id: number } & Record<string, unknown>) =>
        dados(api.PATCH('/v1/actividades/santas-ceias/{id}', { params: { path: { id } }, body: c as never })),
      onSuccess: depois,
    }),
  }
}

/** A ficha completa (para editar: responsável e observações não estão na vista). */
export async function lerSantaCeia(id: number) {
  return dados(api.GET('/v1/actividades/santas-ceias/{id}', { params: { path: { id } } }))
}

/** V51/V52 · A equipa de apoio: diáconos e diaconisas (quem dirige é o pastor ou um ancião, na ficha). */
export type FuncaoAcompanhante = 'DIACONO' | 'DIACONISA'
export interface Acompanhante { membroId: number; funcao: FuncaoAcompanhante }
type LinhaAcompanhante = Acompanhante & { id: number; santaCeiaId: number; endDate?: string | null }

export async function lerAcompanhantes(stcId: number, igrejaId: number): Promise<LinhaAcompanhante[]> {
  const r = (await dados(api.GET('/v1/actividades/acompanhantes-santa-ceia' as never, { params: { query: { igrejaId, santaCeiaId: stcId, limite: 100 } } } as never))) as { dados: LinhaAcompanhante[] }
  return r.dados.filter((a) => !a.endDate && a.santaCeiaId === stcId)
}

/** Grava a equipa: junta os novos, muda a função se mudou e retira os que saíram (fica no histórico). */
export async function gravarAcompanhantes(stcId: number, igrejaId: number, equipa: Acompanhante[]) {
  const actuais = await lerAcompanhantes(stcId, igrejaId)
  for (const a of actuais) {
    const novo = equipa.find((e) => e.membroId === a.membroId)
    if (!novo) await dados(api.POST('/v1/actividades/acompanhantes-santa-ceia/{id}/terminar' as never, { params: { path: { id: a.id } } } as never))
    else if (novo.funcao !== a.funcao) await dados(api.PATCH('/v1/actividades/acompanhantes-santa-ceia/{id}' as never, { params: { path: { id: a.id } }, body: { funcao: novo.funcao } } as never))
  }
  for (const e of equipa) if (!actuais.some((a) => a.membroId === e.membroId)) await dados(api.POST('/v1/actividades/acompanhantes-santa-ceia' as never, { body: { santaCeiaId: stcId, igrejaId, ...e } } as never))
}

/** V52 · Os membros que participaram, pelo nome. */
type LinhaParticipante = { id: number; santaCeiaId: number; membroId: number; endDate?: string | null }
export async function lerParticipantes(stcId: number, igrejaId: number): Promise<LinhaParticipante[]> {
  const todos: LinhaParticipante[] = []
  let cursor: string | undefined
  do {
    const r = (await dados(api.GET('/v1/actividades/participantes-santa-ceia' as never, { params: { query: { igrejaId, santaCeiaId: stcId, limite: 200, ...(cursor ? { depois: cursor } : {}) } } } as never))) as { dados: LinhaParticipante[]; proximo?: string | null }
    todos.push(...r.dados); cursor = r.proximo ?? undefined
  } while (cursor)
  return todos.filter((p) => !p.endDate && p.santaCeiaId === stcId)
}

/**
 * Regista a celebração com os nomes. A ordem conta para as regras da base (os números não ficam abaixo dos nomes):
 * primeiro desmarca quem saiu, depois grava os números e o estado, por fim marca os novos.
 */
export async function gravarParticipacao(stcId: number, igrejaId: number, membros: number[], numeros: Record<string, unknown>) {
  const actuais = await lerParticipantes(stcId, igrejaId)
  for (const p of actuais) if (!membros.includes(p.membroId)) await dados(api.POST('/v1/actividades/participantes-santa-ceia/{id}/terminar' as never, { params: { path: { id: p.id } } } as never))
  await dados(api.PATCH('/v1/actividades/santas-ceias/{id}', { params: { path: { id: stcId } }, body: numeros as never }))
  for (const m of membros) if (!actuais.some((p) => p.membroId === m)) await dados(api.POST('/v1/actividades/participantes-santa-ceia' as never, { body: { santaCeiaId: stcId, igrejaId, membroId: m } } as never))
}

/** Linha de GET /v1/actividades/santa-ceia-participacao (V52): um membro num ano. */
export interface ParticipacaoMembro {
  igrejaId: number; ano: number; membroId: number; membro: string; sexo: 'M' | 'F' | null; estadoMembro: string
  celebracoes: number; participacoes: number; faltas: number; ultima: string | null
}
export function useParticipacaoSantaCeia(ano: number) {
  const igreja = useIgreja()
  return useQuery({
    queryKey: ['santa-ceia', 'participacao', igreja.id, ano],
    queryFn: async () => (await dados(api.GET('/v1/actividades/santa-ceia-participacao' as never, { params: { query: { igrejaId: igreja.id, ano } } } as never))) as unknown as ParticipacaoMembro[],
    staleTime: 60_000,
  })
}
