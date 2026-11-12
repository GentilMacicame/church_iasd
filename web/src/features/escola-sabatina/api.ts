/**
 * Dados da Escola Sabatina (F-ES-01…08, P-05): trimestres e sábados (da Associação), classes da igreja, a classe
 * em cada trimestre (professor e alvos), matrículas, relatórios do sábado, chamada, visitantes, pesos da pontuação
 * e as vistas (painel, classificação, evolução, em falta, conferência das ofertas).
 *
 * As regras (sábado do trimestre, presentes ≤ matriculados, fechar só com as ofertas confirmadas nos fundos certos,
 * relatório fechado não muda, quem pode reabrir) são da base de dados; aqui só se lê e grava.
 * O relatório do sábado também funciona sem rede: ver offline.ts.
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import type { paths } from '@/api/esquema'
import { useIgreja } from '@/auth/sessao'
import { hojeIso } from '@/lib/formatos'
import { comCache } from './armazem'

export type Trimestre = Esquema<'Trimestre'> & { id: number; ano: number; numero: number; dataInicio: string; dataFim: string; numSabados: number }
export type Sabado = Esquema<'Sabado'> & { id: number; trimestreId: number; numero: number; data: string; decimoTerceiro: boolean }
export type Classe = Esquema<'Classe'> & { id: number; nome: string; divisao: Divisao }
export type ClasseTrimestre = Esquema<'ClasseTrimestre'> & { id: number; classeId: number; trimestreId: number }
export type Matricula = Esquema<'Matricula'> & { id: number; classeId: number; membroId: number; dataEntrada: string }
export type Relatorio = Esquema<'Relatorio'> & {
  id: number; classeTrimestreId: number; sabadoId: number; igrejaId: number; membrosMatriculados: number; membrosPresentes: number
  estudoDiario: number; visitantes: number; filiais: number; oferta: string; oferta13Sabado: string; ofertaDespesas: string
  estado: 'ABERTO' | 'FECHADO'
}
export type Presenca = Esquema<'Presenca'> & { id: number; membroId: number; presente: boolean; estudouLicao: boolean }
export type Visitante = Esquema<'Visitante'> & { id: number; relatorioId: number; nome: string }
export type PesosPontuacao = Esquema<'PesosPontuacao'> & { id: number }
export type Divisao = NonNullable<Esquema<'Classe'>['divisao']>
type Corpo<P extends keyof paths, M extends 'post' | 'patch'> = paths[P][M] extends { requestBody?: { content: { 'application/json': infer C } } } ? C : never

/** Linhas das vistas (GET /v1/escola-sabatina/<relatório>): DECIMAL chega como texto, nunca float. */
export interface LinhaPainel {
  ano: number; trimestre: number; classesActivas: number; membros: string; presencaMedia: string | null; estudoDiarioMedio: string | null
  ofertasMissionarias: string; oferta13Sabado: string; ofertaDespesas: string; visitantes: number; baptismos: number; alvoBaptismos: number
}
export interface LinhaClassificacao {
  id: number; trimestreId: number; classe: string; divisao: Divisao; professor: string | null; pontuacao: string; lugar: number
  difPresencaMedia: string | null; difEstudoMedia: string | null; difOfertasMedia: string | null; pontosAtrasDo1o: string; situacao: string
}
export interface LinhaResumoClasse {
  id: number; trimestreId: number; classe: string; divisao: Divisao; activa: boolean; professor: string | null; sabadosRegistados: number
  mediaMatriculados: string | null; mediaPresentes: string | null; pctPresenca: string | null; pctEstudoDiario: string | null
  visitantes: number; mediaFiliais: string | null; ofertas: string; alvoOfertas: string | null; pctAlvoOfertas: string | null
  oferta13Sabado: string; ofertaDespesas: string; baptismos: number; alvoBaptismos: number; alvoMembros: number
}
export interface LinhaEvolucao { sabado: number; data: string; classe: string; pctPresenca: string | null; pctEstudoDiario: string | null; oferta: string }
export interface LinhaEmFalta { classe: string; sabado: number; data: string; secretarioMembroId: number | null; professorMembroId: number | null }
export interface LinhaConferencia {
  id: number; classe: string; data: string; ofertaRelatorio: string; lancadoTesouraria: string | null; estadoLancamento: string | null; situacao: string
}

export const DIVISOES: Divisao[] = ['ROL_DO_BERCO', 'JARDIM_DE_INFANCIA', 'PRIMARIOS', 'JUVENIS', 'ADOLESCENTES', 'JOVENS', 'ADULTOS']

/** Percentagem de uma fracção em texto ("0.8125" → "81%"). */
export function pct(v?: string | null, casas = 0): string {
  if (v == null || v === '') return '—'
  const n = Number(v) * 100
  return `${n.toLocaleString('pt-PT', { maximumFractionDigits: casas, minimumFractionDigits: casas })}%`
}

/** O trimestre de hoje; sem ele, o último que já começou; sem esse, o primeiro. */
export function trimestreActual(lista: Trimestre[]): Trimestre | undefined {
  const hoje = hojeIso()
  const ord = [...lista].sort((a, b) => b.dataInicio.localeCompare(a.dataInicio))
  return ord.find((t) => t.dataInicio <= hoje && hoje <= t.dataFim) ?? ord.find((t) => t.dataInicio <= hoje) ?? ord[ord.length - 1]
}

/** O sábado de hoje ou o último que passou; antes do trimestre, o primeiro. */
export function sabadoActual(lista: Sabado[]): Sabado | undefined {
  const hoje = hojeIso()
  const ord = [...lista].sort((a, b) => a.data.localeCompare(b.data))
  return [...ord].reverse().find((s) => s.data <= hoje) ?? ord[0]
}

export function nomeTrimestre(t: Pick<Trimestre, 'ano' | 'numero'>): string {
  return `${['I', 'II', 'III', 'IV'][t.numero - 1] ?? t.numero} trimestre de ${t.ano}`
}

/** Todos os sábados entre duas datas (ISO), inclusive. */
export function sabadosEntre(inicio: string, fim: string): string[] {
  const d = new Date(`${inicio}T12:00:00Z`)
  d.setUTCDate(d.getUTCDate() + ((6 - d.getUTCDay() + 7) % 7))
  const r: string[] = []
  while (d.toISOString().slice(0, 10) <= fim) {
    r.push(d.toISOString().slice(0, 10))
    d.setUTCDate(d.getUTCDate() + 7)
  }
  return r
}

export const chavesES = {
  todos: (igreja: number) => ['es', igreja] as const,
  trimestres: ['es-trimestres'] as const,
  sabados: (trimestre: number) => ['es-sabados', trimestre] as const,
  pesos: ['es-pesos'] as const,
  classes: (igreja: number) => ['es', igreja, 'classes'] as const,
  classesTrimestre: (igreja: number, trimestre: number) => ['es', igreja, 'classes-trimestre', trimestre] as const,
  matriculas: (classe: number) => ['es-matriculas', classe] as const,
  relatoriosSabado: (igreja: number, sabado: number) => ['es', igreja, 'relatorios', sabado] as const,
  relatorio: (id: number) => ['es-relatorio', id] as const,
  vista: (igreja: number, nome: string, trimestre?: number) => ['es', igreja, 'vista', nome, trimestre ?? 0] as const,
}

/** Lê todas as páginas de uma listagem (até `maximo` linhas). */
async function todas<T>(ler: (depois?: string) => Promise<{ dados: unknown[]; proximo?: string | null }>, maximo = 2000): Promise<T[]> {
  const r: T[] = []
  let depois: string | undefined
  do {
    const p = await ler(depois)
    r.push(...(p.dados as T[]))
    depois = p.proximo ?? undefined
  } while (depois && r.length < maximo)
  return r
}

// ------------------------------------------------------------------ leituras

export async function lerTrimestres(): Promise<Trimestre[]> {
  return todas<Trimestre>(async (depois) => dados(api.GET('/v1/escola-sabatina/trimestres', { params: { query: { limite: 200, ordem: '-dataInicio', depois } } })))
}

export function useTrimestres() {
  return useQuery({ queryKey: chavesES.trimestres, queryFn: () => comCache('trimestres', lerTrimestres), staleTime: 10 * 60_000, networkMode: 'always' })
}

export async function lerSabados(trimestre: number): Promise<Sabado[]> {
  const r = await dados(api.GET('/v1/escola-sabatina/sabados', { params: { query: { trimestreId: trimestre, limite: 50, ordem: 'numero' } } }))
  return r.dados as Sabado[]
}

export function useSabados(trimestre?: number) {
  return useQuery({
    enabled: !!trimestre, queryKey: chavesES.sabados(trimestre ?? 0), staleTime: 10 * 60_000, networkMode: 'always',
    queryFn: () => comCache(`sabados:${trimestre}`, () => lerSabados(trimestre!)),
  })
}

export async function lerClasses(igreja: number): Promise<Classe[]> {
  return todas<Classe>(async (depois) => dados(api.GET('/v1/escola-sabatina/classes', { params: { query: { igrejaId: igreja, limite: 200, ordem: 'nome', depois } } })))
}

export function useClasses() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: chavesES.classes(igreja.id), staleTime: 5 * 60_000, networkMode: 'always',
    queryFn: () => comCache(`classes:${igreja.id}`, () => lerClasses(igreja.id)),
  })
}

export async function lerClassesTrimestre(igreja: number, trimestre: number): Promise<ClasseTrimestre[]> {
  return todas<ClasseTrimestre>(async (depois) =>
    dados(api.GET('/v1/escola-sabatina/classes-trimestre', { params: { query: { igrejaId: igreja, trimestreId: trimestre, limite: 200, depois } } })))
}

export function useClassesTrimestre(trimestre?: number) {
  const igreja = useIgreja()
  return useQuery({
    enabled: !!trimestre,
    queryKey: chavesES.classesTrimestre(igreja.id, trimestre ?? 0),
    networkMode: 'always',
    queryFn: () => comCache(`classes-trimestre:${igreja.id}:${trimestre}`, () => lerClassesTrimestre(igreja.id, trimestre!)),
  })
}

export async function lerMatriculas(classe: number): Promise<Matricula[]> {
  return todas<Matricula>(async (depois) => dados(api.GET('/v1/escola-sabatina/matriculas', { params: { query: { classeId: classe, limite: 200, depois } } })))
}

export function useMatriculas(classe?: number) {
  return useQuery({ enabled: !!classe, queryKey: chavesES.matriculas(classe ?? 0), queryFn: () => lerMatriculas(classe!) })
}

/** Matrícula activa numa data (entrou até essa data e ainda não saiu). */
export function matriculadoEm(m: Matricula, data: string) {
  return m.dataEntrada <= data && (!m.dataSaida || m.dataSaida > data)
}

export async function lerRelatoriosSabado(igreja: number, sabado: number): Promise<Relatorio[]> {
  return todas<Relatorio>(async (depois) =>
    dados(api.GET('/v1/escola-sabatina/relatorios-sabado', { params: { query: { igrejaId: igreja, sabadoId: sabado, limite: 200, depois } } })))
}

export function useRelatoriosSabado(sabado?: number) {
  const igreja = useIgreja()
  return useQuery({
    enabled: !!sabado,
    queryKey: chavesES.relatoriosSabado(igreja.id, sabado ?? 0),
    networkMode: 'always',
    queryFn: () => comCache(`relatorios:${igreja.id}:${sabado}`, () => lerRelatoriosSabado(igreja.id, sabado!)),
  })
}

export function useRelatorio(id: number) {
  return useQuery({
    enabled: id > 0,
    queryKey: chavesES.relatorio(id),
    queryFn: async () => (await dados(api.GET('/v1/escola-sabatina/relatorios-sabado/{id}', { params: { path: { id } } }))) as Relatorio,
  })
}

export async function lerPresencas(igreja: number, relatorio: number): Promise<Presenca[]> {
  return todas<Presenca>(async (depois) =>
    dados(api.GET('/v1/escola-sabatina/presencas', { params: { query: { igrejaId: igreja, relatorioId: relatorio, limite: 200, depois } } })))
}

export async function lerVisitantesRelatorio(relatorio: number): Promise<Visitante[]> {
  return (await dados(api.GET('/v1/escola-sabatina/relatorios-sabado/{id}/visitantes', { params: { path: { id: relatorio } } }))) as unknown as Visitante[]
}

export function usePesos() {
  return useQuery({
    queryKey: chavesES.pesos,
    queryFn: async () => (await dados(api.GET('/v1/escola-sabatina/pesos-pontuacao', { params: { query: { limite: 200 } } }))).dados as PesosPontuacao[],
    staleTime: 10 * 60_000,
  })
}

type Vista = '/v1/escola-sabatina/painel' | '/v1/escola-sabatina/classificacao' | '/v1/escola-sabatina/resumo-classes'
  | '/v1/escola-sabatina/evolucao' | '/v1/escola-sabatina/relatorios-em-falta' | '/v1/escola-sabatina/conferencia-ofertas'

function useVista<T>(caminho: Vista, trimestre?: number, comTrimestre = true) {
  const igreja = useIgreja()
  return useQuery({
    enabled: !comTrimestre || !!trimestre,
    queryKey: chavesES.vista(igreja.id, caminho, comTrimestre ? trimestre : undefined),
    queryFn: async () =>
      (await dados(api.GET(caminho, { params: { query: { igrejaId: igreja.id, ...(comTrimestre ? { trimestreId: trimestre } : {}) } } } as never))) as unknown as T[],
  })
}

export const usePainel = (trimestre?: number) => useVista<LinhaPainel>('/v1/escola-sabatina/painel', trimestre)
export const useClassificacao = (trimestre?: number) => useVista<LinhaClassificacao>('/v1/escola-sabatina/classificacao', trimestre)
export const useResumoClasses = (trimestre?: number) => useVista<LinhaResumoClasse>('/v1/escola-sabatina/resumo-classes', trimestre)
export const useEvolucao = (trimestre?: number) => useVista<LinhaEvolucao>('/v1/escola-sabatina/evolucao', trimestre)
export const useEmFalta = () => useVista<LinhaEmFalta>('/v1/escola-sabatina/relatorios-em-falta', undefined, false)
export const useConferencia = () => useVista<LinhaConferencia>('/v1/escola-sabatina/conferencia-ofertas', undefined, false)

// ------------------------------------------------------------------ gravações

function useInvalidarES() {
  const qc = useQueryClient()
  const igreja = useIgreja()
  return () => {
    qc.invalidateQueries({ queryKey: chavesES.todos(igreja.id) })
    qc.invalidateQueries({ queryKey: ['es-relatorio'] })
    qc.invalidateQueries({ queryKey: ['es-matriculas'] })
    qc.invalidateQueries({ queryKey: ['es-pacote'] })
  }
}

/** F-ES-01: o trimestre e logo os seus sábados (um por sábado do período; o 13.º sábado marcado). */
export function useCriarTrimestre() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async ({ trimestre, decimoTerceiro }: { trimestre: Omit<Corpo<'/v1/escola-sabatina/trimestres', 'post'>, 'numSabados'>; decimoTerceiro: string }) => {
      const datas = sabadosEntre(trimestre.dataInicio!, trimestre.dataFim!)
      const t = (await dados(api.POST('/v1/escola-sabatina/trimestres', { body: { ...trimestre, numSabados: datas.length } }))) as Trimestre
      for (const [i, data] of datas.entries()) {
        await dados(api.POST('/v1/escola-sabatina/sabados', { body: { trimestreId: t.id, numero: i + 1, data, decimoTerceiro: data === decimoTerceiro } }))
      }
      return t
    },
    onSettled: () => {
      qc.invalidateQueries({ queryKey: chavesES.trimestres })
      qc.invalidateQueries({ queryKey: ['es-sabados'] })
    },
  })
}

/** Cria os sábados que faltam a um trimestre (ex.: a criação parou a meio por falta de rede). */
export function useCriarSabadosEmFalta() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async ({ trimestre, existentes }: { trimestre: Trimestre; existentes: Sabado[] }) => {
      const datas = sabadosEntre(trimestre.dataInicio, trimestre.dataFim)
      const tem = new Set(existentes.map((s) => s.data))
      const ultimo13 = !existentes.some((s) => s.decimoTerceiro)
      for (const [i, data] of datas.entries()) {
        if (tem.has(data)) continue
        await dados(api.POST('/v1/escola-sabatina/sabados', {
          body: { trimestreId: trimestre.id, numero: i + 1, data, decimoTerceiro: ultimo13 && i === datas.length - 1 },
        }))
      }
    },
    onSettled: () => qc.invalidateQueries({ queryKey: ['es-sabados'] }),
  })
}

export function useAlterarTrimestre() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, corpo }: { id: number; corpo: Corpo<'/v1/escola-sabatina/trimestres/{id}', 'patch'> }) =>
      dados(api.PATCH('/v1/escola-sabatina/trimestres/{id}', { params: { path: { id } }, body: corpo })),
    onSuccess: () => qc.invalidateQueries({ queryKey: chavesES.trimestres }),
  })
}

/** Muda o sábado da oferta do 13.º sábado (só pode haver um por trimestre: tira-se primeiro o anterior). */
export function useMarcar13() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async ({ anterior, novo }: { anterior?: number; novo: number }) => {
      if (anterior) await dados(api.PATCH('/v1/escola-sabatina/sabados/{id}', { params: { path: { id: anterior } }, body: { decimoTerceiro: false } }))
      await dados(api.PATCH('/v1/escola-sabatina/sabados/{id}', { params: { path: { id: novo } }, body: { decimoTerceiro: true } }))
    },
    onSettled: () => qc.invalidateQueries({ queryKey: ['es-sabados'] }),
  })
}

export function useGravarPesos() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, corpo }: { id?: number; corpo: Corpo<'/v1/escola-sabatina/pesos-pontuacao', 'post'> }) =>
      id
        ? dados(api.PATCH('/v1/escola-sabatina/pesos-pontuacao/{id}', { params: { path: { id } }, body: corpo }))
        : dados(api.POST('/v1/escola-sabatina/pesos-pontuacao', { body: corpo })),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: chavesES.pesos })
      qc.invalidateQueries({ queryKey: ['es'] })
    },
  })
}

export function useCriarClasse() {
  const invalidar = useInvalidarES()
  return useMutation({
    mutationFn: async (corpo: Corpo<'/v1/escola-sabatina/classes', 'post'>) => (await dados(api.POST('/v1/escola-sabatina/classes', { body: corpo }))) as Classe,
    onSuccess: invalidar,
  })
}

export function useAlterarClasse() {
  const invalidar = useInvalidarES()
  return useMutation({
    mutationFn: ({ id, corpo }: { id: number; corpo: Corpo<'/v1/escola-sabatina/classes/{id}', 'patch'> }) =>
      dados(api.PATCH('/v1/escola-sabatina/classes/{id}', { params: { path: { id } }, body: corpo })),
    onSuccess: invalidar,
  })
}

export function useTerminarClasse() {
  const invalidar = useInvalidarES()
  return useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/escola-sabatina/classes/{id}/terminar', { params: { path: { id } } })),
    onSuccess: invalidar,
  })
}

/** F-ES-03: cria ou altera a classe no trimestre (professor, auxiliar, secretário, alvos, activa ou não). */
export function useGravarClasseTrimestre() {
  const invalidar = useInvalidarES()
  return useMutation({
    mutationFn: ({ id, corpo }: { id?: number; corpo: Corpo<'/v1/escola-sabatina/classes-trimestre', 'post'> }) =>
      id
        ? dados(api.PATCH('/v1/escola-sabatina/classes-trimestre/{id}', { params: { path: { id } }, body: corpo }))
        : dados(api.POST('/v1/escola-sabatina/classes-trimestre', { body: corpo })),
    onSuccess: invalidar,
  })
}

export function useMatricular(classe: number) {
  const invalidar = useInvalidarES()
  return useMutation({
    mutationFn: (membroId: number) =>
      dados(api.POST('/v1/escola-sabatina/matriculas', { body: { classeId: classe, membroId, dataEntrada: hojeIso() } })),
    onSuccess: invalidar,
  })
}

/** Sair da classe: a matrícula fica no histórico com a data de saída (nada se apaga). */
export function useTirarMatricula() {
  const invalidar = useInvalidarES()
  return useMutation({
    mutationFn: (id: number) => dados(api.PATCH('/v1/escola-sabatina/matriculas/{id}', { params: { path: { id } }, body: { dataSaida: hojeIso() } })),
    onSuccess: invalidar,
  })
}

export function useFecharRelatorio() {
  const invalidar = useInvalidarES()
  return useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/escola-sabatina/relatorios-sabado/{id}/fechar', { params: { path: { id } } })),
    onSuccess: invalidar,
  })
}

export function useReabrirRelatorio() {
  const invalidar = useInvalidarES()
  return useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/escola-sabatina/relatorios-sabado/{id}/reabrir', { params: { path: { id } } })),
    onSuccess: invalidar,
  })
}

/** P-05 passo 5: o tesoureiro lança as três ofertas (uma linha por fundo) e liga-as ao relatório. */
export function useLancarOfertas(id: number) {
  const invalidar = useInvalidarES()
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ corpo, chave }: { corpo: Corpo<'/v1/escola-sabatina/relatorios-sabado/{id}/ofertas', 'post'>; chave: string }) =>
      dados(api.POST('/v1/escola-sabatina/relatorios-sabado/{id}/ofertas', { params: { path: { id }, header: { 'Idempotency-Key': chave } }, body: corpo })),
    onSuccess: () => {
      invalidar()
      qc.invalidateQueries({ queryKey: ['tesouraria'] })
    },
  })
}

/** F-ES-06: o visitante passou a membro (ou interessado registado). */
export function useVisitanteTornouSe() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, membroId }: { id: number; membroId: number | null }) =>
      dados(api.PATCH('/v1/escola-sabatina/visitantes/{id}', { params: { path: { id } }, body: { tornouSeMembroId: membroId ?? undefined } as never })),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['es-visitantes'] }),
  })
}

/** Visitantes recentes desta igreja (até 600; a RLS só deixa ver os das igrejas do utilizador). */
export function useVisitantes() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: ['es-visitantes', igreja.id],
    queryFn: () => todas<Visitante>(async (depois) =>
      dados(api.GET('/v1/escola-sabatina/visitantes', { params: { query: { limite: 200, ordem: '-id', depois } } })), 600),
  })
}
