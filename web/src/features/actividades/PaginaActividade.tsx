/**
 * Ficha da actividade (F-ACT, V34) · "O que é, quem organiza, quanto custa e quanto já se gastou?"
 * Detalhes e objectivos; responsáveis (o principal e outros, com a função); orçamento: previsto, material, despesas
 * pedidas (ligadas à actividade, decididas na tesouraria) e o executado (saídas confirmadas). Mudar o estado.
 */
import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useQueryClient } from '@tanstack/react-query'
import {
  ArrowLeft, CalendarRange, CheckCircle2, CircleSlash, Clock, MapPin, Package, Pencil, PlayCircle, Plus, Receipt, Target, Trash2, Users,
} from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Avatar, Campo, Cartao, Pilula, Tabela } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { ErroFormulario } from '@/components/comum/formulario'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { ErroApi, mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { centimos, data, dataPorExtenso, deCentimos, dinheiro, hora, partesMaputo } from '@/lib/formatos'
import { useMembrosBasicos } from '@/features/membros/api'
import { DialogoPedir } from '@/features/tesouraria/PaginaDespesas'
import { DialogoActividade } from './DialogoActividade'
import {
  ROTULO_ESTADO, VARIANTE_ESTADO, useActividade, useActividadesMut, useDepartamentosIgreja, useDespesasActividade, useDistritoDaIgreja, useMateriais,
  usePrograma, useResponsaveis, type Actividade, type EstadoActividade,
} from './api'

const ESTADO_DESPESA: Record<string, string> = { SUBMETIDA: 'Por decidir', APROVADA: 'Aprovada', REJEITADA: 'Rejeitada', PAGA: 'Paga', CANCELADA: 'Cancelada' }

function Voltar() {
  return (
    <Link to="/actividades" className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground">
      <ArrowLeft className="size-4" /> Actividades e programa anual
    </Link>
  )
}

export default function PaginaActividade() {
  const id = Number(useParams().id)
  const q = useActividade(id)
  if (q.isPending) return <><Voltar /><Barra className="mb-6 h-28 w-full" /><Barra className="h-64 w-full" /></>
  if (q.isError) {
    return (
      <>
        <Voltar />
        {q.error instanceof ErroApi && q.error.naoEncontrado
          ? <div className="rounded-xl border bg-card shadow-card"><EstadoVazio icone={CalendarRange} titulo="Actividade não encontrada">Não existe ou não pertence às igrejas a que tem acesso.</EstadoVazio></div>
          : <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />}
      </>
    )
  }
  return <Ficha a={q.data} />
}

function Ficha({ a }: { a: Actividade }) {
  const { pode } = useSessao()
  const deps = useDepartamentosIgreja()
  const basicos = useMembrosBasicos()
  const { alterar } = useActividadesMut()
  const [editar, setEditar] = useState(false)
  const [confirmar, setConfirmar] = useState<EstadoActividade | null>(null)
  const estado = a.estado ?? 'PLANEADA'
  const distrito = useDistritoDaIgreja()
  const departamento = a.distritoId ? `Área pastoral · ${distrito.data?.id === a.distritoId ? distrito.data.nome : 'distrito'}`
    : deps.data?.daIgreja.find((d) => d.id === a.departamentoIgrejaId)?.nome
  const responsavel = a.responsavelMembroId ? basicos.data?.find((m) => m.id === a.responsavelMembroId) : undefined
  const podeAlterar = pode('actividades.actividade.alterar')
  const mudarEstado = (e: EstadoActividade) => alterar.mutate({ id: a.id, estado: e } as never, {
    onSuccess: () => { toast.success(`Actividade ${ROTULO_ESTADO[e].toLowerCase()}.`); setConfirmar(null) },
    onError: (err) => { toast.error(mensagemDe(err)); setConfirmar(null) },
  })
  const mesmoDia = !a.dataFim || partesMaputo(a.dataFim).data === partesMaputo(a.dataInicio).data

  return (
    <>
      <Voltar />
      <section className="mb-6 rounded-xl border bg-card p-5 shadow-card sm:p-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div className="min-w-0">
            <div className="flex flex-wrap items-center gap-2">
              <h1 className="text-2xl font-semibold tracking-tight">{a.nome}</h1>
              <Pilula variante={VARIANTE_ESTADO[estado]}>{ROTULO_ESTADO[estado]}</Pilula>
              {a.distritoId && <Pilula variante="info">Área pastoral</Pilula>}
            </div>
            <div className="mt-2 flex flex-wrap items-center gap-x-5 gap-y-1.5 text-sm text-muted-foreground">
              <span className="inline-flex items-center gap-1.5"><CalendarRange className="size-4" /><span className="capitalize">{dataPorExtenso(a.dataInicio)}</span>{!mesmoDia && a.dataFim && ` a ${data(a.dataFim)}`}</span>
              <span className="inline-flex items-center gap-1.5"><Clock className="size-4" />{hora(a.dataInicio)}{a.dataFim ? `–${hora(a.dataFim)}` : ''}</span>
              {a.local && <span className="inline-flex items-center gap-1.5"><MapPin className="size-4" />{a.local}</span>}
              {departamento && <span>{departamento}</span>}
            </div>
          </div>
          {podeAlterar && (
            <div className="flex flex-wrap gap-2">
              {estado === 'PLANEADA' && <Button variant="outline" className="alvo" onClick={() => mudarEstado('EM_CURSO')}><PlayCircle className="size-4" />Iniciar</Button>}
              {(estado === 'PLANEADA' || estado === 'EM_CURSO') && <Button variant="outline" className="alvo" onClick={() => setConfirmar('CONCLUIDA')}><CheckCircle2 className="size-4" />Concluir</Button>}
              {(estado === 'PLANEADA' || estado === 'EM_CURSO') && <Button variant="outline" className="alvo text-destructive-text" onClick={() => setConfirmar('CANCELADA')}><CircleSlash className="size-4" />Cancelar</Button>}
              <Button className="alvo" onClick={() => setEditar(true)}><Pencil className="size-4" />Editar</Button>
            </div>
          )}
        </div>
      </section>

      <div className="grid items-start gap-6 lg:grid-cols-12">
        <div className="grid gap-6 lg:col-span-7">
          <Cartao titulo="Objectivos e descrição" icone={Target}>
            <dl className="grid gap-4">
              <Campo rotulo="Objectivos">{a.objectivos && <span className="whitespace-pre-line">{a.objectivos}</span>}</Campo>
              <Campo rotulo="Descrição">{a.descricao && <span className="whitespace-pre-line">{a.descricao}</span>}</Campo>
            </dl>
          </Cartao>
          <Orcamento a={a} />
        </div>
        <div className="grid gap-6 lg:col-span-5">
          <Responsaveis a={a} principal={responsavel ? `${responsavel.nome} ${responsavel.apelido}` : undefined} />
        </div>
      </div>

      {editar && <DialogoActividade actividade={a} aoFechar={() => setEditar(false)} />}
      <DialogoConfirmar aberto={confirmar != null} aoMudar={(v) => !v && setConfirmar(null)}
        titulo={confirmar === 'CANCELADA' ? `Cancelar «${a.nome}»?` : `Marcar «${a.nome}» como concluída?`}
        texto={confirmar === 'CANCELADA' ? 'Fica no histórico, mas deixa de contar nos conflitos de calendário e no orçamento do programa.' : 'Pode continuar a juntar as despesas que faltam.'}
        accao={confirmar === 'CANCELADA' ? 'Cancelar actividade' : 'Concluir'} perigo={confirmar === 'CANCELADA'} aCorrer={alterar.isPending}
        aoConfirmar={() => confirmar && mudarEstado(confirmar)} />
    </>
  )
}

/** Responsáveis: o principal (na própria actividade) e os outros, cada um com a sua função. */
function Responsaveis({ a, principal }: { a: Actividade; principal?: string }) {
  const { pode } = useSessao()
  const basicos = useMembrosBasicos()
  const ve = pode('actividades.actividade_responsavel.ler')
  const q = useResponsaveis(a.id, ve)
  const { juntarResponsavel, tirarResponsavel } = useActividadesMut()
  const [membro, setMembro] = useState<number | null>(null)
  const [funcao, setFuncao] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }
  const lista = (q.data ?? []).filter((r) => !r.endDate)
  const juntar = async () => {
    setErro(null)
    if (!membro) return setErro('Escolha o membro.')
    try {
      await juntarResponsavel.mutateAsync({ actividadeId: a.id, membroId: membro, funcao: funcao.trim() || undefined })
      toast.success(`${nomeDe(membro)} é responsável pela actividade.`)
      setMembro(null); setFuncao('')
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Cartao titulo="Responsáveis" descricao="Quem organiza e o que faz cada um" icone={Users} semMargem>
      <ul className="divide-y border-t">
        <li className="flex items-center gap-3 px-5 py-3 sm:px-6">
          {a.responsavelMembroId ? <Avatar id={a.responsavelMembroId} nome={principal?.split(' ')[0] ?? '?'} apelido={principal?.split(' ').slice(-1)[0]} tamanho={32} /> : null}
          <div className="min-w-0 flex-1">
            {a.responsavelMembroId ? <Link to={`/membros/${a.responsavelMembroId}`} className="font-medium hover:text-primary">{principal ?? 'Membro'}</Link>
              : <span className="text-muted-foreground">Sem responsável principal</span>}
            <p className="text-xs text-muted-foreground">Responsável principal</p>
          </div>
        </li>
        {lista.map((r) => (
          <li key={r.id} className="flex items-center gap-3 px-5 py-3 sm:px-6">
            <Avatar id={r.membroId} nome={nomeDe(r.membroId)?.split(' ')[0] ?? '?'} apelido={nomeDe(r.membroId)?.split(' ').slice(-1)[0]} tamanho={32} />
            <div className="min-w-0 flex-1">
              <Link to={`/membros/${r.membroId}`} className="font-medium hover:text-primary">{nomeDe(r.membroId) ?? 'Membro'}</Link>
              <p className="text-xs text-muted-foreground">{r.funcao || 'Responsável'}</p>
            </div>
            {pode('actividades.actividade_responsavel.terminar') && (
              <Button variant="ghost" size="icon" className="alvo size-9 text-muted-foreground" aria-label={`Retirar ${nomeDe(r.membroId)}`}
                onClick={() => tirarResponsavel.mutate(r, { onError: (e) => toast.error(mensagemDe(e)) })}><Trash2 className="size-4" /></Button>
            )}
          </li>
        ))}
      </ul>
      {pode('actividades.actividade_responsavel.criar') && (
        <div className="grid gap-2 border-t px-5 py-4 sm:px-6">
          <ErroFormulario mensagem={erro} />
          <CampoMembro valor={membro} aoMudar={setMembro} nomeDe={nomeDe} excluir={[...(a.responsavelMembroId ? [a.responsavelMembroId] : []), ...lista.map((r) => r.membroId)]} vazio="Juntar responsável…" />
          <div className="flex gap-2">
            <Input value={funcao} onChange={(e) => setFuncao(e.target.value)} placeholder="Função (ex.: logística)" aria-label="Função" className="alvo h-9" maxLength={100} />
            <Button size="sm" className="alvo h-9" disabled={juntarResponsavel.isPending} onClick={juntar}><Plus className="size-4" />Juntar</Button>
          </div>
        </div>
      )}
    </Cartao>
  )
}

/** Orçamento e execução: previsto, material (orçamento detalhado), despesas pedidas e o executado na tesouraria. */
function Orcamento({ a }: { a: Actividade }) {
  const { pode } = useSessao()
  const qc = useQueryClient()
  const ano = Number(partesMaputo(a.dataInicio).data.slice(0, 4))
  const programa = usePrograma(ano)
  const linha = programa.data?.find((x) => x.id === a.id)
  const materiais = useMateriais(a.id, pode('actividades.material.ler'))
  const veDespesas = pode('tesouraria.despesa.ler')
  const despesas = useDespesasActividade(a.id, veDespesas)
  const { juntarMaterial, tirarMaterial } = useActividadesMut()
  const [descricao, setDescricao] = useState('')
  const [qtd, setQtd] = useState('1')
  const [preco, setPreco] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const [pedir, setPedir] = useState(false)
  const lista = (materiais.data ?? []).filter((m) => !m.endDate)
  const totalMaterial = lista.reduce((s, m) => s + Math.round(Number(m.quantidade ?? 0) * centimos(m.precoUnitario ?? '0')), 0)
  const previsto = centimos(a.valorPrevisto ?? '0')
  const executado = linha ? centimos(linha.executado) : 0
  const juntar = async () => {
    setErro(null)
    if (!descricao.trim()) return setErro('Descreva o material.')
    if (!/^\d+([.,]\d{1,2})?$/.test(qtd.trim())) return setErro('Quantidade inválida.')
    try {
      await juntarMaterial.mutateAsync({ actividadeId: a.id, descricao: descricao.trim(), quantidade: qtd.trim().replace(',', '.'), precoUnitario: preco || '0.00' })
      setDescricao(''); setQtd('1'); setPreco('')
    } catch (e) { setErro(mensagemDe(e)) }
  }
  return (
    <Cartao titulo="Orçamento e execução" descricao="O previsto, o material, as despesas e o que já saiu da tesouraria" icone={Receipt} semMargem>
      <dl className="grid grid-cols-2 gap-4 border-t px-5 py-4 sm:grid-cols-4 sm:px-6">
        <Campo rotulo="Previsto">{dinheiro(a.valorPrevisto ?? '0.00')}</Campo>
        <Campo rotulo="Material">{dinheiro(deCentimos(totalMaterial))}</Campo>
        <Campo rotulo="Despesas aprovadas">{linha ? dinheiro(linha.despesasAprovadas) : '—'}</Campo>
        <Campo rotulo="Executado">{linha ? `${dinheiro(linha.executado)}${previsto ? ` (${Math.round((executado / previsto) * 100)}%)` : ''}` : '—'}</Campo>
      </dl>
      {previsto > 0 && (
        <div className="px-5 pb-4 sm:px-6">
          <div className="h-2 overflow-hidden rounded-full bg-muted" role="progressbar" aria-label="Execução do orçamento" aria-valuenow={Math.round((executado / previsto) * 100)} aria-valuemin={0} aria-valuemax={100}>
            <div className={executado > previsto ? 'h-full bg-destructive' : 'h-full bg-primary'} style={{ width: `${Math.min(100, (executado / previsto) * 100)}%` }} />
          </div>
          {executado > previsto && <p className="mt-1 text-xs text-destructive-text">O executado passou o previsto em {dinheiro(deCentimos(executado - previsto))}.</p>}
        </div>
      )}

      <h3 className="flex items-center gap-2 border-t px-5 pt-4 text-sm font-semibold sm:px-6"><Package className="size-4" />Material</h3>
      {lista.length ? (
        <Tabela className="mt-2">
          <thead><tr><th className="sm:pl-6">Descrição</th><th className="num">Qtd.</th><th className="num">Preço</th><th className="num">Total</th><th className="w-10 sm:pr-6"><span className="sr-only">Acções</span></th></tr></thead>
          <tbody>
            {lista.map((m) => (
              <tr key={m.id}>
                <td className="sm:pl-6">{m.descricao}</td>
                <td className="num">{Number(m.quantidade ?? 0).toLocaleString('pt-MZ')}</td>
                <td className="num">{dinheiro(m.precoUnitario ?? '0.00')}</td>
                <td className="num">{dinheiro(deCentimos(Math.round(Number(m.quantidade ?? 0) * centimos(m.precoUnitario ?? '0'))))}</td>
                <td className="sm:pr-6">
                  {pode('actividades.material.terminar') && (
                    <Button variant="ghost" size="icon" className="alvo size-9 text-muted-foreground" aria-label={`Retirar ${m.descricao}`}
                      onClick={() => tirarMaterial.mutate(m, { onError: (e) => toast.error(mensagemDe(e)) })}><Trash2 className="size-4" /></Button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </Tabela>
      ) : <p className="px-5 py-3 text-sm text-muted-foreground sm:px-6">Ainda sem material.</p>}
      {pode('actividades.material.criar') && (
        <div className="grid gap-2 px-5 pb-4 sm:px-6">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-2 sm:grid-cols-[1fr_5rem_8rem_auto]">
            <Input value={descricao} onChange={(e) => setDescricao(e.target.value)} placeholder="Material (ex.: cadeiras)" aria-label="Material" className="alvo h-9" maxLength={255} />
            <Input value={qtd} onChange={(e) => setQtd(e.target.value)} inputMode="decimal" aria-label="Quantidade" className="alvo num h-9" />
            <CampoDinheiro value={preco} onChange={setPreco} aria-label="Preço unitário" className="alvo h-9" />
            <Button size="sm" className="alvo h-9" disabled={juntarMaterial.isPending} onClick={juntar}><Plus className="size-4" />Juntar</Button>
          </div>
        </div>
      )}

      {veDespesas && (
        <>
          <div className="flex items-center justify-between gap-3 border-t px-5 pt-4 sm:px-6">
            <h3 className="flex items-center gap-2 text-sm font-semibold"><Receipt className="size-4" />Despesas</h3>
            {pode('tesouraria.despesa.criar') && <Button variant="outline" size="sm" className="alvo" onClick={() => setPedir(true)}><Plus className="size-4" />Pedir despesa</Button>}
          </div>
          {despesas.isPending ? <div className="px-5 py-3 sm:px-6"><Barra className="h-10 w-full" /></div>
            : (despesas.data ?? []).length ? (
              <Tabela className="mt-2">
                <thead><tr><th className="sm:pl-6">Para quê</th><th>Estado</th><th className="num">Pedido</th><th className="num sm:pr-6">Aprovado</th></tr></thead>
                <tbody>
                  {(despesas.data ?? []).map((d) => (
                    <tr key={d.id}>
                      <td className="sm:pl-6"><Link to={`/tesouraria/despesas?despesa=${d.id}`} className="hover:text-primary">{d.descricao}</Link></td>
                      <td><Pilula variante={d.estado === 'PAGA' ? 'success' : d.estado === 'REJEITADA' ? 'destructive' : d.estado === 'APROVADA' ? 'info' : 'warning'}>{ESTADO_DESPESA[d.estado ?? ''] ?? d.estado}</Pilula></td>
                      <td className="num">{dinheiro(d.valorSolicitado ?? '0.00')}</td>
                      <td className="num sm:pr-6">{d.valorAprovado ? dinheiro(d.valorAprovado) : '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </Tabela>
            ) : <p className="px-5 py-3 text-sm text-muted-foreground sm:px-6">Ainda não há despesas pedidas para esta actividade.</p>}
        </>
      )}
      {pedir && <DialogoPedir aberto={pedir} actividade={{ id: a.id, departamentoIgrejaId: a.departamentoIgrejaId ?? undefined, nome: a.nome }}
        aoMudar={(v) => { setPedir(v); if (!v) void qc.invalidateQueries({ queryKey: ['actividade', a.id] }) }} />}
    </Cartao>
  )
}
