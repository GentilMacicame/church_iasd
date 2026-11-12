/**
 * Sino de alertas na barra de topo (todas as páginas): o número de assuntos novos à espera de uma acção do
 * utilizador; ao abrir, a lista por módulo, e cada alerta leva ao ecrã onde o assunto se aprova ou resolve.
 * Abrir a lista marca os alertas como vistos (neste aparelho); um alerta só desaparece quando o assunto fica
 * resolvido. Carregado a pedido (fora do pacote inicial); as consultas refrescam de 3 em 3 minutos com o
 * separador visível.
 */
import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { useQueryClient } from '@tanstack/react-query'
import { ArrowRight, Bell, BellRing, CircleCheck } from 'lucide-react'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { useIgreja, useSessao } from '@/auth/sessao'
import { cn } from '@/lib/utils'
import { Fontes } from './Fontes'
import { lerVistos, marcarVistos, useAlertas, type Alerta, type ModuloAlerta } from './loja'

const ORDEM: ModuloAlerta[] = ['Tesouraria', 'Secretaria', 'Reuniões', 'Escola Sabatina', 'Escalas']
/** Consultas que alimentam os alertas (primeiro elemento da chave). */
const PREFIXOS = new Set(['inicio', 'membros', 'secretaria', 'livro', 'tesouraria', 'es', 'escalas'])
const REFRESCAR_MS = 3 * 60_000

export function TomAlerta({ alerta, className }: { alerta: Alerta; className?: string }) {
  const I = alerta.icone
  return (
    <span className={cn('flex size-9 flex-none items-center justify-center rounded-lg',
      alerta.tom === 'destructive' ? 'bg-tint-destructive text-destructive-text' : alerta.tom === 'warning' ? 'bg-tint-warning text-warning-text' : 'bg-tint-info text-info-text', className)}>
      <I className="size-[18px]" aria-hidden />
    </span>
  )
}

export default function Sino() {
  const igreja = useIgreja()
  const { usuario } = useSessao()
  const qc = useQueryClient()
  const { alertas, aCarregar } = useAlertas()
  const [aberto, setAberto] = useState(false)
  const [vistos, setVistos] = useState(() => lerVistos(usuario?.id ?? 0, igreja.id))
  useEffect(() => setVistos(lerVistos(usuario?.id ?? 0, igreja.id)), [usuario?.id, igreja.id])

  const novos = alertas.filter((a) => !vistos.has(a.chave)).length
  const graves = alertas.some((a) => a.tom === 'destructive' && !vistos.has(a.chave))

  // refrescar de vez em quando (só com o separador visível): um pedido novo de outra pessoa aparece sozinho
  useEffect(() => {
    const t = setInterval(() => {
      if (document.visibilityState !== 'visible' || !navigator.onLine) return
      void qc.invalidateQueries({ predicate: (q) => PREFIXOS.has(String(q.queryKey[0])) && q.getObserversCount() > 0 })
    }, REFRESCAR_MS)
    return () => clearInterval(t)
  }, [qc])

  const abrir = (v: boolean) => {
    setAberto(v)
    if (v) {
      const chaves = alertas.map((a) => a.chave)
      marcarVistos(usuario?.id ?? 0, igreja.id, chaves)
      // o destaque de "novo" fica enquanto a lista está aberta; ao fechar, passam a vistos
    } else {
      setVistos(lerVistos(usuario?.id ?? 0, igreja.id))
    }
  }

  const grupos = useMemo(() => ORDEM.map((m) => ({ m, itens: alertas.filter((a) => a.modulo === m) })).filter((g) => g.itens.length), [alertas])
  const rotulo = novos ? `Alertas: ${novos} novo(s) de ${alertas.length}` : alertas.length ? `Alertas: ${alertas.length} por resolver` : 'Alertas: nada por resolver'

  return (
    <>
      <Fontes />
      <Popover open={aberto} onOpenChange={abrir}>
        <PopoverTrigger asChild>
          <button type="button" aria-label={rotulo} title={rotulo}
            className="relative inline-flex size-9 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground">
            {novos ? <BellRing className="size-[18px]" /> : <Bell className="size-[18px]" />}
            {alertas.length > 0 && (
              <span aria-hidden className={cn(
                'absolute -top-0.5 -right-0.5 flex h-[18px] min-w-[18px] items-center justify-center rounded-full px-1 text-[10px] leading-none font-semibold tabular-nums ring-2 ring-background',
                novos ? (graves ? 'bg-destructive text-white' : 'bg-primary text-primary-foreground') : 'bg-muted text-muted-foreground')}>
                {(novos || alertas.length) > 99 ? '99+' : novos || alertas.length}
              </span>
            )}
          </button>
        </PopoverTrigger>
        <PopoverContent align="end" sideOffset={8} className="w-[24rem] max-w-[calc(100vw-1.5rem)] p-0">
          <div className="flex items-center justify-between gap-3 border-b px-4 py-3">
            <div>
              <p className="text-sm font-semibold">Alertas</p>
              <p className="text-xs text-muted-foreground">
                {aCarregar && !alertas.length ? 'A verificar…' : alertas.length ? `${alertas.length} assunto(s) à espera de uma acção` : 'Nada à espera'}
              </p>
            </div>
            <Link to="/" onClick={() => abrir(false)} className="alvo text-xs font-medium text-primary hover:underline">Ver no Início</Link>
          </div>
          <div className="max-h-[min(28rem,70dvh)] overflow-y-auto">
            {!alertas.length ? (
              <div className="flex flex-col items-center gap-2 px-6 py-10 text-center">
                <span className="flex size-11 items-center justify-center rounded-full bg-tint-success text-success-text" aria-hidden><CircleCheck className="size-5" /></span>
                <p className="text-sm font-medium">{aCarregar ? 'A verificar…' : 'Tudo em dia'}</p>
                {!aCarregar && <p className="max-w-60 text-xs text-muted-foreground">Não há nada à espera de uma acção sua nesta igreja.</p>}
              </div>
            ) : grupos.map((g) => (
              <section key={g.m} aria-label={g.m}>
                <p className="sticky top-0 z-10 bg-popover/95 px-4 pt-3 pb-1 text-[11px] font-semibold tracking-wider text-muted-foreground uppercase backdrop-blur">{g.m}</p>
                <ul>
                  {g.itens.map((a) => (
                    <li key={a.chave}>
                      <Link to={a.para} onClick={() => abrir(false)}
                        className="alvo group flex items-start gap-3 px-4 py-2.5 hover:bg-muted/60 focus-visible:bg-muted/60 focus-visible:outline-none">
                        <TomAlerta alerta={a} />
                        <span className="min-w-0 flex-1">
                          <span className="flex items-start gap-2">
                            <span className="text-sm leading-5 font-medium">{a.titulo}</span>
                            {!vistos.has(a.chave) && <span className="mt-1.5 size-2 flex-none rounded-full bg-primary" aria-label="novo" />}
                          </span>
                          {a.detalhe && <span className="mt-0.5 block text-xs text-muted-foreground">{a.detalhe}</span>}
                        </span>
                        <ArrowRight aria-hidden className="mt-2 size-4 flex-none text-muted-foreground transition-transform group-hover:translate-x-0.5" />
                      </Link>
                    </li>
                  ))}
                </ul>
              </section>
            ))}
          </div>
        </PopoverContent>
      </Popover>
    </>
  )
}
