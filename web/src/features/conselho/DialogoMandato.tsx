/**
 * Criar ou editar um mandato (V31): início, duração (1–5 anos ou outra data), nome, voto que elegeu e observações.
 * Usado no ecrã dos mandatos e na eleição de oficiais.
 */
import { useState } from 'react'
import { CalendarRange } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { mensagemDe } from '@/api/erros'
import { t } from '@/i18n/pt-MZ'
import { data } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { CampoVoto } from '@/features/livro/CampoVoto'
import { fimDoMandato, useConselhoMut, type Mandato } from './api'
import { ISO, anosInteiros, duracaoTexto, nomeSugerido } from './mandatos'

export function DialogoMandato({ mandato, anosPadrao, inicioSugerido, aoFechar, aoGravar }: {
  mandato?: Mandato; anosPadrao: number; inicioSugerido: string; aoFechar: () => void; aoGravar?: (id: number) => void
}) {
  const { criarMandato, alterarMandato } = useConselhoMut()
  const inteiro = mandato ? anosInteiros(mandato.dataInicio, mandato.dataFim) : anosPadrao
  const [inicio, setInicio] = useState(mandato?.dataInicio ?? inicioSugerido)
  const [duracao, setDuracao] = useState<string>(inteiro ? String(inteiro) : 'outra')
  const [fimManual, setFimManual] = useState(mandato?.dataFim ?? '')
  const fim = duracao === 'outra' ? fimManual : fimDoMandato(inicio, Number(duracao))
  const [nome, setNome] = useState(mandato?.nome ?? '')
  const [nomeTocado, setNomeTocado] = useState(!!mandato)
  const nomeFinal = nomeTocado ? nome : nomeSugerido(inicio, fim)
  const [voto, setVoto] = useState(mandato?.votoId ? String(mandato.votoId) : '')
  const [obs, setObs] = useState(mandato?.observacoes ?? '')
  const [erro, setErro] = useState<string | null>(null)
  const aGravar = criarMandato.isPending || alterarMandato.isPending

  const submeter = async () => {
    setErro(null)
    if (!ISO.test(inicio)) return setErro('Escreva o início do mandato como dd/mm/aaaa.')
    if (!ISO.test(fim)) return setErro('Indique o fim do mandato.')
    if (!nomeFinal.trim()) return setErro('Dê um nome ao mandato.')
    const corpo = { nome: nomeFinal.trim(), dataInicio: inicio, dataFim: fim, votoId: voto ? Number(voto) : undefined, observacoes: obs.trim() || undefined }
    try {
      if (mandato) {
        await alterarMandato.mutateAsync({ id: mandato.id, ...corpo, votoId: corpo.votoId ?? null, observacoes: corpo.observacoes ?? null })
        toast.success(`${corpo.nome} actualizado.`, { description: 'Os oficiais do mandato acompanham as novas datas.' })
      } else {
        const m = await criarMandato.mutateAsync(corpo)
        toast.success(`${corpo.nome} criado.`, { description: 'Agora acrescente os oficiais do conselho e da direcção.' })
        aoGravar?.(m.id)
      }
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{mandato ? 'Editar mandato' : 'Novo mandato'}</DialogTitle>
          <DialogDescription>
            {mandato ? 'Se mudar as datas, os oficiais deste mandato passam a ter as mesmas.' : 'O período em que servem os oficiais eleitos. Depois acrescenta-os ao conselho ou à direcção.'}
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5">
            <label htmlFor="mdt-ini" className="text-sm font-medium">Começa em <span className="text-destructive-text">*</span></label>
            <CampoData id="mdt-ini" value={inicio} onChange={setInicio} className="alvo" />
          </div>
          <fieldset className="grid gap-1.5">
            <legend className="mb-1.5 text-sm font-medium">Duração <span className="text-destructive-text">*</span></legend>
            <div role="radiogroup" aria-label="Duração" className="grid grid-cols-3 gap-2 sm:grid-cols-6">
              {['1', '2', '3', '4', '5', 'outra'].map((n) => (
                <button key={n} type="button" role="radio" aria-checked={duracao === n} onClick={() => setDuracao(n)}
                  className={cn('alvo rounded-lg border py-2 text-sm font-semibold transition', duracao === n ? 'border-primary bg-primary/10 text-primary' : 'text-muted-foreground hover:border-primary/40')}>
                  {n === 'outra' ? <>Outra<span className="block text-[11px] font-normal">data</span></> : <>{n}<span className="block text-[11px] font-normal">{n === '1' ? 'ano' : 'anos'}</span></>}
                </button>
              ))}
            </div>
          </fieldset>
          {duracao === 'outra' && (
            <div className="grid gap-1.5">
              <label htmlFor="mdt-fim" className="text-sm font-medium">Último dia do mandato <span className="text-destructive-text">*</span></label>
              <CampoData id="mdt-fim" value={fimManual} onChange={setFimManual} className="alvo" />
            </div>
          )}
          <div className="grid gap-1.5">
            <label htmlFor="mdt-nome" className="text-sm font-medium">Nome <span className="text-destructive-text">*</span></label>
            <Input id="mdt-nome" value={nomeFinal} maxLength={100} onChange={(e) => { setNomeTocado(true); setNome(e.target.value) }} className="alvo" />
          </div>
          <div className="grid gap-1.5">
            <label htmlFor="mdt-voto" className="text-sm font-medium">Voto da igreja que elegeu <span className="font-normal text-muted-foreground">(opcional)</span></label>
            <CampoVoto id="mdt-voto" valor={voto} aoMudar={setVoto} reunioes={['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA']} preferir="ELEICAO" />
          </div>
          <div className="grid gap-1.5">
            <label htmlFor="mdt-obs" className="text-sm font-medium">Observações <span className="font-normal text-muted-foreground">(opcional)</span></label>
            <Input id="mdt-obs" value={obs} maxLength={255} onChange={(e) => setObs(e.target.value)} className="alvo" />
          </div>
          {ISO.test(inicio) && ISO.test(fim) && (
            <div className="flex items-center gap-3 rounded-lg bg-muted/60 px-4 py-3 text-sm">
              <CalendarRange className="size-5 flex-none text-primary" />
              <span><span className="font-semibold">{nomeFinal || 'Mandato'}</span> · <span className="tabular-nums">{data(inicio)} → {data(fim)}</span>
                {fim > inicio && <> · {duracaoTexto(inicio, fim)}</>}</span>
            </div>
          )}
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={aGravar} onClick={submeter}>{aGravar ? t.comum.aGravar : mandato ? t.comum.guardar : 'Criar mandato'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
