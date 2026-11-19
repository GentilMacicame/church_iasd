/**
 * Extractos (V50) · "Quanto tem cada departamento e cada fundo neste período?"
 * Período: mês, trimestre, semestre ou ano. Por departamento: a % do ano, o saldo inicial, a doação directa (entradas
 * em nome do departamento), a distribuída (a parte da igreja nas ofertas e no orçamento local, pela %), as despesas,
 * as transferências, os estornos, os adiantamentos e o saldo final. Por fundo: saldo inicial, entradas, saídas e final.
 * Daqui definem-se as percentagens, transfere-se entre departamentos e registam-se adiantamentos e prestações de contas.
 */
import { useMemo, useState } from 'react'
import { ArrowLeftRight, FileSpreadsheet, HandCoins, Percent, Printer } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Segmentos, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { CampoData } from '@/components/comum/CampoData'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { Seleccao } from '@/components/comum/Seleccao'
import { Folha } from '@/features/escola-sabatina/componentes'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { centimos, data, deCentimos, dinheiro, hojeIso } from '@/lib/formatos'
import { imprimirComo } from '@/lib/documentos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { useDepartamentosIgreja } from '@/features/actividades/api'
import {
  useAdiantamentos, useDepartamentosTesourariaMut, useExtractoDepartamentos, useExtractoFundos, usePercentagensDepartamento,
  type Adiantamento, type LinhaExtractoDepartamento,
} from './api'

type Tipo = 'mes' | 'trimestre' | 'semestre' | 'ano'
const MESES = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro']
const PARTES: Record<Tipo, number> = { mes: 12, trimestre: 4, semestre: 2, ano: 1 }
const MESES_POR: Record<Tipo, number> = { mes: 1, trimestre: 3, semestre: 6, ano: 12 }

/** O primeiro e o último dia do período (aaaa-mm-dd). */
function intervalo(tipo: Tipo, ano: number, n: number) {
  const m0 = (n - 1) * MESES_POR[tipo]
  const ini = new Date(Date.UTC(ano, m0, 1))
  const fim = new Date(Date.UTC(ano, m0 + MESES_POR[tipo], 0))
  return { inicio: ini.toISOString().slice(0, 10), fim: fim.toISOString().slice(0, 10) }
}
function rotuloParte(tipo: Tipo, n: number) {
  return tipo === 'mes' ? MESES[n - 1] : tipo === 'trimestre' ? `${n}.º trimestre` : tipo === 'semestre' ? `${n}.º semestre` : 'Ano inteiro'
}
/** Valor da folha: "—" quando é zero, negativos com o sinal. */
const v = (x?: string | null) => (x == null || centimos(x) === 0 ? '—' : dinheiro(x).replace(/\s*MT$/, ''))

export default function PaginaExtractos() {
  const igreja = useIgreja()
  const hoje = hojeIso()
  const anoActual = Number(hoje.slice(0, 4))
  const [tipo, setTipo] = useState<Tipo>('mes')
  const [ano, setAno] = useState(anoActual)
  const [n, setN] = useState(Number(hoje.slice(5, 7)))
  const [vista, setVista] = useState<'departamentos' | 'fundos'>('departamentos')
  const parte = Math.min(n, PARTES[tipo])
  const { inicio, fim } = intervalo(tipo, ano, parte)
  const titulo = `${rotuloParte(tipo, parte)}${tipo === 'ano' ? '' : ' de'} ${ano}`

  const mudarTipo = (x: Tipo) => {
    setTipo(x)
    const mes = Number(hoje.slice(5, 7))
    setN(x === 'mes' ? mes : x === 'trimestre' ? Math.ceil(mes / 3) : x === 'semestre' ? Math.ceil(mes / 6) : 1)
  }

  return (
    <>
      <div className="print:hidden">
        <TituloPagina icone={FileSpreadsheet} titulo="Extractos" descricao="Por departamento e por fundo, no período escolhido"
          accoes={<Button variant="outline" className="alvo" onClick={() => imprimirComo(`Extracto ${titulo} - ${igreja.nome}`)}><Printer className="size-4" />Imprimir</Button>} />
        <div className="mb-6 flex flex-wrap items-center gap-3">
          <Segmentos rotulo="Período" valor={tipo} aoMudar={mudarTipo}
            opcoes={[{ valor: 'mes', rotulo: 'Mês' }, { valor: 'trimestre', rotulo: 'Trimestre' }, { valor: 'semestre', rotulo: 'Semestre' }, { valor: 'ano', rotulo: 'Ano' }] as const} />
          {tipo !== 'ano' && (
            <div className="w-44"><Seleccao aria-label="Qual" value={String(parte)} onChange={(e) => setN(Number(e.target.value))}>
              {Array.from({ length: PARTES[tipo] }, (_, i) => <option key={i + 1} value={i + 1}>{rotuloParte(tipo, i + 1)}</option>)}
            </Seleccao></div>
          )}
          <div className="w-28"><Seleccao aria-label="Ano" value={String(ano)} onChange={(e) => setAno(Number(e.target.value))}>
            {[anoActual, anoActual - 1, anoActual - 2, anoActual - 3].map((a) => <option key={a} value={a}>{a}</option>)}
          </Seleccao></div>
          <Segmentos rotulo="Extracto" valor={vista} aoMudar={setVista} className="sm:ml-auto"
            opcoes={[{ valor: 'departamentos', rotulo: 'Por departamento' }, { valor: 'fundos', rotulo: 'Por fundo' }] as const} />
        </div>
      </div>
      <p className="mb-3 hidden text-sm print:block">{igreja.nome} · {titulo} ({data(inicio)} a {data(fim)})</p>
      {vista === 'departamentos' ? <ExtractoDepartamentos inicio={inicio} fim={fim} ano={ano} titulo={titulo} /> : <ExtractoFundos inicio={inicio} fim={fim} titulo={titulo} />}
    </>
  )
}

function ExtractoDepartamentos({ inicio, fim, ano, titulo }: { inicio: string; fim: string; ano: number; titulo: string }) {
  const { pode } = useSessao()
  const q = useExtractoDepartamentos(inicio, fim)
  const [janela, setJanela] = useState<'percentagens' | 'transferencia' | 'adiantamento' | null>(null)
  const lista = q.data ?? []
  const soma = (k: keyof LinhaExtractoDepartamento) => deCentimos(lista.reduce((s, l) => s + centimos((l[k] as string | null) ?? '0'), 0))
  const somaPct = lista.reduce((s, l) => s + Number(l.percentagem ?? 0), 0)
  const COLS: [keyof LinhaExtractoDepartamento, string][] = [['saldoInicial', 'Saldo inicial'], ['doacaoDirecta', 'Doação directa'], ['doacaoDistribuida', 'Doação distribuída'],
    ['despesas', 'Despesas'], ['transfSaida', 'Transf. saída'], ['transfEntrada', 'Transf. entrada'], ['estornos', 'Estorno'], ['adiantamentos', 'Adiantamento'], ['saldoFinal', 'Saldo final']]

  return (
    <div className="grid gap-6">
      <Cartao titulo={`Departamentos · ${titulo}`} icone={FileSpreadsheet} semMargem
        accoes={<div className="flex flex-wrap gap-2 print:hidden">
          {pode('tesouraria.percentagem_departamento.criar') && <Button variant="outline" size="sm" className="alvo" onClick={() => setJanela('percentagens')}><Percent className="size-4" />Percentagens</Button>}
          {pode('tesouraria.transferencia_departamento.criar') && <Button variant="outline" size="sm" className="alvo" onClick={() => setJanela('transferencia')}><ArrowLeftRight className="size-4" />Transferência</Button>}
          {pode('tesouraria.adiantamento.criar') && <Button variant="outline" size="sm" className="alvo" onClick={() => setJanela('adiantamento')}><HandCoins className="size-4" />Adiantamento</Button>}
        </div>}>
        {q.isPending ? <LinhasACarregar linhas={6} /> : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="m-4" />
          : !lista.length ? <EstadoVazio icone={FileSpreadsheet}>A igreja ainda não tem departamentos.</EstadoVazio> : (
            <div className="px-4 pb-4 sm:px-6">
              <Folha minimo="min-w-[72rem]">
                <thead><tr><th className="min-w-48">Departamento</th><th className="num">Orçamento</th>{COLS.map(([k, r]) => <th key={k} className="num">{r}</th>)}</tr></thead>
                <tbody>
                  {lista.map((l) => (
                    <tr key={l.departamentoIgrejaId}>
                      <td className="font-medium">{l.departamento}</td>
                      <td className="num text-muted-foreground">{l.percentagem != null && Number(l.percentagem) > 0 ? `${String(Number(l.percentagem)).replace('.', ',')}%` : '—'}</td>
                      {COLS.map(([k]) => {
                        const x = l[k] as string
                        return <td key={k} className={cn('num', k === 'saldoFinal' && 'font-semibold', centimos(x) < 0 && 'text-destructive-text', centimos(x) === 0 && 'text-muted-foreground')}>{v(x)}</td>
                      })}
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr>
                    <td>Total</td>
                    <td className={cn('num', somaPct !== 100 && somaPct > 0 && 'text-warning-text')}>{somaPct ? `${String(Math.round(somaPct * 100) / 100).replace('.', ',')}%` : '—'}</td>
                    {COLS.map(([k]) => <td key={k} className={cn('num', centimos(soma(k)) < 0 && 'text-destructive-text')}>{v(soma(k))}</td>)}
                  </tr>
                </tfoot>
              </Folha>
              {somaPct > 0 && somaPct < 100 && <p className="mt-2 text-xs text-warning-text print:hidden">As percentagens de {ano} somam {String(somaPct).replace('.', ',')}%: o resto da doação fica por distribuir.</p>}
              {!somaPct && <p className="mt-2 text-xs text-muted-foreground print:hidden">Sem percentagens em {ano}: a doação distribuída fica a zero. Defina-as em "Percentagens".</p>}
            </div>
          )}
      </Cartao>
      <Adiantamentos />
      {janela === 'percentagens' && <DialogoPercentagens ano={ano} aoFechar={() => setJanela(null)} />}
      {janela === 'transferencia' && <DialogoTransferenciaDep aoFechar={() => setJanela(null)} />}
      {janela === 'adiantamento' && <DialogoAdiantamento aoFechar={() => setJanela(null)} />}
    </div>
  )
}

function ExtractoFundos({ inicio, fim, titulo }: { inicio: string; fim: string; titulo: string }) {
  const q = useExtractoFundos(inicio, fim)
  const lista = (q.data ?? []).filter((f) => !['ES_MISSOES', 'ES_13_SABADO', 'OFERTA_MISSIONARIA'].includes(f.tipo))
  const soma = (k: 'saldoInicial' | 'entradas' | 'saidas' | 'saldoFinal') => deCentimos(lista.reduce((s, l) => s + centimos(l[k]), 0))
  return (
    <Cartao titulo={`Fundos · ${titulo}`} icone={FileSpreadsheet} semMargem>
      {q.isPending ? <LinhasACarregar linhas={5} /> : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="m-4" />
        : !lista.length ? <EstadoVazio icone={FileSpreadsheet}>Sem movimentos confirmados.</EstadoVazio> : (
          <div className="px-4 pb-4 sm:px-6">
            <Folha minimo="min-w-[40rem]">
              <thead><tr><th className="min-w-48">Fundo</th><th className="num">Saldo inicial</th><th className="num">Entradas</th><th className="num">Saídas</th><th className="num">Saldo final</th></tr></thead>
              <tbody>
                {lista.map((f) => (
                  <tr key={f.fundoId}>
                    <td className="font-medium">{f.fundo}</td>
                    <td className="num">{v(f.saldoInicial)}</td><td className="num text-success-text">{v(f.entradas)}</td>
                    <td className="num text-destructive-text">{v(f.saidas)}</td><td className={cn('num font-semibold', centimos(f.saldoFinal) < 0 && 'text-destructive-text')}>{v(f.saldoFinal)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot><tr><td>Total</td><td className="num">{v(soma('saldoInicial'))}</td><td className="num">{v(soma('entradas'))}</td><td className="num">{v(soma('saidas'))}</td><td className="num">{v(soma('saldoFinal'))}</td></tr></tfoot>
            </Folha>
          </div>
        )}
    </Cartao>
  )
}

/** Adiantamentos: os que ainda não prestaram contas, com o botão para fechar. */
function Adiantamentos() {
  const { pode } = useSessao()
  const q = useAdiantamentos()
  const deps = useDepartamentosIgreja()
  const basicos = useMembrosBasicos()
  const [prestar, setPrestar] = useState<Adiantamento | null>(null)
  const abertos = (q.data ?? []).filter((a) => !a.dataPrestacao)
  const nomeDep = (id: number) => deps.data?.daIgreja.find((d) => d.id === id)?.nome ?? 'Departamento'
  const nomeMembro = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m ? `${m.nome} ${m.apelido}` : `Membro ${id}` }
  if (!abertos.length) return null
  return (
    <Cartao titulo="Adiantamentos por prestar contas" icone={HandCoins} semMargem className="print:hidden">
      <ul className="divide-y border-t">
        {abertos.map((a) => (
          <li key={a.id} className="flex flex-wrap items-center gap-3 px-5 py-3 sm:px-6">
            <span className="min-w-0 flex-1">
              <span className="block font-medium">{nomeMembro(a.membroId)} <span className="font-normal text-muted-foreground">· {nomeDep(a.departamentoIgrejaId)}</span></span>
              <span className="block text-xs text-muted-foreground">{data(a.data)} · {a.descricao}</span>
            </span>
            <span className="num font-semibold">{dinheiro(a.valor)}</span>
            {pode('tesouraria.adiantamento.alterar') && <Button size="sm" variant="outline" className="alvo" onClick={() => setPrestar(a)}>Prestar contas</Button>}
          </li>
        ))}
      </ul>
      {prestar && <DialogoPrestar a={prestar} aoFechar={() => setPrestar(null)} />}
    </Cartao>
  )
}

function DialogoPercentagens({ ano, aoFechar }: { ano: number; aoFechar: () => void }) {
  const deps = useDepartamentosIgreja()
  const actuais = usePercentagensDepartamento(ano)
  const { gravarPercentagem } = useDepartamentosTesourariaMut()
  const [valores, setValores] = useState<Record<number, string>>({})
  const [erro, setErro] = useState<string | null>(null)
  const [aGravar, setAGravar] = useState(false)
  const lista = deps.data?.daIgreja ?? []
  const actual = useMemo(() => new Map((actuais.data ?? []).map((p) => [p.departamentoIgrejaId, p])), [actuais.data])
  const valor = (id: number) => valores[id] ?? (actual.get(id) ? String(Number(actual.get(id)!.percentagem)) : '')
  const total = lista.reduce((s, d) => s + (Number(valor(d.id).replace(',', '.')) || 0), 0)
  const gravar = async () => {
    setErro(null)
    if (total > 100) return setErro(`As percentagens somam ${total}%: não podem passar de 100%.`)
    setAGravar(true)
    try {
      // primeiro as que descem (para a soma nunca passar de 100% a meio), depois as que sobem
      const mudar = lista.map((d) => ({ d, novo: Number(valor(d.id).replace(',', '.')) || 0, antes: Number(actual.get(d.id)?.percentagem ?? 0) }))
        .filter((x) => x.novo !== x.antes).sort((a, b) => (a.novo - a.antes) - (b.novo - b.antes))
      for (const x of mudar) await gravarPercentagem.mutateAsync({ id: actual.get(x.d.id)?.id, departamentoIgrejaId: x.d.id, ano, percentagem: x.novo.toFixed(2) })
      toast.success('Percentagens gravadas.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) } finally { setAGravar(false) }
  }
  return (
    <Dialog open onOpenChange={(o) => !o && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader><DialogTitle>Percentagens de {ano}</DialogTitle><DialogDescription>A parte de cada departamento na doação distribuída.</DialogDescription></DialogHeader>
        <ErroFormulario mensagem={erro} />
        <ul className="divide-y rounded-xl border">
          {lista.map((d) => (
            <li key={d.id} className="flex items-center justify-between gap-3 px-3 py-2">
              <label htmlFor={`pct-${d.id}`} className="text-sm">{d.nome}</label>
              <span className="flex items-center gap-1.5"><Input id={`pct-${d.id}`} inputMode="decimal" value={valor(d.id)} onChange={(e) => setValores((x) => ({ ...x, [d.id]: e.target.value.replace(/[^\d.,]/g, '') }))} className="alvo h-9 w-20 text-right tabular-nums" /><span className="text-sm text-muted-foreground">%</span></span>
            </li>
          ))}
        </ul>
        <p className={cn('flex justify-between text-sm font-medium', total > 100 ? 'text-destructive-text' : total === 100 ? 'text-success-text' : 'text-muted-foreground')}><span>Total</span><span className="tabular-nums">{String(Math.round(total * 100) / 100).replace('.', ',')}%</span></p>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={aGravar} onClick={() => void gravar()}>{aGravar ? t.comum.aGravar : t.comum.guardar}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function DialogoTransferenciaDep({ aoFechar }: { aoFechar: () => void }) {
  const deps = useDepartamentosIgreja()
  const { transferir } = useDepartamentosTesourariaMut()
  const [origem, setOrigem] = useState('')
  const [destino, setDestino] = useState('')
  const [dia, setDia] = useState(hojeIso())
  const [valor, setValor] = useState('')
  const [descricao, setDescricao] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const lista = deps.data?.daIgreja ?? []
  const gravar = () => {
    setErro(null)
    if (!origem || !destino) return setErro('Escolha os dois departamentos.')
    if (origem === destino) return setErro('O destino tem de ser outro departamento.')
    if (!valor || centimos(valor) <= 0) return setErro('Escreva o valor.')
    transferir.mutate({ origemDepartamentoIgrejaId: Number(origem), destinoDepartamentoIgrejaId: Number(destino), data: dia, valor, descricao: descricao.trim() || undefined }, {
      onSuccess: () => { toast.success('Transferência registada.'); aoFechar() }, onError: (e) => setErro(mensagemDe(e)),
    })
  }
  return (
    <Dialog open onOpenChange={(o) => !o && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader><DialogTitle>Transferência entre departamentos</DialogTitle><DialogDescription>Passa saldo de um departamento para outro.</DialogDescription></DialogHeader>
        <ErroFormulario mensagem={erro} />
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="grid gap-1.5"><span className="text-sm font-medium">De</span><Seleccao aria-label="De" value={origem} onChange={(e) => setOrigem(e.target.value)}><option value="">Escolher…</option>{lista.map((d) => <option key={d.id} value={d.id}>{d.nome}</option>)}</Seleccao></div>
          <div className="grid gap-1.5"><span className="text-sm font-medium">Para</span><Seleccao aria-label="Para" value={destino} onChange={(e) => setDestino(e.target.value)}><option value="">Escolher…</option>{lista.filter((d) => String(d.id) !== origem).map((d) => <option key={d.id} value={d.id}>{d.nome}</option>)}</Seleccao></div>
          <div className="campo-flutuante grid gap-1.5"><label htmlFor="tdp-data" className="text-sm font-medium">Data</label><CampoData id="tdp-data" value={dia} onChange={setDia} className="alvo" /></div>
          <div className="campo-flutuante grid gap-1.5"><label htmlFor="tdp-valor" className="text-sm font-medium">Valor</label><CampoDinheiro id="tdp-valor" value={valor} onChange={setValor} className="alvo" /></div>
          <div className="campo-flutuante grid gap-1.5 sm:col-span-2"><label htmlFor="tdp-desc" className="text-sm font-medium">Motivo</label><Input id="tdp-desc" value={descricao} onChange={(e) => setDescricao(e.target.value)} maxLength={255} placeholder="Opcional" className="alvo" /></div>
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={transferir.isPending} onClick={gravar}>{transferir.isPending ? t.comum.aGravar : 'Transferir'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function DialogoAdiantamento({ aoFechar }: { aoFechar: () => void }) {
  const deps = useDepartamentosIgreja()
  const basicos = useMembrosBasicos()
  const { adiantar } = useDepartamentosTesourariaMut()
  const [dep, setDep] = useState('')
  const [membro, setMembro] = useState<number | null>(null)
  const [dia, setDia] = useState(hojeIso())
  const [valor, setValor] = useState('')
  const [descricao, setDescricao] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }
  const gravar = () => {
    setErro(null)
    if (!dep || !membro) return setErro('Escolha o departamento e quem recebe.')
    if (!valor || centimos(valor) <= 0) return setErro('Escreva o valor.')
    if (!descricao.trim()) return setErro('Diga para quê.')
    adiantar.mutate({ departamentoIgrejaId: Number(dep), membroId: membro, data: dia, valor, descricao: descricao.trim() }, {
      onSuccess: () => { toast.success('Adiantamento registado.'); aoFechar() }, onError: (e) => setErro(mensagemDe(e)),
    })
  }
  return (
    <Dialog open onOpenChange={(o) => !o && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader><DialogTitle>Adiantamento</DialogTitle><DialogDescription>Dinheiro entregue a um responsável, que presta contas depois.</DialogDescription></DialogHeader>
        <ErroFormulario mensagem={erro} />
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="grid gap-1.5 sm:col-span-2"><span className="text-sm font-medium">Departamento</span><Seleccao aria-label="Departamento" value={dep} onChange={(e) => setDep(e.target.value)}><option value="">Escolher…</option>{(deps.data?.daIgreja ?? []).map((d) => <option key={d.id} value={d.id}>{d.nome}</option>)}</Seleccao></div>
          <div className="campo-flutuante grid gap-1.5 sm:col-span-2"><label htmlFor="adt-membro" className="text-sm font-medium">Quem recebe</label><CampoMembro id="adt-membro" valor={membro} aoMudar={setMembro} nomeDe={nomeDe} /></div>
          <div className="campo-flutuante grid gap-1.5"><label htmlFor="adt-data" className="text-sm font-medium">Data</label><CampoData id="adt-data" value={dia} onChange={setDia} className="alvo" /></div>
          <div className="campo-flutuante grid gap-1.5"><label htmlFor="adt-valor" className="text-sm font-medium">Valor</label><CampoDinheiro id="adt-valor" value={valor} onChange={setValor} className="alvo" /></div>
          <div className="campo-flutuante grid gap-1.5 sm:col-span-2"><label htmlFor="adt-desc" className="text-sm font-medium">Para quê</label><Input id="adt-desc" value={descricao} onChange={(e) => setDescricao(e.target.value)} maxLength={255} placeholder="ex.: material do retiro" className="alvo" /></div>
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={adiantar.isPending} onClick={gravar}>{adiantar.isPending ? t.comum.aGravar : 'Registar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function DialogoPrestar({ a, aoFechar }: { a: Adiantamento; aoFechar: () => void }) {
  const { prestarContas } = useDepartamentosTesourariaMut()
  const [dia, setDia] = useState(hojeIso())
  const [devolvido, setDevolvido] = useState('0.00')
  const [erro, setErro] = useState<string | null>(null)
  const gravar = () => {
    setErro(null)
    if (centimos(devolvido || '0') > centimos(a.valor)) return setErro('O devolvido não pode passar do adiantado.')
    prestarContas.mutate({ id: a.id, dataPrestacao: dia, valorDevolvido: devolvido || '0.00' }, {
      onSuccess: () => { toast.success('Contas prestadas.'); aoFechar() }, onError: (e) => setErro(mensagemDe(e)),
    })
  }
  return (
    <Dialog open onOpenChange={(o) => !o && aoFechar()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader><DialogTitle>Prestar contas</DialogTitle><DialogDescription>{a.descricao} · adiantado {dinheiro(a.valor)}</DialogDescription></DialogHeader>
        <ErroFormulario mensagem={erro} />
        <div className="grid gap-4">
          <div className="campo-flutuante grid gap-1.5"><label htmlFor="pre-data" className="text-sm font-medium">Data</label><CampoData id="pre-data" value={dia} onChange={setDia} className="alvo" /></div>
          <div className="campo-flutuante grid gap-1.5"><label htmlFor="pre-dev" className="text-sm font-medium">Devolvido</label><CampoDinheiro id="pre-dev" value={devolvido} onChange={setDevolvido} className="alvo" />
            <span className="text-xs text-muted-foreground">O que sobrou e voltou ao departamento.</span></div>
        </div>
        <DialogFooter>
          <Button variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button className="alvo" disabled={prestarContas.isPending} onClick={gravar}>{prestarContas.isPending ? t.comum.aGravar : 'Guardar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

