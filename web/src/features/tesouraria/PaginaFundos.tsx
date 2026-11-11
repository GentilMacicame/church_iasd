/**
 * Fundos e ofertas (F-TES-01): para onde vai cada oferta.
 * - Fundos da Missão: definidos pela Associação/Missão para todas as igrejas (dízimo, ofertas, Escola Sabatina). Aqui
 *   só se lêem: a igreja não os muda (V23).
 * - Ofertas da igreja: as que a própria igreja recolhe (construção do templo, gratidão, Dorcas, ...). Ficam 100% na
 *   igreja; um "projecto" só se gasta no seu fim. Aparecem em "Lançar entrada" (outros fundos) e nas despesas.
 * As regras (só nesta igreja, sem parte para a Missão, quem pode criar) são da base de dados.
 */
import { useState } from 'react'
import { Church, Landmark, Plus, Target, Wallet, X } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Dinheiro, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { cn } from '@/lib/utils'
import { daPropriaIgreja, useFundos, useFundosMut, useSaldosFundos, type Fundo } from './api'
import { parteDoFundo } from './comum'
import { CartaoAlvos } from './Alvos'

export default function PaginaFundos() {
  const { pode } = useSessao()
  const fundos = useFundos()
  const saldos = useSaldosFundos()
  const { terminar } = useFundosMut()
  const [nova, setNova] = useState(false)
  const [aTerminar, setATerminar] = useState<Fundo | null>(null)
  const saldoDe = new Map((saldos.data ?? []).map((s) => [s.fundoId, s]))
  const lista = (fundos.data ?? []).filter((f) => !f.endDate)
  const daMissao = lista.filter((f) => !daPropriaIgreja(f))
  const daIgreja = lista.filter(daPropriaIgreja)
  const podeCriar = pode('tesouraria.fundo.criar')

  const saldo = (f: Fundo) => {
    const s = saldoDe.get(f.id)
    return s ? <Dinheiro valor={s.disponivel ?? s.saldo} /> : <span className="text-muted-foreground">—</span>
  }

  return (
    <>
      <TituloPagina icone={Wallet} titulo="Fundos e ofertas" descricao="Para onde vai cada dízimo e cada oferta, e as ofertas próprias da igreja"
        accoes={podeCriar && <Button className="alvo" onClick={() => setNova(true)}><Plus className="size-4" />Nova oferta da igreja</Button>} />
      {fundos.isError ? <EstadoErro erro={fundos.error} aoTentar={() => fundos.refetch()} /> : (
        <div className="grid items-start gap-6 lg:grid-cols-2">
          <Cartao titulo="Ofertas da igreja" descricao="Recolhidas pela igreja para os seus fins: ficam 100% na igreja" icone={Church} semMargem>
            {fundos.isPending ? <LinhasACarregar linhas={3} />
              : !daIgreja.length ? (
                <EstadoVazio icone={Target} titulo="Ainda não há ofertas próprias"
                  accao={podeCriar && <Button variant="outline" className="alvo" onClick={() => setNova(true)}><Plus className="size-4" />Nova oferta da igreja</Button>}>
                  Por exemplo: construção do templo, oferta de gratidão, Dorcas, fundo de assistência.
                </EstadoVazio>
              ) : (
                <Tabela>
                  <thead><tr><th className="sm:pl-6">Oferta</th><th className="num">Disponível</th><th className="sm:pr-6"><span className="sr-only">Acções</span></th></tr></thead>
                  <tbody>
                    {daIgreja.map((f) => (
                      <tr key={f.id}>
                        <td className="sm:pl-6">
                          <p className="font-medium">{f.nome}</p>
                          <p className="flex flex-wrap items-center gap-1.5 text-xs text-muted-foreground">
                            <Pilula variante={f.tipo === 'PROJECTO' ? 'info' : 'secondary'}>{f.tipo === 'PROJECTO' ? 'Projecto' : 'Oferta especial'}</Pilula>
                            {f.restrito && 'só se gasta neste fim'}
                          </p>
                        </td>
                        <td className="num font-medium">{saldo(f)}</td>
                        <td className="text-right sm:pr-6">
                          {pode('tesouraria.fundo.terminar') && (
                            <Button size="sm" variant="ghost" className="alvo text-muted-foreground" onClick={() => setATerminar(f)} aria-label={`Terminar ${f.nome}`}>
                              <X className="size-4" />Terminar
                            </Button>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </Tabela>
              )}
          </Cartao>
          <Cartao titulo="Fundos da Missão" descricao="Definidos pela Associação/Missão para todas as igrejas" icone={Landmark} semMargem>
            {fundos.isPending ? <LinhasACarregar linhas={5} /> : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Fundo</th><th>Divisão</th><th className="num sm:pr-6">Da igreja</th></tr></thead>
                <tbody>
                  {daMissao.map((f) => {
                    const p = Number(f.percentagemRemessa ?? 0)
                    return (
                      <tr key={f.id}>
                        <td className="font-medium sm:pl-6">{f.nome}</td>
                        <td><span className={cn('text-xs', p >= 100 ? 'text-info-text' : 'text-muted-foreground')}>{parteDoFundo(f)}</span></td>
                        <td className="num sm:pr-6">{p >= 100 ? <span className="text-muted-foreground">—</span> : saldo(f)}</td>
                      </tr>
                    )
                  })}
                </tbody>
              </Tabela>
            )}
            <p className="border-t px-4 py-3 text-xs text-muted-foreground sm:px-6">Só a Associação/Missão muda estes fundos. A parte da Missão vai no depósito à Missão do fim do mês.</p>
          </Cartao>
          {pode('tesouraria.alvo.ler') && <div className="lg:col-span-2"><CartaoAlvos /></div>}
        </div>
      )}
      {nova && <DialogoOferta aoFechar={() => setNova(false)} />}
      <DialogoConfirmar aberto={!!aTerminar} aoMudar={(v) => !v && setATerminar(null)} perigo
        titulo={`Terminar "${aTerminar?.nome}"?`} accao="Terminar"
        texto="Deixa de aparecer ao lançar entradas e despesas. O que já foi lançado fica no histórico."
        aCorrer={terminar.isPending}
        aoConfirmar={() => aTerminar && terminar.mutate(aTerminar.id, {
          onSuccess: () => { toast.success('Oferta terminada.'); setATerminar(null) },
          onError: (e) => toast.error(mensagemDe(e)),
        })} />
    </>
  )
}

function DialogoOferta({ aoFechar }: { aoFechar: () => void }) {
  const { criar } = useFundosMut()
  const [nome, setNome] = useState('')
  const [tipo, setTipo] = useState<'OFERTA_ESPECIAL' | 'PROJECTO'>('OFERTA_ESPECIAL')
  const [erro, setErro] = useState<string | null>(null)
  const submeter = async () => {
    setErro(null)
    if (nome.trim().length < 3) return setErro('Escreva o nome da oferta (por exemplo, Construção do templo).')
    try {
      await criar.mutateAsync({ nome: nome.trim(), tipo, restrito: tipo === 'PROJECTO' })
      toast.success('Oferta criada. Já aparece em "Lançar entrada", em Outros fundos.')
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Nova oferta da igreja</DialogTitle>
          <DialogDescription>Uma oferta que a igreja recolhe para si. Fica 100% na igreja (não vai à Missão).</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5">
            <label htmlFor="ofe-nome" className="text-sm font-medium">Nome</label>
            <Input id="ofe-nome" value={nome} onChange={(e) => setNome(e.target.value)} maxLength={100} placeholder="ex.: Construção do templo" className="alvo" autoFocus />
          </div>
          <div role="radiogroup" aria-label="Tipo de oferta" className="grid gap-2">
            {[{ v: 'OFERTA_ESPECIAL' as const, r: 'Oferta especial', d: 'Gratidão, Dorcas, assistência: gasta-se nas despesas da igreja' },
              { v: 'PROJECTO' as const, r: 'Projecto', d: 'Construção, viatura, instrumentos: só se gasta nesse fim' }].map((o) => (
              <button key={o.v} type="button" role="radio" aria-checked={tipo === o.v} onClick={() => setTipo(o.v)}
                className={cn('alvo rounded-lg border px-3 py-2.5 text-left', tipo === o.v ? 'border-primary bg-primary/5' : 'hover:bg-muted/50')}>
                <span className="block text-sm font-medium">{o.r}</span>
                <span className="block text-xs text-muted-foreground">{o.d}</span>
              </button>
            ))}
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={criar.isPending} onClick={submeter}>{criar.isPending ? t.comum.aGravar : 'Criar oferta'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
