/**
 * Contagem do numerário (P-06 passo 1) · "O dinheiro contado já está todo lançado?"
 * 1. Contar: depois do culto, duas pessoas contam o dinheiro (dízimos, ofertas, Escola Sabatina, outras).
 * 2. Lançar: cada envelope e a salva lançam-se em "Lançar entrada", ligados a esta contagem.
 * 3. Conferir: quando o lançado é igual ao contado, a contagem confere-se.
 * Cada contagem mostra, parte a parte, o contado, o lançado e quanto falta lançar.
 */
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { Calculator, CircleCheck, HandCoins, Landmark, Plus, Scale } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Dinheiro, Indicador, Pilula, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { CampoData } from '@/components/comum/CampoData'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { Seleccao } from '@/components/comum/Seleccao'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { centimos, data, deCentimos, dinheiro, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { DialogoTransferencia } from './DialogoTransferencia'
import { PARTES_CONTAGEM, useConferencia, useContagens, useContagensMut, useContasIgreja as useContas, type Conferencia } from './api'

const ESTADO = {
  ABERTA: { r: 'Por conferir', v: 'warning' as const },
  CONFERIDA: { r: 'Conferida', v: 'success' as const },
  DEPOSITADA: { r: 'Depositada', v: 'info' as const },
}
/** Valor sem "MT" (a tabela das partes já é toda em meticais): "1 200,00". */
const mt = (c: number) => dinheiro(deCentimos(Math.abs(c))).replace(/\s*MT$/, '')

export default function PaginaContagens() {
  const { pode } = useSessao()
  const conf = useConferencia()
  const contagens = useContagens()
  const basicos = useMembrosBasicos()
  const [nova, setNova] = useState(false)
  const nomes = useMemo(() => new Map((basicos.data ?? []).map((m) => [m.id, `${m.nome} ${m.apelido}`])), [basicos.data])
  const porId = useMemo(() => new Map((contagens.data ?? []).map((c) => [c.id, c])), [contagens.data])
  const lista = [...(conf.data ?? [])].sort((a, b) => b.data.localeCompare(a.data) || b.id - a.id)
  const abertas = lista.filter((c) => c.estado === 'ABERTA')
  const faltaLancar = abertas.reduce((s, c) => s + Math.max(0, centimos(c.diferenca)), 0)
  const mes = hojeIso().slice(0, 7)
  const doMes = lista.filter((c) => c.data.startsWith(mes))
  const contadoMes = deCentimos(doMes.reduce((s, c) => s + centimos(c.totalContado), 0))

  return (
    <>
      <TituloPagina icone={Calculator} titulo="Contagem do numerário" descricao="O dinheiro de cada culto: quanto se contou e se já está todo lançado"
        accoes={pode('tesouraria.contagem_numerario.criar') && <Button className="alvo" onClick={() => setNova(true)}><Plus className="size-4" />Nova contagem</Button>} />
      <div className="grid gap-6">
        <ol className="grid gap-3 rounded-xl border bg-card p-4 text-sm shadow-card sm:grid-cols-3 sm:p-5">
          {[
            { n: 1, t: 'Contar', d: 'Depois do culto, duas pessoas contam o dinheiro e registam a contagem.' },
            { n: 2, t: 'Lançar', d: 'Cada envelope e a salva lançam-se em "Lançar entrada", escolhendo esta contagem.' },
            { n: 3, t: 'Conferir', d: 'Quando o lançado é igual ao contado, carregue em "Conferir".' },
          ].map((p) => (
            <li key={p.n} className="flex gap-3">
              <span className="flex size-7 flex-none items-center justify-center rounded-full bg-primary text-xs font-semibold text-primary-foreground">{p.n}</span>
              <span><span className="block font-medium">{p.t}</span><span className="text-muted-foreground">{p.d}</span></span>
            </li>
          ))}
        </ol>

        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4 [&>*:last-child]:col-span-2 sm:[&>*:last-child]:col-span-1">
          <Indicador rotulo="Contado este mês" valor={<Dinheiro valor={contadoMes} />} nota={`${doMes.length} contagem(ns)`} icone={Calculator} aCarregar={conf.isPending} />
          <Indicador rotulo="Por conferir" valor={abertas.length} nota="contagens ainda abertas" icone={Scale} tom="warning" aCarregar={conf.isPending} />
          <Indicador rotulo="Falta lançar" valor={<Dinheiro valor={deCentimos(faltaLancar)} />} nota="contado e ainda não lançado" icone={HandCoins} tom={faltaLancar ? 'destructive' : 'success'} aCarregar={conf.isPending} />
        </div>

        {conf.isPending ? <div className="grid gap-4">{[0, 1].map((i) => <Barra key={i} className="h-40 w-full rounded-xl" />)}</div>
          : conf.isError ? <EstadoErro erro={conf.error} aoTentar={() => conf.refetch()} />
          : lista.length === 0 ? (
            <div className="rounded-xl border bg-card shadow-card">
              <EstadoVazio icone={Calculator} titulo="Ainda não há contagens">Depois do culto, registe o que os dois contadores contaram.</EstadoVazio>
            </div>
          ) : (
            <div className="grid gap-4">
              {lista.map((c) => {
                const cont = porId.get(c.id)
                return <CartaoContagem key={c.id} c={c} contadores={cont ? `${nomes.get(cont.contador1MembroId) ?? '—'} e ${nomes.get(cont.contador2MembroId) ?? '—'}` : ''} />
              })}
            </div>
          )}
      </div>
      {nova && <DialogoContagem aoFechar={() => setNova(false)} nomeDe={(id) => nomes.get(id)} />}
    </>
  )
}

/** Uma contagem: o contado, o lançado e o que falta, parte a parte, e as acções (lançar, conferir). */
function CartaoContagem({ c, contadores }: { c: Conferencia; contadores: string }) {
  const { pode } = useSessao()
  const { mudarEstado } = useContagensMut()
  const contagens = useContagens()
  const [depositar, setDepositar] = useState(false)
  const caixaId = contagens.data?.find((x) => x.id === c.id)?.contaId
  const contado = centimos(c.totalContado), lancado = centimos(c.totalLancado), falta = contado - lancado
  const pct = contado ? Math.min(100, Math.round((lancado / contado) * 100)) : 0
  const aberta = c.estado === 'ABERTA'
  const est = ESTADO[c.estado as keyof typeof ESTADO] ?? ESTADO.ABERTA
  // com partes (contagens novas) mostra-se cada uma; nas antigas, só o total
  const partes = c.dizimos != null
    ? PARTES_CONTAGEM.map((p) => ({ rotulo: p.rotulo, contado: centimos(c[p.campo] ?? '0'), lancado: centimos(c[`${p.campo}Lancado`] ?? '0') })).filter((p) => p.contado || p.lancado)
    : [{ rotulo: 'Total (contagem sem partes)', contado, lancado }]
  const conferir = () => mudarEstado.mutate({ id: c.id, estado: 'CONFERIDA' }, {
    onSuccess: () => toast.success('Contagem conferida.'), onError: (e) => toast.error(mensagemDe(e)),
  })

  return (
    <section className="min-w-0 rounded-xl border bg-card shadow-card">
      <header className="flex flex-wrap items-start justify-between gap-3 px-4 pt-4 sm:px-6 sm:pt-5">
        <div className="min-w-0">
          <h2 className="font-semibold"><span className="tabular-nums">{data(c.data)}</span> · {c.ocasiao ?? 'Culto'}</h2>
          {contadores && <p className="text-sm text-muted-foreground">Contado por {contadores}</p>}
        </div>
        <Pilula variante={est.v}>{est.r}</Pilula>
      </header>

      <div className="grid gap-5 px-4 py-4 sm:px-6 lg:grid-cols-[1fr_1.5fr]">
        <div className="grid content-start gap-3">
          <dl className="grid grid-cols-3 gap-2">
            <div><dt className="text-xs text-muted-foreground">Contado</dt><dd className="num font-semibold"><Dinheiro valor={c.totalContado} /></dd></div>
            <div><dt className="text-xs text-muted-foreground">Já lançado</dt><dd className="num font-semibold"><Dinheiro valor={c.totalLancado} /></dd></div>
            <div>
              <dt className="text-xs text-muted-foreground">{falta >= 0 ? 'Falta lançar' : 'Lançado a mais'}</dt>
              <dd className={cn('num font-semibold', falta === 0 ? 'text-success-text' : 'text-destructive-text')}>{falta === 0 ? 'nada ✓' : <Dinheiro valor={deCentimos(Math.abs(falta))} />}</dd>
            </div>
          </dl>
          <div>
            <div className="h-2 overflow-hidden rounded-full bg-muted" role="img" aria-label={`${pct}% lançado`}>
              <div className={cn('h-full rounded-full', falta === 0 ? 'bg-success' : 'bg-primary')} style={{ width: `${pct}%` }} />
            </div>
            <p className="mt-1 text-xs text-muted-foreground">{pct}% do contado já está lançado</p>
          </div>
        </div>

        <table className="w-full text-sm">
          <thead>
            <tr className="text-xs text-muted-foreground">
              <th className="pb-1.5 text-left font-medium">Parte</th><th className="pb-1.5 text-right font-medium">Contado</th>
              <th className="pb-1.5 text-right font-medium">Lançado</th><th className="pb-1.5 text-right font-medium">Falta</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {partes.map((p) => {
              const f = p.contado - p.lancado
              return (
                <tr key={p.rotulo}>
                  <td className="py-1.5">{p.rotulo}</td>
                  <td className="num py-1.5 text-right">{mt(p.contado)}</td>
                  <td className="num py-1.5 text-right text-muted-foreground">{mt(p.lancado)}</td>
                  <td className={cn('num py-1.5 text-right font-medium', f === 0 ? 'text-success-text' : 'text-destructive-text')}>
                    {f === 0 ? '✓' : `${mt(f)}${f < 0 ? ' a mais' : ''}`}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      {aberta && (
        <footer className="flex flex-wrap items-center justify-between gap-3 border-t px-4 py-3 sm:px-6">
          <p className="text-xs text-muted-foreground">
            {falta === 0 ? 'Está tudo lançado: pode conferir.' : falta > 0 ? 'Lance o que falta (escolhendo esta contagem) para poder conferir.' : 'Lançou-se mais do que o contado: verifique as entradas ligadas a esta contagem.'}
          </p>
          <div className="flex flex-wrap gap-2">
            {falta > 0 && pode('tesouraria.transacao.criar') && (
              <Button asChild size="sm" className="alvo">
                <Link to={`/tesouraria/entrada?contagem=${c.id}`}><HandCoins className="size-4" />Lançar entradas desta contagem</Link>
              </Button>
            )}
            {pode('tesouraria.contagem_numerario.alterar') && (
              <Button size="sm" variant={falta === 0 ? 'default' : 'outline'} className="alvo" disabled={mudarEstado.isPending || falta !== 0} onClick={conferir}>
                <CircleCheck className="size-4" />Conferir
              </Button>
            )}
          </div>
        </footer>
      )}
      {c.estado === 'CONFERIDA' && pode('tesouraria.transacao.criar') && (
        <footer className="flex flex-wrap items-center justify-between gap-3 border-t px-4 py-3 sm:px-6">
          <p className="text-xs text-muted-foreground">Conferida. Quando levar o numerário ao banco, registe aqui o depósito com o n.º do talão.</p>
          <Button size="sm" className="alvo" onClick={() => setDepositar(true)}><Landmark className="size-4" />Depositar no banco</Button>
        </footer>
      )}
      {depositar && <DialogoTransferencia origem={caixaId} valor={c.totalContado} contagem={{ id: c.id, data: c.data, ocasiao: c.ocasiao }} aoFechar={() => setDepositar(false)} />}
    </section>
  )
}

function DialogoContagem({ aoFechar, nomeDe }: { aoFechar: () => void; nomeDe: (id: number) => string | undefined }) {
  const igreja = useIgreja()
  const contas = useContas()
  const { criar } = useContagensMut()
  const caixas = (contas.data ?? []).filter((c) => c.tipo === 'CAIXA')
  const [contaId, setContaId] = useState('')
  const [dia, setDia] = useState(hojeIso())
  const [ocasiao, setOcasiao] = useState('Culto de sábado')
  const [c1, setC1] = useState<number | null>(null)
  const [c2, setC2] = useState<number | null>(null)
  const [partes, setPartes] = useState<Record<string, string>>({ dizimos: '', ofertas: '', escolaSabatina: '', outras: '' })
  const validoOuVazio = (v: string) => v === '' || /^\d{1,14}(\.\d{1,2})?$/.test(v)
  const total = Object.values(partes).reduce((s, v) => s + (v && validoOuVazio(v) ? centimos(v) : 0), 0)
  const [erro, setErro] = useState<string | null>(null)
  const conta = caixas.find((c) => String(c.id) === contaId) ?? caixas[0] ?? contas.data?.[0]

  const submeter = async () => {
    setErro(null)
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dia) || dia > hojeIso()) return setErro('A data tem de ser dd/mm/aaaa e não pode ser no futuro.')
    if (!c1 || !c2) return setErro('Escolha os dois contadores.')
    if (c1 === c2) return setErro('Os dois contadores têm de ser pessoas diferentes.')
    if (!Object.values(partes).every(validoOuVazio)) return setErro('Há um valor inválido: escreva, por exemplo, 2 350,00.')
    if (total <= 0) return setErro('Escreva o que se contou em pelo menos uma das partes.')
    const parte = (v: string) => (v ? v : '0.00')
    try {
      await criar.mutateAsync({ igrejaId: igreja.id, contaId: conta!.id, data: dia, ocasiao: ocasiao.trim() || undefined, contador1MembroId: c1, contador2MembroId: c2,
        totalContado: deCentimos(total), dizimos: parte(partes.dizimos), ofertas: parte(partes.ofertas), escolaSabatina: parte(partes.escolaSabatina), outras: parte(partes.outras) } as never)
      toast.success('Contagem registada. Ao lançar as entradas em numerário, escolha esta contagem.')
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Nova contagem</DialogTitle>
          <DialogDescription>O dinheiro do culto, contado por duas pessoas antes de sair da igreja.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="grid gap-1.5">
              <label htmlFor="cnt-data" className="text-sm font-medium">Data</label>
              <CampoData id="cnt-data" value={dia} onChange={setDia} className="alvo" />
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="cnt-ocasiao" className="text-sm font-medium">Culto</label>
              <Input id="cnt-ocasiao" value={ocasiao} onChange={(e) => setOcasiao(e.target.value)} maxLength={100} className="alvo" />
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="cnt-c1" className="text-sm font-medium">1.º contador</label>
              <CampoMembro id="cnt-c1" valor={c1} aoMudar={setC1} nomeDe={nomeDe} />
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="cnt-c2" className="text-sm font-medium">2.º contador</label>
              <CampoMembro id="cnt-c2" valor={c2} aoMudar={setC2} nomeDe={nomeDe} />
            </div>
            <div className="grid gap-1.5 sm:col-span-2">
              <label htmlFor="cnt-conta" className="text-sm font-medium">Fica no</label>
              <Seleccao id="cnt-conta" value={conta ? String(conta.id) : ''} onChange={(e) => setContaId(e.target.value)}>
                {(caixas.length ? caixas : contas.data ?? []).map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
              </Seleccao>
            </div>
          </div>
          <fieldset className="grid gap-3 rounded-lg border p-3">
            <legend className="px-1 text-sm font-medium">O que se contou</legend>
            <div className="grid gap-3 sm:grid-cols-2">
              {PARTES_CONTAGEM.map((p) => (
                <div key={p.campo} className="grid gap-1">
                  <label htmlFor={`cnt-${p.campo}`} className="text-sm">{p.rotulo} <span className="text-xs text-muted-foreground">· {p.ajuda}</span></label>
                  <CampoDinheiro id={`cnt-${p.campo}`} value={partes[p.campo]} onChange={(v: string) => setPartes((x) => ({ ...x, [p.campo]: v }))} className="alvo" />
                </div>
              ))}
            </div>
            <p className="flex items-baseline justify-between border-t pt-2 text-sm">
              <span className="font-medium">Total contado</span>
              <span className="num text-lg font-semibold"><Dinheiro valor={deCentimos(total)} /></span>
            </p>
          </fieldset>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={criar.isPending || !conta} onClick={submeter}>{criar.isPending ? t.comum.aGravar : 'Registar contagem'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
