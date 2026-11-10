/**
 * Introdução de dinheiro (CLAUDE.md, <Dinheiro>): aceita "1 500,50", "1500.5" ou "1500"; entrega à API o texto
 * "1500.50"; ao sair do campo mostra "1 500,50". Enquanto o texto não for um valor válido, entrega o próprio
 * texto (o Zod diz o que está mal). Nunca usa números de vírgula flutuante.
 */
import { forwardRef, useEffect, useState } from 'react'
import { Input } from '@/components/ui/input'
import { cn } from '@/lib/utils'
import { dinheiroParaApi } from '@/lib/formatos'

function paraEcra(api: string): string {
  const m = /^(-?)(\d+)\.(\d{2})$/.exec(api)
  if (!m) return api
  return `${m[1]}${m[2].replace(/\B(?=(\d{3})+(?!\d))/g, ' ')},${m[3]}`
}

interface Props extends Omit<React.ComponentProps<'input'>, 'value' | 'onChange'> {
  value: string
  onChange: (valor: string) => void
}

export const CampoDinheiro = forwardRef<HTMLInputElement, Props>(function CampoDinheiro({ value, onChange, className, onBlur, ...props }, ref) {
  const [texto, setTexto] = useState(value ? paraEcra(value) : '')
  useEffect(() => {
    // valor vindo de fora: mostra-o formatado (sem estragar o que o utilizador está a escrever)
    if ((dinheiroParaApi(texto) ?? texto) !== value) setTexto(value ? paraEcra(value) : '')
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value])
  return (
    <div className="relative">
      <Input
        ref={ref}
        {...props}
        inputMode="decimal"
        autoComplete="off"
        placeholder={props.placeholder ?? '0,00'}
        value={texto}
        onChange={(e) => {
          const t = e.target.value.replace(/[^\d\s.,-]/g, '')
          setTexto(t)
          onChange(t.trim() === '' ? '' : dinheiroParaApi(t) ?? t)
        }}
        onBlur={(e) => {
          const api = dinheiroParaApi(texto)
          if (api) setTexto(paraEcra(api))
          onBlur?.(e)
        }}
        className={cn('num pr-11 text-right', className)}
      />
      <span className="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2 text-xs font-medium text-muted-foreground">MT</span>
    </div>
  )
})
