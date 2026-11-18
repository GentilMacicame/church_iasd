/**
 * Sessão inactiva: ao fim de 5 minutos sem mexer no ecrã (rato, teclado, toque, deslocamento), avisa com uma
 * contagem de 30 s; "Continuar" mantém a sessão, e no fim da contagem faz logout. A última actividade é partilhada
 * entre separadores (localStorage), para um separador esquecido não terminar a sessão de quem está a usar outro.
 * É uma protecção de ecrã (computador partilhado na igreja); o token de 15 min e a renovação continuam a valer.
 * Excepção: sem rede, nas páginas da Escola Sabatina (relatório do sábado sem rede, P-05), não faz logout.
 */
import { useCallback, useEffect, useRef, useState } from 'react'
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
      // sem rede, no relatório do sábado da Escola Sabatina: não se faz logout (sem rede não se volta a entrar e o
      // secretário ficaria sem o ecrã até a rede voltar); a contagem recomeça quando a rede voltar
      if (!navigator.onLine && window.location.pathname.startsWith('/escola-sabatina')) {
        ultima.current = Date.now()
        setRestam(null)
        return
      }
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
      <DialogContent className="sm:max-w-sm" showCloseButton={false} onPointerDownOutside={(e) => e.preventDefault()}>
        <DialogHeader className="items-center pr-6 text-center">
          <div className="relative my-2 size-28" aria-live="assertive">
            <svg viewBox="0 0 100 100" className="size-full -rotate-90" aria-hidden>
              <circle cx="50" cy="50" r="44" fill="none" strokeWidth="7" className="stroke-muted" />
              <circle cx="50" cy="50" r="44" fill="none" strokeWidth="7" strokeLinecap="round" className="stroke-warning transition-[stroke-dashoffset] duration-1000 ease-linear"
                strokeDasharray={2 * Math.PI * 44} strokeDashoffset={2 * Math.PI * 44 * (1 - (restam ?? 0) / AVISO_S)} />
            </svg>
            <span className="absolute inset-0 flex flex-col items-center justify-center">
              <span className="num text-3xl font-bold tabular-nums">{restam ?? 0}</span>
              <span className="text-xs text-muted-foreground">segundos</span>
            </span>
          </div>
          <DialogTitle className="text-center">Ainda está aí?</DialogTitle>
          <DialogDescription className="text-center">Por segurança, a sessão vai terminar.</DialogDescription>
        </DialogHeader>
        <DialogFooter className="grid grid-cols-2 gap-2 sm:grid-cols-2">
          <Button type="button" variant="outline" className="alvo" onClick={() => { aSair.current = true; void sair() }}>Sair</Button>
          <Button type="button" className="alvo" autoFocus onClick={continuar}>Continuar</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
