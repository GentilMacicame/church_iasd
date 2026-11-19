/**
 * Reavivamento por pessoa (V49) · "Quanto cabe a cada um e quanto já deu?"
 * O alvo do ano (Alvos, fundo REAVIVAMENTO) reparte-se igualmente pelos membros activos e pelas crianças registadas;
 * a quota de uma pessoa pode ajustar-se (ex.: sem rendimento) e as outras repartem o resto. As contribuições lançam-se
 * em "Lançar entrada" (campo Reavivamento), de uma vez ou mês a mês.
 */
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { Flame, Pencil, Plus, Search, Target, Users } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Avatar, Cartao, Dinheiro, Indicador, Pilula, Segmentos, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { Seleccao } from '@/components/comum/Seleccao'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { centimos, deCentimos, dinheiro, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useFundos, useFundosMut, useQuotaEscalao, useQuotaEscalaoMut, useQuotasReavivamentoMut, useReavivamentoPessoas, type PessoaReavivamento } from './api'

const sem = (x: string) => x.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()

export default function PaginaReavivamento() {
  const { pode } = useSessao()
  const anoActual = Number(hojeIso().slice(0, 4))
  const [ano, setAno] = useState(anoActual)
  const [quem, setQuem] = useState<'todos' | 'adultos' | 'criancas' | 'em_falta'>('todos')
  const [busca, setBusca] = useState('')
  const [ajustar, setAjustar] = useState<PessoaReavivamento | null>(null)
  const fundos = useFundos()
  const { criar } = useFundosMut()
  const q = useReavivamentoPessoas(ano)
  const temFundo = (fundos.data ?? []).some((f) => f.tipo === 'REAVIVAMENTO' && !f.endDate)
  const lista = useMemo(() => q.data ?? [], [q.data])
  const alvo = centimos(lista[0]?.alvoIgreja ?? '0')
  const contribuido = lista.reduce((s, p) => s + centimos(p.contribuido), 0)
  const criancas = lista.filter((p) => p.menor).length
  // a quota de cada escalão (a de quem não tem ajuste individual)
  const quotaDe = (menor: boolean) => lista.find((p) => p.menor === menor && p.origem !== 'AJUSTADA')?.quota
  const visiveis = lista.filter((p) => (quem === 'todos' || (quem === 'adultos' ? !p.menor : quem === 'criancas' ? p.menor : centimos(p.falta) > 0))
    && (!busca || sem(`${p.nome} ${p.apelido}`).includes(sem(busca))))
  const pct = (a: number, b: number) => (b > 0 ? Math.min(100, Math.round((a / b) * 100)) : 0)

  const criarFundo = () => criar.mutate({ nome: 'Reavivamento', tipo: 'REAVIVAMENTO', restrito: true }, {
    onSuccess: () => toast.success('Fundo do reavivamento criado. Defina agora o alvo do ano.'), onError: (e) => toast.error(mensagemDe(e)),
  })

  return (
    <>
      <TituloPagina icone={Flame} titulo="Reavivamento" descricao="O alvo da igreja repartido por cada pessoa"
        accoes={<div className="w-28"><Seleccao aria-label="Ano" value={String(ano)} onChange={(e) => setAno(Number(e.target.value))}>
          {[anoActual + 1, anoActual, anoActual - 1, anoActual - 2].map((a) => <option key={a} value={a}>{a}</option>)}
        </Seleccao></div>} />

      {fundos.isPending || q.isPending ? <LinhasACarregar linhas={6} />
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
        : !temFundo ? (
          <Cartao><EstadoVazio icone={Flame} titulo="A igreja ainda não tem o fundo do reavivamento"
            accao={pode('tesouraria.fundo.criar') && <Button className="alvo" disabled={criar.isPending} onClick={criarFundo}><Plus className="size-4" />Criar o fundo</Button>}>
            Crie-o para lançar as contribuições e repartir o alvo.
          </EstadoVazio></Cartao>
        ) : !lista.length ? (
          <Cartao><EstadoVazio icone={Target} titulo={`Sem alvo do reavivamento em ${ano}`}
            accao={pode('tesouraria.alvo.criar') && <Button asChild className="alvo"><Link to="/tesouraria/fundos"><Target className="size-4" />Definir o alvo</Link></Button>}>
            Defina o alvo do ano em Fundos e ofertas → Alvos.
          </EstadoVazio></Cartao>
        ) : (
          <div className="grid gap-6">
            <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
              <Indicador rotulo={`Alvo de ${ano}`} valor={<Dinheiro valor={deCentimos(alvo)} />} nota={`${pct(contribuido, alvo)}% já contribuído`} icone={Target} tom="primary" />
              <Indicador rotulo="Contribuído" valor={<Dinheiro valor={deCentimos(contribuido)} />} nota={`falta ${dinheiro(deCentimos(Math.max(0, alvo - contribuido)))}`} icone={Flame} tom="success" />
              <Indicador rotulo="Pessoas" valor={lista.length} nota={`${lista.length - criancas} adultos · ${criancas} crianças`} icone={Users} />
              <Indicador rotulo="Quota adulto · criança" valor={<span className="text-xl">{quotaDe(false) ? dinheiro(quotaDe(false)!) : '—'} · {quotaDe(true) ? dinheiro(quotaDe(true)!) : '—'}</span>} nota="por ano" icone={Users} tom="info" />
            </div>

            <QuotasPorEscalao ano={ano} quotaAdulto={quotaDe(false)} quotaCrianca={quotaDe(true)} />

            <Cartao semMargem>
              <div className="flex flex-wrap items-center gap-3 border-b px-5 py-4 sm:px-6">
                <Segmentos rotulo="Quem" valor={quem} aoMudar={setQuem}
                  opcoes={[{ valor: 'todos', rotulo: 'Todos', contagem: lista.length }, { valor: 'adultos', rotulo: 'Adultos', contagem: lista.length - criancas },
                    { valor: 'criancas', rotulo: 'Crianças', contagem: criancas }, { valor: 'em_falta', rotulo: 'Em falta', contagem: lista.filter((p) => centimos(p.falta) > 0).length }] as const} />
                <div className="relative ml-auto w-full sm:w-64">
                  <Search aria-hidden className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
                  <Input value={busca} onChange={(e) => setBusca(e.target.value)} placeholder="Pesquisar pessoa…" aria-label="Pesquisar pessoa" className="alvo pl-9" />
                </div>
              </div>
              <Tabela porPagina={20}>
                <thead><tr><th className="sm:pl-6">Pessoa</th><th className="num">Quota</th><th className="num hidden md:table-cell">Por mês</th><th className="num">Contribuído</th><th className="hidden lg:table-cell">Cumprimento</th><th className="num">Falta</th><th className="w-12 sm:pr-6"><span className="sr-only">Ajustar</span></th></tr></thead>
                <tbody>
                  {visiveis.map((p) => {
                    const quota = centimos(p.quota), dado = centimos(p.contribuido)
                    return (
                      <tr key={p.membroId}>
                        <td className="sm:pl-6">
                          <span className="flex items-center gap-3">
                            <Avatar id={p.membroId} nome={p.nome} apelido={p.apelido} tamanho={32} />
                            <span className="min-w-0">
                              <Link to={`/membros/${p.membroId}`} className="block truncate font-medium hover:text-primary">{p.nome} {p.apelido}</Link>
                              <span className="flex items-center gap-1.5 text-xs text-muted-foreground">{p.menor ? 'Criança' : 'Adulto'}{p.origem === 'AJUSTADA' ? <Pilula variante="info">ajustada</Pilula> : p.origem === 'ESCALAO' ? <Pilula variante="secondary">fixa</Pilula> : null}</span>
                            </span>
                          </span>
                        </td>
                        <td className="num font-medium" title={p.motivo ?? undefined}><Dinheiro valor={p.quota} /></td>
                        <td className="num hidden text-muted-foreground md:table-cell">{dinheiro(deCentimos(Math.round(quota / 12)))}</td>
                        <td className="num"><Dinheiro valor={p.contribuido} /></td>
                        <td className="hidden lg:table-cell">
                          <span className="flex items-center gap-2">
                            <span className="h-1.5 w-24 overflow-hidden rounded-full bg-muted"><span className={cn('block h-full rounded-full', dado >= quota ? 'bg-success' : 'bg-primary')} style={{ width: `${pct(dado, quota)}%` }} /></span>
                            <span className="text-xs text-muted-foreground tabular-nums">{quota ? `${pct(dado, quota)}%` : '—'}</span>
                          </span>
                        </td>
                        <td className={cn('num font-medium', centimos(p.falta) > 0 ? 'text-warning-text' : 'text-success-text')}>{centimos(p.falta) > 0 ? <Dinheiro valor={p.falta} /> : 'em dia'}</td>
                        <td className="sm:pr-6">
                          {pode(p.quotaId ? 'tesouraria.quota_reavivamento.alterar' : 'tesouraria.quota_reavivamento.criar') && (
                            <Button variant="ghost" size="icon" className="alvo size-9 text-muted-foreground" aria-label={`Ajustar a quota de ${p.nome}`} onClick={() => setAjustar(p)}><Pencil className="size-4" /></Button>
                          )}
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </Tabela>
            </Cartao>
          </div>
        )}
      {ajustar && <DialogoAjustar p={ajustar} ano={ano} aoFechar={() => setAjustar(null)} />}
    </>
  )
}

function DialogoAjustar({ p, ano, aoFechar }: { p: PessoaReavivamento; ano: number; aoFechar: () => void }) {
  const { ajustar, retirar } = useQuotasReavivamentoMut()
  const [valor, setValor] = useState(p.quotaAjustada ?? p.quota)
  const [motivo, setMotivo] = useState(p.motivo ?? '')
  const [erro, setErro] = useState<string | null>(null)
  const gravar = () => {
    setErro(null)
    if (!/^\d{1,10}(\.\d{1,2})?$/.test(valor)) return setErro('Escreva a quota, ex.: 250,00.')
    ajustar.mutate({ quotaId: p.quotaId, membroId: p.membroId, ano, valor, motivo: motivo.trim() }, {
      onSuccess: () => { toast.success('Quota ajustada. As outras repartem o resto do alvo.'); aoFechar() }, onError: (e) => setErro(mensagemDe(e)),
    })
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Quota de {p.nome} {p.apelido}</DialogTitle>
          <DialogDescription>{ano} · as outras pessoas repartem o resto do alvo.</DialogDescription>
        </DialogHeader>
        <ErroFormulario mensagem={erro} />
        <div className="grid gap-4">
          <div className="campo-flutuante grid gap-1.5"><label htmlFor="qrv-valor" className="text-sm font-medium">Quota do ano</label><CampoDinheiro id="qrv-valor" value={valor} onChange={setValor} className="alvo" /></div>
          <div className="campo-flutuante grid gap-1.5"><label htmlFor="qrv-motivo" className="text-sm font-medium">Motivo</label><Input id="qrv-motivo" value={motivo} onChange={(e) => setMotivo(e.target.value)} maxLength={255} placeholder="ex.: sem rendimento" className="alvo" /></div>
        </div>
        <DialogFooter>
          {p.quotaId != null && (
            <Button type="button" variant="ghost" className="alvo mr-auto" disabled={retirar.isPending}
              onClick={() => retirar.mutate(p.quotaId!, { onSuccess: () => { toast.success('Volta à quota igual.'); aoFechar() }, onError: (e) => setErro(mensagemDe(e)) })}>Voltar à quota igual</Button>
          )}
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={ajustar.isPending} onClick={gravar}>{ajustar.isPending ? t.comum.aGravar : 'Guardar'}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/** Quotas por escalão: um valor para todos os adultos e outro para todas as crianças; vazio = automático. */
function QuotasPorEscalao({ ano, quotaAdulto, quotaCrianca }: { ano: number; quotaAdulto?: string; quotaCrianca?: string }) {
  const { pode } = useSessao()
  const q = useQuotaEscalao(ano)
  const gravar = useQuotaEscalaoMut()
  const [adulto, setAdulto] = useState<string | null>(null)
  const [crianca, setCrianca] = useState<string | null>(null)
  const a = adulto ?? q.data?.quotaAdulto ?? ''
  const c = crianca ?? q.data?.quotaCrianca ?? ''
  const mudou = adulto != null || crianca != null
  const podeGravar = pode(q.data ? 'tesouraria.quota_escalao_reavivamento.alterar' : 'tesouraria.quota_escalao_reavivamento.criar')
  const guardar = () => gravar.mutate({ id: q.data?.id, ano, quotaAdulto: a || null, quotaCrianca: c || null }, {
    onSuccess: () => { setAdulto(null); setCrianca(null); toast.success('Quotas guardadas.') }, onError: (e) => toast.error(mensagemDe(e)),
  })
  const campo = (rotulo: string, valor: string, mudar: (v: string) => void, actual?: string, fixa?: boolean) => (
    <div className="grid gap-1.5">
      <span className="text-sm font-medium">{rotulo}</span>
      <CampoDinheiro aria-label={rotulo} value={valor} onChange={mudar} placeholder="Automático" disabled={!podeGravar} className="alvo" />
      <span className="text-xs text-muted-foreground">{fixa ? 'Fixa para todos' : `Automática${actual ? `: ${dinheiro(actual)}` : ''}`}{actual ? ` · ${dinheiro(deCentimos(Math.round(centimos(actual) / 12)))} por mês` : ''}</span>
    </div>
  )
  return (
    <Cartao titulo="Quotas por escalão" descricao="Vazio = automático: reparte o resto do alvo" icone={Users}
      accoes={podeGravar && mudou && <Button size="sm" className="alvo" disabled={gravar.isPending} onClick={guardar}>{gravar.isPending ? t.comum.aGravar : t.comum.guardar}</Button>}>
      <div className="grid gap-4 sm:grid-cols-2">
        {campo('Adultos', a, setAdulto, quotaAdulto, !!q.data?.quotaAdulto)}
        {campo('Crianças', c, setCrianca, quotaCrianca, !!q.data?.quotaCrianca)}
      </div>
    </Cartao>
  )
}
