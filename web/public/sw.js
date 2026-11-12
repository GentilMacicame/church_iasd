/*
 * Service worker da aplicação (PWA): deixa a aplicação abrir sem rede, para o relatório do sábado da Escola
 * Sabatina (P-05) funcionar na igreja mesmo sem internet.
 *
 *  - Páginas (navegação): primeiro a rede; sem rede, o index.html guardado.
 *  - /assets/* (ficheiros com o hash no nome, nunca mudam): guardados na primeira vez e servidos daí.
 *  - Outros ficheiros estáticos (logotipo, ícone): servidos do guardado e actualizados em segundo plano.
 *  - A API (/v1, /health) NUNCA passa pela cache daqui: os dados sem rede são da própria aplicação
 *    (IndexedDB), que sabe o que é seguro mostrar e envia o que ficou por enviar.
 */
const VERSAO = 'igreja-v1'

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(VERSAO).then((c) => c.add(new Request('/', { cache: 'reload' }))).catch(() => {}))
  self.skipWaiting()
})

self.addEventListener('activate', (e) => {
  e.waitUntil((async () => {
    for (const k of await caches.keys()) if (k !== VERSAO) await caches.delete(k)
    await self.clients.claim()
  })())
})

self.addEventListener('fetch', (e) => {
  const pedido = e.request
  if (pedido.method !== 'GET') return
  const url = new URL(pedido.url)
  if (url.origin !== self.location.origin) return
  if (url.pathname.startsWith('/v1/') || url.pathname.startsWith('/health')) return

  if (pedido.mode === 'navigate') {
    e.respondWith((async () => {
      try {
        const r = await fetch(pedido)
        if (r.ok) (await caches.open(VERSAO)).put('/', r.clone())
        return r
      } catch {
        return (await caches.match('/')) ?? Response.error()
      }
    })())
    return
  }

  if (url.pathname.startsWith('/assets/')) {
    e.respondWith((async () => {
      const guardado = await caches.match(pedido)
      if (guardado) return guardado
      const r = await fetch(pedido)
      if (r.ok) (await caches.open(VERSAO)).put(pedido, r.clone())
      return r
    })())
    return
  }

  e.respondWith((async () => {
    const guardado = await caches.match(pedido)
    const rede = fetch(pedido).then(async (r) => {
      if (r.ok) (await caches.open(VERSAO)).put(pedido, r.clone())
      return r
    }).catch(() => guardado ?? Response.error())
    return guardado ?? rede
  })())
})
