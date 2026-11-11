/**
 * Rotas. Cada página é carregada só quando é aberta (lazy), para a primeira carga caber nos 300 KB
 * pensados para um Android em 3G.
 */
import { Suspense, type ReactNode } from 'react'
import { pagina } from '@/lib/paginas'
import { ErroAplicacao } from '@/components/layout/ErroAplicacao'
import { BrowserRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Toaster } from '@/components/ui/sonner'
import { TooltipProvider } from '@/components/ui/tooltip'
import { SessaoProvider, useSessao } from '@/auth/sessao'
import { Shell } from '@/components/layout/Shell'
import { Marca } from '@/components/layout/Marca'
import { Exige } from '@/components/layout/Exige'
import { ErroApi } from '@/api/erros'

const PaginaEntrar = pagina(() => import('@/features/auth/PaginaEntrar'))
const PaginaInicio = pagina(() => import('@/features/inicio/PaginaInicio'))
const PaginaMembros = pagina(() => import('@/features/membros/PaginaMembros'))
const PaginaMembro = pagina(() => import('@/features/membros/PaginaMembro'))
const PaginaFormMembro = pagina(() => import('@/features/membros/PaginaFormMembro'))
const PaginaLivro = pagina(() => import('@/features/livro/PaginaLivro'))
const PaginaReunioes = pagina(() => import('@/features/livro/PaginaReunioes'))
const PaginaReuniao = pagina(() => import('@/features/livro/PaginaReuniao'))
const PaginaActa = pagina(() => import('@/features/livro/PaginaActa'))
const PaginaConselho = pagina(() => import('@/features/conselho/PaginaConselho'))
const PaginaTesouraria = pagina(() => import('@/features/tesouraria/PaginaTesouraria'))
const PaginaMovimentosTes = pagina(() => import('@/features/tesouraria/PaginaMovimentos'))
const PaginaMovimentoTes = pagina(() => import('@/features/tesouraria/PaginaMovimento'))
const PaginaEntrada = pagina(() => import('@/features/tesouraria/PaginaEntrada'))
const PaginaSaida = pagina(() => import('@/features/tesouraria/PaginaSaida'))
const PaginaDespesas = pagina(() => import('@/features/tesouraria/PaginaDespesas'))
const PaginaContagens = pagina(() => import('@/features/tesouraria/PaginaContagens'))
const PaginaRemessas = pagina(() => import('@/features/tesouraria/PaginaRemessas'))
const PaginaFechos = pagina(() => import('@/features/tesouraria/PaginaFechos'))
const PaginaContas = pagina(() => import('@/features/tesouraria/PaginaContas'))
const PaginaFundos = pagina(() => import('@/features/tesouraria/PaginaFundos'))
const PaginaIgrejas = pagina(() => import('@/features/igrejas/PaginaIgrejas'))
const PaginaAcessos = pagina(() => import('@/features/acessos/PaginaAcessos'))
const PaginaUtilizador = pagina(() => import('@/features/acessos/PaginaUtilizador'))
const PaginaRelatorioMensal = pagina(() => import('@/features/tesouraria/PaginaRelatorioMensal'))
const PaginaEscalas = pagina(() => import('@/features/escalas/PaginaEscalas'))
const PaginaNovaEscala = pagina(() => import('@/features/escalas/PaginaNovaEscala'))
const PaginaEscala = pagina(() => import('@/features/escalas/PaginaEscala'))
const PaginaReconciliacao = pagina(() => import('@/features/tesouraria/PaginaReconciliacao'))
const PaginaOrcamento = pagina(() => import('@/features/tesouraria/PaginaOrcamento'))
const PaginaTransferencias = pagina(() => import('@/features/secretaria/PaginaTransferencias'))
const PaginaDisciplina = pagina(() => import('@/features/secretaria/PaginaDisciplina'))
const PaginaFamilias = pagina(() => import('@/features/secretaria/PaginaFamilias'))
const PaginaRelatorioSecretaria = pagina(() => import('@/features/secretaria/PaginaRelatorioSecretaria'))

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

/** Ecrã de arranque (a verificar a sessão, a carregar a aplicação): ao centro, o logotipo com um anel a rodar. */
function Carregando() {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center gap-5 bg-background px-4" role="status" aria-busy="true" aria-live="polite">
      <div className="relative flex size-24 items-center justify-center">
        <span aria-hidden className="absolute inset-0 rounded-full border-4 border-primary/15" />
        <span aria-hidden className="absolute inset-0 animate-spin rounded-full border-4 border-transparent border-t-primary" />
        <Marca className="size-12" />
      </div>
      <div className="text-center">
        <p className="text-sm font-semibold">Igreja Adventista do Sétimo Dia</p>
        <p className="mt-1 text-sm text-muted-foreground">A carregar…</p>
      </div>
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
        <ErroAplicacao>
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
                  <Route path="familias" element={<Exige permissao="secretaria.familia.ler"><PaginaFamilias /></Exige>} />
                  <Route path="transferencias" element={<Exige permissao="secretaria.transferencia_membro.ler"><PaginaTransferencias /></Exige>} />
                  <Route path="disciplina" element={<Exige permissao="secretaria.disciplina.ler"><PaginaDisciplina /></Exige>} />
                  <Route path="secretaria/relatorio" element={<Exige permissao="secretaria.movimento_membro.ler"><PaginaRelatorioSecretaria /></Exige>} />
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
                  <Route path="tesouraria/orcamento" element={<Exige permissao="tesouraria.orcamento.ler"><PaginaOrcamento /></Exige>} />
                  <Route path="tesouraria/reconciliacao" element={<Exige permissao="tesouraria.extrato_linha.ler"><PaginaReconciliacao /></Exige>} />
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
        </ErroAplicacao>
        <Toaster />
      </TooltipProvider>
    </QueryClientProvider>
  )
}
