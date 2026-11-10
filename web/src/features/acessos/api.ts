/**
 * Utilizadores, perfis e permissões (F-NUC-03, P-13). Tudo é decidido pela base de dados:
 * - só quem tem nucleo.usuario.* gere utilizadores, e só os das igrejas que administra;
 * - ninguém dá a si próprio perfis, nem dá um perfil com mais permissões do que as suas;
 * - perfis e a matriz de permissões só se alteram com permissão global (super-administrador).
 * A senha nunca passa aqui: o utilizador define-a com o código por SMS (/v1/auth/recuperar + /redefinir).
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import { useIgreja } from '@/auth/sessao'

export type Usuario = Esquema<'Usuario'> & { id: number; nome: string; email: string | null; telefone: string | null }
export type Perfil = Esquema<'Perfil'> & { id: number; nome: string; ambito: 'IGREJA' | 'ENTIDADE' }
export type Permissao = Esquema<'Permissao'> & { id: number; codigo: string }
export type PerfilPermissao = Esquema<'PerfilPermissao'> & { id: number; perfilId: number; permissaoId: number }
export type UsuarioIgreja = Esquema<'UsuarioIgreja'> & { id: number; usuarioId: number; igrejaId: number; perfilId: number }

/** Lê todas as páginas de uma listagem (perfis-permissoes tem perto de mil linhas). */
async function todas<T>(pedir: (depois?: string) => Promise<{ dados: unknown[]; proximo?: string | null }>, max = 5000): Promise<T[]> {
  const out: T[] = []
  let depois: string | undefined
  do {
    const r = await pedir(depois)
    out.push(...(r.dados as T[]))
    depois = r.proximo ?? undefined
  } while (depois && out.length < max)
  return out
}

const k = { todos: ['acessos'] as const }

export function useUsuarios() {
  return useQuery({
    queryKey: [...k.todos, 'usuarios'],
    queryFn: () => todas<Usuario>((depois) => dados(api.GET('/v1/nucleo/usuarios', { params: { query: { limite: 200, depois, incluirTerminados: true } as never } }))),
  })
}

export function useUsuario(id: number) {
  return useQuery({
    enabled: id > 0,
    queryKey: [...k.todos, 'usuario', id],
    queryFn: async () => (await dados(api.GET('/v1/nucleo/usuarios/{id}', { params: { path: { id } } }))) as Usuario,
  })
}

/** Perfis dados nesta igreja (a todos os utilizadores). */
export function usePerfisDaIgreja() {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...k.todos, 'usuarios-igreja', igreja.id],
    queryFn: () => todas<UsuarioIgreja>((depois) => dados(api.GET('/v1/nucleo/usuarios-igreja', { params: { query: { igrejaId: igreja.id, limite: 200, depois } } }))),
  })
}

export function usePerfis() {
  return useQuery({
    queryKey: [...k.todos, 'perfis'],
    queryFn: () => todas<Perfil>((depois) => dados(api.GET('/v1/nucleo/perfis', { params: { query: { limite: 200, depois, incluirTerminados: true } as never } }))),
    staleTime: 5 * 60_000,
  })
}

export function usePermissoes() {
  return useQuery({
    queryKey: [...k.todos, 'permissoes'],
    queryFn: () => todas<Permissao>((depois) => dados(api.GET('/v1/nucleo/permissoes', { params: { query: { limite: 200, depois } } }))),
    staleTime: 30 * 60_000,
  })
}

/** A matriz perfil × permissão (só as ligações em vigor). */
export function usePerfisPermissoes() {
  return useQuery({
    queryKey: [...k.todos, 'perfis-permissoes'],
    queryFn: () => todas<PerfilPermissao>((depois) => dados(api.GET('/v1/nucleo/perfis-permissoes', { params: { query: { limite: 200, depois } } }))),
    staleTime: 5 * 60_000,
  })
}

function useInvalidar() {
  const qc = useQueryClient()
  return () => qc.invalidateQueries({ queryKey: k.todos })
}

export interface DadosUtilizador { nome: string; email: string; telefone: string; membroId: number | null }

/**
 * Grava o utilizador e acerta os perfis nesta igreja: dá os novos e termina os retirados (nada se apaga).
 * Se a base de dados recusar um perfil (ex.: mais permissões do que as de quem dá), o erro sobe com a mensagem.
 */
export function useGravarUtilizador() {
  const invalidar = useInvalidar()
  const igreja = useIgreja()
  return useMutation({
    mutationFn: async ({ id, dadosU, perfis, actuais }: { id?: number; dadosU: DadosUtilizador; perfis: number[]; actuais: UsuarioIgreja[] }) => {
      const corpo = { nome: dadosU.nome, email: dadosU.email || null, telefone: dadosU.telefone || null, membroId: dadosU.membroId }
      const u = id
        ? ((await dados(api.PATCH('/v1/nucleo/usuarios/{id}', { params: { path: { id } }, body: corpo as never }))) as Usuario)
        : ((await dados(api.POST('/v1/nucleo/usuarios', { body: corpo as never }))) as Usuario)
      const tem = new Set(actuais.map((a) => a.perfilId))
      for (const p of perfis.filter((p) => !tem.has(p))) {
        await dados(api.POST('/v1/nucleo/usuarios-igreja', { body: { usuarioId: u.id, igrejaId: igreja.id, perfilId: p } as never }))
      }
      for (const a of actuais.filter((a) => !perfis.includes(a.perfilId))) {
        await dados(api.POST('/v1/nucleo/usuarios-igreja/{id}/terminar', { params: { path: { id: a.id } } }))
      }
      return u
    },
    onSettled: () => invalidar(),
  })
}

export function useEstadoUtilizador() {
  const invalidar = useInvalidar()
  return useMutation({
    mutationFn: ({ id, activar }: { id: number; activar: boolean }) =>
      activar
        ? dados(api.POST('/v1/nucleo/usuarios/{id}/reactivar', { params: { path: { id } } }))
        : dados(api.POST('/v1/nucleo/usuarios/{id}/terminar', { params: { path: { id } } })),
    onSuccess: () => invalidar(),
  })
}

/** Manda ao telemóvel do utilizador o código para definir a senha (o "convite"). */
export function useEnviarCodigo() {
  return useMutation({
    mutationFn: (login: string) => dados(api.POST('/v1/auth/recuperar', { body: { login } })),
  })
}

export function usePerfisMut() {
  const invalidar = useInvalidar()
  const criar = useMutation({
    mutationFn: (p: { nome: string; descricao: string; ambito: string }) => dados(api.POST('/v1/nucleo/perfis', { body: p as never })) as Promise<Perfil>,
    onSuccess: () => invalidar(),
  })
  const alterar = useMutation({
    mutationFn: ({ id, descricao }: { id: number; descricao: string }) => dados(api.PATCH('/v1/nucleo/perfis/{id}', { params: { path: { id } }, body: { descricao } as never })),
    onSuccess: () => invalidar(),
  })
  const estado = useMutation({
    mutationFn: ({ id, activar }: { id: number; activar: boolean }) =>
      activar
        ? dados(api.POST('/v1/nucleo/perfis/{id}/reactivar', { params: { path: { id } } }))
        : dados(api.POST('/v1/nucleo/perfis/{id}/terminar', { params: { path: { id } } })),
    onSuccess: () => invalidar(),
  })
  /** Aplica a matriz de um perfil: dá as permissões novas e termina as retiradas. */
  const permissoes = useMutation({
    mutationFn: async ({ perfilId, dar, tirar }: { perfilId: number; dar: number[]; tirar: PerfilPermissao[] }) => {
      for (const permissaoId of dar) await dados(api.POST('/v1/nucleo/perfis-permissoes', { body: { perfilId, permissaoId } as never }))
      for (const l of tirar) await dados(api.POST('/v1/nucleo/perfis-permissoes/{id}/terminar', { params: { path: { id: l.id } } }))
    },
    onSettled: () => invalidar(),
  })
  return { criar, alterar, estado, permissoes }
}

/* ------------------------------------------------------------------ apresentação */

export const MODULOS: Record<string, string> = {
  nucleo: 'Núcleo e acessos', organizacao: 'Organização', secretaria: 'Secretaria', actividades: 'Actividades',
  escola_sabatina: 'Escola Sabatina', tesouraria: 'Tesouraria',
}
export const ACCOES = ['ler', 'criar', 'alterar', 'terminar'] as const
export const ROTULO_ACCAO: Record<string, string> = { ler: 'Ver', criar: 'Criar', alterar: 'Alterar', terminar: 'Terminar' }

/**
 * A base de dados diz que permissões faltam pelo código ("secretaria.disciplina.ler, …"). Para o ecrã:
 * "Disciplina: ver, …", com as primeiras 6 e "e mais N".
 */
export function traduzirPermissoes(mensagem: string, permissoes: Permissao[] = []): string {
  const porCodigo = new Map(permissoes.map((p) => [p.codigo, p]))
  // nome curto do recurso: "Censuras (1 a 12 meses): sem cargos…" → "Censuras"
  const curto = (codigo: string) => {
    const tabela = codigo.split('.').slice(0, 2).join('.')
    const p = porCodigo.get(`${tabela}.ler`) ?? porCodigo.get(codigo)
    return nomeDoRecurso(p?.descricao, codigo.split('.')[1]).split(/\s*[(:]/)[0]
  }
  // a base de dados corta a lista em 300 caracteres: um último código a meio ("…, tesourar") vira "e outras"
  let cortada = false
  const texto = mensagem.replace(/,\s*[a-z_]+(?:\.[a-z_]*)?$/, () => { cortada = true; return '' })
  return texto.replace(/((?:[a-z_]+\.[a-z_]+\.[a-z_]+)(?:,\s*[a-z_]+\.[a-z_]+\.[a-z_]+)*)/g, (lista) => {
    // agrupa as acções de cada recurso: "Censuras: ver, criar"; as acções próprias pela sua descrição
    const grupos = new Map<string, string[]>()
    for (const codigo of lista.split(/,\s*/)) {
      const accao = codigo.split('.').pop() ?? ''
      if ((ACCOES as readonly string[]).includes(accao)) {
        const r = curto(codigo)
        grupos.set(r, [...(grupos.get(r) ?? []), ROTULO_ACCAO[accao].toLowerCase()])
      } else grupos.set(porCodigo.get(codigo)?.descricao ?? codigo, [])
    }
    const itens = [...grupos].map(([r, a]) => (a.length ? `${r} (${a.join(', ')})` : r))
    return itens.slice(0, 6).join('; ') + (itens.length > 6 ? ` e mais ${itens.length - 6}` : '') + (cortada ? ' e outras' : '')
  })
}

/** "Ler: Membros, interessados ... (estado muda só por movimento)" → "Membros, interessados ...". */
export function nomeDoRecurso(descricao?: string | null, tabela?: string): string {
  const d = (descricao ?? '').replace(/^[^:]+:\s*/, '').replace(/\s*\([^)]*\)\s*$/, '').trim()
  return d || (tabela ?? '').replace(/_/g, ' ')
}
