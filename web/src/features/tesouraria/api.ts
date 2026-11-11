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
import { centimos, deCentimos } from '@/lib/formatos'

export type Conta = Esquema<'Conta'> & { id: number; nome: string }
/** Conta da Missão: regista o que os membros pagam directamente lá (o dinheiro não está na igreja). */
export const daMissao = (c: { entidadeId?: number | null }) => c.entidadeId != null
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
export interface SaldoConta { id: number; nome: string; tipo: string; moeda: string; saldo: string; entidadeId: number | null }
/**
 * Saldo de um fundo (V21): saldo = o que está nas contas da igreja; naAssociacao = pago directamente na conta da
 * Missão; porRemeter = o que ainda se deve à Missão (negativo: a Missão já tem a mais); disponivel = o que a igreja
 * pode gastar.
 */
export interface SaldoFundo {
  fundoId: number; codigo: string; nome: string; tipo: string; entradas: string; saidas: string; saldo: string; alertaRestrito?: boolean
  percentagemRemessa: string; naAssociacao: string; porRemeter: string; disponivel: string
}

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

/** Só as contas onde está o dinheiro da igreja (sem a conta da Missão): para pagar, depositar, contar. */
export function useContasIgreja() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'contas'],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/contas', { params: { query: { igrejaId: igreja.id, limite: 50 } } }))).dados as Conta[],
    staleTime: 5 * 60_000,
    select: (l: Conta[]) => l.filter((c) => !daMissao(c)),
  })
}

/** Os fundos gerais (da Missão) e os desta igreja (as suas ofertas e projectos); os de outras igrejas não. */
export function useFundos() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: ['tesouraria', 'fundos', igreja.id],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/fundos', { params: { query: { limite: 200 } } }))).dados as Fundo[],
    select: (l: Fundo[]) => l.filter((f) => f.igrejaId == null || f.igrejaId === igreja.id),
    staleTime: 10 * 60_000,
  })
}

/** Fundo próprio da igreja (oferta especial ou projecto): 100% da igreja. */
export const daPropriaIgreja = (f: Fundo) => f.igrejaId != null

/** Criar e terminar as ofertas e projectos da igreja (a base de dados só deixa nesta igreja, sem parte da Missão). */
export function useFundosMut() {
  const igreja = useIgreja()
  const qc = useQueryClient()
  const depois = () => qc.invalidateQueries({ queryKey: ['tesouraria', 'fundos'] })
  const criar = useMutation({
    mutationFn: (v: { nome: string; tipo: 'OFERTA_ESPECIAL' | 'PROJECTO'; restrito: boolean }) => {
      // código único (o índice é de todas as igrejas): I<igreja>-<nome abreviado>-<sufixo>
      const base = v.nome.normalize('NFD').replace(/[^A-Za-z0-9]/g, '').toUpperCase().slice(0, 8) || 'OFERTA'
      const codigo = `I${igreja.id}-${base}-${Math.random().toString(36).slice(2, 5).toUpperCase()}`.slice(0, 20)
      return dados(api.POST('/v1/tesouraria/fundos', { body: { igrejaId: igreja.id, codigo, nome: v.nome, tipo: v.tipo, restrito: v.restrito, percentagemRemessa: '0.00' } as never })) as Promise<Fundo>
    },
    onSuccess: depois,
  })
  const terminar = useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/tesouraria/fundos/{id}/terminar', { params: { path: { id } } })),
    onSuccess: depois,
  })
  return { criar, terminar }
}

/** Fundos de onde a igreja pode gastar: os seus e os repartidos (a parte da igreja); não os 100% da Missão. */
export function fundosDaIgreja(l?: Fundo[]) {
  return (l ?? []).filter((f) => !f.endDate && (!f.destinoEntidadeId || Number(f.percentagemRemessa ?? 0) < 100))
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

/* ===================================================================== despesas (P-07) */
export type EstadoDespesa = 'SUBMETIDA' | 'APROVADA' | 'REJEITADA' | 'PAGA' | 'CANCELADA'
export type Despesa = Esquema<'Despesa'> & { id: number; descricao: string; valorSolicitado: string; categoriaId: number; fundoId: number; estado: EstadoDespesa }

export function useDespesas() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'despesas'],
    queryFn: async () => {
      const out: Despesa[] = []
      let depois: string | undefined
      do {
        const r = await dados(api.GET('/v1/tesouraria/despesas', { params: { query: { igrejaId: igreja.id, limite: 200, ordem: '-id', depois, incluirTerminados: true } as never } }))
        out.push(...(r.dados as Despesa[]))
        depois = r.proximo ?? undefined
      } while (depois && out.length < 1000)
      return out
    },
  })
}

export function useDespesasMut() {
  const invalidar = useInvalidar()
  const pedir = useMutation({
    mutationFn: (corpo: Corpo<'/v1/tesouraria/despesas', 'post'>) => dados(api.POST('/v1/tesouraria/despesas', { body: corpo })) as Promise<Despesa>,
    onSuccess: () => invalidar(),
  })
  /** Aprovar (pode reduzir o valor) ou rejeitar com motivo: tesouraria.fn_decidir_despesa; quem pede não decide. */
  const decidir = useMutation({
    mutationFn: ({ id, ...corpo }: { id: number; aprovar: boolean; valor?: string; motivo?: string }) =>
      dados(api.POST('/v1/tesouraria/despesas/{id}/decidir', { params: { path: { id } }, body: corpo })),
    onSuccess: () => invalidar(),
  })
  const cancelar = useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/tesouraria/despesas/{id}/terminar', { params: { path: { id } } })),
    onSuccess: () => invalidar(),
  })
  return { pedir, decidir, cancelar }
}

/* ===================================================================== remessas (P-09) */
export type EstadoRemessa = 'PREPARADA' | 'ENVIADA' | 'CONFIRMADA'
export type Remessa = Esquema<'Remessa'> & { id: number; entidadeId: number; ano: number; mes: number; estado: EstadoRemessa }
export type LinhaRemessa = Esquema<'RemessaLinha'> & { id: number; remessaId: number; fundoId: number; valor: string }
export type RemessaComLinhas = Remessa & { linhas: LinhaRemessa[] }
/** Linha de GET /v1/tesouraria/remessas-devidas (vista; a V20 acrescentou fundoId, fundoNome, entidadeId). */
export interface Devida { ano: number; mes: number; recebido: string; devido: string; remetido: string; emFalta: string; fundoId: number; fundoNome: string; fundoCodigo: string; entidadeId: number; pagoDirecto: string }

/** Associações/Missões (leitura global): para mostrar o nome da Missão. */
export function useEntidades() {
  return useQuery({
    queryKey: ['organizacao', 'entidades'],
    queryFn: async () => (await dados(api.GET('/v1/organizacao/entidades', { params: { query: { limite: 200 } } }))).dados as { id: number; nome: string; sigla?: string | null }[],
    staleTime: 30 * 60_000,
  })
}

export function useRemessasDevidas() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'remessas-devidas'],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/remessas-devidas', { params: { query: { igrejaId: igreja.id } } }))) as unknown as Devida[],
  })
}

export function useRemessas() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'remessas'],
    queryFn: async (): Promise<RemessaComLinhas[]> => {
      const rem = (await dados(api.GET('/v1/tesouraria/remessas', { params: { query: { igrejaId: igreja.id, limite: 100, ordem: '-id' } } }))).dados as Remessa[]
      return Promise.all(rem.map(async (r) => ({
        ...r,
        linhas: (await dados(api.GET('/v1/tesouraria/linhas-remessa', { params: { query: { remessaId: r.id, limite: 50 } } }))).dados as LinhaRemessa[],
      })))
    },
  })
}

export interface EnvioRemessa {
  remessa?: RemessaComLinhas
  entidadeId: number; entidadeNome: string; ano: number; mes: number
  linhas: { fundoId: number; valor: string }[]
  contaId: number; metodo: string; data: string; categoriaRemessaId: number
  /** N.º do talão do depósito na conta da Missão (ou código M-Pesa). */
  referencia?: string
  /** Já houve um depósito deste mês: esta segue o que entrou depois. */
  complementar?: boolean
}

/**
 * Envia a remessa de um mês (P-09 passos 2 e 3): cria a remessa e as linhas por fundo, paga-a com uma saída da
 * categoria de remessa (não precisa de aprovação: é a obrigação mensal) e marca-a como enviada. Se um passo
 * falhar, a remessa fica PREPARADA e retoma-se com o mesmo botão (não se cria outra).
 */
export function useEnviarRemessa() {
  const invalidar = useInvalidar()
  const igreja = useIgreja()
  return useMutation({
    mutationFn: async (p: EnvioRemessa) => {
      let rem = p.remessa
      if (!rem) {
        const r = (await dados(api.POST('/v1/tesouraria/remessas', {
          body: { igrejaId: igreja.id, entidadeId: p.entidadeId, ano: p.ano, mes: p.mes },
          params: { header: { 'Idempotency-Key': crypto.randomUUID() } } as never,
        }))) as Remessa
        const ls: LinhaRemessa[] = []
        for (const l of p.linhas) {
          ls.push((await dados(api.POST('/v1/tesouraria/linhas-remessa', { body: { remessaId: r.id, fundoId: l.fundoId, valor: l.valor } }))) as LinhaRemessa)
        }
        rem = { ...r, linhas: ls }
      }
      const total = rem.linhas.reduce((s, l) => s + centimos(l.valor), 0)
      let tr = (await dados(api.POST('/v1/tesouraria/transacoes', {
        body: {
          igrejaId: igreja.id, tipo: 'SAIDA', metodo: p.metodo, valorTotal: deCentimos(total), contaId: p.contaId, dataHora: `${p.data}T12:00:00+02:00`,
          beneficiario: p.entidadeNome, descricao: `Depósito à Missão ${p.complementar ? '(complementar) ' : ''}de ${String(rem.mes).padStart(2, '0')}/${rem.ano}`, referencia: p.referencia || undefined,
          linhas: rem.linhas.map((l) => ({ fundoId: l.fundoId, categoriaId: p.categoriaRemessaId, valor: l.valor })),
        } as NovaTransacao,
        params: { header: { 'Idempotency-Key': crypto.randomUUID() } },
      }))) as Transacao
      if (tr.estado === 'PENDENTE') tr = (await dados(api.POST('/v1/tesouraria/transacoes/{id}/confirmar', { params: { path: { id: tr.id } } }))) as Transacao
      await dados(api.POST('/v1/tesouraria/remessas/{id}/enviar', { params: { path: { id: rem.id } }, body: { transacaoId: tr.id, data: p.data } }))
      return rem
    },
    onSettled: () => invalidar(),
  })
}

export function useConfirmarRemessa() {
  const invalidar = useInvalidar()
  return useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/tesouraria/remessas/{id}/confirmar', { params: { path: { id } } })),
    onSuccess: () => invalidar(),
  })
}

/* ===================================================================== fecho do mês (P-10) */
export type Fecho = Esquema<'FechoPeriodo'> & { id: number; ano: number; mes: number }

export function useFechos() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'fechos'],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/fechos', { params: { query: { igrejaId: igreja.id, limite: 100, ordem: '-id', incluirTerminados: true } as never } }))).dados as Fecho[],
  })
}

export function useFechosMut() {
  const invalidar = useInvalidar()
  const igreja = useIgreja()
  const fechar = useMutation({
    mutationFn: ({ ano, mes }: { ano: number; mes: number }) => dados(api.POST('/v1/tesouraria/fechos', { body: { igrejaId: igreja.id, ano, mes } })),
    onSuccess: () => invalidar(),
  })
  /** Reabrir fica registado (o fecho é terminado, nada se apaga). */
  const reabrir = useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/tesouraria/fechos/{id}/reabrir', { params: { path: { id } } })),
    onSuccess: () => invalidar(),
  })
  return { fechar, reabrir }
}

/* ===================================================================== contagem do numerário (P-06 passo 1) */
export type EstadoContagem = 'ABERTA' | 'CONFERIDA' | 'DEPOSITADA'
export type Contagem = Esquema<'Contagem'> & { id: number; data: string; contaId: number; totalContado: string; contador1MembroId: number; contador2MembroId: number; estado: EstadoContagem }
export interface Conferencia {
  id: number; data: string; ocasiao: string | null; totalContado: string; totalLancado: string; diferenca: string; estado: EstadoContagem
  /** V23: o contado por partes (null nas contagens antigas, só com o total) e o lançado por partes */
  dizimos: string | null; ofertas: string | null; escolaSabatina: string | null; outras: string | null
  dizimosLancado: string; ofertasLancado: string; escolaSabatinaLancado: string; outrasLancado: string
}
/** As partes da contagem: o contado (campo) e o lançado (campo + 'Lancado'), pela ordem do envelope. */
export const PARTES_CONTAGEM = [
  { campo: 'dizimos', rotulo: 'Dízimos', ajuda: 'Envelopes e dízimos soltos' },
  { campo: 'ofertas', rotulo: 'Ofertas', ajuda: 'Oferta combinada e missionárias' },
  { campo: 'escolaSabatina', rotulo: 'Escola Sabatina', ajuda: 'Ofertas das classes' },
  { campo: 'outras', rotulo: 'Outras ofertas', ajuda: 'Especiais e projectos da igreja' },
] as const

export function useContagens() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'contagens'],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/contagens', { params: { query: { igrejaId: igreja.id, limite: 100, ordem: '-data' } } }))).dados as Contagem[],
  })
}

export function useConferencia() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'conferencia'],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/conferencia-contagens', { params: { query: { igrejaId: igreja.id } } }))) as unknown as Conferencia[],
  })
}

export function useContagensMut() {
  const invalidar = useInvalidar()
  const criar = useMutation({
    mutationFn: (corpo: Corpo<'/v1/tesouraria/contagens', 'post'>) =>
      dados(api.POST('/v1/tesouraria/contagens', { body: corpo, params: { header: { 'Idempotency-Key': crypto.randomUUID() } } as never })) as Promise<Contagem>,
    onSuccess: () => invalidar(),
  })
  const mudarEstado = useMutation({
    mutationFn: ({ id, estado }: { id: number; estado: EstadoContagem }) => dados(api.PATCH('/v1/tesouraria/contagens/{id}', { params: { path: { id } }, body: { estado } })),
    onSuccess: () => invalidar(),
  })
  return { criar, mudarEstado }
}

/* ===================================================================== estorno (P-12) */
export function useEstornar(id: number) {
  const invalidar = useInvalidar()
  return useMutation({
    mutationFn: async (corpo: { valor: string; motivo: string; linhas: { fundoId: number; categoriaId: number; valor: string }[] }) =>
      (await dados(api.POST('/v1/tesouraria/transacoes/{id}/estornar', { params: { path: { id }, header: { 'Idempotency-Key': crypto.randomUUID() } } as never, body: corpo }))) as Transacao,
    onSuccess: () => invalidar(id),
  })
}

/** Estornos já feitos de um movimento (para não estornar duas vezes sem ver). */
export function useEstornosDe(id: number) {
  const igreja = useIgreja()
  return useQuery({
    enabled: id > 0,
    queryKey: [...k.um(id), 'estornos'],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/transacoes', { params: { query: { igrejaId: igreja.id, estornoTransacaoId: id, limite: 20 } as never } }))).dados as Transacao[],
  })
}

/* ===================================================================== contribuições do mês (relatório à Missão) */
/** Linha de GET /v1/tesouraria/contribuicoes (vista; uma por fundo de cada contribuição de um membro). */
export interface Contribuicao {
  id: number; membroId: number | null; familiaId: number | null; dataHora: string; metodo: string; fundo: string; fundoId: number
  valor: string; estorno: boolean; ano: number | null; numero: number | null; pagoNaMissao: boolean | null; referencia: string | null
}

export function useContribuicoesDoMes(ano: number, mes: number) {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'contribuicoes', ano, mes],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/contribuicoes', { params: { query: { igrejaId: igreja.id, ano, mes } } }))) as unknown as Contribuicao[],
  })
}

/* ===================================================================== contas */
export function useContasMut() {
  const invalidar = useInvalidar()
  const qc = useQueryClient()
  const criar = useMutation({
    mutationFn: (corpo: Corpo<'/v1/tesouraria/contas', 'post'>) => dados(api.POST('/v1/tesouraria/contas', { body: corpo })) as Promise<Conta>,
    onSuccess: () => { invalidar(); qc.invalidateQueries({ queryKey: ['tesouraria'] }) },
  })
  return { criar }
}

/* ===================================================================== resumo para gráficos */
const MESES_CURTOS = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']

/**
 * Entradas e saídas confirmadas por mês (últimos N meses, o actual incluído), só nas contas da igreja: o que os
 * membros pagaram directamente na conta da Missão não entrou na igreja. Valores em meticais (para o gráfico; os
 * totais exactos continuam a ser somados em cêntimos).
 */
export function useResumoMensal(meses = 6) {
  const hoje = new Date()
  const inicio = new Date(Date.UTC(hoje.getFullYear(), hoje.getMonth() - (meses - 1), 1))
  const desde = inicio.toISOString().slice(0, 10)
  const movs = useMovimentos({ desde, ate: new Date().toISOString().slice(0, 10) })
  const contas = useContas()
  const chaves = Array.from({ length: meses }, (_, i) => {
    const d = new Date(Date.UTC(inicio.getUTCFullYear(), inicio.getUTCMonth() + i, 1))
    return { chave: d.toISOString().slice(0, 7), rotulo: MESES_CURTOS[d.getUTCMonth()] }
  })
  const naMissao = new Set((contas.data ?? []).filter((c) => daMissao(c)).map((c) => c.id))
  const entradas = chaves.map(() => 0), saidas = chaves.map(() => 0)
  for (const t of movs.data ?? []) {
    if (t.endDate || t.estado !== 'CONFIRMADA' || naMissao.has(t.contaId ?? 0) || t.tipo === 'TRANSFERENCIA') continue
    const i = chaves.findIndex((c) => t.dataHora.startsWith(c.chave))
    if (i < 0) continue
    const v = centimos(t.valorTotal) / 100
    if (t.tipo === 'ENTRADA') entradas[i] += v; else saidas[i] += v
  }
  return { categorias: chaves.map((c) => c.rotulo), entradas, saidas, aCarregar: movs.isPending || contas.isPending, erro: movs.error ?? contas.error }
}

/** Contribuições do ano (para mostrar, ao lançar, o que o membro já deu este ano). */
export function useContribuicoesDoAno(ano: number) {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos(igreja.id), 'contribuicoes', ano],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/contribuicoes', { params: { query: { igrejaId: igreja.id, ano } } }))) as unknown as Contribuicao[],
    staleTime: 60_000,
  })
}

/* ===================================================================== comprovativos (fotografia do talão, print M-Pesa, PDF) */
export type Documento = Esquema<'Documento'> & { id: number; nomeFicheiro: string }
const TIPOS_COMPROVATIVO = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
export const ACEITA_COMPROVATIVO = 'image/*,application/pdf'
const MAX_COMPROVATIVO = 5 * 1024 * 1024

/**
 * Prepara o ficheiro para enviar em 3G: fotografias grandes são reduzidas (lado maior 1600 px, JPEG 80%) no próprio
 * telemóvel; PDF segue como está. O tipo verdadeiro é verificado pela API pelos primeiros bytes.
 */
export async function prepararComprovativo(f: File): Promise<{ corpo: Blob; tipo: string; nome: string }> {
  const ehImagem = f.type.startsWith('image/')
  if (!ehImagem && f.type !== 'application/pdf') throw new Error('O comprovativo tem de ser uma fotografia ou um PDF.')
  let corpo: Blob = f
  let tipo = f.type
  if (ehImagem && (f.size > 400 * 1024 || !TIPOS_COMPROVATIVO.includes(f.type))) {
    try {
      const img = await createImageBitmap(f)
      const escala = Math.min(1, 1600 / Math.max(img.width, img.height))
      const tela = document.createElement('canvas')
      tela.width = Math.round(img.width * escala)
      tela.height = Math.round(img.height * escala)
      tela.getContext('2d')!.drawImage(img, 0, 0, tela.width, tela.height)
      img.close()
      const jpeg = await new Promise<Blob | null>((ok) => tela.toBlob(ok, 'image/jpeg', 0.8))
      if (jpeg && (jpeg.size < f.size || !TIPOS_COMPROVATIVO.includes(f.type))) { corpo = jpeg; tipo = 'image/jpeg' }
    } catch { /* o navegador não lê o formato (ex.: HEIC): envia-se como está e a API decide */ }
  }
  if (corpo.size > MAX_COMPROVATIVO) throw new Error('O ficheiro é demasiado grande (máximo 5 MB).')
  return { corpo, tipo, nome: f.name }
}

export async function carregarComprovativo(transacaoId: number, f: File): Promise<Documento> {
  const { corpo, tipo, nome } = await prepararComprovativo(f)
  return (await dados(api.POST('/v1/tesouraria/documentos/carregar', {
    params: { query: { transacaoId, tipo: 'COMPROVATIVO', nome } },
    body: corpo as never,
    bodySerializer: (b: unknown) => b as Blob,
    headers: { 'Content-Type': tipo },
  }))) as Documento
}

export function useDocumentos(transacaoId: number) {
  return useQuery({
    queryKey: [...k.um(transacaoId), 'documentos'],
    queryFn: async () => (await dados(api.GET('/v1/tesouraria/documentos', { params: { query: { transacaoId, limite: 50 } } }))).dados as Documento[],
  })
}

export function useCarregarComprovativo(transacaoId: number) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (f: File) => carregarComprovativo(transacaoId, f),
    onSuccess: () => qc.invalidateQueries({ queryKey: [...k.um(transacaoId), 'documentos'] }),
  })
}

/** Abre o ficheiro num separador novo (o pedido leva o token; um <a href> directo não levaria). */
export async function abrirDocumento(id: number) {
  const janela = window.open('', '_blank')
  try {
    const blob = (await dados(api.GET('/v1/tesouraria/documentos/{id}/ficheiro', { params: { path: { id } }, parseAs: 'blob' }))) as unknown as Blob
    const url = URL.createObjectURL(blob)
    if (janela) janela.location.href = url
    else window.location.href = url
    setTimeout(() => URL.revokeObjectURL(url), 60_000)
  } catch (e) {
    janela?.close()
    throw e
  }
}
