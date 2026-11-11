/**
 * Contas · "Onde está o dinheiro da igreja?" — caixa, M-Pesa e banco da igreja, e a conta da Missão (V21), onde
 * se registam os pagamentos que os membros fazem directamente lá (esse dinheiro não é da igreja nem entra no
 * saldo). A base de dados recusa uma conta da Missão do tipo caixa ou de uma entidade que não recebe fundos.
 */
import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { ArrowLeftRight, Church, FileCheck2, Landmark, Plus, Wallet } from 'lucide-react'
import { Link } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Dinheiro, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { CampoData } from '@/components/comum/CampoData'
import { Seleccao } from '@/components/comum/Seleccao'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { centimos, deCentimos, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { DialogoTransferencia } from './DialogoTransferencia'
import { useContas, useContasMut, useEntidades, useFundos, useSaldosContas, type Conta } from './api'

const TIPOS: Record<string, string> = { CAIXA: 'Caixa (numerário)', MPESA: 'M-Pesa', EMOLA: 'e-Mola', BANCO: 'Banco' }

export default function PaginaContas() {
  const { pode } = useSessao()
  const contas = useContas()
  const saldos = useSaldosContas()
  const entidades = useEntidades()
  const [params, setParams] = useSearchParams()
  const nova = params.get('nova')
  const transferir = params.get('transferir')
  const abrir = (tipo: 'igreja' | 'missao' | null) => setParams((p) => { const n = new URLSearchParams(p); if (tipo) n.set('nova', tipo); else n.delete('nova'); return n })
  const abrirTransferencia = (de: number | null) => setParams((p) => { const n = new URLSearchParams(p); if (de != null) n.set('transferir', String(de)); else n.delete('transferir'); return n })
  const saldoDe = (id: number) => saldos.data?.find((s) => s.id === id)?.saldo
  const daIgreja = (contas.data ?? []).filter((c) => c.entidadeId == null)
  const daMissao = (contas.data ?? []).filter((c) => c.entidadeId != null)
  const totalIgreja = deCentimos(daIgreja.reduce((s, c) => s + centimos(saldoDe(c.id) ?? '0'), 0))
  const nomeEntidade = (id: number) => entidades.data?.find((e) => e.id === id)?.nome ?? 'Missão'
  const podeTransferir = pode('tesouraria.transacao.criar') && daIgreja.length > 1

  const linhas = (l: Conta[], missao: boolean) => (
    <Tabela>
      <thead><tr><th className="sm:pl-6">Conta</th><th className="hidden sm:table-cell">Tipo</th><th className="num">{missao ? 'Pago lá pelos membros' : 'Saldo'}</th>{!missao && podeTransferir && <th className="sm:pr-6"><span className="sr-only">Acções</span></th>}</tr></thead>
      <tbody>
        {l.map((c) => (
          <tr key={c.id}>
            <td className="sm:pl-6">
              <p className="font-medium">{c.nome}</p>
              <p className="text-xs text-muted-foreground">{[c.banco, c.numero, missao && c.entidadeId ? nomeEntidade(c.entidadeId) : c.titular].filter(Boolean).join(' · ') || '—'}</p>
            </td>
            <td className="hidden text-muted-foreground sm:table-cell">{TIPOS[c.tipo ?? ''] ?? c.tipo}</td>
            <td className={cn('num font-medium', (missao || !podeTransferir) && 'sm:pr-6')}><Dinheiro valor={saldoDe(c.id) ?? '0.00'} /></td>
            {!missao && podeTransferir && (
              <td className="w-px whitespace-nowrap text-right sm:pr-6">
                <Button size="sm" variant="ghost" className="alvo" onClick={() => abrirTransferencia(c.id)} aria-label={`Transferir de ${c.nome}`}>
                  <ArrowLeftRight className="size-4" /><span className="hidden md:inline">Transferir</span>
                </Button>
              </td>
            )}
          </tr>
        ))}
        {!missao && l.length > 1 && <tr className="bg-muted/30"><td className="font-semibold sm:pl-6" colSpan={2}>Total da igreja</td><td className={cn('num font-semibold', !podeTransferir && 'sm:pr-6')}><Dinheiro valor={totalIgreja} /></td>{podeTransferir && <td />}</tr>}
      </tbody>
    </Tabela>
  )

  return (
    <>
      <TituloPagina icone={Wallet} titulo="Contas" descricao="Onde está o dinheiro da igreja, e a conta da Missão para o que os membros pagam directamente lá"
        accoes={(
          <>
            {pode('tesouraria.extrato_linha.ler') && <Button asChild variant="outline" className="alvo"><Link to="/tesouraria/reconciliacao"><FileCheck2 className="size-4" />Reconciliar extracto</Link></Button>}
            {podeTransferir && <Button variant="outline" className="alvo" onClick={() => abrirTransferencia(0)}><ArrowLeftRight className="size-4" />Transferir</Button>}
            {pode('tesouraria.conta_financeira.criar') && <Button className="alvo" onClick={() => abrir('igreja')}><Plus className="size-4" />Nova conta</Button>}
          </>
        )} />
      {contas.isPending ? <Barra className="h-64 w-full" />
        : contas.isError ? <EstadoErro erro={contas.error} aoTentar={() => contas.refetch()} />
        : (
          <div className="grid items-start gap-6 lg:grid-cols-12">
            <Cartao titulo="Contas da igreja" descricao="O caixa, o M-Pesa e o banco onde o dinheiro da igreja está" icone={Church} semMargem className="lg:col-span-7">
              {daIgreja.length ? linhas(daIgreja, false) : <EstadoVazio icone={Wallet}>Ainda não há contas da igreja.</EstadoVazio>}
            </Cartao>
            <Cartao titulo="Conta da Missão" descricao="Para registar os dízimos e ofertas que os membros pagam directamente na Missão" icone={Landmark} semMargem className="lg:col-span-5">
              {daMissao.length ? linhas(daMissao, true) : (
                <EstadoVazio icone={Landmark} titulo="Ainda não está registada"
                  accao={pode('tesouraria.conta_financeira.criar') && <Button variant="outline" className="alvo" onClick={() => abrir('missao')}>Registar a conta da Missão</Button>}>
                  Alguns membros pagam o dízimo na conta da Missão e mandam o comprovativo: registe aqui essa conta para os lançar.
                </EstadoVazio>
              )}
              {daMissao.length > 0 && <p className="border-t px-4 py-3 text-xs text-muted-foreground sm:px-6">Este dinheiro já está na Missão: não entra no saldo da igreja e conta como já remetido.</p>}
            </Cartao>
          </div>
        )}
      {transferir != null && <DialogoTransferencia origem={Number(transferir) || undefined} aoFechar={() => abrirTransferencia(null)} />}
      {nova && <DialogoConta missao={nova === 'missao'} aoFechar={() => abrir(null)} />}
    </>
  )
}

function DialogoConta({ missao: inicial, aoFechar }: { missao: boolean; aoFechar: () => void }) {
  const igreja = useIgreja()
  const fundos = useFundos()
  const entidades = useEntidades()
  const { criar } = useContasMut()
  const [missao, setMissao] = useState(inicial)
  const [tipo, setTipo] = useState(inicial ? 'BANCO' : 'CAIXA')
  const [nome, setNome] = useState(inicial ? 'Conta da Missão' : '')
  const [banco, setBanco] = useState('')
  const [numero, setNumero] = useState('')
  const [titular, setTitular] = useState('')
  const [saldo, setSaldo] = useState('0.00')
  const [dia, setDia] = useState(hojeIso())
  const [erro, setErro] = useState<string | null>(null)
  // a entidade que recebe os fundos da igreja (a Missão/Associação)
  const entidadeId = (fundos.data ?? []).find((f) => f.destinoEntidadeId)?.destinoEntidadeId ?? null
  const nomeEntidade = entidades.data?.find((e) => e.id === entidadeId)?.nome

  const submeter = async () => {
    setErro(null)
    if (!nome.trim()) return setErro('Dê um nome à conta.')
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dia)) return setErro('Escreva a data como dd/mm/aaaa.')
    if (!missao && !/^\d{1,14}(\.\d{1,2})?$/.test(saldo)) return setErro('Escreva o saldo inicial, por exemplo 1 500,00.')
    if (missao && !entidadeId) return setErro('Não há nenhum fundo da Missão configurado: peça ao administrador.')
    try {
      await criar.mutateAsync({
        igrejaId: igreja.id, tipo, nome: nome.trim(), banco: banco.trim() || undefined, numero: numero.trim() || undefined,
        titular: titular.trim() || (missao ? nomeEntidade : undefined), saldoInicial: missao ? '0.00' : saldo, dataSaldoInicial: dia,
        entidadeId: missao ? entidadeId : undefined,
      } as never)
      toast.success(missao ? 'Conta da Missão registada. Já pode lançar os pagamentos feitos lá.' : 'Conta registada.')
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{missao ? 'Conta da Missão' : 'Nova conta da igreja'}</DialogTitle>
          <DialogDescription>
            {missao ? `A conta${nomeEntidade ? ` de ${nomeEntidade}` : ''} onde alguns membros depositam o dízimo e as ofertas. Serve só para registar esses pagamentos: a igreja não paga nada a partir dela.`
              : 'Um caixa, M-Pesa ou conta bancária onde está o dinheiro da igreja.'}
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div role="radiogroup" aria-label="De quem é a conta" className="grid grid-cols-2 gap-2">
            {[{ v: false, r: 'Da igreja' }, { v: true, r: 'Da Missão' }].map((o) => (
              <button key={o.r} type="button" role="radio" aria-checked={missao === o.v}
                onClick={() => { setMissao(o.v); if (o.v && tipo === 'CAIXA') setTipo('BANCO') }}
                className={cn('alvo rounded-lg border px-3 py-2 text-sm font-medium', missao === o.v ? 'border-primary bg-primary/10 text-primary' : 'text-muted-foreground')}>
                {o.r}
              </button>
            ))}
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="grid gap-1.5">
              <label htmlFor="cta-tipo" className="text-sm font-medium">Tipo</label>
              <Seleccao id="cta-tipo" value={tipo} onChange={(e) => setTipo(e.target.value)}>
                {Object.entries(TIPOS).filter(([k]) => !missao || k !== 'CAIXA').map(([k, r]) => <option key={k} value={k}>{r}</option>)}
              </Seleccao>
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="cta-nome" className="text-sm font-medium">Nome <span className="text-destructive-text">*</span></label>
              <Input id="cta-nome" value={nome} onChange={(e) => setNome(e.target.value)} placeholder={missao ? 'Conta da Missão (BIM)' : 'ex.: BCI da igreja'} className="alvo" maxLength={100} />
            </div>
            {tipo !== 'CAIXA' && (
              <>
                <div className="grid gap-1.5">
                  <label htmlFor="cta-banco" className="text-sm font-medium">{tipo === 'BANCO' ? 'Banco' : 'Operador'}</label>
                  <Input id="cta-banco" value={banco} onChange={(e) => setBanco(e.target.value)} placeholder={tipo === 'BANCO' ? 'ex.: BIM' : 'ex.: Vodacom'} className="alvo" maxLength={100} />
                </div>
                <div className="grid gap-1.5">
                  <label htmlFor="cta-numero" className="text-sm font-medium">{tipo === 'BANCO' ? 'N.º da conta ou NIB' : 'Número'}</label>
                  <Input id="cta-numero" value={numero} onChange={(e) => setNumero(e.target.value)} className="alvo num" maxLength={50} />
                </div>
              </>
            )}
            <div className="grid gap-1.5">
              <label htmlFor="cta-titular" className="text-sm font-medium">Titular</label>
              <Input id="cta-titular" value={titular} onChange={(e) => setTitular(e.target.value)} placeholder={missao ? nomeEntidade : igreja.nome} className="alvo" maxLength={150} />
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="cta-data" className="text-sm font-medium">{missao ? 'A contar de' : 'Data do saldo inicial'}</label>
              <CampoData id="cta-data" value={dia} onChange={setDia} className="alvo" />
            </div>
            {!missao && (
              <div className="grid gap-1.5">
                <label htmlFor="cta-saldo" className="text-sm font-medium">Saldo inicial</label>
                <CampoDinheiro id="cta-saldo" value={saldo} onChange={setSaldo} className="alvo" />
              </div>
            )}
          </div>
          {missao && <p className="text-xs text-muted-foreground"><Pilula variante="info" className="mr-1">Missão</Pilula>Só recebe dízimos e ofertas da Missão, sempre com a referência do comprovativo.</p>}
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={criar.isPending || fundos.isPending} onClick={submeter}>{criar.isPending ? t.comum.aGravar : 'Registar conta'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
