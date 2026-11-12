/**
 * Classes da Escola Sabatina (F-ES-02, F-ES-03) · o quadro das classes do trimestre: n.º, nome do grupo,
 * professor/líder, alvos (membros, E.D., filiais, ofertas por sábado, baptismos) e estado (activa / desactivada).
 * Registar e editar fazem-se num só formulário (DialogoClasse); abrir a classe mostra a folha do trimestre.
 */
import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { ChevronRight, Copy, Pencil, Plus, School } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Cartao, Indicador, Pilula, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { useSessao } from '@/auth/sessao'
import { mensagemDe } from '@/api/erros'
import { rotulos, t } from '@/i18n/pt-MZ'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import {
  nomeTrimestre, trimestreActual, useClasses, useClassesTrimestre, useCopiarConfiguracao, useTrimestres, type Classe, type ClasseTrimestre,
} from './api'
import { DialogoClasse } from './DialogoClasse'
import { EscolherTrimestre, Folha, textoMT } from './componentes'

export default function PaginaClasses() {
  const { pode } = useSessao()
  const navigate = useNavigate()
  const [params, setParams] = useSearchParams()
  const [editar, setEditar] = useState<{ classe?: Classe; ct?: ClasseTrimestre; numero?: number } | null>(null)
  const trimestres = useTrimestres()
  const trimestre = trimestres.data?.find((x) => x.id === Number(params.get('trimestre'))) ?? trimestreActual(trimestres.data ?? [])
  const classes = useClasses()
  const cts = useClassesTrimestre(trimestre?.id)
  const basicos = useMembrosBasicos()
  const nomeDe = (id?: number) => { const m = id ? basicos.data?.find((x) => x.id === id) : undefined; return m ? `${m.nome} ${m.apelido}` : null }
  const lista = classes.data ?? []
  const config = new Map((cts.data ?? []).map((c) => [c.classeId, c]))
  // activas primeiro (pela ordem do nome), depois as desactivadas e as por configurar, como no quadro
  const ordenadas = [...lista].sort((a, b) => {
    const pa = config.get(a.id)?.estado === 'ACTIVO' ? 0 : config.has(a.id) ? 1 : 2
    const pb = config.get(b.id)?.estado === 'ACTIVO' ? 0 : config.has(b.id) ? 1 : 2
    return pa - pb || a.nome.localeCompare(b.nome, 'pt', { numeric: true })
  })
  const activas = lista.filter((c) => config.get(c.id)?.estado === 'ACTIVO')
  const semConfig = lista.filter((c) => !config.has(c.id)).length
  const somaAlvo = (k: 'alvoMembros' | 'alvoBaptismos') => activas.reduce((s, c) => s + (config.get(c.id)?.[k] ?? 0), 0)
  const somaOfertas = activas.reduce((s, c) => s + Number(config.get(c.id)?.alvoOfertaSabado ?? 0), 0)
  const linkClasse = (id: number) => `/escola-sabatina/classes/${id}${trimestre ? `?trimestre=${trimestre.id}` : ''}`
  const podeEditar = pode('escola_sabatina.classe.alterar') || pode('escola_sabatina.classe_trimestre.alterar') || pode('escola_sabatina.classe_trimestre.criar')

  const anterior = trimestre ? [...(trimestres.data ?? [])].filter((x) => x.dataInicio < trimestre.dataInicio).sort((a, b) => b.dataInicio.localeCompare(a.dataInicio))[0] : undefined
  const copiar = useCopiarConfiguracao()
  const copiarAnterior = async () => {
    if (!anterior || !trimestre) return
    try {
      const r = await copiar.mutateAsync({ de: anterior.id, para: trimestre.id })
      if (r.copiadas) toast.success(`${r.copiadas} classe(s) configurada(s) como no ${nomeTrimestre(anterior)}. Reveja os alvos.`)
      else if (!r.erros.length) toast.info(`O ${nomeTrimestre(anterior)} não tem classes por copiar.`)
      if (r.erros.length) toast.error(`${r.erros.length} classe(s) não copiada(s): ${r.erros[0]}`)
    } catch (e) {
      toast.error(mensagemDe(e))
    }
  }

  return (
    <>
      <TituloPagina
        icone={School}
        titulo={t.es.classes}
        descricao="Classes (grupos) do trimestre: professor, alvos e estado"
        accoes={<>
          <EscolherTrimestre trimestres={trimestres.data ?? []} valor={trimestre?.id} aoMudar={(v) => setParams({ trimestre: v }, { replace: true })} />
          {pode('escola_sabatina.classe.criar') && <Button className="alvo" onClick={() => setEditar({})}><Plus className="size-4" />Registar classe</Button>}
        </>}
      />
      <div className="grid gap-6">
        <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
          <Indicador rotulo="Classes activas" valor={activas.length} nota={`de ${lista.length} registadas`} icone={School} aCarregar={classes.isPending || cts.isPending} />
          <Indicador rotulo="Alvo de membros" valor={somaAlvo('alvoMembros')} nota="soma das classes activas" tom="info" aCarregar={cts.isPending} />
          <Indicador rotulo="Alvo de ofertas" valor={textoMT(somaOfertas)} nota="por sábado, todas as classes" tom="success" aCarregar={cts.isPending} />
          <Indicador rotulo="Alvo de baptismos" valor={somaAlvo('alvoBaptismos')} nota={semConfig ? `${semConfig} classe(s) por configurar` : 'no trimestre'} tom={semConfig ? 'warning' : 'primary'} aCarregar={cts.isPending} />
        </div>

        <Cartao
          titulo={trimestre ? `Quadro das classes · ${nomeTrimestre(trimestre)}` : 'Quadro das classes'}
          descricao="Clique numa classe para abrir a folha do trimestre (sábado a sábado) e as matrículas"
          accoes={anterior && semConfig > 0 && !cts.isPending && pode('escola_sabatina.classe_trimestre.criar') && (
            <Button variant="outline" size="sm" className="alvo" disabled={copiar.isPending} onClick={() => void copiarAnterior()}>
              <Copy className="size-4" />{copiar.isPending ? 'A copiar…' : `Copiar do ${nomeTrimestre(anterior)}`}
            </Button>
          )}>
          {classes.isPending || (trimestre && cts.isPending) ? <LinhasACarregar linhas={5} />
            : classes.isError ? <EstadoErro erro={classes.error} aoTentar={() => classes.refetch()} />
            : lista.length === 0 ? (
              <EstadoVazio icone={School} titulo="Ainda não há classes"
                accao={pode('escola_sabatina.classe.criar') && <Button size="sm" onClick={() => setEditar({})}><Plus className="size-4" />Registar classe</Button>}>
                Registe as classes (grupos) da Escola Sabatina com o professor e os alvos do trimestre.
              </EstadoVazio>
            ) : (
              <Folha minimo="min-w-[60rem]">
                <thead>
                  <tr>
                    <th className="w-12 centro">N.º</th><th className="text-left">Nome do grupo</th><th className="text-left">Professor / líder</th>
                    <th className="num">Alvo de membros</th><th className="num">Alvo de E.D.</th><th className="num">Alvo de filiais</th>
                    <th className="num">Alvo de ofertas por sábado</th><th className="centro">Estado</th><th className="num">Alvo de baptismos</th>
                    {podeEditar && <th className="w-12"><span className="sr-only">Editar</span></th>}
                  </tr>
                </thead>
                <tbody>
                  {ordenadas.map((c, i) => {
                    const ct = config.get(c.id)
                    const inactiva = ct?.estado === 'INACTIVO'
                    return (
                      <tr key={c.id} onClick={() => navigate(linkClasse(c.id))} className={cn('cursor-pointer', inactiva && 'text-muted-foreground [&_td]:bg-muted/40')}>
                        <td className="centro font-semibold tabular-nums">{i + 1}</td>
                        <td>
                          <Link to={linkClasse(c.id)} onClick={(e) => e.stopPropagation()} className={cn('font-medium hover:text-primary', !inactiva && 'text-primary')}>
                            {c.nome}{inactiva && ' (desactivado)'}
                          </Link>
                          <span className="block text-xs text-muted-foreground">{rotulos.divisao[c.divisao]}{c.localReuniao ? ` · ${c.localReuniao}` : ''}</span>
                        </td>
                        <td>{nomeDe(ct?.professorMembroId) ?? <span className="text-muted-foreground">Ir. ________</span>}</td>
                        {ct ? (
                          <>
                            <td className="num tabular-nums">{ct.alvoMembros}</td>
                            <td className="num tabular-nums">{Math.round(Number(ct.alvoEstudoDiario ?? 1) * 100)}%</td>
                            <td className="num tabular-nums">{ct.alvoFiliais}</td>
                            <td className="num tabular-nums">{textoMT(ct.alvoOfertaSabado)}</td>
                            <td className="centro">
                              {inactiva ? <Pilula variante="secondary">Desactivado</Pilula> : <Pilula variante="success">Activo</Pilula>}
                            </td>
                            <td className="num tabular-nums">{ct.alvoBaptismos}</td>
                          </>
                        ) : (
                          <td colSpan={6} className="centro">
                            <Pilula variante="warning">Por configurar neste trimestre</Pilula>
                          </td>
                        )}
                        {podeEditar && (
                          <td className="text-right" onClick={(e) => e.stopPropagation()}>
                            <Button variant="ghost" size="icon" className="size-9" aria-label={`Editar ${c.nome}`} onClick={() => setEditar({ classe: c, ct, numero: i + 1 })}>
                              <Pencil className="size-4" />
                            </Button>
                          </td>
                        )}
                      </tr>
                    )
                  })}
                </tbody>
                {activas.length > 0 && (
                  <tfoot>
                    <tr>
                      <td colSpan={3}>Total das classes activas ({activas.length})</td>
                      <td className="num tabular-nums">{somaAlvo('alvoMembros')}</td>
                      <td className="num tabular-nums">{Math.round(activas.reduce((s, c) => s + Number(config.get(c.id)?.alvoEstudoDiario ?? 1), 0) / activas.length * 100)}%</td>
                      <td className="num tabular-nums">{activas.reduce((s, c) => s + (config.get(c.id)?.alvoFiliais ?? 0), 0)}</td>
                      <td className="num tabular-nums">{textoMT(somaOfertas)}</td>
                      <td />
                      <td className="num tabular-nums">{somaAlvo('alvoBaptismos')}</td>
                      {podeEditar && <td />}
                    </tr>
                  </tfoot>
                )}
              </Folha>
            )}
          {lista.length > 0 && <p className="mt-3 flex items-center gap-1 text-xs text-muted-foreground"><ChevronRight className="size-3" />Os desactivados aparecem a cinzento e ficam fora das médias e da classificação.</p>}
        </Cartao>
      </div>
      {editar && <DialogoClasse {...editar} trimestre={trimestre} aoFechar={() => setEditar(null)} aoGravar={(id) => { if (!editar.classe) navigate(linkClasse(id)) }} />}
    </>
  )
}
