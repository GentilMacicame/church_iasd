/**
 * Componentes partilhados do Design System (equivalentes aos x-ui.* do SGMS): cabeçalho de página,
 * indicador (stat), cartão, pílula, avatar, dinheiro e par rótulo/valor.
 */
import type { ComponentType, ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { cn } from '@/lib/utils'
import { dinheiro, iniciais, tomPessoa } from '@/lib/formatos'
import { t } from '@/i18n/pt-MZ'

type Icone = ComponentType<{ className?: string }>
export type Tom = 'primary' | 'success' | 'warning' | 'destructive' | 'info'

const TONS_ICONE: Record<Tom, string> = {
  primary: 'bg-primary/10 text-primary',
  success: 'bg-success/12 text-success-text',
  warning: 'bg-warning/15 text-warning-text',
  destructive: 'bg-destructive/10 text-destructive-text',
  info: 'bg-info/12 text-info-text',
}

/** Ícone num quadrado de tom suave (cabeçalhos, indicadores, cartões). */
export function IconeTom({ icone: I, tom = 'primary', tamanho = 'md' }: { icone: Icone; tom?: Tom; tamanho?: 'sm' | 'md' | 'lg' }) {
  const caixa = tamanho === 'lg' ? 'size-10' : tamanho === 'md' ? 'size-9' : 'size-8'
  return (
    <span className={cn('flex flex-none items-center justify-center rounded-lg', caixa, TONS_ICONE[tom])} aria-hidden>
      <I className={tamanho === 'lg' ? 'size-5' : 'size-[18px]'} />
    </span>
  )
}

/** Cabeçalho do ecrã: ícone, título (h1), descrição e acções à direita. */
export function TituloPagina({ titulo, descricao, icone, accoes, antes }: {
  titulo: ReactNode; descricao?: ReactNode; icone?: Icone; accoes?: ReactNode; antes?: ReactNode
}) {
  return (
    <div className="mb-6">
      {antes}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div className="flex min-w-0 items-start gap-3">
          {icone && <IconeTom icone={icone} tamanho="lg" />}
          <div className="min-w-0">
            <h1 className="text-2xl font-semibold tracking-tight text-foreground">{titulo}</h1>
            {descricao && <p className="mt-1 text-sm text-muted-foreground">{descricao}</p>}
          </div>
        </div>
        {accoes && <div className="flex flex-wrap items-center gap-2">{accoes}</div>}
      </div>
    </div>
  )
}

/** Indicador: rótulo, ícone de tom, valor grande e uma nota. Com `para`, é uma ligação. */
export function Indicador({ rotulo, valor, nota, icone, tom = 'primary', para, activo, aoClicar, aCarregar }: {
  rotulo: string; valor: ReactNode; nota?: ReactNode; icone?: Icone; tom?: Tom; para?: string
  activo?: boolean; aoClicar?: () => void; aCarregar?: boolean
}) {
  const classes = cn(
    'group flex min-w-0 flex-col rounded-xl border bg-card p-4 text-left text-card-foreground shadow-card transition sm:p-5',
    (para || aoClicar) && 'hover:border-primary/40 hover:shadow-md',
    activo && 'border-primary ring-1 ring-primary',
  )
  const conteudo = (
    <>
      <div className="flex items-start justify-between gap-3">
        <span className="min-w-0 text-[11px] font-semibold tracking-wider text-muted-foreground uppercase sm:text-xs">{rotulo}</span>
        {icone && <span className="hidden sm:block"><IconeTom icone={icone} tom={tom} /></span>}
      </div>
      {aCarregar ? <span className="mt-3 block h-9 w-16 rounded-md bg-muted" aria-hidden />
        : <div className="num mt-2 truncate text-xl font-bold tracking-tight text-foreground min-[400px]:text-2xl sm:mt-3 sm:text-3xl">{valor}</div>}
      {nota && <p className="mt-1 text-xs text-muted-foreground sm:text-sm">{nota}</p>}
    </>
  )
  if (para) return <Link to={para} className={classes}>{conteudo}</Link>
  if (aoClicar) return <button type="button" onClick={aoClicar} aria-pressed={activo} className={cn(classes, 'alvo cursor-pointer')}>{conteudo}</button>
  return <article className={classes}>{conteudo}</article>
}

/** Cartão: título, descrição, ícone e acções no cabeçalho; conteúdo com ou sem margem interior. */
export function Cartao({ titulo, descricao, icone, accoes, children, className, semMargem }: {
  titulo?: ReactNode; descricao?: ReactNode; icone?: Icone; accoes?: ReactNode; children: ReactNode; className?: string; semMargem?: boolean
}) {
  const temCabeca = titulo || accoes
  return (
    <section className={cn('flex min-w-0 flex-col rounded-xl border bg-card text-card-foreground shadow-card', className)}>
      {temCabeca && (
        <header className="flex items-start justify-between gap-4 px-5 pt-5 sm:px-6">
          <div className="flex min-w-0 items-start gap-3">
            {icone && (
              <span className="mt-0.5 flex size-8 flex-none items-center justify-center rounded-lg bg-accent text-accent-foreground" aria-hidden>
                {(() => { const I = icone; return <I className="size-4" /> })()}
              </span>
            )}
            <div className="min-w-0">
              <h2 className="text-base leading-6 font-semibold tracking-tight">{titulo}</h2>
              {descricao && <p className="mt-0.5 text-sm text-muted-foreground">{descricao}</p>}
            </div>
          </div>
          {accoes && <div className="flex flex-none items-center gap-2">{accoes}</div>}
        </header>
      )}
      <div className={cn('flex min-w-0 flex-1 flex-col', !semMargem && 'p-5 sm:p-6', !semMargem && temCabeca && 'pt-4 sm:pt-4', semMargem && temCabeca && 'mt-4')}>
        {children}
      </div>
    </section>
  )
}

type VariantePilula = 'default' | 'secondary' | 'outline' | 'success' | 'warning' | 'destructive' | 'info'
const PILULAS: Record<VariantePilula, string> = {
  default: 'bg-primary text-primary-foreground border-transparent',
  secondary: 'bg-secondary text-secondary-foreground border-transparent',
  outline: 'border-border text-foreground',
  success: 'bg-tint-success text-success-text border-success/20',
  warning: 'bg-tint-warning text-warning-text border-warning/30',
  destructive: 'bg-tint-destructive text-destructive-text border-destructive/20',
  info: 'bg-tint-info text-info-text border-info/20',
}

/** Estado numa linha (badge): tom suave com texto do mesmo tom; nunca espremido. */
export function Pilula({ variante = 'secondary', children, className }: { variante?: VariantePilula; children: ReactNode; className?: string }) {
  return (
    <span className={cn('inline-flex flex-none items-center gap-1 rounded-md border px-2 py-0.5 text-xs font-medium whitespace-nowrap', PILULAS[variante], className)}>
      {children}
    </span>
  )
}

/** Pessoa: iniciais sobre um tom estável. */
export function Avatar({ id, nome, apelido, tamanho = 32 }: { id: number; nome: string; apelido?: string | null; tamanho?: number }) {
  const tom = tomPessoa(id)
  return (
    <span aria-hidden className="inline-flex flex-none items-center justify-center rounded-full font-semibold"
      style={{ width: tamanho, height: tamanho, background: tom.fundo, color: tom.tinta, fontSize: tamanho * 0.36 }}>
      {iniciais(nome, apelido)}
    </span>
  )
}

/** Dinheiro no ecrã: "1 500,50 MT". A API envia e recebe texto "1500.50". */
export function Dinheiro({ valor, moeda, className }: { valor?: string | null; moeda?: string; className?: string }) {
  return <span className={cn('num whitespace-nowrap', className)}>{dinheiro(valor, moeda)}</span>
}

/** Par rótulo/valor das fichas; valor em falta = traço. */
export function Campo({ rotulo, children }: { rotulo: string; children?: ReactNode }) {
  const vazio = children == null || children === ''
  return (
    <div className="min-w-0">
      <dt className="text-xs font-medium text-muted-foreground">{rotulo}</dt>
      <dd className={cn('mt-1 text-sm break-words', vazio ? 'text-muted-foreground' : 'text-foreground')}>{vazio ? t.comum.semValor : children}</dd>
    </div>
  )
}

/** Tabela no estilo do Design System (cabeçalho com faixa suave, linhas com realce). */
export function Tabela({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className="relative w-full min-w-0 overflow-x-auto">
      <table className={cn(
        'w-full border-collapse text-sm text-foreground',
        '[&_thead_tr]:border-b [&_th]:h-10 [&_th]:bg-muted/50 [&_th]:px-4 [&_th]:text-left [&_th]:align-middle [&_th]:text-xs [&_th]:font-medium [&_th]:whitespace-nowrap [&_th]:text-muted-foreground',
        '[&_td]:border-t [&_td]:px-4 [&_td]:py-3 [&_td]:align-middle [&_tbody_tr]:transition-colors [&_tbody_tr:hover]:bg-muted/50',
        '[&_.num]:text-right', className,
      )}>
        {children}
      </table>
    </div>
  )
}
