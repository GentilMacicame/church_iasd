/** Livro de membros · "Quem entrou e quem saiu, e com que voto?" (o registo oficial da igreja). */
import { useMemo } from 'react'
import { Link } from 'react-router-dom'
import { ArrowDownRight, ArrowUpRight, BarChart3, BookOpen, Scale } from 'lucide-react'
import { Cartao, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { GraficoBarras } from '@/components/comum/graficos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { rotulos, t } from '@/i18n/pt-MZ'
import { data, hojeIso } from '@/lib/formatos'
import { useMembrosBasicos } from '@/features/membros/api'
import { eEntrada, useMovimentos, useReunioes, useVotos } from './api'

export default function PaginaLivro() {
  const q = useMovimentos()
  const basicos = useMembrosBasicos()
  const votos = useVotos()
  const reunioes = useReunioes()
  const ano = hojeIso().slice(0, 4)
  const nomes = useMemo(() => new Map((basicos.data ?? []).map((m) => [m.id, `${m.nome} ${m.apelido}`])), [basicos.data])
  const votoPorId = useMemo(() => new Map((votos.data ?? []).map((v) => [v.id, v])), [votos.data])
  const reuniaoPorId = useMemo(() => new Map((reunioes.data ?? []).map((r) => [r.id, r])), [reunioes.data])
  const lista = q.data ?? []
  const doAno = lista.filter((m) => m.data.startsWith(ano))
  const entradas = doAno.filter((m) => eEntrada(m.tipo)).length
  const saidas = doAno.length - entradas
  const mesActual = Number(hojeIso().slice(5, 7))
  const meses = Array.from({ length: mesActual }, (_, i) => i + 1)
  const porMes = (entrada: boolean) => meses.map((m) => doAno.filter((x) => Number(x.data.slice(5, 7)) === m && eEntrada(x.tipo) === entrada).length)
  const MESES = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']

  return (
    <>
      <TituloPagina icone={BookOpen} titulo={t.livro.titulo}
        descricao="Cada entrada e saída de membros, com o voto que a autoriza. Regista-se a partir da ficha do membro." />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4">
          <Indicador rotulo={`Entradas em ${ano}`} valor={entradas} nota="baptismos, profissões de fé, cartas" icone={ArrowDownRight} tom="success" aCarregar={q.isPending} />
          <Indicador rotulo={`Saídas em ${ano}`} valor={saidas} nota="cartas, falecimentos, remoções" icone={ArrowUpRight} tom="destructive" aCarregar={q.isPending} />
          <Indicador rotulo="Variação" valor={`${entradas - saidas > 0 ? '+' : ''}${entradas - saidas}`} nota={`no livro em ${ano}`} icone={Scale} tom="info" aCarregar={q.isPending} />
        </div>
        <Cartao titulo={`Entradas e saídas em ${ano}`} descricao="Por mês, com o voto da igreja" icone={BarChart3}>
          {q.isPending ? <div className="h-48 animate-pulse rounded-lg bg-muted" />
            : <GraficoBarras rotulo={`Entradas e saídas do livro de membros em ${ano}`} altura={200} categorias={meses.map((m) => MESES[m - 1])} destaque={mesActual - 1}
                series={[{ nome: 'Entradas', slot: 1, valores: porMes(true) }, { nome: 'Saídas', slot: 2, valores: porMes(false) }]} formatar={(v) => String(v)} inteiros />}
        </Cartao>
        <Cartao titulo="Movimentos" descricao="O mais recente primeiro" semMargem>
          {q.isPending ? <LinhasACarregar linhas={5} />
            : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="mx-6 mb-6" />
            : lista.length === 0 ? (
              <EstadoVazio icone={BookOpen} titulo="O livro ainda está vazio">
                Para admitir um interessado: registe o voto da igreja em Reuniões e depois, na ficha do membro, "Registar entrada".
              </EstadoVazio>
            ) : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Data</th><th>Membro</th><th>Movimento</th><th className="hidden md:table-cell sm:pr-6">Voto</th></tr></thead>
                <tbody>
                  {lista.map((m) => {
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
    </>
  )
}
