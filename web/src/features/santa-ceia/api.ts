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
}
export const ROTULO_ESTADO: Record<EstadoSantaCeia, string> = { AGENDADA: 'Agendada', REALIZADA: 'Realizada', CANCELADA: 'Cancelada' }

/** O histórico de uma igreja (a escolhida) ou, sem igreja, de todas as que o utilizador vê (painel geral). */
export function useHistoricoSantaCeia(todas = false, activo = true) {
  const igreja = useIgreja()
  return useQuery({
    enabled: activo,
    queryKey: ['santa-ceia', todas ? 'todas' : igreja.id],
    queryFn: async () => (await dados(api.GET('/v1/actividades/santa-ceia-historico', {
      params: { query: todas ? {} : { igrejaId: igreja.id } },
    }))) as unknown as SantaCeia[],
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
