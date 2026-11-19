/**
 * Programação do dia (V44) · "O que acontece neste sábado, a que horas e quem faz?"
 * As programações por data; "Preparar" cria a de um dia a partir do modelo da igreja (Escola Sabatina, Transição,
 * Culto Divino, JA) ou copiando outro dia, e põe logo os nomes da escala desse dia. Depois ajusta-se e imprime-se.
 */
import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ClipboardList, Plus } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { Seleccao } from '@/components/comum/Seleccao'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { tituloDoDia, usePreparar, useProgramas, type Programa } from './api'

/** O próximo sábado (hoje, se for sábado). */
function proximoSabado() {
  const [a, m, d] = hojeIso().split('-').map(Number)
  const dt = new Date(Date.UTC(a, m - 1, d))
  dt.setUTCDate(dt.getUTCDate() + ((6 - dt.getUTCDay() + 7) % 7))
  return dt.toISOString().slice(0, 10)
}

export default function PaginaProgramacoes() {
  const { pode } = useSessao()
  const q = useProgramas()
  const navigate = useNavigate()
  const [preparar, setPreparar] = useState(false)
  const lista = (q.data ?? []).filter((p) => !p.endDate)
  const hoje = hojeIso()
  const proxima = [...lista].reverse().find((p) => p.data >= hoje)

  return (
    <>
      <TituloPagina icone={ClipboardList} titulo="Programação do dia" descricao="A folha de cada sábado, com as horas e os responsáveis"
        accoes={pode('actividades.programa_dia.criar') && <Button className="alvo" onClick={() => setPreparar(true)}><Plus className="size-4" />Preparar programação</Button>} />
      <section className="min-w-0 rounded-xl border bg-card shadow-card">
        {q.isPending ? <LinhasACarregar linhas={5} />
          : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="m-4" />
          : lista.length === 0 ? (
            <EstadoVazio icone={ClipboardList} titulo="Ainda não há programações"
              accao={pode('actividades.programa_dia.criar') && <Button variant="outline" className="alvo" onClick={() => setPreparar(true)}>Preparar a do próximo sábado</Button>}>
              Prepare a programação do sábado: vem do modelo da igreja, já com os nomes da escala, e ajusta-se antes de imprimir.
            </EstadoVazio>
          ) : (
            <Tabela>
              <thead><tr><th className="sm:pl-6">Dia</th><th className="hidden sm:table-cell">Título</th><th className="sm:pr-6"><span className="sr-only">Estado</span></th></tr></thead>
              <tbody>
                {lista.map((p) => (
                  <tr key={p.id} onClick={() => navigate(`/programacao/${p.id}`)} className={cn('cursor-pointer', p.data < hoje && 'text-muted-foreground')}>
                    <td className="sm:pl-6"><Link to={`/programacao/${p.id}`} onClick={(e) => e.stopPropagation()} className="font-medium text-foreground hover:text-primary">{tituloDoDia(p.data)}</Link></td>
                    <td className="hidden sm:table-cell">{p.titulo ?? '—'}</td>
                    <td className="text-right sm:pr-6">{p.id === proxima?.id && <Pilula variante="info">Próxima</Pilula>}</td>
                  </tr>
                ))}
              </tbody>
            </Tabela>
          )}
      </section>
      {preparar && <DialogoPreparar lista={lista} aoFechar={() => setPreparar(false)} />}
    </>
  )
}

function DialogoPreparar({ lista, aoFechar }: { lista: Programa[]; aoFechar: () => void }) {
  const navigate = useNavigate()
  const preparar = usePreparar()
  const [dia, setDia] = useState(proximoSabado())
  const [origem, setOrigem] = useState(lista[0] ? String(lista[0].id) : '')
  const [modo, setModo] = useState<'modelo' | 'copiar'>(lista.length ? 'copiar' : 'modelo')
  const [erro, setErro] = useState<string | null>(null)
  const submeter = async () => {
    setErro(null)
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dia)) return setErro('Escreva a data como dd/mm/aaaa.')
    if (lista.some((p) => p.data === dia)) return setErro('Já há uma programação para este dia: abra-a na lista.')
    try {
      const p = await preparar.mutateAsync({ data: dia, origemId: modo === 'copiar' && origem ? Number(origem) : undefined })
      toast.success('Programação preparada, já com os nomes da escala. Ajuste o que for preciso e imprima.')
      navigate(`/programacao/${p.id}`)
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Preparar programação</DialogTitle>
          <DialogDescription>Os nomes da escala desse dia entram sozinhos.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="campo-flutuante grid gap-1.5">
            <label htmlFor="pp-dia" className="text-sm font-medium">Dia</label>
            <CampoData id="pp-dia" value={dia} onChange={setDia} className="alvo" />
          </div>
          <div role="radiogroup" aria-label="A partir de" className="grid gap-2">
            {([{ v: 'modelo', r: 'Do modelo da igreja', d: 'Escola Sabatina, Transição, Culto Divino e JA, com as horas habituais' },
              { v: 'copiar', r: 'Copiar de outro dia', d: 'As mesmas partes, horas e responsáveis; a escala actualiza os nomes' }] as const).map((o) => (
              <button key={o.v} type="button" role="radio" aria-checked={modo === o.v} disabled={o.v === 'copiar' && !lista.length} onClick={() => setModo(o.v)}
                className={cn('alvo rounded-lg border px-3 py-2.5 text-left disabled:opacity-50', modo === o.v ? 'border-primary bg-primary/5' : 'hover:bg-muted/50')}>
                <span className="block text-sm font-medium">{o.r}</span><span className="block text-xs text-muted-foreground">{o.d}</span>
              </button>
            ))}
          </div>
          {modo === 'copiar' && lista.length > 0 && (
            <Seleccao aria-label="Programação a copiar" value={origem} onChange={(e) => setOrigem(e.target.value)}>
              {lista.map((p) => <option key={p.id} value={p.id}>{tituloDoDia(p.data)}</option>)}
            </Seleccao>
          )}
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={preparar.isPending} onClick={submeter}>{preparar.isPending ? t.comum.aGravar : 'Preparar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
