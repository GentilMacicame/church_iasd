/** Escalas · "Que escalas tem a igreja e qual está em vigor?" */
import { Link, useNavigate } from 'react-router-dom'
import { CalendarDays, CalendarPlus, ChevronRight, Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Cartao, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { data } from '@/lib/formatos'
import { emVigor, usePlanos, type Plano } from './api'

export function EstadoPlano({ p }: { p: Plano }) {
  return (
    <span className="flex flex-wrap gap-1.5">
      {p.publicada ? <Pilula variante="success">Publicada</Pilula> : <Pilula variante="warning">Rascunho</Pilula>}
      {emVigor(p) && <Pilula variante="info">Em vigor</Pilula>}
    </span>
  )
}

export default function PaginaEscalas() {
  const { pode } = useSessao()
  const navigate = useNavigate()
  const q = usePlanos()
  const planos = q.data ?? []
  const vigor = planos.find(emVigor)
  const rascunhos = planos.filter((p) => !p.publicada).length

  return (
    <>
      <TituloPagina
        icone={CalendarDays}
        titulo={t.escalas.titulo}
        descricao="Escalas de pregação e de serviço, sábado a sábado"
        accoes={pode('actividades.escala_plano.criar') && (
          <Button asChild className="alvo"><Link to="/escalas/nova"><Plus className="size-4" />{t.escalas.nova}</Link></Button>
        )}
      />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4">
          <Indicador rotulo="Em vigor" valor={vigor ? `até ${data(vigor.dataFim).slice(0, 5)}` : '—'}
            nota={vigor?.titulo ?? 'nenhuma escala para hoje'} icone={CalendarDays} para={vigor ? `/escalas/${vigor.id}` : undefined} aCarregar={q.isPending} />
          <Indicador rotulo="Escalas" valor={planos.length} nota="elaboradas nesta igreja" icone={CalendarPlus} tom="info" aCarregar={q.isPending} />
          <Indicador rotulo="Rascunhos" valor={rascunhos} nota="ainda não publicadas" icone={CalendarDays} tom="warning" aCarregar={q.isPending} />
        </div>

        <Cartao titulo="Todas as escalas" descricao="Só as publicadas são vistas pelos membros e geram lembretes por SMS" semMargem>
          {q.isPending ? <LinhasACarregar linhas={3} />
            : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="mx-6 mb-6" />
            : planos.length === 0 ? (
              <EstadoVazio icone={CalendarDays} titulo="Ainda não há escalas"
                accao={pode('actividades.escala_plano.criar') && <Button asChild size="sm"><Link to="/escalas/nova"><Plus className="size-4" />{t.escalas.nova}</Link></Button>}>
                Crie a escala do trimestre: os sábados do período são preparados automaticamente.
              </EstadoVazio>
            ) : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Escala</th><th className="hidden sm:table-cell">Período</th><th>Estado</th><th className="hidden md:table-cell">Emissão</th><th className="sm:pr-6" /></tr></thead>
                <tbody>
                  {planos.map((p) => (
                    <tr key={p.id} onClick={() => navigate(`/escalas/${p.id}`)} className="group cursor-pointer">
                      <td className="sm:pl-6">
                        <Link to={`/escalas/${p.id}`} onClick={(e) => e.stopPropagation()} className="font-medium hover:text-primary">{p.titulo}</Link>
                        <span className="mt-0.5 block text-xs tabular-nums text-muted-foreground sm:hidden">{data(p.dataInicio)} – {data(p.dataFim)}</span>
                      </td>
                      <td className="hidden whitespace-nowrap tabular-nums text-muted-foreground sm:table-cell">{data(p.dataInicio)} – {data(p.dataFim)}</td>
                      <td><EstadoPlano p={p} /></td>
                      <td className="hidden text-muted-foreground md:table-cell">{[p.localEmissao, p.dataEmissao && data(p.dataEmissao)].filter(Boolean).join(', ') || '—'}</td>
                      <td className="w-10 sm:pr-6"><ChevronRight aria-hidden className="size-4 text-muted-foreground" /></td>
                    </tr>
                  ))}
                </tbody>
              </Tabela>
            )}
        </Cartao>
      </div>
    </>
  )
}
