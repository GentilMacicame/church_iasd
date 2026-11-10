/**
 * Estorno (P-12): corrige um movimento confirmado com outro, do tipo contrário, pelo valor errado (no máximo o
 * original). O estorno fica PENDENTE e segue o caminho normal: aprovação por outra pessoa e confirmação. A base
 * de dados recusa estornar o que não está confirmado ou estornar mais do que o original.
 */
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { ErroFormulario } from '@/components/comum/formulario'
import { mensagemDe } from '@/api/erros'
import { t } from '@/i18n/pt-MZ'
import { centimos, deCentimos, dinheiro } from '@/lib/formatos'
import { useEstornar, type Linha, type Transacao } from './api'

export function DialogoEstorno({ tr, linhas, fundoDe, aberto, aoMudar }: {
  tr: Transacao; linhas: Linha[]; fundoDe: (id: number) => string; aberto: boolean; aoMudar: (v: boolean) => void
}) {
  const navigate = useNavigate()
  const estornar = useEstornar(tr.id)
  const [valores, setValores] = useState<Record<number, string>>(() => Object.fromEntries(linhas.map((l) => [l.id, l.valor])))
  const [motivo, setMotivo] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const [tentou, setTentou] = useState(false)

  /** Centimos de um valor escrito; -1 se ainda não for um valor válido. */
  const c = (v?: string) => (!v ? 0 : /^\d{1,14}(\.\d{1,2})?$/.test(v) ? centimos(v) : -1)
  const invalidos = linhas.filter((l) => c(valores[l.id]) < 0)
  const total = linhas.reduce((s, l) => s + Math.max(0, c(valores[l.id])), 0)
  const acima = linhas.filter((l) => c(valores[l.id]) > centimos(l.valor))
  const semMotivo = motivo.trim().length < 5

  const submeter = async () => {
    setTentou(true)
    setErro(null)
    if (semMotivo || total <= 0 || acima.length || invalidos.length) return
    try {
      const novo = await estornar.mutateAsync({
        valor: deCentimos(total), motivo: motivo.trim(),
        linhas: linhas.filter((l) => c(valores[l.id]) > 0).map((l) => ({ fundoId: l.fundoId, categoriaId: l.categoriaId, valor: valores[l.id] })),
      })
      toast.success('Estorno registado. Fica à espera da aprovação de outra pessoa.')
      aoMudar(false)
      navigate(`/tesouraria/movimentos/${novo.id}`)
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }

  return (
    <Dialog open={aberto} onOpenChange={(v) => { aoMudar(v); if (!v) { setErro(null); setTentou(false) } }}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Estornar {tr.tipo === 'ENTRADA' ? 'esta entrada' : 'esta saída'}</DialogTitle>
          <DialogDescription>
            O movimento original não se altera. Regista-se {tr.tipo === 'ENTRADA' ? 'uma saída' : 'uma entrada'} pelo valor a corrigir,
            que outra pessoa aprova antes de contar nos saldos.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-3">
            {linhas.map((l) => (
              <div key={l.id} className="grid grid-cols-[1fr_9rem] items-center gap-3">
                <label htmlFor={`est-${l.id}`} className="text-sm">
                  <span className="font-medium">{fundoDe(l.fundoId)}</span>
                  <span className="block text-xs text-muted-foreground">original {dinheiro(l.valor)}</span>
                </label>
                <CampoDinheiro id={`est-${l.id}`} value={valores[l.id] ?? ''} onChange={(v) => setValores((x) => ({ ...x, [l.id]: v }))} className="alvo"
                  aria-invalid={c(valores[l.id]) < 0 || c(valores[l.id]) > centimos(l.valor) || undefined} />
              </div>
            ))}
            <div className="flex items-center justify-between border-t pt-3 text-sm">
              <span className="font-medium">A estornar</span>
              <span className="num font-semibold">{dinheiro(deCentimos(total))}</span>
            </div>
            {acima.length > 0 && <p className="text-sm text-destructive-text">Não pode estornar mais do que o valor original de cada fundo.</p>}
            {invalidos.length > 0 && <p className="text-sm text-destructive-text">Escreva os valores como 1 500,00.</p>}
            {tentou && total <= 0 && <p className="text-sm text-destructive-text">Escreva o valor a estornar.</p>}
          </div>
          <div className="grid gap-1.5">
            <label htmlFor="est-motivo" className="text-sm font-medium">Motivo <span className="text-destructive-text">*</span></label>
            <Textarea id="est-motivo" value={motivo} onChange={(e) => setMotivo(e.target.value)} rows={3} placeholder="ex.: valor lançado em duplicado no sábado 07/11"
              aria-invalid={(tentou && semMotivo) || undefined} />
            {tentou && semMotivo && <p className="text-sm text-destructive-text">Explique o erro que este estorno corrige.</p>}
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={() => aoMudar(false)}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={estornar.isPending} onClick={submeter}>{estornar.isPending ? t.comum.aGravar : 'Registar estorno'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
