/**
 * Guarda de rota: quem não tem a permissão vê "Sem acesso" em vez de uma página vazia (por exemplo, a secretária
 * que escreve /tesouraria no endereço). É só UX: a base de dados já não devolve dados a quem não pode ler.
 */
import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { Lock } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { EstadoVazio } from '@/components/comum/estados'
import { useSessao } from '@/auth/sessao'

export function Exige({ permissao, children }: { permissao: string | string[]; children: ReactNode }) {
  const { pode } = useSessao()
  const lista = Array.isArray(permissao) ? permissao : [permissao]
  if (lista.some((p) => pode(p))) return <>{children}</>
  return (
    <div className="mx-auto mt-10 max-w-lg rounded-xl border bg-card shadow-card">
      <EstadoVazio icone={Lock} titulo="Sem acesso a esta página"
        accao={<Button asChild className="alvo"><Link to="/">Voltar ao início</Link></Button>}>
        O seu perfil nesta igreja não inclui esta parte do sistema. Se precisar, peça ao administrador.
      </EstadoVazio>
    </div>
  )
}
