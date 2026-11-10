/**
 * Remessas (P-09) · "Quanto devemos à Associação de cada mês, e o que já enviámos?"
 * O devido vem da vista vw_remessa_devida (percentagem de cada fundo da Associação sobre o que entrou). Enviar
 * cria a remessa com as linhas por fundo, paga-a com uma saída da categoria de remessa (os fundos da Associação
 * só saem assim; não precisa de outra aprovação) e marca-a como enviada. A Associação confirma a recepção.
 */
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { CircleCheck, Hourglass, Landmark, Send, Undo2 } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Dinheiro, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { CampoData } from '@/components/comum/CampoData'
import { Seleccao } from '@/components/comum/Seleccao'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { centimos, data, deCentimos, dinheiro, hojeIso } from '@/lib/formatos'
import { METODO_DA_CONTA } from './PaginaEntrada'
import {
  useCategorias, useConfirmarRemessa, useContasIgreja as useContas, useEntidades, useEnviarRemessa, useFundos, useRemessas, useRemessasDevidas,
  type Devida, type EstadoRemessa, type RemessaComLinhas,
} from './api'
import { parteDoFundo } from './comum'

export const MESES = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro']
export const nomeMes = (ano: number, mes: number) => `${MESES[mes - 1]} de ${ano}`


interface Periodo { chave: string; ano: number; mes: number; entidadeId: number; linhas: Devida[]; emFalta: string; remessa?: RemessaComLinhas; complementar?: boolean }

const PILULA: Record<EstadoRemessa, { v: 'warning' | 'info' | 'success'; r: string }> = {
  PREPARADA: { v: 'warning', r: 'Preparada' }, ENVIADA: { v: 'info', r: 'Enviada' }, CONFIRMADA: { v: 'success', r: 'Confirmada' },
}

export default function PaginaRemessas() {
  const { pode } = useSessao()
  const devidas = useRemessasDevidas()
  const remessas = useRemessas()
  const entidades = useEntidades()
  const fundos = useFundos()
  const confirmar = useConfirmarRemessa()
  const [enviar, setEnviar] = useState<Periodo | null>(null)
  const [aConfirmar, setAConfirmar] = useState<RemessaComLinhas | null>(null)
  const nomeEntidade = (id: number) => entidades.data?.find((e) => e.id === id)?.nome ?? 'Associação'
  const fundoDe = (id: number) => fundos.data?.find((f) => f.id === id)?.nome ?? `Fundo ${id}`
  const totalDe = (r: RemessaComLinhas) => deCentimos(r.linhas.filter((l) => !l.endDate).reduce((s, l) => s + centimos(l.valor), 0))

  /** Meses com valor em falta, o mais antigo primeiro (é o que se paga primeiro). */
  const porEnviar = useMemo(() => {
    const m = new Map<string, Periodo>()
    for (const d of devidas.data ?? []) {
      const chave = `${d.ano}-${String(d.mes).padStart(2, '0')}-${d.entidadeId}`
      const p = m.get(chave) ?? { chave, ano: d.ano, mes: d.mes, entidadeId: d.entidadeId, linhas: [], emFalta: '0.00' }
      p.linhas.push(d)
      m.set(chave, p)
    }
    const preparadas = (remessas.data ?? []).filter((r) => !r.endDate && r.estado === 'PREPARADA')
    return [...m.values()]
      .map((p) => ({
        ...p, emFalta: deCentimos(p.linhas.reduce((s, l) => s + Math.max(0, centimos(l.emFalta)), 0)),
        remessa: preparadas.find((r) => r.ano === p.ano && r.mes === p.mes && r.entidadeId === p.entidadeId),
        complementar: (remessas.data ?? []).some((r) => !r.endDate && r.estado !== 'PREPARADA' && r.ano === p.ano && r.mes === p.mes && r.entidadeId === p.entidadeId),
      }))
      .filter((p) => centimos(p.emFalta) > 0)
      .sort((a, b) => a.chave.localeCompare(b.chave))
  }, [devidas.data, remessas.data])

  const lista = (remessas.data ?? []).filter((r) => !r.endDate)
  const emFaltaTotal = deCentimos(porEnviar.reduce((s, p) => s + centimos(p.emFalta), 0))
  const enviadas = lista.filter((r) => r.estado === 'ENVIADA')
  const ano = Number(hojeIso().slice(0, 4))
  const confirmadasAno = lista.filter((r) => r.estado === 'CONFIRMADA' && r.ano === ano)
  const soma = (l: RemessaComLinhas[]) => deCentimos(l.reduce((s, r) => s + centimos(totalDe(r)), 0))
  const mesActual = (p: Periodo) => `${p.ano}-${String(p.mes).padStart(2, '0')}` === hojeIso().slice(0, 7)

  return (
    <>
      <TituloPagina icone={Landmark} titulo="Remessas" descricao="No fim de cada mês: 100% dos dízimos e a parte da Missão nas ofertas, depositados na conta da Missão" />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4 [&>*:last-child]:col-span-2 sm:[&>*:last-child]:col-span-1">
          <Indicador rotulo="Por enviar" valor={<Dinheiro valor={emFaltaTotal} />} nota={`${porEnviar.length} mês(es)`} icone={Hourglass} tom="warning" aCarregar={devidas.isPending} />
          <Indicador rotulo="Enviadas, por confirmar" valor={<Dinheiro valor={soma(enviadas)} />} nota={`${enviadas.length} remessa(s)`} icone={Send} tom="info" aCarregar={remessas.isPending} />
          <Indicador rotulo={`Confirmadas em ${ano}`} valor={<Dinheiro valor={soma(confirmadasAno)} />} nota={`${confirmadasAno.length} remessa(s)`} icone={CircleCheck} tom="success" aCarregar={remessas.isPending} />
        </div>

        <Cartao titulo="Por enviar" descricao="Por mês: quanto entrou em cada fundo, quanto cabe à Missão e o que os membros já pagaram directamente lá" icone={Hourglass} semMargem>
          {devidas.isPending || remessas.isPending ? <div className="px-6 pb-6"><Barra className="h-24 w-full" /></div>
            : devidas.isError ? <EstadoErro erro={devidas.error} aoTentar={() => devidas.refetch()} className="mx-6 mb-6" />
            : porEnviar.length === 0 ? <EstadoVazio icone={CircleCheck} titulo="Nada por enviar">Todas as remessas devidas foram enviadas.</EstadoVazio>
            : (
              <div className="grid gap-px border-t bg-border">
                {porEnviar.map((p) => (
                  <section key={p.chave} className="bg-card">
                    <div className="flex flex-wrap items-center gap-3 px-4 pt-4 sm:px-6">
                      <div className="min-w-0 flex-1">
                        <h3 className="font-semibold first-letter:uppercase">{nomeMes(p.ano, p.mes)}</h3>
                        <p className="text-xs text-muted-foreground">
                          Para {nomeEntidade(p.entidadeId)}{mesActual(p) ? ' · o mês ainda não terminou' : ''}{p.remessa ? ' · remessa preparada, falta pagar' : ''}{p.complementar ? ' · entrou mais depois do depósito: remessa complementar' : ''}
                        </p>
                      </div>
                      <span className="num text-lg font-semibold">{dinheiro(p.emFalta)}</span>
                      {pode('tesouraria.remessa.criar') && pode('tesouraria.transacao.criar') && (
                        <Button className="alvo" onClick={() => setEnviar(p)}><Send className="size-4" />{p.remessa ? 'Pagar e enviar' : 'Enviar remessa'}</Button>
                      )}
                    </div>
                    <Tabela className="mt-2">
                      <thead><tr><th className="sm:pl-6">Fundo</th><th className="num hidden sm:table-cell">Entrou</th><th className="num">Cabe à Missão</th><th className="num hidden md:table-cell">Pago na Missão</th><th className="num hidden sm:table-cell">Já enviado</th><th className="num sm:pr-6">Em falta</th></tr></thead>
                      <tbody>
                        {p.linhas.map((l) => (
                          <tr key={l.fundoId}>
                            <td className="sm:pl-6"><span className="font-medium">{l.fundoNome}</span><span className="block text-xs text-muted-foreground">{fundos.data && parteDoFundo(fundos.data.find((f) => f.id === l.fundoId) ?? {})}</span></td>
                            <td className="num hidden text-muted-foreground sm:table-cell"><Dinheiro valor={l.recebido} /></td>
                            <td className="num"><Dinheiro valor={l.devido} /></td>
                            <td className="num hidden text-muted-foreground md:table-cell"><Dinheiro valor={l.pagoDirecto} /></td>
                            <td className="num hidden text-muted-foreground sm:table-cell"><Dinheiro valor={l.remetido} /></td>
                            <td className="num font-medium sm:pr-6"><Dinheiro valor={l.emFalta} /></td>
                          </tr>
                        ))}
                      </tbody>
                    </Tabela>
                  </section>
                ))}
              </div>
            )}
        </Cartao>

        <Cartao titulo="Remessas" descricao="Depositadas na conta da Missão e confirmadas por ela" icone={Landmark} semMargem>
          {remessas.isPending ? <LinhasACarregar linhas={3} />
            : remessas.isError ? <EstadoErro erro={remessas.error} aoTentar={() => remessas.refetch()} className="mx-6 mb-6" />
            : lista.length === 0 ? <EstadoVazio icone={Landmark}>Ainda não foi enviada nenhuma remessa.</EstadoVazio>
            : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Mês</th><th className="hidden md:table-cell">Fundos</th><th>Estado</th><th className="num">Total</th><th className="sm:pr-6"><span className="sr-only">Acções</span></th></tr></thead>
                <tbody>
                  {lista.map((r) => (
                    <tr key={r.id}>
                      <td className="sm:pl-6">
                        <p className="font-medium first-letter:uppercase">{nomeMes(r.ano, r.mes)}</p>
                        <p className="text-xs text-muted-foreground">
                          {nomeEntidade(r.entidadeId)}{r.enviadaEm ? ` · enviada em ${data(r.enviadaEm)}` : ''}
                          {r.transacaoId ? <> · <Link to={`/tesouraria/movimentos/${r.transacaoId}`} className="text-primary hover:underline">depósito</Link></> : null}
                          {' · '}<Link to={`/tesouraria/relatorio-mensal?mes=${r.ano}-${String(r.mes).padStart(2, '0')}`} className="text-primary hover:underline">relatório</Link>
                        </p>
                      </td>
                      <td className="hidden text-muted-foreground md:table-cell">{r.linhas.filter((l) => !l.endDate).map((l) => fundoDe(l.fundoId)).join(', ')}</td>
                      <td><Pilula variante={PILULA[r.estado].v}>{PILULA[r.estado].r}</Pilula></td>
                      <td className="num font-medium"><Dinheiro valor={totalDe(r)} /></td>
                      <td className="text-right sm:pr-6">
                        {r.estado === 'ENVIADA' && pode('tesouraria.remessa.confirmar') && (
                          <Button size="sm" variant="outline" className="alvo" onClick={() => setAConfirmar(r)}><CircleCheck className="size-4" />Confirmar recepção</Button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </Tabela>
            )}
        </Cartao>
        {enviadas.length > 0 && !pode('tesouraria.remessa.confirmar') && (
          <p className="flex items-center gap-2 text-sm text-muted-foreground"><Undo2 className="size-4" />Depois do depósito, envie à Missão o relatório do mês com os recibos. A Missão confirma a recepção.</p>
        )}
      </div>

      {enviar && <DialogoEnviar p={enviar} entidadeNome={nomeEntidade(enviar.entidadeId)} aoFechar={() => setEnviar(null)} />}
      <DialogoConfirmar aberto={!!aConfirmar} aoMudar={(v) => !v && setAConfirmar(null)} titulo="Confirmar a recepção desta remessa?"
        texto={aConfirmar ? <>A Missão recebeu {dinheiro(totalDe(aConfirmar))} de {nomeMes(aConfirmar.ano, aConfirmar.mes)}. Depois de confirmada, a remessa não se altera.</> : null}
        accao="Confirmar recepção" aCorrer={confirmar.isPending}
        aoConfirmar={() => aConfirmar && confirmar.mutate(aConfirmar.id, {
          onSuccess: () => { toast.success('Remessa confirmada.'); setAConfirmar(null) },
          onError: (e) => { toast.error(mensagemDe(e)); setAConfirmar(null) },
        })} />
    </>
  )
}

function DialogoEnviar({ p, entidadeNome, aoFechar }: { p: Periodo; entidadeNome: string; aoFechar: () => void }) {
  const contas = useContas()
  const categorias = useCategorias()
  const enviar = useEnviarRemessa()
  const [valores, setValores] = useState<Record<number, string>>(() =>
    Object.fromEntries(p.remessa ? p.remessa.linhas.map((l) => [l.fundoId, l.valor]) : p.linhas.filter((l) => centimos(l.emFalta) > 0).map((l) => [l.fundoId, l.emFalta])))
  const [contaId, setContaId] = useState('')
  const [metodo, setMetodo] = useState('')
  const [dia, setDia] = useState(hojeIso())
  const [referencia, setReferencia] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const conta = contas.data?.find((c) => String(c.id) === contaId) ?? contas.data?.find((c) => c.tipo === 'CAIXA') ?? contas.data?.[0]
  // o numerário do caixa deposita-se no banco: a forma é sempre "Banco", salvo M-Pesa ou e-Mola
  const met = metodo || (conta?.tipo === 'MPESA' || conta?.tipo === 'EMOLA' ? METODO_DA_CONTA[conta.tipo] : 'BANCO')
  const categoria = categorias.data?.find((c) => c.eRemessa)
  const c = (v?: string) => (!v ? 0 : /^\d{1,14}(\.\d{1,2})?$/.test(v) ? centimos(v) : -1)
  const fundosLinhas = p.remessa ? p.remessa.linhas.map((l) => ({ fundoId: l.fundoId, nome: p.linhas.find((d) => d.fundoId === l.fundoId)?.fundoNome ?? `Fundo ${l.fundoId}`, emFalta: l.valor }))
    : p.linhas.filter((l) => centimos(l.emFalta) > 0).map((l) => ({ fundoId: l.fundoId, nome: l.fundoNome, emFalta: l.emFalta }))
  const total = fundosLinhas.reduce((s, l) => s + Math.max(0, c(valores[l.fundoId])), 0)

  const submeter = async () => {
    setErro(null)
    if (fundosLinhas.some((l) => c(valores[l.fundoId]) < 0)) { setErro('Escreva os valores como 1 500,00.'); return }
    if (total <= 0) { setErro('Escreva o valor a enviar.'); return }
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dia) || dia > hojeIso()) { setErro('A data tem de ser dd/mm/aaaa e não pode ser no futuro.'); return }
    if (!categoria || !conta) { setErro('Falta a categoria de remessa ou uma conta: peça ao administrador.'); return }
    if (!referencia.trim()) { setErro('Escreva o n.º do talão do depósito (ou o código M-Pesa).'); return }
    try {
      await enviar.mutateAsync({
        remessa: p.remessa, entidadeId: p.entidadeId, entidadeNome, ano: p.ano, mes: p.mes, complementar: p.complementar,
        linhas: fundosLinhas.filter((l) => c(valores[l.fundoId]) > 0).map((l) => ({ fundoId: l.fundoId, valor: valores[l.fundoId] })),
        contaId: conta.id, metodo: met, data: dia, categoriaRemessaId: categoria.id, referencia: referencia.trim(),
      })
      toast.success(`Remessa de ${nomeMes(p.ano, p.mes)} enviada: ${dinheiro(deCentimos(total))}.`)
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle className="first-letter:uppercase">Remessa {p.complementar ? 'complementar ' : ''}de {nomeMes(p.ano, p.mes)}</DialogTitle>
          <DialogDescription>
            Depósito na conta de {entidadeNome}. Regista a saída do dinheiro da Missão (não precisa de outra aprovação) e marca a remessa como enviada.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-3">
            {fundosLinhas.map((l) => (
              <div key={l.fundoId} className="grid grid-cols-[1fr_9rem] items-center gap-3">
                <label htmlFor={`rem-${l.fundoId}`} className="text-sm">
                  <span className="font-medium">{l.nome}</span>
                  <span className="block text-xs text-muted-foreground">{p.remessa ? 'preparado' : 'em falta'} {dinheiro(l.emFalta)}</span>
                </label>
                <CampoDinheiro id={`rem-${l.fundoId}`} value={valores[l.fundoId] ?? ''} disabled={!!p.remessa}
                  onChange={(v) => setValores((x) => ({ ...x, [l.fundoId]: v }))} className="alvo" />
              </div>
            ))}
            <div className="flex items-center justify-between border-t pt-3 text-sm">
              <span className="font-medium">Total a enviar</span><span className="num font-semibold">{dinheiro(deCentimos(total))}</span>
            </div>
          </div>
          <div className="grid gap-4 sm:grid-cols-3">
            <div className="grid gap-1.5">
              <label htmlFor="rem-conta" className="text-sm font-medium">Sai da conta</label>
              <Seleccao id="rem-conta" value={conta ? String(conta.id) : ''} onChange={(e) => { setContaId(e.target.value); setMetodo('') }}>
                {(contas.data ?? []).map((x) => <option key={x.id} value={x.id}>{x.nome}</option>)}
              </Seleccao>
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="rem-metodo" className="text-sm font-medium">Forma</label>
              <Seleccao id="rem-metodo" value={met} onChange={(e) => setMetodo(e.target.value)}>
                {Object.entries(rotulos.metodo).map(([k, r]) => <option key={k} value={k}>{r}</option>)}
              </Seleccao>
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="rem-data" className="text-sm font-medium">Data do depósito</label>
              <CampoData id="rem-data" value={dia} onChange={setDia} className="alvo" />
            </div>
            <div className="grid gap-1.5 sm:col-span-3">
              <label htmlFor="rem-ref" className="text-sm font-medium">N.º do talão do depósito <span className="text-destructive-text">*</span></label>
              <Input id="rem-ref" value={referencia} onChange={(e) => setReferencia(e.target.value)} placeholder="ou o código da transacção M-Pesa" className="alvo num uppercase" maxLength={100} />
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={enviar.isPending || contas.isPending || categorias.isPending} onClick={submeter}>
            {enviar.isPending ? t.comum.aGravar : 'Enviar remessa'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
