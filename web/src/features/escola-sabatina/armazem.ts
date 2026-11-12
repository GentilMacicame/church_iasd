/**
 * Armazém no telemóvel (IndexedDB) para a Escola Sabatina funcionar sem rede (P-05, RNF "Sem rede"):
 *  - "cache": a última cópia do que se leu da API (classes, sábados, alunos, relatório), para abrir o ecrã sem rede;
 *  - "rascunhos": o relatório do sábado tal como o secretário o deixou, até ser enviado.
 * Sem IndexedDB (modo privado antigo, pré-visualização) tudo continua a funcionar, só sem a cópia local.
 */
import { ErroApi } from '@/api/erros'

const NOME = 'igreja-escola-sabatina'
const VERSAO = 1
export type Loja = 'cache' | 'rascunhos'

let bd: Promise<IDBDatabase | null> | null = null

function abrir(): Promise<IDBDatabase | null> {
  bd ??= new Promise((resolver) => {
    try {
      const p = indexedDB.open(NOME, VERSAO)
      p.onupgradeneeded = () => {
        const b = p.result
        if (!b.objectStoreNames.contains('cache')) b.createObjectStore('cache')
        if (!b.objectStoreNames.contains('rascunhos')) b.createObjectStore('rascunhos')
      }
      p.onsuccess = () => resolver(p.result)
      p.onerror = () => resolver(null)
      p.onblocked = () => resolver(null)
    } catch {
      resolver(null)
    }
  })
  return bd
}

function pedido<T>(loja: Loja, modo: IDBTransactionMode, fazer: (s: IDBObjectStore) => IDBRequest): Promise<T | undefined> {
  return abrir().then((b) => new Promise<T | undefined>((resolver) => {
    if (!b) return resolver(undefined)
    try {
      const r = fazer(b.transaction(loja, modo).objectStore(loja))
      r.onsuccess = () => resolver(r.result as T)
      r.onerror = () => resolver(undefined)
    } catch {
      resolver(undefined)
    }
  }))
}

export const ler = <T>(loja: Loja, chave: string) => pedido<T>(loja, 'readonly', (s) => s.get(chave))
export const gravar = (loja: Loja, chave: string, valor: unknown) => pedido<IDBValidKey>(loja, 'readwrite', (s) => s.put(valor, chave)).then(() => undefined)
export const apagar = (loja: Loja, chave: string) => pedido<undefined>(loja, 'readwrite', (s) => s.delete(chave)).then(() => undefined)
export const todos = <T>(loja: Loja) => pedido<T[]>(loja, 'readonly', (s) => s.getAll()).then((r) => r ?? [])
export const limpar = (loja: Loja) => pedido<undefined>(loja, 'readwrite', (s) => s.clear()).then(() => undefined)

/** Erro de rede (sem ligação), não uma resposta da API. */
export function semRede(erro: unknown) {
  return erro instanceof ErroApi && erro.estado === 0
}

/**
 * Lê da API e guarda a cópia; sem rede, devolve a última cópia guardada (ou o erro, se nunca se leu).
 * Respostas da API (403, 404, 422…) não usam a cópia: a base de dados decidiu.
 */
export async function comCache<T>(chave: string, lerDaApi: () => Promise<T>): Promise<T> {
  try {
    const r = await lerDaApi()
    void gravar('cache', chave, r)
    return r
  } catch (erro) {
    if (!semRede(erro)) throw erro
    const copia = await ler<T>('cache', chave)
    if (copia === undefined) throw erro
    return copia
  }
}
