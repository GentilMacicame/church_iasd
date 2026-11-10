/**
 * Tesouraria (P-06, P-08): contas, fundos, categorias, movimentos (cabeçalho + linhas por fundo), confirmar,
 * aprovar saídas (por outra pessoa), recibos. As regras de dinheiro (soma das linhas, fundos da Associação só
 * saem em remessa, mês fechado, quem regista não aprova) são da base de dados.
 *
 * Pedidos que criam dinheiro levam Idempotency-Key: repetir o mesmo pedido (rede que caiu a meio) não duplica.
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import type { paths } from '@/api/esquema'
import { useIgreja } from '@/auth/sessao'

export type Conta = Esquema<'Conta'> & { id: number; nome: string }
export type Fundo = Esquema<'Fundo'> & { id: number; nome: string; codigo: string; tipo: TipoFundo }
export type Categoria = Esquema<'Categoria'> & { id: number; nome: string; codigo: string; tipo: 'RECEITA' | 'DESPESA' }
export type Transacao = Esquema<'Transacao'> & { id: number; tipo: TipoTransacao; valorTotal: string; dataHora: string; estado: EstadoTransacao }
export type Linha = Esquema<'TransacaoLinha'> & { id: number; fundoId: number; categoriaId: number; valor: string }
export type Recibo = Esquema<'Recibo'> & { id: number; ano: number; numero: number }
export type TipoTransacao = NonNullable<Esquema<'Transacao'>['tipo']>
export type EstadoTransacao = NonNullable<Esquema<'Transacao'>['estado']>
export type TipoFundo = NonNullable<Esquema<'Fundo'>['tipo']>
type Corpo<P extends keyof paths, M extends 'post' | 'patch'> = paths[P][M] extends { requestBody?: { content: { 'application/json': infer C } } } ? C : never

/** Linha de GET /v1/tesouraria/saldos-contas e saldos-fundos (vistas). */
export interface SaldoConta { id: number; nome: string; tipo: string; moeda: string; saldo: string }
export interface SaldoFundo { fundoId?: number; codigo: string; nome: string; tipo: string; entradas: string; saidas: string; saldo: string; alertaRestrito?: boolean }

/** Categoria sugerida para cada tipo de fundo (o tesoureiro pode mudar). */
export const CATEGORIA_POR_FUNDO: Record<string, string> = {
  DIZIMO: 'R1', OFERTA_MISSIONARIA: 'R2', OFERTA_COMBINADA: 'R2', OFERTA_ESPECIAL: 'R2', ORCAMENTO_LOCAL: 'R2',
  ES_MISSOES: 'R3', ES_13_SABADO: 'R3', ES_DESPESAS: 'R3', PROJECTO: 'R4',
}

const k = {
  todos: (igreja: number) => ['tesouraria', igreja] as const,
  um: (id: number) => ['transacao', id] as const,
}

export function useContas() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'contas'],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/contas', { params: { query: { igrejaId: igreja.id, limite: 50 } } }))).dados as Conta[],
    staleTime: 5 * 60_000,
  })
}

export function useFundos() {
  return useQuery({
    queryKey: ['tesouraria', 'fundos'],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/fundos', { params: { query: { limite: 100 } } }))).dados as Fundo[],
    staleTime: 10 * 60_000,
  })
}

export function useCategorias() {
  return useQuery({
    queryKey: ['tesouraria', 'categorias'],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/categorias', { params: { query: { limite: 200 } } }))).dados as Categoria[],
    staleTime: 10 * 60_000,
  })
}

export function useSaldosContas() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'saldos-contas'],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/saldos-contas', { params: { query: { igrejaId: igreja.id } } }))) as unknown as SaldoConta[],
  })
}

export function useSaldosFundos() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'saldos-fundos'],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/saldos-fundos', { params: { query: { igrejaId: igreja.id } } }))) as unknown as SaldoFundo[],
  })
}

export interface FiltrosMovimentos { tipo?: TipoTransacao; estado?: EstadoTransacao; desde?: string; ate?: string }

/** Movimentos de um período (lê todas as páginas: um mês de uma igreja são dezenas ou centenas). */
export function useMovimentos(f: FiltrosMovimentos) {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'movimentos', f],
    queryFn: async () => {
      const out: Transacao[] = []
      let depois: string | undefined
      do {
        const r = await dados(api.GET('/v1/tesouraria/transacoes', {
          params: { query: { igrejaId: igreja.id, limite: 200, ordem: '-dataHora', depois, tipo: f.tipo, estado: f.estado, desde: f.desde, ate: f.ate } },
        }))
        out.push(...(r.dados as Transacao[]))
        depois = r.proximo ?? undefined
      } while (depois && out.length < 2000)
      return out
    },
  })
}

export function useTransacao(id: number) {
  return useQuery({
    enabled: id > 0,
    queryKey: k.um(id),
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/transacoes/{id}', { params: { path: { id } } }))) as Transacao,
  })
}

export function useLinhas(id: number) {
  return useQuery({
    enabled: id > 0,
    queryKey: [...k.um(id), 'linhas'],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/transacoes/{id}/linhas', { params: { path: { id } } }))) as unknown as Linha[],
  })
}

export function useRecibo(transacaoId: number) {
  const igreja = useIgreja()
  return useQuery({
    enabled: transacaoId > 0,
    queryKey: [...k.um(transacaoId), 'recibo'],
    queryFn: async () => ((await dados(api.GET('/v1/tesouraria/recibos', { params: { query: { igrejaId: igreja.id, transacaoId, limite: 1 } } }))).dados[0] ?? null) as Recibo | null,
  })
}

function useInvalidar() {
  const qc = useQueryClient()
  const igreja = useIgreja()
  return (id?: number) => {
    qc.invalidateQueries({ queryKey: k.todos(igreja.id) })
    qc.invalidateQueries({ queryKey: ['inicio', igreja.id] })
    if (id) qc.invalidateQueries({ queryKey: k.um(id) })
  }
}

type NovaTransacao = Corpo<'/v1/tesouraria/transacoes', 'post'>

/**
 * Cria o movimento (cabeçalho + linhas) com uma Idempotency-Key; uma entrada pode ser confirmada logo a seguir.
 * A chave é gerada uma vez por formulário: se a rede cair e o tesoureiro carregar de novo, não duplica.
 */
export function useCriarMovimento() {
  const invalidar = useInvalidar()
  return useMutation({
    mutationFn: async ({ corpo, chave, confirmar, recibo }: { corpo: NovaTransacao; chave: string; confirmar: boolean; recibo?: boolean }) => {
      let t = (await dados(api.POST('/v1/tesouraria/transacoes', { body: corpo, params: { header: { 'Idempotency-Key': chave } } }))) as Transacao
      if (confirmar && t.estado === 'PENDENTE') {
        t = (await dados(api.POST('/v1/tesouraria/transacoes/{id}/confirmar', { params: { path: { id: t.id } } }))) as Transacao
      }
      let r: Recibo | null = null
      let erroRecibo: unknown = null
      if (recibo && t.estado === 'CONFIRMADA') {
        // se falhar, o movimento fica gravado e o recibo emite-se depois na ficha do movimento (o ecrã avisa)
        try {
          r = (await dados(api.POST('/v1/tesouraria/transacoes/{id}/recibo', { params: { path: { id: t.id }, header: { 'Idempotency-Key': crypto.randomUUID() } } as never }))) as unknown as Recibo
        } catch (e) {
          erroRecibo = e
        }
      }
      return { transacao: t, recibo: r, erroRecibo }
    },
    onSuccess: ({ transacao }) => invalidar(transacao.id),
  })
}

export function useAccao(id: number) {
  const invalidar = useInvalidar()
  const confirmar = useMutation({
    mutationFn: () => dados(api.POST('/v1/tesouraria/transacoes/{id}/confirmar', { params: { path: { id } } })),
    onSuccess: () => invalidar(id),
  })
  const aprovar = useMutation({
    mutationFn: () => dados(api.POST('/v1/tesouraria/transacoes/{id}/aprovar', { params: { path: { id } } })),
    onSuccess: () => invalidar(id),
  })
  const recibo = useMutation({
    // um recibo por pedido: a chave evita gastar dois números se o pedido se repetir
    mutationFn: () => dados(api.POST('/v1/tesouraria/transacoes/{id}/recibo', { params: { path: { id }, header: { 'Idempotency-Key': crypto.randomUUID() } } as never })),
    onSuccess: () => invalidar(id),
  })
  const anular = useMutation({
    mutationFn: () => dados(api.POST('/v1/tesouraria/transacoes/{id}/terminar', { params: { path: { id } } })),
    onSuccess: () => invalidar(id),
  })
  return { confirmar, aprovar, recibo, anular }
}
