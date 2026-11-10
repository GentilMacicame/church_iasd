/**
 * Tema claro/escuro: classe .dark no <html>, guardado no browser (o index.html aplica-o antes de desenhar,
 * para não piscar). Um só estado partilhado por todos os botões que o alternam.
 */
import { useSyncExternalStore } from 'react'

const CHAVE = 'igreja.tema'
const ouvintes = new Set<() => void>()

function escuroAgora() {
  return document.documentElement.classList.contains('dark')
}

function definir(escuro: boolean) {
  document.documentElement.classList.toggle('dark', escuro)
  document.querySelector('meta[name="theme-color"]')?.setAttribute('content', escuro ? '#0b1120' : '#f8fafc')
  try {
    localStorage.setItem(CHAVE, escuro ? 'escuro' : 'claro')
  } catch {
    /* sem armazenamento: fica só nesta sessão */
  }
  ouvintes.forEach((f) => f())
}

export function useTema() {
  const escuro = useSyncExternalStore((f) => (ouvintes.add(f), () => ouvintes.delete(f)), escuroAgora)
  return { escuro, alternar: () => definir(!escuroAgora()) }
}
