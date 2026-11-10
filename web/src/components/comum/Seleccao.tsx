/**
 * Lista de escolha nativa, com o aspecto dos campos do Design System. Nativa de propósito: no Android
 * abre o selector do sistema (grande, fácil com o polegar) e funciona com teclado e leitores de ecrã.
 */
import { forwardRef, type SelectHTMLAttributes } from 'react'
import { ChevronDown } from 'lucide-react'
import { cn } from '@/lib/utils'

export const Seleccao = forwardRef<HTMLSelectElement, SelectHTMLAttributes<HTMLSelectElement>>(function Seleccao(
  { className, children, ...props },
  ref,
) {
  return (
    <div className="relative">
      <select
        ref={ref}
        {...props}
        className={cn(
          'alvo h-9 w-full appearance-none rounded-md border border-input bg-card pr-9 pl-3 text-sm text-foreground shadow-[0_1px_2px_rgb(0_0_0/0.04)] outline-none',
          'focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/30 aria-invalid:border-destructive disabled:opacity-60',
          className,
        )}
      >
        {children}
      </select>
      <ChevronDown aria-hidden className="pointer-events-none absolute top-1/2 right-3 size-4 -translate-y-1/2 text-muted-foreground" />
    </div>
  )
})
