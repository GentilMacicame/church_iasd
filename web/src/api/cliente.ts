/**
 * Cliente da API, com os tipos gerados de api/openapi.yaml (npm run gerar:api). Nunca escrever tipos
 * da API à mão: usa-se `Esquema<'Membro'>` e os caminhos de `paths`.
 *
 * Sessão: o token de acesso (15 min) fica só em memória; o de renovação (30 dias) é um cookie HttpOnly
 * que o browser envia sozinho para /v1/auth/renovar. Um 401 renova uma vez e repete o pedido.
 */
import createClient from 'openapi-fetch'
import type { components, paths } from './esquema'
import { ErroApi } from './erros'

export type Esquema<N extends keyof components['schemas']> = components['schemas'][N]

let tokenAcesso: string | null = null
let aoTerminarSessao: (() => void) | null = null
let renovacaoEmCurso: Promise<boolean> | null = null

export function definirToken(token: string | null) {
  tokenAcesso = token
}

export function temToken() {
  return tokenAcesso !== null
}

/** Chamado quando a renovação falha (sessão expirada ou terminada noutro sítio). */
export function aoSessaoTerminar(fn: () => void) {
  aoTerminarSessao = fn
}

/** Pede um token novo com o cookie de renovação. Um só pedido de cada vez, mesmo com vários 401. */
export function renovarSessao(): Promise<boolean> {
  renovacaoEmCurso ??= (async () => {
    try {
      const r = await fetch('/v1/auth/renovar', { method: 'POST', credentials: 'same-origin' })
      if (!r.ok) return false
      const corpo = (await r.json()) as { tokenAcesso: string }
      tokenAcesso = corpo.tokenAcesso
      return true
    } catch {
      return false
    } finally {
      setTimeout(() => (renovacaoEmCurso = null), 0)
    }
  })()
  return renovacaoEmCurso
}

async function fetchComSessao(pedido: Request): Promise<Response> {
  const comToken = (token: string | null) => {
    const p = pedido.clone()
    if (token) p.headers.set('Authorization', `Bearer ${token}`)
    return p
  }
  const resposta = await fetch(comToken(tokenAcesso))
  const publico = new URL(pedido.url).pathname.startsWith('/v1/auth/')
  if (resposta.status !== 401 || publico) return resposta
  if (await renovarSessao()) return fetch(comToken(tokenAcesso))
  tokenAcesso = null
  aoTerminarSessao?.()
  return resposta
}

export const api = createClient<paths>({ baseUrl: '', fetch: fetchComSessao, credentials: 'same-origin' })

/**
 * Devolve os dados ou lança ErroApi com a mensagem da API (já em português) e o campo, se houver.
 * Uso: const membro = await dados(api.GET('/v1/secretaria/membros/{id}', { params: { path: { id } } }))
 */
export async function dados<T>(pedido: Promise<{ data?: T; error?: unknown; response: Response }>): Promise<T> {
  let r: { data?: T; error?: unknown; response: Response }
  try {
    r = await pedido
  } catch {
    throw ErroApi.semLigacao()
  }
  if (r.response.ok) return r.data as T
  throw ErroApi.de(r.response.status, r.error)
}
