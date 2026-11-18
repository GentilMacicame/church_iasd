/**
 * Novo utilizador numa janela: nome, contactos, membro ligado (opcional) e perfis nesta igreja. Sem senha: depois de
 * registar abre-se a ficha do utilizador, onde se manda o código por SMS para ele definir a senha.
 */
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { CampoFormulario, ErroFormulario } from '@/components/comum/formulario'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { ErroApi, mensagemDe } from '@/api/erros'
import { useIgreja } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { traduzirPermissoes, useGravarUtilizador, usePerfis, usePermissoes } from './api'
import { nomePerfil } from './PaginaAcessos'

const TELEFONE = /^\+?(258)?\s?8[2-7](\s?\d){7}$/

export function DialogoNovoUtilizador({ aoFechar }: { aoFechar: () => void }) {
  const navigate = useNavigate()
  const igreja = useIgreja()
  const perfis = usePerfis()
  const basicos = useMembrosBasicos()
  const gravar = useGravarUtilizador()
  const permissoes = usePermissoes()
  const [nome, setNome] = useState('')
  const [email, setEmail] = useState('')
  const [telefone, setTelefone] = useState('')
  const [membroId, setMembroId] = useState<number | null>(null)
  const [escolhidos, setEscolhidos] = useState<number[]>([])
  const [erro, setErro] = useState<string | null>(null)
  const [erros, setErros] = useState<Record<string, string>>({})
  const daIgreja = (perfis.data ?? []).filter((p) => p.ambito === 'IGREJA' && !p.endDate && p.codigo !== 'MEMBRO')
  const nomeDe = (mid: number) => { const m = basicos.data?.find((x) => x.id === mid); return m && `${m.nome} ${m.apelido}` }
  const trocar = (pid: number) => setEscolhidos((l) => (l.includes(pid) ? l.filter((x) => x !== pid) : [...l, pid]))

  const submeter = async () => {
    setErro(null)
    const e: Record<string, string> = {}
    if (nome.trim().length < 3) e.nome = 'Escreva o nome completo'
    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) e.email = 'E-mail inválido'
    if (!telefone.trim()) e.telefone = 'Recebe o código por SMS'
    else if (!TELEFONE.test(telefone.trim())) e.telefone = 'ex.: +258 84 123 4567'
    if (!escolhidos.length) e.perfis = 'Escolha pelo menos um perfil'
    setErros(e)
    if (Object.keys(e).length) return
    try {
      const r = await gravar.mutateAsync({
        actuais: [], dadosU: { nome: nome.trim(), email: email.trim().toLowerCase(), telefone: telefone.replace(/\s+/g, ''), membroId }, perfis: escolhidos,
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
      <DialogContent className="sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>Novo utilizador</DialogTitle>
          <DialogDescription>Define a senha com o código que recebe por SMS.</DialogDescription>
        </DialogHeader>
        <ErroFormulario mensagem={erro} />
        <div className="grid gap-4 sm:grid-cols-2">
          <CampoFormulario rotulo="Nome completo" erro={erros.nome} obrigatorio className="sm:col-span-2">
            {(p) => <Input {...p} value={nome} onChange={(e) => setNome(e.target.value)} maxLength={150} autoComplete="off" placeholder="ex.: Ana Machava" className="alvo" autoFocus />}
          </CampoFormulario>
          <CampoFormulario rotulo="Telemóvel" erro={erros.telefone} obrigatorio>
            {(p) => <Input {...p} type="tel" inputMode="tel" value={telefone} onChange={(e) => setTelefone(e.target.value)} maxLength={20} placeholder="+258 84 123 4567" className="alvo num" />}
          </CampoFormulario>
          <CampoFormulario rotulo="E-mail" erro={erros.email}>
            {(p) => <Input {...p} type="email" value={email} onChange={(e) => setEmail(e.target.value)} maxLength={150} autoComplete="off" placeholder="nome@exemplo.co.mz" className="alvo" />}
          </CampoFormulario>
          <CampoFormulario rotulo="Membro da igreja" className="sm:col-span-2">
            {(p) => <CampoMembro id={p.id} valor={membroId} aoMudar={setMembroId} nomeDe={nomeDe} vazio="Sem membro ligado (opcional)" />}
          </CampoFormulario>
        </div>
        <fieldset className="grid gap-2">
          <legend className="mb-2 text-sm font-medium">Perfis em {igreja.nome} <span className="text-destructive-text">*</span></legend>
          <div className="grid gap-2 sm:grid-cols-2">
            {daIgreja.map((p) => {
              const sim = escolhidos.includes(p.id)
              return (
                <label key={p.id} title={p.descricao ?? undefined}
                  className={cn('alvo flex cursor-pointer items-start gap-2.5 rounded-lg border px-3 py-2.5 transition-colors hover:bg-muted/50', sim && 'border-primary bg-primary/5')}>
                  <input type="checkbox" className="mt-0.5 size-4 accent-[var(--primary)]" checked={sim} onChange={() => trocar(p.id)} />
                  <span className="min-w-0">
                    <span className="block text-sm font-medium">{nomePerfil(p)}</span>
                    {p.descricao && <span className="block truncate text-xs text-muted-foreground">{p.descricao.replace(/^[^:]+:\s*/, '')}</span>}
                  </span>
                </label>
              )
            })}
          </div>
          {erros.perfis && <p className="text-sm font-medium text-destructive-text">{erros.perfis}</p>}
        </fieldset>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={gravar.isPending} onClick={submeter}>{gravar.isPending ? t.comum.aGravar : 'Registar utilizador'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
