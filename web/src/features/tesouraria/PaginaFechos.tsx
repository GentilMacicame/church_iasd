/**
 * Fecho do mês (P-10) · "Que meses já estão fechados?"
 * Fechar um mês bloqueia qualquer movimento com data nesse mês (a base de dados recusa). Reabrir termina o fecho
 * (fica no histórico, nada se apaga) e exige uma permissão que o tesoureiro não tem.
 */
import { useState } from 'react'
import { CalendarCheck, Lock, LockOpen, ShieldAlert } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Cartao, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, LinhasACarregar } from '@/components/comum/estados'
import { DialogoConfirmar } from '@/components/comum/confirmar'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { data, hojeIso } from '@/lib/formatos'
import { useFechos, useFechosMut, useMovimentos, type Fecho } from './api'
import { nomeMes } from './PaginaRemessas'

interface Mes { ano: number; mes: number; chave: string; fecho?: Fecho; reaberturas: Fecho[] }

function ultimosMeses(n: number) {
  const [a, m] = hojeIso().split('-').map(Number)
  return Array.from({ length: n }, (_, i) => {
    const d = new Date(Date.UTC(a, m - 1 - i, 1))
    return { ano: d.getUTCFullYear(), mes: d.getUTCMonth() + 1 }
  })
}
const ultimoDia = (ano: number, mes: number) => new Date(Date.UTC(ano, mes, 0)).getUTCDate()

export default function PaginaFechos() {
  const { pode } = useSessao()
  const q = useFechos()
  const { fechar, reabrir } = useFechosMut()
  const [aFechar, setAFechar] = useState<Mes | null>(null)
  const [aReabrir, setAReabrir] = useState<Mes | null>(null)
  const actual = hojeIso().slice(0, 7)

  const meses: Mes[] = ultimosMeses(12).map(({ ano, mes }) => {
    const doMes = (q.data ?? []).filter((f) => f.ano === ano && f.mes === mes)
    return { ano, mes, chave: `${ano}-${String(mes).padStart(2, '0')}`, fecho: doMes.find((f) => !f.endDate), reaberturas: doMes.filter((f) => !!f.endDate) }
  })
  // o mês a fechar a seguir: o primeiro aberto depois do último fechado (sem fechos, o mês passado)
  const ultimoFechado = meses.find((m) => m.fecho)
  const proximo = ultimoFechado
    ? [...meses].reverse().find((m) => !m.fecho && m.chave > ultimoFechado.chave && m.chave < actual)
    : meses.find((m) => m.chave < actual)

  return (
    <>
      <TituloPagina icone={CalendarCheck} titulo="Fecho do mês"
        descricao="Depois de conferir os saldos com o banco e o caixa, feche o mês: nada mais se lança com data nesse mês." />
      <div className="grid items-start gap-6 lg:grid-cols-12">
        <Cartao titulo="Últimos 12 meses" icone={CalendarCheck} semMargem className="lg:col-span-8">
          {q.isPending ? <LinhasACarregar linhas={6} />
            : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="mx-6 mb-6" />
            : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Mês</th><th>Estado</th><th className="sm:pr-6"><span className="sr-only">Acções</span></th></tr></thead>
                <tbody>
                  {meses.map((m) => (
                    <tr key={m.chave}>
                      <td className="sm:pl-6">
                        <p className="font-medium first-letter:uppercase">{nomeMes(m.ano, m.mes)}</p>
                        <p className="text-xs text-muted-foreground">
                          {m.fecho ? `Fechado em ${data(m.fecho.criadoEm)}` : m.chave === actual ? 'Mês em curso' : 'Aberto'}
                          {m.reaberturas.length > 0 && ` · reaberto ${m.reaberturas.length}× (último em ${data(m.reaberturas[m.reaberturas.length - 1].endDate)})`}
                        </p>
                      </td>
                      <td>{m.fecho ? <Pilula variante="success"><Lock className="mr-1 size-3" />Fechado</Pilula> : <Pilula variante={m.chave === actual ? 'secondary' : 'warning'}>Aberto</Pilula>}</td>
                      <td className="text-right sm:pr-6">
                        {!m.fecho && m.chave < actual && pode('tesouraria.fecho_periodo.criar') && (
                          <Button size="sm" variant={m === proximo ? 'default' : 'outline'} className="alvo" onClick={() => setAFechar(m)}><Lock className="size-4" />Fechar</Button>
                        )}
                        {m.fecho && pode('tesouraria.fecho_periodo.terminar') && (
                          <Button size="sm" variant="ghost" className="alvo text-muted-foreground" onClick={() => setAReabrir(m)}><LockOpen className="size-4" />Reabrir</Button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </Tabela>
            )}
        </Cartao>
        <Cartao titulo="Antes de fechar" icone={ShieldAlert} className="lg:col-span-4">
          <ol className="grid list-decimal gap-2 pl-4 text-sm text-muted-foreground">
            <li>Confirme os movimentos pendentes do mês (ou anule-os).</li>
            <li>Compare o saldo de cada conta com o extracto do banco, da carteira móvel e com o caixa contado.</li>
            <li>Envie a remessa do mês à Associação.</li>
            <li>Feche o mês. Um erro descoberto depois corrige-se com um estorno no mês aberto, ou pede-se ao pastor ou ao administrador que reabra.</li>
          </ol>
        </Cartao>
      </div>

      {aFechar && <ConfirmarFecho m={aFechar} aCorrer={fechar.isPending} aoFechar={() => setAFechar(null)}
        aoConfirmar={() => fechar.mutate({ ano: aFechar.ano, mes: aFechar.mes }, {
          onSuccess: () => { toast.success(`${nomeMes(aFechar.ano, aFechar.mes).replace(/^./, (c) => c.toUpperCase())} fechado.`); setAFechar(null) },
          onError: (e) => { toast.error(mensagemDe(e)); setAFechar(null) },
        })} />}
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

/** Diz quantos movimentos do mês ainda estão pendentes (ficariam presos no mês fechado). */
function ConfirmarFecho({ m, aCorrer, aoConfirmar, aoFechar }: { m: Mes; aCorrer: boolean; aoConfirmar: () => void; aoFechar: () => void }) {
  const movs = useMovimentos({ desde: `${m.chave}-01`, ate: `${m.chave}-${String(ultimoDia(m.ano, m.mes)).padStart(2, '0')}` })
  const pendentes = (movs.data ?? []).filter((x) => !x.endDate && x.estado === 'PENDENTE').length
  return (
    <DialogoConfirmar aberto aoMudar={(v) => !v && aoFechar()} titulo={`Fechar ${nomeMes(m.ano, m.mes)}?`} aCorrer={aCorrer || movs.isPending} accao="Fechar mês"
      texto={<>
        Depois de fechado, ninguém lança nem confirma movimentos com data neste mês.
        {movs.isPending ? ' A verificar movimentos pendentes…'
          : pendentes > 0 ? <strong className="mt-2 block text-warning-text">Há {pendentes} movimento(s) pendente(s) neste mês: confirme-os ou anule-os antes de fechar.</strong>
          : ' Não há movimentos pendentes neste mês.'}
      </>}
      aoConfirmar={aoConfirmar} />
  )
}
