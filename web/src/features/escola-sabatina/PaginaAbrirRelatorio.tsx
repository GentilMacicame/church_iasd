/** Abre um relatório do sábado pelo número (ligações do painel e da conferência das ofertas). */
import { Navigate, useParams } from 'react-router-dom'
import { Cartao } from '@/components/comum/elementos'
import { EstadoErro, LinhasACarregar } from '@/components/comum/estados'
import { useRelatorio } from './api'

export default function PaginaAbrirRelatorio() {
  const id = Number(useParams().id)
  const q = useRelatorio(id)
  if (q.isError) return <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
  if (!q.data) return <Cartao><LinhasACarregar linhas={4} /></Cartao>
  return <Navigate to={`/escola-sabatina/sabado/${q.data.classeTrimestreId}/${q.data.sabadoId}`} replace />
}
