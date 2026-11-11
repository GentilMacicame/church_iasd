/**
 * Fecho do mês (P-10) · "Que mês fecho a seguir, e já está tudo pronto?"
 * No topo, o mês a fechar a seguir com a lista de verificação calculada a partir dos dados (movimentos pendentes,
 * contagens por conferir, remessa à Missão) e o resumo do mês. Em baixo, os últimos 12 meses com entradas, saídas e
 * estado. Fechar um mês bloqueia qualquer movimento com data nesse mês (a base de dados recusa). Reabrir termina o
 * fecho (fica no histórico, nada se apaga) e exige uma permissão que o tesoureiro não tem.
 */
import { useState, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { ArrowDownRight, ArrowUpRight, CalendarCheck, CircleAlert, CircleCheck, Lock, LockOpen, Scale } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Cartao, Dinheiro, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro, LinhasACarregar } from '@/components/comum/estados'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { centimos, data, deCentimos, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { daMissao, useContagens, useContas, useFechos, useFechosMut, useMovimentos, useRemessas, useRemessasDevidas, type Fecho } from './api'
import { nomeMes } from './PaginaRemessas'

interface Mes {
  ano: number; mes: number; chave: string; fecho?: Fecho; reaberturas: Fecho[]
  entradas: number; saidas: number; pendentes: number; contagensAbertas: number
  remessaEnviada: boolean; porRemeter: number
}

function ultimosMeses(n: number) {
  const [a, m] = hojeIso().split('-').map(Number)
  return Array.from({ length: n }, (_, i) => {
    const d = new Date(Date.UTC(a, m - 1 - i, 1))
    return { ano: d.getUTCFullYear(), mes: d.getUTCMonth() + 1 }
  })
}
const Mes1 = (s: string) => s.replace(/^./, (c) => c.toUpperCase())

export default function PaginaFechos() {
  const { pode } = useSessao()
  const q = useFechos()
  const { fechar, reabrir } = useFechosMut()
  const lista = ultimosMeses(12)
  const ultimo = lista[lista.length - 1]
  const movs = useMovimentos({ desde: `${ultimo.ano}-${String(ultimo.mes).padStart(2, '0')}-01`, ate: hojeIso() })
  const contas = useContas()
  const contagens = useContagens()
  const remessas = useRemessas()
  const devidas = useRemessasDevidas()
  const [aFechar, setAFechar] = useState<Mes | null>(null)
  const [aReabrir, setAReabrir] = useState<Mes | null>(null)
  const actual = hojeIso().slice(0, 7)
  const naMissao = new Set((contas.data ?? []).filter((c) => daMissao(c)).map((c) => c.id))

  const meses: Mes[] = lista.map(({ ano, mes }) => {
    const chave = `${ano}-${String(mes).padStart(2, '0')}`
    const doMes = (q.data ?? []).filter((f) => f.ano === ano && f.mes === mes)
    let entradas = 0, saidas = 0, pendentes = 0
    for (const t of movs.data ?? []) {
      if (t.endDate || !t.dataHora.startsWith(chave)) continue
      if (t.estado === 'PENDENTE') pendentes++
      if (t.estado !== 'CONFIRMADA' || naMissao.has(t.contaId ?? 0) || t.tipo === 'TRANSFERENCIA') continue
      if (t.tipo === 'ENTRADA') entradas += centimos(t.valorTotal); else saidas += centimos(t.valorTotal)
    }
    return {
      ano, mes, chave, fecho: doMes.find((f) => !f.endDate), reaberturas: doMes.filter((f) => !!f.endDate),
      entradas, saidas, pendentes,
      contagensAbertas: (contagens.data ?? []).filter((c) => !c.endDate && c.estado === 'ABERTA' && c.data.startsWith(chave)).length,
      remessaEnviada: (remessas.data ?? []).some((r) => !r.endDate && r.ano === ano && r.mes === mes && r.estado !== 'PREPARADA'),
      porRemeter: (devidas.data ?? []).filter((d) => d.ano === ano && d.mes === mes).reduce((s, d) => s + Math.max(0, centimos(d.emFalta)), 0),
    }
  })
  // o mês a fechar a seguir: o mais antigo aberto depois do último fechado (sem fechos, o mês passado)
  const ultimoFechado = meses.find((m) => m.fecho)
  const proximo = ultimoFechado
    ? [...meses].reverse().find((m) => !m.fecho && m.chave > ultimoFechado.chave && m.chave < actual)
    : meses.find((m) => m.chave < actual)
  const aCarregar = q.isPending || movs.isPending
  const podeFechar = pode('tesouraria.fecho_periodo.criar')

  return (
    <>
      <TituloPagina icone={CalendarCheck} titulo="Fecho do mês"
        descricao="Depois de conferir os saldos com o banco e o caixa, feche o mês: nada mais se lança com data nesse mês." />
      <div className="grid gap-6">
        {q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
          : aCarregar ? <Barra className="h-56 w-full rounded-xl" />
          : proximo ? <ProximoFecho m={proximo} podeFechar={podeFechar} aoFechar={() => setAFechar(proximo)} />
          : (
            <section className="flex items-center gap-3 rounded-xl border border-success/25 bg-tint-success px-5 py-4 text-sm text-success-text">
              <CircleCheck className="size-5 flex-none" />Os meses anteriores estão todos fechados. O mês em curso fecha-se depois de terminar.
            </section>
          )}

        <Cartao titulo="Últimos 12 meses" descricao="Entradas e saídas confirmadas nas contas da igreja" icone={CalendarCheck} semMargem>
          {aCarregar ? <LinhasACarregar linhas={6} /> : (
            <Tabela>
              <thead><tr>
                <th className="sm:pl-6">Mês</th><th className="num hidden sm:table-cell">Entradas</th><th className="num hidden sm:table-cell">Saídas</th>
                <th>Estado</th><th className="sm:pr-6"><span className="sr-only">Acções</span></th>
              </tr></thead>
              <tbody>
                {meses.map((m) => {
                  const vazio = !m.fecho && m.chave < actual && m !== proximo && !m.entradas && !m.saidas && !m.pendentes
                  return (
                  <tr key={m.chave} className={cn(m === proximo && 'bg-primary/[0.03]')}>
                    <td className="sm:pl-6">
                      <p className="font-medium">{Mes1(nomeMes(m.ano, m.mes))}</p>
                      <p className="text-xs text-muted-foreground">
                        {m.fecho ? `Fechado em ${data(m.fecho.criadoEm)}` : m.chave === actual ? 'Mês em curso' : m === proximo ? 'A fechar a seguir' : vazio ? 'Sem movimentos' : 'Por fechar'}
                        {m.reaberturas.length > 0 && ` · reaberto ${m.reaberturas.length}×`}
                        {!m.fecho && m.pendentes > 0 && <span className="text-warning-text"> · {m.pendentes} pendente(s)</span>}
                      </p>
                    </td>
                    <td className="num hidden sm:table-cell">{m.entradas ? <Dinheiro valor={deCentimos(m.entradas)} /> : <span className="text-muted-foreground">—</span>}</td>
                    <td className="num hidden text-muted-foreground sm:table-cell">{m.saidas ? <Dinheiro valor={deCentimos(m.saidas)} /> : '—'}</td>
                    <td>
                      {m.fecho ? <Pilula variante="success"><Lock className="size-3" />Fechado</Pilula>
                        : m.chave === actual ? <Pilula variante="secondary">Em curso</Pilula>
                        : vazio ? <span className="text-xs text-muted-foreground">—</span>
                        : <Pilula variante="warning">Aberto</Pilula>}
                    </td>
                    <td className="text-right sm:pr-6">
                      {m.fecho && pode('tesouraria.fecho_periodo.terminar') && (
                        <Button size="sm" variant="ghost" className="alvo text-muted-foreground" onClick={() => setAReabrir(m)}><LockOpen className="size-4" />Reabrir</Button>
                      )}
                      {!m.fecho && !vazio && m !== proximo && m.chave < actual && podeFechar && (
                        <Button size="sm" variant="ghost" className="alvo text-muted-foreground" onClick={() => setAFechar(m)}><Lock className="size-4" />Fechar</Button>
                      )}
                    </td>
                  </tr>
                  )
                })}
              </tbody>
            </Tabela>
          )}
          <p className="border-t px-4 py-3 text-xs text-muted-foreground sm:px-6">
            Um erro descoberto num mês fechado corrige-se com um estorno no mês aberto; só o pastor ou o administrador podem reabrir.
          </p>
        </Cartao>
      </div>

      {aFechar && (
        <DialogoConfirmar aberto aoMudar={(v) => !v && setAFechar(null)} titulo={`Fechar ${nomeMes(aFechar.ano, aFechar.mes)}?`} aCorrer={fechar.isPending} accao="Fechar mês"
          texto={<>
            Depois de fechado, ninguém lança nem confirma movimentos com data neste mês.
            {aFechar.pendentes > 0 && <strong className="mt-2 block text-warning-text">Há {aFechar.pendentes} movimento(s) pendente(s): confirme-os ou anule-os antes de fechar.</strong>}
            {aFechar.porRemeter > 0 && <strong className="mt-2 block text-warning-text">Falta depositar <Dinheiro valor={deCentimos(aFechar.porRemeter)} /> à Missão neste mês.</strong>}
          </>}
          aoConfirmar={() => fechar.mutate({ ano: aFechar.ano, mes: aFechar.mes }, {
            onSuccess: () => { toast.success(`${Mes1(nomeMes(aFechar.ano, aFechar.mes))} fechado.`); setAFechar(null) },
            onError: (e) => { toast.error(mensagemDe(e)); setAFechar(null) },
          })} />
      )}
      <DialogoConfirmar aberto={!!aReabrir} aoMudar={(v) => !v && setAReabrir(null)} titulo={`Reabrir ${aReabrir ? nomeMes(aReabrir.ano, aReabrir.mes) : ''}?`}
        texto="Volta a ser possível lançar e confirmar movimentos com data neste mês. A reabertura fica registada no histórico." accao="Reabrir mês" perigo
        aCorrer={reabrir.isPending}
        aoConfirmar={() => aReabrir?.fecho && reabrir.mutate(aReabrir.fecho.id, {
          onSuccess: () => { toast.success('Mês reaberto.'); setAReabrir(null) },
          onError: (e) => { toast.error(mensagemDe(e)); setAReabrir(null) },
        })} />
    </>
  )
}

/** O mês a fechar a seguir: resumo e lista de verificação (calculada; o saldo do banco confere-se à mão). */
function ProximoFecho({ m, podeFechar, aoFechar }: { m: Mes; podeFechar: boolean; aoFechar: () => void }) {
  const resultado = m.entradas - m.saidas
  const passos: { ok: boolean | null; titulo: string; detalhe: ReactNode; para?: string; accao?: string }[] = [
    { ok: m.pendentes === 0, titulo: 'Movimentos confirmados', para: '/tesouraria/movimentos', accao: 'Ver movimentos',
      detalhe: m.pendentes ? `${m.pendentes} pendente(s): confirme ou anule` : 'Nenhum pendente' },
    { ok: m.contagensAbertas === 0, titulo: 'Contagens conferidas', para: '/tesouraria/contagens', accao: 'Ver contagens',
      detalhe: m.contagensAbertas ? `${m.contagensAbertas} contagem(ns) por conferir` : 'Contado = lançado' },
    { ok: m.porRemeter === 0 && (m.remessaEnviada || m.entradas === 0), titulo: 'Depósito à Missão', para: '/tesouraria/remessas', accao: 'Ver depósitos',
      detalhe: m.porRemeter > 0 ? <>Falta depositar <Dinheiro valor={deCentimos(m.porRemeter)} /></> : m.remessaEnviada ? 'Depositado' : 'Nada a depositar' },
    { ok: null, titulo: 'Saldos conferidos', para: '/tesouraria/contas', accao: 'Ver contas',
      detalhe: 'Compare cada conta com o extracto do banco, do M-Pesa e com o caixa' },
  ]
  const prontos = passos.filter((p) => p.ok === true).length
  return (
    <section className="overflow-hidden rounded-xl border bg-card shadow-card">
      <div className="grid gap-6 p-5 sm:p-6 lg:grid-cols-[1fr_1.4fr]">
        <div className="grid content-start gap-4">
          <div>
            <p className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">A fechar a seguir</p>
            <h2 className="mt-1 text-2xl font-semibold tracking-tight">{Mes1(nomeMes(m.ano, m.mes))}</h2>
            <p className="mt-1 text-sm text-muted-foreground">{prontos} de 3 verificações automáticas feitas</p>
          </div>
          <dl className="grid grid-cols-3 gap-3 rounded-lg bg-muted/40 p-3">
            <div><dt className="flex items-center gap-1 text-xs text-muted-foreground"><ArrowDownRight className="size-3.5 text-success-text" />Entradas</dt><dd className="num mt-0.5 font-semibold"><Dinheiro valor={deCentimos(m.entradas)} /></dd></div>
            <div><dt className="flex items-center gap-1 text-xs text-muted-foreground"><ArrowUpRight className="size-3.5 text-destructive-text" />Saídas</dt><dd className="num mt-0.5 font-semibold"><Dinheiro valor={deCentimos(m.saidas)} /></dd></div>
            <div><dt className="flex items-center gap-1 text-xs text-muted-foreground"><Scale className="size-3.5" />Resultado</dt><dd className={cn('num mt-0.5 font-semibold', resultado < 0 && 'text-destructive-text')}><Dinheiro valor={deCentimos(resultado)} /></dd></div>
          </dl>
          {podeFechar && (
            <Button className="alvo h-11 w-full sm:w-auto sm:justify-self-start" onClick={aoFechar}>
              <Lock className="size-4" />Fechar {nomeMes(m.ano, m.mes)}
            </Button>
          )}
        </div>
        <ol className="grid content-start gap-2">
          {passos.map((p) => (
            <li key={p.titulo} className="flex items-center gap-3 rounded-lg border px-3 py-2.5">
              {p.ok === true ? <CircleCheck className="size-5 flex-none text-success-text" aria-label="feito" />
                : p.ok === false ? <CircleAlert className="size-5 flex-none text-warning-text" aria-label="por fazer" />
                : <Scale className="size-5 flex-none text-muted-foreground" aria-label="conferir à mão" />}
              <div className="min-w-0 flex-1">
                <p className="text-sm font-medium">{p.titulo}</p>
                <p className={cn('text-xs', p.ok === false ? 'text-warning-text' : 'text-muted-foreground')}>{p.detalhe}</p>
              </div>
              {p.para && p.ok !== true && <Link to={p.para} className="alvo flex-none text-xs font-medium text-primary hover:underline">{p.accao}</Link>}
            </li>
          ))}
        </ol>
      </div>
    </section>
  )
}
