/**
 * Indicação de que a aplicação está a trabalhar:
 * - BarraCarregamento: barra fina no topo enquanto há pedidos à API (leituras ou gravações). Só aparece se demorar
 *   mais de 250 ms, para não piscar nos pedidos rápidos.
 * - CarregandoPagina: o que se vê na área principal enquanto chega o código de uma página (lazy).
 */
import { useEffect, useState } from 'react'
import { useIsFetching, useIsMutating } from '@tanstack/react-query'
import { Loader2 } from 'lucide-react'

export function BarraCarregamento() {
  const ocupado = useIsFetching() + useIsMutating() > 0
  const [visivel, setVisivel] = useState(false)
  useEffect(() => {
    if (!ocupado) { setVisivel(false); return }
    const t = setTimeout(() => setVisivel(true), 250)
    return () => clearTimeout(t)
  }, [ocupado])
  return (
    <div role="progressbar" aria-label="A carregar" aria-hidden={!visivel} aria-busy={visivel}
      className={`pointer-events-none fixed inset-x-0 top-0 z-50 h-0.5 overflow-hidden transition-opacity duration-200 print:hidden ${visivel ? 'opacity-100' : 'opacity-0'}`}>
      <div className="h-full w-1/3 animate-[carregar_1.1s_ease-in-out_infinite] rounded-full bg-primary" />
    </div>
  )
}

export function CarregandoPagina() {
  return (
    <div className="flex min-h-[40vh] items-center justify-center gap-2 text-sm text-muted-foreground" aria-busy="true">
      <Loader2 className="size-5 animate-spin" aria-hidden />A carregar…
    </div>
  )
}
