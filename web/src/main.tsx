import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App'

// ícone do separador: o logotipo oficial da Igreja, se estiver em public/ (ver components/layout/Marca)
for (const f of ['/logotipo-iasd.svg', '/logotipo-iasd.png']) {
  fetch(f, { method: 'HEAD' }).then((r) => {
    if (!r.ok || !(r.headers.get('content-type') ?? '').startsWith('image/')) return
    const icone = document.querySelector<HTMLLinkElement>('link[rel=icon]')
    if (icone && !icone.dataset.oficial) { icone.href = f; icone.type = r.headers.get('content-type') ?? ''; icone.dataset.oficial = '1' }
  }).catch(() => {})
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
