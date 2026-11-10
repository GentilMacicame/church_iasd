/**
 * Campos de formulário: rótulo por cima (nunca só placeholder), ajuda e erro ligados ao campo por
 * aria-describedby. Os erros da API com `campo` vão para junto do campo; sem campo, para o topo.
 */
import { useId, type ReactNode } from 'react'
import type { FieldValues, Path, UseFormReturn } from 'react-hook-form'
import { AlertCircle } from 'lucide-react'
import { Label } from '@/components/ui/label'
import { ErroApi, mensagemDe } from '@/api/erros'
import { cn } from '@/lib/utils'

interface PropsCampo {
  rotulo: string
  erro?: string
  ajuda?: string
  obrigatorio?: boolean
  className?: string
  children: (props: { id: string; 'aria-invalid': boolean; 'aria-describedby'?: string }) => ReactNode
}

export function CampoFormulario({ rotulo, erro, ajuda, obrigatorio, className, children }: PropsCampo) {
  const id = useId()
  const descricao = [ajuda && `${id}-ajuda`, erro && `${id}-erro`].filter(Boolean).join(' ') || undefined
  return (
    <div className={cn('grid content-start gap-2', className)}>
      <Label htmlFor={id} className="text-sm font-medium">
        {rotulo}
        {obrigatorio && <span className="text-destructive" aria-hidden> *</span>}
      </Label>
      {children({ id, 'aria-invalid': Boolean(erro), 'aria-describedby': descricao })}
      {ajuda && !erro && <p id={`${id}-ajuda`} className="text-xs text-muted-foreground">{ajuda}</p>}
      {erro && <p id={`${id}-erro`} className="text-xs font-medium text-destructive-text">{erro}</p>}
    </div>
  )
}

/** Mensagem de erro no topo do formulário (erros sem campo). */
export function ErroFormulario({ mensagem }: { mensagem?: string | null }) {
  if (!mensagem) return null
  return (
    <div role="alert" className="flex items-start gap-2 rounded-lg border border-destructive/20 bg-tint-destructive px-4 py-3 text-sm text-destructive-text">
      <AlertCircle className="mt-0.5 size-4 shrink-0" aria-hidden />
      <p>{mensagem}</p>
    </div>
  )
}

/**
 * Põe o erro da API no sítio certo: junto ao campo (se o formulário o tiver) ou devolve a mensagem para
 * o topo. A mensagem vem da base de dados, já em português.
 */
export function aplicarErroApi<T extends FieldValues>(form: UseFormReturn<T>, erro: unknown): string | null {
  if (erro instanceof ErroApi && erro.campo && erro.campo in form.getValues()) {
    form.setError(erro.campo as Path<T>, { type: 'api', message: erro.message }, { shouldFocus: true })
    return null
  }
  return mensagemDe(erro)
}

/** Campo de texto em branco → null (a API distingue "sem valor" de texto vazio). */
export function vazioParaNull<T extends Record<string, unknown>>(valores: T): T {
  return Object.fromEntries(Object.entries(valores).map(([k, v]) => [k, v === '' ? null : v])) as T
}
