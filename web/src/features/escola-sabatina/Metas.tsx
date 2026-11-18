/**
 * Escola Sabatina (V47) · metas e programas especiais:
 *  - MetasDaClasse: a meta de cada aluno no trimestre (editável), o que deu na chamada e o cumprimento; a meta da
 *    classe é a soma e o contribuído da classe vem dos relatórios do sábado (o identificado é a parte dada por aluno);
 *  - MetasDasClasses: as classes do trimestre lado a lado (meta, contribuído, cumprimento);
 *  - SemanasEspeciais: semana de oração, da família, de evangelismo… (as próximas ficam em destaque e geram alertas).
 */
import { useState } from 'react'
import { Link } from 'react-router-dom'
import { CalendarHeart, Plus, Target, Trash2 } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Pilula, Tabela } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { CampoData } from '@/components/comum/CampoData'
import { Seleccao } from '@/components/comum/Seleccao'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { data, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { textoMT, textoPct } from './componentes'
import {
  TIPOS_SEMANA, semanasProximas, useGravarMeta, useMetasAlunos, useMetasClasses, useSemanasEspeciais, useSemanasMut,
  type LinhaMetaAluno, type SemanaEspecial, type TipoSemana,
} from './apiMetas'
import type { Trimestre } from './api'

const num = (v?: string | number | null) => Number(v ?? 0) || 0
const razao = (a: number, b: number) => (b > 0 ? a / b : null)

/** Barra de cumprimento: verde a partir de 100%, amarela a meio, cinzenta no início. */
function Cumprimento({ v }: { v: number | null }) {
  if (v == null) return <span className="text-muted-foreground">—</span>
  const pct = Math.min(1, v)
  return (
    <span className="flex items-center gap-2">
      <span className="h-1.5 w-20 overflow-hidden rounded-full bg-muted" aria-hidden>
        <span className={cn('block h-full rounded-full', v >= 1 ? 'bg-success' : v >= 0.5 ? 'bg-warning' : 'bg-[var(--serie-1)]')} style={{ width: `${pct * 100}%` }} />
      </span>
      <span className="w-12 text-right text-xs tabular-nums">{textoPct(v, 0)}</span>
    </span>
  )
}

/* ---------------------------------------------------------------- metas de uma classe */
export function MetasDaClasse({ trimestre, classeTrimestre }: { trimestre: Trimestre; classeTrimestre: number }) {
  const { pode } = useSessao()
  const q = useMetasAlunos(trimestre.id, classeTrimestre)
  const qc = useMetasClasses(trimestre.id)
  const gravar = useGravarMeta()
  const [todos, setTodos] = useState('')
  const podeGravar = pode('escola_sabatina.meta_individual.criar') && pode('escola_sabatina.meta_individual.alterar')
  const classe = qc.data?.find((c) => c.classeTrimestreId === classeTrimestre)
  const lista = q.data ?? []
  const meta = num(classe?.meta), contribuido = num(classe?.contribuido), identificado = num(classe?.identificado)

  const guardar = (a: LinhaMetaAluno, valor: string) => {
    if (!/^\d{1,10}(\.\d{1,2})?$/.test(valor) || valor === (a.meta ?? '')) return
    gravar.mutate({ metaId: a.metaId, classeTrimestreId: classeTrimestre, membroId: a.membroId, valor }, { onError: (e) => toast.error(mensagemDe(e)) })
  }
  const aplicarATodos = async () => {
    if (!/^\d{1,10}(\.\d{1,2})?$/.test(todos)) return toast.error('Escreva a meta, por exemplo 500,00.')
    try {
      for (const a of lista) await gravar.mutateAsync({ metaId: a.metaId, classeTrimestreId: classeTrimestre, membroId: a.membroId, valor: todos })
      toast.success(`Meta de ${textoMT(todos)} para os ${lista.length} alunos.`)
      setTodos('')
    } catch (e) { toast.error(mensagemDe(e)) }
  }

  return (
    <div className="grid gap-5">
      <dl className="grid grid-cols-2 overflow-hidden rounded-xl border bg-card shadow-card lg:grid-cols-4">
        {[['Meta da classe', textoMT(meta), `soma das metas de ${classe?.comMeta ?? 0} aluno(s) · ${textoMT(meta / (trimestre.numSabados || 13))} por sábado`],
          ['Contribuído', textoMT(contribuido), `oferta missionária em ${classe?.sabadosComRelatorio ?? 0} de ${trimestre.numSabados} sábados`],
          ['Identificado por aluno', textoMT(identificado), contribuido ? `${textoPct(razao(identificado, contribuido), 0)} do contribuído` : 'na chamada nominal'],
          ['Cumprimento', meta ? textoPct(razao(contribuido, meta), 0) : '—', 'contribuído ÷ meta da classe']].map(([r, v, n]) => (
          <div key={r} className="border-r border-b px-4 py-3">
            <dt className="text-[11px] font-semibold tracking-wide text-muted-foreground uppercase">{r}</dt>
            <dd className="mt-1 text-lg font-semibold tabular-nums">{v}</dd>
            <dd className="text-xs text-muted-foreground">{n}</dd>
          </div>
        ))}
      </dl>

      <Cartao titulo="Metas individuais" descricao="Meta de cada aluno no trimestre e o que já deu" icone={Target} semMargem
        accoes={podeGravar && lista.length > 0 && (
          <div className="flex items-center gap-2">
            <CampoDinheiro value={todos} onChange={setTodos} aria-label="Meta para todos" className="h-9 w-32" />
            <Button size="sm" variant="outline" disabled={gravar.isPending} onClick={aplicarATodos}>Aplicar a todos</Button>
          </div>
        )}>
        {q.isPending ? <LinhasACarregar linhas={4} />
          : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="m-4" />
          : lista.length === 0 ? <EstadoVazio icone={Target}>Ainda ninguém matriculado nesta classe.</EstadoVazio>
          : (
            <Tabela>
              <thead><tr><th className="sm:pl-6">Aluno</th><th className="num">Meta do trimestre</th><th className="num">Contribuído</th><th className="hidden num sm:table-cell">Presenças</th><th className="sm:pr-6">Cumprimento</th></tr></thead>
              <tbody>
                {lista.map((a) => (
                  <tr key={a.membroId}>
                    <td className="sm:pl-6"><Link to={`/membros/${a.membroId}`} className="font-medium hover:text-primary">{a.nome}</Link></td>
                    <td className="num">
                      {podeGravar
                        ? <CampoMeta valor={a.meta ?? ''} aoGuardar={(v) => guardar(a, v)} rotulo={`Meta de ${a.nome}`} />
                        : a.meta ? textoMT(a.meta) : '—'}
                    </td>
                    <td className="num">{textoMT(a.contribuido)}</td>
                    <td className="hidden num sm:table-cell">{a.presencas}</td>
                    <td className="sm:pr-6"><Cumprimento v={a.cumprimento == null ? null : num(a.cumprimento)} /></td>
                  </tr>
                ))}
              </tbody>
            </Tabela>
          )}
      </Cartao>
    </div>
  )
}

/** Meta editável: grava ao sair do campo (ou Enter). */
function CampoMeta({ valor, aoGuardar, rotulo }: { valor: string; aoGuardar: (v: string) => void; rotulo: string }) {
  const [v, setV] = useState(valor)
  return (
    <span className="inline-block" onBlur={() => aoGuardar(v)} onKeyDown={(e) => { if (e.key === 'Enter') aoGuardar(v) }}>
      <CampoDinheiro value={v} onChange={setV} aria-label={rotulo} className="ml-auto h-8 w-32 text-sm" />
    </span>
  )
}

/* ---------------------------------------------------------------- as classes lado a lado */
export function MetasDasClasses({ trimestre }: { trimestre?: Trimestre }) {
  const q = useMetasClasses(trimestre?.id)
  const lista = [...(q.data ?? [])].sort((a, b) => (razao(num(b.contribuido), num(b.meta)) ?? -1) - (razao(num(a.contribuido), num(a.meta)) ?? -1))
  const meta = lista.reduce((s, c) => s + num(c.meta), 0), contribuido = lista.reduce((s, c) => s + num(c.contribuido), 0)
  return (
    <Cartao titulo="Metas das classes" descricao={`Oferta missionária no trimestre: ${textoMT(contribuido)} de ${textoMT(meta)} (${meta ? textoPct(razao(contribuido, meta), 0) : '—'})`} icone={Target} semMargem>
      {q.isPending ? <LinhasACarregar linhas={4} />
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="m-4" />
        : lista.length === 0 ? <EstadoVazio icone={Target}>Sem classes configuradas neste trimestre.</EstadoVazio>
        : (
          <Tabela>
            <thead><tr><th className="sm:pl-6">Classe</th><th className="hidden num sm:table-cell">Alunos com meta</th><th className="num">Meta</th><th className="num">Contribuído</th><th className="sm:pr-6">Cumprimento</th></tr></thead>
            <tbody>
              {lista.map((c) => (
                <tr key={c.classeTrimestreId}>
                  <td className="font-medium sm:pl-6">{c.classe}</td>
                  <td className="hidden num sm:table-cell">{c.comMeta} de {c.alunos}</td>
                  <td className="num">{c.meta ? textoMT(c.meta) : '—'}</td>
                  <td className="num">{textoMT(c.contribuido)}</td>
                  <td className="sm:pr-6"><Cumprimento v={razao(num(c.contribuido), num(c.meta))} /></td>
                </tr>
              ))}
            </tbody>
          </Tabela>
        )}
    </Cartao>
  )
}

/* ---------------------------------------------------------------- semanas especiais */
export function SemanasEspeciais() {
  const { pode } = useSessao()
  const q = useSemanasEspeciais()
  const { tirar } = useSemanasMut()
  const [aberta, setAberta] = useState<SemanaEspecial | 'nova' | null>(null)
  const hoje = hojeIso()
  const proximas = new Set(semanasProximas(q.data ?? []).map((s) => s.id))
  const lista = (q.data ?? []).filter((s) => s.dataFim >= hoje || proximas.has(s.id)).sort((a, b) => a.dataInicio.localeCompare(b.dataInicio))
  const passadas = (q.data ?? []).filter((s) => s.dataFim < hoje).slice(0, 3)
  return (
    <Cartao titulo="Programas especiais" descricao="Semanas de oração, família, evangelismo…" icone={CalendarHeart} semMargem
      accoes={pode('escola_sabatina.semana_especial.criar') && <Button size="sm" variant="outline" onClick={() => setAberta('nova')}><Plus className="size-4" />Programa</Button>}>
      {q.isPending ? <LinhasACarregar linhas={3} />
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="m-4" />
        : !lista.length && !passadas.length ? <EstadoVazio icone={CalendarHeart}>Ainda sem programas especiais marcados.</EstadoVazio>
        : (
          <ul className="divide-y">
            {[...lista, ...passadas].map((s) => {
              const agora = s.dataInicio <= hoje && s.dataFim >= hoje
              return (
                <li key={s.id} className={cn('flex items-center gap-3 px-4 py-2.5 sm:px-6', s.dataFim < hoje && 'text-muted-foreground')}>
                  <button type="button" disabled={!pode('escola_sabatina.semana_especial.alterar')} onClick={() => setAberta(s)} className="min-w-0 flex-1 text-left enabled:hover:text-primary">
                    <span className="flex flex-wrap items-center gap-2 font-medium">{s.nome}
                      {agora ? <Pilula variante="success">A decorrer</Pilula> : proximas.has(s.id) ? <Pilula variante="info">Em breve</Pilula> : null}
                    </span>
                    <span className="block text-xs text-muted-foreground">{TIPOS_SEMANA[s.tipo]} · {data(s.dataInicio)} a {data(s.dataFim)}</span>
                  </button>
                  {pode('escola_sabatina.semana_especial.terminar') && (
                    <Button variant="ghost" size="icon" className="size-8" aria-label={`Retirar ${s.nome}`} disabled={tirar.isPending}
                      onClick={() => tirar.mutate(s.id, { onSuccess: () => toast.success('Programa retirado.'), onError: (e) => toast.error(mensagemDe(e)) })}>
                      <Trash2 className="size-4" />
                    </Button>
                  )}
                </li>
              )
            })}
          </ul>
        )}
      {aberta && <DialogoSemana semana={aberta === 'nova' ? null : aberta} aoFechar={() => setAberta(null)} />}
    </Cartao>
  )
}

function DialogoSemana({ semana, aoFechar }: { semana: SemanaEspecial | null; aoFechar: () => void }) {
  const { gravar } = useSemanasMut()
  const [tipo, setTipo] = useState<TipoSemana>(semana?.tipo ?? 'ORACAO')
  const [nome, setNome] = useState(semana?.nome ?? TIPOS_SEMANA.ORACAO)
  const [inicio, setInicio] = useState(semana?.dataInicio ?? '')
  const [fim, setFim] = useState(semana?.dataFim ?? '')
  const [obs, setObs] = useState(semana?.observacoes ?? '')
  const [erro, setErro] = useState<string | null>(null)
  const submeter = async () => {
    setErro(null)
    if (!nome.trim()) return setErro('Escreva o nome do programa.')
    if (!/^\d{4}-\d{2}-\d{2}$/.test(inicio) || !/^\d{4}-\d{2}-\d{2}$/.test(fim)) return setErro('Escreva as datas como dd/mm/aaaa.')
    if (fim < inicio) return setErro('O fim tem de ser no mesmo dia ou depois do início.')
    try {
      await gravar.mutateAsync({ id: semana?.id, tipo, nome: nome.trim(), dataInicio: inicio, dataFim: fim, observacoes: obs.trim() || null } as never)
      toast.success(semana ? 'Programa actualizado.' : 'Programa marcado.')
      aoFechar()
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader><DialogTitle>{semana ? semana.nome : 'Programa especial'}</DialogTitle><DialogDescription>Aparece como alerta nos 14 dias antes e enquanto decorre.</DialogDescription></DialogHeader>
        <div className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-1.5"><label htmlFor="se-tipo" className="text-sm font-medium">Tipo</label>
            <Seleccao id="se-tipo" value={tipo} onChange={(e) => { const k = e.target.value as TipoSemana; if (nome === TIPOS_SEMANA[tipo]) setNome(k === 'OUTRO' ? '' : TIPOS_SEMANA[k]); setTipo(k) }}>
              {(Object.keys(TIPOS_SEMANA) as TipoSemana[]).map((k) => <option key={k} value={k}>{TIPOS_SEMANA[k]}</option>)}
            </Seleccao></div>
          <div className="grid gap-1.5"><label htmlFor="se-nome" className="text-sm font-medium">Nome</label>
            <Input id="se-nome" value={nome} onChange={(e) => setNome(e.target.value)} maxLength={150} className="alvo" /></div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-1.5"><label htmlFor="se-ini" className="text-sm font-medium">Início</label><CampoData id="se-ini" value={inicio} onChange={setInicio} className="alvo" /></div>
            <div className="grid gap-1.5"><label htmlFor="se-fim" className="text-sm font-medium">Fim</label><CampoData id="se-fim" value={fim} onChange={setFim} className="alvo" /></div>
          </div>
          <div className="grid gap-1.5"><label htmlFor="se-obs" className="text-sm font-medium">Observações</label>
            <Textarea id="se-obs" rows={2} value={obs} onChange={(e) => setObs(e.target.value)} maxLength={500} placeholder="ex.: tema, pregador, horário" /></div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={gravar.isPending} onClick={submeter}>{gravar.isPending ? t.comum.aGravar : t.comum.guardar}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
