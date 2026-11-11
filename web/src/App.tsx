/**
 * Rotas. Cada página é carregada só quando é aberta (lazy), para a primeira carga caber nos 300 KB
 * pensados para um Android em 3G.
 */
import { lazy, Suspense, type ReactNode } from 'react'
import { BrowserRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Toaster } from '@/components/ui/sonner'
import { TooltipProvider } from '@/components/ui/tooltip'
import { SessaoProvider, useSessao } from '@/auth/sessao'
import { Shell } from '@/components/layout/Shell'
import { Marca } from '@/components/layout/Marca'
import { Exige } from '@/components/layout/Exige'
import { ErroApi } from '@/api/erros'

const PaginaEntrar = lazy(() => import('@/features/auth/PaginaEntrar'))
const PaginaInicio = lazy(() => import('@/features/inicio/PaginaInicio'))
const PaginaMembros = lazy(() => import('@/features/membros/PaginaMembros'))
const PaginaMembro = lazy(() => import('@/features/membros/PaginaMembro'))
const PaginaFormMembro = lazy(() => import('@/features/membros/PaginaFormMembro'))
const PaginaLivro = lazy(() => import('@/features/livro/PaginaLivro'))
const PaginaReunioes = lazy(() => import('@/features/livro/PaginaReunioes'))
const PaginaReuniao = lazy(() => import('@/features/livro/PaginaReuniao'))
const PaginaActa = lazy(() => import('@/features/livro/PaginaActa'))
const PaginaConselho = lazy(() => import('@/features/conselho/PaginaConselho'))
const PaginaTesouraria = lazy(() => import('@/features/tesouraria/PaginaTesouraria'))
const PaginaMovimentosTes = lazy(() => import('@/features/tesouraria/PaginaMovimentos'))
const PaginaMovimentoTes = lazy(() => import('@/features/tesouraria/PaginaMovimento'))
const PaginaEntrada = lazy(() => import('@/features/tesouraria/PaginaEntrada'))
const PaginaSaida = lazy(() => import('@/features/tesouraria/PaginaSaida'))
const PaginaDespesas = lazy(() => import('@/features/tesouraria/PaginaDespesas'))
const PaginaContagens = lazy(() => import('@/features/tesouraria/PaginaContagens'))
const PaginaRemessas = lazy(() => import('@/features/tesouraria/PaginaRemessas'))
const PaginaFechos = lazy(() => import('@/features/tesouraria/PaginaFechos'))
const PaginaContas = lazy(() => import('@/features/tesouraria/PaginaContas'))
const PaginaFundos = lazy(() => import('@/features/tesouraria/PaginaFundos'))
const PaginaIgrejas = lazy(() => import('@/features/igrejas/PaginaIgrejas'))
const PaginaAcessos = lazy(() => import('@/features/acessos/PaginaAcessos'))
const PaginaUtilizador = lazy(() => import('@/features/acessos/PaginaUtilizador'))
const PaginaRelatorioMensal = lazy(() => import('@/features/tesouraria/PaginaRelatorioMensal'))
const PaginaEscalas = lazy(() => import('@/features/escalas/PaginaEscalas'))
const PaginaNovaEscala = lazy(() => import('@/features/escalas/PaginaNovaEscala'))
const PaginaEscala = lazy(() => import('@/features/escalas/PaginaEscala'))

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      refetchOnWindowFocus: false,
      // 403/404 são respostas da base de dados (sem permissão, não visível): não se repetem
      retry: (n, erro) => !(erro instanceof ErroApi && [401, 403, 404, 422].includes(erro.estado)) && n < 2,
    },
  },
})

function Carregando() {
  return (
    <div className="flex min-h-[40vh] items-center justify-center" aria-busy="true" aria-label="A carregar">
      <Marca className="size-8 opacity-60" />
    </div>
  )
}

/** Só com sessão; sem ela vai para /entrar e volta depois para onde estava. */
function ComSessao({ children }: { children: ReactNode }) {
  const { estado, igreja } = useSessao()
  const local = useLocation()
  if (estado === 'a-verificar') return <Carregando />
  if (estado === 'anonimo') return <Navigate to="/entrar" replace state={{ de: local.pathname + local.search }} />
  if (!igreja) {
    return (
      <main className="mx-auto max-w-lg px-4 pt-[15vh]">
        <h1 className="text-2xl font-bold">Sem igreja atribuída</h1>
        <p className="mt-2 text-muted-foreground">
          A sua conta ainda não tem perfil em nenhuma igreja. Peça ao secretário ou ao administrador da Associação que lhe atribua um.
        </p>
      </main>
    )
  }
  return <>{children}</>
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider delayDuration={300}>
        <BrowserRouter>
          <SessaoProvider>
            <Suspense fallback={<Carregando />}>
              <Routes>
                <Route path="/entrar" element={<PaginaEntrar />} />
                <Route element={<ComSessao><Shell /></ComSessao>}>
                  <Route index element={<PaginaInicio />} />
                  <Route path="membros" element={<Exige permissao="secretaria.membro.ler"><PaginaMembros /></Exige>} />
                  <Route path="membros/novo" element={<Exige permissao="secretaria.membro.criar"><PaginaFormMembro /></Exige>} />
                  <Route path="membros/:id" element={<Exige permissao="secretaria.membro.ler"><PaginaMembro /></Exige>} />
                  <Route path="membros/:id/editar" element={<Exige permissao="secretaria.membro.alterar"><PaginaFormMembro /></Exige>} />
                  <Route path="livro" element={<Exige permissao="secretaria.movimento_membro.ler"><PaginaLivro /></Exige>} />
                  <Route path="reunioes" element={<Exige permissao="secretaria.reuniao.ler"><PaginaReunioes /></Exige>} />
                  <Route path="reunioes/:id" element={<Exige permissao="secretaria.reuniao.ler"><PaginaReuniao /></Exige>} />
                  <Route path="reunioes/:id/acta" element={<Exige permissao="secretaria.reuniao.ler"><PaginaActa /></Exige>} />
                  <Route path="conselho" element={<Exige permissao="secretaria.oficial.ler"><PaginaConselho /></Exige>} />
                  <Route path="tesouraria" element={<Exige permissao="tesouraria.conta_financeira.ler"><PaginaTesouraria /></Exige>} />
                  <Route path="tesouraria/movimentos" element={<Exige permissao="tesouraria.transacao.ler"><PaginaMovimentosTes /></Exige>} />
                  <Route path="tesouraria/movimentos/:id" element={<Exige permissao="tesouraria.transacao.ler"><PaginaMovimentoTes /></Exige>} />
                  <Route path="tesouraria/entrada" element={<Exige permissao="tesouraria.transacao.criar"><PaginaEntrada /></Exige>} />
                  <Route path="tesouraria/saida" element={<Exige permissao="tesouraria.transacao.criar"><PaginaSaida /></Exige>} />
                  <Route path="tesouraria/despesas" element={<Exige permissao="tesouraria.despesa.ler"><PaginaDespesas /></Exige>} />
                  <Route path="tesouraria/contagens" element={<Exige permissao="tesouraria.contagem_numerario.ler"><PaginaContagens /></Exige>} />
                  <Route path="tesouraria/remessas" element={<Exige permissao="tesouraria.remessa.ler"><PaginaRemessas /></Exige>} />
                  <Route path="tesouraria/fechos" element={<Exige permissao="tesouraria.fecho_periodo.ler"><PaginaFechos /></Exige>} />
                  <Route path="tesouraria/contas" element={<Exige permissao="tesouraria.conta_financeira.ler"><PaginaContas /></Exige>} />
                  <Route path="tesouraria/fundos" element={<Exige permissao="tesouraria.fundo.ler"><PaginaFundos /></Exige>} />
                  <Route path="tesouraria/relatorio-mensal" element={<Exige permissao="tesouraria.transacao.ler"><PaginaRelatorioMensal /></Exige>} />
                  <Route path="igrejas" element={<Exige permissao="organizacao.igreja.criar"><PaginaIgrejas /></Exige>} />
                  <Route path="acessos" element={<Exige permissao="nucleo.usuario.ler"><PaginaAcessos /></Exige>} />
                  <Route path="acessos/utilizadores/novo" element={<Exige permissao="nucleo.usuario.criar"><PaginaUtilizador /></Exige>} />
                  <Route path="acessos/utilizadores/:id" element={<Exige permissao="nucleo.usuario.ler"><PaginaUtilizador /></Exige>} />
                  <Route path="escalas" element={<Exige permissao="actividades.escala_plano.ler"><PaginaEscalas /></Exige>} />
                  <Route path="escalas/nova" element={<Exige permissao="actividades.escala_plano.criar"><PaginaNovaEscala /></Exige>} />
                  <Route path="escalas/:id" element={<Exige permissao="actividades.escala_plano.ler"><PaginaEscala /></Exige>} />
                  <Route path="*" element={<Navigate to="/" replace />} />
                </Route>
              </Routes>
            </Suspense>
          </SessaoProvider>
        </BrowserRouter>
        <Toaster />
      </TooltipProvider>
    </QueryClientProvider>
  )
}
