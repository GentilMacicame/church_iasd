/**
 * Formatos de ecrã (CLAUDE.md): datas dd/mm/aaaa; dinheiro "1 500,50 MT" no ecrã e "1500.50" na API.
 * As datas da API vêm em ISO ("2026-11-14" ou "2026-11-14T10:00:00+02:00").
 */
const LOCALE = 'pt-MZ'
const FUSO = 'Africa/Maputo'

function paraData(iso: string): Date {
  // "2026-11-14" é uma data sem hora: lê-se ao meio-dia de Maputo, para não mudar de dia por causa do fuso
  return /^\d{4}-\d{2}-\d{2}$/.test(iso) ? new Date(`${iso}T12:00:00+02:00`) : new Date(iso)
}

/** 14/11/2026 */
export function data(iso?: string | null): string {
  if (!iso) return '—'
  return new Intl.DateTimeFormat(LOCALE, { day: '2-digit', month: '2-digit', year: 'numeric', timeZone: FUSO }).format(paraData(iso))
}

/** sábado, 14 de novembro */
export function dataPorExtenso(iso: string): string {
  return new Intl.DateTimeFormat(LOCALE, { weekday: 'long', day: 'numeric', month: 'long', timeZone: FUSO }).format(paraData(iso))
}

/** Hoje em Maputo, em ISO (2026-11-10). */
export function hojeIso(): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone: FUSO }).format(new Date())
}

/** Dias inteiros de hoje até à data (0 = hoje). */
export function diasAte(iso: string): number {
  const a = paraData(hojeIso()).getTime()
  const b = paraData(iso).getTime()
  return Math.round((b - a) / 86_400_000)
}

/** Idade em anos completos, ou null. */
export function idade(nascimento?: string | null): number | null {
  if (!nascimento) return null
  const [a, m, d] = nascimento.split('-').map(Number)
  const [ha, hm, hd] = hojeIso().split('-').map(Number)
  return ha - a - (hm < m || (hm === m && hd < d) ? 1 : 0)
}

/** "650.00" → "650,00 MT"; "1500.5" → "1 500,50 MT". Nunca passa por float: o valor é texto. */
export function dinheiro(valor?: string | null, moeda = 'MT'): string {
  if (valor == null || valor === '') return '—'
  const negativo = valor.startsWith('-')
  const [inteiro, dec = ''] = valor.replace('-', '').split('.')
  const grupos = inteiro.replace(/\B(?=(\d{3})+(?!\d))/g, ' ')
  return `${negativo ? '−' : ''}${grupos},${(dec + '00').slice(0, 2)} ${moeda}`
}

/** "1 500,50" ou "1500.5" escrito pelo utilizador → "1500.50" para a API; null se inválido. */
export function dinheiroParaApi(texto: string): string | null {
  const limpo = texto.replace(/[\s ]/g, '').replace(/MT$/i, '')
  const m = /^(-?)(\d{1,14})(?:[.,](\d{1,2}))?$/.exec(limpo)
  if (!m) return null
  return `${m[1]}${m[2]}.${(m[3] ?? '').padEnd(2, '0')}`
}

/** Iniciais de um nome: "Elisa Fumo" → "EF". */
export function iniciais(nome: string, apelido?: string | null): string {
  const partes = `${nome} ${apelido ?? ''}`.trim().split(/\s+/)
  return ((partes[0]?.[0] ?? '') + (partes.length > 1 ? partes[partes.length - 1][0] : '')).toUpperCase()
}

/** Tom estável para a pessoa (identidade, não dado): matiz a partir do id, tons claros. */
export function tomPessoa(id: number): { fundo: string; tinta: string } {
  const matiz = (id * 137) % 360
  return { fundo: `hsl(${matiz} 45% 93%)`, tinta: `hsl(${matiz} 45% 26%)` }
}
