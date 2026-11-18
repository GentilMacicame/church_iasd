/**
 * Ficha do membro · "Quem é, como o contactar e como entrou na igreja?"
 * Cabeçalho com o membro e as acções; cartões da ficha; contactos e baptismo ao lado.
 */
import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import {
  ArrowLeft, Briefcase, Cake, CalendarCheck, Check, Church, Droplets, Heart, IdCard, Mail, MapPin, MessageCircle, MoreHorizontal, Pencil,
  Phone, Plus, Smartphone, Star, UserX,
} from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { Avatar, Campo, Cartao, Pilula } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { ErroApi, mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { f, rotulos, t } from '@/i18n/pt-MZ'
import { data, idade } from '@/lib/formatos'
import { PilulasMembro } from './PaginaMembros'
import { DialogoBaptismo, DialogoContacto } from './Dialogos'
import { CartaoLivro } from '@/features/livro/MovimentosMembro'
import { CartaoConsentimentos } from '@/features/secretaria/Consentimentos'
import {
  useBaptismos, useCargosDoMembro, useContactos, useMatriculasDoMembro, useMembro, useMembrosBasicos, useParticipacao, useTerminarMembro, useValidarMembro,
  type Membro,
} from './api'
import { useCargos } from '@/features/conselho/api'
import { useFamilias } from '@/features/secretaria/api'
import { useClasses } from '@/features/escola-sabatina/api'

const ICONE_CONTACTO = { TELEFONE: Smartphone, TELEFONE_FIXO: Phone, WHATSAPP: MessageCircle, EMAIL: Mail, OUTRO: Phone } as const

function Voltar() {
  return (
    <Link to="/membros" className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground">
      <ArrowLeft className="size-4" /> {t.membros.titulo}
    </Link>
  )
}

function Cabecalho({ m }: { m: Membro }) {
  const { pode } = useSessao()
  const navigate = useNavigate()
  const validar = useValidarMembro(m.id)
  const terminar = useTerminarMembro(m.id)
  const [confirmar, setConfirmar] = useState(false)
  const anos = idade(m.dataNascimento)
  const nome = `${m.nome} ${m.apelido}`
  const podeAprovar = m.validacao === 'PENDENTE' && pode('secretaria.membro.validar')

  return (
    <section className="mb-6 rounded-xl border bg-card p-5 shadow-card sm:p-6">
      <div className="flex flex-col gap-5 sm:flex-row sm:items-center">
        <Avatar id={m.id} nome={m.nome} apelido={m.apelido} tamanho={64} />
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <h1 className="text-2xl font-semibold tracking-tight">{nome}</h1>
            <PilulasMembro m={m} />
          </div>
          <div className="mt-2 flex flex-wrap items-center gap-x-5 gap-y-1.5 text-sm text-muted-foreground">
            {anos != null && <span className="inline-flex items-center gap-1.5"><Cake className="size-4" />{f(t.ficha.idade, { n: anos })}</span>}
            {m.bairro && <span className="inline-flex items-center gap-1.5"><MapPin className="size-4" />{m.bairro}</span>}
            {m.dataEntrada && <span className="inline-flex items-center gap-1.5"><CalendarCheck className="size-4" />Na igreja desde {data(m.dataEntrada)}</span>}
          </div>
        </div>
        <div className="flex flex-wrap gap-2">
          {podeAprovar && (
            <Button className="alvo" disabled={validar.isPending}
              onClick={() => validar.mutate(undefined, { onSuccess: () => toast.success(t.membros.aprovado), onError: (e) => toast.error(mensagemDe(e)) })}>
              <Check className="size-4" /> {validar.isPending ? t.comum.aGravar : t.membros.aprovar}
            </Button>
          )}
          {pode('secretaria.membro.alterar') && (
            <Button asChild variant="outline" className="alvo"><Link to={`/membros/${m.id}/editar`}><Pencil className="size-4" /> {t.comum.editar}</Link></Button>
          )}
          {pode('secretaria.membro.terminar') && (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="outline" size="icon" aria-label="Mais acções" className="alvo"><MoreHorizontal className="size-4" /></Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onSelect={() => setConfirmar(true)} className="text-destructive-text focus:text-destructive-text">
                  <UserX className="size-4" /> {t.membros.terminar}
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          )}
        </div>
      </div>
      <DialogoConfirmar
        aberto={confirmar} aoMudar={setConfirmar} titulo={f(t.membros.terminarTitulo, { nome })} texto={t.membros.terminarTexto}
        accao={t.membros.terminar} perigo aCorrer={terminar.isPending}
        aoConfirmar={() => terminar.mutate(undefined, {
          onSuccess: () => { toast.success(t.membros.terminado); navigate('/membros') },
          onError: (e) => { toast.error(mensagemDe(e)); setConfirmar(false) },
        })}
      />
    </section>
  )
}

function Grelha({ titulo, children }: { titulo?: string; children: React.ReactNode }) {
  return (
    <div className="border-t pt-5 first:border-t-0 first:pt-0">
      {titulo && <h3 className="mb-3 text-sm font-semibold">{titulo}</h3>}
      <dl className="grid grid-cols-2 gap-x-4 gap-y-4 sm:gap-x-6 xl:grid-cols-3">{children}</dl>
    </div>
  )
}

function Ficha({ m }: { m: Membro }) {
  const basicos = useMembrosBasicos()
  const doc = m.tipoIdentificacao ? `${rotulos.tipoIdentificacao[m.tipoIdentificacao]}${m.numeroIdentificacao ? ` · ${m.numeroIdentificacao}` : ''}` : m.numeroIdentificacao
  const conjuge = m.conjugeMembroId ? basicos.data?.find((b) => b.id === m.conjugeMembroId) : undefined
  const familias = useFamilias()
  return (
    <div className="grid gap-6 lg:col-span-8">
      <Cartao titulo="Dados pessoais" descricao="Identificação e documentos" icone={IdCard}>
        <Grelha>
          <Campo rotulo={t.ficha.dataNascimento}>{m.dataNascimento && data(m.dataNascimento)}</Campo>
          <Campo rotulo={t.ficha.sexo}>{m.sexo && rotulos.sexo[m.sexo]}</Campo>
          <Campo rotulo="Local de nascimento">{m.naturalidade}</Campo>
          <Campo rotulo={t.ficha.nacionalidade}>{m.nacionalidade}</Campo>
          <Campo rotulo={t.ficha.tipoIdentificacao}>{doc}</Campo>
          <Campo rotulo={t.ficha.outroDocumento}>{m.outroDocumento}</Campo>
        </Grelha>
      </Cartao>
      <Cartao titulo="Dados familiares" descricao="Estado civil, cônjuge e filiação" icone={Heart}>
        <div className="grid gap-5">
          <Grelha>
            <Campo rotulo={t.ficha.estadoCivil}>{m.estadoCivil && rotulos.estadoCivil[m.estadoCivil]}</Campo>
            <Campo rotulo={t.ficha.dataCasamento}>{m.dataCasamento && data(m.dataCasamento)}</Campo>
            <Campo rotulo="Cônjuge">
              {conjuge ? <Link to={`/membros/${conjuge.id}`} className="font-medium text-primary hover:underline">{conjuge.nome} {conjuge.apelido}</Link>
                : m.conjugeMembroId ? 'Membro de outra igreja' : m.nomeConjuge}
            </Campo>
            <Campo rotulo={t.ficha.dependentes}>{m.dependentes != null ? String(m.dependentes) : null}</Campo>
            <Campo rotulo="Família">
              {m.familiaId ? <Link to={`/familias?familia=${m.familiaId}`} className="font-medium text-primary hover:underline">{familias.data?.find((x) => x.id === m.familiaId)?.nome ?? 'Ver a família'}</Link> : null}
              {m.parentesco ? <span className="text-muted-foreground"> · {rotulos.parentesco[m.parentesco]}</span> : null}
            </Campo>
          </Grelha>
          <Grelha titulo={t.ficha.filiacao}>
            <Campo rotulo={t.ficha.nomePai}>{m.nomePai}</Campo>
            <Campo rotulo={t.ficha.nomeMae}>{m.nomeMae}</Campo>
          </Grelha>
        </div>
      </Cartao>
      <Cartao titulo="Residência" descricao="Onde vive e endereço postal" icone={MapPin}>
        <Grelha>
          <Campo rotulo={t.ficha.provincia}>{m.provincia}</Campo>
          <Campo rotulo={t.ficha.cidadeDistrito}>{m.cidadeDistrito}</Campo>
          <Campo rotulo={t.ficha.bairro}>{m.bairro}</Campo>
          <Campo rotulo={`${t.ficha.quarteirao} · ${t.ficha.numeroCasa}`}>{[m.quarteirao, m.numeroCasa].filter(Boolean).join(' · ')}</Campo>
          <Campo rotulo={t.ficha.morada}>{m.morada}</Campo>
          <Campo rotulo={t.ficha.enderecoPostal}>{[m.enderecoPostal, m.codigoPostal].filter(Boolean).join(' · ')}</Campo>
        </Grelha>
      </Cartao>
      <Cartao titulo="Profissão, estudos e conversão" icone={Briefcase}>
        <Grelha>
          <Campo rotulo={t.ficha.profissao}>{m.profissao}</Campo>
          <Campo rotulo={t.ficha.localTrabalho}>{m.localTrabalho}</Campo>
          <Campo rotulo="Nível académico">{m.escolaridade && rotulos.escolaridade[m.escolaridade]}</Campo>
          <Campo rotulo={t.ficha.religiaoAnterior}>{m.religiaoAnterior}</Campo>
          <Campo rotulo={t.ficha.metodoConversao}>{m.metodoConversao}</Campo>
          <Campo rotulo="Ex-membro">{m.exMembro ? 'Sim (rebaptizado)' : null}</Campo>
        </Grelha>
      </Cartao>
      <Participacao m={m} />
    </div>
  )
}

/** Participação na igreja: entrada no livro, cargos (mandatos) e classe da Escola Sabatina, lidos dos respectivos módulos. */
function Participacao({ m }: { m: Membro }) {
  const { pode, igreja } = useSessao()
  const veCargos = pode('secretaria.oficial.ler')
  const veClasse = pode('escola_sabatina.matricula.ler')
  const oficiais = useCargosDoMembro(m.id, m.igrejaId, veCargos)
  const cargos = useCargos()
  const matriculas = useMatriculasDoMembro(m.id, veClasse)
  const classes = useClasses()
  const hoje = new Date().toISOString().slice(0, 10)
  const actuais = (oficiais.data ?? []).filter((o) => !o.dataFim || o.dataFim >= hoje)
  const nomeCargo = (id?: number | null) => cargos.data?.find((c) => c.id === id)?.nome ?? 'Cargo'
  const matricula = (matriculas.data ?? []).find((x) => !x.dataSaida)
  const classe = matricula ? classes.data?.find((c) => c.id === matricula.classeId) : undefined
  const participacao = useParticipacao(pode('secretaria.membro.ler'))
  const minha = participacao.data?.find((p) => p.membroId === m.id)
  return (
    <Cartao titulo="Participação na igreja" descricao="Entrada no livro de membros, cargos e Escola Sabatina" icone={Church}>
      <Grelha>
        <Campo rotulo="Igreja ou grupo">{igreja?.nome}</Campo>
        <Campo rotulo={t.ficha.dataEntrada}>{m.dataEntrada && data(m.dataEntrada)}</Campo>
        <Campo rotulo={t.ficha.modoEntrada}>{m.modoEntrada && rotulos.modoEntrada[m.modoEntrada]}</Campo>
        <Campo rotulo={t.ficha.validacao}>{m.validacao && rotulos.validacao[m.validacao]}</Campo>
        {minha && (
          <Campo rotulo="Última participação">
            {minha.ultimaParticipacao ? data(minha.ultimaParticipacao) : 'Sem registo'}
            {minha.inactivo && <Pilula variante="warning" className="ml-2">Inactivo</Pilula>}
          </Campo>
        )}
        {veCargos && (
          <Campo rotulo="Cargos actuais">
            {actuais.length ? actuais.map((o) => `${nomeCargo(o.cargoId)}${o.fimPrevisto ? ` (até ${data(o.fimPrevisto)})` : ''}`).join(' · ') : null}
          </Campo>
        )}
        {veClasse && (
          <Campo rotulo="Classe da Escola Sabatina">
            {classe ? `${classe.nome}${matricula?.dataEntrada ? ` · desde ${data(matricula.dataEntrada)}` : ''}` : null}
          </Campo>
        )}
      </Grelha>
    </Cartao>
  )
}

function Contactos({ m }: { m: Membro }) {
  const { pode } = useSessao()
  const q = useContactos(m.id)
  const lista = q.data ?? []
  return (
    <Cartao titulo={t.contactos.titulo} descricao="Telefone principal recebe os SMS" icone={Phone} semMargem
      accoes={pode('secretaria.contacto.criar') && (
        <DialogoContacto membroId={m.id} igrejaId={m.igrejaId} primeiro={lista.length === 0}
          gatilho={<Button variant="outline" size="icon" aria-label={t.contactos.adicionar} className="alvo size-8"><Plus className="size-4" /></Button>} />
      )}>
      {q.isPending ? <div className="px-6 pb-6"><Barra className="h-10 w-full" /></div>
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="mx-6 mb-6" />
        : lista.length === 0 ? <EstadoVazio icone={Phone} className="py-6">{t.contactos.nenhum}</EstadoVazio>
        : (
          <ul className="pb-2">
            {lista.map((c) => {
              const Icone = ICONE_CONTACTO[c.tipo ?? 'OUTRO']
              const href = c.tipo === 'EMAIL' ? `mailto:${c.valor}` : c.tipo === 'WHATSAPP' ? `https://wa.me/${c.valor?.replace(/\D/g, '')}` : `tel:${c.valor?.replace(/\s/g, '')}`
              return (
                <li key={c.id} className="flex min-h-14 items-center gap-3 border-t px-5 py-2.5 first:border-t-0 sm:px-6">
                  <span className="flex size-8 flex-none items-center justify-center rounded-lg bg-muted text-muted-foreground" aria-hidden><Icone className="size-4" /></span>
                  <div className="min-w-0 flex-1">
                    <a href={href} className="num block truncate text-sm font-medium hover:text-primary">{c.valor}</a>
                    <span className="text-xs text-muted-foreground">{c.tipo && rotulos.tipoContacto[c.tipo]}</span>
                  </div>
                  {c.principal && <Pilula variante="info"><Star className="size-3 fill-current" aria-hidden />Principal</Pilula>}
                </li>
              )
            })}
          </ul>
        )}
    </Cartao>
  )
}

function Baptismos({ m }: { m: Membro }) {
  const { pode, igrejas } = useSessao()
  const q = useBaptismos(m.id)
  const lista = q.data ?? []
  const nomeIgreja = (id?: number | null) => igrejas.find((i) => i.id === id)?.nome
  return (
    <Cartao titulo={t.baptismo.titulo} descricao="Data, local e pastor oficiante" icone={Droplets}
      accoes={pode('secretaria.baptismo.criar') && (
        <DialogoBaptismo membroId={m.id}
          gatilho={<Button variant="outline" size="icon" aria-label={t.baptismo.registar} className="alvo size-8"><Plus className="size-4" /></Button>} />
      )}>
      {q.isPending ? <Barra className="h-12 w-full" />
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
        : lista.length === 0 ? <EstadoVazio icone={Droplets} className="py-4">{t.baptismo.nenhum}</EstadoVazio>
        : (
          <ol className="grid gap-4">
            {lista.map((b) => (
              <li key={b.id} className="relative border-l-2 border-primary/30 pl-4">
                <p className="flex items-center gap-2 text-sm font-semibold">
                  <span className="num">{data(b.data)}</span>
                  {b.rebaptismo && <Pilula variante="secondary">Rebaptismo</Pilula>}
                </p>
                <dl className="mt-2 grid gap-1.5 text-sm">
                  {b.local && <div className="flex gap-2"><dt className="w-16 flex-none text-muted-foreground">Local</dt><dd>{b.local}</dd></div>}
                  {nomeIgreja(b.localIgrejaId) && <div className="flex gap-2"><dt className="w-16 flex-none text-muted-foreground">Igreja</dt><dd>{nomeIgreja(b.localIgrejaId)}</dd></div>}
                  {b.oficiante && <div className="flex gap-2"><dt className="w-16 flex-none text-muted-foreground">Pastor</dt><dd>{b.oficiante}</dd></div>}
                </dl>
              </li>
            ))}
          </ol>
        )}
    </Cartao>
  )
}

export default function PaginaMembro() {
  const id = Number(useParams().id)
  const q = useMembro(id)

  if (q.isPending) {
    return (
      <>
        <Voltar />
        <div className="mb-6 flex items-center gap-5 rounded-xl border bg-card p-6 shadow-card" aria-busy="true" aria-label="A carregar">
          <Barra className="size-16 rounded-full" /><div className="grid gap-2"><Barra className="h-7 w-56" /><Barra className="h-4 w-72" /></div>
        </div>
      </>
    )
  }
  if (q.isError) {
    return (
      <>
        <Voltar />
        {q.error instanceof ErroApi && q.error.naoEncontrado
          ? <div className="rounded-xl border bg-card shadow-card"><EstadoVazio icone={UserX} titulo="Membro não encontrado">Este membro não existe ou não pertence às igrejas a que tem acesso.</EstadoVazio></div>
          : <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />}
      </>
    )
  }
  const m = q.data
  return (
    <>
      <Voltar />
      <Cabecalho m={m} />
      <div className="grid items-start gap-6 lg:grid-cols-12">
        <Ficha m={m} />
        <div className="grid gap-6 lg:sticky lg:top-[calc(var(--header-height)+1.5rem)] lg:col-span-4">
          <CartaoLivro m={m} />
          <Contactos m={m} />
          <Baptismos m={m} />
          <CartaoConsentimentos m={m} />
        </div>
      </div>
    </>
  )
}
