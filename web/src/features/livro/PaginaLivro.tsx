/**
 * Livro de membros · "Quem entrou e quem saiu, e com que voto?" (o registo oficial da igreja).
 * Daqui regista-se uma entrada ou uma saída (escolhendo o membro e o voto), vêem-se os interessados por admitir e
 * consultam-se os movimentos por ano, por sentido e por nome.
 */
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowDownRight, ArrowUpRight, BarChart3, BookOpen, Search, Sprout, UserPlus, Users } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Avatar, Cartao, Indicador, Pilula, Segmentos, Tabela, TituloPagina } from '@/components/comum/elementos'
import { GraficoBarras } from '@/components/comum/graficos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { Seleccao } from '@/components/comum/Seleccao'
import { useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { data, hojeIso } from '@/lib/formatos'
import { useMembrosBasicos, type Membro } from '@/features/membros/api'
import { eEntrada, useMovimentos, useReunioes, useVotos } from './api'
import { DialogoMovimento } from './MovimentosMembro'

const MESES = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']
const sem = (x: string) => x.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()

export default function PaginaLivro() {
  const { pode } = useSessao()
  const q = useMovimentos()
  const basicos = useMembrosBasicos()
  const votos = useVotos()
  const reunioes = useReunioes()
  const hoje = hojeIso()
  const [ano, setAno] = useState(hoje.slice(0, 4))
  const [sentido, setSentido] = useState<'todos' | 'entradas' | 'saidas'>('todos')
  const [busca, setBusca] = useState('')
  const [todosInt, setTodosInt] = useState(false)
  const [registar, setRegistar] = useState<{ sentido: 'entrada' | 'saida'; m: Membro | null } | null>(null)
  const podeRegistar = pode('secretaria.movimento_membro.criar')

  const nomes = useMemo(() => new Map((basicos.data ?? []).map((m) => [m.id, `${m.nome} ${m.apelido}`])), [basicos.data])
  const votoPorId = useMemo(() => new Map((votos.data ?? []).map((v) => [v.id, v])), [votos.data])
  const reuniaoPorId = useMemo(() => new Map((reunioes.data ?? []).map((r) => [r.id, r])), [reunioes.data])
  const lista = q.data ?? []
  const anos = [...new Set([hoje.slice(0, 4), ...lista.map((m) => m.data.slice(0, 4))])].sort().reverse()
  const doAno = lista.filter((m) => m.data.startsWith(ano))
  const entradas = doAno.filter((m) => eEntrada(m.tipo)).length
  const saidas = doAno.length - entradas
  const activos = (basicos.data ?? []).filter((m) => m.estado === 'ACTIVO').length
  const interessados = (basicos.data ?? []).filter((m) => m.estado === 'INTERESSADO')
  const ultimoMes = ano === hoje.slice(0, 4) ? Number(hoje.slice(5, 7)) : 12
  const meses = Array.from({ length: ultimoMes }, (_, i) => i + 1)
  const porMes = (entrada: boolean) => meses.map((m) => doAno.filter((x) => Number(x.data.slice(5, 7)) === m && eEntrada(x.tipo) === entrada).length)
  const visiveis = doAno.filter((m) => (sentido === 'todos' || eEntrada(m.tipo) === (sentido === 'entradas'))
    && (!busca || sem(nomes.get(m.membroId) ?? '').includes(sem(busca))))

  return (
    <>
      <TituloPagina icone={BookOpen} titulo={t.livro.titulo} descricao="O registo oficial de quem entra e sai, com o voto da igreja"
        accoes={podeRegistar && (
          <>
            <Button variant="outline" className="alvo" onClick={() => setRegistar({ sentido: 'saida', m: null })}><ArrowUpRight className="size-4" />Registar saída</Button>
            <Button className="alvo" onClick={() => setRegistar({ sentido: 'entrada', m: null })}><ArrowDownRight className="size-4" />Registar entrada</Button>
          </>
        )} />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
          <Indicador rotulo="Membros no livro" valor={activos} nota="activos hoje" icone={Users} aCarregar={basicos.isPending} />
          <Indicador rotulo={`Entradas em ${ano}`} valor={entradas} nota="baptismos, profissões de fé, cartas" icone={ArrowDownRight} tom="success" aCarregar={q.isPending} />
          <Indicador rotulo={`Saídas em ${ano}`} valor={saidas} nota="cartas, falecimentos, remoções" icone={ArrowUpRight} tom="destructive" aCarregar={q.isPending} />
          <Indicador rotulo="Por admitir" valor={interessados.length} nota="interessados" icone={Sprout} tom="info" aCarregar={basicos.isPending} />
        </div>

        <div className="grid items-stretch gap-6 lg:grid-cols-[minmax(0,1fr)_24rem]">
          <Cartao titulo={`Entradas e saídas em ${ano}`} descricao="Por mês" icone={BarChart3}>
            {q.isPending ? <div className="h-40 animate-pulse rounded-lg bg-muted" />
              : <GraficoBarras rotulo={`Entradas e saídas do livro de membros em ${ano}`} altura={170} categorias={meses.map((m) => MESES[m - 1])} destaque={ultimoMes - 1}
                  series={[{ nome: 'Entradas', slot: 1, valores: porMes(true) }, { nome: 'Saídas', slot: 2, valores: porMes(false) }]} formatar={(v) => String(v)} inteiros />}
          </Cartao>
          <Cartao titulo="Por admitir" descricao="Interessados à espera do voto" icone={Sprout} semMargem className="h-full">
            {basicos.isPending ? <LinhasACarregar linhas={3} /> : !interessados.length ? (
              <p className="px-5 pb-5 text-sm text-muted-foreground sm:px-6">Nenhum interessado à espera.</p>
            ) : (
              <>
              <ul className="divide-y border-t">
                {(todosInt ? interessados : interessados.slice(0, 5)).map((m) => (
                  <li key={m.id} className="flex items-center gap-3 px-5 py-2.5 sm:px-6">
                    <Avatar id={m.id} nome={m.nome} apelido={m.apelido} tamanho={32} />
                    <Link to={`/membros/${m.id}`} className="min-w-0 flex-1 text-sm leading-tight font-medium hover:text-primary">{m.nome} {m.apelido}</Link>
                    {podeRegistar && (
                      <Button size="sm" variant="outline" className="alvo flex-none" title="Registar a entrada no livro"
                        onClick={() => setRegistar({ sentido: 'entrada', m: { id: m.id, nome: m.nome, apelido: m.apelido } as Membro })}>
                        <UserPlus className="size-4" />Entrada
                      </Button>
                    )}
                  </li>
                ))}
              </ul>
              {interessados.length > 5 && (
                <Button type="button" variant="ghost" size="sm" className="m-2 w-[calc(100%-1rem)]" onClick={() => setTodosInt((x) => !x)}>
                  {todosInt ? 'Mostrar menos' : `Ver todos (${interessados.length})`}
                </Button>
              )}
              </>
            )}
          </Cartao>
        </div>

        <Cartao titulo="Movimentos" semMargem>
          <div className="flex flex-wrap items-center gap-3 border-b px-5 pb-4 sm:px-6">
            <Segmentos rotulo="Sentido" valor={sentido} aoMudar={setSentido}
              opcoes={[{ valor: 'todos', rotulo: 'Todos', contagem: doAno.length }, { valor: 'entradas', rotulo: 'Entradas', contagem: entradas }, { valor: 'saidas', rotulo: 'Saídas', contagem: saidas }] as const} />
            <div className="w-28"><Seleccao aria-label="Ano" value={ano} onChange={(e) => setAno(e.target.value)}>{anos.map((a) => <option key={a} value={a}>{a}</option>)}</Seleccao></div>
            <div className="relative ml-auto w-full sm:w-64">
              <Search aria-hidden className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input value={busca} onChange={(e) => setBusca(e.target.value)} placeholder="Pesquisar membro…" aria-label="Pesquisar membro" className="alvo pl-9" />
            </div>
          </div>
          {q.isPending ? <LinhasACarregar linhas={5} />
            : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="mx-6 my-6" />
            : visiveis.length === 0 ? (
              <EstadoVazio icone={BookOpen} titulo={lista.length ? 'Nenhum movimento com estes filtros' : 'O livro ainda está vazio'}>
                {lista.length ? 'Mude o ano, o sentido ou a pesquisa.' : 'Registe o voto em Reuniões e depois a entrada aqui.'}
              </EstadoVazio>
            ) : (
              <Tabela porPagina={15}>
                <thead><tr><th className="sm:pl-6">Data</th><th>Membro</th><th>Movimento</th><th className="hidden md:table-cell sm:pr-6">Voto</th></tr></thead>
                <tbody>
                  {visiveis.map((m) => {
                    const v = m.votoId ? votoPorId.get(m.votoId) : undefined
                    const r = v ? reuniaoPorId.get(v.reuniaoId) : undefined
                    return (
                      <tr key={m.id}>
                        <td className="tabular-nums whitespace-nowrap sm:pl-6">{data(m.data)}</td>
                        <td><Link to={`/membros/${m.membroId}`} className="font-medium hover:text-primary">{nomes.get(m.membroId) ?? `Membro ${m.membroId}`}</Link></td>
                        <td><Pilula variante={eEntrada(m.tipo) ? 'success' : 'destructive'}>{rotulos.modoEntrada[m.tipo]}</Pilula></td>
                        <td className="hidden text-muted-foreground md:table-cell sm:pr-6">
                          {v ? <Link to={`/reunioes/${v.reuniaoId}`} className="hover:text-primary"><span className="num">{v.numero}</span>{r ? ` · ${rotulos.tipoReuniao[r.tipo]} de ${data(r.data)}` : ''}</Link> : m.tipo === 'FALECIMENTO' ? 'não precisa de voto' : '—'}
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </Tabela>
            )}
        </Cartao>
      </div>
      {registar && <DialogoMovimento m={registar.m} sentido={registar.sentido} aberto aoMudar={(v) => !v && setRegistar(null)} />}
    </>
  )
}
