/**
 * Contagem do numerário (P-06 passo 1) · "O dinheiro contado já está todo lançado?"
 * 1. Contar: depois do culto, duas pessoas contam o dinheiro (dízimos, ofertas, Escola Sabatina, outras).
 * 2. Lançar: cada envelope e a salva lançam-se em "Lançar entrada", ligados a esta contagem.
 * 3. Conferir: quando o lançado é igual ao contado, a contagem confere-se.
 * Cada contagem mostra, parte a parte, o contado, o lançado e quanto falta lançar, e quem participou (V42).
 * V43: contam no mínimo o tesoureiro, um representante da Escola Sabatina e um diácono (o ancião pode juntar-se); sem os
 * três a contagem não se confere (a base de dados recusa). Os dois primeiros ficam também como os contadores 1 e 2.
 */
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { Calculator, Check, CircleCheck, HandCoins, Landmark, Plus, Scale, UserPlus, Users, X } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Dinheiro, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { CampoData } from '@/components/comum/CampoData'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { Seleccao } from '@/components/comum/Seleccao'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { centimos, data, deCentimos, dinheiro, hojeIso, qtd } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { DialogoTransferencia } from './DialogoTransferencia'
import { FUNCOES_CONTAGEM, MINIMO_CONTAGEM, PARTES_CONTAGEM, useConferencia, useContagens, useContagensMut, useContasIgreja as useContas, useParticipantesContagem, useParticipantesContagemMut, type Conferencia, type ParticipanteContagem } from './api'

const ESTADO = {
  ABERTA: { r: 'Por conferir', v: 'warning' as const },
  CONFERIDA: { r: 'Conferida', v: 'success' as const },
  DEPOSITADA: { r: 'Depositada', v: 'info' as const },
}
/** Valor sem "MT" (a tabela das partes já é toda em meticais): "1 200,00". */
const mt = (c: number) => dinheiro(deCentimos(Math.abs(c))).replace(/\s*MT$/, '')

/** Rótulos curtos dos que contam, na janela da nova contagem. */
const ROTULO_CURTO: Record<string, string> = { TESOUREIRO: 'Tesoureiro', ESCOLA_SABATINA: 'Escola Sabatina', DIACONO: 'Diácono' }

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
  const porTratar = lista.filter((c) => c.estado !== 'DEPOSITADA')
  const historico = lista.filter((c) => c.estado === 'DEPOSITADA')
  const faltaLancar = abertas.reduce((s, c) => s + Math.max(0, centimos(c.diferenca)), 0)
  const mes = hojeIso().slice(0, 7)
  const doMes = lista.filter((c) => c.data.startsWith(mes))
  const contadoMes = deCentimos(doMes.reduce((s, c) => s + centimos(c.totalContado), 0))

  return (
    <>
      <TituloPagina icone={Calculator} titulo="Contagem do numerário" descricao="O contado em cada culto e o já lançado"
        accoes={pode('tesouraria.contagem_numerario.criar') && <Button className="alvo" onClick={() => setNova(true)}><Plus className="size-4" />Nova contagem</Button>} />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4 [&>*:last-child]:col-span-2 sm:[&>*:last-child]:col-span-1">
          <Indicador rotulo="Contado este mês" valor={<Dinheiro valor={contadoMes} />} nota={`${qtd(doMes.length, 'contagem(ns)')}`} icone={Calculator} aCarregar={conf.isPending} />
          <Indicador rotulo="Por conferir" valor={abertas.length} nota="contagens ainda abertas" icone={Scale} tom="warning" aCarregar={conf.isPending} />
          <Indicador rotulo="Falta lançar" valor={<Dinheiro valor={deCentimos(faltaLancar)} />} nota="contado e ainda não lançado" icone={HandCoins} tom={faltaLancar ? 'destructive' : 'success'} aCarregar={conf.isPending} />
        </div>

        {conf.isPending ? <div className="grid gap-4">{[0, 1].map((i) => <Barra key={i} className="h-40 w-full rounded-xl" />)}</div>
          : conf.isError ? <EstadoErro erro={conf.error} aoTentar={() => conf.refetch()} />
          : lista.length === 0 ? (
            <div className="rounded-xl border bg-card shadow-card">
              <EstadoVazio icone={Calculator} titulo="Ainda não há contagens">Depois do culto, registe quem contou e o que se contou.</EstadoVazio>
            </div>
          ) : (
            <>
              {porTratar.length > 0 && (
                <section className="grid gap-3">
                  <h2 className="text-sm font-semibold">Por tratar <span className="font-normal text-muted-foreground">· {porTratar.length}</span></h2>
                  {porTratar.map((c) => {
                    const cont = porId.get(c.id)
                    return <CartaoContagem key={c.id} c={c} nomeDe={(id) => nomes.get(id)} contadores={cont ? `${nomes.get(cont.contador1MembroId) ?? '—'} e ${nomes.get(cont.contador2MembroId) ?? '—'}` : ''} />
                  })}
                </section>
              )}
              {historico.length > 0 && (
                <Cartao titulo="Histórico" descricao="Contagens já depositadas no banco" icone={Landmark} semMargem>
                  <Tabela porPagina={10}>
                    <thead><tr><th className="sm:pl-6">Data</th><th>Culto</th><th className="num">Contado</th><th className="num sm:pr-6">Estado</th></tr></thead>
                    <tbody>
                      {historico.map((c) => (
                        <tr key={c.id}>
                          <td className="tabular-nums sm:pl-6">{data(c.data)}</td>
                          <td>{c.ocasiao ?? 'Culto'}</td>
                          <td className="num font-medium"><Dinheiro valor={c.totalContado} /></td>
                          <td className="text-right sm:pr-6"><Pilula variante="info">Depositada</Pilula></td>
                        </tr>
                      ))}
                    </tbody>
                  </Tabela>
                </Cartao>
              )}
            </>
          )}
      </div>
      {nova && <DialogoContagem aoFechar={() => setNova(false)} nomeDe={(id) => nomes.get(id)} />}
    </>
  )
}

/** Uma contagem: o contado, o lançado e o que falta, parte a parte, e as acções (lançar, conferir). */
function CartaoContagem({ c, contadores, nomeDe }: { c: Conferencia; contadores: string; nomeDe: (id: number) => string | undefined }) {
  const { pode } = useSessao()
  const { mudarEstado } = useContagensMut()
  const contagens = useContagens()
  const participantes = useParticipantesContagem(c.id)
  const [depositar, setDepositar] = useState(false)
  const activos = (participantes.data ?? []).filter((x) => !x.endDate)
  const faltam = participantes.isPending ? [] : MINIMO_CONTAGEM.filter((f) => !activos.some((x) => x.funcao === f.funcao))
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

  // os quatro passos: quem contou → lançar → conferir → depositar
  const okQuem = !participantes.isPending && faltam.length === 0
  const okLancar = falta === 0
  const passo = !aberta ? 4 : !okQuem ? 1 : !okLancar ? 2 : 3
  const passos = [
    { r: 'Quem contou', d: !aberta ? 'registado' : okQuem ? `${activos.length} pessoas` : `faltam ${faltam.length}`, ok: okQuem || !aberta },
    { r: 'Lançar entradas', d: okLancar ? 'tudo lançado' : `${pct}% lançado`, ok: okLancar || !aberta },
    { r: 'Conferir', d: aberta ? 'tesoureiro confere' : 'conferida', ok: !aberta },
    { r: 'Depositar', d: c.estado === 'DEPOSITADA' ? 'depositada' : 'no banco', ok: c.estado === 'DEPOSITADA' },
  ]
  const dica = !aberta ? 'Quando levar o dinheiro ao banco, registe o depósito com o n.º do talão.'
    : !okQuem ? `Junte ${faltam.map((f) => f.rotulo).join(', ').replace(/, ([^,]*)$/, ' e $1')}.`
    : falta > 0 ? `Faltam ${dinheiro(deCentimos(falta))} por lançar: em "Lançar entrada", escolha esta contagem.`
    : falta < 0 ? 'Lançou-se mais do que o contado: verifique as entradas desta contagem.'
    : 'Está tudo lançado: pode conferir.'

  return (
    <section className={cn('min-w-0 overflow-hidden rounded-xl border bg-card shadow-card', !aberta && 'border-success/40')}>
      <header className="flex flex-wrap items-center justify-between gap-3 px-4 pt-4 sm:px-6 sm:pt-5">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <h3 className="text-base font-semibold"><span className="tabular-nums">{data(c.data)}</span> · {c.ocasiao ?? 'Culto'}</h3>
            <Pilula variante={est.v}>{est.r}</Pilula>
          </div>
          {contadores && !activos.length && !participantes.isPending && <p className="text-sm text-muted-foreground">Contado por {contadores}</p>}
        </div>
        <div className="text-right">
          <p className="text-xs text-muted-foreground">Contado</p>
          <p className="num text-xl font-semibold tracking-tight"><Dinheiro valor={c.totalContado} /></p>
        </div>
      </header>

      <ol className="mx-4 mt-4 grid grid-cols-2 gap-2 sm:mx-6 sm:grid-cols-4" aria-label="Passos da contagem">
        {passos.map((x, i) => {
          const n = i + 1, actual = n === passo
          return (
            <li key={x.r} aria-current={actual ? 'step' : undefined}
              className={cn('flex items-center gap-2.5 rounded-lg border px-3 py-2', actual ? 'border-primary bg-primary/5' : x.ok ? 'border-success/30 bg-tint-success/40' : 'bg-muted/30')}>
              <span className={cn('flex size-6 flex-none items-center justify-center rounded-full text-xs font-semibold',
                x.ok ? 'bg-success text-white' : actual ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground')}>
                {x.ok ? <Check className="size-3.5" /> : n}
              </span>
              <span className="min-w-0">
                <span className={cn('block truncate text-sm font-medium', !x.ok && !actual && 'text-muted-foreground')}>{x.r}</span>
                <span className="block truncate text-xs text-muted-foreground">{x.d}</span>
              </span>
            </li>
          )
        })}
      </ol>

      {aberta && (
        <div className="grid gap-4 px-4 py-4 sm:px-6 lg:grid-cols-2">
          <Participantes contagemId={c.id} aberta={aberta} nomeDe={nomeDe} lista={activos} aCarregar={participantes.isPending} />
          <div className="rounded-lg border">
            <div className="flex items-center justify-between gap-3 border-b px-3 py-2">
              <span className="text-sm font-medium">Lançado</span>
              <span className="flex items-center gap-2 text-xs text-muted-foreground">
                <span className="h-1.5 w-24 overflow-hidden rounded-full bg-muted" aria-hidden><span className={cn('block h-full rounded-full', falta === 0 ? 'bg-success' : 'bg-primary')} style={{ width: `${pct}%` }} /></span>
                {pct}%
              </span>
            </div>
            <table className="w-full text-sm">
              <thead><tr className="text-xs text-muted-foreground"><th className="px-3 pt-2 pb-1 text-left font-medium">Parte</th><th className="px-3 pt-2 pb-1 text-right font-medium">Contado</th><th className="px-3 pt-2 pb-1 text-right font-medium">Falta</th></tr></thead>
              <tbody>
                {partes.map((x) => {
                  const f = x.contado - x.lancado
                  return (
                    <tr key={x.rotulo} className="border-t">
                      <td className="px-3 py-1.5">{x.rotulo}</td>
                      <td className="num px-3 py-1.5 text-right">{mt(x.contado)}</td>
                      <td className={cn('num px-3 py-1.5 text-right font-medium', f === 0 ? 'text-success-text' : 'text-destructive-text')}>{f === 0 ? <Check className="ml-auto size-4" aria-label="lançado" /> : `${mt(f)}${f < 0 ? ' a mais' : ''}`}</td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <footer className={cn('mt-4 flex flex-wrap items-center justify-between gap-3 border-t bg-muted/30 px-4 py-3 sm:px-6', aberta && 'mt-0')}>
        <p className="text-sm text-muted-foreground">{dica}</p>
        <div className="flex flex-wrap gap-2">
          {aberta && passo === 2 && falta > 0 && pode('tesouraria.transacao.criar') && (
            <Button asChild size="sm" className="alvo"><Link to={`/tesouraria/entrada?contagem=${c.id}`}><HandCoins className="size-4" />Lançar entradas</Link></Button>
          )}
          {aberta && pode('tesouraria.contagem_numerario.alterar') && (
            <Button size="sm" variant={passo === 3 ? 'default' : 'outline'} className="alvo" disabled={mudarEstado.isPending || passo !== 3} onClick={conferir}>
              <CircleCheck className="size-4" />Conferir
            </Button>
          )}
          {c.estado === 'CONFERIDA' && pode('tesouraria.transacao.criar') && (
            <Button size="sm" className="alvo" onClick={() => setDepositar(true)}><Landmark className="size-4" />Depositar no banco</Button>
          )}
        </div>
      </footer>
      {depositar && <DialogoTransferencia origem={caixaId} valor={c.totalContado} contagem={{ id: c.id, data: c.data, ocasiao: c.ocasiao }} aoFechar={() => setDepositar(false)} />}
    </section>
  )
}

/** Quem participou na contagem (com a função); enquanto está aberta, junta-se ou tira-se alguém. */
function Participantes({ contagemId, aberta, nomeDe, lista, aCarregar }: {
  contagemId: number; aberta: boolean; nomeDe: (id: number) => string | undefined; lista: ParticipanteContagem[]; aCarregar: boolean
}) {
  const { pode } = useSessao()
  const { juntar, tirar } = useParticipantesContagemMut()
  const [aJuntar, setAJuntar] = useState(false)
  const [membro, setMembro] = useState<number | null>(null)
  const [funcao, setFuncao] = useState('DIACONO')
  const podeJuntar = aberta && pode('tesouraria.contagem_participante.criar')
  const podeTirar = aberta && pode('tesouraria.contagem_participante.terminar')
  if (!lista.length && !podeJuntar) return null

  const gravar = () => {
    if (!membro) return toast.error('Escolha o membro.')
    juntar.mutate({ contagemId, membroId: membro, funcao }, {
      onSuccess: () => { setMembro(null); setAJuntar(false); toast.success('Participante registado.') },
      onError: (e) => toast.error(mensagemDe(e)),
    })
  }

  return (
    <div className="rounded-lg border">
      <div className="flex items-center justify-between gap-3 border-b px-3 py-2">
        <span className="flex items-center gap-1.5 text-sm font-medium"><Users className="size-4 text-muted-foreground" />Quem contou</span>
        {podeJuntar && !aJuntar && <Button type="button" size="sm" variant="ghost" className="alvo h-7" onClick={() => setAJuntar(true)}><UserPlus className="size-4" />Juntar</Button>}
      </div>
      <div className="flex flex-wrap gap-2 px-3 py-3 text-sm">
        {aCarregar ? <Barra className="h-6 w-40" /> : lista.length === 0 ? <span className="text-muted-foreground">Ninguém registado</span> : lista.map((x) => (
          <span key={x.id} className="inline-flex items-center gap-1.5 rounded-full border bg-card py-1 pr-1.5 pl-3">
            <span className="font-medium">{nomeDe(x.membroId) ?? `Membro ${x.membroId}`}</span> <span className="text-xs text-muted-foreground">{FUNCOES_CONTAGEM[x.funcao] ?? x.funcao}</span>
            {podeTirar && (
              <button type="button" className="rounded-full p-0.5 text-muted-foreground hover:bg-muted hover:text-foreground" aria-label={`Tirar ${nomeDe(x.membroId) ?? 'participante'}`} disabled={tirar.isPending}
                onClick={() => tirar.mutate(x.id, { onError: (e) => toast.error(mensagemDe(e)) })}>
                <X className="size-3" />
              </button>
            )}
          </span>
        ))}
      </div>
      {aJuntar && (
        <div className="grid gap-2 border-t px-3 py-3">
          <CampoMembro id={`cpa-${contagemId}`} valor={membro} aoMudar={setMembro} nomeDe={nomeDe} vazio="Procurar o membro…" />
          <Seleccao aria-label="Função na contagem" value={funcao} onChange={(e) => setFuncao(e.target.value)}>
            {Object.entries(FUNCOES_CONTAGEM).map(([k, r]) => <option key={k} value={k}>{r}</option>)}
          </Seleccao>
          <div className="flex gap-2">
            <Button type="button" size="sm" className="alvo" disabled={juntar.isPending} onClick={gravar}>{juntar.isPending ? t.comum.aGravar : 'Juntar'}</Button>
            <Button type="button" size="sm" variant="ghost" className="alvo" onClick={() => setAJuntar(false)}>{t.comum.cancelar}</Button>
          </div>
        </div>
      )}
    </div>
  )
}

function DialogoContagem({ aoFechar, nomeDe }: { aoFechar: () => void; nomeDe: (id: number) => string | undefined }) {
  const igreja = useIgreja()
  const contas = useContas()
  const { criar } = useContagensMut()
  const { juntar } = useParticipantesContagemMut()
  const caixas = (contas.data ?? []).filter((c) => c.tipo === 'CAIXA')
  const [contaId, setContaId] = useState('')
  const [dia, setDia] = useState(hojeIso())
  const [ocasiao, setOcasiao] = useState('Culto de sábado')
  // quem conta: tesoureiro, Escola Sabatina e diácono (obrigatórios) e o ancião (opcional)
  const [quem, setQuem] = useState<Record<string, number | null>>({ TESOUREIRO: null, ESCOLA_SABATINA: null, DIACONO: null, ANCIAO: null })
  const [partes, setPartes] = useState<Record<string, string>>({ dizimos: '', ofertas: '', escolaSabatina: '', construcao: '', outras: '' })
  const validoOuVazio = (v: string) => v === '' || /^\d{1,14}(\.\d{1,2})?$/.test(v)
  const total = Object.values(partes).reduce((s, v) => s + (v && validoOuVazio(v) ? centimos(v) : 0), 0)
  const [erro, setErro] = useState<string | null>(null)
  const conta = caixas.find((c) => String(c.id) === contaId) ?? caixas[0] ?? contas.data?.[0]

  const submeter = async () => {
    setErro(null)
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dia) || dia > hojeIso()) return setErro('A data tem de ser dd/mm/aaaa e não pode ser no futuro.')
    const faltam = MINIMO_CONTAGEM.filter((f) => !quem[f.funcao])
    if (faltam.length) return setErro(`Escolha ${faltam.map((f) => f.rotulo).join(', ')}: contam pelo menos três pessoas.`)
    const escolhidos = Object.values(quem).filter((x): x is number => x != null)
    if (new Set(escolhidos).size !== escolhidos.length) return setErro('Cada pessoa só pode ter uma função na contagem.')
    if (!Object.values(partes).every(validoOuVazio)) return setErro('Há um valor inválido: escreva, por exemplo, 2 350,00.')
    if (total <= 0) return setErro('Escreva o que se contou em pelo menos uma das partes.')
    const parte = (v: string) => (v ? v : '0.00')
    try {
      const nova = await criar.mutateAsync({ igrejaId: igreja.id, contaId: conta!.id, data: dia, ocasiao: ocasiao.trim() || undefined,
        contador1MembroId: quem.TESOUREIRO, contador2MembroId: quem.ESCOLA_SABATINA,
        totalContado: deCentimos(total), dizimos: parte(partes.dizimos), ofertas: parte(partes.ofertas), escolaSabatina: parte(partes.escolaSabatina), construcao: parte(partes.construcao), outras: parte(partes.outras) } as never)
      // os participantes com a função: se algum falhar, a contagem fica e junta-se no cartão
      const falhas: string[] = []
      for (const [funcao, membroId] of Object.entries(quem)) {
        if (membroId == null) continue
        try { await juntar.mutateAsync({ contagemId: nova.id, membroId, funcao }) } catch (e) { falhas.push(`${FUNCOES_CONTAGEM[funcao]}: ${mensagemDe(e)}`) }
      }
      if (falhas.length) toast.warning('A contagem ficou registada, mas falta juntar participantes no cartão', { description: falhas.join(' · '), duration: 10_000 })
      else toast.success('Contagem registada. Ao lançar as entradas em numerário, escolha esta contagem.')
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-3xl">
        <DialogHeader>
          <DialogTitle>Nova contagem</DialogTitle>
          <DialogDescription>Contam o tesoureiro, um representante da Escola Sabatina e um diácono.</DialogDescription>
        </DialogHeader>
        <ErroFormulario mensagem={erro} />
        <div className="grid gap-6 md:grid-cols-2">
          <section className="grid content-start gap-3">
            <h3 className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Quem conta</h3>
            <div className="grid grid-cols-2 gap-3">
              <div className="grid gap-1.5">
                <label htmlFor="cnt-data" className="text-sm font-medium">Data</label>
                <CampoData id="cnt-data" value={dia} onChange={setDia} className="alvo" />
              </div>
              <div className="grid gap-1.5">
                <label htmlFor="cnt-ocasiao" className="text-sm font-medium">Culto</label>
                <Input id="cnt-ocasiao" value={ocasiao} onChange={(e) => setOcasiao(e.target.value)} maxLength={100} className="alvo" />
              </div>
            </div>
            {[...MINIMO_CONTAGEM, { funcao: 'ANCIAO', rotulo: 'o ancião', titulo: 'Ancião' }].map((f) => (
              <div key={f.funcao} className="grid gap-1.5">
                <label htmlFor={`cnt-${f.funcao}`} className="text-sm font-medium">
                  {ROTULO_CURTO[f.funcao] ?? f.titulo}
                  {f.funcao !== 'ANCIAO' ? <span className="text-destructive-text"> *</span> : <span className="font-normal text-muted-foreground"> (opcional)</span>}
                </label>
                <CampoMembro id={`cnt-${f.funcao}`} valor={quem[f.funcao]} aoMudar={(x) => setQuem((q) => ({ ...q, [f.funcao]: x }))} nomeDe={nomeDe} />
              </div>
            ))}
            <div className="grid gap-1.5">
              <label htmlFor="cnt-conta" className="text-sm font-medium">Fica no</label>
              <Seleccao id="cnt-conta" value={conta ? String(conta.id) : ''} onChange={(e) => setContaId(e.target.value)}>
                {(caixas.length ? caixas : contas.data ?? []).map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
              </Seleccao>
            </div>
          </section>
          <section className="grid content-start gap-3">
            <h3 className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">O que se contou</h3>
            <div className="divide-y rounded-xl border bg-muted/30">
              {PARTES_CONTAGEM.map((p) => (
                <div key={p.campo} className="flex items-center justify-between gap-3 px-3 py-2">
                  <label htmlFor={`cnt-${p.campo}`} title={p.ajuda} className="text-sm font-medium">{p.rotulo}</label>
                  <CampoDinheiro id={`cnt-${p.campo}`} value={partes[p.campo]} onChange={(v: string) => setPartes((x) => ({ ...x, [p.campo]: v }))} className="alvo w-40 flex-none" />
                </div>
              ))}
              <p className="flex items-baseline justify-between gap-3 rounded-b-xl bg-card px-3 py-3">
                <span className="text-sm font-medium">Total contado</span>
                <span className="num text-xl font-semibold tracking-tight"><Dinheiro valor={deCentimos(total)} /></span>
              </p>
            </div>
          </section>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={criar.isPending || juntar.isPending || !conta} onClick={submeter}>{criar.isPending || juntar.isPending ? t.comum.aGravar : 'Registar contagem'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
