/** Campo de senha com o olho: mostra ou esconde o que se escreveu (o campo continua a ser de senha para o browser). */
import { forwardRef, useState } from 'react'
import { Eye, EyeOff } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { cn } from '@/lib/utils'

export const CampoSenha = forwardRef<HTMLInputElement, Omit<React.ComponentProps<'input'>, 'type'>>(function CampoSenha({ className, ...props }, ref) {
  const [ver, setVer] = useState(false)
  return (
    <span className="relative block">
      <Input ref={ref} {...props} type={ver ? 'text' : 'password'} className={cn('pr-11', className)} />
      <button type="button" onClick={() => setVer((v) => !v)} aria-label={ver ? 'Esconder a senha' : 'Mostrar a senha'} aria-pressed={ver}
        className="absolute top-1/2 right-1.5 flex size-8 -translate-y-1/2 items-center justify-center rounded-[2px] text-muted-foreground transition-colors hover:bg-muted hover:text-foreground">
        {ver ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
      </button>
    </span>
  )
})
