/**
 * Fundo de maneio (V42, V56) · "Quanto há para urgências e quanto falta repor?"
 * A igreja define o valor do fundo. As despesas urgentes saem do fundo sem outra aprovação. Todos os meses pede-se a
 * reposição do que foi gasto (o valor definido menos o saldo): se o fundo não foi usado, não há reposição; se as despesas
 * passaram o valor, repõe-se o gasto. O Conselho da Igreja vota a reposição; depois o tesoureiro repõe o dinheiro de uma
 * conta da igreja. A base de dados recusa o que não cumprir isto e explica porquê.
 */
import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Banknote, History, Pencil, RotateCcw, Send } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Dinheiro, Pilula } from '@/components/comum/elementos'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { Seleccao } from '@/components/comum/Seleccao'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { centimos, deCentimos, dinheiro, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { ResumoAprovacao } from '@/features/aprovacoes/EtapasAprovacao'
import { useAprovacoes } from '@/features/aprovacoes/api'
import { useContasMut, useReposicoesManeio, useReposicoesManeioMut, type Conta, type ReposicaoManeio } from './api'

const MESES = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro']

export function FundoManeio({ c, saldo, contasOrigem }: { c: Conta; saldo: string; contasOrigem: Conta[] }) {
  const { pode } = useSessao()
  const reposicoes = useReposicoesManeio()
  const processos = useAprovacoes()
  const [definir, setDefinir] = useState(false)
  const [pedir, setPedir] = useState(false)
  const [repor, setRepor] = useState<ReposicaoManeio | null>(null)
  const valor = c.valorManeio ?? null
  const gasto = valor ? centimos(valor) - centimos(saldo) : 0
  const minhas = (reposicoes.data ?? []).filter((r) => r.contaId === c.id && !r.endDate).slice(0, 3)
  const estadoDe = (r: ReposicaoManeio) => (processos.data ?? []).find((p) => p.reposicaoId === r.id && p.estado !== 'CANCELADO')?.estado
  const pendente = minhas.some((r) => !r.transacaoId && estadoDe(r) !== 'REJEITADO')

  return (
    <li className="grid gap-3">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="font-medium">{c.nome}</p>
          <p className="num text-2xl font-bold tracking-tight"><Dinheiro valor={saldo} /></p>
          <p className="text-xs text-muted-foreground">
            {valor ? <>Valor do fundo <Dinheiro valor={valor} /> · gasto <span className={cn('font-medium', gasto > 0 && 'text-warning-text')}>{dinheiro(deCentimos(Math.max(gasto, 0)))}</span></>
              : 'A igreja ainda não definiu o valor do fundo'}
            {pode('tesouraria.conta_financeira.alterar') && (
              <button type="button" className="alvo ml-1 inline-flex items-center gap-1 font-medium text-primary hover:underline" onClick={() => setDefinir(true)}>
                <Pencil className="size-3" />{valor ? 'Mudar' : 'Definir'}
              </button>
            )}
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          {pode('tesouraria.reposicao_maneio.criar') && valor && gasto > 0 && !pendente && (
            <Button size="sm" variant="outline" className="alvo" onClick={() => setPedir(true)}><Send className="size-4" />Pedir reposição</Button>
          )}
          {pode('tesouraria.transacao.criar') && <Button asChild size="sm" variant="outline" className="alvo"><Link to={`/tesouraria/saida?conta=${c.id}`}><Banknote className="size-4" />Despesa urgente</Link></Button>}
          <Button asChild size="sm" variant="ghost" className="alvo"><Link to={`/tesouraria/movimentos?conta=${c.id}`}><History className="size-4" />Histórico</Link></Button>
        </div>
      </div>
      {valor && gasto <= 0 && !pendente && <p className="text-xs text-muted-foreground">O fundo não foi usado desde a última reposição: não há reposição a pedir.</p>}
      {minhas.length > 0 && (
        <ul className="grid gap-2 rounded-lg border bg-muted/20 p-3">
          {minhas.map((r) => {
            const estado = estadoDe(r)
            return (
              <li key={r.id} className="grid gap-1">
                <div className="flex flex-wrap items-center justify-between gap-2 text-sm">
                  <span><span className="font-medium">Reposição de {MESES[r.mes - 1]} {r.ano}</span> · <Dinheiro valor={r.valor} /></span>
                  {r.transacaoId ? <Pilula variante="success">Reposta</Pilula>
                    : estado === 'APROVADO' && pode('tesouraria.transacao.criar') ? (
                      <Button size="sm" className="alvo" onClick={() => setRepor(r)}><RotateCcw className="size-4" />Repor</Button>
                    ) : null}
                </div>
                {!r.transacaoId && <ResumoAprovacao filtro={{ reposicaoId: r.id }} compacto rotuloBotao="Registar o voto" />}
              </li>
            )
          })}
        </ul>
      )}
      {definir && <DialogoValor c={c} aoFechar={() => setDefinir(false)} />}
      {pedir && valor && <DialogoPedir c={c} gasto={deCentimos(gasto)} aoFechar={() => setPedir(false)} />}
      {repor && <DialogoRepor r={repor} contas={contasOrigem} aoFechar={() => setRepor(null)} />}
    </li>
  )
}

function DialogoValor({ c, aoFechar }: { c: Conta; aoFechar: () => void }) {
  const { alterar } = useContasMut()
  const [valor, setValor] = useState(c.valorManeio ?? '')
  const [erro, setErro] = useState<string | null>(null)
  const gravar = async () => {
    setErro(null)
    if (!/^\d{1,14}(\.\d{1,2})?$/.test(valor) || Number(valor) <= 0) return setErro('Escreva o valor do fundo, por exemplo 5 000,00.')
    try {
      await alterar.mutateAsync({ id: c.id, valorManeio: valor } as never)
      toast.success('Valor do fundo de maneio definido.')
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Valor do fundo de maneio</DialogTitle>
          <DialogDescription>O valor que a igreja decidiu ter à mão para urgências. Cada mês repõe-se só o que foi gasto, até este valor.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-3">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5">
            <label htmlFor="mnj-valor" className="text-sm font-medium">Valor do fundo</label>
            <CampoDinheiro id="mnj-valor" value={valor} onChange={setValor} className="alvo" />
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={alterar.isPending} onClick={gravar}>{alterar.isPending ? t.comum.aGravar : t.comum.guardar}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function DialogoPedir({ c, gasto, aoFechar }: { c: Conta; gasto: string; aoFechar: () => void }) {
  const igreja = useIgreja()
  const { pedir } = useReposicoesManeioMut()
  const hoje = hojeIso()
  const [mes, setMes] = useState(Number(hoje.slice(5, 7)))
  const [ano] = useState(Number(hoje.slice(0, 4)))
  const [valor, setValor] = useState(gasto)
  const [erro, setErro] = useState<string | null>(null)
  const gravar = async () => {
    setErro(null)
    if (!/^\d{1,14}(\.\d{1,2})?$/.test(valor) || Number(valor) <= 0) return setErro('Escreva o valor a repor.')
    if (centimos(valor) > centimos(gasto)) return setErro(`Só se repõe o que foi gasto: até ${dinheiro(gasto)}.`)
    try {
      await pedir.mutateAsync({ igrejaId: igreja.id, contaId: c.id, ano, mes, valor } as never)
      toast.success('Reposição pedida: aguarda o voto do Conselho da Igreja.')
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Pedir a reposição do fundo de maneio</DialogTitle>
          <DialogDescription>{c.nome}: gastaram-se {dinheiro(gasto)}. A reposição vai a voto no Conselho da Igreja.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-3">
          <ErroFormulario mensagem={erro} />
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-1.5">
              <label htmlFor="rpm-mes" className="text-sm font-medium">Mês</label>
              <Seleccao id="rpm-mes" className="alvo" value={mes} onChange={(e) => setMes(Number(e.target.value))}>
                {MESES.map((m, i) => <option key={m} value={i + 1}>{m} {ano}</option>)}
              </Seleccao>
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="rpm-valor" className="text-sm font-medium">Valor a repor</label>
              <CampoDinheiro id="rpm-valor" value={valor} onChange={setValor} className="alvo" />
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={pedir.isPending} onClick={gravar}>{pedir.isPending ? t.comum.aGravar : 'Pedir reposição'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function DialogoRepor({ r, contas, aoFechar }: { r: ReposicaoManeio; contas: Conta[]; aoFechar: () => void }) {
  const { repor } = useReposicoesManeioMut()
  const [origem, setOrigem] = useState(String(contas[0]?.id ?? ''))
  const [erro, setErro] = useState<string | null>(null)
  const gravar = async () => {
    setErro(null)
    if (!origem) return setErro('Escolha a conta de onde sai o dinheiro.')
    try {
      await repor.mutateAsync({ id: r.id, contaOrigemId: Number(origem) })
      toast.success('Fundo de maneio reposto.')
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Repor o fundo de maneio</DialogTitle>
          <DialogDescription>Aprovada pelo Conselho: {dinheiro(r.valor)} passam para o fundo de maneio.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-3">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5">
            <label htmlFor="rpm-origem" className="text-sm font-medium">Sai de</label>
            <Seleccao id="rpm-origem" className="alvo" value={origem} onChange={(e) => setOrigem(e.target.value)}>
              {contas.map((x) => <option key={x.id} value={x.id}>{x.nome}</option>)}
            </Seleccao>
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={repor.isPending} onClick={gravar}>{repor.isPending ? t.comum.aGravar : 'Repor'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
