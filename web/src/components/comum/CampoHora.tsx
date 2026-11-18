/**
 * Hora em 24 horas (hh:mm), qualquer que seja a língua do browser. O campo nativo type="time" mostra AM/PM num
 * browser em inglês e corta o texto; este é de texto: aceita só algarismos, põe os dois pontos sozinho e entrega
 * "09:30", como o nativo. Funciona com o register() do formulário e com value/onChange.
 */
import { forwardRef } from 'react'
import { Input } from '@/components/ui/input'
import { cn } from '@/lib/utils'

function mascara(texto: string): string {
  const n = texto.replace(/\D/g, '').slice(0, 4)
  if (n.length <= 2) return n.length === 2 && Number(n) > 23 ? `0${n[0]}:${n[1]}` : n
  const h = Math.min(23, Number(n.slice(0, 2)))
  const m = n.slice(2)
  return `${String(h).padStart(2, '0')}:${m.length === 2 ? String(Math.min(59, Number(m))).padStart(2, '0') : m}`
}

export const CampoHora = forwardRef<HTMLInputElement, Omit<React.ComponentProps<'input'>, 'type'>>(function CampoHora({ className, onChange, ...props }, ref) {
  return (
    <Input ref={ref} type="text" inputMode="numeric" autoComplete="off" placeholder="hh:mm" maxLength={5} {...props}
      onChange={(e) => {
        const antes = e.target.value
        const depois = antes.length < 3 && antes.endsWith(':') ? antes : mascara(antes)
        if (depois !== antes) e.target.value = depois
        onChange?.(e)
      }}
      className={cn('num w-24', className)} />
  )
})
