/**
 * Registar membro · passo 0: procurar primeiro (F-SEC-01, 4.4; V43). "Esta pessoa já está registada?"
 *
 * Procura pelo nome, data e local de nascimento e documento, em todas as igrejas:
 *   - não encontra ninguém      → segue logo para a ficha, já com o que se escreveu;
 *   - encontra o mesmo membro   → diz que já existe (mesmo documento, ou mesmo nome e data de nascimento) e não deixa
 *                                 registar outra vez: abre-se a ficha, ou pede-se a transferência à igreja onde está;
 *   - encontra só parecidos     → mostra-os; quem pode registar confere e confirma que é outra pessoa (a semelhança do
 *                                 nome, sozinha, não bloqueia).
 * A base de dados recusa o segundo registo da mesma pessoa mesmo que este passo seja saltado.
 */
import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ArrowLeft, ArrowRight, CircleAlert, Search, UserCheck, UserPlus, Users } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Cartao, Pilula, TituloPagina } from '@/components/comum/elementos'
import { CampoData } from '@/components/comum/CampoData'
import { EstadoErro } from '@/components/comum/estados'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { data as dataEcra } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useParecidos, type MembroParecido } from './api'

interface Pedido { nome: string; apelido: string; dataNascimento: string; naturalidade: string; numeroIdentificacao: string }
const VAZIO: Pedido = { nome: '', apelido: '', dataNascimento: '', naturalidade: '', numeroIdentificacao: '' }

/** A ficha nova, já com o que se escreveu na procura. */
function caminhoDaFicha(p: Pedido, confirmado = false) {
  const q = new URLSearchParams({ procurado: '1' })
  for (const [k, v] of Object.entries(p)) if (v.trim()) q.set(k, v.trim())
  if (confirmado) q.set('confirmado', '1')
  return `/membros/novo/ficha?${q}`
}

export default function PaginaProcurarMembro() {
  const igreja = useIgreja()
  const navigate = useNavigate()
  const [campos, setCampos] = useState<Pedido>(VAZIO)
  const [pedido, setPedido] = useState<Pedido | null>(null)
  const [erro, setErro] = useState<string | null>(null)
  const [conferiu, setConferiu] = useState(false)
  const q = useParecidos(pedido ?? VAZIO)
  const mudar = (k: keyof Pedido, v: string) => { setCampos((c) => ({ ...c, [k]: v })); setPedido(null); setConferiu(false) }

  const procurar = async (ev: React.FormEvent) => {
    ev.preventDefault()
    setErro(null)
    if (campos.nome.trim().length < 2 || campos.apelido.trim().length < 2) return setErro('Escreva o nome e o apelido (pelo menos 2 letras cada).')
    if (campos.dataNascimento && !/^\d{4}-\d{2}-\d{2}$/.test(campos.dataNascimento)) return setErro('Escreva a data de nascimento como dd/mm/aaaa.')
    setConferiu(false)
    setPedido({ ...campos })
  }

  // não encontrou ninguém: segue para a ficha
  const lista = pedido && q.data && !q.isFetching ? q.data : null
  const nenhum = !!pedido && !!lista && lista.length === 0
  useEffect(() => {
    if (!nenhum || !pedido) return
    toast.success('Não há nenhum registo com estes dados: continue o registo.')
    navigate(caminhoDaFicha(pedido))
  }, [nenhum, pedido, navigate])
  const existentes = (lista ?? []).filter((p) => p.existe)
  const provaveis = (lista ?? []).filter((p) => !p.existe && p.pontos >= 70)
  const parecidos = (lista ?? []).filter((p) => !p.existe && p.pontos < 70)

  return (
    <>
      <TituloPagina
        antes={<Link to="/membros" className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" /> {t.membros.titulo}</Link>}
        icone={UserPlus} titulo={t.membros.novo}
        descricao={`${igreja.nome} · antes de registar, procure a pessoa: cada membro tem um só registo`}
      />
      <div className="grid items-start gap-6 lg:grid-cols-12">
        <form onSubmit={procurar} noValidate className="lg:col-span-5">
          <Cartao titulo="1. Procurar a pessoa" descricao="Em todas as igrejas: pelo nome, nascimento e documento" icone={Search}>
            <div className="grid gap-4 sm:grid-cols-2">
              <Campo id="pm-nome" rotulo="Nome" obrigatorio>
                <Input id="pm-nome" value={campos.nome} onChange={(e) => mudar('nome', e.target.value)} autoComplete="off" className="alvo" autoFocus />
              </Campo>
              <Campo id="pm-apelido" rotulo="Apelido" obrigatorio>
                <Input id="pm-apelido" value={campos.apelido} onChange={(e) => mudar('apelido', e.target.value)} autoComplete="off" className="alvo" />
              </Campo>
              <Campo id="pm-nasc" rotulo="Data de nascimento" ajuda="Com a data, a procura reconhece a mesma pessoa">
                <CampoData id="pm-nasc" value={campos.dataNascimento} onChange={(v) => mudar('dataNascimento', v)} className="alvo" />
              </Campo>
              <Campo id="pm-local" rotulo="Local de nascimento">
                <Input id="pm-local" value={campos.naturalidade} onChange={(e) => mudar('naturalidade', e.target.value)} placeholder="ex.: Xai-Xai, Gaza" className="alvo" />
              </Campo>
              <Campo id="pm-doc" rotulo="N.º do BI ou outro documento" className="sm:col-span-2">
                <Input id="pm-doc" value={campos.numeroIdentificacao} onChange={(e) => mudar('numeroIdentificacao', e.target.value)} placeholder="ex.: 110100000000A" className="alvo num uppercase placeholder:normal-case" />
              </Campo>
            </div>
            {erro && <p className="mt-3 text-sm font-medium text-destructive-text" role="alert">{erro}</p>}
            <Button type="submit" className="alvo mt-4 w-full sm:w-auto" disabled={q.isFetching}>
              <Search className="size-4" />{q.isFetching ? 'A procurar…' : 'Procurar'}
            </Button>
          </Cartao>
        </form>

        <div className="grid gap-6 lg:col-span-7">
          {!pedido && (
            <Cartao titulo="2. Resultado" icone={Users}>
              <p className="text-sm text-muted-foreground">
                Escreva os dados da pessoa e carregue em <strong>Procurar</strong>. Se não estiver registada, segue para a ficha; se já
                estiver, abre-se o registo dela em vez de criar outro.
              </p>
            </Cartao>
          )}
          {pedido && q.isError && <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />}

          {existentes.length > 0 && (
            <section role="alert" className="rounded-xl border border-destructive/40 bg-tint-destructive p-4 sm:p-5">
              <h2 className="flex items-center gap-2 font-semibold text-destructive-text"><UserCheck className="size-5" />Este membro já existe</h2>
              <p className="mt-1 text-sm text-muted-foreground">Não se regista outra vez: um segundo registo divide o histórico da pessoa.</p>
              <ul className="mt-3 grid gap-2">{existentes.map((p, i) => <Linha key={p.membroId ?? `f${i}`} p={p} />)}</ul>
              <Button type="button" variant="outline" className="alvo mt-4" onClick={() => { setPedido(null); setCampos(VAZIO) }}>Procurar outra pessoa</Button>
            </section>
          )}

          {existentes.length === 0 && provaveis.length > 0 && (
            <section role="alert" className="rounded-xl border border-warning/40 bg-tint-warning p-4 sm:p-5">
              <h2 className="flex items-center gap-2 font-semibold text-warning-text"><CircleAlert className="size-5" />Pode ser alguém que já está registado</h2>
              <p className="mt-1 text-sm text-muted-foreground">Abra cada registo e confira. Se for a mesma pessoa, use esse registo.</p>
              <ul className="mt-3 grid gap-2">{provaveis.map((p) => <Linha key={p.membroId} p={p} />)}</ul>
              {parecidos.length > 0 && <ul className="mt-2 grid gap-2">{parecidos.map((p) => <Linha key={p.membroId} p={p} />)}</ul>}
              <label className="alvo mt-4 flex items-center gap-2 text-sm font-medium">
                <input type="checkbox" checked={conferiu} onChange={(e) => setConferiu(e.target.checked)} className="size-4 accent-[var(--primary)]" />
                Conferi: é outra pessoa
              </label>
              <Button type="button" className="alvo mt-3" disabled={!conferiu} onClick={() => navigate(caminhoDaFicha(pedido!, true))}>
                Continuar o registo<ArrowRight className="size-4" />
              </Button>
            </section>
          )}

          {existentes.length === 0 && provaveis.length === 0 && parecidos.length > 0 && (
            <Cartao titulo="Há registos com nome parecido" descricao="Confira se não é nenhum destes" icone={Users}>
              <ul className="grid gap-2">{parecidos.map((p) => <Linha key={p.membroId} p={p} />)}</ul>
              <Button type="button" className="alvo mt-4" onClick={() => navigate(caminhoDaFicha(pedido!))}>
                Não é nenhum destes: continuar o registo<ArrowRight className="size-4" />
              </Button>
            </Cartao>
          )}
        </div>
      </div>
    </>
  )
}

function Campo({ id, rotulo, obrigatorio, ajuda, className, children }: { id: string; rotulo: string; obrigatorio?: boolean; ajuda?: string; className?: string; children: React.ReactNode }) {
  return (
    <div className={cn('grid gap-1.5', className)}>
      <label htmlFor={id} className="text-sm font-medium">{rotulo}{obrigatorio && <span className="text-destructive-text"> *</span>}</label>
      {children}
      {ajuda && <p className="text-xs text-muted-foreground">{ajuda}</p>}
    </div>
  )
}

/** Um registo encontrado: da igreja que o utilizador vê, com ligação à ficha; de outra, só o nome e a igreja. */
function Linha({ p }: { p: MembroParecido }) {
  const { igrejas } = useSessao()
  const nomeIgreja = p.igreja ?? igrejas.find((i) => i.id === p.igrejaId)?.nome
  return (
    <li className="flex flex-wrap items-center gap-x-3 gap-y-1 rounded-lg border bg-card px-3 py-2 text-sm">
      {p.membroId != null
        ? <Link to={`/membros/${p.membroId}`} className="font-medium hover:text-primary hover:underline">{p.nome}</Link>
        : <span className="font-medium">{p.nome}</span>}
      <span className="text-muted-foreground">
        {[p.dataNascimento && dataEcra(p.dataNascimento), p.numeroIdentificacao, nomeIgreja, p.estado && rotulos.estadoMembro[p.estado]].filter(Boolean).join(' · ')}
      </span>
      <span className="flex flex-wrap gap-1">{p.motivos.map((m) => <Pilula key={m} variante={p.existe ? 'destructive' : p.pontos >= 70 ? 'warning' : 'secondary'}>{m}</Pilula>)}</span>
      {p.membroId != null && p.existe && <Button asChild size="sm" variant="outline" className="ml-auto"><Link to={`/membros/${p.membroId}`}>Abrir a ficha</Link></Button>}
      {p.membroId == null && <span className="basis-full text-xs text-muted-foreground">Está registado(a) noutra igreja: para o(a) ter nesta, peça a transferência a essa igreja.</span>}
    </li>
  )
}
