/**
 * Registo da classe (F-ES-02 + F-ES-03), num só formulário, com os campos do quadro: nome, divisão, local,
 * professor/líder (e auxiliar e secretário), alvo de membros, alvo de estudo diário, alvo de filiais, alvo de
 * ofertas por sábado, alvo de baptismos e estado (activa / desactivada) no trimestre.
 * Grava a classe (escola_sabatina.classe) e a sua configuração no trimestre (classe_trimestre).
 */
import { useState } from 'react'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { CampoMembro } from '@/components/comum/EscolherMembro'
import { CampoDinheiro } from '@/components/comum/CampoDinheiro'
import { Seleccao } from '@/components/comum/Seleccao'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import {
  DIVISOES, nomeTrimestre, useAlterarClasse, useCriarClasse, useGravarClasseTrimestre,
  type Classe, type ClasseTrimestre, type Divisao, type Trimestre,
} from './api'

const inteiro = z.coerce.number({ invalid_type_error: 'Escreva um número' }).int('Só números inteiros').min(0, 'Não pode ser negativo').max(9999)
const esquema = z.object({
  nome: z.string().trim().min(1, t.comum.obrigatorio).max(100),
  divisao: z.enum(DIVISOES as [Divisao, ...Divisao[]]),
  localReuniao: z.string().trim().max(150),
  professor: z.number().nullable(),
  auxiliar: z.number().nullable(),
  secretario: z.number().nullable(),
  alvoMembros: inteiro,
  alvoEstudo: z.coerce.number({ invalid_type_error: 'Escreva um número' }).min(0, 'Entre 0 e 100').max(100, 'Entre 0 e 100'),
  alvoFiliais: inteiro,
  alvoOferta: z.string().regex(/^\d+(\.\d{1,2})?$/, 'Valor inválido (ex.: 500,00)'),
  alvoBaptismos: inteiro,
  activa: z.boolean(),
})
type Valores = z.infer<typeof esquema>

function Seccao({ titulo, descricao, children }: { titulo: string; descricao?: string; children: React.ReactNode }) {
  return (
    <fieldset className="grid gap-4 rounded-lg border p-4">
      <legend className="px-1 text-sm font-semibold">{titulo}</legend>
      {descricao && <p className="-mt-2 text-xs text-muted-foreground">{descricao}</p>}
      {children}
    </fieldset>
  )
}

export function DialogoClasse({ classe, ct, trimestre, numero, aoFechar, aoGravar }: {
  classe?: Classe; ct?: ClasseTrimestre; trimestre?: Trimestre; numero?: number
  aoFechar: () => void; aoGravar?: (classeId: number) => void
}) {
  const igreja = useIgreja()
  const { pode } = useSessao()
  const basicos = useMembrosBasicos()
  const criarClasse = useCriarClasse()
  const alterarClasse = useAlterarClasse()
  const gravarCt = useGravarClasseTrimestre()
  const [erro, setErro] = useState<string | null>(null)
  const nomeDe = (id: number) => { const m = basicos.data?.find((x) => x.id === id); return m && `${m.nome} ${m.apelido}` }
  const podeTrimestre = !!trimestre && (ct ? pode('escola_sabatina.classe_trimestre.alterar') : pode('escola_sabatina.classe_trimestre.criar'))
  const form = useForm<Valores>({
    resolver: zodResolver(esquema),
    defaultValues: {
      nome: classe?.nome ?? '', divisao: classe?.divisao ?? 'ADULTOS', localReuniao: classe?.localReuniao ?? '',
      professor: ct?.professorMembroId ?? null, auxiliar: ct?.auxiliarMembroId ?? null, secretario: ct?.secretarioMembroId ?? null,
      alvoMembros: ct?.alvoMembros ?? 0, alvoEstudo: Math.round(Number(ct?.alvoEstudoDiario ?? '1') * 100), alvoFiliais: ct?.alvoFiliais ?? 1,
      alvoOferta: ct?.alvoOfertaSabado ?? '0.00', alvoBaptismos: ct?.alvoBaptismos ?? 0, activa: ct ? ct.estado !== 'INACTIVO' : true,
    },
  })
  const e = form.formState.errors
  const activa = form.watch('activa')

  const submeter = form.handleSubmit(async (v) => {
    setErro(null)
    try {
      let id = classe?.id
      if (!id) {
        id = (await criarClasse.mutateAsync({ igrejaId: igreja.id, nome: v.nome, divisao: v.divisao, localReuniao: v.localReuniao || undefined })).id
      } else if (v.nome !== classe!.nome || v.divisao !== classe!.divisao || (v.localReuniao || '') !== (classe!.localReuniao ?? '')) {
        await alterarClasse.mutateAsync({ id, corpo: { nome: v.nome, divisao: v.divisao, localReuniao: v.localReuniao || undefined } })
      }
      if (trimestre && podeTrimestre) {
        await gravarCt.mutateAsync({
          id: ct?.id,
          corpo: {
            classeId: id, trimestreId: trimestre.id,
            professorMembroId: v.professor ?? undefined, auxiliarMembroId: v.auxiliar ?? undefined, secretarioMembroId: v.secretario ?? undefined,
            alvoMembros: v.alvoMembros, alvoEstudoDiario: (v.alvoEstudo / 100).toFixed(4), alvoFiliais: v.alvoFiliais,
            alvoOfertaSabado: v.alvoOferta, alvoBaptismos: v.alvoBaptismos, estado: v.activa ? 'ACTIVO' : 'INACTIVO',
          } as never,
        })
      }
      toast.success(classe ? 'Classe actualizada.' : 'Classe registada.')
      aoFechar()
      aoGravar?.(id)
    } catch (err) {
      setErro(aplicarErroApi(form, err))
    }
  })

  const membro = (nome: 'professor' | 'auxiliar' | 'secretario', rotulo: string) => (
    <CampoFormulario rotulo={rotulo} erro={e[nome]?.message}>
      {(p) => <Controller control={form.control} name={nome} render={({ field }) => (
        <CampoMembro id={p.id} valor={field.value} aoMudar={field.onChange} nomeDe={nomeDe} estados={['ACTIVO', 'INTERESSADO']} vazio="Ir. ________" />
      )} />}
    </CampoFormulario>
  )
  const numero_ = (nome: 'alvoMembros' | 'alvoEstudo' | 'alvoFiliais' | 'alvoBaptismos', rotulo: string, sufixo?: string) => (
    <CampoFormulario rotulo={rotulo} erro={e[nome]?.message}>
      {(p) => (
        <div className="relative">
          <Input {...p} inputMode="numeric" {...form.register(nome)} className={cn('num text-right', sufixo && 'pr-8')} />
          {sufixo && <span className="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2 text-xs text-muted-foreground">{sufixo}</span>}
        </div>
      )}
    </CampoFormulario>
  )

  return (
    <Dialog open onOpenChange={(x) => !x && aoFechar()}>
      <DialogContent className="max-h-[92dvh] overflow-y-auto sm:max-w-2xl">
        <form onSubmit={submeter} noValidate className="grid gap-5">
          <DialogHeader>
            <DialogTitle>{classe ? `Classe ${numero ? `n.º ${numero} · ` : ''}${classe.nome}` : 'Registar classe'}</DialogTitle>
            <DialogDescription>{trimestre ? `Dados da classe e alvos para o ${nomeTrimestre(trimestre)}.` : 'Dados da classe.'}</DialogDescription>
          </DialogHeader>
          <ErroFormulario mensagem={erro} />

          <Seccao titulo="Classe">
            <div className="grid gap-4 sm:grid-cols-2">
              <CampoFormulario rotulo="Nome do grupo / classe" erro={e.nome?.message} obrigatorio className="sm:col-span-2">
                {(p) => <Input {...p} {...form.register('nome')} placeholder="ex.: Grupo 1 · Classe Esperança" autoFocus={!classe} />}
              </CampoFormulario>
              <CampoFormulario rotulo="Divisão" erro={e.divisao?.message} obrigatorio>
                {(p) => <Seleccao {...p} {...form.register('divisao')}>{DIVISOES.map((d) => <option key={d} value={d}>{rotulos.divisao[d]}</option>)}</Seleccao>}
              </CampoFormulario>
              <CampoFormulario rotulo="Local de reunião" erro={e.localReuniao?.message}>
                {(p) => <Input {...p} {...form.register('localReuniao')} placeholder="ex.: Sala 2" />}
              </CampoFormulario>
            </div>
          </Seccao>

          {trimestre && (
            <fieldset disabled={!podeTrimestre} className="contents">
              <Seccao titulo="Liderança" descricao="Quem dirige a classe neste trimestre">
                <div className="grid gap-4 sm:grid-cols-3">
                  {membro('professor', 'Professor / líder')}
                  {membro('auxiliar', 'Auxiliar')}
                  {membro('secretario', 'Secretário(a)')}
                </div>
              </Seccao>

              <Seccao titulo="Alvos do trimestre" descricao="Servem para a % do alvo e para a pontuação da classe">
                <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
                  {numero_('alvoMembros', 'Alvo de membros')}
                  {numero_('alvoEstudo', 'Alvo de E.D.', '%')}
                  {numero_('alvoFiliais', 'Alvo de filiais')}
                  <CampoFormulario rotulo="Alvo de ofertas por sábado" erro={e.alvoOferta?.message}>
                    {(p) => <Controller control={form.control} name="alvoOferta" render={({ field }) => <CampoDinheiro {...p} value={field.value} onChange={field.onChange} onBlur={field.onBlur} />} />}
                  </CampoFormulario>
                  {numero_('alvoBaptismos', 'Alvo de baptismos')}
                  <div className="grid content-start gap-2">
                    <span className="text-sm font-medium">Estado</span>
                    <div role="radiogroup" aria-label="Estado da classe no trimestre" className="grid grid-cols-2 gap-1 rounded-lg bg-muted p-1">
                      {([[true, 'Activo'], [false, 'Desactivado']] as const).map(([v, r]) => (
                        <button key={r} type="button" role="radio" aria-checked={activa === v} onClick={() => form.setValue('activa', v, { shouldDirty: true })}
                          className={cn('h-8 rounded-md text-sm font-medium transition-colors',
                            activa === v ? (v ? 'bg-card text-success-text shadow-sm' : 'bg-card text-foreground shadow-sm') : 'text-muted-foreground hover:text-foreground')}>
                          {r}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
                {!activa && <p className="text-xs text-muted-foreground">Desactivada: aparece a cinzento e fica fora das médias, da classificação e dos relatórios em falta.</p>}
              </Seccao>
            </fieldset>
          )}

          <DialogFooter>
            <Button type="button" variant="outline" onClick={aoFechar}>{t.comum.cancelar}</Button>
            <Button type="submit" disabled={form.formState.isSubmitting} className="min-w-32">{form.formState.isSubmitting ? t.comum.aGravar : classe ? t.comum.guardar : 'Registar classe'}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
