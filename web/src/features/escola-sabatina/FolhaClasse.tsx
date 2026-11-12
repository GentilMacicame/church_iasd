/**
 * Folha da classe no trimestre (a folha "Grupo N" do quadro): uma linha por sábado com M.M. (membros
 * matriculados), M.P. (membros presentes), % de presença, E.D. (estudo diário), % de E.D., visitantes, a oferta
 * missionária do sábado com o alvo, o total acumulado e a % do alvo, as ofertas do 13.º sábado e das despesas da
 * ES, e as filiais; por baixo, o total / média do trimestre.
 *
 * Lê-se como o quadro. Cada sábado tem o seu estado (Por registar, Aberto, Fechado, Futuro) e um botão: "Registar"
 * ou "Editar" abre só essa linha para escrever, com Guardar e Cancelar ali mesmo (Enter guarda, Esc cancela).
 * As regras são da base de dados: um relatório fechado não muda, presentes não passam os matriculados; a recusa
 * aparece na linha. Sábados com chamada nominal contam M.P. e E.D. pela chamada (no ecrã do sábado).
 */
import { useMemo, useState, type KeyboardEvent } from 'react'
import { Link } from 'react-router-dom'
import { AlertCircle, Check, ExternalLink, Lock, Pencil, Plus, Printer, X } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Tooltip, TooltipContent, TooltipTrigger } from '@/components/ui/tooltip'
import { EstadoErro, LinhasACarregar } from '@/components/comum/estados'
import { Pilula } from '@/components/comum/elementos'
import { useSessao } from '@/auth/sessao'
import { mensagemDe } from '@/api/erros'
import { data, dinheiroParaApi, hojeIso } from '@/lib/formatos'
import { imprimirComo } from '@/lib/documentos'
import { cn } from '@/lib/utils'
import {
  matriculadoEm, nomeTrimestre, useComChamada, useGravarLinhaFolha, useMatriculas, useRelatoriosClasse, useSabados,
  type Classe, type ClasseTrimestre, type Relatorio, type Trimestre,
} from './api'
import { CelulaPct, Folha, textoMT, textoNum, textoPct } from './componentes'

type Col = 'mm' | 'mp' | 'ed' | 'vis' | 'oferta' | 'o13' | 'desp' | 'fil'
const COLS_INTEIRAS: Col[] = ['mm', 'mp', 'ed', 'vis', 'fil']
type Valores = Record<Col, string>

/** "1500.50" → "1 500,50" para escrever na célula (sem os espaços especiais do toLocaleString). */
const dinheiroEcra = (api?: string | null) => {
  if (api == null || api === '' || Number(api) === 0) return ''
  const [i, d] = Number(api).toFixed(2).split('.')
  return `${i.replace(/\B(?=(\d{3})+(?!\d))/g, ' ')},${d}`
}
const valoresDe = (r?: Relatorio): Valores => r ? {
  mm: String(r.membrosMatriculados), mp: String(r.membrosPresentes), ed: String(r.estudoDiario), vis: String(r.visitantes),
  oferta: dinheiroEcra(r.oferta), o13: dinheiroEcra(r.oferta13Sabado), desp: dinheiroEcra(r.ofertaDespesas), fil: String(r.filiais),
} : { mm: '', mp: '', ed: '', vis: '', oferta: '', o13: '', desp: '', fil: '' }
const inteiro = (t: string) => (t.trim() === '' ? null : /^\d+$/.test(t.trim()) ? Number(t.trim()) : NaN)
const mt = (t: string) => (t.trim() === '' ? 0 : Number(dinheiroParaApi(t) ?? NaN))
const ROTULO: Record<Col, string> = { mm: 'M.M.', mp: 'M.P.', ed: 'E.D.', vis: 'Visitantes', oferta: 'Oferta do sábado', o13: '13.º sábado', desp: 'Despesas da ES', fil: 'Filiais' }

export function FolhaClasse({ classe, ct, trimestre }: { classe: Classe; ct: ClasseTrimestre; trimestre: Trimestre }) {
  const { pode } = useSessao()
  const sabados = useSabados(trimestre.id)
  const rels = useRelatoriosClasse(ct.id)
  const matriculas = useMatriculas(classe.id)
  const ids = useMemo(() => (rels.data ?? []).map((r) => r.id).sort((a, b) => a - b), [rels.data])
  const chamada = useComChamada(ids)
  const gravar = useGravarLinhaFolha(ct.id)
  const [edicao, setEdicao] = useState<{ sabadoId: number; v: Valores; erro?: string } | null>(null)
  const hoje = hojeIso()
  const podeCriar = pode('escola_sabatina.relatorio_sabado.criar')
  const podeAlterar = pode('escola_sabatina.relatorio_sabado.alterar')
  const alvo = Number(ct.alvoOfertaSabado ?? 0)
  const relDe = useMemo(() => new Map((rels.data ?? []).map((r) => [r.sabadoId, r])), [rels.data])
  const inactiva = ct.estado === 'INACTIVO'

  if (sabados.isError || rels.isError) return <EstadoErro erro={sabados.error ?? rels.error} aoTentar={() => { void sabados.refetch(); void rels.refetch() }} />
  if (sabados.isPending || rels.isPending) return <LinhasACarregar linhas={8} />
  if (!sabados.data.length) return <p className="py-6 text-sm text-muted-foreground">O {nomeTrimestre(trimestre)} ainda não tem sábados. A Associação cria-os em Trimestres.</p>

  const linhas = sabados.data.map((s) => {
    const r = relDe.get(s.id)
    const aEditar = edicao?.sabadoId === s.id
    const v = aEditar ? edicao.v : valoresDe(r)
    const mmMatriculas = (matriculas.data ?? []).filter((m) => matriculadoEm(m, s.data)).length
    const comChamada = !!r && !!chamada.data?.has(r.id)
    const fechado = r?.estado === 'FECHADO'
    const futuro = s.data > hoje
    const editavel = !fechado && !futuro && !inactiva && (r ? podeAlterar : podeCriar)
    const n = { mm: inteiro(v.mm), mp: inteiro(v.mp), ed: inteiro(v.ed), vis: inteiro(v.vis), fil: inteiro(v.fil), oferta: mt(v.oferta), o13: mt(v.o13), desp: mt(v.desp) }
    const tem = !!r || (aEditar && Object.values(v).some((x) => x.trim() !== ''))
    return { s, r, v, n, mmMatriculas, comChamada, fechado, futuro, editavel, tem, aEditar }
  })
  type Linha = (typeof linhas)[number]

  // totais e médias do trimestre (só os sábados com dados), como na linha "TOTAL / MÉDIA"
  const comDados = linhas.filter((l) => l.tem)
  const mmEf = (l: Linha) => l.n.mm ?? l.mmMatriculas
  let acumulado = 0
  const acumulados = linhas.map((l) => (acumulado += l.tem ? l.n.oferta || 0 : 0))
  const soma = (f: (l: Linha) => number) => comDados.reduce((s, l) => s + (f(l) || 0), 0)
  const media = (f: (l: Linha) => number) => (comDados.length ? soma(f) / comDados.length : null)
  const somaMM = soma(mmEf), somaMP = soma((l) => l.n.mp ?? 0), somaED = soma((l) => l.n.ed ?? 0)
  const totalOfertas = soma((l) => l.n.oferta)
  const alvoTotal = alvo * comDados.length
  const porRegistar = linhas.filter((l) => !l.r && !l.futuro).length

  const comecar = (l: Linha) => {
    if (edicao && edicao.sabadoId !== l.s.id && !window.confirm('Há outro sábado a ser editado. Descartar essas alterações?')) return
    const v = valoresDe(l.r)
    if (!l.r && v.mm === '') v.mm = String(l.mmMatriculas)
    setEdicao({ sabadoId: l.s.id, v })
    setTimeout(() => document.querySelector<HTMLInputElement>(`input[data-folha="${l.s.id}-mp"]`)?.focus(), 30)
  }
  const mudar = (col: Col, valor: string) => setEdicao((e) => e && { ...e, v: { ...e.v, [col]: valor }, erro: undefined })

  const guardar = async (l: Linha) => {
    if (!edicao) return
    const v = edicao.v
    const num = { mm: inteiro(v.mm), mp: inteiro(v.mp), ed: inteiro(v.ed), vis: inteiro(v.vis), fil: inteiro(v.fil) }
    const din = { oferta: dinheiroParaApi(v.oferta || '0'), o13: dinheiroParaApi(v.o13 || '0'), desp: dinheiroParaApi(v.desp || '0') }
    if (Object.values(num).some((x) => Number.isNaN(x)) || Object.values(din).some((x) => x == null)) {
      setEdicao({ ...edicao, erro: 'Há um valor inválido: só números; ofertas como 500 ou 500,50.' })
      return
    }
    try {
      await gravar.mutateAsync({
        sabadoId: l.s.id, relatorioId: l.r?.id, comChamada: l.comChamada,
        membrosMatriculados: num.mm ?? undefined, membrosPresentes: num.mp ?? 0, estudoDiario: num.ed ?? 0,
        visitantes: num.vis ?? 0, filiais: num.fil ?? 0, oferta: din.oferta!, oferta13Sabado: din.o13!, ofertaDespesas: din.desp!,
      })
      toast.success(`${l.s.numero}.º sábado gravado.`)
      setEdicao(null)
    } catch (e) {
      setEdicao({ ...edicao, erro: mensagemDe(e) })
    }
  }

  const teclas = (e: KeyboardEvent<HTMLInputElement>, l: Linha) => {
    if (e.key === 'Enter') { e.preventDefault(); void guardar(l) }
    if (e.key === 'Escape') { e.preventDefault(); setEdicao(null) }
  }

  const celula = (l: Linha, col: Col) => {
    const so = (col === 'mp' || col === 'ed') && l.comChamada
    const inteira = COLS_INTEIRAS.includes(col)
    if (l.aEditar && !so) {
      const invalido = inteira ? Number.isNaN(inteiro(l.v[col])) : l.v[col].trim() !== '' && dinheiroParaApi(l.v[col]) == null
      return (
        <td className="p-1!">
          <input data-folha={`${l.s.id}-${col}`} aria-label={`${ROTULO[col]} do ${l.s.numero}.º sábado`} value={l.v[col]} autoComplete="off"
            inputMode={inteira ? 'numeric' : 'decimal'} placeholder={inteira ? '0' : '0,00'}
            onChange={(e) => mudar(col, e.target.value.replace(inteira ? /\D/g : /[^\d\s.,]/g, ''))}
            onFocus={(e) => e.target.select()} onKeyDown={(e) => teclas(e, l)}
            className={cn('h-9 w-full min-w-0 rounded-md border border-input bg-card px-2 text-right text-sm font-semibold tabular-nums shadow-sm outline-none',
              'focus:border-ring focus:ring-2 focus:ring-ring/30', invalido && 'border-destructive bg-tint-destructive')} />
        </td>
      )
    }
    const texto = !l.tem ? '' : inteira ? l.v[col] || '0' : l.v[col] || '0,00'
    return (
      <td className={cn('num tabular-nums', so && 'italic')} title={so ? 'Contado pela chamada nominal' : undefined}>
        {texto}
      </td>
    )
  }

  /** Estado e acção da linha: Registar (por registar), Editar, abrir o sábado; Guardar / Cancelar ao editar. */
  const accoes = (l: Linha) => {
    if (l.aEditar) {
      return (
        <span className="flex items-center gap-1">
          <Button size="sm" className="h-8" disabled={gravar.isPending} onClick={() => void guardar(l)}><Check className="size-4" />{gravar.isPending ? 'A gravar…' : 'Guardar'}</Button>
          <Button size="icon" variant="ghost" className="size-8" aria-label="Cancelar" onClick={() => setEdicao(null)}><X className="size-4" /></Button>
        </span>
      )
    }
    if (!l.r && l.editavel) {
      return <Button size="sm" variant="outline" className="h-8 border-warning/50 bg-tint-warning px-2.5 text-warning-text hover:bg-warning/20" onClick={() => comecar(l)}><Plus className="size-3.5" />Registar</Button>
    }
    return (
      <span className="flex items-center gap-0.5">
        {estado(l)}
        {l.editavel && l.r && (
          <Tooltip><TooltipTrigger asChild><Button size="icon" variant="ghost" className="size-8" aria-label={`Editar o ${l.s.numero}.º sábado`} onClick={() => comecar(l)}><Pencil className="size-4" /></Button></TooltipTrigger><TooltipContent>Editar os números</TooltipContent></Tooltip>
        )}
        {l.r && (
          <Tooltip><TooltipTrigger asChild>
            <Button asChild size="icon" variant="ghost" className="size-8"><Link to={`/escola-sabatina/sabado/${ct.id}/${l.s.id}`} aria-label={`Abrir o ${l.s.numero}.º sábado`}><ExternalLink className="size-4" /></Link></Button>
          </TooltipTrigger><TooltipContent>Abrir o sábado completo: chamada, visitantes, tesouraria e fecho</TooltipContent></Tooltip>
        )}
      </span>
    )
  }

  const estado = (l: Linha) =>
    l.fechado ? <Pilula variante="success"><Lock className="size-3" />Fechado</Pilula>
      : l.r ? <Pilula variante="info">Aberto</Pilula>
      : l.futuro ? <Pilula variante="outline" className="text-muted-foreground">Futuro</Pilula>
      : <Pilula variante="warning">Por registar</Pilula>

  return (
    <div className="grid gap-3">
      <div className="flex flex-wrap items-center justify-between gap-3 print:hidden">
        <p className="text-sm text-muted-foreground">
          {inactiva ? 'Classe desactivada neste trimestre: a folha é só de leitura.'
            : porRegistar ? <><strong className="font-semibold text-warning-text">{porRegistar} sábado(s) por registar.</strong> Carregue em <strong className="font-semibold">Registar</strong> na linha do sábado, escreva os números e Guardar (ou Enter).</>
            : 'Todos os sábados que já passaram estão registados. Para corrigir um sábado aberto, use Editar.'}
        </p>
        <Button variant="outline" size="sm" onClick={() => imprimirComo(`Folha ${classe.nome} ${nomeTrimestre(trimestre)}`)}><Printer className="size-4" />Imprimir</Button>
      </div>

      <Folha minimo="min-w-[72rem]" className="[&_tbody_td]:px-2! [&_thead_th]:px-2! [&_tfoot_td]:px-2!">
        <thead>
          <tr>
            <th rowSpan={2} className="w-14 centro">Sáb.</th>
            <th rowSpan={2} className="text-left">Data</th>
            <th rowSpan={2} className="w-40 text-left print:hidden">Estado</th>
            <th rowSpan={2} className="num w-20" title="Membros matriculados">M.M.</th>
            <th rowSpan={2} className="num w-20" title="Membros presentes">M.P.</th>
            <th rowSpan={2} className="num">% Presença</th>
            <th rowSpan={2} className="num w-20" title="Estudo diário">E.D.</th>
            <th rowSpan={2} className="num">% E.D.</th>
            <th rowSpan={2} className="num w-20">Visit.</th>
            <th colSpan={4} className="centro">Ofertas missionárias (MT)</th>
            <th colSpan={2} className="centro">Outras ofertas (MT)</th>
            <th rowSpan={2} className="num w-16">Fil.</th>
          </tr>
          <tr>
            <th className="num w-28">Por sáb.</th><th className="num">Alvo</th><th className="num">Total</th><th className="num">% do alvo</th>
            <th className="num w-28">13.º sáb.</th><th className="num w-28">Despesas ES</th>
          </tr>
        </thead>
        <tbody>
          {linhas.map((l, i) => {
            const mm = mmEf(l), mp = l.n.mp ?? 0, ed = l.n.ed ?? 0
            return (
              <tr key={l.s.id} className={cn(l.futuro && 'text-muted-foreground', l.aEditar && 'bg-tint-info/60 [&_td:first-child]:bg-tint-info/60',
                !l.tem && !l.futuro && !l.aEditar && '[&_td]:bg-tint-warning/25')}>
                <td className="centro tabular-nums font-semibold">
                  {String(l.s.numero).padStart(2, '0')}
                  {l.s.decimoTerceiro && <span className="ml-1 rounded bg-tint-warning px-1 text-[10px] text-warning-text" title="13.º sábado">13.º</span>}
                </td>
                <td className="whitespace-nowrap tabular-nums">{data(l.s.data)}</td>
                <td className="print:hidden">{accoes(l)}</td>
                {celula(l, 'mm')}
                {celula(l, 'mp')}
                {l.tem ? <CelulaPct v={mm ? mp / mm : null} /> : <td />}
                {celula(l, 'ed')}
                {l.tem ? <CelulaPct v={mp ? ed / mp : null} /> : <td />}
                {celula(l, 'vis')}
                {celula(l, 'oferta')}
                <td className="num tabular-nums text-muted-foreground">{textoMT(alvo)}</td>
                <td className="num tabular-nums">{l.tem ? textoMT(acumulados[i]) : ''}</td>
                {l.tem ? <CelulaPct v={alvo ? l.n.oferta / alvo : null} tipo="alvo" /> : <td />}
                {celula(l, 'o13')}
                {celula(l, 'desp')}
                {celula(l, 'fil')}
              </tr>
            )
          })}
          {edicao?.erro && (
            <tr data-fixa>
              <td colSpan={17} className="bg-tint-destructive! text-sm text-destructive-text">
                <span className="flex items-center gap-2"><AlertCircle className="size-4 flex-none" />{linhas.find((l) => l.aEditar)?.s.numero}.º sábado: {edicao.erro}</span>
              </td>
            </tr>
          )}
        </tbody>
        <tfoot>
          <tr>
            <td colSpan={3}>Total / média</td>
            <td className="num tabular-nums">{textoNum(media(mmEf))}</td>
            <td className="num tabular-nums">{textoNum(media((l) => l.n.mp ?? 0))}</td>
            <CelulaPct v={somaMM ? somaMP / somaMM : null} />
            <td className="num tabular-nums">{textoNum(media((l) => l.n.ed ?? 0))}</td>
            <CelulaPct v={somaMP ? somaED / somaMP : null} />
            <td className="num tabular-nums">{soma((l) => l.n.vis ?? 0)}</td>
            <td className="num tabular-nums">{textoMT(totalOfertas)}</td>
            <td className="num tabular-nums">{textoMT(alvoTotal)}</td>
            <td className="num tabular-nums">{textoMT(totalOfertas)}</td>
            <CelulaPct v={alvoTotal ? totalOfertas / alvoTotal : null} tipo="alvo" />
            <td className="num tabular-nums">{textoMT(soma((l) => l.n.o13))}</td>
            <td className="num tabular-nums">{textoMT(soma((l) => l.n.desp))}</td>
            <td className="num tabular-nums">{textoNum(media((l) => l.n.fil ?? 0))}</td>
          </tr>
        </tfoot>
      </Folha>
      <p className="text-xs text-muted-foreground">
        M.M. = membros matriculados · M.P. = membros presentes · E.D. = estudo diário · % Presença = M.P. ÷ M.M. · % E.D. = E.D. ÷ M.P. ·
        % do alvo = oferta do sábado ÷ alvo ({textoMT(alvo)}) · Total = ofertas acumuladas · {textoPct(linhas.length ? comDados.length / linhas.length : null, 0)} dos sábados registados.
        Números em itálico: contados pela chamada nominal.
      </p>
    </div>
  )
}
