/**
 * Marca da aplicação: o logotipo oficial da Igreja Adventista do Sétimo Dia.
 *
 * O ficheiro oficial (do kit de identidade visual da Igreja) fica em `web/public/logotipo-iasd.svg` (ou `.png`):
 * não se desenha à mão. Enquanto não estiver lá, mostra-se a marca neutra da aplicação. Usado no menu, no ecrã de
 * entrada, no ecrã de carregamento e no cabeçalho dos documentos impressos (recibo, acta, relatório, escala).
 */
import { useState } from 'react'
import { cn } from '@/lib/utils'

const FICHEIROS = ['/logotipo-iasd.svg', '/logotipo-iasd.png']
const NOME = 'Igreja Adventista do Sétimo Dia'

export function Marca({ className, sobreEscuro }: { className?: string; sobreEscuro?: boolean }) {
  const [tentativa, setTentativa] = useState(0)
  if (tentativa < FICHEIROS.length) {
    return (
      <img src={FICHEIROS[tentativa]} alt={NOME} className={cn('object-contain', sobreEscuro && 'brightness-0 invert', className)}
        onError={() => setTentativa((n) => n + 1)} />
    )
  }
  return (
    <svg viewBox="0 0 32 32" className={className} role="img" aria-label={NOME}>
      <rect width="32" height="32" rx="8" fill="var(--primary)" />
      <path d="M16 10.5c-2.4-1.6-5.2-2.1-8-1.6v12.6c2.8-.5 5.6 0 8 1.6 2.4-1.6 5.2-2.1 8-1.6V8.9c-2.8-.5-5.6 0-8 1.6Z"
        fill="none" stroke="var(--primary-foreground)" strokeWidth="1.8" strokeLinejoin="round" />
      <path d="M16 10.5v12.6" stroke="var(--primary-foreground)" strokeWidth="1.8" />
    </svg>
  )
}

/** Cabeçalho dos documentos impressos: logotipo, "Igreja Adventista do Sétimo Dia" e a linha de baixo. */
export function CabecalhoDocumento({ linha, titulo, className }: { linha?: string; titulo: string; className?: string }) {
  return (
    <div className={cn('flex items-center gap-4', className)}>
      <Marca className="size-14 flex-none" />
      <div className="min-w-0">
        <p className="text-[10pt] tracking-[0.15em] uppercase">{NOME}{linha ? ` · ${linha}` : ''}</p>
        <p className="text-lg font-bold">{titulo}</p>
      </div>
    </div>
  )
}
