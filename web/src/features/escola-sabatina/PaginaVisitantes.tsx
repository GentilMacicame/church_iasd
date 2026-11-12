/**
 * Visitantes da Escola Sabatina (F-ES-06) · "Quem nos visitou e quem ainda precisa de seguimento?"
 * Nome, contacto e quem convidou; marca-se quando o visitante se torna membro (ou interessado registado).
 * Ao fim de 12 meses sem se tornar membro, a base de dados anonimiza-o (RNF-08).
 */
import { useMemo, useState } from 'react'
import { Phone, Search, UserCheck, UserPlus } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { EstadoErro, EstadoVazio, LinhasACarregar } from '@/components/comum/estados'
import { CampoFormulario, ErroFormulario } from '@/components/comum/formulario'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { useSessao } from '@/auth/sessao'
import { mensagemDe } from '@/api/erros'
import { t } from '@/i18n/pt-MZ'
import { data } from '@/lib/formatos'
import { useMembrosBasicos } from '@/features/membros/api'
import { useVisitantes, useVisitanteTornouSe, type Visitante } from './api'

type Filtro = 'seguimento' | 'membros' | 'todos'
const normal = (s: string) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()

export default function PaginaVisitantes() {
  const { pode } = useSessao()
  const q = useVisitantes()
  const basicos = useMembrosBasicos()
  const [filtro, setFiltro] = useState<Filtro>('seguimento')
  const [texto, setTexto] = useState('')
  const [marcar, setMarcar] = useState<Visitante | null>(null)
  const nomeDe = (id?: number | null) => { const m = id ? basicos.data?.find((x) => x.id === id) : undefined; return m ? `${m.nome} ${m.apelido}` : undefined }
  const todos = q.data ?? []
  const seguimento = todos.filter((v) => !v.tornouSeMembroId && !v.anonimizadoEm)
  const membros = todos.filter((v) => v.tornouSeMembroId)
  const lista = useMemo(() => {
    const base = filtro === 'seguimento' ? seguimento : filtro === 'membros' ? membros : todos
    const n = normal(texto.trim())
    return n ? base.filter((v) => normal(`${v.nome} ${v.telefone ?? ''}`).includes(n)) : base
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q.data, filtro, texto])

  return (
    <>
      <TituloPagina icone={UserPlus} titulo={t.es.visitantes} descricao="Visitantes registados nos relatórios do sábado, para o seguimento" />
      <div className="grid gap-6">
        <div className="grid grid-cols-3 gap-3 sm:gap-4">
          <Indicador rotulo="Por acompanhar" valor={seguimento.length} nota="ainda não são membros" icone={UserPlus} tom="warning" aCarregar={q.isPending}
            aoClicar={() => setFiltro('seguimento')} activo={filtro === 'seguimento'} />
          <Indicador rotulo="Tornaram-se membros" valor={membros.length} nota="ou interessados registados" icone={UserCheck} tom="success" aCarregar={q.isPending}
            aoClicar={() => setFiltro('membros')} activo={filtro === 'membros'} />
          <Indicador rotulo="Todos" valor={todos.length} nota="mais recentes primeiro" aCarregar={q.isPending} aoClicar={() => setFiltro('todos')} activo={filtro === 'todos'} />
        </div>
        <Cartao semMargem titulo="Visitantes" accoes={
          <div className="relative w-48 sm:w-64">
            <Search aria-hidden className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
            <Input value={texto} onChange={(e) => setTexto(e.target.value)} placeholder="Nome ou telefone" aria-label="Procurar visitante" className="h-9 pl-9" />
          </div>
        }>
          {q.isPending ? <LinhasACarregar linhas={4} />
            : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="mx-6 mb-6" />
            : lista.length === 0 ? <EstadoVazio icone={UserPlus}>{texto ? 'Ninguém com esse nome.' : filtro === 'seguimento' ? 'Nenhum visitante por acompanhar.' : 'Sem visitantes registados.'}</EstadoVazio>
            : (
              <Tabela>
                <thead><tr><th className="sm:pl-6">Visitante</th><th className="hidden sm:table-cell">Visitou em</th><th className="hidden md:table-cell">Convidado por</th><th>Situação</th><th className="sm:pr-6" /></tr></thead>
                <tbody>
                  {lista.map((v) => (
                    <tr key={v.id}>
                      <td className="sm:pl-6">
                        <span className="block font-medium">{v.anonimizadoEm ? <span className="text-muted-foreground">(anonimizado)</span> : v.nome}</span>
                        {v.telefone && !v.anonimizadoEm && (
                          <a href={`tel:${v.telefone}`} className="alvo inline-flex items-center gap-1 text-xs text-primary hover:underline"><Phone className="size-3" />{v.telefone}</a>
                        )}
                        <span className="block text-xs text-muted-foreground sm:hidden">{data(v.criadoEm?.slice(0, 10))}</span>
                      </td>
                      <td className="hidden tabular-nums text-muted-foreground sm:table-cell">{data(v.criadoEm?.slice(0, 10))}</td>
                      <td className="hidden md:table-cell">{nomeDe(v.convidadoPorMembroId) ?? <span className="text-muted-foreground">—</span>}</td>
                      <td>
                        {v.tornouSeMembroId ? <Pilula variante="success">{nomeDe(v.tornouSeMembroId) ?? 'Membro'}</Pilula>
                          : v.anonimizadoEm ? <Pilula variante="secondary">Anonimizado</Pilula>
                          : <Pilula variante="warning">Por acompanhar</Pilula>}
                      </td>
                      <td className="text-right sm:pr-6">
                        {!v.tornouSeMembroId && !v.anonimizadoEm && pode('escola_sabatina.visitante.alterar') && (
                          <Button variant="outline" size="sm" className="alvo" onClick={() => setMarcar(v)}>Tornou-se membro</Button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </Tabela>
            )}
        </Cartao>
      </div>
      {marcar && <DialogoTornouSe visitante={marcar} aoFechar={() => setMarcar(null)} nomeDe={nomeDe} />}
    </>
  )
}

function DialogoTornouSe({ visitante, aoFechar, nomeDe }: { visitante: Visitante; aoFechar: () => void; nomeDe: (id: number) => string | undefined }) {
  const gravar = useVisitanteTornouSe()
  const [membro, setMembro] = useState<number | null>(null)
  const [erro, setErro] = useState<string | null>(null)
  const submeter = async () => {
    if (!membro) return
    setErro(null)
    try {
      await gravar.mutateAsync({ id: visitante.id, membroId: membro })
      toast.success(`${visitante.nome} ligado(a) ao registo de membro.`)
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }
  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{visitante.nome} tornou-se membro</DialogTitle>
          <DialogDescription>Escolha o registo na secretaria (membro ou interessado). Se ainda não existir, registe-o primeiro em Membros.</DialogDescription>
        </DialogHeader>
        <ErroFormulario mensagem={erro} />
        <CampoFormulario rotulo="Registo de membro">
          {(p) => <CampoMembro id={p.id} valor={membro} aoMudar={setMembro} nomeDe={nomeDe} estados={['ACTIVO', 'INTERESSADO']} />}
        </CampoFormulario>
        <DialogFooter>
          <Button variant="outline" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button onClick={() => void submeter()} disabled={!membro || gravar.isPending}>{gravar.isPending ? t.comum.aGravar : t.comum.guardar}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
