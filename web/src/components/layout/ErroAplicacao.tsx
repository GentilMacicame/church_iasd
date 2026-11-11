/**
 * Rede de segurança: um erro inesperado ao desenhar o ecrã mostra uma mensagem com "Recarregar" (em vez de deixar
 * a página em branco). Os erros da API continuam a ser tratados em cada página (EstadoErro, mensagens).
 */
import { Component, type ErrorInfo, type ReactNode } from 'react'
import { RotateCw, TriangleAlert } from 'lucide-react'

export class ErroAplicacao extends Component<{ children: ReactNode }, { erro: Error | null }> {
  state = { erro: null as Error | null }

  static getDerivedStateFromError(erro: Error) {
    return { erro }
  }

  componentDidCatch(erro: Error, info: ErrorInfo) {
    console.error('Erro na aplicação', erro, info.componentStack)
  }

  render() {
    if (!this.state.erro) return this.props.children
    return (
      <div className="flex min-h-dvh flex-col items-center justify-center gap-4 bg-background px-4 text-center" role="alert">
        <span className="flex size-14 items-center justify-center rounded-full bg-tint-warning text-warning-text"><TriangleAlert className="size-7" /></span>
        <div>
          <h1 className="text-lg font-semibold">Algo correu mal ao abrir esta página</h1>
          <p className="mt-1 max-w-sm text-sm text-muted-foreground">Recarregue a aplicação. Se a plataforma foi actualizada há pouco, isto resolve.</p>
        </div>
        <button type="button" onClick={() => window.location.reload()}
          className="alvo inline-flex h-10 items-center gap-2 rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground hover:bg-primary/90">
          <RotateCw className="size-4" />Recarregar
        </button>
      </div>
    )
  }
}
