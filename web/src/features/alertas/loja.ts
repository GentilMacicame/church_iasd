/**
 * Alertas: tudo o que espera uma acção do utilizador, em todo o sistema (secretaria, reuniões, tesouraria, Escola
 * Sabatina, escalas). Cada fonte (Fontes.tsx) só existe para quem pode agir sobre aquele assunto e publica aqui os
 * seus alertas; o sino (Sino.tsx) e o "Precisa de atenção" do Início lêem daqui.
 *
 * Um alerta é um assunto concreto ("Aprovar a saída de 1 500,00 MT · Luz") com a ligação para o ecrã onde se
 * resolve. Desaparece quando o assunto fica resolvido (as fontes usam as consultas dos módulos: o que se aprova
 * num ecrã invalida a consulta e o sino actualiza-se sozinho). "Visto" só tira o destaque de novo.
 */
import { useSyncExternalStore, type ComponentType } from 'react'

export type TomAlerta = 'destructive' | 'warning' | 'info'
export type ModuloAlerta = 'Secretaria' | 'Reuniões' | 'Tesouraria' | 'Escola Sabatina' | 'Escalas'

export interface Alerta {
  /** estável por assunto (ex.: "saida:123"): serve para marcar como visto */
  chave: string
  modulo: ModuloAlerta
  icone: ComponentType<{ className?: string }>
  titulo: string
  detalhe?: string
  /** o ecrã onde o assunto se resolve */
  para: string
  tom: TomAlerta
  /** data do assunto (ISO), para ordenar dentro do mesmo tom */
  data?: string
}

interface EstadoFonte { itens: Alerta[]; aCarregar: boolean }

const fontes = new Map<string, EstadoFonte>()
let activas = new Set<string>()
let instantaneo: { alertas: Alerta[]; aCarregar: boolean; iniciado: boolean } = { alertas: [], aCarregar: true, iniciado: false }
const ouvintes = new Set<() => void>()

const PESO: Record<TomAlerta, number> = { destructive: 0, warning: 1, info: 2 }

function recalcular() {
  const alertas = [...activas].flatMap((f) => fontes.get(f)?.itens ?? [])
    .sort((a, b) => PESO[a.tom] - PESO[b.tom] || (b.data ?? '').localeCompare(a.data ?? ''))
  const aCarregar = [...activas].some((f) => fontes.get(f)?.aCarregar ?? true)
  instantaneo = { alertas, aCarregar, iniciado: true }
  ouvintes.forEach((o) => o())
}

/** As fontes montadas agora (as outras deixam de contar: ex. mudou de igreja ou de perfil). */
export function registarFontes(nomes: string[]) {
  activas = new Set(nomes)
  for (const f of [...fontes.keys()]) if (!activas.has(f)) fontes.delete(f)
  recalcular()
}

export function publicar(fonte: string, itens: Alerta[], aCarregar: boolean) {
  const antes = fontes.get(fonte)
  if (antes && !aCarregar && antes.aCarregar === aCarregar && mesmos(antes.itens, itens)) return
  fontes.set(fonte, { itens, aCarregar })
  recalcular()
}

function mesmos(a: Alerta[], b: Alerta[]) {
  return a.length === b.length && a.every((x, i) => x.chave === b[i].chave && x.titulo === b[i].titulo && x.detalhe === b[i].detalhe && x.tom === b[i].tom)
}

/** Todos os alertas do utilizador na igreja escolhida, os mais graves primeiro. */
export function useAlertas() {
  return useSyncExternalStore(
    (o) => { ouvintes.add(o); return () => { ouvintes.delete(o) } },
    () => instantaneo,
  )
}

/** Mostra no máximo `max` alertas de uma lista e junta o resto num só ("e mais N…"). */
export function limitar(itens: Alerta[], max: number, resto: (n: number) => Alerta): Alerta[] {
  return itens.length <= max ? itens : [...itens.slice(0, max - 1), resto(itens.length - max + 1)]
}

// ------------------------------------------------------------------ vistos (só neste aparelho)

const chaveVistos = (usuario: number, igreja: number) => `igreja.alertas-vistos.${usuario}.${igreja}`

export function lerVistos(usuario: number, igreja: number): Set<string> {
  try {
    return new Set(JSON.parse(localStorage.getItem(chaveVistos(usuario, igreja)) ?? '[]') as string[])
  } catch {
    return new Set()
  }
}

/** Marca os alertas actuais como vistos (e esquece os que já foram resolvidos). */
export function marcarVistos(usuario: number, igreja: number, chaves: string[]) {
  try { localStorage.setItem(chaveVistos(usuario, igreja), JSON.stringify(chaves)) } catch { /* sem armazenamento */ }
}
