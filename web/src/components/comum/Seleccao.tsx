/**
 * Lista de escolha com pesquisa, com a mesma interface de um <select>: aceita <option> e <optgroup>, value/onChange,
 * defaultValue e o {...register('campo')} do React Hook Form. Por dentro há um <select> escondido (é ele que o
 * formulário lê, que recebe o evento "change" e de onde se lêem as opções); por fora, a lista com pesquisa sem acentos e com teclado
 * (CampoEscolha). Assim todas as listas da aplicação têm pesquisa sem mudar quem as usa.
 */
import { forwardRef, useCallback, useLayoutEffect, useRef, useState, type SelectHTMLAttributes } from 'react'
import { cn } from '@/lib/utils'
import { CampoEscolha, type OpcaoEscolha } from './CampoEscolha'

/** As opções tal como o <select> escondido as desenhou (funciona com <option>, <optgroup>, .map() e componentes). */
function lerOpcoes(el: HTMLSelectElement | null): OpcaoEscolha[] {
  if (!el) return []
  return [...el.options].map((o) => ({
    valor: o.value, rotulo: o.text,
    detalhe: o.parentElement instanceof HTMLOptGroupElement ? o.parentElement.label : undefined,
    desactivada: o.disabled || undefined,
  }))
}

export const Seleccao = forwardRef<HTMLSelectElement, SelectHTMLAttributes<HTMLSelectElement>>(function Seleccao(
  { className, children, id, value, defaultValue, disabled, onBlur, onChange, 'aria-label': ariaLabel, 'aria-invalid': ariaInvalid, ...props },
  ref,
) {
  // o ref de quem usa (ex.: register do formulário) vai tal e qual para o <select>, como num <select> normal;
  // a lista com pesquisa encontra o <select> pelo elemento que o envolve
  const caixa = useRef<HTMLDivElement>(null)
  const select = { get current() { return caixa.current?.querySelector('select') ?? null } }
  const [opcoes, setOpcoes] = useState<OpcaoEscolha[]>([])
  const [actual, setActual] = useState<string>(value != null ? String(value) : defaultValue != null ? String(defaultValue) : '')
  // o formulário (React Hook Form) pode mudar o valor do <select> sem eventos (reset, valores por defeito)
  useLayoutEffect(() => {
    const v = value != null ? String(value) : select.current?.value ?? ''
    if (v !== actual) setActual(v)
    const novas = lerOpcoes(select.current)
    if (JSON.stringify(novas) !== JSON.stringify(opcoes)) setOpcoes(novas)
  })
  const mudar = useCallback((v: string) => {
    const el = select.current
    if (!el) return
    el.value = v
    // o onChange de quem usa (register do formulário ou estado do ecrã) recebe o <select> já com o valor novo
    onChange?.({ target: el, currentTarget: el, type: 'change', nativeEvent: new Event('change'), preventDefault() {}, stopPropagation() {}, persist() {} } as never)
    setActual(v)
  }, [onChange])  // eslint-disable-line react-hooks/exhaustive-deps
  const vazio = opcoes.find((o) => o.valor === '')?.rotulo ?? 'Escolher…'

  return (
    <div ref={caixa} className={cn('relative', className?.match(/\b(w-\S+|max-w-\S+|min-w-\S+|sm:w-\S+|lg:w-\S+)\b/g)?.join(' '))}>
      <select ref={ref} {...props} onChange={onChange} value={value} defaultValue={value == null ? defaultValue : undefined} disabled={disabled}
        tabIndex={-1} aria-hidden className="sr-only">
        {children}
      </select>
      <CampoEscolha id={id} valor={actual} aoMudar={mudar} opcoes={opcoes} vazio={vazio} disabled={disabled}
        invalido={ariaInvalid === true || ariaInvalid === 'true'} rotuloAcessivel={ariaLabel}
        aoFechar={() => select.current && onBlur?.({ target: select.current, currentTarget: select.current, type: 'blur' } as never)} />
    </div>
  )
})
