/**
 * Membros · "Quem está no livro desta igreja, e quem falta aprovar?"
 * Os indicadores são o filtro (contagens reais, da vista vw_membro_basico); a pesquisa e os filtros são
 * feitos pela API; a lista carrega 50 de cada vez (cursor).
 */
import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { ChevronRight, ClipboardCheck, Plus, Search, Sprout, UserMinus, Users, X } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Avatar, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { useSessao } from '@/auth/sessao'
import { f, rotulos, t } from '@/i18n/pt-MZ'
import { data, idade } from '@/lib/formatos'
import { useContagemPorAprovar, useListaMembros, useMembrosBasicos, type EstadoMembro, type Membro } from './api'
import { ControlosPaginacao, usePaginacao } from '@/components/comum/Paginacao'

const OUTROS_ESTADOS: EstadoMembro[] = ['TRANSFERIDO', 'FALECIDO', 'REMOVIDO', 'DESAPARECIDO']

export function varianteEstado(e?: EstadoMembro | null) {
  return e === 'ACTIVO' ? 'success' : e === 'INTERESSADO' ? 'info' : 'secondary'
}

function useDebounce<T>(valor: T, ms = 300): T {
  const [v, setV] = useState(valor)
  useEffect(() => {
    const id = setTimeout(() => setV(valor), ms)
    return () => clearTimeout(id)
  }, [valor, ms])
  return v
}

export function PilulasMembro({ m }: { m: Membro }) {
  return (
    <span className="flex flex-wrap items-center gap-1.5">
      <Pilula variante={varianteEstado(m.estado)}>{m.estado ? rotulos.estadoMembro[m.estado] : '—'}</Pilula>
      {m.validacao === 'PENDENTE' && <Pilula variante="warning">{rotulos.validacao.PENDENTE}</Pilula>}
      {m.validacao === 'REJEITADO' && <Pilula variante="destructive">{rotulos.validacao.REJEITADO}</Pilula>}
    </span>
  )
}

function LinhaTabela({ m }: { m: Membro }) {
  const navigate = useNavigate()
  const anos = idade(m.dataNascimento)
  return (
    <tr onClick={() => navigate(`/membros/${m.id}`)} className="group cursor-pointer">
      <td className="sm:pl-6">
        <div className="flex items-center gap-3">
          <Avatar id={m.id} nome={m.nome} apelido={m.apelido} tamanho={36} />
          <div className="min-w-0">
            <Link to={`/membros/${m.id}`} onClick={(e) => e.stopPropagation()} className="block truncate font-medium text-foreground hover:text-primary">
              {m.nome} {m.apelido}
            </Link>
            <span className="block text-xs text-muted-foreground">
              {[m.sexo && rotulos.sexo[m.sexo], anos != null && f(t.ficha.idade, { n: anos })].filter(Boolean).join(' · ') || t.comum.semValor}
            </span>
          </div>
        </div>
      </td>
      <td><PilulasMembro m={m} /></td>
      <td className="text-muted-foreground">{m.bairro ?? t.comum.semValor}</td>
      <td className="text-muted-foreground">{m.profissao ?? t.comum.semValor}</td>
      <td className="num text-muted-foreground">{data(m.dataEntrada)}</td>
      <td className="w-10 sm:pr-6"><ChevronRight aria-hidden className="size-4 text-muted-foreground opacity-0 transition-opacity group-hover:opacity-100" /></td>
    </tr>
  )
}

/** No telemóvel a tabela vira lista de duas linhas (nada se perde: vai para a 2.ª linha). */
function LinhaLista({ m }: { m: Membro }) {
  return (
    <li className="border-t first:border-t-0">
      <Link to={`/membros/${m.id}`} className="alvo flex items-center gap-3 px-4 py-3 active:bg-muted">
        <Avatar id={m.id} nome={m.nome} apelido={m.apelido} tamanho={40} />
        <div className="min-w-0 flex-1">
          <p className="truncate font-medium">{m.nome} {m.apelido}</p>
          <p className="truncate text-xs text-muted-foreground">
            {[m.bairro, m.dataEntrada && `desde ${data(m.dataEntrada)}`].filter(Boolean).join(' · ') || t.comum.semValor}
          </p>
        </div>
        <div className="flex flex-col items-end gap-1"><PilulasMembro m={m} /></div>
      </Link>
    </li>
  )
}

export default function PaginaMembros() {
  const { pode } = useSessao()
  const [params, setParams] = useSearchParams()
  const estado = (params.get('estado') as EstadoMembro | null) ?? undefined
  const soPorAprovar = params.get('validacao') === 'PENDENTE'
  const [texto, setTexto] = useState(params.get('q') ?? '')
  const q = useDebounce(texto.trim())

  useEffect(() => {
    setParams((p) => {
      const n = new URLSearchParams(p)
      if (q) n.set('q', q); else n.delete('q')
      return n
    }, { replace: true })
  }, [q, setParams])

  const basicos = useMembrosBasicos()
  const porAprovar = useContagemPorAprovar()
  const lista = useListaMembros({ q, estado, validacao: soPorAprovar ? 'PENDENTE' : undefined })

  const contagens = useMemo(() => {
    const c: Record<string, number> = {}
    for (const m of basicos.data ?? []) c[m.estado] = (c[m.estado] ?? 0) + 1
    return c
  }, [basicos.data])
  const total = basicos.data?.length ?? 0
  const saidas = OUTROS_ESTADOS.reduce((s, e) => s + (contagens[e] ?? 0), 0)
  const membros = (lista.data?.pages.flatMap((p) => p.dados) ?? []) as Membro[]
  const pag = usePaginacao(membros)
  const totalFiltro = !q && !soPorAprovar ? (estado ? contagens[estado] ?? 0 : total) : null

  /** Um filtro de cada vez: estado OU "por aprovar". */
  const filtrar = (fl: { estado?: EstadoMembro; validacao?: string }) =>
    setParams((p) => {
      const n = new URLSearchParams(p)
      n.delete('estado'); n.delete('validacao')
      if (fl.estado) n.set('estado', fl.estado)
      if (fl.validacao) n.set('validacao', fl.validacao)
      return n
    })
  const filtroActivo = estado ? rotulos.estadoMembroPlural[estado] : soPorAprovar ? t.membros.porAprovar : null

  return (
    <>
      <TituloPagina
        icone={Users}
        titulo={t.membros.titulo}
        descricao="Livro de membros da igreja: interessados, membros activos e saídas"
        accoes={pode('secretaria.membro.criar') && (
          <Button asChild className="alvo"><Link to="/membros/novo"><Plus className="size-4" />{t.membros.registar}</Link></Button>
        )}
      />

      {basicos.isError ? <EstadoErro erro={basicos.error} aoTentar={() => basicos.refetch()} className="mb-6" /> : (
        <div className="mb-6 grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-4">
          <Indicador rotulo={t.membros.todos} valor={total} nota="registos no livro" icone={Users} aCarregar={basicos.isPending}
            activo={!estado && !soPorAprovar} aoClicar={() => filtrar({})} />
          <Indicador rotulo="Activos" valor={contagens.ACTIVO ?? 0} nota="membros baptizados" icone={Users} tom="success" aCarregar={basicos.isPending}
            activo={estado === 'ACTIVO'} aoClicar={() => filtrar({ estado: 'ACTIVO' })} />
          <Indicador rotulo="Interessados" valor={contagens.INTERESSADO ?? 0} nota="a preparar para o baptismo" icone={Sprout} tom="info" aCarregar={basicos.isPending}
            activo={estado === 'INTERESSADO'} aoClicar={() => filtrar({ estado: 'INTERESSADO' })} />
          {saidas > 0 ? (
            <Indicador rotulo="Saídas" valor={saidas} nota="transferidos, falecidos, removidos" icone={UserMinus} tom="destructive" aCarregar={basicos.isPending}
              activo={!!estado && OUTROS_ESTADOS.includes(estado)} aoClicar={() => filtrar({ estado: OUTROS_ESTADOS.find((e) => contagens[e]) })} />
          ) : (
            <Indicador rotulo={t.membros.porAprovar} valor={porAprovar ?? 0} nota="à espera do secretário" icone={ClipboardCheck} tom="warning" aCarregar={basicos.isPending}
              activo={soPorAprovar} aoClicar={() => filtrar({ validacao: 'PENDENTE' })} />
          )}
        </div>
      )}

      <section className="rounded-xl border bg-card shadow-card" aria-label={t.membros.titulo}>
        <div className="flex flex-wrap items-center gap-3 border-b px-4 py-3 sm:px-6">
          <div className="relative w-full sm:w-80">
            <Search aria-hidden className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
            <Input type="search" value={texto} onChange={(e) => setTexto(e.target.value)} placeholder={t.membros.pesquisar}
              aria-label={t.membros.pesquisar} className="alvo h-9 pl-9" />
          </div>
          {filtroActivo && (
            <button type="button" onClick={() => filtrar({})} aria-label={`Limpar filtro ${filtroActivo}`}
              className="alvo inline-flex h-8 items-center gap-1.5 rounded-md border bg-secondary px-2.5 text-xs font-medium text-secondary-foreground hover:bg-muted">
              {filtroActivo} <X className="size-3.5" aria-hidden />
            </button>
          )}
          {!soPorAprovar && saidas > 0 && (
            <button type="button" onClick={() => filtrar({ validacao: 'PENDENTE' })} className="alvo text-xs font-medium text-primary hover:underline">
              {t.membros.porAprovar} ({porAprovar ?? 0})
            </button>
          )}
          {totalFiltro != null && membros.length > 0 && (
            <span className="num ml-auto text-sm text-muted-foreground">A mostrar 1–{membros.length} de {totalFiltro}</span>
          )}
        </div>

        {lista.isPending ? <LinhasACarregar linhas={6} />
          : lista.isError ? <EstadoErro erro={lista.error} aoTentar={() => lista.refetch()} className="m-4" />
          : membros.length === 0 ? (
            <EstadoVazio icone={Users} titulo={q || estado || soPorAprovar ? 'Sem resultados' : 'Sem membros'}
              accao={!q && !estado && !soPorAprovar && pode('secretaria.membro.criar') && (
                <Button asChild size="sm"><Link to="/membros/novo"><Plus className="size-4" />{t.membros.registar}</Link></Button>
              )}>
              {q || estado || soPorAprovar ? t.membros.nenhumFiltro : t.membros.nenhum}
            </EstadoVazio>
          ) : (
            <>
              <div className="hidden md:block">
                <Tabela porPagina={false}>
                  <thead>
                    <tr>
                      <th className="sm:pl-6">{t.membros.colunas.nome}</th>
                      <th>{t.membros.colunas.estado}</th>
                      <th>{t.membros.colunas.bairro}</th>
                      <th>{t.ficha.profissao}</th>
                      <th className="num">{t.membros.colunas.entrada}</th>
                      <th className="sm:pr-6"><span className="sr-only">Abrir</span></th>
                    </tr>
                  </thead>
                  <tbody>{pag.visiveis.map((m) => <LinhaTabela key={m.id} m={m} />)}</tbody>
                </Tabela>
              </div>
              <ul className="md:hidden">{pag.visiveis.map((m) => <LinhaLista key={m.id} m={m} />)}</ul>
              <ControlosPaginacao {...pag} />
              {lista.hasNextPage && pag.pagina === pag.paginas && (
                <div className="border-t p-3 text-center">
                  <Button variant="outline" size="sm" className="alvo" disabled={lista.isFetchingNextPage} onClick={() => lista.fetchNextPage()}>
                    {lista.isFetchingNextPage ? 'A carregar…' : t.comum.carregarMais}
                  </Button>
                </div>
              )}
            </>
          )}
      </section>
    </>
  )
}
