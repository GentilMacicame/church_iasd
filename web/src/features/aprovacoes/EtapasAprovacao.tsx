/**
 * As etapas de um processo de aprovação, à vista: as decididas (quem, quando, com que voto), a em curso (quem é o
 * responsável, com os nomes) e as que faltam. E a janela para decidir a etapa em curso: aprovar ou rejeitar (perfil ou
 * permissão) ou indicar o voto da reunião (órgão). Quem pode decidir, a ordem e "outra pessoa" decide-os a base de dados.
 */
import { useState } from 'react'
import { Check, CircleDot, Gavel, Hourglass, Users, X } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Pilula } from '@/components/comum/elementos'
import { Barra } from '@/components/comum/estados'
import { ErroFormulario } from '@/components/comum/formulario'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { mensagemDe } from '@/api/erros'
import { t } from '@/i18n/pt-MZ'
import { centimos, data, dinheiro } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { CampoVoto } from '@/features/livro/CampoVoto'
import { ACCOES, ESTADOS, ORGAOS, PROCESSOS, useAprovacaoDe, useDecidir, useEtapasProcesso, type ProcessoAprovacao } from './api'

/** "Etapa 1 de 2 · Apreciação do tesoureiro" com as barrinhas das etapas. */
export function LinhaEtapa({ p, className }: { p: ProcessoAprovacao; className?: string }) {
  const emCurso = p.estado === 'EM_CURSO'
  return (
    <span className={cn('flex min-w-0 items-center gap-2 text-sm text-muted-foreground', className)}>
      <span className="flex flex-none gap-1" aria-hidden>
        {Array.from({ length: p.totalEtapas }, (_, i) => {
          const n = i + 1
          const feita = p.estado === 'APROVADO' || n < p.etapa
          const rejeitada = p.estado === 'REJEITADO' && n === p.etapa
          return <span key={n} className={cn('h-1.5 w-5 rounded-full', rejeitada ? 'bg-destructive' : feita ? 'bg-success' : emCurso && n === p.etapa ? 'bg-primary' : 'bg-muted')} />
        })}
      </span>
      <span className="truncate">
        {emCurso ? `Etapa ${p.etapa} de ${p.totalEtapas} · ${p.etapaNome ?? ''}` : ESTADOS[p.estado].rotulo}
      </span>
    </span>
  )
}

/** Quem decide a etapa em curso, em palavras: "Tesoureiro: Ana Matos" ou "Conselho da Igreja, por voto". */
export function QuemDecide({ p }: { p: ProcessoAprovacao }) {
  if (p.estado !== 'EM_CURSO') return null
  if (p.responsavelTipo === 'ORGAO') return <>{p.responsavel}, por voto em reunião</>
  return <>{p.responsavel}{p.responsaveis ? `: ${p.responsaveis}` : ' (ninguém tem este perfil na igreja)'}</>
}

/** A lista das etapas de um processo, por ordem. */
export function EtapasAprovacao({ aprovacaoId, className }: { aprovacaoId: number; className?: string }) {
  const q = useEtapasProcesso(aprovacaoId)
  if (q.isPending) return <div className={cn('grid gap-2', className)}>{[0, 1].map((i) => <Barra key={i} className="h-12 w-full" />)}</div>
  const etapas = q.data ?? []
  return (
    <ol className={cn('grid gap-0', className)} aria-label="Etapas da aprovação">
      {etapas.map((e, i) => {
        const ultima = i === etapas.length - 1
        const icone = e.situacao === 'APROVADA' ? <Check className="size-3.5" /> : e.situacao === 'REJEITADA' ? <X className="size-3.5" />
          : e.situacao === 'EM_CURSO' ? <CircleDot className="size-3.5" /> : e.ordem
        return (
          <li key={e.etapaId} className="relative flex gap-3 pb-4 last:pb-0" aria-current={e.situacao === 'EM_CURSO' ? 'step' : undefined}>
            {!ultima && <span className="absolute left-3 top-7 h-[calc(100%-1.5rem)] w-px bg-border" aria-hidden />}
            <span className={cn('relative z-10 flex size-6 flex-none items-center justify-center rounded-full text-xs font-semibold',
              e.situacao === 'APROVADA' ? 'bg-success text-white' : e.situacao === 'REJEITADA' ? 'bg-destructive text-white'
                : e.situacao === 'EM_CURSO' ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground')}>
              {icone}
            </span>
            <div className="min-w-0 flex-1">
              <p className={cn('text-sm font-medium', (e.situacao === 'PENDENTE' || e.situacao === 'NAO_DECIDIDA') && 'text-muted-foreground')}>
                {e.nome}
                <span className="ml-2 text-xs font-normal text-muted-foreground">{ACCOES[e.accao]}: {e.responsavel}</span>
              </p>
              {e.situacao === 'APROVADA' || e.situacao === 'REJEITADA' ? (
                <p className="text-xs text-muted-foreground">
                  {e.situacao === 'APROVADA' ? 'Aprovada' : 'Rejeitada'}
                  {e.votoNumero ? ` pelo voto n.º ${e.votoNumero}` : ''}{e.decididoPor ? ` · ${e.votoNumero ? 'registado por ' : 'por '}${e.decididoPor}` : ''}
                  {e.decididoEm ? ` · ${data(e.decididoEm)}` : ''}
                  {e.valorAprovado ? ` · valor aprovado ${dinheiro(e.valorAprovado)}` : ''}
                  {e.motivo ? ` · «${e.motivo}»` : ''}
                </p>
              ) : e.situacao === 'EM_CURSO' ? (
                <p className="text-xs text-primary">
                  <Hourglass className="mr-1 inline size-3" aria-hidden />
                  Aguarda {e.responsavelTipo === 'ORGAO' ? `o voto: ${e.orgao ? ORGAOS[e.orgao] : e.responsavel}` : `${e.responsavel}${e.responsaveis ? ` (${e.responsaveis})` : ''}`}
                </p>
              ) : e.situacao === 'PENDENTE' ? (
                <p className="text-xs text-muted-foreground">Depois da etapa anterior</p>
              ) : <p className="text-xs text-muted-foreground">Não chegou a ser decidida</p>}
            </div>
          </li>
        )
      })}
    </ol>
  )
}

/** Janela para decidir a etapa em curso. */
export function DialogoDecidirEtapa({ p, aoFechar, aoDecidir }: { p: ProcessoAprovacao; aoFechar: () => void; aoDecidir?: (estado: string) => void }) {
  const decidir = useDecidir()
  const orgao = p.responsavelTipo === 'ORGAO'
  const [rejeitar, setRejeitar] = useState(false)
  const [valor, setValor] = useState(p.valor ?? '')
  const [motivo, setMotivo] = useState('')
  const [voto, setVoto] = useState('')
  const [erro, setErro] = useState<string | null>(null)
  const podeReduzir = p.processo === 'DESPESA' && !!p.valor && !orgao
  const valorValido = !podeReduzir || (/^\d{1,14}(\.\d{1,2})?$/.test(valor) && Number(valor) > 0 && centimos(valor) <= centimos(p.valor!))

  const submeter = async () => {
    setErro(null)
    if (orgao && !voto) return setErro('Escolha o voto da reunião que decidiu esta etapa.')
    if (!orgao && rejeitar && motivo.trim().length < 3) return setErro('Diga porque rejeita.')
    if (!orgao && !rejeitar && !valorValido) return setErro('O valor aprovado tem de ser maior que zero e não pode passar o pedido.')
    try {
      const r = await decidir.mutateAsync(orgao
        ? { id: p.id, votoId: Number(voto) }
        : rejeitar ? { id: p.id, aprovar: false, motivo: motivo.trim() }
          : { id: p.id, aprovar: true, motivo: motivo.trim() || undefined, valor: podeReduzir && valor !== p.valor ? valor : undefined })
      toast.success(r.estado === 'APROVADO' ? 'Aprovado: era a última etapa.' : r.estado === 'REJEITADO' ? 'Rejeitado.' : 'Etapa decidida: segue para a próxima.')
      aoDecidir?.(r.estado)
      aoFechar()
    } catch (e) {
      setErro(mensagemDe(e))
    }
  }

  return (
    <Dialog open onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{p.etapaNome}</DialogTitle>
          <DialogDescription>
            {PROCESSOS[p.processo].rotulo}: {p.assunto}{p.valor ? ` · ${dinheiro(p.valor)}` : ''} · fluxo «{p.fluxo}», etapa {p.etapa} de {p.totalEtapas}
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <EtapasAprovacao aprovacaoId={p.id} className="rounded-lg border bg-muted/20 p-3" />
          <ErroFormulario mensagem={erro} />
          {orgao ? (
            <div className="grid gap-1.5">
              <label htmlFor="apv-voto" className="text-sm font-medium">Voto da reunião <span className="text-destructive-text">*</span></label>
              <CampoVoto id="apv-voto" valor={voto} aoMudar={setVoto} reunioes={p.orgao ? [p.orgao] : []} igrejaId={p.igrejaId}
                preferir={p.processo === 'ADMISSAO_MEMBRO' ? 'ADMISSAO' : p.processo === 'REMOCAO_MEMBRO' ? 'REMOCAO' : 'FINANCEIRO'} />
              <p className="text-xs text-muted-foreground">Esta etapa decide-a {p.orgao ? ORGAOS[p.orgao] : 'o órgão'}: a decisão é a do voto registado na acta.</p>
            </div>
          ) : (
            <>
              <div role="radiogroup" aria-label="Decisão" className="grid grid-cols-2 gap-2">
                {[{ v: false, r: p.etapaAccao === 'CONFERIR' ? 'Conferir' : p.etapaAccao === 'APRECIAR' ? 'Dar parecer favorável' : 'Aprovar' }, { v: true, r: 'Rejeitar' }].map((o) => (
                  <button key={o.r} type="button" role="radio" aria-checked={rejeitar === o.v} onClick={() => setRejeitar(o.v)}
                    className={cn('alvo rounded-lg border px-3 py-2 text-sm font-medium', rejeitar === o.v ? (o.v ? 'border-destructive bg-tint-destructive text-destructive-text' : 'border-primary bg-primary/10 text-primary') : 'text-muted-foreground')}>
                    {o.r}
                  </button>
                ))}
              </div>
              {!rejeitar && podeReduzir && (
                <div className="grid gap-1.5">
                  <label htmlFor="apv-valor" className="text-sm font-medium">Valor aprovado</label>
                  <CampoDinheiro id="apv-valor" value={valor} onChange={setValor} className="alvo" />
                  <p className="text-xs text-muted-foreground">Pode aprovar menos do que o pedido, nunca mais.</p>
                </div>
              )}
              <div className="grid gap-1.5">
                <label htmlFor="apv-motivo" className="text-sm font-medium">{rejeitar ? 'Motivo' : 'Nota'}{rejeitar && <span className="text-destructive-text"> *</span>}</label>
                <Textarea id="apv-motivo" rows={2} value={motivo} onChange={(e) => setMotivo(e.target.value)} placeholder={rejeitar ? 'ex.: não há saldo no fundo' : 'opcional'} />
              </div>
            </>
          )}
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className={cn('alvo', !orgao && rejeitar && 'bg-destructive text-white hover:bg-destructive/90')} disabled={decidir.isPending} onClick={submeter}>
            {decidir.isPending ? t.comum.aGravar : orgao ? 'Registar a decisão' : rejeitar ? 'Rejeitar' : 'Confirmar'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/**
 * Resumo do processo de um objecto (uma despesa, uma contagem, ...): a etapa em curso, quem decide e, se o utilizador
 * puder, o botão para decidir. Sem processo (igreja sem fluxo, registo antigo) não mostra nada.
 */
export function ResumoAprovacao({ filtro, compacto, rotuloBotao, mostrarProcesso }: {
  filtro: Parameters<typeof useAprovacaoDe>[0]; compacto?: boolean; rotuloBotao?: string; mostrarProcesso?: boolean
}) {
  const q = useAprovacaoDe(filtro)
  const [aberto, setAberto] = useState(false)
  const p = q.data
  if (q.isPending) return <Barra className="h-5 w-48" />
  if (!p) return null
  return (
    <div className={cn('flex flex-wrap items-center gap-x-3 gap-y-1', compacto ? 'text-xs' : 'text-sm')}>
      {mostrarProcesso && <span className="font-medium">{PROCESSOS[p.processo].rotulo}:</span>}
      {p.estado !== 'EM_CURSO' && <Pilula variante={ESTADOS[p.estado].variante}>{ESTADOS[p.estado].rotulo}</Pilula>}
      <LinhaEtapa p={p} className={compacto ? 'text-xs' : undefined} />
      {p.estado === 'EM_CURSO' && (
        <span className="flex min-w-0 items-center gap-1 text-muted-foreground"><Users className="size-3.5 flex-none" aria-hidden /><span className="truncate"><QuemDecide p={p} /></span></span>
      )}
      {p.podeDecidir && (
        <Button size="sm" className="alvo" onClick={() => setAberto(true)}><Gavel className="size-4" />{rotuloBotao ?? 'Decidir'}</Button>
      )}
      {aberto && <DialogoDecidirEtapa p={p} aoFechar={() => setAberto(false)} />}
    </div>
  )
}
