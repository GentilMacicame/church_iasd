/**
 * Uma classe da Escola Sabatina (F-ES-02…05): o resumo da configuração no trimestre (professor, alvos, estado),
 * a folha do trimestre (sábado a sábado, como o quadro) e as matrículas (membros e interessados; sair da classe
 * guarda a data, nada se apaga). Editar abre o registo completo da classe (DialogoClasse).
 * Cada membro só tem uma matrícula activa: a base de dados recusa matricular quem já está noutra classe.
 */
import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { ArrowLeft, Pencil, School, Search, Table2, Target, UserMinus, UserPlus, Users } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Avatar, Cartao, Pilula, Segmentos, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Input } from '@/components/ui/input'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { useSessao } from '@/auth/sessao'
import { ErroApi, mensagemDe } from '@/api/erros'
import { rotulos, t } from '@/i18n/pt-MZ'
import { data, idade } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import {
  matriculaActivaDe, nomeTrimestre, trimestreActual, useClasses, useClassesTrimestre, useMatricular,
  useMatriculas, useMudarDeClasse, useTerminarClasse, useTirarMatricula, useTrimestres, type Classe,
} from './api'
import { DialogoClasse } from './DialogoClasse'
import { FolhaClasse } from './FolhaClasse'
import { EscolherTrimestre, textoMT } from './componentes'
import { MetasDaClasse } from './Metas'

type Aba = 'folha' | 'matriculas' | 'metas'

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
  const aba: Aba = params.get('aba') === 'matriculas' ? 'matriculas' : params.get('aba') === 'metas' ? 'metas' : 'folha'
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
                <dt className="text-[12px] font-semibold tracking-wide text-muted-foreground uppercase">{r}</dt>
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
          {([['folha', 'Folha do trimestre', Table2], ['metas', 'Metas', Target], ['matriculas', 'Matrículas', Users]] as const)
            .filter(([k]) => k !== 'metas' || pode('escola_sabatina.meta_individual.ler')).map(([k, r, I]) => (
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
        ) : aba === 'metas' ? (
          !trimestre || !ct ? <Cartao><EstadoVazio icone={Target}>Configure a classe para o trimestre para definir as metas.</EstadoVazio></Cartao>
            : <MetasDaClasse trimestre={trimestre} classeTrimestre={ct.id} />
        ) : (
          <Matriculas classe={classe} />
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
  const [busca, setBusca] = useState('')
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
    <Cartao semMargem>
      <div className="flex flex-wrap items-center gap-3 border-b px-5 pb-4 sm:px-6">
        <Segmentos rotulo="Matrículas" valor={historico ? 'sairam' : 'classe'} aoMudar={(v) => setHistorico(v === 'sairam')}
          opcoes={[{ valor: 'classe', rotulo: 'Na classe', contagem: activas.length }, { valor: 'sairam', rotulo: 'Saíram', contagem: antigas.length }] as const} />
        <div className="relative w-full sm:w-56">
          <Search aria-hidden className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input value={busca} onChange={(e) => setBusca(e.target.value)} placeholder="Pesquisar aluno…" aria-label="Pesquisar aluno" className="alvo pl-9" />
        </div>
        {pode('escola_sabatina.matricula.criar') && (
          <div className="w-full sm:ml-auto sm:w-80">
            <CampoMembro id="matricular" valor={novo} aoMudar={setNovo} nomeDe={nomeDe} estados={['ACTIVO', 'INTERESSADO']}
              excluir={activas.map((m) => m.membroId)} vazio={matricular.isPending ? 'A matricular…' : '+ Matricular membro ou interessado'} />
          </div>
        )}
      </div>
      {(erro || mudar) && (
        <div className="grid gap-3 px-5 pt-4 sm:px-6">
          <ErroFormulario mensagem={erro} />
          {mudar && (
            <div role="alert" className="flex flex-wrap items-center gap-3 rounded-xl border border-warning/40 bg-tint-warning px-4 py-3 text-sm text-warning-text">
              <p className="flex-1">
                <strong className="font-medium">{nomeDe(mudar.membroId) ?? 'Este membro'}</strong> está na classe{' '}
                <strong className="font-medium">{todasClasses.data?.find((c) => c.id === mudar.classeId)?.nome ?? 'outra classe'}</strong> desde {data(mudar.desde)}.
              </p>
              {pode('escola_sabatina.matricula.alterar') && (
                <Button size="sm" className="alvo" disabled={mudarDeClasse.isPending} onClick={() => void confirmarMudanca()}>
                  {mudarDeClasse.isPending ? 'A mudar…' : `Mudar para ${classe.nome}`}
                </Button>
              )}
              <Button size="sm" variant="outline" className="alvo" onClick={() => setMudar(null)}>{t.comum.cancelar}</Button>
            </div>
          )}
        </div>
      )}
      {q.isPending ? <LinhasACarregar linhas={4} />
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="m-4" />
        : (() => {
          const lista = (historico ? antigas : activas).filter((m) => !busca || (nomeDe(m.membroId) ?? '').toLowerCase().includes(busca.toLowerCase()))
          if (!lista.length) return <EstadoVazio icone={UserPlus}>{historico ? 'Ninguém saiu desta classe.' : busca ? 'Nenhum aluno com esse nome.' : 'Ainda ninguém matriculado nesta classe.'}</EstadoVazio>
          return (
            <Tabela porPagina={15} procurar={false}>
              <thead><tr><th className="sm:pl-6">Aluno</th><th>Situação</th><th className="num hidden sm:table-cell">Idade</th><th className="hidden md:table-cell">{historico ? 'Período' : 'Desde'}</th><th className="w-12 sm:pr-6"><span className="sr-only">Acções</span></th></tr></thead>
              <tbody>
                {lista.map((m) => {
                  const b = membros.get(m.membroId)
                  const anos = idade(b?.dataNascimento)
                  return (
                    <tr key={m.id}>
                      <td className="sm:pl-6">
                        <Link to={`/membros/${m.membroId}`} className="flex items-center gap-3 font-medium hover:text-primary">
                          <Avatar id={m.membroId} nome={b?.nome ?? '?'} apelido={b?.apelido} tamanho={32} />
                          {nomeDe(m.membroId) ?? `Membro n.º ${m.membroId}`}
                        </Link>
                      </td>
                      <td><Pilula variante={b?.estado === 'INTERESSADO' ? 'info' : 'success'}>{b?.estado === 'INTERESSADO' ? 'Interessado' : 'Membro'}</Pilula></td>
                      <td className="num hidden text-muted-foreground sm:table-cell">{anos ?? '—'}</td>
                      <td className="hidden tabular-nums text-muted-foreground md:table-cell">{historico ? `${data(m.dataEntrada)} – ${data(m.dataSaida)}` : data(m.dataEntrada)}</td>
                      <td className="sm:pr-6">
                        {!historico && pode('escola_sabatina.matricula.alterar') && (
                          <Button variant="ghost" size="icon" className="alvo size-9 text-muted-foreground hover:text-destructive-text" aria-label={`Tirar ${nomeDe(m.membroId) ?? ''} da classe`} title="Tirar da classe" onClick={() => setATirar(m.id)}>
                            <UserMinus className="size-4" />
                          </Button>
                        )}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </Tabela>
          )
        })()}
      <DialogoConfirmar aberto={aTirar != null} aoMudar={(v) => !v && setATirar(null)} titulo="Tirar da classe?"
        texto="A matrícula termina hoje e fica no histórico; os relatórios anteriores não mudam." accao="Tirar da classe"
        aCorrer={tirar.isPending}
        aoConfirmar={async () => {
          try { await tirar.mutateAsync(aTirar!); toast.success('Saiu da classe.') } catch (e) { toast.error(mensagemDe(e)) } finally { setATirar(null) }
        }} />
    </Cartao>
  )
}
