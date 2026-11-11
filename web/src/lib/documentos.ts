/**
 * Documentos: imprimir ou guardar em PDF o que está no ecrã (o navegador oferece "Guardar como PDF", também no
 * telemóvel), com um nome de ficheiro útil; e descarregar um relatório da API em PDF ou CSV (?formato=).
 */
import { api } from '@/api/cliente'
import { ErroApi } from '@/api/erros'

/** O nome que o navegador propõe ao guardar o PDF é o título da página: muda-o só durante a impressão. */
export function imprimirComo(nomeFicheiro: string) {
  const antes = document.title
  document.title = nomeFicheiro.replace(/[\/:*?"<>|]/g, '-')
  const repor = () => { document.title = antes; window.removeEventListener('afterprint', repor) }
  window.addEventListener('afterprint', repor)
  window.print()
  setTimeout(repor, 60_000)
}

/** Descarrega um relatório da API (rota de GET /v1/...) no formato pedido. */
export async function descarregarRelatorio(caminho: string, query: Record<string, string | number | undefined>, formato: 'pdf' | 'csv', nome: string) {
  const r = await (api.GET as unknown as (p: string, o: unknown) => Promise<{ data?: Blob; error?: unknown; response: Response }>)(
    caminho, { params: { query: { ...query, formato } }, parseAs: 'blob' })
  if (!r.response.ok) throw ErroApi.de(r.response.status, r.error)
  const url = URL.createObjectURL(r.data as Blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${nome}.${formato}`
  document.body.appendChild(a)
  a.click()
  a.remove()
  setTimeout(() => URL.revokeObjectURL(url), 10_000)
}
