/**
 * Transferência entre contas da igreja (F-TES-05): levar o dinheiro do caixa ao banco, levantar do banco para o
 * caixa, passar do M-Pesa para o banco. Não tem linhas de fundo — o dinheiro continua nos mesmos fundos, só muda
 * de conta. A base de dados recusa contas de outra igreja, moedas diferentes, a conta da Missão e meses fechados.
 *
 * Também serve para "Depositar no banco" a contagem conferida: no fim marca a contagem como DEPOSITADA.
 */
import { useState } from 'react'
import { ArrowRight } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Dinheiro } from '@/components/comum/elementos'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { CampoData } from '@/components/comum/CampoData'
import { CampoEscolha } from '@/components/comum/CampoEscolha'
import { mensagemDe } from '@/api/erros'
import { t } from '@/i18n/pt-MZ'
import { centimos, data, hojeIso } from '@/lib/formatos'
import { useContagensMut, useContasIgreja, useCriarMovimento, useSaldosContas } from './api'

const TIPO: Record<string, string> = { CAIXA: 'Caixa', MPESA: 'M-Pesa', EMOLA: 'e-Mola', BANCO: 'Banco' }
const METODO: Record<string, 'NUMERARIO' | 'MPESA' | 'EMOLA' | 'BANCO'> = { CAIXA: 'NUMERARIO', MPESA: 'MPESA', EMOLA: 'EMOLA', BANCO: 'BANCO' }

export function DialogoTransferencia({ aoFechar, origem, valor: valorInicial, contagem }: {
  aoFechar: () => void
  /** conta de onde sai (por defeito, a primeira) */
  origem?: number
  valor?: string
  /** depósito de uma contagem conferida: no fim, a contagem passa a DEPOSITADA */
  contagem?: { id: number; data: string; ocasiao: string | null }
}) {
  const contas = useContasIgreja()
  const saldos = useSaldosContas()
  const criar = useCriarMovimento()
  const { mudarEstado } = useContagensMut()
  const lista = contas.data ?? []
  const [de, setDe] = useState(origem ? String(origem) : '')
  const [para, setPara] = useState('')
  const [valor, setValor] = useState(valorInicial ?? '')
  const [dia, setDia] = useState(hojeIso())
  const [referencia, setReferencia] = useState('')
  const [descricao, setDescricao] = useState(contagem ? `Depósito da contagem de ${data(contagem.data)}${contagem.ocasiao ? ` (${contagem.ocasiao})` : ''}` : '')
  const [erro, setErro] = useState<string | null>(null)
  // a chave fica a mesma enquanto o diálogo está aberto: carregar duas vezes (rede lenta) não duplica
  const [chave] = useState(() => crypto.randomUUID())
  const deId = de || (lista[0] ? String(lista[0].id) : '')
  // num depósito, o destino por defeito é o banco
  const paraId = para || (contagem ? String(lista.find((c) => c.tipo === 'BANCO')?.id ?? '') : '')
  const contaDe = lista.find((c) => String(c.id) === deId)
  const contaPara = lista.find((c) => String(c.id) === paraId)
  const saldoDe = saldos.data?.find((s) => String(s.id) === deId)?.saldo
  const opcao = (c: (typeof lista)[number]) => ({
    valor: String(c.id), rotulo: c.nome,
    detalhe: [TIPO[c.tipo ?? ''] ?? c.tipo, c.banco, c.numero, saldos.data?.find((s) => s.id === c.id)?.saldo ? `saldo ${saldos.data.find((s) => s.id === c.id)!.saldo.replace('.', ',')} MT` : null].filter(Boolean).join(' · '),
  })

  const submeter = async () => {
    setErro(null)
    if (!deId || !paraId) return setErro('Escolha as duas contas.')
    if (deId === paraId) return setErro('A conta de destino tem de ser diferente da de origem.')
    if (!/^\d{1,14}(\.\d{1,2})?$/.test(valor) || centimos(valor) <= 0) return setErro('Escreva o valor, por exemplo 1 500,00.')
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dia)) return setErro('Escreva a data como dd/mm/aaaa.')
    if (contaPara?.tipo === 'BANCO' && !referencia.trim() && contaDe?.tipo === 'CAIXA') return setErro('Escreva o n.º do talão de depósito.')
    try {
      await criar.mutateAsync({
        chave, confirmar: true,
        corpo: {
          tipo: 'TRANSFERENCIA', metodo: METODO[contaPara?.tipo ?? 'BANCO'], valorTotal: valor, contaId: Number(deId), destinoContaId: Number(paraId),
          dataHora: `${dia}T12:00:00+02:00`, descricao: descricao.trim() || `Transferência de ${contaDe?.nome} para ${contaPara?.nome}`,
          referencia: referencia.trim() || undefined,
        } as never,
      })
      if (contagem) {
        try {
          await mudarEstado.mutateAsync({ id: contagem.id, estado: 'DEPOSITADA' })
        } catch (e) {
          toast.error(`O depósito ficou registado, mas a contagem não mudou para depositada: ${mensagemDe(e)}`)
          return aoFechar()
        }
      }
      toast.success(contagem ? 'Depósito registado e contagem marcada como depositada.' : 'Transferência registada.')
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{contagem ? 'Depositar no banco' : 'Transferir entre contas'}</DialogTitle>
          <DialogDescription>
            {contagem ? 'O numerário desta contagem sai do caixa e entra na conta bancária. Os fundos (dízimos, ofertas) não mudam.'
              : 'O dinheiro muda de conta mas continua nos mesmos fundos: não é entrada nem saída.'}
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid items-end gap-3 sm:grid-cols-[1fr_auto_1fr]">
            <div className="grid gap-1.5">
              <label htmlFor="trf-de" className="text-sm font-medium">De</label>
              <CampoEscolha id="trf-de" valor={deId} aoMudar={setDe} opcoes={lista.map(opcao)} vazio="Conta de origem…" />
            </div>
            <ArrowRight aria-hidden className="mx-auto mb-2.5 hidden size-4 text-muted-foreground sm:block" />
            <div className="grid gap-1.5">
              <label htmlFor="trf-para" className="text-sm font-medium">Para</label>
              <CampoEscolha id="trf-para" valor={paraId} aoMudar={setPara} opcoes={lista.filter((c) => String(c.id) !== deId).map(opcao)} vazio="Conta de destino…" />
            </div>
          </div>
          {saldoDe != null && <p className="-mt-2 text-xs text-muted-foreground">Saldo em {contaDe?.nome}: <Dinheiro valor={saldoDe} /></p>}
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="grid gap-1.5">
              <label htmlFor="trf-valor" className="text-sm font-medium">Valor <span className="text-destructive-text">*</span></label>
              <CampoDinheiro id="trf-valor" value={valor} onChange={setValor} className="alvo" />
            </div>
            <div className="grid gap-1.5">
              <label htmlFor="trf-data" className="text-sm font-medium">Data</label>
              <CampoData id="trf-data" value={dia} onChange={setDia} className="alvo" />
            </div>
            <div className="grid gap-1.5 sm:col-span-2">
              <label htmlFor="trf-ref" className="text-sm font-medium">{contaPara?.tipo === 'BANCO' ? 'N.º do talão de depósito' : 'Referência'}</label>
              <Input id="trf-ref" value={referencia} onChange={(e) => setReferencia(e.target.value)} className="alvo num" maxLength={100} placeholder={contaPara?.tipo === 'BANCO' ? 'ex.: 004512' : 'opcional'} />
            </div>
            <div className="grid gap-1.5 sm:col-span-2">
              <label htmlFor="trf-desc" className="text-sm font-medium">Descrição</label>
              <Input id="trf-desc" value={descricao} onChange={(e) => setDescricao(e.target.value)} className="alvo" maxLength={255} placeholder="ex.: Depósito das ofertas de sábado" />
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={criar.isPending || mudarEstado.isPending || contas.isPending} onClick={submeter}>
            {criar.isPending || mudarEstado.isPending ? t.comum.aGravar : contagem ? 'Registar o depósito' : 'Transferir'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
