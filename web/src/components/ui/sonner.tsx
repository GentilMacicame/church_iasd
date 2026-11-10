import { CircleCheckIcon, InfoIcon, Loader2Icon, OctagonXIcon, TriangleAlertIcon } from 'lucide-react'
import { Toaster as Sonner, type ToasterProps } from 'sonner'

/** Notificações curtas (gravado, erro). Um tema só: claro. */
const Toaster = (props: ToasterProps) => (
  <Sonner
    theme="light"
    position="top-center"
    className="toaster group"
    icons={{
      success: <CircleCheckIcon className="size-4 text-success-text" />,
      info: <InfoIcon className="size-4" />,
      warning: <TriangleAlertIcon className="size-4 text-warning-text" />,
      error: <OctagonXIcon className="size-4 text-destructive-text" />,
      loading: <Loader2Icon className="size-4 animate-spin" />,
    }}
    style={
      {
        '--normal-bg': 'var(--popover)',
        '--normal-text': 'var(--popover-foreground)',
        '--normal-border': 'var(--border)',
        '--border-radius': 'var(--radius)',
      } as React.CSSProperties
    }
    {...props}
  />
)

export { Toaster }
