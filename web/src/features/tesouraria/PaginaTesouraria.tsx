/** Tesouraria · "Quanto há em cada conta e fundo, e o que espera por mim?" */
import { Link, useNavigate } from 'react-router-dom'
import { ArrowDownRight, ArrowUpRight, Banknote, FileText, HandCoins, Landmark, PiggyBank, ShieldAlert, Wallet } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Cartao, Dinheiro, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { centimos, data, deCentimos, hojeIso } from '@/lib/formatos'
import { useMembrosBasicos } from '@/features/membros/api'
import { useFundos, useMovimentos, useSaldosContas, useSaldosFundos, type Transacao } from './api'
import { PilulaEstado, Valor, parteDoFundo, quem } from './comum'

export default function PaginaTesouraria() {
  const { pode } = useSessao()
  const navigate = useNavigate()
  const contas = useSaldosContas()
  const fundosSaldo = useSaldosFundos()
  const fundos = useFundos()
  const basicos = useMembrosBasicos()
  const mes = hojeIso().slice(0, 7)
  const movs = useMovimentos({ desde: `${mes}-01`, ate: hojeIso() })
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }

  // a conta da Missão regista o que os membros pagaram lá: não é dinheiro da igreja
  const contasIgreja = (contas.data ?? []).filter((c) => c.entidadeId == null)
  const contasMissao = (contas.data ?? []).filter((c) => c.entidadeId != null)
  const total = deCentimos(contasIgreja.reduce((s, c) => s + centimos(c.saldo), 0))
  const porRemeter = deCentimos((fundosSaldo.data ?? []).reduce((s, f) => s + Math.max(0, centimos(f.porRemeter ?? '0')), 0))
  const fundoDe = (id: number) => fundos.data?.find((f) => f.id === id)
  const validos = (movs.data ?? []).filter((x) => !x.endDate)
  const soma = (l: Transacao[]) => deCentimos(l.reduce((s, x) => s + centimos(x.valorTotal), 0))
  // o pago directamente na conta da Missão não entrou na igreja: mostra-se à parte
  const naMissao = new Set(contasMissao.map((c) => c.id))
  const daIgreja = validos.filter((x) => !naMissao.has(x.contaId ?? 0))
  const entradas = daIgreja.filter((x) => x.tipo === 'ENTRADA' && x.estado === 'CONFIRMADA')
  const saidas = daIgreja.filter((x) => x.tipo === 'SAIDA' && x.estado === 'CONFIRMADA')
  const pagoNaMissao = validos.filter((x) => naMissao.has(x.contaId ?? 0) && x.estado === 'CONFIRMADA')
  const somaComSinal = (l: Transacao[]) => deCentimos(l.reduce((s, x) => s + (x.tipo === 'ENTRADA' ? 1 : -1) * centimos(x.valorTotal), 0))
  const pendentes = validos.filter((x) => x.estado === 'PENDENTE')
  const fundoAssociacao = new Map((fundos.data ?? []).map((f) => [f.codigo, !!f.destinoEntidadeId]))

  return (
    <>
      <TituloPagina icone={PiggyBank} titulo={t.tesouraria.titulo} descricao="Contas, fundos e movimentos da igreja"
        accoes={pode('tesouraria.transacao.criar') && (
          <>
            <Button asChild variant="outline" className="alvo"><Link to="/tesouraria/relatorio-mensal"><FileText className="size-4" />{t.tesouraria.relatorioMensal}</Link></Button>
            <Button asChild variant="outline" className="alvo"><Link to="/tesouraria/saida"><Banknote className="size-4" />{t.tesouraria.saida}</Link></Button>
            <Button asChild className="alvo"><Link to="/tesouraria/entrada"><HandCoins className="size-4" />{t.tesouraria.entrada}</Link></Button>
          </>
        )} />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-4">
          <Indicador rotulo="Saldo total" valor={<Dinheiro valor={total} />} nota={<>contas da igreja · <Dinheiro valor={porRemeter} /> é da Missão</>} icone={Wallet} para="/tesouraria/remessas" aCarregar={contas.isPending || fundosSaldo.isPending} />
          <Indicador rotulo="Entradas do mês" valor={<Dinheiro valor={soma(entradas)} />} nota={pagoNaMissao.length ? <>{entradas.length} na igreja · + <Dinheiro valor={somaComSinal(pagoNaMissao)} /> pagos na Missão</> : `${entradas.length} confirmada(s)`} icone={ArrowDownRight} tom="success" para="/tesouraria/movimentos?ver=entradas" aCarregar={movs.isPending || contas.isPending} />
          <Indicador rotulo="Saídas do mês" valor={<Dinheiro valor={soma(saidas)} />} nota={`${saidas.length} confirmada(s)`} icone={ArrowUpRight} tom="destructive" para="/tesouraria/movimentos?ver=saidas" aCarregar={movs.isPending} />
          <Indicador rotulo="Por confirmar" valor={pendentes.length} nota="pendentes ou por aprovar" icone={ShieldAlert} tom="warning" para="/tesouraria/movimentos?ver=pendentes" aCarregar={movs.isPending} />
        </div>
        <div className="grid items-start gap-6 lg:grid-cols-12">
          <Cartao titulo="Contas" descricao="Saldo actual de cada conta" icone={Landmark} semMargem className="lg:col-span-5">
            {contas.isPending ? <div className="px-6 pb-6"><Barra className="h-20 w-full" /></div>
              : contas.isError ? <EstadoErro erro={contas.error} aoTentar={() => contas.refetch()} className="mx-6 mb-6" />
              : !contasIgreja.length ? <EstadoVazio icone={Landmark}>Ainda não há contas registadas.</EstadoVazio>
              : (
                <Tabela>
                  <thead><tr><th className="sm:pl-6">Conta</th><th className="num sm:pr-6">Saldo</th></tr></thead>
                  <tbody>
                    {contasIgreja.map((c) => <tr key={c.id}><td className="sm:pl-6">{c.nome}</td><td className="num font-medium sm:pr-6"><Dinheiro valor={c.saldo} /></td></tr>)}
                    {contasIgreja.length > 1 && <tr className="bg-muted/30"><td className="font-semibold sm:pl-6">Total</td><td className="num font-semibold sm:pr-6"><Dinheiro valor={total} /></td></tr>}
                    {contasMissao.map((c) => (
                      <tr key={c.id}>
                        <td className="sm:pl-6"><span className="text-muted-foreground">{c.nome}</span><span className="block text-xs text-muted-foreground">pago pelos membros directamente na Missão</span></td>
                        <td className="num text-muted-foreground sm:pr-6"><Dinheiro valor={c.saldo} /></td>
                      </tr>
                    ))}
                  </tbody>
                </Tabela>
              )}
          </Cartao>
          <Cartao titulo="Por fundo" descricao="O que está nas contas, o que ainda é da Missão e o que a igreja pode gastar" icone={PiggyBank} semMargem className="lg:col-span-7">
            {fundosSaldo.isPending ? <div className="px-6 pb-6"><Barra className="h-20 w-full" /></div>
              : fundosSaldo.isError ? <EstadoErro erro={fundosSaldo.error} aoTentar={() => fundosSaldo.refetch()} className="mx-6 mb-6" />
              : !fundosSaldo.data.length ? <EstadoVazio icone={PiggyBank}>Os saldos por fundo aparecem quando houver movimentos confirmados.</EstadoVazio>
              : (
                <Tabela>
                  <thead><tr><th className="sm:pl-6">Fundo</th><th className="num hidden sm:table-cell">Saldo</th><th className="num hidden sm:table-cell">Da Missão</th><th className="num sm:pr-6">Pode gastar</th></tr></thead>
                  <tbody>
                    {fundosSaldo.data.map((f) => (
                      <tr key={f.codigo}>
                        <td className="sm:pl-6">
                          <span className="font-medium">{f.nome}</span>{fundoAssociacao.get(f.codigo) && <Pilula variante="secondary" className="ml-2">Missão</Pilula>}
                          <span className="block text-xs text-muted-foreground">{parteDoFundo(fundoDe(f.fundoId) ?? {})}</span>
                        </td>
                        <td className="num hidden text-muted-foreground sm:table-cell"><Dinheiro valor={f.saldo} /></td>
                        <td className="num hidden text-muted-foreground sm:table-cell">{centimos(f.porRemeter ?? '0') > 0 ? <Dinheiro valor={f.porRemeter} /> : '—'}</td>
                        <td className="num font-medium sm:pr-6"><Dinheiro valor={f.disponivel ?? f.saldo} /></td>
                      </tr>
                    ))}
                  </tbody>
                </Tabela>
              )}
          </Cartao>
        </div>
        <Cartao titulo="Últimos movimentos" descricao="Deste mês" icone={HandCoins} semMargem
          accoes={<Button asChild variant="outline" size="sm"><Link to="/tesouraria/movimentos">{t.comum.verTodos}</Link></Button>}>
          {movs.isPending ? <div className="px-6 pb-6"><Barra className="h-24 w-full" /></div>
            : movs.isError ? <EstadoErro erro={movs.error} aoTentar={() => movs.refetch()} className="mx-6 mb-6" />
            : !validos.length ? <EstadoVazio icone={HandCoins} titulo="Sem movimentos este mês">Lance as entradas do sábado ou registe uma saída.</EstadoVazio>
            : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Data</th><th>Movimento</th><th>Estado</th><th className="num sm:pr-6">Valor</th></tr></thead>
                <tbody>
                  {validos.slice(0, 6).map((x) => (
                    <tr key={x.id} onClick={() => navigate(`/tesouraria/movimentos/${x.id}`)} className="cursor-pointer">
                      <td className="tabular-nums whitespace-nowrap text-muted-foreground sm:pl-6">{data(x.dataHora)}</td>
                      <td className="font-medium">{quem(x, nomeDe)}</td>
                      <td><PilulaEstado tr={x} /></td>
                      <td className="num sm:pr-6"><Valor tr={x} /></td>
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
