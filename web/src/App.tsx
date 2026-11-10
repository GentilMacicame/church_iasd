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
import { ErroApi } from '@/api/erros'

const PaginaEntrar = lazy(() => import('@/features/auth/PaginaEntrar'))
const PaginaInicio = lazy(() => import('@/features/inicio/PaginaInicio'))
const PaginaMembros = lazy(() => import('@/features/membros/PaginaMembros'))
const PaginaMembro = lazy(() => import('@/features/membros/PaginaMembro'))
const PaginaFormMembro = lazy(() => import('@/features/membros/PaginaFormMembro'))
const PaginaLivro = lazy(() => import('@/features/livro/PaginaLivro'))
const PaginaReunioes = lazy(() => import('@/features/livro/PaginaReunioes'))
const PaginaReuniao = lazy(() => import('@/features/livro/PaginaReuniao'))
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
                  <Route path="membros" element={<PaginaMembros />} />
                  <Route path="membros/novo" element={<PaginaFormMembro />} />
                  <Route path="membros/:id" element={<PaginaMembro />} />
                  <Route path="membros/:id/editar" element={<PaginaFormMembro />} />
                  <Route path="livro" element={<PaginaLivro />} />
                  <Route path="reunioes" element={<PaginaReunioes />} />
                  <Route path="reunioes/:id" element={<PaginaReuniao />} />
                  <Route path="tesouraria" element={<PaginaTesouraria />} />
                  <Route path="tesouraria/movimentos" element={<PaginaMovimentosTes />} />
                  <Route path="tesouraria/movimentos/:id" element={<PaginaMovimentoTes />} />
                  <Route path="tesouraria/entrada" element={<PaginaEntrada />} />
                  <Route path="tesouraria/saida" element={<PaginaSaida />} />
                  <Route path="tesouraria/despesas" element={<PaginaDespesas />} />
                  <Route path="tesouraria/contagens" element={<PaginaContagens />} />
                  <Route path="tesouraria/remessas" element={<PaginaRemessas />} />
                  <Route path="tesouraria/fechos" element={<PaginaFechos />} />
                  <Route path="tesouraria/contas" element={<PaginaContas />} />
                  <Route path="tesouraria/relatorio-mensal" element={<PaginaRelatorioMensal />} />
                  <Route path="acessos" element={<PaginaAcessos />} />
                  <Route path="acessos/utilizadores/novo" element={<PaginaUtilizador />} />
                  <Route path="acessos/utilizadores/:id" element={<PaginaUtilizador />} />
                  <Route path="escalas" element={<PaginaEscalas />} />
                  <Route path="escalas/nova" element={<PaginaNovaEscala />} />
                  <Route path="escalas/:id" element={<PaginaEscala />} />
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
