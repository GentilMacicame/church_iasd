/**
 * Área pastoral (F-ACT, ponto 6; V35) · "O que o distrito pastoral programou para as nossas igrejas?"
 * O distrito da igreja, o pastor e as igrejas abrangidas; o programa do ano da área pastoral (aparece também no
 * Programa anual e nos conflitos de cada igreja do distrito). Registam e alteram o pastor do distrito, a Associação e o
 * super-administrador (a base de dados decide); as igrejas do distrito vêem. Sem distrito, explica como o associar.
 */
import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { ChevronLeft, ChevronRight, Church, Network, Plus, UserRound } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Cartao, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { useIgreja, useSessao } from '@/auth/sessao'
import { dinheiro, hojeIso, hora } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useEntidadeDaIgreja, useIgrejasDaEntidade } from '@/features/comunicados/api'
import { ROTULO_ESTADO, VARIANTE_ESTADO, useDistritoDaIgreja, usePrograma } from './api'
import { DialogoActividade } from './DialogoActividade'

const DIA = new Intl.DateTimeFormat('pt-PT', { day: 'numeric', month: 'short', timeZone: 'Africa/Maputo' })

export default function PaginaAreaPastoral() {
  const igreja = useIgreja()
  const { pode, usuario } = useSessao()
  const navigate = useNavigate()
  const [params, setParams] = useSearchParams()
  const ano = Number(params.get('ano')) || Number(hojeIso().slice(0, 4))
  const [nova, setNova] = useState(false)
  const distrito = useDistritoDaIgreja()
  const entidade = useEntidadeDaIgreja()
  const igrejas = useIgrejasDaEntidade(entidade.data?.id)
  const q = usePrograma(ano)
  const d = distrito.data
  const podeRegistar = !!d && (d.pastorUsuarioId === usuario?.id || pode('organizacao.distrito.alterar')) && pode('actividades.actividade.criar')
  const doDistrito = (igrejas.data ?? []).filter((i) => d && i.distritoId === d.id)
  const lista = (q.data ?? []).filter((x) => x.origem === 'AREA_PASTORAL').sort((a, b) => a.dataInicio.localeCompare(b.dataInicio))
  const hoje = hojeIso()
  const proximas = lista.filter((x) => x.dataInicio.slice(0, 10) >= hoje && x.estado !== 'CANCELADA')
  const previsto = lista.reduce((s, x) => s + Number(x.valorPrevisto ?? 0), 0)
  const mudarAno = (n: number) => setParams((p) => { const x = new URLSearchParams(p); x.set('ano', String(n)); return x }, { replace: true })

  return (
    <>
      <TituloPagina icone={Network} titulo="Área pastoral"
        descricao={d ? `${d.nome} · as actividades do distrito para todas as suas igrejas` : 'As actividades do distrito pastoral para as suas igrejas'}
        accoes={podeRegistar && <Button className="alvo" onClick={() => setNova(true)}><Plus className="size-4" />Nova actividade da área pastoral</Button>} />

      {distrito.isPending ? <LinhasACarregar linhas={4} />
        : distrito.isError ? <EstadoErro erro={distrito.error} aoTentar={() => distrito.refetch()} />
        : !d ? (
          <Cartao>
            <EstadoVazio icone={Network} titulo={`${igreja.nome} ainda não está num distrito pastoral`}
              accao={pode('organizacao.distrito.alterar') && <Button asChild variant="outline" className="alvo"><Link to="/igrejas?ver=distritos">Distritos pastorais</Link></Button>}>
              Quem gere as igrejas (a Associação/Missão) associa a igreja ao distrito e indica o pastor, em Igrejas › Distritos pastorais.
              Depois o pastor do distrito regista aqui as actividades da área pastoral, e elas aparecem no programa de cada igreja.
            </EstadoVazio>
          </Cartao>
        ) : (
          <div className="grid gap-6">
            <div className="grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-4">
              <Indicador rotulo="Pastor do distrito" valor={d.pastorNome ?? '—'} icone={UserRound} nota={d.pastorUsuarioId ? 'regista e altera as actividades' : 'ainda não indicado'} />
              <Indicador rotulo="Igrejas do distrito" valor={doDistrito.length || '—'} icone={Church} nota={doDistrito.map((i) => i.nome).slice(0, 3).join(', ') || 'só esta igreja visível'} />
              <Indicador rotulo={`Actividades em ${ano}`} valor={lista.length} icone={Network} tom="info" nota={`${proximas.length} por realizar`} aCarregar={q.isPending} />
              <Indicador rotulo="Orçamento previsto" valor={dinheiro(previsto.toFixed(2))} icone={Network} tom="success" nota="soma das actividades do ano" aCarregar={q.isPending} />
            </div>

            <Cartao titulo={`Programa da área pastoral · ${ano}`} descricao="Aparece também no Programa anual e no calendário de cada igreja do distrito" semMargem
              accoes={(
                <div className="flex items-center gap-1">
                  <Button variant="outline" size="icon" className="size-9" aria-label="Ano anterior" onClick={() => mudarAno(ano - 1)}><ChevronLeft className="size-4" /></Button>
                  <span className="w-14 text-center text-sm font-medium tabular-nums">{ano}</span>
                  <Button variant="outline" size="icon" className="size-9" aria-label="Ano seguinte" onClick={() => mudarAno(ano + 1)}><ChevronRight className="size-4" /></Button>
                </div>
              )}>
              {q.isPending ? <LinhasACarregar linhas={4} />
                : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="m-4" />
                : lista.length === 0 ? (
                  <EstadoVazio icone={Network} titulo="Sem actividades da área pastoral"
                    accao={podeRegistar && <Button variant="outline" onClick={() => setNova(true)}>Registar a primeira</Button>}>
                    {podeRegistar ? 'Registe as actividades do distrito (seminários, campanhas, encontros): aparecem no programa de todas as igrejas.'
                      : 'Quando o pastor do distrito registar actividades, aparecem aqui e no Programa anual.'}
                  </EstadoVazio>
                ) : (
                  <Tabela>
                    <thead><tr><th className="sm:pl-6">Data</th><th>Actividade</th><th className="hidden lg:table-cell">Responsável</th><th>Estado</th><th className="num hidden sm:table-cell sm:pr-6">Previsto</th></tr></thead>
                    <tbody>
                      {lista.map((x) => (
                        <tr key={x.id} onClick={() => navigate(`/actividades/${x.id}`)} className={cn('cursor-pointer', (x.estado === 'CANCELADA' || x.dataInicio.slice(0, 10) < hoje) && 'text-muted-foreground')}>
                          <td className="whitespace-nowrap sm:pl-6"><span className="font-medium">{DIA.format(new Date(x.dataInicio))}</span><span className="block text-xs text-muted-foreground tabular-nums">{hora(x.dataInicio)}{x.dataFim ? `–${hora(x.dataFim)}` : ''}</span></td>
                          <td>
                            <Link to={`/actividades/${x.id}`} onClick={(e) => e.stopPropagation()} className={cn('font-medium hover:text-primary', x.estado === 'CANCELADA' && 'line-through')}>{x.nome}</Link>
                            {x.local && <span className="block text-xs text-muted-foreground">{x.local}</span>}
                          </td>
                          <td className="hidden lg:table-cell">{x.responsavel ?? '—'}</td>
                          <td><Pilula variante={VARIANTE_ESTADO[x.estado]}>{ROTULO_ESTADO[x.estado]}</Pilula></td>
                          <td className="num hidden sm:table-cell sm:pr-6">{dinheiro(x.valorPrevisto)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </Tabela>
                )}
            </Cartao>
          </div>
        )}
      {nova && <DialogoActividade pastoral aoFechar={() => setNova(false)} aoGravar={(id) => navigate(`/actividades/${id}`)} />}
    </>
  )
}
