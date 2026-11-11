/**
 * Consentimentos do membro (protecção de dados): guardar os dados, fotografias, SMS, WhatsApp e email. Cada mudança
 * é um registo novo com a data (o histórico fica); vale o mais recente de cada tipo. Nos menores, o consentimento
 * dos dados pessoais é dado pelo encarregado (vw_menores_pendentes avisa quando falta).
 */
import { useState } from 'react'
import { Check, ShieldCheck, X } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao } from '@/components/comum/elementos'
import { LinhasACarregar } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { data, hojeIso, idade } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos, type Membro } from '@/features/membros/api'
import { TIPOS_CONSENTIMENTO, useConsentimentos, useCriarConsentimento, type Consentimento, type TipoConsentimento } from './api'

export function CartaoConsentimentos({ m }: { m: Membro }) {
  const { pode } = useSessao()
  const q = useConsentimentos(m.id)
  const [registar, setRegistar] = useState<TipoConsentimento | null>(null)
  const menor = (idade(m.dataNascimento) ?? 99) < 18
  // o mais recente de cada tipo (a lista vem por data descendente; em empate, o último registado)
  const ultimo = new Map<TipoConsentimento, Consentimento>()
  for (const c of [...(q.data ?? [])].filter((c) => !c.endDate).sort((a, b) => b.data.localeCompare(a.data) || b.id - a.id)) {
    if (!ultimo.has(c.tipo)) ultimo.set(c.tipo, c)
  }
  if (!pode('secretaria.consentimento.ler')) return null
  return (
    <Cartao titulo="Consentimentos" descricao={menor ? 'Menor: o encarregado dá o consentimento' : 'O que o membro autoriza'} icone={ShieldCheck} semMargem>
      {q.isPending ? <LinhasACarregar linhas={3} /> : (
        <ul className="divide-y">
          {TIPOS_CONSENTIMENTO.map((tc) => {
            const c = ultimo.get(tc.tipo)
            return (
              <li key={tc.tipo} className="flex items-center justify-between gap-3 px-4 py-2.5 sm:px-6">
                <div className="min-w-0">
                  <p className="text-sm font-medium">{tc.rotulo}</p>
                  <p className="text-xs text-muted-foreground">{c ? `${c.concedido ? 'Autorizou' : 'Recusou'} a ${data(c.data)}` : 'Sem registo'}</p>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className={cn('flex size-6 items-center justify-center rounded-full', c ? (c.concedido ? 'bg-success/15 text-success-text' : 'bg-destructive/10 text-destructive-text') : 'bg-muted text-muted-foreground')}
                    aria-label={c ? (c.concedido ? 'Autorizado' : 'Recusado') : 'Sem registo'} role="img">
                    {c ? (c.concedido ? <Check className="size-3.5" /> : <X className="size-3.5" />) : <span className="text-xs">?</span>}
                  </span>
                  {pode('secretaria.consentimento.criar') && <Button size="sm" variant="ghost" className="alvo" onClick={() => setRegistar(tc.tipo)}>Mudar</Button>}
                </div>
              </li>
            )
          })}
        </ul>
      )}
      {registar && <DialogoConsentimento m={m} tipo={registar} actual={ultimo.get(registar)} menor={menor} aoFechar={() => setRegistar(null)} />}
    </Cartao>
  )
}

function DialogoConsentimento({ m, tipo, actual, menor, aoFechar }: { m: Membro; tipo: TipoConsentimento; actual?: Consentimento; menor: boolean; aoFechar: () => void }) {
  const criar = useCriarConsentimento(m.id)
  const membros = useMembrosBasicos()
  const tc = TIPOS_CONSENTIMENTO.find((x) => x.tipo === tipo)!
  const [concedido, setConcedido] = useState(actual ? !actual.concedido : true)
  const [dia, setDia] = useState(hojeIso())
  const [porQuem, setPorQuem] = useState<number | null>(menor ? (m.encarregadoMembroId ?? null) : null)
  const [obs, setObs] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const nomeDe = (id: number) => { const x = membros.data?.find((y) => y.id === id); return x ? `${x.nome} ${x.apelido}` : undefined }
  const submeter = () => {
    setErro(null)
    if (menor && tipo === 'DADOS_PESSOAIS' && concedido && !porQuem) return setErro('Num menor, indique o encarregado que deu o consentimento.')
    criar.mutate({ tipo, concedido, data: dia, concedidoPorMembroId: porQuem ?? undefined, observacoes: obs.trim() || undefined }, {
      onSuccess: () => { toast.success('Consentimento registado.'); aoFechar() }, onError: (e) => setErro(mensagemDe(e)),
    })
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{tc.rotulo}</DialogTitle>
          <DialogDescription>{tc.ajuda}. Fica registado com a data; o anterior mantém-se no histórico.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div role="radiogroup" aria-label="Decisão" className="grid grid-cols-2 gap-2">
            {[{ v: true, r: 'Autoriza' }, { v: false, r: 'Não autoriza' }].map((o) => (
              <button key={o.r} type="button" role="radio" aria-checked={concedido === o.v} onClick={() => setConcedido(o.v)}
                className={cn('alvo rounded-lg border px-3 py-2 text-sm font-medium', concedido === o.v ? 'border-primary bg-primary/10 text-primary' : 'text-muted-foreground')}>{o.r}</button>
            ))}
          </div>
          <div className="grid gap-1.5 sm:w-1/2">
            <label htmlFor="cns-data" className="text-sm font-medium">Data</label>
            <CampoData id="cns-data" value={dia} onChange={setDia} className="alvo" />
          </div>
          {menor && (
            <div className="grid gap-1.5">
              <label htmlFor="cns-quem" className="text-sm font-medium">Dado pelo encarregado</label>
              <CampoMembro id="cns-quem" valor={porQuem} aoMudar={setPorQuem} nomeDe={nomeDe} excluir={[m.id]} vazio="Escolher o encarregado…" />
            </div>
          )}
          <div className="grid gap-1.5">
            <label htmlFor="cns-obs" className="text-sm font-medium">Observações</label>
            <Input id="cns-obs" value={obs} onChange={(e) => setObs(e.target.value)} className="alvo" maxLength={500} placeholder="ex.: assinou o formulário em papel" />
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={criar.isPending} onClick={submeter}>{criar.isPending ? t.comum.aGravar : 'Registar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
