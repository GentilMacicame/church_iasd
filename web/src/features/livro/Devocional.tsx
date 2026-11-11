/**
 * Abertura e encerramento da reunião (V28): quem fez a meditação (um membro ou um convidado, ex.: o pastor do
 * distrito), o hino entoado e quem fez a primeira e a última oração. Entram no texto da acta.
 */
import { useState } from 'react'
import { BookOpenText, Music, Pencil } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao } from '@/components/comum/elementos'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { ErroFormulario } from '@/components/comum/formulario'
import { mensagemDe } from '@/api/erros'
import { t } from '@/i18n/pt-MZ'
import { cn } from '@/lib/utils'
import { useReuniaoMut, type Reuniao } from './api'

/** Quem fez a meditação: o membro ou o convidado. */
export const quemMeditou = (r: Reuniao, nome: (id?: number | null) => string | undefined) =>
  (r.meditacaoMembroId ? nome(r.meditacaoMembroId) : r.meditacaoConvidado) || ''

export function CartaoDevocional({ reuniao: r, fechada, nomeDe }: { reuniao: Reuniao; fechada: boolean; nomeDe: (id: number) => string | undefined }) {
  const [editar, setEditar] = useState(false)
  const nome = (id?: number | null) => (id ? nomeDe(id) : undefined)
  const linhas = [
    { r: 'Primeira oração', v: nome(r.oracaoInicialMembroId) },
    { r: 'Hino', v: r.hino },
    { r: 'Meditação', v: quemMeditou(r, nome) },
    { r: 'Última oração', v: nome(r.oracaoFinalMembroId) },
  ]
  const vazio = linhas.every((l) => !l.v)
  return (
    <Cartao titulo="Abertura e encerramento" descricao="Orações, hino e meditação" icone={BookOpenText} semMargem
      accoes={!fechada && <Button size="sm" variant="ghost" className="alvo" onClick={() => setEditar(true)}><Pencil className="size-4" />{vazio ? 'Registar' : 'Editar'}</Button>}>
      <dl className="divide-y">
        {linhas.map((l) => (
          <div key={l.r} className="flex items-baseline justify-between gap-3 px-4 py-2.5 sm:px-6">
            <dt className="text-sm text-muted-foreground">{l.r}</dt>
            <dd className={cn('min-w-0 truncate text-right text-sm font-medium', !l.v && 'font-normal text-muted-foreground')}>{l.v || '—'}</dd>
          </div>
        ))}
      </dl>
      {editar && <DialogoDevocional r={r} nomeDe={nomeDe} aoFechar={() => setEditar(false)} />}
    </Cartao>
  )
}

function DialogoDevocional({ r, nomeDe, aoFechar }: { r: Reuniao; nomeDe: (id: number) => string | undefined; aoFechar: () => void }) {
  const mut = useReuniaoMut(r.id)
  const [inicial, setInicial] = useState<number | null>(r.oracaoInicialMembroId ?? null)
  const [hino, setHino] = useState(r.hino ?? '')
  const [convidado, setConvidado] = useState(!!r.meditacaoConvidado)
  const [meditacao, setMeditacao] = useState<number | null>(r.meditacaoMembroId ?? null)
  const [nomeConvidado, setNomeConvidado] = useState(r.meditacaoConvidado ?? '')
  const [final, setFinal] = useState<number | null>(r.oracaoFinalMembroId ?? null)
  const [erro, setErro] = useState<string | null>(null)
  const submeter = async () => {
    setErro(null)
    try {
      await mut.alterarReuniao.mutateAsync({
        oracaoInicialMembroId: inicial, hino: hino.trim() || null,
        meditacaoMembroId: convidado ? null : meditacao, meditacaoConvidado: convidado ? nomeConvidado.trim() || null : null,
        oracaoFinalMembroId: final,
      } as never)
      toast.success('Abertura e encerramento guardados.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Abertura e encerramento</DialogTitle>
          <DialogDescription>Fica registado na acta da reunião.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5">
            <label htmlFor="dev-ini" className="text-sm font-medium">Primeira oração</label>
            <CampoMembro id="dev-ini" valor={inicial} aoMudar={setInicial} nomeDe={nomeDe} vazio="Quem orou…" />
          </div>
          <div className="grid gap-1.5">
            <label htmlFor="dev-hino" className="text-sm font-medium">Hino entoado</label>
            <div className="relative">
              <Music aria-hidden className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input id="dev-hino" value={hino} onChange={(e) => setHino(e.target.value)} maxLength={150} className="alvo pl-9" placeholder="ex.: Hino 123 — Castelo forte" />
            </div>
          </div>
          <div className="grid gap-1.5">
            <span className="text-sm font-medium">Meditação</span>
            <div role="radiogroup" aria-label="Quem fez a meditação" className="grid grid-cols-2 gap-2">
              {[{ v: false, r: 'Membro da igreja' }, { v: true, r: 'Convidado' }].map((o) => (
                <button key={o.r} type="button" role="radio" aria-checked={convidado === o.v} onClick={() => setConvidado(o.v)}
                  className={cn('alvo rounded-lg border px-3 py-2 text-sm font-medium', convidado === o.v ? 'border-primary bg-primary/10 text-primary' : 'text-muted-foreground')}>{o.r}</button>
              ))}
            </div>
            {convidado
              ? <Input aria-label="Nome do convidado" value={nomeConvidado} onChange={(e) => setNomeConvidado(e.target.value)} maxLength={150} className="alvo" placeholder="ex.: Pastor João Mabunda (pastor do distrito)" />
              : <CampoMembro id="dev-med" valor={meditacao} aoMudar={setMeditacao} nomeDe={nomeDe} vazio="Quem fez a meditação…" />}
          </div>
          <div className="grid gap-1.5">
            <label htmlFor="dev-fim" className="text-sm font-medium">Última oração</label>
            <CampoMembro id="dev-fim" valor={final} aoMudar={setFinal} nomeDe={nomeDe} vazio="Quem orou…" />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={mut.alterarReuniao.isPending} onClick={submeter}>{mut.alterarReuniao.isPending ? t.comum.aGravar : t.comum.guardar}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
