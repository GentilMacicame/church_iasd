/**
 * Secretaria: transferências com carta (P-02), disciplina (P-03), famílias, consentimentos (RGPD/menores) e o
 * relatório da secretaria (F-SEC-10). As regras — carta só a membro activo e sem censura, voto em 2.ª leitura,
 * validade de 6 meses, censura de 1 a 12 meses, encarregado avisado se for menor — estão na base de dados.
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import { useIgreja } from '@/auth/sessao'

export type EstadoTransferencia = 'PEDIDA' | 'CARTA_EMITIDA' | 'CONCLUIDA' | 'RECUSADA' | 'EXPIRADA'
/** Linha de GET /v1/secretaria/transferencias-resumo (V27: com o nome do membro e das duas igrejas). */
export interface TransferenciaResumo {
  id: number; membroId: number; membro: string
  origemIgrejaId: number; origem: string; destinoIgrejaId: number | null; destino: string | null; destinoExterno: string | null
  dataPedido: string | null; origemVotoId: number | null; cartaEmitidaEm: string | null; validaAte: string | null; expirada: boolean
  destinoVotoId: number | null; aceiteEm: string | null; observacoes: string | null; estado: EstadoTransferencia
}
/** Igreja do directório (V27): qualquer utilizador vê o nome e a localização de todas as igrejas. */
export interface IgrejaDirectorio { id: number; nome: string; tipo: string; entidadeId: number; entidade: string; provincia: string | null; distrito: string | null; localidade: string | null }
export type Disciplina = Esquema<'Disciplina'> & { id: number; membroId: number; votoId: number; dataInicio: string; dataFim: string }
export interface CensuraActiva { id: number; igrejaId: number; membroId: number; membro: string; dataInicio: string; dataFim: string }
export type Familia = Esquema<'Familia'> & { id: number; igrejaId: number; nome: string }
export interface FamiliaResumo { id: number; igrejaId: number; nome: string; membrosActivos: number; baptizados: number }
export type TipoConsentimento = 'DADOS_PESSOAIS' | 'FOTOGRAFIAS' | 'CONTACTO_SMS' | 'CONTACTO_WHATSAPP' | 'CONTACTO_EMAIL'
export type Consentimento = Esquema<'Consentimento'> & { id: number; membroId: number; tipo: TipoConsentimento; concedido: boolean; data: string }
export interface LinhaRelatorioMensal {
  id: number; ano: number; mes: number; baptismos: number; rebaptismos: number; profissoesDeFe: number
  transferenciasEntrada: number; transferenciasSaida: number; falecimentos: number; remocoes: number; desaparecidos: number; variacao: number
}
export interface MenorPendente { id: number; igrejaId: number; nome: string; apelido: string; dataNascimento: string; faltaEncarregado: boolean; faltaConsentimento: boolean }

export const TIPOS_CONSENTIMENTO: { tipo: TipoConsentimento; rotulo: string; ajuda: string }[] = [
  { tipo: 'DADOS_PESSOAIS', rotulo: 'Dados pessoais', ajuda: 'Guardar os dados no livro de membros (obrigatório para menores, dado pelo encarregado)' },
  { tipo: 'FOTOGRAFIAS', rotulo: 'Fotografias', ajuda: 'Publicar fotografias em que aparece' },
  { tipo: 'CONTACTO_SMS', rotulo: 'SMS', ajuda: 'Receber avisos por SMS (escalas, reuniões)' },
  { tipo: 'CONTACTO_WHATSAPP', rotulo: 'WhatsApp', ajuda: 'Receber avisos por WhatsApp' },
  { tipo: 'CONTACTO_EMAIL', rotulo: 'Email', ajuda: 'Receber avisos por email' },
]

const k = (igreja: number, ...resto: unknown[]) => ['secretaria', igreja, ...resto] as const

function useInvalidar() {
  const qc = useQueryClient()
  const igreja = useIgreja()
  return () => {
    qc.invalidateQueries({ queryKey: ['secretaria', igreja.id] })
    qc.invalidateQueries({ queryKey: ['membros', igreja.id] })
    qc.invalidateQueries({ queryKey: ['livro', igreja.id] })
    qc.invalidateQueries({ queryKey: ['membro'] })
    qc.invalidateQueries({ queryKey: ['inicio', igreja.id] })
  }
}

/* ===================================================================== transferências (P-02) */
export function useTransferencias() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: k(igreja.id, 'transferencias'),
    queryFn: async () => (await dados(api.GET('/v1/secretaria/transferencias-resumo', { params: { query: { igrejaId: igreja.id } } }))) as unknown as TransferenciaResumo[],
  })
}

export function useDirectorioIgrejas() {
  return useQuery({
    queryKey: ['organizacao', 'directorio'],
    queryFn: async () => (await dados(api.GET('/v1/organizacao/directorio-igrejas', {}))) as unknown as IgrejaDirectorio[],
    staleTime: 30 * 60_000,
  })
}

export function useTransferenciasMut() {
  const invalidar = useInvalidar()
  const pedir = useMutation({
    mutationFn: (corpo: { membroId: number; origemIgrejaId: number; destinoIgrejaId?: number; destinoExterno?: string; dataPedido: string; observacoes?: string }) =>
      dados(api.POST('/v1/secretaria/transferencias', { body: corpo as never })),
    onSuccess: invalidar,
  })
  const emitirCarta = useMutation({
    mutationFn: ({ id, votoId, data }: { id: number; votoId: number; data: string }) =>
      dados(api.POST('/v1/secretaria/transferencias/{id}/emitir-carta', { params: { path: { id } }, body: { votoId, data } })),
    onSuccess: invalidar,
  })
  const concluir = useMutation({
    mutationFn: ({ id, votoId, data }: { id: number; votoId: number; data: string }) =>
      dados(api.POST('/v1/secretaria/transferencias/{id}/concluir', { params: { path: { id } }, body: { votoId, data } })),
    onSuccess: invalidar,
  })
  const recusar = useMutation({
    mutationFn: ({ id, motivo }: { id: number; motivo: string }) =>
      dados(api.POST('/v1/secretaria/transferencias/{id}/recusar', { params: { path: { id } }, body: { motivo } })),
    onSuccess: invalidar,
  })
  const anular = useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/secretaria/transferencias/{id}/terminar', { params: { path: { id } } })),
    onSuccess: invalidar,
  })
  return { pedir, emitirCarta, concluir, recusar, anular }
}

/* ===================================================================== disciplina (P-03) */
export function useDisciplinas() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: k(igreja.id, 'disciplinas'),
    // a tabela não tem a igreja: a RLS mostra só as dos membros que o utilizador vê
    queryFn: async () => (await dados(api.GET('/v1/secretaria/disciplinas', { params: { query: { limite: 200, ordem: '-dataInicio' } as never } }))).dados as Disciplina[],
  })
}

export function useCensurasActivas() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: k(igreja.id, 'censuras-activas'),
    queryFn: async () => (await dados(api.GET('/v1/secretaria/censuras-activas', { params: { query: { igrejaId: igreja.id } } }))) as unknown as CensuraActiva[],
  })
}

export function useDisciplinaMut() {
  const invalidar = useInvalidar()
  const aplicar = useMutation({
    mutationFn: (corpo: { membroId: number; votoId: number; dataInicio: string; dataFim: string; encarregadoNotificado: boolean; motivo?: string }) =>
      dados(api.POST('/v1/secretaria/disciplinas', { body: corpo as never })),
    onSuccess: invalidar,
  })
  const anular = useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/secretaria/disciplinas/{id}/terminar', { params: { path: { id } } })),
    onSuccess: invalidar,
  })
  return { aplicar, anular }
}

/* ===================================================================== famílias */
export function useFamilias() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: k(igreja.id, 'familias'),
    queryFn: async () => (await dados(api.GET('/v1/secretaria/familias', { params: { query: { igrejaId: igreja.id, limite: 200, ordem: 'nome' } as never } }))).dados as Familia[],
  })
}

export function useFamiliasResumo() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: k(igreja.id, 'familias-resumo'),
    queryFn: async () => (await dados(api.GET('/v1/secretaria/familias-resumo', { params: { query: { igrejaId: igreja.id } } }))) as unknown as FamiliaResumo[],
  })
}

export function useFamiliasMut() {
  const invalidar = useInvalidar()
  const igreja = useIgreja()
  const criar = useMutation({
    mutationFn: (corpo: { nome: string; morada?: string }) => dados(api.POST('/v1/secretaria/familias', { body: { ...corpo, igrejaId: igreja.id } as never })) as Promise<Familia>,
    onSuccess: invalidar,
  })
  const alterar = useMutation({
    mutationFn: ({ id, ...corpo }: { id: number; nome?: string; morada?: string | null }) => dados(api.PATCH('/v1/secretaria/familias/{id}', { params: { path: { id } }, body: corpo as never })),
    onSuccess: invalidar,
  })
  /** Põe (ou tira, com null) o membro na família. */
  const ligarMembro = useMutation({
    mutationFn: ({ membroId, familiaId }: { membroId: number; familiaId: number | null }) =>
      dados(api.PATCH('/v1/secretaria/membros/{id}', { params: { path: { id: membroId } }, body: { familiaId } as never })),
    onSuccess: invalidar,
  })
  const terminar = useMutation({
    mutationFn: (id: number) => dados(api.POST('/v1/secretaria/familias/{id}/terminar', { params: { path: { id } } })),
    onSuccess: invalidar,
  })
  return { criar, alterar, ligarMembro, terminar }
}

/* ===================================================================== consentimentos */
export function useConsentimentos(membroId: number) {
  return useQuery({
    queryKey: ['membro', membroId, 'consentimentos'],
    queryFn: async () => (await dados(api.GET('/v1/secretaria/consentimentos', { params: { query: { membroId, limite: 200, ordem: '-data' } as never } }))).dados as Consentimento[],
  })
}

export function useCriarConsentimento(membroId: number) {
  const qc = useQueryClient()
  const igreja = useIgreja()
  return useMutation({
    mutationFn: (corpo: { tipo: TipoConsentimento; concedido: boolean; data: string; concedidoPorMembroId?: number | null; observacoes?: string }) =>
      dados(api.POST('/v1/secretaria/consentimentos', { body: { ...corpo, membroId } as never })),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['membro', membroId, 'consentimentos'] })
      qc.invalidateQueries({ queryKey: ['secretaria', igreja.id] })
    },
  })
}

/* ===================================================================== relatórios (F-SEC-10) */
export function useRelatorioMensalSecretaria() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: k(igreja.id, 'relatorio-mensal'),
    queryFn: async () => (await dados(api.GET('/v1/secretaria/relatorio-mensal', { params: { query: { igrejaId: igreja.id } } }))) as unknown as LinhaRelatorioMensal[],
  })
}

export function useMenoresPendentes() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: k(igreja.id, 'menores-pendentes'),
    queryFn: async () => (await dados(api.GET('/v1/secretaria/menores-pendentes', { params: { query: { igrejaId: igreja.id } } }))) as unknown as MenorPendente[],
  })
}
