/**
 * Programação do dia (V44) · a folha do sábado: partes (Escola Sabatina, Transição, Culto Divino, JA) com o
 * apresentador e os itens com as horas, a actividade e o responsável (membro, família, departamento ou texto).
 * Preparar (modelo ou cópia de outro dia) e preencher pela escala são funções da base de dados.
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import { useIgreja } from '@/auth/sessao'

export type Programa = Esquema<'ProgramaDia'> & { id: number; data: string }
export type Parte = Esquema<'ProgramaParte'> & { id: number; programaDiaId: number; ordem: number; titulo: string; rotulo: string }
export type Item = Esquema<'ProgramaItem'> & { id: number; programaDiaId: number; programaParteId: number; ordem: number; actividade: string; destaque: boolean }

/** Funções da escala a que uma parte ou item se pode ligar (a escala do dia preenche o nome). */
export const ESCALA: Record<string, string> = {
  FAMILIA_ES: 'Família da Escola Sabatina', APRESENTADOR_ES: 'Apresentador da Escola Sabatina', APRESENTADOR_CULTO: 'Apresentador do Culto Divino',
  PREGADOR: 'Sermão principal', TRADUTOR: 'Tradutor', SERMAO_CRIANCA: 'Sermão da criança', ORACAO_INICIAL: 'Oração inicial (culto)',
  ORACAO_FINAL: 'Oração final (culto)', APRESENTADOR_JA: 'Apresentador da JA', MEDITACAO_JA: 'Meditação da JA',
}

const k = {
  lista: (igreja: number) => ['programacao', igreja] as const,
  um: (id: number) => ['programacao', 'um', id] as const,
}

export function useProgramas() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: k.lista(igreja.id),
    queryFn: async () => (await dados(api.GET('/v1/actividades/programas-dia', {
      params: { query: { igrejaId: igreja.id, limite: 100, ordem: '-data' } },
    }))).dados as Programa[],
  })
}

/** A programação, as partes e os itens (activos), por ordem. */
export function useProgramacao(id: number) {
  return useQuery({
    queryKey: k.um(id),
    enabled: id > 0,
    queryFn: async () => {
      const [p, partes, itens] = await Promise.all([
        dados(api.GET('/v1/actividades/programas-dia/{id}', { params: { path: { id } } })),
        dados(api.GET('/v1/actividades/partes-programa', { params: { query: { programaDiaId: id, limite: 50 } } })),
        dados(api.GET('/v1/actividades/itens-programa', { params: { query: { programaDiaId: id, limite: 200 } } })),
      ])
      const ord = <T extends { ordem: number; id: number }>(a: T, b: T) => a.ordem - b.ordem || a.id - b.id
      return {
        programa: p as Programa,
        partes: ((partes.dados as Parte[]).filter((x) => !x.endDate)).sort(ord),
        itens: ((itens.dados as Item[]).filter((x) => !x.endDate)).sort(ord),
      }
    },
  })
}

export function useProgramacaoMut(id: number) {
  const qc = useQueryClient()
  const igreja = useIgreja()
  const invalidar = () => {
    qc.invalidateQueries({ queryKey: k.um(id) })
    qc.invalidateQueries({ queryKey: k.lista(igreja.id) })
  }
  const opts = { onSuccess: invalidar }
  return {
    alterarPrograma: useMutation({ ...opts, mutationFn: (corpo: Partial<Programa>) =>
      dados(api.PATCH('/v1/actividades/programas-dia/{id}', { params: { path: { id } }, body: corpo as never })) }),
    preencher: useMutation({ ...opts, mutationFn: async () =>
      (await dados(api.POST('/v1/actividades/programas-dia/{id}/preencher-escala', { params: { path: { id } } }))) as { mudaram: number } }),
    gravarParte: useMutation({ ...opts, mutationFn: ({ id: pid, ...corpo }: Partial<Parte>) => pid
      ? dados(api.PATCH('/v1/actividades/partes-programa/{id}', { params: { path: { id: pid } }, body: corpo as never }))
      : dados(api.POST('/v1/actividades/partes-programa', { body: { ...corpo, programaDiaId: id } as never })) }),
    tirarParte: useMutation({ ...opts, mutationFn: (pid: number) =>
      dados(api.POST('/v1/actividades/partes-programa/{id}/terminar', { params: { path: { id: pid } } })) }),
    gravarItem: useMutation({ ...opts, mutationFn: ({ id: iid, ...corpo }: Partial<Item>) => iid
      ? dados(api.PATCH('/v1/actividades/itens-programa/{id}', { params: { path: { id: iid } }, body: corpo as never }))
      : dados(api.POST('/v1/actividades/itens-programa', { body: { ...corpo, programaDiaId: id } as never })) }),
    tirarItem: useMutation({ ...opts, mutationFn: (iid: number) =>
      dados(api.POST('/v1/actividades/itens-programa/{id}/terminar', { params: { path: { id: iid } } })) }),
  }
}

/** Prepara a programação de um dia: do modelo, ou copiando outro dia; já preenchida pela escala. */
export function usePreparar() {
  const qc = useQueryClient()
  const igreja = useIgreja()
  return useMutation({
    mutationFn: async (c: { data: string; origemId?: number }) =>
      (await dados(api.POST('/v1/actividades/programas-dia/preparar', { body: { igrejaId: igreja.id, ...c } }))) as Programa,
    onSuccess: () => qc.invalidateQueries({ queryKey: k.lista(igreja.id) }),
  })
}

/** "Sábado 14 de Novembro de 2026" (o título da folha, como na igreja). */
export function tituloDoDia(iso: string) {
  const [a, m, d] = iso.split('-').map(Number)
  const dt = new Date(Date.UTC(a, m - 1, d, 12))
  const dia = new Intl.DateTimeFormat('pt-PT', { weekday: 'long', timeZone: 'UTC' }).format(dt)
  const mes = new Intl.DateTimeFormat('pt-PT', { month: 'long', timeZone: 'UTC' }).format(dt)
  const mai = (x: string) => x.charAt(0).toUpperCase() + x.slice(1)
  return `${mai(dia)} ${d} de ${mai(mes)} de ${a}`
}
