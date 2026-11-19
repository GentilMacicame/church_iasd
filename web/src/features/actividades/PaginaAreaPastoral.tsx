/**
 * Área pastoral (F-ACT, ponto 6; V35) · "O que o distrito pastoral programou para as nossas igrejas?"
 * O distrito da igreja, o pastor e as igrejas abrangidas; o programa do ano da área pastoral (aparece também no
 * Programa anual e nos conflitos de cada igreja do distrito). Registam e alteram o pastor do distrito, a Associação e o
 * super-administrador (a base de dados decide); as igrejas do distrito vêem. Sem distrito, explica como o associar.
 */
import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { CalendarRange, Church, CircleCheck, Coins, ListChecks, Network, Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Cartao, Indicador, Pilula, Segmentos, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { useIgreja, useSessao } from '@/auth/sessao'
import { dinheiro, hojeIso, hora, qtd } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useEntidadeDaIgreja, useIgrejasDaEntidade } from '@/features/comunicados/api'
import { ROTULO_ESTADO, VARIANTE_ESTADO, useDistritoDaIgreja, usePrograma } from './api'
import { DialogoActividade } from './DialogoActividade'
import { Acompanhamento } from './Acompanhamento'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

const MESES_CURTOS = ['jan.', 'fev.', 'mar.', 'abr.', 'mai.', 'jun.', 'jul.', 'ago.', 'set.', 'out.', 'nov.', 'dez.']
const SEMANA = ['dom.', 'seg.', 'ter.', 'qua.', 'qui.', 'sex.', 'sáb.']
/** "10 out." e o dia da semana, na hora de Maputo. */
function diaMes(iso: string) {
  const d = new Date(new Date(iso).toLocaleString('en-US', { timeZone: 'Africa/Maputo' }))
  return { dia: `${d.getDate()} ${MESES_CURTOS[d.getMonth()]}`, semana: SEMANA[d.getDay()] }
}

export default function PaginaAreaPastoral() {
  const igreja = useIgreja()
  const { pode, usuario, distrito: noDistrito, igrejas: minhas } = useSessao()
  const navigate = useNavigate()
  const [params, setParams] = useSearchParams()
  const ano = Number(params.get('ano')) || Number(hojeIso().slice(0, 4))
  const [nova, setNova] = useState(false)
  const distrito = useDistritoDaIgreja()
  const entidade = useEntidadeDaIgreja()
  const igrejas = useIgrejasDaEntidade(entidade.data?.id)
  const q = usePrograma(ano)
  // no contexto do distrito (o pastor), o distrito vem da sessão; numa igreja, do distrito da igreja
  const d = noDistrito ? { id: noDistrito.id, nome: noDistrito.nome, pastorUsuarioId: usuario?.id ?? null, pastorNome: usuario?.nome ?? null } : distrito.data
  const [aba, setAba] = useState('programa')
  const podeRegistar = !!d && (d.pastorUsuarioId === usuario?.id || pode('organizacao.distrito.alterar')) && pode('actividades.actividade.criar')
  const doDistrito = noDistrito ? minhas.filter((i) => noDistrito.igrejas.includes(i.id)) : (igrejas.data ?? []).filter((i) => d && i.distritoId === d.id)
  const lista = (q.data ?? []).filter((x) => x.origem === 'AREA_PASTORAL').sort((a, b) => a.dataInicio.localeCompare(b.dataInicio))
  const hoje = hojeIso()
  const proximas = lista.filter((x) => x.dataInicio.slice(0, 10) >= hoje && x.estado !== 'CANCELADA')
  const previsto = lista.reduce((s, x) => s + Number(x.valorPrevisto ?? 0), 0)
  // os dois anos anteriores, o corrente e o seguinte (e o escolhido, se for outro)
  const anoHoje = Number(hojeIso().slice(0, 4))
  const anosVisiveis = [...new Set([anoHoje - 2, anoHoje - 1, anoHoje, anoHoje + 1, ano])].sort((x, y) => x - y)
  const mudarAno = (n: number) => setParams((p) => { const x = new URLSearchParams(p); x.set('ano', String(n)); return x }, { replace: true })

  return (
    <>
      <TituloPagina icone={Network} titulo="Área pastoral"
        descricao={d ? `${d.nome}${d.pastorNome ? ` · Pastor: ${d.pastorNome}` : ''}` : 'As actividades do distrito para as suas igrejas'}
        accoes={podeRegistar && <Button className="alvo" onClick={() => setNova(true)}><Plus className="size-4" />Nova actividade da área pastoral</Button>} />

      {!noDistrito && distrito.isPending ? <LinhasACarregar linhas={4} />
        : !noDistrito && distrito.isError ? <EstadoErro erro={distrito.error} aoTentar={() => distrito.refetch()} />
        : !d ? (
          <Cartao>
            <EstadoVazio icone={Network} titulo={`${igreja.nome} ainda não está num distrito pastoral`}
              accao={pode('organizacao.distrito.alterar') && <Button asChild variant="outline" className="alvo"><Link to="/igrejas?ver=distritos">Distritos pastorais</Link></Button>}>
              Quem gere as igrejas (a Associação/Missão) associa a igreja ao distrito e indica o pastor, em Igrejas › Distritos pastorais.
              Depois o pastor do distrito regista aqui as actividades da área pastoral, e elas aparecem no programa de cada igreja.
            </EstadoVazio>
          </Cartao>
        ) : (
          <Tabs value={aba} onValueChange={setAba} className="grid gap-6">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <Segmentos rotulo="Ano" valor={String(ano)} aoMudar={(v) => mudarAno(Number(v))}
                opcoes={anosVisiveis.map((a) => ({ valor: String(a), rotulo: String(a) }))} />
              <TabsList>
                <TabsTrigger value="programa" className="alvo gap-1.5"><CalendarRange className="size-4" />Programa</TabsTrigger>
                <TabsTrigger value="acompanhamento" className="alvo gap-1.5"><ListChecks className="size-4" />Acompanhamento</TabsTrigger>
              </TabsList>
            </div>
            <div className="grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-4">
              <Indicador rotulo="Igrejas" valor={doDistrito.length || '—'} icone={Church} nota={doDistrito.map((i) => i.nome).slice(0, 2).join(', ') || 'do distrito'} />
              <Indicador rotulo="Actividades" valor={lista.length} icone={CalendarRange} tom="info" nota={`${proximas.length} por realizar`} aCarregar={q.isPending} />
              <Indicador rotulo="Realizadas" valor={lista.filter((x) => x.estado === 'CONCLUIDA').length} icone={CircleCheck} tom="success"
                nota={`${qtd(lista.filter((x) => x.estado === 'CANCELADA').length, 'cancelada(s)')}`} aCarregar={q.isPending} />
              <Indicador rotulo="Orçamento" valor={dinheiro(previsto.toFixed(2))} icone={Coins} nota={`executado ${dinheiro(lista.reduce((s, x) => s + Number(x.executado ?? 0), 0).toFixed(2))}`} aCarregar={q.isPending} />
            </div>

            <TabsContent value="acompanhamento" className="mt-0">
              {q.isPending ? <LinhasACarregar linhas={4} /> : <Acompanhamento ano={ano} linhas={lista.map((x) => ({ ...x, grupo: 'Área pastoral' }))} />}
            </TabsContent>
            <TabsContent value="programa" className="mt-0">
            <Cartao titulo={`Programa de ${ano}`} descricao="Aparece também no programa de cada igreja" semMargem>
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
                          <td className="whitespace-nowrap sm:pl-6"><span className="font-medium">{diaMes(x.dataInicio).dia}</span><span className="block text-xs text-muted-foreground tabular-nums">{diaMes(x.dataInicio).semana} · {hora(x.dataInicio)}{x.dataFim ? `–${hora(x.dataFim)}` : ''}</span></td>
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
            </TabsContent>
          </Tabs>
        )}
      {nova && <DialogoActividade pastoral aoFechar={() => setNova(false)} aoGravar={(id) => navigate(`/actividades/${id}`)} />}
    </>
  )
}
