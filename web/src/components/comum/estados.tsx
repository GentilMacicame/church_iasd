/**
 * Estados de cada bloco: vazio (ícone, título e frase), a carregar (barras do tamanho real) e erro
 * (dentro do bloco que falhou, com "Tentar de novo").
 */
import { AlertCircle, Inbox } from 'lucide-react'
import type { ComponentType, ReactNode } from 'react'
import { Button } from '@/components/ui/button'
import { mensagemDe } from '@/api/erros'
import { t } from '@/i18n/pt-MZ'
import { cn } from '@/lib/utils'

export function EstadoVazio({ children, titulo, icone: I = Inbox, accao, className }: {
  children: ReactNode; titulo?: string; icone?: ComponentType<{ className?: string }>; accao?: ReactNode; className?: string
}) {
  return (
    <div className={cn('flex flex-col items-center justify-center gap-2 px-6 py-10 text-center', className)}>
      <span className="flex size-11 items-center justify-center rounded-full bg-muted text-muted-foreground" aria-hidden><I className="size-5" /></span>
      {titulo && <p className="text-sm font-medium text-foreground">{titulo}</p>}
      <p className="max-w-sm text-sm text-muted-foreground">{children}</p>
      {accao && <div className="mt-2">{accao}</div>}
    </div>
  )
}

export function EstadoErro({ erro, aoTentar, className }: { erro: unknown; aoTentar?: () => void; className?: string }) {
  return (
    <div role="alert" className={cn('flex flex-wrap items-center gap-3 rounded-lg border border-destructive/20 bg-tint-destructive px-4 py-3 text-sm text-destructive-text', className)}>
      <AlertCircle className="size-4 shrink-0" aria-hidden />
      <p className="flex-1">{mensagemDe(erro)}</p>
      {aoTentar && <Button variant="outline" size="sm" onClick={aoTentar}>{t.comum.tentarDeNovo}</Button>}
    </div>
  )
}

/** Barra do tamanho do valor que vai aparecer. */
export function Barra({ className }: { className?: string }) {
  return <span aria-hidden className={cn('block animate-pulse rounded-md bg-muted', className)} />
}

/** Linhas de lista a carregar, com o mesmo passo das linhas reais. */
export function LinhasACarregar({ linhas = 5, className }: { linhas?: number; className?: string }) {
  return (
    <div aria-busy="true" aria-label="A carregar" className={className}>
      {Array.from({ length: linhas }, (_, i) => (
        <div key={i} className="flex h-14 items-center gap-3 border-t px-4 first:border-t-0">
          <Barra className="size-8 rounded-full" />
          <Barra className="h-3.5 w-44" />
          <Barra className="ml-auto h-3.5 w-20" />
        </div>
      ))}
    </div>
  )
}
