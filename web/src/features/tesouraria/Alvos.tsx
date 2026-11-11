/**
 * Alvos de arrecadação (F-TES-12): "este ano queremos juntar 300 000 MT para o telhado" ou "o alvo de 13.º sábado é
 * 15 000 MT". O arrecadado vem dos saldos diários do fundo no período (vista vw_progresso_alvo).
 */
import { useState } from 'react'
import { Plus, Target, X } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Dinheiro } from '@/components/comum/elementos'
import { EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { CampoData } from '@/components/comum/CampoData'
import { CampoEscolha } from '@/components/comum/CampoEscolha'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { centimos, data, diasAte, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useAlvos, useAlvosMut, useFundos, useProgressoAlvos, type Alvo } from './api'

export function CartaoAlvos() {
  const { pode } = useSessao()
  const alvos = useAlvos()
  const progresso = useProgressoAlvos()
  const fundos = useFundos()
  const { terminar } = useAlvosMut()
  const [novo, setNovo] = useState(false)
  const [aTerminar, setATerminar] = useState<Alvo | null>(null)
  const prog = new Map((progresso.data ?? []).map((p) => [p.id, p]))
  const lista = (alvos.data ?? []).filter((a) => !a.endDate)
  const nomeFundo = (id: number) => fundos.data?.find((f) => f.id === id)?.nome ?? '—'

  return (
    <Cartao titulo="Alvos" descricao="Quanto a igreja quer juntar em cada fundo, e até quando" icone={Target} semMargem
      accoes={pode('tesouraria.alvo.criar') && <Button size="sm" variant="outline" className="alvo" onClick={() => setNovo(true)}><Plus className="size-4" />Novo alvo</Button>}>
      {alvos.isPending ? <LinhasACarregar linhas={2} />
        : !lista.length ? (
          <EstadoVazio icone={Target} titulo="Ainda não há alvos">
            Por exemplo: 300 000 MT para o telhado até Dezembro, ou o alvo da oferta do 13.º sábado.
          </EstadoVazio>
        ) : (
          <ul className="divide-y">
            {lista.map((a) => {
              const p = prog.get(a.id)
              const feito = centimos(p?.arrecadado ?? '0'), meta = centimos(a.valorAlvo)
              const pct = meta ? Math.round((feito / meta) * 100) : 0
              const dias = diasAte(a.dataFim)
              return (
                <li key={a.id} className="grid gap-2 px-4 py-3 sm:px-6">
                  <div className="flex flex-wrap items-start justify-between gap-2">
                    <div className="min-w-0">
                      <p className="font-medium">{a.descricao || nomeFundo(a.fundoId)}</p>
                      <p className="text-xs text-muted-foreground">
                        {a.descricao ? `${nomeFundo(a.fundoId)} · ` : ''}{data(a.dataInicio)} a {data(a.dataFim)}
                        {dias >= 0 ? ` · faltam ${dias} dia${dias === 1 ? '' : 's'}` : ' · terminado'}
                      </p>
                    </div>
                    <div className="flex items-center gap-1">
                      <p className="text-right text-sm"><span className="num font-semibold"><Dinheiro valor={p?.arrecadado ?? '0.00'} /></span> <span className="text-muted-foreground">de <Dinheiro valor={a.valorAlvo} /></span></p>
                      {pode('tesouraria.alvo.terminar') && (
                        <Button size="icon" variant="ghost" className="alvo text-muted-foreground" aria-label={`Terminar o alvo ${a.descricao ?? ''}`} onClick={() => setATerminar(a)}><X className="size-4" /></Button>
                      )}
                    </div>
                  </div>
                  <div className="h-2 overflow-hidden rounded-full bg-muted" role="img" aria-label={`${pct}% do alvo`}>
                    <div className={cn('h-full rounded-full', pct >= 100 ? 'bg-success' : 'bg-primary')} style={{ width: `${Math.min(100, pct)}%` }} />
                  </div>
                  <p className={cn('text-xs', pct >= 100 ? 'font-medium text-success-text' : 'text-muted-foreground')}>{pct >= 100 ? 'Alvo atingido ✓' : `${pct}% do alvo`}</p>
                </li>
              )
            })}
          </ul>
        )}
      {novo && <DialogoAlvo aoFechar={() => setNovo(false)} />}
      <DialogoConfirmar aberto={!!aTerminar} aoMudar={(v) => !v && setATerminar(null)} titulo="Terminar este alvo?" accao="Terminar"
        texto="Deixa de aparecer aqui. O dinheiro do fundo não muda." aCorrer={terminar.isPending}
        aoConfirmar={() => aTerminar && terminar.mutate(aTerminar.id, { onSuccess: () => { setATerminar(null); toast.success('Alvo terminado.') }, onError: (e) => toast.error(mensagemDe(e)) })} />
    </Cartao>
  )
}

function DialogoAlvo({ aoFechar }: { aoFechar: () => void }) {
  const igreja = useIgreja()
  const fundos = useFundos()
  const { criar } = useAlvosMut()
  const ano = new Date().getFullYear()
  const [fundo, setFundo] = useState('')
  const [descricao, setDescricao] = useState('')
  const [valor, setValor] = useState('')
  const [inicio, setInicio] = useState(hojeIso())
  const [fim, setFim] = useState(`${ano}-12-31`)
  const [erro, setErro] = useState<string | null>(null)
  const submeter = () => {
    setErro(null)
    if (!fundo) return setErro('Escolha o fundo.')
    if (!/^\d{1,14}(\.\d{1,2})?$/.test(valor) || centimos(valor) <= 0) return setErro('Escreva o valor do alvo.')
    if (fim < inicio) return setErro('O fim tem de ser depois do início.')
    criar.mutate({ igrejaId: igreja.id, fundoId: Number(fundo), descricao: descricao.trim() || undefined, valorAlvo: valor, dataInicio: inicio, dataFim: fim }, {
      onSuccess: () => { toast.success('Alvo criado.'); aoFechar() }, onError: (e) => setErro(mensagemDe(e)),
    })
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Novo alvo</DialogTitle>
          <DialogDescription>Conta-se o que entrar no fundo entre as duas datas.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="sm:col-span-2"><ErroFormulario mensagem={erro} /></div>
          <div className="grid gap-1.5 sm:col-span-2">
            <label htmlFor="alv-fundo" className="text-sm font-medium">Fundo <span className="text-destructive-text">*</span></label>
            <CampoEscolha id="alv-fundo" valor={fundo} aoMudar={setFundo} vazio="Escolher o fundo…" opcoes={(fundos.data ?? []).filter((f) => !f.endDate).map((f) => ({ valor: String(f.id), rotulo: f.nome }))} />
          </div>
          <div className="grid gap-1.5 sm:col-span-2">
            <label htmlFor="alv-desc" className="text-sm font-medium">Para quê</label>
            <Input id="alv-desc" value={descricao} onChange={(e) => setDescricao(e.target.value)} className="alvo" maxLength={255} placeholder="ex.: Telhado do templo" />
          </div>
          <div className="grid gap-1.5">
            <label htmlFor="alv-valor" className="text-sm font-medium">Valor do alvo <span className="text-destructive-text">*</span></label>
            <CampoDinheiro id="alv-valor" value={valor} onChange={setValor} className="alvo" />
          </div>
          <div />
          <div className="grid gap-1.5">
            <label htmlFor="alv-ini" className="text-sm font-medium">De</label>
            <CampoData id="alv-ini" value={inicio} onChange={setInicio} className="alvo" />
          </div>
          <div className="grid gap-1.5">
            <label htmlFor="alv-fim" className="text-sm font-medium">Até</label>
            <CampoData id="alv-fim" value={fim} onChange={setFim} className="alvo" />
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={criar.isPending} onClick={submeter}>{criar.isPending ? t.comum.aGravar : 'Criar alvo'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
