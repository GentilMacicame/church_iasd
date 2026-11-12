/**
 * Transferências com carta (F-SEC-06, P-02):
 *   1. a igreja de origem regista o pedido (para outra igreja do sistema ou de fora);
 *   2. vota a carta em 2.ª leitura (reunião regular ou assembleia) e emite-a — válida 6 meses;
 *   3. a igreja de destino vota a aceitação (também em 2.ª leitura) e conclui: o membro sai do livro da origem e
 *      entra no do destino. Para uma igreja fora do sistema, a origem regista a resposta.
 * Carta só a membro activo e sem censura; as duas igrejas vêem a transferência (V27). A base de dados decide.
 */
import { useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { ArrowDownLeft, ArrowRightLeft, ArrowUpRight, Ban, FileSignature, Plus, Printer, UserCheck } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { CampoEscolha } from '@/components/comum/CampoEscolha'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { CabecalhoDocumento } from '@/components/layout/Marca'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { data, dataCompleta, diasAte, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { imprimirComo } from '@/lib/documentos'
import { useMembrosBasicos } from '@/features/membros/api'
import { CampoVoto } from '@/features/livro/CampoVoto'
import { useDirectorioIgrejas, useTransferencias, useTransferenciasMut, type TransferenciaResumo } from './api'

const ESTADO: Record<string, { r: string; v: 'warning' | 'info' | 'success' | 'destructive' | 'secondary' }> = {
  PEDIDA: { r: 'Pedida', v: 'warning' }, CARTA_EMITIDA: { r: 'Carta emitida', v: 'info' }, CONCLUIDA: { r: 'Concluída', v: 'success' },
  RECUSADA: { r: 'Recusada', v: 'destructive' }, EXPIRADA: { r: 'Expirada', v: 'secondary' },
}
type Accao = { tipo: 'carta' | 'aceitar' | 'externa' | 'recusar' | 'anular' | 'imprimir'; t: TransferenciaResumo }

export default function PaginaTransferencias() {
  const igreja = useIgreja()
  const { pode } = useSessao()
  const q = useTransferencias()
  // ?aba=entradas (vindo de um alerta: membro a aceitar de outra igreja)
  const [params] = useSearchParams()
  const [aba, setAba] = useState<'saidas' | 'entradas'>(params.get('aba') === 'entradas' ? 'entradas' : 'saidas')
  const [novo, setNovo] = useState(false)
  const [accao, setAccao] = useState<Accao | null>(null)
  const { anular } = useTransferenciasMut()
  const lista = q.data ?? []
  const saidas = lista.filter((x) => x.origemIgrejaId === igreja.id)
  const entradas = lista.filter((x) => x.destinoIgrejaId === igreja.id)
  const visiveis = aba === 'saidas' ? saidas : entradas
  const pendentes = (l: TransferenciaResumo[]) => l.filter((x) => x.estado === 'PEDIDA' || x.estado === 'CARTA_EMITIDA').length

  const botoes = (x: TransferenciaResumo) => {
    const daqui = x.origemIgrejaId === igreja.id
    const b: { r: string; a: Accao['tipo']; icone: typeof Plus; principal?: boolean }[] = []
    if (daqui && x.estado === 'PEDIDA' && pode('secretaria.transferencia_membro.emitir_carta')) b.push({ r: 'Emitir carta', a: 'carta', icone: FileSignature, principal: true })
    if (daqui && x.estado === 'CARTA_EMITIDA') b.push({ r: 'Imprimir carta', a: 'imprimir', icone: Printer })
    if (daqui && x.estado === 'CARTA_EMITIDA' && !x.destinoIgrejaId && pode('secretaria.transferencia_membro.aceitar')) b.push({ r: 'Registar aceitação', a: 'externa', icone: UserCheck, principal: true })
    if (!daqui && x.estado === 'CARTA_EMITIDA' && pode('secretaria.transferencia_membro.aceitar')) b.push({ r: 'Aceitar o membro', a: 'aceitar', icone: UserCheck, principal: !x.expirada })
    if ((x.estado === 'PEDIDA' || x.estado === 'CARTA_EMITIDA') && pode('secretaria.transferencia_membro.alterar')) b.push({ r: 'Recusar', a: 'recusar', icone: Ban })
    if (daqui && x.estado === 'PEDIDA' && pode('secretaria.transferencia_membro.terminar')) b.push({ r: 'Anular', a: 'anular', icone: Ban })
    return b
  }

  return (
    <>
      <TituloPagina icone={ArrowRightLeft} titulo="Transferências" descricao="Cartas de transferência de membros entre igrejas (válidas 6 meses)"
        accoes={pode('secretaria.transferencia_membro.criar') && <Button className="alvo" onClick={() => setNovo(true)}><Plus className="size-4" />Pedido de transferência</Button>} />
      {q.isPending ? <Barra className="h-64 w-full" /> : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} /> : (
        <div className="grid gap-6">
          <div className="grid gap-3 sm:grid-cols-3">
            <Indicador rotulo="A sair (por concluir)" valor={String(pendentes(saidas))} icone={ArrowUpRight} tom="warning" activo={aba === 'saidas'} aoClicar={() => setAba('saidas')} />
            <Indicador rotulo="A chegar (por aceitar)" valor={String(pendentes(entradas))} icone={ArrowDownLeft} tom="info" activo={aba === 'entradas'} aoClicar={() => setAba('entradas')} />
            <Indicador rotulo="Cartas a expirar (30 dias)" valor={String(lista.filter((x) => x.estado === 'CARTA_EMITIDA' && x.validaAte && diasAte(x.validaAte) <= 30).length)} icone={FileSignature} tom="destructive" />
          </div>
          <div role="tablist" aria-label="Sentido" className="flex gap-2">
            {([['saidas', `A sair desta igreja (${saidas.length})`], ['entradas', `A chegar a esta igreja (${entradas.length})`]] as const).map(([v, r]) => (
              <button key={v} role="tab" aria-selected={aba === v} onClick={() => setAba(v)}
                className={cn('alvo rounded-full border px-4 text-sm font-medium', aba === v ? 'border-primary bg-primary text-primary-foreground' : 'bg-card text-muted-foreground hover:text-foreground')}>{r}</button>
            ))}
          </div>
          <Cartao semMargem>
            {!visiveis.length ? (
              <EstadoVazio icone={ArrowRightLeft} titulo={aba === 'saidas' ? 'Nenhum membro a sair' : 'Nenhum membro a chegar'}>
                {aba === 'saidas' ? 'Quando um membro pede a carta para outra igreja, registe aqui o pedido.' : 'Aparecem aqui as cartas que outras igrejas emitiram para esta igreja.'}
              </EstadoVazio>
            ) : (
              <Tabela>
                <thead>
                  <tr><th className="sm:pl-6">Membro</th><th>{aba === 'saidas' ? 'Para' : 'De'}</th><th className="hidden md:table-cell">Datas</th><th>Estado</th><th className="sm:pr-6"><span className="sr-only">Acções</span></th></tr>
                </thead>
                <tbody>
                  {visiveis.map((x) => {
                    const est = ESTADO[x.estado] ?? ESTADO.PEDIDA
                    const dias = x.validaAte ? diasAte(x.validaAte) : null
                    return (
                      <tr key={x.id}>
                        <td className="sm:pl-6">
                          {aba === 'saidas' ? <Link to={`/membros/${x.membroId}`} className="font-medium hover:underline">{x.membro}</Link> : <span className="font-medium">{x.membro}</span>}
                          {x.observacoes && <p className="max-w-64 truncate text-xs text-muted-foreground" title={x.observacoes}>{x.observacoes}</p>}
                        </td>
                        <td>
                          <p>{aba === 'saidas' ? x.destino ?? '—' : x.origem}</p>
                          {aba === 'saidas' && !x.destinoIgrejaId && <p className="text-xs text-muted-foreground">fora do sistema</p>}
                        </td>
                        <td className="hidden text-xs text-muted-foreground md:table-cell">
                          {x.dataPedido && <p>Pedido {data(x.dataPedido)}</p>}
                          {x.cartaEmitidaEm && <p>Carta {data(x.cartaEmitidaEm)}</p>}
                          {x.aceiteEm && <p>Aceite {data(x.aceiteEm)}</p>}
                        </td>
                        <td>
                          <Pilula variante={x.estado === 'CARTA_EMITIDA' && x.expirada ? 'destructive' : est.v}>{x.estado === 'CARTA_EMITIDA' && x.expirada ? 'Carta expirada' : est.r}</Pilula>
                          {x.estado === 'CARTA_EMITIDA' && dias != null && !x.expirada && <p className={cn('mt-1 text-xs', dias <= 30 ? 'text-warning-text' : 'text-muted-foreground')}>válida até {data(x.validaAte)}</p>}
                        </td>
                        <td className="sm:pr-6">
                          <div className="flex flex-wrap justify-end gap-1.5">
                            {botoes(x).map((b) => (
                              <Button key={b.a} size="sm" variant={b.principal ? 'default' : b.a === 'recusar' || b.a === 'anular' ? 'ghost' : 'outline'} className="alvo" onClick={() => setAccao({ tipo: b.a, t: x })}>
                                <b.icone className="size-4" />{b.r}
                              </Button>
                            ))}
                          </div>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </Tabela>
            )}
          </Cartao>
        </div>
      )}
      {novo && <DialogoPedido aoFechar={() => setNovo(false)} />}
      {accao && (accao.tipo === 'carta' || accao.tipo === 'aceitar' || accao.tipo === 'externa') && <DialogoVoto accao={accao} aoFechar={() => setAccao(null)} />}
      {accao?.tipo === 'recusar' && <DialogoRecusar t={accao.t} aoFechar={() => setAccao(null)} />}
      {accao?.tipo === 'imprimir' && <DialogoCarta t={accao.t} aoFechar={() => setAccao(null)} />}
      <DialogoConfirmar aberto={accao?.tipo === 'anular'} aoMudar={(v) => !v && setAccao(null)} titulo="Anular o pedido?" accao="Anular" perigo
        texto={`O pedido de transferência de ${accao?.t.membro} deixa de aparecer. O membro continua nesta igreja.`} aCorrer={anular.isPending}
        aoConfirmar={() => accao && anular.mutate(accao.t.id, { onSuccess: () => { setAccao(null); toast.success('Pedido anulado.') }, onError: (e) => toast.error(mensagemDe(e)) })} />
    </>
  )
}

function DialogoPedido({ aoFechar }: { aoFechar: () => void }) {
  const igreja = useIgreja()
  const membros = useMembrosBasicos()
  const dir = useDirectorioIgrejas()
  const { pedir } = useTransferenciasMut()
  const [membro, setMembro] = useState<number | null>(null)
  const [fora, setFora] = useState(false)
  const [destino, setDestino] = useState('')
  const [externo, setExterno] = useState('')
  const [dia, setDia] = useState(hojeIso())
  const [obs, setObs] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const nomeDe = (id: number) => { const m = membros.data?.find((x) => x.id === id); return m ? `${m.nome} ${m.apelido}` : undefined }
  const submeter = () => {
    setErro(null)
    if (!membro) return setErro('Escolha o membro.')
    if (!fora && !destino) return setErro('Escolha a igreja de destino.')
    if (fora && !externo.trim()) return setErro('Escreva o nome e o local da igreja de destino.')
    pedir.mutate({ membroId: membro, origemIgrejaId: igreja.id, destinoIgrejaId: fora ? undefined : Number(destino), destinoExterno: fora ? externo.trim() : undefined, dataPedido: dia, observacoes: obs.trim() || undefined }, {
      onSuccess: () => { toast.success('Pedido registado. O passo seguinte é votar a carta (2.ª leitura).'); aoFechar() }, onError: (e) => setErro(mensagemDe(e)),
    })
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Pedido de transferência</DialogTitle>
          <DialogDescription>O membro (ou a igreja de destino) pede a carta. A carta só se emite depois do voto da igreja em 2.ª leitura.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5">
            <label htmlFor="tr-membro" className="text-sm font-medium">Membro <span className="text-destructive-text">*</span></label>
            <CampoMembro id="tr-membro" valor={membro} aoMudar={setMembro} nomeDe={nomeDe} />
          </div>
          <div role="radiogroup" aria-label="Para onde vai" className="grid grid-cols-2 gap-2">
            {[{ v: false, r: 'Igreja do sistema' }, { v: true, r: 'Igreja de fora' }].map((o) => (
              <button key={o.r} type="button" role="radio" aria-checked={fora === o.v} onClick={() => setFora(o.v)}
                className={cn('alvo rounded-lg border px-3 py-2 text-sm font-medium', fora === o.v ? 'border-primary bg-primary/10 text-primary' : 'text-muted-foreground')}>{o.r}</button>
            ))}
          </div>
          {fora ? (
            <div className="grid gap-1.5">
              <label htmlFor="tr-ext" className="text-sm font-medium">Igreja de destino <span className="text-destructive-text">*</span></label>
              <Input id="tr-ext" value={externo} onChange={(e) => setExterno(e.target.value)} className="alvo" maxLength={150} placeholder="ex.: IASD de Lichinga, Missão do Norte" />
            </div>
          ) : (
            <div className="grid gap-1.5">
              <label htmlFor="tr-dest" className="text-sm font-medium">Igreja de destino <span className="text-destructive-text">*</span></label>
              {dir.isPending ? <Barra className="h-9 w-full" /> : (
                <CampoEscolha id="tr-dest" valor={destino} aoMudar={setDestino} vazio="Escolher a igreja…" pesquisar="Pesquisar pelo nome ou local…"
                  opcoes={(dir.data ?? []).filter((i) => i.id !== igreja.id).map((i) => ({ valor: String(i.id), rotulo: i.nome, detalhe: [i.localidade, i.distrito, i.provincia, i.entidade].filter(Boolean).join(' · ') }))} />
              )}
            </div>
          )}
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="grid gap-1.5">
              <label htmlFor="tr-data" className="text-sm font-medium">Data do pedido</label>
              <CampoData id="tr-data" value={dia} onChange={setDia} className="alvo" />
            </div>
          </div>
          <div className="grid gap-1.5">
            <label htmlFor="tr-obs" className="text-sm font-medium">Observações</label>
            <Input id="tr-obs" value={obs} onChange={(e) => setObs(e.target.value)} className="alvo" maxLength={500} placeholder="ex.: mudou-se para Lichinga por trabalho" />
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={pedir.isPending} onClick={submeter}>{pedir.isPending ? t.comum.aGravar : 'Registar pedido'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/** Emitir a carta (origem), aceitar o membro (destino) ou registar a aceitação de uma igreja de fora (origem). */
function DialogoVoto({ accao, aoFechar }: { accao: Accao; aoFechar: () => void }) {
  const { emitirCarta, concluir } = useTransferenciasMut()
  const x = accao.t
  const [voto, setVoto] = useState('')
  const [dia, setDia] = useState(hojeIso())
  const [erro, setErro] = useState<string | null>(null)
  const m = accao.tipo === 'carta' ? emitirCarta : concluir
  const submeter = () => {
    setErro(null)
    // a aceitação por uma igreja de fora não tem voto nosso: regista-se com o voto que concedeu a carta
    const votoId = accao.tipo === 'externa' ? x.origemVotoId : Number(voto)
    if (!votoId) return setErro('Escolha o voto.')
    m.mutate({ id: x.id, votoId, data: dia }, {
      onSuccess: () => {
        toast.success(accao.tipo === 'carta' ? 'Carta emitida. É válida 6 meses.' : `${x.membro} foi transferido(a). O livro de membros das duas igrejas foi actualizado.`)
        aoFechar()
      },
      onError: (e) => setErro(mensagemDe(e)),
    })
  }
  const titulo = accao.tipo === 'carta' ? 'Emitir carta de transferência' : accao.tipo === 'aceitar' ? 'Aceitar o membro' : 'Registar a aceitação'
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{titulo}</DialogTitle>
          <DialogDescription>
            {accao.tipo === 'carta' && <>Carta de <b>{x.membro}</b> para {x.destino}. Exige o voto da igreja em 2.ª leitura (reunião regular ou assembleia administrativa).</>}
            {accao.tipo === 'aceitar' && <><b>{x.membro}</b>, vindo(a) de {x.origem}. A igreja vota a aceitação em 2.ª leitura; ao concluir, o membro passa para o livro desta igreja.</>}
            {accao.tipo === 'externa' && <>{x.destino} aceitou <b>{x.membro}</b>? Indique a data da resposta: o membro sai do livro desta igreja.</>}
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          {accao.tipo !== 'externa' && (
            <div className="grid gap-1.5">
              <label htmlFor="tr-voto" className="text-sm font-medium">Voto (2.ª leitura)</label>
              <CampoVoto id="tr-voto" valor={voto} aoMudar={setVoto} reunioes={['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA']} segundaLeitura preferir="TRANSFERENCIA" />
            </div>
          )}
          <div className="grid gap-1.5 sm:w-1/2">
            <label htmlFor="tr-dia" className="text-sm font-medium">{accao.tipo === 'carta' ? 'Data da carta' : 'Data da aceitação'}</label>
            <CampoData id="tr-dia" value={dia} onChange={setDia} className="alvo" />
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={m.isPending} onClick={submeter}>{m.isPending ? t.comum.aGravar : accao.tipo === 'carta' ? 'Emitir carta' : 'Concluir transferência'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function DialogoRecusar({ t: x, aoFechar }: { t: TransferenciaResumo; aoFechar: () => void }) {
  const { recusar } = useTransferenciasMut()
  const [motivo, setMotivo] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const submeter = () => {
    setErro(null)
    if (!motivo.trim()) return setErro('Escreva o motivo.')
    recusar.mutate({ id: x.id, motivo: motivo.trim() }, { onSuccess: () => { toast.success('Transferência recusada.'); aoFechar() }, onError: (e) => setErro(mensagemDe(e)) })
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Recusar a transferência</DialogTitle>
          <DialogDescription>{x.membro}: o membro continua em {x.origem}.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-2">
          <ErroFormulario mensagem={erro} />
          <label htmlFor="tr-motivo" className="text-sm font-medium">Motivo</label>
          <Input id="tr-motivo" value={motivo} onChange={(e) => setMotivo(e.target.value)} className="alvo" maxLength={500} autoFocus />
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" variant="destructive" className="alvo" disabled={recusar.isPending} onClick={submeter}>{recusar.isPending ? t.comum.aGravar : 'Recusar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/** A carta de transferência pronta a imprimir (com o logotipo, assinaturas do secretário e do pastor). */
function DialogoCarta({ t: x, aoFechar }: { t: TransferenciaResumo; aoFechar: () => void }) {
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-2xl print:fixed print:inset-0 print:max-h-none print:max-w-none print:translate-x-0 print:translate-y-0 print:overflow-visible print:border-0 print:p-0 print:shadow-none">
        <DialogHeader className="print:hidden">
          <DialogTitle>Carta de transferência</DialogTitle>
          <DialogDescription>Imprima, assine e envie à igreja de destino.</DialogDescription>
        </DialogHeader>
        <article id="carta-transferencia" className="imprimir-so-isto documento-a4 grid gap-5 rounded-lg border bg-white p-6 text-[11pt] leading-relaxed text-black print:border-0 print:p-0">
          <CabecalhoDocumento titulo={x.origem} linha="Secretaria" />
          <h2 className="text-center text-base font-bold tracking-wide uppercase">Carta de transferência de membro</h2>
          <p>À {x.destino},</p>
          <p>
            Certificamos que <b>{x.membro}</b> é membro regular desta igreja e, a seu pedido, foi votada a sua transferência para essa igreja
            {x.cartaEmitidaEm ? <> em {dataCompleta(x.cartaEmitidaEm)}</> : null}. Recomendamo-lo(a) à vossa comunhão cristã.
          </p>
          <p>Pedimos que nos informem da aceitação, para o retirarmos do nosso livro de membros. Esta carta é válida até <b>{x.validaAte ? dataCompleta(x.validaAte) : '—'}</b>.</p>
          <div className="mt-10 grid grid-cols-2 gap-10 text-center text-sm">
            <div className="border-t border-black pt-1">O secretário da igreja</div>
            <div className="border-t border-black pt-1">O pastor / ancião</div>
          </div>
        </article>
        <DialogFooter className="print:hidden">
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>Fechar</Button>
          <Button type="button" className="alvo" onClick={() => imprimirComo(`Carta de transferência - ${x.membro}`)}><Printer className="size-4" />Imprimir / guardar PDF</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
