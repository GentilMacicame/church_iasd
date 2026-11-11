/**
 * Comprovativos (P-06): a fotografia do talão ou o print do M-Pesa que o membro manda ao tesoureiro, ou um PDF.
 * - CampoComprovativo: escolher (ou fotografar, no telemóvel) antes de gravar; mostra a pré-visualização.
 * - CartaoComprovativos: na ficha do movimento, os que já estão juntos (abrir) e juntar mais.
 * Quem pode juntar e ver decide-o a base de dados (tesouraria.documento.criar / ler).
 */
import { useEffect, useRef, useState } from 'react'
import { Camera, FileText, Paperclip, X } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Cartao } from '@/components/comum/elementos'
import { Barra } from '@/components/comum/estados'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { data } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { ACEITA_COMPROVATIVO, abrirDocumento, useCarregarComprovativo, useDocumentos } from './api'

const tamanho = (b: number) => (b < 1024 * 1024 ? `${Math.max(1, Math.round(b / 1024))} KB` : `${(b / 1024 / 1024).toFixed(1).replace('.', ',')} MB`)

/** Dois botões: fotografar (abre a câmara no telemóvel) e escolher um ficheiro (fotografia ou PDF). */
function Escolher({ aoEscolher, desactivado, compacto }: { aoEscolher: (f: File) => void; desactivado?: boolean; compacto?: boolean }) {
  const camara = useRef<HTMLInputElement>(null)
  const ficheiro = useRef<HTMLInputElement>(null)
  const escolhido = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]
    e.target.value = ''
    if (f) aoEscolher(f)
  }
  return (
    <div className="flex flex-wrap gap-2">
      <input ref={camara} type="file" accept="image/*" capture="environment" className="sr-only" tabIndex={-1} aria-hidden onChange={escolhido} />
      <input ref={ficheiro} type="file" accept={ACEITA_COMPROVATIVO} className="sr-only" tabIndex={-1} aria-hidden onChange={escolhido} data-testid="ficheiro-comprovativo" />
      <Button type="button" variant="outline" className="alvo sm:hidden" disabled={desactivado} onClick={() => camara.current?.click()}>
        <Camera className="size-4" />Fotografar
      </Button>
      <Button type="button" variant="outline" className="alvo" disabled={desactivado} onClick={() => ficheiro.current?.click()}>
        <Paperclip className="size-4" />{compacto ? 'Juntar comprovativo' : 'Escolher fotografia ou PDF'}
      </Button>
    </div>
  )
}

/** Antes de gravar: o ficheiro escolhido, com pré-visualização. Envia-se depois de a entrada ficar gravada. */
export function CampoComprovativo({ ficheiro, aoMudar }: { ficheiro: File | null; aoMudar: (f: File | null) => void }) {
  const [previa, setPrevia] = useState<string | null>(null)
  useEffect(() => {
    if (!ficheiro || !ficheiro.type.startsWith('image/')) { setPrevia(null); return }
    const url = URL.createObjectURL(ficheiro)
    setPrevia(url)
    return () => URL.revokeObjectURL(url)
  }, [ficheiro])

  return (
    <div className="grid gap-1.5">
      <p className="text-sm font-medium">Fotografia ou PDF do comprovativo</p>
      {ficheiro ? (
        <div className="flex items-center gap-3 rounded-lg border bg-muted/30 p-2.5">
          {previa
            ? <img src={previa} alt="Pré-visualização do comprovativo" className="size-14 flex-none rounded-md border object-cover" />
            : <span className="flex size-14 flex-none items-center justify-center rounded-md border bg-card"><FileText className="size-6 text-muted-foreground" /></span>}
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-medium">{ficheiro.name}</p>
            <p className="text-xs text-muted-foreground">{tamanho(ficheiro.size)} · é enviado ao gravar a entrada</p>
          </div>
          <Button type="button" variant="ghost" size="icon" className="alvo flex-none" aria-label="Retirar o ficheiro" onClick={() => aoMudar(null)}><X className="size-4" /></Button>
        </div>
      ) : (
        <div className="rounded-lg border border-dashed p-3">
          <Escolher aoEscolher={aoMudar} />
          <p className="mt-2 text-xs text-muted-foreground">A fotografia do talão ou o print da mensagem M-Pesa que o membro mandou. Opcional, mas ajuda na conferência.</p>
        </div>
      )}
    </div>
  )
}

/** Na ficha do movimento: os comprovativos juntos e o botão para juntar mais. */
export function CartaoComprovativos({ transacaoId, className }: { transacaoId: number; className?: string }) {
  const { pode } = useSessao()
  const docs = useDocumentos(transacaoId)
  const carregar = useCarregarComprovativo(transacaoId)
  if (!pode('tesouraria.documento.ler')) return null
  const lista = (docs.data ?? []).filter((d) => !d.endDate)
  const juntar = async (f: File) => {
    try {
      await carregar.mutateAsync(f)
      toast.success('Comprovativo junto ao movimento.')
    } catch (e) {
      toast.error('O comprovativo não foi carregado', { description: mensagemDe(e) })
    }
  }
  const abrir = async (id: number) => {
    try { await abrirDocumento(id) } catch (e) { toast.error('Não foi possível abrir o ficheiro', { description: mensagemDe(e) }) }
  }
  return (
    <Cartao titulo="Comprovativos" icone={Paperclip} className={className}>
      {docs.isPending ? <Barra className="h-10 w-full" />
        : !lista.length ? <p className="text-sm text-muted-foreground">{carregar.isPending ? 'A carregar…' : 'Nenhum comprovativo junto.'}</p>
        : (
          <ul className="grid gap-2">
            {lista.map((d) => {
              const temFicheiro = (d.url ?? '').startsWith('armazem:')
              return (
                <li key={d.id}>
                  <button type="button" disabled={!temFicheiro} onClick={() => abrir(d.id)}
                    className={cn('alvo flex w-full items-center gap-3 rounded-lg border px-3 py-2 text-left', temFicheiro && 'hover:bg-muted/50')}>
                    <FileText className="size-5 flex-none text-muted-foreground" />
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-sm font-medium">{d.nomeFicheiro}</span>
                      <span className="block text-xs text-muted-foreground">{d.criadoEm ? `juntado a ${data(d.criadoEm)}` : ''}{temFicheiro ? ' · abrir' : ' · sem ficheiro'}</span>
                    </span>
                  </button>
                </li>
              )
            })}
            {carregar.isPending && <li className="text-sm text-muted-foreground">A carregar…</li>}
          </ul>
        )}
      {pode('tesouraria.documento.criar') && <div className="mt-3"><Escolher aoEscolher={juntar} desactivado={carregar.isPending} compacto /></div>}
    </Cartao>
  )
}
