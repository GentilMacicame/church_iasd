import { t } from '@/i18n/pt-MZ'

/** Corpo de erro da API: { erro, mensagem, campo, pedidoId } (CLAUDE.md, "Erros"). */
interface CorpoErro {
  erro?: string
  mensagem?: string
  campo?: string | null
  pedidoId?: string
}

/**
 * Erro devolvido pela API. `mensagem` vem da base de dados, em português, e mostra-se tal e qual.
 * Com `campo`, o formulário mostra-a junto ao campo; sem campo, no topo do formulário.
 */
export class ErroApi extends Error {
  readonly estado: number
  readonly codigo: string
  readonly campo: string | null
  readonly pedidoId: string | null

  constructor(estado: number, codigo: string, mensagem: string, campo: string | null = null, pedidoId: string | null = null) {
    super(mensagem)
    this.estado = estado
    this.codigo = codigo
    this.campo = campo
    this.pedidoId = pedidoId
  }

  static de(estado: number, corpo: unknown): ErroApi {
    const c = (corpo ?? {}) as CorpoErro
    return new ErroApi(estado, c.erro ?? 'erro', c.mensagem ?? t.comum.erroInesperado, c.campo ?? null, c.pedidoId ?? null)
  }

  static semLigacao(): ErroApi {
    return new ErroApi(0, 'sem_ligacao', t.comum.semLigacao)
  }

  /** Linha que existe mas não é visível também dá 404 (a base de dados decide). */
  get naoEncontrado() {
    return this.estado === 404
  }
}

export function mensagemDe(erro: unknown): string {
  return erro instanceof ErroApi ? erro.message : t.comum.erroInesperado
}
