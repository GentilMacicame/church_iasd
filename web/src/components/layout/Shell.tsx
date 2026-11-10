/**
 * Moldura da aplicação (como o shell do SGMS): barra lateral branca com a marca, secções e itens com ícone;
 * barra de topo fixa com o botão do menu, o caminho (breadcrumb), o tema e o menu do utilizador.
 * Computador: a barra lateral encolhe para só ícones (fica guardado). Telemóvel: gaveta com fundo escurecido.
 * O menu só mostra módulos que existem e que o utilizador pode abrir.
 */
import { useEffect, useState, type ComponentType } from 'react'
import { Link, NavLink, Outlet, useLocation } from 'react-router-dom'
import {
  BookOpen, Building2, CalendarDays, Check, Landmark, ChevronRight, ChevronsUpDown, LayoutDashboard, LogOut, Menu, Moon, PanelLeft, ShieldCheck, Sun, SunMoon,
  UserPlus, Users, X,
} from 'lucide-react'
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Tooltip, TooltipContent, TooltipTrigger } from '@/components/ui/tooltip'
import { Pilula } from '@/components/comum/elementos'
import { useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { useTema } from '@/lib/tema'
import { cn } from '@/lib/utils'
import { Marca } from './Marca'

interface ItemNav { para: string; rotulo: string; icone: ComponentType<{ className?: string }>; permissao?: string; fim?: boolean }
interface GrupoNav { rotulo?: string; itens: ItemNav[] }

const NAV: GrupoNav[] = [
  { itens: [{ para: '/', rotulo: t.nav.inicio, icone: LayoutDashboard, fim: true }] },
  {
    rotulo: t.nav.secretaria,
    itens: [
      { para: '/membros', rotulo: t.nav.membros, icone: Users, permissao: 'secretaria.membro.ler', fim: false },
      { para: '/membros/novo', rotulo: t.membros.registar, icone: UserPlus, permissao: 'secretaria.membro.criar', fim: true },
      { para: '/livro', rotulo: t.livro.titulo, icone: BookOpen, permissao: 'secretaria.movimento_membro.ler', fim: false },
      { para: '/reunioes', rotulo: t.livro.reunioes, icone: Landmark, permissao: 'secretaria.reuniao.ler', fim: false },
    ],
  },
  {
    rotulo: t.nav.actividades,
    itens: [{ para: '/escalas', rotulo: t.nav.escalas, icone: CalendarDays, permissao: 'actividades.escala_plano.ler', fim: false }],
  },
]

const CHAVE_ENCOLHIDA = 'igreja.menu-encolhido'
function lerEncolhida() {
  try { return localStorage.getItem(CHAVE_ENCOLHIDA) === '1' } catch { return false }
}

function Navegacao({ encolhida, aoEscolher }: { encolhida: boolean; aoEscolher?: () => void }) {
  const { pode } = useSessao()
  const { pathname } = useLocation()
  return (
    <nav aria-label="Principal">
      {NAV.map((grupo, i) => {
        const itens = grupo.itens.filter((it) => !it.permissao || pode(it.permissao))
        if (!itens.length) return null
        return (
          <div key={i} className={cn(grupo.rotulo && 'mt-5')}>
            {grupo.rotulo && !encolhida && (
              <p className="px-2.5 pb-1.5 text-[11px] font-semibold tracking-wider text-sidebar-muted uppercase">{grupo.rotulo}</p>
            )}
            {grupo.rotulo && encolhida && <div className="mx-2.5 mb-2 h-px bg-sidebar-border" aria-hidden />}
            <ul className="grid gap-0.5">
              {itens.map((it) => {
                // "Membros" não fica activo quando se está a registar (esse tem o seu próprio item)
                const activo = it.fim ? pathname === it.para : pathname.startsWith(it.para) && pathname !== '/membros/novo'
                const ligacao = (
                  <NavLink
                    to={it.para}
                    end={it.fim}
                    onClick={aoEscolher}
                    aria-current={activo ? 'page' : undefined}
                    className={cn(
                      'alvo flex min-h-9 items-center gap-2.5 rounded-md px-2.5 py-1.5 text-sm font-medium whitespace-nowrap text-sidebar-foreground transition-colors',
                      'hover:bg-sidebar-accent hover:text-sidebar-accent-foreground',
                      activo && 'bg-accent font-semibold text-accent-foreground hover:bg-accent hover:text-accent-foreground',
                      encolhida && 'justify-center px-0',
                    )}
                  >
                    <it.icone className="size-[18px] shrink-0 opacity-85" />
                    {!encolhida && <span className="min-w-0 flex-1 truncate">{it.rotulo}</span>}
                  </NavLink>
                )
                return (
                  <li key={it.para}>
                    {encolhida ? (
                      <Tooltip>
                        <TooltipTrigger asChild>{ligacao}</TooltipTrigger>
                        <TooltipContent side="right">{it.rotulo}</TooltipContent>
                      </Tooltip>
                    ) : ligacao}
                  </li>
                )
              })}
            </ul>
          </div>
        )
      })}
    </nav>
  )
}

function BarraLateral({ encolhida, aberta, aoFechar }: { encolhida: boolean; aberta: boolean; aoFechar: () => void }) {
  const { igreja, sair } = useSessao()
  return (
    <>
      <aside
        aria-label="Navegação principal"
        className={cn(
          'fixed inset-y-0 left-0 z-40 flex w-[var(--sidebar-width)] print:hidden flex-col border-r border-sidebar-border bg-sidebar text-sidebar-foreground transition-[width,transform] duration-200',
          'lg:sticky lg:top-0 lg:h-dvh lg:translate-x-0',
          aberta ? 'translate-x-0 shadow-[0_10px_40px_rgb(0_0_0/0.2)]' : '-translate-x-full',
          encolhida && 'lg:w-[var(--sidebar-collapsed-width)]',
        )}
      >
        <div className={cn('flex h-[var(--header-height)] flex-none items-center gap-3 border-b border-sidebar-border px-4', encolhida && 'lg:justify-center lg:px-0')}>
          <Link to="/" onClick={aoFechar} className="flex min-w-0 items-center gap-3 text-foreground">
            <Marca className="size-8 flex-none" />
            <span className={cn('flex min-w-0 flex-col leading-tight', encolhida && 'lg:hidden')}>
              <span className="truncate text-sm font-semibold">{igreja?.nome ?? t.produto.nome}</span>
              <span className="text-xs text-muted-foreground">{t.produto.descricao}</span>
            </span>
          </Link>
          <button type="button" onClick={aoFechar} aria-label={t.comum.fechar}
            className="ml-auto inline-flex size-9 flex-none items-center justify-center rounded-md text-muted-foreground hover:bg-accent lg:hidden">
            <X className="size-[18px]" />
          </button>
        </div>
        <div className="flex-1 overflow-x-hidden overflow-y-auto px-2.5 py-3">
          <Navegacao encolhida={encolhida} aoEscolher={aoFechar} />
        </div>
        <div className="border-t border-sidebar-border p-2.5">
          <button type="button" onClick={() => sair()}
            className={cn('alvo flex min-h-9 w-full items-center gap-2.5 rounded-md px-2.5 text-sm font-medium text-sidebar-foreground hover:bg-tint-destructive hover:text-destructive-text', encolhida && 'lg:justify-center lg:px-0')}>
            <LogOut className="size-[18px] shrink-0" />
            <span className={cn(encolhida && 'lg:hidden')}>{t.nav.sair}</span>
          </button>
        </div>
      </aside>
      {aberta && <div className="fixed inset-0 z-30 bg-slate-950/45 backdrop-blur-[2px] lg:hidden" onClick={aoFechar} aria-hidden />}
    </>
  )
}

/** Caminho do ecrã actual: Início › Secretaria › Membros › … */
function Caminho() {
  const { pathname } = useLocation()
  const partes: { rotulo: string; para?: string }[] = [{ rotulo: t.nav.inicio, para: '/' }]
  if (pathname.startsWith('/membros')) {
    partes.push({ rotulo: t.nav.secretaria }, { rotulo: t.nav.membros, para: '/membros' })
    if (pathname === '/membros/novo') partes.push({ rotulo: t.membros.registar })
    else if (pathname.endsWith('/editar')) partes.push({ rotulo: t.ficha.titulo, para: pathname.replace(/\/editar$/, '') }, { rotulo: t.comum.editar })
    else if (/^\/membros\/\d+/.test(pathname)) partes.push({ rotulo: t.ficha.titulo })
  }
  if (pathname.startsWith('/livro')) partes.push({ rotulo: t.nav.secretaria }, { rotulo: t.livro.titulo })
  if (pathname.startsWith('/reunioes')) {
    partes.push({ rotulo: t.nav.secretaria }, { rotulo: t.livro.reunioes, para: '/reunioes' })
    if (/^\/reunioes\/\d+/.test(pathname)) partes.push({ rotulo: 'Acta' })
  }
  if (pathname.startsWith('/escalas')) {
    partes.push({ rotulo: t.nav.actividades }, { rotulo: t.nav.escalas, para: '/escalas' })
    if (pathname === '/escalas/nova') partes.push({ rotulo: t.escalas.nova })
    else if (/^\/escalas\/\d+/.test(pathname)) partes.push({ rotulo: 'Escala' })
  }
  const ultimo = partes.length - 1
  return (
    <nav aria-label="Caminho" className="min-w-0">
      <ol className="flex min-w-0 items-center gap-1.5 text-sm">
        {partes.map((p, i) => (
          <li key={i} className={cn('flex min-w-0 items-center gap-1.5', i < ultimo && 'hidden sm:flex')}>
            {i > 0 && <ChevronRight className={cn('size-3.5 flex-none text-muted-foreground', i === ultimo && 'hidden sm:block')} aria-hidden />}
            {i === ultimo || !p.para
              ? <span className={cn('truncate', i === ultimo ? 'font-medium text-foreground' : 'text-muted-foreground')} aria-current={i === ultimo ? 'page' : undefined}>{p.rotulo}</span>
              : <Link to={p.para} className="truncate text-muted-foreground hover:text-foreground">{p.rotulo}</Link>}
          </li>
        ))}
      </ol>
    </nav>
  )
}

function MenuUtilizador() {
  const { usuario, igreja, igrejas, escolherIgreja, sair } = useSessao()
  const { alternar } = useTema()
  const nome = usuario?.nome ?? '—'
  const iniciais = nome.split(/\s+/).filter(Boolean).slice(0, 2).map((p) => p[0]!.toUpperCase()).join('')
  const perfis = igreja?.perfis?.map((p) => rotulos.perfil[p] ?? p) ?? []
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <button type="button" className="flex items-center gap-2.5 rounded-md py-1 pr-2 pl-1 text-left transition-colors hover:bg-accent">
          <span className="flex size-8 items-center justify-center rounded-md bg-primary text-xs font-semibold text-primary-foreground">{iniciais}</span>
          <span className="hidden flex-col leading-tight md:flex">
            <span className="max-w-40 truncate text-sm font-medium text-foreground">{nome}</span>
            <span className="max-w-40 truncate text-xs text-muted-foreground">{perfis[0] ?? t.nav.igreja}</span>
          </span>
          <ChevronsUpDown className="hidden size-4 text-muted-foreground md:block" />
        </button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-64">
        <div className="px-2 py-2">
          <p className="truncate text-sm font-medium">{nome}</p>
          <p className="truncate text-xs text-muted-foreground">{igreja?.nome}</p>
          {perfis.length > 0 && (
            <div className="mt-2 flex flex-wrap gap-1">
              {perfis.map((p) => <Pilula key={p} variante="info"><ShieldCheck className="size-3" />{p}</Pilula>)}
            </div>
          )}
        </div>
        {igrejas.length > 1 && (
          <>
            <DropdownMenuSeparator />
            <DropdownMenuLabel className="text-xs font-normal text-muted-foreground">{t.nav.mudarIgreja}</DropdownMenuLabel>
            {igrejas.map((i) => (
              <DropdownMenuItem key={i.id} onSelect={() => escolherIgreja(i.id)}>
                <Building2 className="size-4" /><span className="flex-1 truncate">{i.nome}</span>
                {i.id === igreja?.id && <Check className="size-4 text-primary" />}
              </DropdownMenuItem>
            ))}
          </>
        )}
        <DropdownMenuSeparator />
        <DropdownMenuItem onSelect={alternar}><SunMoon className="size-4" /> {t.nav.alternarTema}</DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem onSelect={() => sair()} className="text-destructive-text focus:text-destructive-text">
          <LogOut className="size-4" /> {t.nav.sair}
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

export function Shell() {
  const [encolhida, setEncolhida] = useState(lerEncolhida)
  const [gaveta, setGaveta] = useState(false)
  const { escuro, alternar } = useTema()
  const { pathname } = useLocation()
  useEffect(() => setGaveta(false), [pathname])

  const encolher = () => setEncolhida((v) => {
    try { localStorage.setItem(CHAVE_ENCOLHIDA, v ? '0' : '1') } catch { /* sem armazenamento */ }
    return !v
  })
  const botaoIcone = 'inline-flex size-9 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground'

  return (
    <div className="flex min-h-dvh">
      <BarraLateral encolhida={encolhida} aberta={gaveta} aoFechar={() => setGaveta(false)} />
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-20 flex print:hidden h-[var(--header-height)] items-center gap-3 border-b bg-background/85 px-4 backdrop-blur-md backdrop-saturate-150 sm:px-6">
          <button type="button" onClick={() => setGaveta(true)} className={cn(botaoIcone, 'size-11 lg:hidden')} aria-label="Abrir menu"><Menu className="size-5" /></button>
          <button type="button" onClick={encolher} className={cn(botaoIcone, 'hidden lg:inline-flex')} aria-label={encolhida ? 'Mostrar menu' : 'Minimizar menu'} aria-expanded={!encolhida}>
            <PanelLeft className="size-[18px]" />
          </button>
          <span className="hidden h-5 w-px bg-border sm:block" aria-hidden />
          <Caminho />
          <div className="ml-auto flex items-center gap-1">
            <button type="button" onClick={alternar} className={botaoIcone} aria-label={t.nav.alternarTema}>
              {escuro ? <Sun className="size-[18px]" /> : <Moon className="size-[18px]" />}
            </button>
            <MenuUtilizador />
          </div>
        </header>
        <main className="mx-auto w-full max-w-[1600px] flex-1 px-4 py-6 sm:px-6 lg:px-8 print:max-w-none print:p-0">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
