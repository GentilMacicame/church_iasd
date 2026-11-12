import { CircleCheck, Info, LoaderCircle, OctagonX, TriangleAlert, X } from 'lucide-react'
import { Toaster as Sonner, type ToasterProps } from 'sonner'
import { useTema } from '@/lib/tema'
import { cn } from '@/lib/utils'

/** Ícone do aviso num círculo da cor do tipo (sucesso, erro, atenção, informação). */
function Icone({ tom, children }: { tom: 'success' | 'destructive' | 'warning' | 'info' | 'muted'; children: React.ReactNode }) {
  const cor = {
    success: 'bg-tint-success text-success-text ring-success/15',
    destructive: 'bg-tint-destructive text-destructive-text ring-destructive/15',
    warning: 'bg-tint-warning text-warning-text ring-warning/20',
    info: 'bg-tint-info text-info-text ring-info/15',
    muted: 'bg-muted text-muted-foreground ring-border',
  }[tom]
  return <span className={cn('flex size-10 items-center justify-center rounded-full ring-4', cor)}>{children}</span>
}

/**
 * Avisos de todo o sistema (gravado, erro, atenção): um cartão ao centro, logo abaixo da barra de topo, com o ícone
 * do tipo num círculo colorido, uma faixa da mesma cor à esquerda e o texto grande. Segue o tema claro/escuro.
 * Os erros de qualquer gravação aparecem aqui sozinhos (App.tsx, MutationCache); as mensagens vêm da base de dados.
 */
const Toaster = (props: ToasterProps) => {
  const { escuro } = useTema()
  return (
    <Sonner
      theme={escuro ? 'dark' : 'light'}
      position="top-center"
      offset={72}
      gap={10}
      visibleToasts={4}
      closeButton
      duration={4500}
      icons={{
        success: <Icone tom="success"><CircleCheck className="size-5" strokeWidth={2.25} /></Icone>,
        error: <Icone tom="destructive"><OctagonX className="size-5" strokeWidth={2.25} /></Icone>,
        warning: <Icone tom="warning"><TriangleAlert className="size-5" strokeWidth={2.25} /></Icone>,
        info: <Icone tom="info"><Info className="size-5" strokeWidth={2.25} /></Icone>,
        loading: <Icone tom="muted"><LoaderCircle className="size-5 animate-spin" /></Icone>,
        close: <X className="size-3.5" />,
      }}
      toastOptions={{
        unstyled: true,
        classNames: {
          toast: cn(
            'group pointer-events-auto relative flex w-[min(28rem,calc(100vw-2rem))] items-center gap-3.5 overflow-hidden',
            'rounded-2xl border bg-card py-3.5 pr-11 pl-5 text-card-foreground',
            'shadow-[0_20px_50px_-12px_rgb(15_23_42/0.35),0_4px_12px_-4px_rgb(15_23_42/0.12)]',
            'before:absolute before:inset-y-0 before:left-0 before:w-1.5 before:bg-primary before:content-[""]',
          ),
          success: 'border-success/25 before:bg-success!',
          error: 'border-destructive/25 before:bg-destructive!',
          warning: 'border-warning/35 before:bg-warning!',
          info: 'border-info/25 before:bg-info!',
          icon: 'm-0! size-10! flex-none',
          content: 'min-w-0 flex-1',
          title: 'text-[15px] leading-snug font-semibold text-foreground',
          description: 'mt-0.5 text-sm leading-snug text-muted-foreground',
          actionButton: 'rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-primary-foreground',
          cancelButton: 'rounded-md bg-muted px-3 py-1.5 text-sm font-medium',
          closeButton: cn(
            'absolute! top-1/2! right-3! left-auto! -mt-3.5! flex! size-7! transform-none! items-center justify-center',
            'rounded-full! border-0! bg-transparent! text-muted-foreground! opacity-70 hover:bg-muted! hover:opacity-100',
          ),
        },
      }}
      {...props}
    />
  )
}

export { Toaster }
