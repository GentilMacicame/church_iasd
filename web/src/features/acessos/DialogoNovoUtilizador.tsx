/**
 * Novo utilizador numa janela: um membro da igreja (o nome vem da ficha), os contactos e o perfil nesta igreja. Sem senha: depois de
 * registar abre-se a ficha do utilizador, onde se manda o código por SMS para ele definir a senha.
 */
import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { CampoFormulario, ErroFormulario } from '@/components/comum/formulario'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { ErroApi, mensagemDe } from '@/api/erros'
import { t } from '@/i18n/pt-MZ'
import { contactoDoTipo, useContactos, useMembrosBasicos } from '@/features/membros/api'
import { Seleccao } from '@/components/comum/Seleccao'
import { Avatar } from '@/components/comum/elementos'
import { traduzirPermissoes, useGravarUtilizador, usePerfis, usePermissoes } from './api'
import { nomePerfil } from './PaginaAcessos'

const TELEFONE = /^\+?(258)?\s?8[2-7](\s?\d){7}$/

export function DialogoNovoUtilizador({ aoFechar }: { aoFechar: () => void }) {
  const navigate = useNavigate()
  const perfis = usePerfis()
  const basicos = useMembrosBasicos()
  const gravar = useGravarUtilizador()
  const permissoes = usePermissoes()
  const [email, setEmail] = useState('')
  const [telefone, setTelefone] = useState('')
  const [membroId, setMembroId] = useState<number | null>(null)
  const [perfil, setPerfil] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const [erros, setErros] = useState<Record<string, string>>({})
  const daIgreja = (perfis.data ?? []).filter((p) => p.ambito === 'IGREJA' && !p.endDate && p.codigo !== 'MEMBRO')
  const nomeDe = (mid: number) => { const m = basicos.data?.find((x) => x.id === mid); return m && `${m.nome} ${m.apelido}` }
  // o utilizador é um membro: o nome vem da ficha, e o telemóvel e o e-mail também, se lá estiverem
  const membro = basicos.data?.find((x) => x.id === membroId)
  const nome = membro ? `${membro.nome} ${membro.apelido}` : ''
  const contactos = useContactos(membroId ?? 0)
  useEffect(() => {
    if (!contactos.data) return
    setTelefone(contactoDoTipo(contactos.data, 'TELEFONE')?.valor ?? '')
    setEmail(contactoDoTipo(contactos.data, 'EMAIL')?.valor ?? '')
  }, [contactos.data])

  const submeter = async () => {
    setErro(null)
    const e: Record<string, string> = {}
    if (!membro) e.membro = 'Escolha o membro'
    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) e.email = 'E-mail inválido'
    if (!telefone.trim()) e.telefone = 'Recebe o código por SMS'
    else if (!TELEFONE.test(telefone.trim())) e.telefone = 'ex.: +258 84 123 4567'
    if (!perfil) e.perfis = 'Escolha o perfil'
    setErros(e)
    if (Object.keys(e).length) return
    try {
      const r = await gravar.mutateAsync({
        actuais: [], dadosU: { nome: nome.trim(), email: email.trim().toLowerCase(), telefone: telefone.replace(/\s+/g, ''), membroId }, perfis: [Number(perfil)],
      })
      toast.success('Utilizador registado. Mande-lhe o código para definir a senha.')
      navigate(`/acessos/utilizadores/${r.id}`)
    } catch (err) {
      const m = traduzirPermissoes(mensagemDe(err), permissoes.data)
      if (err instanceof ErroApi && err.campo) setErros({ [err.campo]: m })
      else setErro(m)
    }
  }

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Novo utilizador</DialogTitle>
          <DialogDescription>Um membro da igreja; define a senha com o código que recebe por SMS.</DialogDescription>
        </DialogHeader>
        <ErroFormulario mensagem={erro} />
        <div className="grid gap-4 sm:grid-cols-2">
          <CampoFormulario rotulo="Membro" erro={erros.membro} obrigatorio className="sm:col-span-2">
            {(p) => <CampoMembro id={p.id} valor={membroId} aoMudar={setMembroId} nomeDe={nomeDe} vazio="Procurar o membro…" />}
          </CampoFormulario>
          {membro && (
            <div className="flex items-center gap-3 rounded-xl border bg-muted/30 px-3 py-2.5 sm:col-span-2">
              <Avatar id={membro.id} nome={membro.nome} apelido={membro.apelido} tamanho={36} />
              <span className="min-w-0"><span className="block truncate text-sm font-medium">{nome}</span><span className="block text-xs text-muted-foreground">Nome da ficha do membro</span></span>
            </div>
          )}
          <CampoFormulario rotulo="Telemóvel" erro={erros.telefone} obrigatorio>
            {(p) => <Input {...p} type="tel" inputMode="tel" value={telefone} onChange={(e) => setTelefone(e.target.value)} maxLength={20} placeholder="+258 84 123 4567" className="alvo num" />}
          </CampoFormulario>
          <CampoFormulario rotulo="E-mail" erro={erros.email}>
            {(p) => <Input {...p} type="email" value={email} onChange={(e) => setEmail(e.target.value)} maxLength={150} autoComplete="off" placeholder="nome@exemplo.co.mz" className="alvo" />}
          </CampoFormulario>
          <CampoFormulario rotulo="Perfil" erro={erros.perfis} obrigatorio className="sm:col-span-2"
            ajuda={daIgreja.find((x) => String(x.id) === perfil)?.descricao?.replace(/^[^:]+:\s*/, '') ?? undefined}>
            {(p) => (
              <Seleccao {...p} value={perfil} onChange={(e) => setPerfil(e.target.value)}>
                <option value="">Escolher o perfil…</option>
                {daIgreja.map((x) => <option key={x.id} value={x.id}>{nomePerfil(x)}</option>)}
              </Seleccao>
            )}
          </CampoFormulario>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={gravar.isPending} onClick={submeter}>{gravar.isPending ? t.comum.aGravar : 'Registar utilizador'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
