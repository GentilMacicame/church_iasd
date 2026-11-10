/**
 * Marca do produto: um livro aberto (o livro de membros, a Bíblia) sobre a cor principal. Desenhada para
 * este sistema; não é o logótipo oficial da Igreja.
 */
export function Marca({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 32 32" className={className} role="img" aria-label="Igreja">
      <rect width="32" height="32" rx="8" fill="var(--primary)" />
      <path d="M16 10.5c-2.4-1.6-5.2-2.1-8-1.6v12.6c2.8-.5 5.6 0 8 1.6 2.4-1.6 5.2-2.1 8-1.6V8.9c-2.8-.5-5.6 0-8 1.6Z"
        fill="none" stroke="var(--primary-foreground)" strokeWidth="1.8" strokeLinejoin="round" />
      <path d="M16 10.5v12.6" stroke="var(--primary-foreground)" strokeWidth="1.8" />
    </svg>
  )
}
