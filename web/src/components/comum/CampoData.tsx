/**
 * Data no formato do ecrã (dd/mm/aaaa), qualquer que seja a língua do telemóvel. O campo nativo
 * type="date" segue a língua do sistema (um Android em inglês mostra mm/dd/yyyy), por isso este é de texto:
 * aceita só algarismos, põe as barras sozinho e entrega à API a data ISO (2026-11-14).
 */
import { forwardRef, useEffect, useState } from 'react'
import { Input } from '@/components/ui/input'
import { cn } from '@/lib/utils'

export function isoParaEcra(iso?: string | null): string {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso ?? '')
  return m ? `${m[3]}/${m[2]}/${m[1]}` : ''
}

/** "14/11/2026" → "2026-11-14"; "" → ""; data impossível → null. */
export function ecraParaIso(texto: string): string | null {
  if (!texto.trim()) return ''
  const m = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(texto.trim())
  if (!m) return null
  const [d, mes, a] = [Number(m[1]), Number(m[2]), Number(m[3])]
  const data = new Date(Date.UTC(a, mes - 1, d))
  if (data.getUTCFullYear() !== a || data.getUTCMonth() !== mes - 1 || data.getUTCDate() !== d || a < 1900) return null
  return `${m[3]}-${m[2]}-${m[1]}`
}

function mascara(texto: string): string {
  const n = texto.replace(/\D/g, '').slice(0, 8)
  return [n.slice(0, 2), n.slice(2, 4), n.slice(4)].filter(Boolean).join('/')
}

interface Props extends Omit<React.ComponentProps<'input'>, 'value' | 'onChange'> {
  /** valor ISO (aaaa-mm-dd) ou "" */
  value: string
  /** recebe ISO, "" (vazio) ou o texto tal como está se ainda não for uma data válida */
  onChange: (valor: string) => void
}

export const CampoData = forwardRef<HTMLInputElement, Props>(function CampoData({ value, onChange, className, ...props }, ref) {
  const [texto, setTexto] = useState(isoParaEcra(value))
  useEffect(() => {
    // valor vindo de fora (ex.: ficha carregada): mostra-o
    if (ecraParaIso(texto) !== value) setTexto(isoParaEcra(value) || (value && !/^\d{4}-/.test(value) ? value : ''))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value])
  return (
    <Input
      ref={ref}
      {...props}
      inputMode="numeric"
      autoComplete="off"
      placeholder="dd/mm/aaaa"
      maxLength={10}
      value={texto}
      onChange={(e) => {
        const t = mascara(e.target.value)
        setTexto(t)
        const iso = ecraParaIso(t)
        onChange(iso === null ? t : iso)
      }}
      className={cn('num', className)}
    />
  )
})
