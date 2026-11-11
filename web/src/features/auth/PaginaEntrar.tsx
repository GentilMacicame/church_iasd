import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Navigate, useLocation, useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { CampoFormulario, ErroFormulario } from '@/components/comum/formulario'
import { Marca } from '@/components/layout/Marca'
import { useSessao } from '@/auth/sessao'
import { api, dados } from '@/api/cliente'
import { mensagemDe } from '@/api/erros'
import { t } from '@/i18n/pt-MZ'

const esquemaEntrar = z.object({
  login: z.string().trim().min(1, t.comum.obrigatorio),
  senha: z.string().min(1, t.comum.obrigatorio),
})

function FormEntrar({ aoEsquecer }: { aoEsquecer: () => void }) {
  const { entrar, terminadaPorExpirar } = useSessao()
  const navigate = useNavigate()
  const destino = (useLocation().state as { de?: string } | null)?.de ?? '/'
  const [erro, setErro] = useState<string | null>(terminadaPorExpirar ? t.entrar.sessaoTerminada : null)
  const form = useForm({ resolver: zodResolver(esquemaEntrar), defaultValues: { login: '', senha: '' } })

  const submeter = form.handleSubmit(async ({ login, senha }) => {
    setErro(null)
    try {
      await entrar(login, senha)
      navigate(destino, { replace: true })
    } catch (e) {
      setErro(mensagemDe(e))
    }
  })

  return (
    <form onSubmit={submeter} noValidate className="grid gap-5">
      <ErroFormulario mensagem={erro} />
      <CampoFormulario rotulo={t.entrar.login} erro={form.formState.errors.login?.message}>
        {(p) => <Input {...p} {...form.register('login')} autoComplete="username" inputMode="email" autoFocus className="alvo h-11" />}
      </CampoFormulario>
      <CampoFormulario rotulo={t.entrar.senha} erro={form.formState.errors.senha?.message}>
        {(p) => <Input {...p} {...form.register('senha')} type="password" autoComplete="current-password" className="alvo h-11" />}
      </CampoFormulario>
      <Button type="submit" disabled={form.formState.isSubmitting} className="alvo h-12 w-full text-base font-semibold">
        {form.formState.isSubmitting ? t.entrar.aEntrar : t.entrar.botao}
      </Button>
      <button type="button" onClick={aoEsquecer} className="alvo justify-self-center text-sm font-medium text-primary underline underline-offset-4 hover:text-primary/80">
        {t.entrar.esqueci}
      </button>
    </form>
  )
}

const esquemaPedir = z.object({ login: z.string().trim().min(1, t.comum.obrigatorio) })
const esquemaDefinir = z.object({
  codigo: z.string().regex(/^\d{6}$/, 'O código tem 6 dígitos'),
  senha: z.string().min(8, 'Pelo menos 8 caracteres'),
})

function FormRecuperar({ aoVoltar }: { aoVoltar: (msg?: string) => void }) {
  const [login, setLogin] = useState<string | null>(null)
  const [erro, setErro] = useState<string | null>(null)
  const pedir = useForm({ resolver: zodResolver(esquemaPedir), defaultValues: { login: '' } })
  const definir = useForm({ resolver: zodResolver(esquemaDefinir), defaultValues: { codigo: '', senha: '' } })

  if (!login) {
    return (
      <form
        noValidate
        className="grid gap-5"
        onSubmit={pedir.handleSubmit(async (v) => {
          setErro(null)
          try {
            await dados(api.POST('/v1/auth/recuperar', { body: { login: v.login } }))
            setLogin(v.login)
          } catch (e) {
            setErro(mensagemDe(e))
          }
        })}
      >
        <p className="text-muted-foreground">{t.recuperar.subtitulo}</p>
        <ErroFormulario mensagem={erro} />
        <CampoFormulario rotulo={t.entrar.login} erro={pedir.formState.errors.login?.message}>
          {(p) => <Input {...p} {...pedir.register('login')} autoComplete="username" autoFocus className="alvo h-11" />}
        </CampoFormulario>
        <Button type="submit" disabled={pedir.formState.isSubmitting} className="alvo h-11">{t.recuperar.pedir}</Button>
        <Button type="button" variant="ghost" onClick={() => aoVoltar()} className="alvo">{t.comum.voltar}</Button>
      </form>
    )
  }
  return (
    <form
      noValidate
      className="grid gap-5"
      onSubmit={definir.handleSubmit(async (v) => {
        setErro(null)
        try {
          await dados(api.POST('/v1/auth/redefinir', { body: { login, codigo: v.codigo, senha: v.senha } }))
          aoVoltar(t.recuperar.feito)
        } catch (e) {
          setErro(mensagemDe(e))
        }
      })}
    >
      <p className="rounded-lg border border-info/20 bg-tint-info px-4 py-3 text-sm text-info-text">{t.recuperar.enviado}</p>
      <ErroFormulario mensagem={erro} />
      <CampoFormulario rotulo={t.recuperar.codigo} erro={definir.formState.errors.codigo?.message}>
        {(p) => <Input {...p} {...definir.register('codigo')} inputMode="numeric" autoComplete="one-time-code" maxLength={6} autoFocus className="alvo num h-11 tracking-[0.3em]" />}
      </CampoFormulario>
      <CampoFormulario rotulo={t.recuperar.novaSenha} erro={definir.formState.errors.senha?.message}>
        {(p) => <Input {...p} {...definir.register('senha')} type="password" autoComplete="new-password" className="alvo h-11" />}
      </CampoFormulario>
      <Button type="submit" disabled={definir.formState.isSubmitting} className="alvo h-11">{t.recuperar.definir}</Button>
    </form>
  )
}

export default function PaginaEntrar() {
  const { estado } = useSessao()
  const [modo, setModo] = useState<'entrar' | 'recuperar'>('entrar')
  const [aviso, setAviso] = useState<string | null>(null)
  if (estado === 'autenticado') return <Navigate to="/" replace />

  return (
    <main className="flex min-h-dvh flex-col items-center justify-center bg-muted/60 px-4 py-10">
      <div className="w-full max-w-[440px]">
        <section className="rounded-xl border bg-card px-6 py-10 text-card-foreground shadow-card sm:px-10">
          <div className="flex flex-col items-center gap-4 text-center">
            <Marca className="size-20" />
            <div>
              <p className="text-lg font-semibold tracking-tight">{t.produto.nome}</p>
              <p className="text-sm text-muted-foreground">{t.produto.descricao}</p>
            </div>
            <h1 className="sr-only">{modo === 'entrar' ? t.entrar.titulo : t.recuperar.titulo}</h1>
            <p className="max-w-xs text-base text-muted-foreground">
              {modo === 'entrar'
                ? <>Por favor insira as suas <strong className="font-semibold text-foreground">credenciais</strong> para entrar.</>
                : <>Recuperar a <strong className="font-semibold text-foreground">senha</strong> da sua conta.</>}
            </p>
          </div>
          <div className="mt-8">
            {aviso && modo === 'entrar' && (
              <p className="mb-5 rounded-lg border border-success/20 bg-tint-success px-4 py-3 text-sm text-success-text">{aviso}</p>
            )}
            {modo === 'entrar' ? (
              <FormEntrar aoEsquecer={() => setModo('recuperar')} />
            ) : (
              <FormRecuperar aoVoltar={(msg) => { setAviso(msg ?? null); setModo('entrar') }} />
            )}
          </div>
        </section>
        <p className="mt-6 text-center text-xs text-muted-foreground">Igreja Adventista do Sétimo Dia · Moçambique</p>
      </div>
    </main>
  )
}
