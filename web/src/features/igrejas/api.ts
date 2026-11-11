/**
 * Igrejas (F-ORG-01, P-13): o super-administrador (ou a administração da Associação/Missão) regista as igrejas e o
 * administrador de cada uma; esse administrador gere depois os utilizadores da sua igreja em "Utilizadores e perfis".
 * As regras são da base de dados (V25): só regista igrejas quem tem a permissão ao nível da Associação dela.
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'

export type Igreja = Esquema<'Igreja'> & { id: number; nome: string; entidadeId: number }
export type TipoIgreja = NonNullable<Igreja['tipo']>
export type Entidade = Esquema<'Entidade'> & { id: number; nome: string; tipo: string }
export type Distrito = Esquema<'Distrito'> & { id: number; nome: string; entidadeId: number }
type Usuario = Esquema<'Usuario'> & { id: number; nome: string }
type UsuarioIgreja = Esquema<'UsuarioIgreja'> & { id: number; usuarioId: number; igrejaId: number; perfilId: number }

export const TIPO_IGREJA: Record<TipoIgreja, string> = {
  IGREJA_ORGANIZADA: 'Igreja organizada', GRUPO_ORGANIZADO: 'Grupo organizado', GRUPO: 'Grupo', FILIAL: 'Filial',
}

const k = ['igrejas-admin'] as const

async function todas<T>(pedir: (depois?: string) => Promise<{ dados: unknown[]; proximo?: string | null }>): Promise<T[]> {
  const out: T[] = []
  let depois: string | undefined
  do {
    const r = await pedir(depois)
    out.push(...(r.dados as T[]))
    depois = r.proximo ?? undefined
  } while (depois && out.length < 5000)
  return out
}

/** Todas as igrejas que o utilizador vê (o super-administrador vê todas). */
export function useIgrejas() {
  return useQuery({
    queryKey: [...k, 'igrejas'],
    queryFn: () => todas<Igreja>((depois) => dados(api.GET('/v1/organizacao/igrejas', { params: { query: { limite: 200, depois } as never } }))),
  })
}

export function useEntidadesOrg() {
  return useQuery({
    queryKey: [...k, 'entidades'],
    queryFn: async () => (await dados(api.GET('/v1/organizacao/entidades', { params: { query: { limite: 200 } } }))).dados as Entidade[],
    staleTime: 10 * 60_000,
  })
}

export function useDistritos() {
  return useQuery({
    queryKey: [...k, 'distritos'],
    queryFn: async () => (await dados(api.GET('/v1/organizacao/distritos', { params: { query: { limite: 200 } } }))).dados as Distrito[],
  })
}

/** Os administradores (perfil ADMIN) de cada igreja, com o nome: igrejaId → nomes (a listagem é por igreja). */
export function useAdministradores(igrejas: number[]) {
  return useQuery({
    queryKey: [...k, 'administradores', igrejas],
    enabled: igrejas.length > 0,
    queryFn: async () => {
      const perfis = (await dados(api.GET('/v1/nucleo/perfis', { params: { query: { limite: 100 } } }))).dados as { id: number; nome: string }[]
      const admin = perfis.find((p) => p.nome === 'ADMIN')
      if (!admin) return new Map<number, string[]>()
      const ligacoes = (await Promise.all(igrejas.map((igrejaId) => todas<UsuarioIgreja>((depois) =>
        dados(api.GET('/v1/nucleo/usuarios-igreja', { params: { query: { igrejaId, perfilId: admin.id, limite: 200, depois } as never } })))))).flat()
      const usuarios = await todas<Usuario>((depois) => dados(api.GET('/v1/nucleo/usuarios', { params: { query: { limite: 200, depois } as never } })))
      const nome = new Map(usuarios.map((u) => [u.id, u.nome]))
      const out = new Map<number, string[]>()
      for (const l of ligacoes.filter((x) => !x.endDate)) out.set(l.igrejaId, [...(out.get(l.igrejaId) ?? []), nome.get(l.usuarioId) ?? `Utilizador ${l.usuarioId}`])
      return out
    },
  })
}

export interface NovoAdministrador { nome: string; email: string; telefone: string; enviarCodigo: boolean }

/** Cria o utilizador e dá-lhe o perfil ADMIN na igreja; pode enviar já o código por SMS para definir a senha. */
async function criarAdministrador(igrejaId: number, a: NovoAdministrador) {
  const perfis = (await dados(api.GET('/v1/nucleo/perfis', { params: { query: { limite: 100 } } }))).dados as { id: number; nome: string }[]
  const admin = perfis.find((p) => p.nome === 'ADMIN')
  if (!admin) throw new Error('O perfil ADMIN não existe nesta instalação.')
  const u = (await dados(api.POST('/v1/nucleo/usuarios', { body: { nome: a.nome, email: a.email || undefined, telefone: a.telefone || undefined } as never }))) as Usuario
  await dados(api.POST('/v1/nucleo/usuarios-igreja', { body: { usuarioId: u.id, igrejaId, perfilId: admin.id } as never }))
  if (a.enviarCodigo && (a.telefone || a.email)) await dados(api.POST('/v1/auth/recuperar', { body: { login: a.telefone || a.email } }))
  return u
}

export function useIgrejasMut() {
  const qc = useQueryClient()
  const depois = () => qc.invalidateQueries({ queryKey: k })
  const registar = useMutation({
    mutationFn: async (v: { igreja: Record<string, unknown>; administrador?: NovoAdministrador }) => {
      const igreja = (await dados(api.POST('/v1/organizacao/igrejas', { body: v.igreja as never }))) as Igreja
      let erroAdmin: unknown = null
      if (v.administrador) {
        try { await criarAdministrador(igreja.id, v.administrador) } catch (e) { erroAdmin = e }
      }
      return { igreja, erroAdmin }
    },
    onSuccess: depois,
  })
  const administrador = useMutation({
    mutationFn: (v: { igrejaId: number; administrador: NovoAdministrador }) => criarAdministrador(v.igrejaId, v.administrador),
    onSuccess: depois,
  })
  return { registar, administrador }
}
