/** Contas dos mandatos (V31) para mostrar antes de gravar: a base de dados guarda e valida as datas. */
import { fimDoMandato } from './api'

export const ISO = /^\d{4}-\d{2}-\d{2}$/
export const diaSeguinte = (iso: string) => new Date(Date.parse(iso + 'T12:00:00Z') + 86_400_000).toISOString().slice(0, 10)

/** Duração do mandato em anos inteiros (1–5), ou null se o fim não calhar num aniversário. */
export function anosInteiros(inicio: string, fim: string) {
  for (let n = 1; n <= 5; n++) if (fimDoMandato(inicio, n) === fim) return n
  return null
}
export function duracaoTexto(inicio: string, fim: string) {
  const n = anosInteiros(inicio, fim)
  if (n) return `${n} ${n === 1 ? 'ano' : 'anos'}`
  const meses = Math.max(1, Math.round((Date.parse(fim) - Date.parse(inicio)) / (30.44 * 86_400_000)))
  return `${meses} ${meses === 1 ? 'mês' : 'meses'}`
}
/** Nome sugerido: "Mandato 2027" ou "Mandato 2027–2028". */
export function nomeSugerido(inicio: string, fim: string) {
  if (!ISO.test(inicio) || !ISO.test(fim)) return ''
  const a = inicio.slice(0, 4), b = fim.slice(0, 4)
  return a === b ? `Mandato ${a}` : `Mandato ${a}–${b}`
}
