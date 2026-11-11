/**
 * Páginas carregadas a pedido (lazy) que sobrevivem a uma actualização da aplicação.
 *
 * Cada versão nova tem ficheiros com outros nomes; um separador aberto com a versão anterior, ao abrir uma página
 * (ex.: a de entrada, depois do logout), pede um ficheiro que já não existe. Em vez de ficar em branco, recarrega a
 * aplicação uma vez (e passa a usar a versão nova). Se mesmo assim falhar, o erro segue para a ErroAplicacao.
 */
import { lazy, type ComponentType } from 'react'

const CHAVE = 'igreja.recarregada-por-versao'

export function pagina<T extends ComponentType<object>>(importar: () => Promise<{ default: T }>) {
  return lazy(async () => {
    try {
      const m = await importar()
      try { sessionStorage.removeItem(CHAVE) } catch { /* sem armazenamento */ }
      return m
    } catch (erro) {
      let jaRecarregou = false
      try { jaRecarregou = sessionStorage.getItem(CHAVE) === '1'; sessionStorage.setItem(CHAVE, '1') } catch { /* sem armazenamento */ }
      if (!jaRecarregou) {
        window.location.reload()
        return new Promise<{ default: T }>(() => { /* a página vai recarregar */ })
      }
      throw erro
    }
  })
}
