/**
 * Uma classe da Escola Sabatina (F-ES-02…05): o resumo da configuração no trimestre (professor, alvos, estado),
 * a folha do trimestre (sábado a sábado, como o quadro) e as matrículas (membros e interessados; sair da classe
 * guarda a data, nada se apaga). Editar abre o registo completo da classe (DialogoClasse).
 * Cada membro só tem uma matrícula activa: a base de dados recusa matricular quem já está noutra classe.
 */
import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { ArrowLeft, Pencil, School, Table2, UserMinus, UserPlus, Users } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Avatar, Cartao, Pilula, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { CampoFormulario, ErroFormulario } from '@/components/comum/formulario'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { Paginada } from '@/components/comum/Paginacao'
import { useSessao } from '@/auth/sessao'
import { ErroApi, mensagemDe } from '@/api/erros'
import { rotulos, t } from '@/i18n/pt-MZ'
import { data } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import {
  matriculaActivaDe, nomeTrimestre, trimestreActual, useClasses, useClassesTrimestre, useMatricular,
  useMatriculas, useMudarDeClasse, useTerminarClasse, useTirarMatricula, useTrimestres, type Classe,
} from './api'
import { DialogoClasse } from './DialogoClasse'
import { FolhaClasse } from './FolhaClasse'
import { EscolherTrimestre, textoMT } from './componentes'

type Aba = 'folha' | 'matriculas'

export default function PaginaClasse() {
  const id = Number(useParams().id)
  const navigate = useNavigate()
  const { pode } = useSessao()
  const [params, setParams] = useSearchParams()
  const classes = useClasses()
  const classe = classes.data?.find((c) => c.id === id)
  const trimestres = useTrimestres()
  const trimestre = trimestres.data?.find((x) => x.id === Number(params.get('trimestre'))) ?? trimestreActual(trimestres.data ?? [])
  const cts = useClassesTrimestre(trimestre?.id)
  const ct = cts.data?.find((c) => c.classeId === id)
  const basicos = useMembrosBasicos()
  const nomeDe = (mid?: number) => { const m = mid ? basicos.data?.find((x) => x.id === mid) : undefined; return m ? `${m.nome} ${m.apelido}` : null }
  const aba: Aba = params.get('aba') === 'matriculas' ? 'matriculas' : 'folha'
  const definir = (k: string, v: string) => setParams((p) => { const n = new URLSearchParams(p); n.set(k, v); return n }, { replace: true })
  const [editar, setEditar] = useState(false)
  const [terminar, setTerminar] = useState(false)
  const terminarClasse = useTerminarClasse()
  const podeEditar = pode('escola_sabatina.classe.alterar') || pode('escola_sabatina.classe_trimestre.alterar') || pode('escola_sabatina.classe_trimestre.criar')

  if (classes.isError) return <EstadoErro erro={classes.error} aoTentar={() => classes.refetch()} />
  if (classes.isPending) return <Cartao><LinhasACarregar linhas={5} /></Cartao>
  if (!classe) return <Cartao><EstadoVazio icone={School} titulo="Classe não encontrada">A classe não existe ou foi terminada. <Link to="/escola-sabatina/classes" className="text-primary hover:underline">Ver as classes</Link></EstadoVazio></Cartao>

  const resumo: [string, ReactNode][] = ct ? [
    ['Professor / líder', nomeDe(ct.professorMembroId) ?? 'Ir. ________'],
    ['Secretário(a)', nomeDe(ct.secretarioMembroId) ?? '—'],
    ['Alvo de membros', ct.alvoMembros],
    ['Alvo de E.D.', `${Math.round(Number(ct.alvoEstudoDiario ?? 1) * 100)}%`],
    ['Alvo de filiais', ct.alvoFiliais],
    ['Ofertas por sábado', textoMT(ct.alvoOfertaSabado)],
    ['Alvo de baptismos', ct.alvoBaptismos],
  ] : []

  return (
    <>
      <TituloPagina
        antes={<Link to={`/escola-sabatina/classes${trimestre ? `?trimestre=${trimestre.id}` : ''}`} className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground print:hidden"><ArrowLeft className="size-4" />{t.es.classes}</Link>}
        icone={School}
        titulo={<span className="flex flex-wrap items-center gap-2">{classe.nome}{ct && (ct.estado === 'INACTIVO' ? <Pilula variante="secondary">Desactivado</Pilula> : <Pilula variante="success">Activo</Pilula>)}</span>}
        descricao={[rotulos.divisao[classe.divisao], classe.localReuniao, trimestre && nomeTrimestre(trimestre)].filter(Boolean).join(' · ')}
        accoes={<>
          <EscolherTrimestre trimestres={trimestres.data ?? []} valor={trimestre?.id} aoMudar={(v) => definir('trimestre', v)} className="print:hidden" />
          {podeEditar && <Button variant="outline" className="alvo print:hidden" onClick={() => setEditar(true)}><Pencil className="size-4" />{ct ? t.comum.editar : 'Configurar'}</Button>}
          {pode('escola_sabatina.classe.terminar') && <Button variant="ghost" className="alvo text-destructive-text print:hidden" onClick={() => setTerminar(true)}>Terminar</Button>}
        </>}
      />
      <div className="grid gap-5">
        {trimestre && !cts.isPending && (ct ? (
          <dl className="grid grid-cols-2 overflow-hidden rounded-xl border bg-card shadow-card sm:grid-cols-4 lg:grid-cols-7">
            {resumo.map(([r, v]) => (
              <div key={r} className="border-r border-b px-4 py-3">
                <dt className="text-[11px] font-semibold tracking-wide text-muted-foreground uppercase">{r}</dt>
                <dd className="mt-1 truncate text-sm font-semibold tabular-nums">{v}</dd>
              </div>
            ))}
          </dl>
        ) : (
          <div className="flex flex-wrap items-center gap-3 rounded-lg border border-warning/30 bg-tint-warning px-4 py-3 text-sm text-warning-text">
            <p className="flex-1">Esta classe ainda não está configurada para o {nomeTrimestre(trimestre)} (professor e alvos). Sem isso não há folha nem relatórios do sábado.</p>
            {podeEditar && <Button size="sm" onClick={() => setEditar(true)}>Configurar</Button>}
          </div>
        ))}

        <div role="tablist" aria-label="Classe" className="flex gap-1 border-b print:hidden">
          {([['folha', 'Folha do trimestre', Table2], ['matriculas', 'Matrículas', Users]] as const).map(([k, r, I]) => (
            <button key={k} type="button" role="tab" aria-selected={aba === k} onClick={() => definir('aba', k)}
              className={cn('alvo -mb-px inline-flex items-center gap-2 border-b-2 px-3 py-2.5 text-sm font-medium transition-colors',
                aba === k ? 'border-primary text-foreground' : 'border-transparent text-muted-foreground hover:text-foreground')}>
              <I className="size-4" />{r}
            </button>
          ))}
        </div>

        {aba === 'folha' ? (
          <Cartao titulo={`Folha da classe${trimestre ? ` · ${nomeTrimestre(trimestre)}` : ''}`} descricao="Sábado a sábado, como o quadro da Escola Sabatina">
            {!trimestre ? <EstadoVazio>Ainda não há trimestres criados pela Associação.</EstadoVazio>
              : cts.isPending ? <LinhasACarregar linhas={6} />
              : cts.isError ? <EstadoErro erro={cts.error} aoTentar={() => cts.refetch()} />
              : !ct ? <EstadoVazio icone={Table2}>Configure a classe para o trimestre para preencher a folha.</EstadoVazio>
              : <FolhaClasse classe={classe} ct={ct} trimestre={trimestre} />}
          </Cartao>
        ) : (
          <div className="max-w-3xl"><Matriculas classe={classe} /></div>
        )}
      </div>
      {editar && <DialogoClasse classe={classe} ct={ct} trimestre={trimestre} aoFechar={() => setEditar(false)} />}
      <DialogoConfirmar aberto={terminar} aoMudar={setTerminar} perigo titulo={`Terminar a classe ${classe.nome}?`}
        texto="A classe deixa de aparecer nas listas; os relatórios e as matrículas ficam no histórico." accao="Terminar"
        aCorrer={terminarClasse.isPending}
        aoConfirmar={async () => {
          try { await terminarClasse.mutateAsync(classe.id); toast.success('Classe terminada.'); navigate('/escola-sabatina/classes') } catch (e) { toast.error(mensagemDe(e)) }
        }} />
    </>
  )
}

function Matriculas({ classe }: { classe: Classe }) {
  const { pode } = useSessao()
  const q = useMatriculas(classe.id)
  const basicos = useMembrosBasicos()
  const matricular = useMatricular(classe.id)
  const tirar = useTirarMatricula()
  const [novo, setNovo] = useState<number | null>(null)
  const [aTirar, setATirar] = useState<number | null>(null)
  const [historico, setHistorico] = useState(false)
  const [erro, setErro] = useState<string | null>(null)
  const [mudar, setMudar] = useState<{ membroId: number; anterior: number; classeId: number; desde: string } | null>(null)
  const mudarDeClasse = useMudarDeClasse(classe.id)
  const todasClasses = useClasses()
  const membros = useMemo(() => new Map((basicos.data ?? []).map((m) => [m.id, m])), [basicos.data])
  const nomeDe = (id: number) => { const m = membros.get(id); return m && `${m.nome} ${m.apelido}` }
  const activas = (q.data ?? []).filter((m) => !m.dataSaida).sort((a, b) => (nomeDe(a.membroId) ?? '').localeCompare(nomeDe(b.membroId) ?? '', 'pt'))
  const antigas = (q.data ?? []).filter((m) => m.dataSaida)

  useEffect(() => {
    if (novo == null) return
    setErro(null)
    setMudar(null)
    const membroId = novo
    matricular.mutateAsync(membroId)
      .then(() => toast.success(`${nomeDe(membroId) ?? 'Membro'} matriculado(a).`))
      .catch(async (e) => {
        // já está noutra classe: diz qual e oferece a mudança
        if (e instanceof ErroApi && e.estado === 409) {
          const actual = await matriculaActivaDe(membroId).catch(() => undefined)
          if (actual && actual.classeId !== classe.id) {
            setMudar({ membroId, anterior: actual.id, classeId: actual.classeId, desde: actual.dataEntrada })
            return
          }
        }
        setErro(mensagemDe(e))
      })
      .finally(() => setNovo(null))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [novo])

  const confirmarMudanca = async () => {
    if (!mudar) return
    try {
      await mudarDeClasse.mutateAsync({ membroId: mudar.membroId, anterior: mudar.anterior })
      toast.success(`${nomeDe(mudar.membroId) ?? 'Membro'} mudou para ${classe.nome}.`)
      setMudar(null)
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }

  return (
    <Cartao titulo="Matrículas" icone={Users} descricao={`${activas.length} aluno(s) na classe`}
      accoes={antigas.length > 0 && <Button variant="ghost" size="sm" onClick={() => setHistorico((x) => !x)}>{historico ? 'Ocultar saídas' : `Saídas (${antigas.length})`}</Button>}>
      <div className="grid gap-3">
        <ErroFormulario mensagem={erro} />
        {mudar && (
          <div role="alert" className="grid gap-3 rounded-lg border border-warning/40 bg-tint-warning px-4 py-3 text-sm text-warning-text">
            <p>
              <strong className="font-medium">{nomeDe(mudar.membroId) ?? 'Este membro'}</strong> está na classe{' '}
              <strong className="font-medium">{todasClasses.data?.find((c) => c.id === mudar.classeId)?.nome ?? 'outra classe'}</strong> desde {data(mudar.desde)}.
              Cada pessoa só está numa classe de cada vez.
            </p>
            <div className="flex flex-wrap gap-2">
              {pode('escola_sabatina.matricula.alterar') && (
                <Button size="sm" className="alvo" disabled={mudarDeClasse.isPending} onClick={() => void confirmarMudanca()}>
                  {mudarDeClasse.isPending ? 'A mudar…' : `Mudar para ${classe.nome}`}
                </Button>
              )}
              <Button size="sm" variant="outline" className="alvo" onClick={() => setMudar(null)}>{t.comum.cancelar}</Button>
            </div>
          </div>
        )}
        {pode('escola_sabatina.matricula.criar') && (
          <CampoFormulario rotulo="Matricular" ajuda="Membros e interessados; quem está noutra classe tem de sair dela primeiro.">
            {(p) => <CampoMembro id={p.id} valor={novo} aoMudar={setNovo} nomeDe={nomeDe} estados={['ACTIVO', 'INTERESSADO']}
              excluir={activas.map((m) => m.membroId)} vazio={matricular.isPending ? 'A matricular…' : 'Escolher membro ou interessado…'} />}
          </CampoFormulario>
        )}
        {q.isPending ? <LinhasACarregar linhas={3} />
          : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
          : activas.length === 0 ? <EstadoVazio icone={UserPlus}>Ainda ninguém matriculado nesta classe.</EstadoVazio>
          : (
            <Paginada itens={activas}>
              {(visiveis) => <div className="-mx-5 divide-y border-y sm:-mx-6">{visiveis.map((m) => {
                const b = membros.get(m.membroId)
                return (
                  <div key={m.id} className="flex items-center gap-3 px-5 py-2.5 sm:px-6">
                    <Avatar id={m.membroId} nome={b?.nome ?? '?'} apelido={b?.apelido} tamanho={30} />
                    <span className="min-w-0 flex-1">
                      <Link to={`/membros/${m.membroId}`} className="block truncate text-sm font-medium hover:text-primary">{nomeDe(m.membroId) ?? `Membro n.º ${m.membroId}`}</Link>
                      <span className="block text-xs text-muted-foreground">desde {data(m.dataEntrada)}{b?.estado === 'INTERESSADO' && ' · interessado'}</span>
                    </span>
                    {pode('escola_sabatina.matricula.alterar') && (
                      <Button variant="ghost" size="icon" className="size-11" aria-label={`Tirar ${nomeDe(m.membroId) ?? ''} da classe`} onClick={() => setATirar(m.id)}>
                        <UserMinus className="size-4" />
                      </Button>
                    )}
                  </div>
                )
              })}</div>}
            </Paginada>
          )}
        {historico && antigas.length > 0 && (
          <ul className="grid gap-1 text-sm text-muted-foreground">
            {antigas.map((m) => <li key={m.id}>{nomeDe(m.membroId) ?? `Membro n.º ${m.membroId}`} · {data(m.dataEntrada)} – {data(m.dataSaida)} <Pilula variante="secondary">Saiu</Pilula></li>)}
          </ul>
        )}
      </div>
      <DialogoConfirmar aberto={aTirar != null} aoMudar={(v) => !v && setATirar(null)} titulo="Tirar da classe?"
        texto="A matrícula termina hoje e fica no histórico; os relatórios anteriores não mudam." accao="Tirar da classe"
        aCorrer={tirar.isPending}
        aoConfirmar={async () => {
          try { await tirar.mutateAsync(aTirar!); toast.success('Saiu da classe.') } catch (e) { toast.error(mensagemDe(e)) } finally { setATirar(null) }
        }} />
    </Cartao>
  )
}
