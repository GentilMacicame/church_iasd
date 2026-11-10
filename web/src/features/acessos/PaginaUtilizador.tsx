/**
 * Novo / editar utilizador · dados, membro ligado e perfis nesta igreja; ao lado, o estado da conta.
 * Sem senha: o utilizador define-a com o código que recebe por SMS ("Esqueci a senha" na entrada, ou o
 * administrador manda-lhe o código daqui). A base de dados recusa dar a si próprio perfis ou dar um perfil
 * com mais permissões do que as de quem o dá.
 */
import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, KeyRound, MessageSquareText, Power, Save, Send, UserRound } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Cartao, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { CampoFormulario, ErroFormulario } from '@/components/comum/formulario'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { ErroApi, mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { data, dataPorExtenso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { traduzirPermissoes, useEnviarCodigo, useEstadoUtilizador, useGravarUtilizador, usePerfis, usePerfisDaIgreja, usePermissoes, useUsuario } from './api'
import { PilulaUtilizador, estadoDe, nomePerfil } from './PaginaAcessos'

const TELEFONE = /^\+?(258)?\s?8[2-7](\s?\d){7}$/

export default function PaginaUtilizador() {
  const params = useParams()
  const id = params.id ? Number(params.id) : 0
  const editar = id > 0
  const navigate = useNavigate()
  const igreja = useIgreja()
  const { usuario: eu } = useSessao()
  const u = useUsuario(id)
  const perfis = usePerfis()
  const ligacoes = usePerfisDaIgreja()
  const basicos = useMembrosBasicos()
  const gravar = useGravarUtilizador()
  const enviar = useEnviarCodigo()
  const estado = useEstadoUtilizador()
  const permissoes = usePermissoes()

  const [nome, setNome] = useState('')
  const [email, setEmail] = useState('')
  const [telefone, setTelefone] = useState('')
  const [membroId, setMembroId] = useState<number | null>(null)
  const [escolhidos, setEscolhidos] = useState<number[]>([])
  const [erro, setErro] = useState<string | null>(null)
  const [erros, setErros] = useState<Record<string, string>>({})
  const [alternar, setAlternar] = useState(false)
  const [carregado, setCarregado] = useState(false)

  const actuais = useMemo(() => (ligacoes.data ?? []).filter((l) => l.usuarioId === id && !l.endDate), [ligacoes.data, id])
  const daIgreja = (perfis.data ?? []).filter((p) => p.ambito === 'IGREJA' && !p.endDate && p.nome !== 'MEMBRO')
  const nomeDe = (mid: number) => { const m = basicos.data?.find((x) => x.id === mid); return m && `${m.nome} ${m.apelido}` }

  useEffect(() => {
    if (carregado || !editar || !u.data || !ligacoes.data) return
    setNome(u.data.nome); setEmail(u.data.email ?? ''); setTelefone(u.data.telefone ?? ''); setMembroId(u.data.membroId ?? null)
    setEscolhidos(actuais.map((a) => a.perfilId)); setCarregado(true)
  }, [carregado, editar, u.data, ligacoes.data, actuais])

  const proprio = editar && u.data?.id === eu?.id
  const trocar = (pid: number) => setEscolhidos((l) => (l.includes(pid) ? l.filter((x) => x !== pid) : [...l, pid]))

  const submeter = async () => {
    setErro(null)
    const e: Record<string, string> = {}
    if (nome.trim().length < 3) e.nome = 'Escreva o nome completo'
    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) e.email = 'E-mail inválido'
    if (!telefone.trim()) e.telefone = 'O telemóvel recebe o código para definir a senha'
    else if (!TELEFONE.test(telefone.trim())) e.telefone = 'Escreva um telemóvel de Moçambique, ex.: +258 84 123 4567'
    if (!editar && !escolhidos.length) e.perfis = 'Escolha pelo menos um perfil'
    setErros(e)
    if (Object.keys(e).length) return
    try {
      const r = await gravar.mutateAsync({
        id: editar ? id : undefined, actuais,
        dadosU: { nome: nome.trim(), email: email.trim().toLowerCase(), telefone: telefone.replace(/\s+/g, ''), membroId },
        perfis: escolhidos,
      })
      toast.success(editar ? 'Alterações guardadas.' : 'Utilizador registado. Mande-lhe o código para definir a senha.')
      if (!editar) navigate(`/acessos/utilizadores/${r.id}`, { replace: true })
    } catch (err) {
      const m = traduzirPermissoes(mensagemDe(err), permissoes.data)
      if (err instanceof ErroApi && err.campo) setErros({ [err.campo]: m })
      else setErro(m)
    }
  }

  const voltar = <Link to="/acessos" className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" /> Utilizadores e perfis</Link>
  if (editar && u.isError) return <>{voltar}{u.error instanceof ErroApi && u.error.naoEncontrado
    ? <div className="rounded-xl border bg-card shadow-card"><EstadoVazio icone={UserRound} titulo="Utilizador não encontrado">Não existe ou não o pode ver.</EstadoVazio></div>
    : <EstadoErro erro={u.error} aoTentar={() => u.refetch()} />}</>
  if ((editar && (u.isPending || !carregado)) || perfis.isPending || ligacoes.isPending) return <>{voltar}<Barra className="h-96 w-full" /></>

  const conta = u.data
  return (
    <>
      <TituloPagina antes={voltar} icone={UserRound} titulo={editar ? 'Editar utilizador' : 'Novo utilizador'}
        descricao={editar ? `Dados, membro ligado e perfis de ${conta?.nome} em ${igreja.nome}.` : 'Registe o utilizador; ele define a senha com o código que recebe por SMS.'} />
      <div className="grid items-start gap-6 xl:grid-cols-[minmax(0,1fr)_340px]">
        <div className="grid min-w-0 gap-6">
          <ErroFormulario mensagem={erro} />
          <Cartao titulo="Dados do utilizador" descricao="Entra com o e-mail ou o telemóvel; o telemóvel recebe o código para definir a senha." icone={UserRound}>
            <div className="grid gap-4 md:grid-cols-2">
              <CampoFormulario rotulo="Nome completo" erro={erros.nome} obrigatorio className="md:col-span-2">
                {(p) => <Input {...p} value={nome} onChange={(e) => setNome(e.target.value)} maxLength={150} autoComplete="off" placeholder="ex.: Ana Machava" className="alvo" />}
              </CampoFormulario>
              <CampoFormulario rotulo="E-mail" erro={erros.email}>
                {(p) => <Input {...p} type="email" value={email} onChange={(e) => setEmail(e.target.value)} maxLength={150} autoComplete="off" placeholder="nome@exemplo.co.mz" className="alvo" />}
              </CampoFormulario>
              <CampoFormulario rotulo="Telemóvel" erro={erros.telefone} obrigatorio ajuda="Recebe o código por SMS.">
                {(p) => <Input {...p} type="tel" inputMode="tel" value={telefone} onChange={(e) => setTelefone(e.target.value)} maxLength={20} placeholder="+258 84 123 4567" className="alvo num" />}
              </CampoFormulario>
              <CampoFormulario rotulo="Membro da igreja" ajuda="Opcional. Ligado ao membro, vê as suas contribuições e escalas." className="md:col-span-2">
                {(p) => <CampoMembro id={p.id} valor={membroId} aoMudar={setMembroId} nomeDe={nomeDe} vazio="Sem membro ligado" />}
              </CampoFormulario>
            </div>
          </Cartao>

          <Cartao titulo="Acesso nesta igreja" descricao={`Os perfis definem o que o utilizador pode ver e fazer em ${igreja.nome}.`} icone={KeyRound}>
            {proprio && <p className="mb-4 rounded-lg border border-warning/30 bg-tint-warning px-4 py-3 text-sm text-warning-text">Não pode alterar os seus próprios perfis: peça a outro administrador.</p>}
            {conta?.superAdmin && <p className="mb-4 rounded-lg border border-info/30 bg-tint-info px-4 py-3 text-sm text-info-text">Super-administrador: tem acesso total a todas as igrejas, com ou sem perfis.</p>}
            <fieldset>
              <legend className="mb-3 text-sm font-medium">Perfis {!editar && <span className="text-destructive-text">*</span>}</legend>
              <div className="grid gap-3 md:grid-cols-2">
                {daIgreja.map((p) => (
                  <label key={p.id} className={cn('flex cursor-pointer items-start gap-3 rounded-lg border p-4 hover:bg-muted/50', escolhidos.includes(p.id) && 'border-primary bg-primary/5', proprio && 'cursor-not-allowed opacity-60')}>
                    <input type="checkbox" className="mt-0.5 size-4 accent-[var(--primary)]" checked={escolhidos.includes(p.id)} disabled={proprio} onChange={() => trocar(p.id)} />
                    <span className="min-w-0">
                      <span className="block text-sm font-medium">{nomePerfil(p)}</span>
                      {p.descricao && <span className="mt-0.5 block text-xs text-muted-foreground">{p.descricao}</span>}
                    </span>
                  </label>
                ))}
              </div>
              {erros.perfis && <p className="mt-2 text-sm font-medium text-destructive-text">{erros.perfis}</p>}
            </fieldset>
          </Cartao>

          <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
            <Button asChild variant="outline" className="alvo"><Link to="/acessos">{t.comum.cancelar}</Link></Button>
            <Button className="alvo" disabled={gravar.isPending} onClick={submeter}>
              {gravar.isPending ? t.comum.aGravar : editar ? <><Save className="size-4" />Guardar alterações</> : <><UserRound className="size-4" />Registar utilizador</>}
            </Button>
          </div>
        </div>

        <aside className="grid gap-4 xl:sticky xl:top-[calc(var(--header-height)+1.5rem)]">
          {!editar ? (
            <Cartao>
              <span className="flex size-10 items-center justify-center rounded-lg bg-primary/10 text-primary"><MessageSquareText className="size-5" /></span>
              <h2 className="mt-4 font-semibold">Como funciona o acesso</h2>
              <ol className="mt-4 grid gap-4 text-sm text-muted-foreground">
                {['Registe os dados e os perfis. Não é preciso escolher senha.',
                  'Depois de gravar, carregue em "Enviar código por SMS": o utilizador recebe um código de 6 dígitos, válido 15 minutos.',
                  'Na página de entrada, em "Esqueci a senha", escreve o e-mail ou o telemóvel, o código e a senha nova, e passa a entrar.',
                ].map((passo, i) => (
                  <li key={i} className="flex gap-3">
                    <span className="flex size-6 flex-none items-center justify-center rounded-full bg-muted text-xs font-semibold text-foreground">{i + 1}</span>
                    <span>{passo}</span>
                  </li>
                ))}
              </ol>
            </Cartao>
          ) : conta && (
            <Cartao titulo="Estado da conta">
              <dl className="grid gap-3 text-sm">
                <div className="flex items-center justify-between gap-3"><dt className="text-muted-foreground">Estado</dt><dd><PilulaUtilizador u={conta} /></dd></div>
                <div className="flex items-center justify-between gap-3"><dt className="text-muted-foreground">Registado em</dt><dd className="tabular-nums">{data(conta.criadoEm)}</dd></div>
                <div className="flex items-center justify-between gap-3"><dt className="text-muted-foreground">Último acesso</dt><dd className="text-right">{conta.ultimoLogin ? dataPorExtenso(conta.ultimoLogin) : 'Nunca entrou'}</dd></div>
                <div className="flex items-start justify-between gap-3"><dt className="text-muted-foreground">Perfis aqui</dt><dd className="text-right">{actuais.length ? actuais.map((a) => nomePerfil(perfis.data?.find((p) => p.id === a.perfilId))).join(', ') : '—'}</dd></div>
              </dl>
              {estadoDe(conta) !== 'inactivo' && conta.telefone && (
                <>
                  <p className="mt-4 text-sm text-muted-foreground">
                    {estadoDe(conta) === 'por_entrar' ? 'Ainda não definiu a senha. Mande-lhe o código por SMS.' : 'Se esqueceu a senha, pode mandar-lhe um código novo.'}
                  </p>
                  <Button variant="outline" className="alvo mt-3 w-full" disabled={enviar.isPending}
                    onClick={() => enviar.mutate(conta.email || conta.telefone || '', {
                      onSuccess: () => toast.success(`Código enviado por SMS para ${conta.telefone}.`),
                      onError: (e) => toast.error(mensagemDe(e)),
                    })}>
                    <Send className="size-4" />{enviar.isPending ? 'A enviar…' : 'Enviar código por SMS'}
                  </Button>
                </>
              )}
              {!proprio && (
                <Button variant="outline" className={cn('alvo mt-3 w-full', !conta.endDate && 'text-destructive-text hover:text-destructive-text')} onClick={() => setAlternar(true)}>
                  <Power className="size-4" />{conta.endDate ? 'Reactivar conta' : 'Desactivar conta'}
                </Button>
              )}
            </Cartao>
          )}
        </aside>
      </div>

      {conta && (
        <DialogoConfirmar aberto={alternar} aoMudar={setAlternar}
          titulo={conta.endDate ? `Reactivar a conta de ${conta.nome}?` : `Desactivar a conta de ${conta.nome}?`}
          texto={conta.endDate ? 'Volta a poder entrar com a sua senha.' : 'Deixa de poder entrar e as sessões abertas terminam. Fica no histórico e pode ser reactivada.'}
          accao={conta.endDate ? 'Reactivar' : 'Desactivar'} perigo={!conta.endDate} aCorrer={estado.isPending}
          aoConfirmar={() => estado.mutate({ id: conta.id, activar: !!conta.endDate }, {
            onSuccess: () => { toast.success(conta.endDate ? 'Conta reactivada.' : 'Conta desactivada.'); setAlternar(false); u.refetch() },
            onError: (e) => { toast.error(mensagemDe(e)); setAlternar(false) },
          })} />
      )}
    </>
  )
}
