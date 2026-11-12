/**
 * Classes da Escola Sabatina (F-ES-02, F-ES-03) · "Que classes temos e quem as dirige neste trimestre?"
 * As classes são da igreja (por divisão, do rol do berço aos adultos); em cada trimestre cada classe tem professor,
 * secretário, alvos e pode estar activa ou desactivada. Abrir uma classe: matrículas e configuração.
 */
import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ChevronRight, Plus, School } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { Seleccao } from '@/components/comum/Seleccao'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { mensagemDe } from '@/api/erros'
import { useMembrosBasicos } from '@/features/membros/api'
import { DIVISOES, nomeTrimestre, trimestreActual, useClasses, useClassesTrimestre, useCopiarConfiguracao, useCriarClasse, useTrimestres, type Divisao } from './api'

export default function PaginaClasses() {
  const { pode } = useSessao()
  const navigate = useNavigate()
  const [params, setParams] = useSearchParams()
  const [nova, setNova] = useState(false)
  const trimestres = useTrimestres()
  const trimestre = trimestres.data?.find((x) => x.id === Number(params.get('trimestre'))) ?? trimestreActual(trimestres.data ?? [])
  const classes = useClasses()
  const cts = useClassesTrimestre(trimestre?.id)
  const basicos = useMembrosBasicos()
  const nomeDe = (id?: number) => { const m = id ? basicos.data?.find((x) => x.id === id) : undefined; return m ? `${m.nome} ${m.apelido}` : null }
  const lista = classes.data ?? []
  const config = new Map((cts.data ?? []).map((c) => [c.classeId, c]))
  const activas = lista.filter((c) => config.get(c.id)?.estado === 'ACTIVO').length
  const semConfig = lista.filter((c) => !config.has(c.id)).length
  // início do trimestre: copiar a configuração do trimestre anterior para as classes por configurar
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
  const linkClasse = (id: number) => `/escola-sabatina/classes/${id}${trimestre ? `?trimestre=${trimestre.id}` : ''}`

  return (
    <>
      <TituloPagina
        icone={School}
        titulo={t.es.classes}
        descricao="Classes por divisão, matrículas, professores e alvos de cada trimestre"
        accoes={<>
          {(trimestres.data?.length ?? 0) > 0 && (
            <div className="w-56">
              <Seleccao aria-label="Trimestre" value={trimestre?.id ?? ''} onChange={(e) => setParams({ trimestre: e.target.value }, { replace: true })}>
                {(trimestres.data ?? []).map((x) => <option key={x.id} value={x.id}>{nomeTrimestre(x)}</option>)}
              </Seleccao>
            </div>
          )}
          {pode('escola_sabatina.classe.criar') && <Button className="alvo" onClick={() => setNova(true)}><Plus className="size-4" />Nova classe</Button>}
        </>}
      />
      <div className="grid gap-6">
        <div className="grid grid-cols-3 gap-3 sm:gap-4">
          <Indicador rotulo="Classes" valor={lista.length} nota="da igreja" icone={School} aCarregar={classes.isPending} />
          <Indicador rotulo="Activas" valor={activas} nota={trimestre ? nomeTrimestre(trimestre) : 'no trimestre'} tom="success" aCarregar={classes.isPending || cts.isPending} />
          <Indicador rotulo="Por configurar" valor={semConfig} nota="sem professor nem alvos" tom="warning" aCarregar={classes.isPending || cts.isPending} />
        </div>
        <Cartao titulo="Todas as classes" descricao={trimestre ? `Configuração no ${nomeTrimestre(trimestre)}` : undefined} semMargem
          accoes={anterior && semConfig > 0 && !cts.isPending && pode('escola_sabatina.classe_trimestre.criar') && (
            <Button variant="outline" size="sm" className="alvo" disabled={copiar.isPending} onClick={() => void copiarAnterior()}>
              {copiar.isPending ? 'A copiar…' : `Copiar do ${nomeTrimestre(anterior)}`}
            </Button>
          )}>
          {classes.isPending ? <LinhasACarregar linhas={4} />
            : classes.isError ? <EstadoErro erro={classes.error} aoTentar={() => classes.refetch()} className="mx-6 mb-6" />
            : lista.length === 0 ? (
              <EstadoVazio icone={School} titulo="Ainda não há classes"
                accao={pode('escola_sabatina.classe.criar') && <Button size="sm" onClick={() => setNova(true)}><Plus className="size-4" />Nova classe</Button>}>
                Crie as classes (unidades de acção) da Escola Sabatina e matricule os alunos.
              </EstadoVazio>
            ) : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Classe</th><th className="hidden sm:table-cell">Divisão</th><th className="hidden md:table-cell">Professor</th><th>No trimestre</th><th className="sm:pr-6" /></tr></thead>
                <tbody>
                  {lista.map((c) => {
                    const ct = config.get(c.id)
                    return (
                      <tr key={c.id} onClick={() => navigate(linkClasse(c.id))} className="cursor-pointer">
                        <td className="sm:pl-6">
                          <Link to={linkClasse(c.id)} onClick={(e) => e.stopPropagation()} className="font-medium hover:text-primary">{c.nome}</Link>
                          <span className="block text-xs text-muted-foreground sm:hidden">{rotulos.divisao[c.divisao]}</span>
                          {c.localReuniao && <span className="hidden text-xs text-muted-foreground sm:block">{c.localReuniao}</span>}
                        </td>
                        <td className="hidden sm:table-cell">{rotulos.divisao[c.divisao]}</td>
                        <td className="hidden md:table-cell">{nomeDe(ct?.professorMembroId) ?? <span className="text-muted-foreground">—</span>}</td>
                        <td>{!ct ? <Pilula variante="outline">Por configurar</Pilula> : ct.estado === 'ACTIVO' ? <Pilula variante="success">Activa</Pilula> : <Pilula variante="secondary">Desactivada</Pilula>}</td>
                        <td className="w-10 sm:pr-6"><ChevronRight aria-hidden className="size-4 text-muted-foreground" /></td>
                      </tr>
                    )
                  })}
                </tbody>
              </Tabela>
            )}
        </Cartao>
      </div>
      {nova && <DialogoClasse aoFechar={() => setNova(false)} aoCriar={(id) => navigate(linkClasse(id))} />}
    </>
  )
}

const esquema = z.object({
  nome: z.string().trim().min(1, t.comum.obrigatorio).max(100),
  divisao: z.enum(DIVISOES as [Divisao, ...Divisao[]]),
  localReuniao: z.string().trim().max(150),
})
type Valores = z.infer<typeof esquema>

export function DialogoClasse({ aoFechar, aoCriar }: { aoFechar: () => void; aoCriar: (id: number) => void }) {
  const igreja = useIgreja()
  const criar = useCriarClasse()
  const [erro, setErro] = useState<string | null>(null)
  const form = useForm<Valores>({ resolver: zodResolver(esquema), defaultValues: { nome: '', divisao: 'ADULTOS', localReuniao: '' } })
  const e = form.formState.errors
  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    try {
      const c = await criar.mutateAsync({ igrejaId: igreja.id, nome: v.nome, divisao: v.divisao, localReuniao: v.localReuniao || undefined })
      toast.success('Classe criada. Configure-a para o trimestre e matricule os alunos.')
      aoFechar()
      aoCriar(c.id)
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <form onSubmit={submeter} noValidate className="grid gap-4">
          <DialogHeader>
            <DialogTitle>Nova classe</DialogTitle>
            <DialogDescription>Uma unidade de acção da Escola Sabatina, numa divisão.</DialogDescription>
          </DialogHeader>
          <ErroFormulario mensagem={erro} />
          <CampoFormulario rotulo="Nome" erro={e.nome?.message} obrigatorio>
            {(p) => <Input {...p} {...form.register('nome')} placeholder="ex.: Classe dos Fiéis" autoFocus />}
          </CampoFormulario>
          <CampoFormulario rotulo="Divisão" erro={e.divisao?.message} obrigatorio>
            {(p) => <Seleccao {...p} {...form.register('divisao')}>{DIVISOES.map((d) => <option key={d} value={d}>{rotulos.divisao[d]}</option>)}</Seleccao>}
          </CampoFormulario>
          <CampoFormulario rotulo="Local de reunião" erro={e.localReuniao?.message}>
            {(p) => <Input {...p} {...form.register('localReuniao')} placeholder="ex.: Sala 2, debaixo da mangueira" />}
          </CampoFormulario>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={aoFechar}>{t.comum.cancelar}</Button>
            <Button type="submit" disabled={form.formState.isSubmitting}>{form.formState.isSubmitting ? t.comum.aGravar : 'Criar classe'}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
