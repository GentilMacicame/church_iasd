/**
 * Contagem do numerário (P-06 passo 1) · "O dinheiro contado bate com o que foi lançado?"
 * Dois contadores (tesoureiro e diácono, pessoas diferentes) contam o dinheiro do culto; as entradas em numerário
 * desse culto ligam-se à contagem ao lançar. A conferência compara o contado com o lançado e confirmado.
 */
import { Fragment, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { Calculator, CircleCheck, HandCoins, Plus, Scale } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Dinheiro, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
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
import { PARTES_CONTAGEM, useConferencia, useContagens, useContagensMut, useContasIgreja as useContas, type Conferencia } from './api'

export default function PaginaContagens() {
  const { pode } = useSessao()
  const conf = useConferencia()
  const contagens = useContagens()
  const basicos = useMembrosBasicos()
  const { mudarEstado } = useContagensMut()
  const [nova, setNova] = useState(false)
  const nomes = useMemo(() => new Map((basicos.data ?? []).map((m) => [m.id, `${m.nome} ${m.apelido}`])), [basicos.data])
  const porId = useMemo(() => new Map((contagens.data ?? []).map((c) => [c.id, c])), [contagens.data])
  const lista = [...(conf.data ?? [])].sort((a, b) => b.data.localeCompare(a.data) || b.id - a.id)
  const abertas = lista.filter((c) => c.estado === 'ABERTA')
  const comDiferenca = lista.filter((c) => centimos(c.diferenca) !== 0 && c.estado !== 'ABERTA')
  const mes = hojeIso().slice(0, 7)
  const doMes = lista.filter((c) => c.data.startsWith(mes))
  const contadoMes = (doMes.reduce((s, c) => s + centimos(c.totalContado), 0) / 100).toFixed(2)

  const conferir = (id: number) => mudarEstado.mutate({ id, estado: 'CONFERIDA' }, {
    onSuccess: () => toast.success('Contagem conferida.'), onError: (e) => toast.error(mensagemDe(e)),
  })

  return (
    <>
      <TituloPagina icone={Calculator} titulo="Contagem do numerário" descricao="O dinheiro de cada culto, contado por duas pessoas e comparado com o que se lançou"
        accoes={pode('tesouraria.contagem_numerario.criar') && <Button className="alvo" onClick={() => setNova(true)}><Plus className="size-4" />Nova contagem</Button>} />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4 [&>*:last-child]:col-span-2 sm:[&>*:last-child]:col-span-1">
          <Indicador rotulo="Contado este mês" valor={<Dinheiro valor={contadoMes} />} nota={`${doMes.length} contagem(ns)`} icone={Calculator} aCarregar={conf.isPending} />
          <Indicador rotulo="Por conferir" valor={abertas.length} nota="contagens abertas" icone={Scale} tom="warning" aCarregar={conf.isPending} />
          <Indicador rotulo="Com diferença" valor={comDiferenca.length} nota="contado ≠ lançado" icone={HandCoins} tom={comDiferenca.length ? 'destructive' : 'success'} aCarregar={conf.isPending} />
        </div>
        <section className="min-w-0 rounded-xl border bg-card shadow-card">
          <div className="border-b px-4 py-3 sm:px-6">
            <h2 className="font-semibold">Conferência</h2>
            <p className="text-sm text-muted-foreground">Ao lançar as entradas em numerário de um culto, escolha a contagem: o lançado soma aqui.</p>
          </div>
          {conf.isPending ? <LinhasACarregar linhas={4} />
            : conf.isError ? <EstadoErro erro={conf.error} aoTentar={() => conf.refetch()} className="m-4" />
            : lista.length === 0 ? <EstadoVazio icone={Calculator} titulo="Ainda não há contagens">Depois do culto, registe o total contado pelos dois contadores.</EstadoVazio>
            : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Culto</th><th className="num">Contado</th><th className="num hidden sm:table-cell">Lançado</th><th className="num">Diferença</th><th>Estado</th><th className="sm:pr-6"><span className="sr-only">Acções</span></th></tr></thead>
                <tbody>
                  {lista.map((c) => {
                    const cont = porId.get(c.id)
                    const dif = centimos(c.diferenca)
                    return (
                      <Fragment key={c.id}>
                      <tr className={cn(c.dizimos != null && '[&>td]:border-b-0')}>
                        <td className="sm:pl-6">
                          <p className="font-medium"><span className="tabular-nums">{data(c.data)}</span> · {c.ocasiao ?? 'Culto'}</p>
                          {cont && <p className="text-xs text-muted-foreground">{nomes.get(cont.contador1MembroId) ?? '—'} e {nomes.get(cont.contador2MembroId) ?? '—'}</p>}
                        </td>
                        <td className="num font-medium"><Dinheiro valor={c.totalContado} /></td>
                        <td className="num hidden text-muted-foreground sm:table-cell"><Dinheiro valor={c.totalLancado} /></td>
                        <td className={cn('num font-medium', dif === 0 ? 'text-success-text' : 'text-destructive-text')}>{dif === 0 ? 'certo' : <Dinheiro valor={c.diferenca} />}</td>
                        <td><Pilula variante={c.estado === 'ABERTA' ? 'warning' : c.estado === 'CONFERIDA' ? 'success' : 'info'}>{c.estado === 'ABERTA' ? 'Aberta' : c.estado === 'CONFERIDA' ? 'Conferida' : 'Depositada'}</Pilula></td>
                        <td className="text-right sm:pr-6">
                          {c.estado === 'ABERTA' && pode('tesouraria.contagem_numerario.alterar') && (
                            <Button size="sm" variant="outline" className="alvo" disabled={mudarEstado.isPending || dif !== 0} title={dif !== 0 ? 'O lançado tem de bater com o contado' : undefined}
                              onClick={() => conferir(c.id)}><CircleCheck className="size-4" />Conferir</Button>
                          )}
                        </td>
                      </tr>
                      {c.dizimos != null && <LinhaPartes c={c} />}
                      </Fragment>
                    )
                  })}
                </tbody>
              </Tabela>
            )}
        </section>
        {abertas.some((c) => centimos(c.diferenca) !== 0) && pode('tesouraria.transacao.criar') && (
          <p className="text-sm text-muted-foreground">Falta lançar parte do contado? <Link to="/tesouraria/entrada" className="font-medium text-primary hover:underline">Lançar entrada</Link> e escolha a contagem do culto.</p>
        )}
      </div>
      {nova && <DialogoContagem aoFechar={() => setNova(false)} nomeDe={(id) => nomes.get(id)} />}
    </>
  )
}

/** Por baixo de cada contagem: cada parte, contado / lançado; a que não bate fica a vermelho. */
function LinhaPartes({ c }: { c: Conferencia }) {
  return (
    <tr>
      <td colSpan={6} className="pt-0 sm:px-6">
        <ul className="flex flex-wrap gap-x-5 gap-y-1 text-xs">
          {PARTES_CONTAGEM.map((p) => {
            const contado = centimos(c[p.campo] ?? '0')
            const lancado = centimos(c[`${p.campo}Lancado`] ?? '0')
            if (!contado && !lancado) return null
            const certo = contado === lancado
            return (
              <li key={p.campo} className={cn('tabular-nums', certo ? 'text-muted-foreground' : 'font-medium text-destructive-text')}>
                {p.rotulo}: {dinheiro(deCentimos(contado))}{certo ? ' ✓' : ` · lançado ${dinheiro(deCentimos(lancado))}`}
              </li>
            )
          })}
        </ul>
      </td>
    </tr>
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
