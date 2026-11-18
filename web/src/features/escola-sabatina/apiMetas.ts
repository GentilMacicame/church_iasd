/**
 * Escola Sabatina (V47): metas individuais (a da classe é a soma, calculada pela base de dados), o acompanhamento por
 * aluno e por classe, e as semanas especiais (semana de oração, da família, de evangelismo…) com alertas.
 * DECIMAL chega como texto.
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import { useIgreja } from '@/auth/sessao'
import { hojeIso } from '@/lib/formatos'

export interface LinhaMetaAluno {
  igrejaId: number; trimestreId: number; classeTrimestreId: number; membroId: number; nome: string
  metaId: number | null; meta: string | null; contribuido: string; presencas: number; cumprimento: string | null
}
export interface LinhaMetaClasse {
  igrejaId: number; trimestreId: number; classeTrimestreId: number; classe: string; divisao: string
  alunos: number; comMeta: number; meta: string | null; contribuido: string; identificado: string; sabadosComRelatorio: number; sabados: number
}
export type SemanaEspecial = Esquema<'SemanaEspecial'> & { id: number; tipo: TipoSemana; nome: string; dataInicio: string; dataFim: string }
export type TipoSemana = 'ORACAO' | 'FAMILIA' | 'EVANGELISMO' | 'JOVENS' | 'MORDOMIA' | 'OUTRO'
export const TIPOS_SEMANA: Record<TipoSemana, string> = {
  ORACAO: 'Semana de Oração', FAMILIA: 'Semana da Família', EVANGELISMO: 'Semana de Evangelismo', JOVENS: 'Semana dos Jovens',
  MORDOMIA: 'Semana da Mordomia', OUTRO: 'Outro programa',
}

const k = {
  alunos: (igreja: number, ct: number) => ['es', igreja, 'metas-alunos', ct] as const,
  classes: (igreja: number, tr: number) => ['es', igreja, 'metas-classes', tr] as const,
  semanas: (igreja: number) => ['es', igreja, 'semanas-especiais'] as const,
}

export function useMetasAlunos(trimestre?: number, classeTrimestre?: number) {
  const igreja = useIgreja()
  return useQuery({
    enabled: !!trimestre && !!classeTrimestre,
    queryKey: k.alunos(igreja.id, classeTrimestre ?? 0),
    queryFn: async () => (await dados(api.GET('/v1/escola-sabatina/metas-alunos', {
      params: { query: { igrejaId: igreja.id, trimestreId: trimestre, classeTrimestreId: classeTrimestre } },
    } as never))) as unknown as LinhaMetaAluno[],
  })
}

export function useMetasClasses(trimestre?: number) {
  const igreja = useIgreja()
  return useQuery({
    enabled: !!trimestre,
    queryKey: k.classes(igreja.id, trimestre ?? 0),
    queryFn: async () => (await dados(api.GET('/v1/escola-sabatina/metas-classes', {
      params: { query: { igrejaId: igreja.id, trimestreId: trimestre } },
    } as never))) as unknown as LinhaMetaClasse[],
  })
}

/** Gravar a meta de um aluno (nova ou alterada); a da classe recalcula-se na base de dados. */
export function useGravarMeta() {
  const qc = useQueryClient()
  const igreja = useIgreja()
  return useMutation({
    mutationFn: ({ metaId, classeTrimestreId, membroId, valor }: { metaId: number | null; classeTrimestreId: number; membroId: number; valor: string }) => metaId
      ? dados(api.PATCH('/v1/escola-sabatina/metas-individuais/{id}', { params: { path: { id: metaId } }, body: { alvoOferta: valor } as never }))
      : dados(api.POST('/v1/escola-sabatina/metas-individuais', { body: { classeTrimestreId, membroId, igrejaId: igreja.id, alvoOferta: valor } as never })),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['es', igreja.id] }),
  })
}

export function useSemanasEspeciais() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: k.semanas(igreja.id),
    queryFn: async () => ((await dados(api.GET('/v1/escola-sabatina/semanas-especiais', {
      params: { query: { igrejaId: igreja.id, limite: 100 } },
    }))).dados as SemanaEspecial[]).filter((s) => !s.endDate).sort((a, b) => b.dataInicio.localeCompare(a.dataInicio)),
    staleTime: 5 * 60_000,
  })
}

export function useSemanasMut() {
  const qc = useQueryClient()
  const igreja = useIgreja()
  const invalidar = () => qc.invalidateQueries({ queryKey: k.semanas(igreja.id) })
  return {
    gravar: useMutation({ onSuccess: invalidar, mutationFn: ({ id, ...corpo }: Partial<SemanaEspecial>) => id
      ? dados(api.PATCH('/v1/escola-sabatina/semanas-especiais/{id}', { params: { path: { id } }, body: corpo as never }))
      : dados(api.POST('/v1/escola-sabatina/semanas-especiais', { body: { ...corpo, igrejaId: igreja.id } as never })) }),
    tirar: useMutation({ onSuccess: invalidar, mutationFn: (id: number) =>
      dados(api.POST('/v1/escola-sabatina/semanas-especiais/{id}/terminar', { params: { path: { id } } })) }),
  }
}

/** A decorrer hoje, ou a começar nos próximos dias (por defeito 14). */
export function semanasProximas(lista: SemanaEspecial[], dias = 14) {
  const hoje = hojeIso()
  const limite = new Date(Date.parse(`${hoje}T12:00:00Z`) + dias * 86_400_000).toISOString().slice(0, 10)
  return lista.filter((s) => s.dataFim >= hoje && s.dataInicio <= limite).sort((a, b) => a.dataInicio.localeCompare(b.dataInicio))
}
