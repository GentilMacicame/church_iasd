/**
 * Registar saída (P-08): um pagamento da igreja. Fica PENDENTE até outra pessoa a aprovar (quem regista não
 * aprova) e depois confirma-se. Só a parte da igreja: os fundos 100% da Missão saem só como remessa, e nos
 * repartidos (oferta combinada) só o que não é da Missão (a base de dados recusa o resto, com a mensagem no topo).
 *
 * ?conta= escolhe a conta (ex.: "Despesa urgente" do fundo de maneio, V42: pede quem fez a despesa; o comprovativo junta-se
 * na ficha do movimento, que abre a seguir).
 */
import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ArrowLeft, Banknote, ShieldCheck, Wallet } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Cartao, TituloPagina } from '@/components/comum/elementos'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { Seleccao } from '@/components/comum/Seleccao'
import { Barra, EstadoErro } from '@/components/comum/estados'
import { rotulos, t } from '@/i18n/pt-MZ'
import { dinheiro, hojeIso } from '@/lib/formatos'
import { METODO_DA_CONTA } from './PaginaEntrada'
import { fundosDaIgreja, useCategorias, useContasIgreja as useContas, useCriarMovimento, useFundos, useSaldosFundos } from './api'
import { parteDoFundo } from './comum'
import { CampoHora } from '@/components/comum/CampoHora'

const esquema = z.object({
  contaId: z.string().min(1, t.comum.obrigatorio),
  metodo: z.string().min(1),
  data: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Escreva a data como dd/mm/aaaa').refine((d) => d <= hojeIso(), 'A data não pode ser no futuro'),
  hora: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'Hora como 10:00'),
  valor: z.string().regex(/^\d{1,14}(\.\d{1,2})?$/, 'Escreva o valor, por exemplo 1 500,00').refine((v) => Number(v) > 0, 'O valor tem de ser maior que zero'),
  fundoId: z.string().min(1, t.comum.obrigatorio),
  categoriaId: z.string().min(1, t.comum.obrigatorio),
  beneficiario: z.string().trim().min(1, 'Diga a quem se paga').max(150),
  descricao: z.string().trim().min(1, 'Diga para que é').max(255),
  referencia: z.string().trim().max(100),
})
type Valores = z.infer<typeof esquema>

export default function PaginaSaida() {
  const navigate = useNavigate()
  const contas = useContas()
  const fundos = useFundos()
  const categorias = useCategorias()
  const criar = useCriarMovimento()
  const [chave] = useState(() => crypto.randomUUID())
  const [erro, setErro] = useState<string | null>(null)
  const saldos = useSaldosFundos()
  const locais = fundosDaIgreja(fundos.data)
  const despesas = (categorias.data ?? []).filter((c) => c.tipo === 'DESPESA' && !c.eRemessa)
  const [params] = useSearchParams()
  const contaInicial = (contas.data ?? []).find((c) => String(c.id) === params.get('conta')) ?? contas.data?.[0]

  const form = useForm<Valores>({
    resolver: zodResolver(esquema),
    values: {
      contaId: contaInicial ? String(contaInicial.id) : '', metodo: METODO_DA_CONTA[contaInicial?.tipo ?? 'CAIXA'],
      data: hojeIso(), hora: new Date().toTimeString().slice(0, 5), valor: '',
      fundoId: String(locais.find((f) => f.tipo === 'ORCAMENTO_LOCAL')?.id ?? locais[0]?.id ?? ''), categoriaId: String(despesas[0]?.id ?? ''),
      beneficiario: '', descricao: '', referencia: '',
    },
    resetOptions: { keepDirtyValues: true },
  })
  const e = form.formState.errors
  const doManeio = contas.data?.find((c) => String(c.id) === form.watch('contaId'))?.tipo === 'FUNDO_MANEIO'
  const ajudaFundo = (id: string) => {
    const f = locais.find((x) => String(x.id) === id)
    const s = saldos.data?.find((x) => String(x.fundoId) === id)
    if (!f) return 'O dízimo e os fundos 100% da Missão só saem no depósito à Missão.'
    return `${parteDoFundo(f)}${s ? ` · a igreja pode gastar ${dinheiro(s.disponivel ?? s.saldo)}` : ''}`
  }

  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    try {
      const { transacao } = await criar.mutateAsync({
        chave, confirmar: false,
        corpo: {
          tipo: 'SAIDA', metodo: v.metodo as never, valorTotal: v.valor, contaId: Number(v.contaId), dataHora: `${v.data}T${v.hora}:00+02:00`,
          beneficiario: v.beneficiario, descricao: v.descricao, referencia: v.referencia || undefined,
          linhas: [{ fundoId: Number(v.fundoId), categoriaId: Number(v.categoriaId), valor: v.valor }],
        } as never,
      })
      toast.success(doManeio ? 'Despesa registada. Junte o comprovativo aqui; fica à espera da aprovação de outra pessoa.' : 'Saída registada. Fica à espera da aprovação de outra pessoa.')
      navigate(`/tesouraria/movimentos/${transacao.id}`)
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })

  if (contas.isPending || fundos.isPending || categorias.isPending) return <Barra className="h-96 w-full" />
  const falha = contas.error ?? fundos.error ?? categorias.error
  if (falha) return <EstadoErro erro={falha} aoTentar={() => { contas.refetch(); fundos.refetch(); categorias.refetch() }} />

  return (
    <form onSubmit={submeter} noValidate>
      <TituloPagina
        antes={<Link to="/tesouraria" className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" /> {t.tesouraria.titulo}</Link>}
        icone={Banknote} titulo={t.tesouraria.saida} descricao="Outra pessoa aprova antes de o dinheiro sair"
      />
      <div className="mx-auto grid w-full max-w-4xl items-start gap-6">
        <div className="grid gap-6">
          <ErroFormulario mensagem={erro} />
          <Cartao titulo="Pagamento" icone={Banknote}>
            <div className="grid gap-4 sm:grid-cols-2">
              <CampoFormulario rotulo={doManeio ? 'Quem fez a despesa' : 'Pago a'} erro={e.beneficiario?.message} obrigatorio
                ajuda={doManeio ? 'O responsável que gastou o dinheiro do fundo de maneio (e a quem pagou)' : undefined}>
                {(p) => <Input {...p} {...form.register('beneficiario')} placeholder={doManeio ? 'ex.: Diácono João Langa (ferragem Chaúque)' : 'ex.: EDM, Carpintaria Langa'} className="alvo" />}
              </CampoFormulario>
              <CampoFormulario rotulo="Valor" erro={e.valor?.message} obrigatorio>
                {(p) => <Controller control={form.control} name="valor" render={({ field }) => <CampoDinheiro {...p} {...field} className="alvo" />} />}
              </CampoFormulario>
              <CampoFormulario rotulo="Para quê" erro={e.descricao?.message} obrigatorio className="sm:col-span-2">
                {(p) => <Input {...p} {...form.register('descricao')} placeholder="ex.: Conta da luz de Outubro" className="alvo" />}
              </CampoFormulario>
              <CampoFormulario rotulo="Categoria" erro={e.categoriaId?.message}>
                {(p) => <Seleccao {...p} {...form.register('categoriaId')}>{despesas.map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}</Seleccao>}
              </CampoFormulario>
              <CampoFormulario rotulo="Sai do fundo" erro={e.fundoId?.message} ajuda={ajudaFundo(form.watch('fundoId'))}>
                {(p) => <Seleccao {...p} {...form.register('fundoId')}>{locais.map((f) => <option key={f.id} value={f.id}>{f.nome}</option>)}</Seleccao>}
              </CampoFormulario>
            </div>
          </Cartao>
          <Cartao titulo="De onde sai" icone={Wallet}>
            <div className="grid gap-4 sm:grid-cols-2">
              <CampoFormulario rotulo="Conta" erro={e.contaId?.message} obrigatorio>
                {(p) => (
                  <Seleccao {...p} {...form.register('contaId', {
                    onChange: (ev) => { const c = contas.data?.find((x) => String(x.id) === ev.target.value); if (c?.tipo) form.setValue('metodo', METODO_DA_CONTA[c.tipo]) },
                  })}>
                    {(contas.data ?? []).map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
                  </Seleccao>
                )}
              </CampoFormulario>
              <CampoFormulario rotulo="Forma de pagamento">
                {(p) => <Seleccao {...p} {...form.register('metodo')}>{Object.entries(rotulos.metodo).map(([k, r]) => <option key={k} value={k}>{r}</option>)}</Seleccao>}
              </CampoFormulario>
              <div className="grid grid-cols-[1fr_auto] gap-3">
                <CampoFormulario rotulo="Data" erro={e.data?.message} obrigatorio>
                  {(p) => <Controller control={form.control} name="data" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
                </CampoFormulario>
                <CampoFormulario rotulo="Hora" erro={e.hora?.message}>
                  {(p) => <CampoHora {...p} {...form.register('hora')} className="alvo" />}
                </CampoFormulario>
              </div>
              <CampoFormulario rotulo="Referência" erro={e.referencia?.message} ajuda="N.º da factura, do recibo ou da transacção">
                {(p) => <Input {...p} {...form.register('referencia')} className="alvo num" />}
              </CampoFormulario>
            </div>
          </Cartao>
        </div>
      </div>
      <div className="sticky bottom-0 z-20 mx-auto mt-6 w-full max-w-4xl print:hidden">
        <div className="flex flex-wrap items-center gap-x-6 gap-y-3 rounded-t-2xl border border-b-0 bg-card/95 px-4 py-3 shadow-[0_-8px_24px_-12px_rgb(15_23_42/0.18)] backdrop-blur sm:px-6">
          <div className="min-w-0">
            <p className="text-xs font-medium text-muted-foreground">Valor a pagar</p>
            <p className="num text-2xl font-bold tracking-tight">{dinheiro(form.watch('valor') || '0')}</p>
          </div>
          <p className="hidden items-center gap-1.5 text-sm text-muted-foreground md:flex"><ShieldCheck className="size-4" />Fica pendente até outra pessoa aprovar</p>
          <div className="ml-auto flex items-center gap-2">
            <Button type="button" variant="ghost" className="alvo" onClick={() => navigate('/tesouraria')}>{t.comum.cancelar}</Button>
            <Button type="submit" disabled={form.formState.isSubmitting} className="alvo h-11 px-6 text-base">{form.formState.isSubmitting ? t.comum.aGravar : 'Registar saída'}</Button>
          </div>
        </div>
      </div>
    </form>
  )
}
