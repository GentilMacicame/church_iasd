/**
 * Na ficha do membro: o seu histórico no livro e o registo de uma entrada (interessado → membro activo) ou de
 * uma saída. Mostram-se só os votos aprovados que servem para o movimento escolhido (ajuda; a base de dados
 * confirma o tipo de reunião, o resultado e a igreja, e aplica o movimento ao membro).
 */
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { BookOpen, LogIn, LogOut } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Cartao, Pilula } from '@/components/comum/elementos'
import { Barra, EstadoErro, EstadoVazio } from '@/components/comum/estados'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { CampoData } from '@/components/comum/CampoData'
import { Seleccao } from '@/components/comum/Seleccao'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { data, hojeIso } from '@/lib/formatos'
import type { Membro } from '@/features/membros/api'
import { ENTRADAS, REUNIOES_QUE_VOTAM, SAIDAS, eEntrada, useCriarMovimento, useMovimentosDoMembro, useReunioes, useVotos, type TipoMovimento } from './api'

const esquema = z.object({
  tipo: z.string().min(1),
  data: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Escreva a data como dd/mm/aaaa').refine((d) => d <= hojeIso(), 'A data não pode ser no futuro'),
  voto: z.string(),
  observacoes: z.string().trim().max(255),
})

function DialogoMovimento({ m, sentido, aberto, aoMudar }: { m: Membro; sentido: 'entrada' | 'saida'; aberto: boolean; aoMudar: (v: boolean) => void }) {
  const igreja = useIgreja()
  const votos = useVotos()
  const reunioes = useReunioes()
  const criar = useCriarMovimento(m.id)
  const [erro, setErro] = useState<string | null>(null)
  const tipos = sentido === 'entrada' ? ENTRADAS : SAIDAS
  const form = useForm({ resolver: zodResolver(esquema), defaultValues: { tipo: tipos[0], data: hojeIso(), voto: '', observacoes: '' } })
  const tipo = form.watch('tipo') as TipoMovimento
  const precisaVoto = tipo !== 'FALECIMENTO'

  const opcoes = useMemo(() => {
    const aceites = REUNIOES_QUE_VOTAM[tipo] ?? []
    const reun = new Map((reunioes.data ?? []).map((r) => [r.id, r]))
    const tipoVoto = sentido === 'entrada' ? 'ADMISSAO' : 'REMOCAO'
    return (votos.data ?? [])
      .filter((v) => v.estado === 'APROVADO' && reun.has(v.reuniaoId) && aceites.includes(reun.get(v.reuniaoId)!.tipo))
      .map((v) => ({ v, r: reun.get(v.reuniaoId)! }))
      .sort((a, b) => Number(b.v.tipo === tipoVoto) - Number(a.v.tipo === tipoVoto) || b.r.data.localeCompare(a.r.data))
  }, [votos.data, reunioes.data, tipo, sentido])

  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    if (precisaVoto && !v.voto) { form.setError('voto', { message: 'Escolha o voto que autoriza este movimento' }); return }
    try {
      await criar.mutateAsync({
        membroId: m.id, igrejaId: igreja.id, tipo: v.tipo as TipoMovimento, data: v.data,
        votoId: precisaVoto ? Number(v.voto) : undefined, observacoes: v.observacoes || undefined,
      })
      toast.success(sentido === 'entrada' ? `${m.nome} ${m.apelido} é agora membro activo.` : 'Saída registada no livro de membros.', {
        description: v.tipo === 'BAPTISMO' || v.tipo === 'REBAPTISMO' ? 'Registe também o baptismo (data, local e pastor) no cartão Baptismo.' : undefined,
      })
      aoMudar(false)
    } catch (e) {
      setErro(aplicarErroApi(form, e))
    }
  })

  return (
    <Dialog open={aberto} onOpenChange={aoMudar}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{sentido === 'entrada' ? 'Registar entrada no livro' : 'Registar saída do livro'}</DialogTitle>
          <DialogDescription>
            {sentido === 'entrada'
              ? `${m.nome} ${m.apelido} passa a membro activo desta igreja, com a data e o modo de entrada.`
              : `${m.nome} ${m.apelido} deixa de ser membro activo e deixa os cargos que tiver.`}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={submeter} noValidate className="grid gap-4">
          <ErroFormulario mensagem={erro} />
          <div className="grid gap-4 sm:grid-cols-2">
            <CampoFormulario rotulo="Movimento">
              {(p) => <Seleccao {...p} {...form.register('tipo')}>{tipos.map((k) => <option key={k} value={k}>{rotulos.modoEntrada[k]}</option>)}</Seleccao>}
            </CampoFormulario>
            <CampoFormulario rotulo="Data" erro={form.formState.errors.data?.message} obrigatorio>
              {(p) => <Controller control={form.control} name="data" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
            </CampoFormulario>
          </div>
          {precisaVoto && (
            <CampoFormulario rotulo="Voto que autoriza" erro={form.formState.errors.voto?.message} obrigatorio
              ajuda={`Só votos aprovados em ${(REUNIOES_QUE_VOTAM[tipo] ?? []).map((r) => rotulos.tipoReuniao[r].toLowerCase()).join(' ou ')}.`}>
              {(p) => votos.isPending || reunioes.isPending ? <Barra className="h-9 w-full" />
                : opcoes.length === 0 ? (
                  <p {...p} className="rounded-lg border border-warning/30 bg-tint-warning px-3 py-2 text-sm text-warning-text">
                    Não há votos aprovados que sirvam. Registe primeiro o voto da igreja em <Link to="/reunioes" className="font-medium underline">Reuniões</Link>.
                  </p>
                ) : (
                  <Seleccao {...p} {...form.register('voto')}>
                    <option value="">Escolher…</option>
                    {opcoes.map(({ v, r }) => <option key={v.id} value={v.id}>{v.numero} · {v.assunto} ({rotulos.tipoReuniao[r.tipo]}, {data(r.data)})</option>)}
                  </Seleccao>
                )}
            </CampoFormulario>
          )}
          <CampoFormulario rotulo="Observações" erro={form.formState.errors.observacoes?.message}>
            {(p) => <Textarea {...p} {...form.register('observacoes')} rows={2} />}
          </CampoFormulario>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => aoMudar(false)}>{t.comum.cancelar}</Button>
            <Button type="submit" disabled={form.formState.isSubmitting} variant={sentido === 'saida' ? 'destructive' : 'default'}>
              {form.formState.isSubmitting ? t.comum.aGravar : sentido === 'entrada' ? 'Registar entrada' : 'Registar saída'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

export function CartaoLivro({ m }: { m: Membro }) {
  const { pode } = useSessao()
  const q = useMovimentosDoMembro(m.id)
  const [aberto, setAberto] = useState<'entrada' | 'saida' | null>(null)
  const podeRegistar = pode('secretaria.movimento_membro.criar')
  const entrada = podeRegistar && m.estado === 'INTERESSADO'
  const saida = podeRegistar && m.estado === 'ACTIVO'
  return (
    <Cartao titulo={t.livro.titulo} descricao="Entradas e saídas com o voto" icone={BookOpen}>
      {q.isPending ? <Barra className="h-10 w-full" />
        : q.isError ? <EstadoErro erro={q.error} aoTentar={() => q.refetch()} />
        : !q.data.length ? (
          <EstadoVazio icone={BookOpen} className="py-4">
            {m.estado === 'INTERESSADO' ? 'Ainda não entrou no livro: falta o voto da igreja e o registo da entrada.' : 'Sem movimentos registados.'}
          </EstadoVazio>
        ) : (
          <ol className="grid gap-3">
            {q.data.map((mv) => (
              <li key={mv.id} className="flex items-center justify-between gap-3 border-l-2 border-primary/30 pl-3">
                <div>
                  <p className="text-sm font-medium">{rotulos.modoEntrada[mv.tipo]}</p>
                  <p className="num text-xs text-muted-foreground">{data(mv.data)}</p>
                </div>
                <Pilula variante={eEntrada(mv.tipo) ? 'success' : 'destructive'}>{eEntrada(mv.tipo) ? 'Entrada' : 'Saída'}</Pilula>
              </li>
            ))}
          </ol>
        )}
      {(entrada || saida) && (
        <Button className="alvo mt-4 w-full" variant={entrada ? 'default' : 'outline'} onClick={() => setAberto(entrada ? 'entrada' : 'saida')}>
          {entrada ? <><LogIn className="size-4" />Registar entrada no livro</> : <><LogOut className="size-4" />Registar saída do livro</>}
        </Button>
      )}
      {aberto && <DialogoMovimento m={m} sentido={aberto} aberto aoMudar={(v) => !v && setAberto(null)} />}
    </Cartao>
  )
}
