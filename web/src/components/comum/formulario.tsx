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
    <div className={cn('grid content-start gap-1.5', className)}>
      {/* rótulo flutuante: vazio e sem foco fica dentro do campo; ao entrar ou com valor sobe para a linha do contorno */}
      <div data-campo className={cn('group/campo relative mt-2',
        '[&_input:not(:focus)]:placeholder:text-transparent [&_textarea:not(:focus)]:placeholder:text-transparent')}>
        {children({ id, 'aria-invalid': Boolean(erro), 'aria-describedby': descricao })}
        <Label htmlFor={id} className={cn(
          'pointer-events-none absolute -top-2 left-2.5 block z-[1] max-w-[calc(100%-1.25rem)] truncate rounded-sm bg-card px-1 text-xs leading-4 font-medium text-muted-foreground transition-all duration-150',
          'group-focus-within/campo:text-primary',
          'group-has-[input:placeholder-shown:not(:focus)]/campo:top-1/2 group-has-[input:placeholder-shown:not(:focus)]/campo:-translate-y-1/2 group-has-[input:placeholder-shown:not(:focus)]/campo:text-sm group-has-[input:placeholder-shown:not(:focus)]/campo:font-normal',
          'group-has-[textarea:placeholder-shown:not(:focus)]/campo:top-2.5 group-has-[textarea:placeholder-shown:not(:focus)]/campo:text-sm group-has-[textarea:placeholder-shown:not(:focus)]/campo:font-normal',
          erro && 'text-destructive-text group-focus-within/campo:text-destructive-text',
        )}>
          {rotulo}
          {obrigatorio && <span className="text-destructive" aria-hidden> *</span>}
        </Label>
      </div>
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
