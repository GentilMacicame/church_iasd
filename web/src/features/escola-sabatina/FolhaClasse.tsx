/**
 * Folha da classe no trimestre (a folha "Grupo N" do quadro): uma linha por sábado com M.M. (membros
 * matriculados), M.P. (membros presentes), % de presença, E.D. (estudo diário), % de E.D., visitantes, a oferta
 * missionária do sábado com o alvo, o total acumulado e a % do alvo, as ofertas do 13.º sábado e das despesas da
 * ES, e as filiais; por baixo, o total / média do trimestre.
 *
 * Escreve-se directamente nas células (Enter ou ↓ desce, ↑ sobe), como na folha de cálculo; "Guardar" grava os
 * sábados alterados (cria ou altera o relatório). As regras são da base de dados: um relatório fechado não muda,
 * presentes não passam os matriculados; cada recusa aparece na linha. Sábados com chamada nominal contam M.P. e
 * E.D. pela chamada (no ecrã do sábado).
 */
import { useEffect, useMemo, useRef, useState, type KeyboardEvent } from 'react'
import { Link } from 'react-router-dom'
import { AlertCircle, CheckCircle2, ExternalLink, Lock, Printer, Save, Undo2 } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Tooltip, TooltipContent, TooltipTrigger } from '@/components/ui/tooltip'
import { EstadoErro, LinhasACarregar } from '@/components/comum/estados'
import { useSessao } from '@/auth/sessao'
import { mensagemDe } from '@/api/erros'
import { data, dinheiroParaApi, hojeIso } from '@/lib/formatos'
import { imprimirComo } from '@/lib/documentos'
import { cn } from '@/lib/utils'
import {
  matriculadoEm, nomeTrimestre, useComChamada, useGravarLinhaFolha, useMatriculas, useRelatoriosClasse, useSabados,
  type Classe, type ClasseTrimestre, type Relatorio, type Sabado, type Trimestre,
} from './api'
import { CelulaPct, Folha, textoMT, textoNum, textoPct } from './componentes'

type Col = 'mm' | 'mp' | 'ed' | 'vis' | 'oferta' | 'o13' | 'desp' | 'fil'
const COLS_INTEIRAS: Col[] = ['mm', 'mp', 'ed', 'vis', 'fil']
type Valores = Record<Col, string>

const dinheiroEcra = (api?: string | null) => {
  if (api == null || api === '' || Number(api) === 0) return ''
  return Number(api).toLocaleString('pt-PT', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).replace(/[\u00a0\u202f]/g, ' ')
}
const valoresDe = (r?: Relatorio): Valores => r ? {
  mm: String(r.membrosMatriculados), mp: String(r.membrosPresentes), ed: String(r.estudoDiario), vis: String(r.visitantes),
  oferta: dinheiroEcra(r.oferta), o13: dinheiroEcra(r.oferta13Sabado), desp: dinheiroEcra(r.ofertaDespesas), fil: String(r.filiais),
} : { mm: '', mp: '', ed: '', vis: '', oferta: '', o13: '', desp: '', fil: '' }
const inteiro = (t: string) => (t.trim() === '' ? null : /^\d+$/.test(t.trim()) ? Number(t.trim()) : NaN)
const mt = (t: string) => (t.trim() === '' ? 0 : Number(dinheiroParaApi(t) ?? NaN))

/** Célula editável, discreta até ter o foco (aspecto de folha de cálculo). */
function Entrada({ linha, col, valor, aoMudar, desactivado, invalido, rotulo, dinheiro }: {
  linha: number; col: Col; valor: string; aoMudar: (v: string) => void; desactivado?: boolean; invalido?: boolean; rotulo: string; dinheiro?: boolean
}) {
  const mover = (e: KeyboardEvent<HTMLInputElement>, passo: number) => {
    const alvo = document.querySelector<HTMLInputElement>(`input[data-folha="${linha + passo}-${col}"]:not(:disabled)`)
    if (alvo) { e.preventDefault(); alvo.focus(); alvo.select() }
  }
  return (
    <input
      data-folha={`${linha}-${col}`} aria-label={rotulo} value={valor} disabled={desactivado} inputMode={dinheiro ? 'decimal' : 'numeric'} autoComplete="off"
      onChange={(e) => aoMudar(e.target.value.replace(dinheiro ? /[^\d\s.,]/g : /\D/g, ''))}
      onFocus={(e) => e.target.select()}
      onKeyDown={(e) => { if (e.key === 'Enter' || e.key === 'ArrowDown') mover(e, 1); else if (e.key === 'ArrowUp') mover(e, -1) }}
      className={cn(
        // célula de entrada visível (fundo azul claro, texto azul, como no quadro); desactivada = texto normal
        'h-8 w-full min-w-0 rounded-md border border-primary/15 bg-primary/[0.05] px-1.5 text-right text-sm font-medium tabular-nums text-primary outline-none transition-colors',
        'hover:border-primary/40 focus:border-ring focus:bg-card focus:ring-2 focus:ring-ring/30',
        'disabled:cursor-default disabled:border-transparent disabled:bg-transparent disabled:font-normal disabled:text-foreground',
        invalido && 'border-destructive/60 bg-tint-destructive',
      )}
    />
  )
}

export function FolhaClasse({ classe, ct, trimestre }: { classe: Classe; ct: ClasseTrimestre; trimestre: Trimestre }) {
  const { pode } = useSessao()
  const sabados = useSabados(trimestre.id)
  const rels = useRelatoriosClasse(ct.id)
  const matriculas = useMatriculas(classe.id)
  const ids = useMemo(() => (rels.data ?? []).map((r) => r.id).sort((a, b) => a - b), [rels.data])
  const chamada = useComChamada(ids)
  const gravar = useGravarLinhaFolha(ct.id)
  const [editado, setEditado] = useState<Record<number, Valores>>({})
  const [erros, setErros] = useState<Record<number, string>>({})
  const [aGuardar, setAGuardar] = useState(false)
  const hoje = hojeIso()
  const podeCriar = pode('escola_sabatina.relatorio_sabado.criar')
  const podeAlterar = pode('escola_sabatina.relatorio_sabado.alterar')
  const alvo = Number(ct.alvoOfertaSabado ?? 0)
  const relDe = useMemo(() => new Map((rels.data ?? []).map((r) => [r.sabadoId, r])), [rels.data])
  const inactiva = ct.estado === 'INACTIVO'

  // ao sair da página com alterações por guardar, avisa
  const porGuardar = Object.keys(editado).length
  const avisar = useRef(porGuardar)
  avisar.current = porGuardar
  useEffect(() => {
    const f = (e: BeforeUnloadEvent) => { if (avisar.current) { e.preventDefault(); e.returnValue = '' } }
    window.addEventListener('beforeunload', f)
    return () => window.removeEventListener('beforeunload', f)
  }, [])

  if (sabados.isError || rels.isError) return <EstadoErro erro={sabados.error ?? rels.error} aoTentar={() => { void sabados.refetch(); void rels.refetch() }} />
  if (sabados.isPending || rels.isPending) return <LinhasACarregar linhas={8} />
  if (!sabados.data.length) return <p className="py-6 text-sm text-muted-foreground">O {nomeTrimestre(trimestre)} ainda não tem sábados. A Associação cria-os em Trimestres.</p>

  const linhas = sabados.data.map((s) => {
    const r = relDe.get(s.id)
    const v = editado[s.id] ?? valoresDe(r)
    const mmMatriculas = (matriculas.data ?? []).filter((m) => matriculadoEm(m, s.data)).length
    const comChamada = !!r && !!chamada.data?.has(r.id)
    const fechado = r?.estado === 'FECHADO'
    const futuro = s.data > hoje
    const editavel = !fechado && !futuro && !inactiva && (r ? podeAlterar : podeCriar)
    const n = { mm: inteiro(v.mm), mp: inteiro(v.mp), ed: inteiro(v.ed), vis: inteiro(v.vis), fil: inteiro(v.fil), oferta: mt(v.oferta), o13: mt(v.o13), desp: mt(v.desp) }
    const tem = !!r || Object.values(v).some((x) => x.trim() !== '')
    return { s, r, v, n, mmMatriculas, comChamada, fechado, futuro, editavel, tem }
  })

  // totais e médias do trimestre (só os sábados com dados), como na linha "TOTAL / MÉDIA"
  const comDados = linhas.filter((l) => l.tem)
  const mmEf = (l: (typeof linhas)[number]) => l.n.mm ?? l.mmMatriculas
  let acumulado = 0
  const acumulados = linhas.map((l) => (acumulado += l.tem ? l.n.oferta || 0 : 0))
  const soma = (f: (l: (typeof linhas)[number]) => number) => comDados.reduce((s, l) => s + (f(l) || 0), 0)
  const media = (f: (l: (typeof linhas)[number]) => number) => (comDados.length ? soma(f) / comDados.length : null)
  const somaMM = soma(mmEf), somaMP = soma((l) => l.n.mp ?? 0), somaED = soma((l) => l.n.ed ?? 0)
  const totalOfertas = soma((l) => l.n.oferta)
  // alvo dos sábados registados (como a % do alvo do resumo, vw_resumo_classe)
  const alvoTotal = alvo * comDados.length

  const mudar = (s: Sabado, col: Col, valor: string) => {
    setEditado((x) => ({ ...x, [s.id]: { ...(x[s.id] ?? valoresDe(relDe.get(s.id))), [col]: valor } }))
    setErros((x) => { const resto = { ...x }; delete resto[s.id]; return resto })
  }

  const guardar = async () => {
    setAGuardar(true)
    let ok = 0
    const novosErros: Record<number, string> = {}
    for (const [sid, v] of Object.entries(editado)) {
      const l = linhas.find((x) => x.s.id === Number(sid))!
      const num = { mm: inteiro(v.mm), mp: inteiro(v.mp), ed: inteiro(v.ed), vis: inteiro(v.vis), fil: inteiro(v.fil) }
      const din = { oferta: dinheiroParaApi(v.oferta || '0'), o13: dinheiroParaApi(v.o13 || '0'), desp: dinheiroParaApi(v.desp || '0') }
      if (Object.values(num).some((x) => Number.isNaN(x)) || Object.values(din).some((x) => x == null)) {
        novosErros[l.s.id] = 'Há um valor inválido nesta linha (só números; ofertas como 500 ou 500,50).'
        continue
      }
      if (!l.r && Object.values(v).every((x) => x.trim() === '')) continue
      try {
        await gravar.mutateAsync({
          sabadoId: l.s.id, relatorioId: l.r?.id, comChamada: l.comChamada,
          membrosMatriculados: num.mm ?? undefined, membrosPresentes: num.mp ?? 0, estudoDiario: num.ed ?? 0,
          visitantes: num.vis ?? 0, filiais: num.fil ?? 0, oferta: din.oferta!, oferta13Sabado: din.o13!, ofertaDespesas: din.desp!,
        })
        ok++
        setEditado((x) => { const resto = { ...x }; delete resto[l.s.id]; return resto })
      } catch (e) {
        novosErros[l.s.id] = mensagemDe(e)
      }
    }
    setErros(novosErros)
    setAGuardar(false)
    const nErros = Object.keys(novosErros).length
    if (ok) toast.success(`${ok} sábado(s) gravado(s).`)
    if (nErros) toast.error(`${nErros} sábado(s) não gravado(s): veja a mensagem na linha.`)
  }

  const ROTULO: Record<Col, string> = { mm: 'M.M.', mp: 'M.P.', ed: 'E.D.', vis: 'Visitantes', oferta: 'Oferta do sábado', o13: '13.º sábado', desp: 'Despesas da ES', fil: 'Filiais' }
  const celula = (l: (typeof linhas)[number], i: number, col: Col) => {
    const so = (col === 'mp' || col === 'ed') && l.comChamada
    const invalido = COLS_INTEIRAS.includes(col) ? Number.isNaN(inteiro(l.v[col])) : l.v[col].trim() !== '' && dinheiroParaApi(l.v[col]) == null
    return (
      <td className="p-0.5!">
        {so ? (
          <Tooltip><TooltipTrigger asChild><span className="block px-1.5 text-right tabular-nums">{l.v[col]}</span></TooltipTrigger>
            <TooltipContent>Contado pela chamada nominal</TooltipContent></Tooltip>
        ) : (
          <Entrada linha={i} col={col} valor={col === 'mm' && l.v.mm === '' && !l.r ? '' : l.v[col]} aoMudar={(x) => mudar(l.s, col, x)}
            desactivado={!l.editavel} invalido={invalido} rotulo={`${ROTULO[col]} do ${l.s.numero}.º sábado`} dinheiro={!COLS_INTEIRAS.includes(col)} />
        )}
      </td>
    )
  }

  return (
    <div className="grid gap-3">
      <div className="flex flex-wrap items-center justify-between gap-3 print:hidden">
        <p className="text-sm text-muted-foreground">
          {inactiva ? 'Classe desactivada neste trimestre: a folha é só de leitura.'
            : 'Escreva nas células azuis; Enter passa ao sábado seguinte. M.M. vazio = contado pelas matrículas.'}
        </p>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={() => imprimirComo(`Folha ${classe.nome} ${nomeTrimestre(trimestre)}`)}><Printer className="size-4" />Imprimir</Button>
          {porGuardar > 0 && <Button variant="ghost" size="sm" onClick={() => { setEditado({}); setErros({}) }}><Undo2 className="size-4" />Desfazer</Button>}
          {(podeCriar || podeAlterar) && !inactiva && (
            <Button size="sm" disabled={!porGuardar || aGuardar} onClick={() => void guardar()}>
              <Save className="size-4" />{aGuardar ? 'A gravar…' : porGuardar ? `Guardar ${porGuardar} sábado(s)` : 'Guardado'}
            </Button>
          )}
        </div>
      </div>

      <Folha minimo="min-w-[72rem]">
        <thead>
          <tr>
            <th rowSpan={2} className="w-14 centro">Sáb.</th>
            <th rowSpan={2} className="text-left">Data</th>
            <th rowSpan={2} className="num w-20" title="Membros matriculados">M.M.</th>
            <th rowSpan={2} className="num w-20" title="Membros presentes">M.P.</th>
            <th rowSpan={2} className="num">% Presença</th>
            <th rowSpan={2} className="num w-20" title="Estudo diário">E.D.</th>
            <th rowSpan={2} className="num">% E.D.</th>
            <th rowSpan={2} className="num w-20">Visit.</th>
            <th colSpan={4} className="centro">Ofertas missionárias (MT)</th>
            <th colSpan={2} className="centro">Outras ofertas (MT)</th>
            <th rowSpan={2} className="num w-16">Fil.</th>
            <th rowSpan={2} className="w-20 centro">Estado</th>
          </tr>
          <tr>
            <th className="num w-28">Por sáb.</th><th className="num">Alvo</th><th className="num">Total</th><th className="num">% do alvo</th>
            <th className="num w-28">13.º sáb.</th><th className="num w-28">Despesas ES</th>
          </tr>
        </thead>
        <tbody>
          {linhas.map((l, i) => {
            const mm = mmEf(l), mp = l.n.mp ?? 0, ed = l.n.ed ?? 0
            const erro = erros[l.s.id]
            return (
              <tr key={l.s.id} className={cn(!l.tem && !l.editavel && 'text-muted-foreground', editado[l.s.id] && 'bg-tint-info/40', erro && 'bg-tint-destructive/60',
                l.s.decimoTerceiro && '[&_td:first-child]:font-bold')}>
                <td className="centro tabular-nums font-semibold">
                  {String(l.s.numero).padStart(2, '0')}
                  {l.s.decimoTerceiro && <span className="ml-1 rounded bg-tint-warning px-1 text-[10px] text-warning-text" title="13.º sábado">13.º</span>}
                </td>
                <td className="whitespace-nowrap tabular-nums text-muted-foreground">{data(l.s.data)}</td>
                {celula(l, i, 'mm')}
                {celula(l, i, 'mp')}
                {l.tem ? <CelulaPct v={mm ? mp / mm : null} /> : <td className="num text-muted-foreground">—</td>}
                {celula(l, i, 'ed')}
                {l.tem ? <CelulaPct v={mp ? ed / mp : null} /> : <td className="num text-muted-foreground">—</td>}
                {celula(l, i, 'vis')}
                {celula(l, i, 'oferta')}
                <td className="num tabular-nums text-muted-foreground">{textoMT(alvo)}</td>
                <td className="num tabular-nums">{l.tem ? textoMT(acumulados[i]) : '—'}</td>
                {l.tem ? <CelulaPct v={alvo ? l.n.oferta / alvo : null} tipo="alvo" /> : <td className="num text-muted-foreground">—</td>}
                {celula(l, i, 'o13')}
                {celula(l, i, 'desp')}
                {celula(l, i, 'fil')}
                <td className="centro">
                  <span className="inline-flex items-center gap-1">
                    {erro ? (
                      <Tooltip><TooltipTrigger asChild><AlertCircle className="size-4 text-destructive-text" aria-label={erro} /></TooltipTrigger><TooltipContent className="max-w-72">{erro}</TooltipContent></Tooltip>
                    ) : l.fechado ? <Lock className="size-4 text-success-text" aria-label="Fechado" />
                      : l.r ? <CheckCircle2 className="size-4 text-primary" aria-label="Registado" /> : null}
                    {!l.futuro && (
                      <Tooltip><TooltipTrigger asChild>
                        <Link to={`/escola-sabatina/sabado/${ct.id}/${l.s.id}`} className="text-muted-foreground hover:text-primary" aria-label={`Abrir o ${l.s.numero}.º sábado`}><ExternalLink className="size-4" /></Link>
                      </TooltipTrigger><TooltipContent>Abrir o sábado: chamada, visitantes, tesouraria e fecho</TooltipContent></Tooltip>
                    )}
                  </span>
                </td>
              </tr>
            )
          })}
        </tbody>
        <tfoot>
          <tr>
            <td colSpan={2}>Total / média</td>
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
            <td />
          </tr>
        </tfoot>
      </Folha>
      <p className="text-xs text-muted-foreground">
        % Presença = M.P. ÷ M.M. · % E.D. = E.D. ÷ M.P. · % do alvo = oferta do sábado ÷ alvo ({textoMT(alvo)}) ·
        Total = ofertas acumuladas · {textoPct(comDados.length / linhas.length, 0)} dos sábados registados.
        Cores: verde ≥ 85% (alvo ≥ 100%), âmbar ≥ 75% (alvo ≥ 90%), vermelho abaixo.
      </p>
    </div>
  )
}
