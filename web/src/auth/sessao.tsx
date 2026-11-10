/**
 * Sessão do utilizador: entrar, sair, a igreja escolhida e as permissões (GET /v1/eu).
 *
 * `pode(codigo)` decide o que se MOSTRA (menus, botões); quem decide o que se pode FAZER é sempre a base
 * de dados (RLS e triggers). Esconder um botão é experiência de uso, não segurança (CLAUDE.md).
 */
import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { api, aoSessaoTerminar, dados, definirToken, renovarSessao } from '@/api/cliente'
import type { paths } from '@/api/esquema'

type Eu = paths['/v1/eu']['get']['responses']['200']['content']['application/json']
export type IgrejaDoUtilizador = Eu['igrejas'][number]

interface Sessao {
  estado: 'a-verificar' | 'anonimo' | 'autenticado'
  usuario: Eu['usuario'] | null
  igrejas: IgrejaDoUtilizador[]
  igreja: IgrejaDoUtilizador | null
  escolherIgreja: (id: number) => void
  pode: (codigo: string) => boolean
  entrar: (login: string, senha: string) => Promise<void>
  sair: () => Promise<void>
  terminadaPorExpirar: boolean
}

const Contexto = createContext<Sessao | null>(null)
const CHAVE_IGREJA = 'igreja.escolhida'

function lerIgrejaGuardada(): number | null {
  try {
    const v = localStorage.getItem(CHAVE_IGREJA)
    return v ? Number(v) : null
  } catch {
    return null
  }
}

export function SessaoProvider({ children }: { children: ReactNode }) {
  const queryClient = useQueryClient()
  const [estado, setEstado] = useState<Sessao['estado']>('a-verificar')
  const [eu, setEu] = useState<Eu | null>(null)
  const [igrejaId, setIgrejaId] = useState<number | null>(lerIgrejaGuardada)
  const [terminadaPorExpirar, setTerminadaPorExpirar] = useState(false)

  const carregarEu = useCallback(async () => {
    const r = await dados(api.GET('/v1/eu'))
    setEu(r)
    setEstado('autenticado')
  }, [])

  // ao abrir a aplicação: o cookie de renovação ainda é válido? então a sessão continua
  useEffect(() => {
    aoSessaoTerminar(() => {
      setEu(null)
      setEstado('anonimo')
      setTerminadaPorExpirar(true)
      queryClient.clear()
    })
    renovarSessao()
      .then((ok) => (ok ? carregarEu() : setEstado('anonimo')))
      .catch(() => setEstado('anonimo'))
  }, [carregarEu, queryClient])

  const entrar = useCallback(
    async (login: string, senha: string) => {
      const r = await dados(api.POST('/v1/auth/login', { body: { login, senha } }))
      definirToken(r.tokenAcesso)
      setTerminadaPorExpirar(false)
      await carregarEu()
    },
    [carregarEu],
  )

  const sair = useCallback(async () => {
    try {
      await api.POST('/v1/auth/sair')
    } finally {
      definirToken(null)
      setEu(null)
      setEstado('anonimo')
      queryClient.clear()
    }
  }, [queryClient])

  const igrejas = useMemo(() => eu?.igrejas ?? [], [eu])
  const igreja = useMemo(() => igrejas.find((i) => i.id === igrejaId) ?? igrejas[0] ?? null, [igrejas, igrejaId])

  const escolherIgreja = useCallback(
    (id: number) => {
      setIgrejaId(id)
      try {
        localStorage.setItem(CHAVE_IGREJA, String(id))
      } catch {
        /* sem armazenamento: fica só nesta sessão */
      }
      queryClient.invalidateQueries()
    },
    [queryClient],
  )

  const pode = useCallback(
    (codigo: string) => (igreja ? (eu?.permissoes?.[String(igreja.id)] ?? []).includes(codigo) : false),
    [eu, igreja],
  )

  const valor = useMemo<Sessao>(
    () => ({ estado, usuario: eu?.usuario ?? null, igrejas, igreja, escolherIgreja, pode, entrar, sair, terminadaPorExpirar }),
    [estado, eu, igrejas, igreja, escolherIgreja, pode, entrar, sair, terminadaPorExpirar],
  )
  return <Contexto.Provider value={valor}>{children}</Contexto.Provider>
}

export function useSessao(): Sessao {
  const s = useContext(Contexto)
  if (!s) throw new Error('useSessao fora do SessaoProvider')
  return s
}

/** A igreja escolhida (as páginas só abrem com sessão, por isso existe). */
export function useIgreja(): IgrejaDoUtilizador {
  const { igreja } = useSessao()
  if (!igreja) throw new Error('Sem igreja na sessão')
  return igreja
}
