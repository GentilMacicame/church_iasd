/**
 * Sessão inactiva: ao fim de 5 minutos sem mexer no ecrã (rato, teclado, toque, deslocamento), avisa com uma
 * contagem de 30 s; "Continuar" mantém a sessão, e no fim da contagem faz logout. A última actividade é partilhada
 * entre separadores (localStorage), para um separador esquecido não terminar a sessão de quem está a usar outro.
 * É uma protecção de ecrã (computador partilhado na igreja); o token de 15 min e a renovação continuam a valer.
 */
import { useCallback, useEffect, useRef, useState } from 'react'
import { Clock } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { useSessao } from '@/auth/sessao'

const INACTIVO_MS = 5 * 60_000
const AVISO_S = 30
const CHAVE = 'igreja.ultima-actividade'
const EVENTOS = ['mousemove', 'mousedown', 'keydown', 'touchstart', 'scroll', 'wheel'] as const

function ler(): number {
  try { return Number(localStorage.getItem(CHAVE)) || 0 } catch { return 0 }
}

export function Inactividade() {
  const { sair } = useSessao()
  const ultima = useRef(Date.now())
  const [restam, setRestam] = useState<number | null>(null)   // segundos da contagem (null = sem aviso)
  const aSair = useRef(false)

  const marcar = useCallback(() => {
    const agora = Date.now()
    if (agora - ultima.current < 1000) return               // no máximo uma escrita por segundo
    ultima.current = agora
    try { localStorage.setItem(CHAVE, String(agora)) } catch { /* sem armazenamento: só este separador */ }
  }, [])

  // actividade: só conta enquanto não há aviso (com o aviso aberto, é preciso escolher "Continuar")
  useEffect(() => {
    if (restam != null) return
    const f = () => marcar()
    EVENTOS.forEach((e) => window.addEventListener(e, f, { passive: true }))
    return () => EVENTOS.forEach((e) => window.removeEventListener(e, f))
  }, [restam, marcar])

  // verificação a cada segundo: abre o aviso, conta, e faz logout no fim
  useEffect(() => {
    const t = setInterval(() => {
      const ultimaVista = Math.max(ultima.current, ler())
      ultima.current = ultimaVista
      const parado = Date.now() - ultimaVista
      if (parado < INACTIVO_MS) { setRestam(null); return }
      const falta = Math.ceil((INACTIVO_MS + AVISO_S * 1000 - parado) / 1000)
      if (falta <= 0) {
        if (!aSair.current) { aSair.current = true; void sair() }
        return
      }
      setRestam(falta)
    }, 1000)
    return () => clearInterval(t)
  }, [sair])

  const continuar = () => {
    ultima.current = 0
    marcar()
    setRestam(null)
  }

  return (
    <Dialog open={restam != null} onOpenChange={(v) => { if (!v) continuar() }}>
      <DialogContent className="sm:max-w-sm" onPointerDownOutside={(e) => e.preventDefault()}>
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2"><Clock className="size-5 text-warning-text" />Ainda está aí?</DialogTitle>
          <DialogDescription>Não mexe no ecrã há 5 minutos. Por segurança, a sessão termina sozinha.</DialogDescription>
        </DialogHeader>
        <div className="flex flex-col items-center gap-2 py-2" aria-live="assertive">
          <span className="num text-5xl font-bold tabular-nums">{restam ?? 0}</span>
          <span className="text-sm text-muted-foreground">segundos para sair</span>
          <div className="mt-1 h-1.5 w-full overflow-hidden rounded-full bg-muted" aria-hidden>
            <div className="h-full rounded-full bg-warning transition-[width] duration-1000 ease-linear" style={{ width: `${((restam ?? 0) / AVISO_S) * 100}%` }} />
          </div>
        </div>
        <DialogFooter className="gap-2 sm:justify-between">
          <Button type="button" variant="ghost" className="alvo" onClick={() => { aSair.current = true; void sair() }}>Sair agora</Button>
          <Button type="button" className="alvo" autoFocus onClick={continuar}>Continuar</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
