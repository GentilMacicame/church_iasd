/**
 * Registar ou editar a ficha do membro, por secções. Valida só o formato (Zod); as regras (encarregado
 * para menores, estado só por movimento, quem pode alterar) são da base de dados e as suas mensagens
 * aparecem junto ao campo ou no topo. Ao editar envia só os campos alterados (PATCH).
 */
import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ArrowLeft, Briefcase, Church, IdCard, MapPin, UserPen, UserPlus, Users } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Cartao, TituloPagina } from '@/components/comum/elementos'
import { CampoFormulario, ErroFormulario, aplicarErroApi } from '@/components/comum/formulario'
import { Seleccao } from '@/components/comum/Seleccao'
import { CampoData } from '@/components/comum/CampoData'
import { Barra, EstadoErro } from '@/components/comum/estados'
import { useIgreja } from '@/auth/sessao'
import { PROVINCIAS, rotulos, t } from '@/i18n/pt-MZ'
import { hojeIso, idade } from '@/lib/formatos'
import { useAlterarMembro, useCriarMembro, useMembro, useMembrosBasicos, type Membro } from './api'

const texto = (max: number) => z.string().trim().max(max, `No máximo ${max} caracteres`)
const dataPassada = z.string()
  .refine((d) => d === '' || /^\d{4}-\d{2}-\d{2}$/.test(d), 'Escreva a data como dd/mm/aaaa')
  .refine((d) => !d || d <= hojeIso(), 'A data não pode ser no futuro')

const esquema = z.object({
  nome: texto(100).min(1, t.comum.obrigatorio),
  apelido: texto(100).min(1, t.comum.obrigatorio),
  sexo: z.string(),
  dataNascimento: dataPassada,
  estadoCivil: z.string(),
  tipoIdentificacao: z.string(),
  numeroIdentificacao: texto(30),
  nacionalidade: texto(60),
  naturalidade: texto(150),
  nomePai: texto(150),
  nomeMae: texto(150),
  provincia: texto(60),
  cidadeDistrito: texto(100),
  bairro: texto(100),
  quarteirao: texto(20),
  numeroCasa: texto(20),
  morada: texto(255),
  profissao: texto(100),
  escolaridade: z.string(),
  encarregadoMembroId: z.string(),
  dataEntrada: dataPassada,
  modoEntrada: z.string(),
})
type Valores = z.infer<typeof esquema>

const VAZIO: Valores = {
  nome: '', apelido: '', sexo: '', dataNascimento: '', estadoCivil: '', tipoIdentificacao: '', numeroIdentificacao: '',
  nacionalidade: 'Moçambicana', naturalidade: '', nomePai: '', nomeMae: '', provincia: '', cidadeDistrito: '', bairro: '',
  quarteirao: '', numeroCasa: '', morada: '', profissao: '', escolaridade: '', encarregadoMembroId: '', dataEntrada: '', modoEntrada: '',
}

function paraForm(m: Membro): Valores {
  const v = { ...VAZIO }
  for (const k of Object.keys(VAZIO) as (keyof Valores)[]) {
    const x = (m as Record<string, unknown>)[k]
    v[k] = x == null ? '' : String(x)
  }
  return v
}

/** Valores do formulário → corpo da API: texto vazio é null; o encarregado é um id. */
function paraApi(v: Partial<Valores>): Record<string, unknown> {
  const out: Record<string, unknown> = {}
  for (const [k, x] of Object.entries(v)) {
    const s = typeof x === 'string' ? x.trim() : x
    out[k] = s === '' ? null : k === 'encarregadoMembroId' ? Number(s) : s
  }
  return out
}

function Opcoes({ mapa }: { mapa: Record<string, string> }) {
  return (
    <>
      <option value="">{t.ficha.escolher}</option>
      {Object.entries(mapa).map(([k, r]) => <option key={k} value={k}>{r}</option>)}
    </>
  )
}

export default function PaginaFormMembro() {
  const params = useParams()
  const id = params.id ? Number(params.id) : null
  const igreja = useIgreja()
  const navigate = useNavigate()
  const existente = useMembro(id ?? 0)
  const basicos = useMembrosBasicos()
  const criar = useCriarMembro()
  const alterar = useAlterarMembro(id ?? 0)
  const [erroTopo, setErroTopo] = useState<string | null>(null)

  const form = useForm<Valores>({ resolver: zodResolver(esquema), defaultValues: VAZIO })
  const { register, formState: { errors: e, isSubmitting, dirtyFields } } = form

  useEffect(() => {
    if (id && existente.data) form.reset(paraForm(existente.data))
  }, [id, existente.data, form])

  const nasc = form.watch('dataNascimento')
  const anos = /^\d{4}-\d{2}-\d{2}$/.test(nasc) ? idade(nasc) : null
  const candidatosEncarregado = useMemo(
    () => (basicos.data ?? []).filter((b) => b.id !== id && b.estado === 'ACTIVO').sort((a, b) => `${a.nome} ${a.apelido}`.localeCompare(`${b.nome} ${b.apelido}`, 'pt')),
    [basicos.data, id],
  )

  const submeter = form.handleSubmit(async (v) => {
    setErroTopo(null)
    try {
      if (id) {
        const alterados = Object.fromEntries(Object.keys(dirtyFields).map((k) => [k, v[k as keyof Valores]])) as Partial<Valores>
        if (Object.keys(alterados).length) await alterar.mutateAsync(paraApi(alterados) as never)
        toast.success(t.membros.alterado)
        navigate(`/membros/${id}`)
      } else {
        const m = await criar.mutateAsync({ igrejaId: igreja.id, ...paraApi(v) } as never)
        toast.success(t.membros.criado)
        navigate(`/membros/${m.id}`)
      }
    } catch (err) {
      setErroTopo(aplicarErroApi(form, err))
      window.scrollTo({ top: 0, behavior: 'smooth' })
    }
  })

  const voltarPara = id ? `/membros/${id}` : '/membros'
  const titulo = id ? t.membros.editarTitulo : t.membros.novo

  if (id && existente.isPending) {
    return <div className="grid gap-4" aria-busy="true" aria-label="A carregar"><Barra className="h-8 w-64" /><Barra className="h-64 w-full" /></div>
  }
  if (id && existente.isError) return <EstadoErro erro={existente.error} aoTentar={() => existente.refetch()} />

  const grade = 'grid gap-x-5 gap-y-4 sm:grid-cols-2 lg:grid-cols-3'
  return (
    <form onSubmit={submeter} noValidate>
      <TituloPagina
        antes={
          <Link to={voltarPara} className="alvo mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground">
            <ArrowLeft className="size-4" /> {id && existente.data ? `${existente.data.nome} ${existente.data.apelido}` : t.membros.titulo}
          </Link>
        }
        icone={id ? UserPen : UserPlus}
        titulo={titulo}
        descricao={id ? `Ficha no livro de membros de ${igreja.nome}` : `${igreja.nome} · o registo fica por aprovar pelo secretário`}
      />

      <div className="grid gap-6">
        <ErroFormulario mensagem={erroTopo} />

        <Cartao titulo={t.ficha.identificacao} descricao="Nome, data de nascimento e estado civil" icone={IdCard}>
          <div className={grade}>
            <CampoFormulario rotulo={t.ficha.nome} erro={e.nome?.message} obrigatorio>
              {(p) => <Input {...p} {...register('nome')} autoComplete="given-name" className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.apelido} erro={e.apelido?.message} obrigatorio>
              {(p) => <Input {...p} {...register('apelido')} autoComplete="family-name" className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.sexo} erro={e.sexo?.message}>
              {(p) => <Seleccao {...p} {...register('sexo')}><Opcoes mapa={rotulos.sexo} /></Seleccao>}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.dataNascimento} erro={e.dataNascimento?.message} ajuda={anos != null ? `${anos} anos` : undefined}>
              {(p) => <Controller control={form.control} name="dataNascimento" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.estadoCivil} erro={e.estadoCivil?.message}>
              {(p) => <Seleccao {...p} {...register('estadoCivil')}><Opcoes mapa={rotulos.estadoCivil} /></Seleccao>}
            </CampoFormulario>
          </div>
        </Cartao>

        <Cartao titulo={t.ficha.documento} descricao="Documento de identificação e onde nasceu" icone={IdCard}>
          <div className={grade}>
            <CampoFormulario rotulo={t.ficha.tipoIdentificacao} erro={e.tipoIdentificacao?.message}>
              {(p) => <Seleccao {...p} {...register('tipoIdentificacao')}><Opcoes mapa={rotulos.tipoIdentificacao} /></Seleccao>}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.numeroIdentificacao} erro={e.numeroIdentificacao?.message}>
              {(p) => <Input {...p} {...register('numeroIdentificacao')} autoComplete="off" className="alvo num uppercase" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.nacionalidade} erro={e.nacionalidade?.message}>
              {(p) => <Input {...p} {...register('nacionalidade')} className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.naturalidade} erro={e.naturalidade?.message} className="sm:col-span-2 lg:col-span-1">
              {(p) => <Input {...p} {...register('naturalidade')} placeholder="ex.: Xai-Xai, Gaza" className="alvo" />}
            </CampoFormulario>
          </div>
        </Cartao>

        <Cartao titulo={t.ficha.filiacao} descricao="Nomes do pai e da mãe" icone={Users}>
          <div className="grid gap-x-5 gap-y-4 sm:grid-cols-2">
            <CampoFormulario rotulo={t.ficha.nomePai} erro={e.nomePai?.message}>
              {(p) => <Input {...p} {...register('nomePai')} className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.nomeMae} erro={e.nomeMae?.message}>
              {(p) => <Input {...p} {...register('nomeMae')} className="alvo" />}
            </CampoFormulario>
          </div>
        </Cartao>

        <Cartao titulo={t.ficha.moradaTitulo} descricao="Onde vive: permite encontrar o membro e fazer relatórios por bairro" icone={MapPin}>
          <div className={grade}>
            <CampoFormulario rotulo={t.ficha.provincia} erro={e.provincia?.message}>
              {(p) => (
                <Seleccao {...p} {...register('provincia')}>
                  <option value="">{t.ficha.escolher}</option>
                  {PROVINCIAS.map((pr) => <option key={pr} value={pr}>{pr}</option>)}
                </Seleccao>
              )}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.cidadeDistrito} erro={e.cidadeDistrito?.message}>
              {(p) => <Input {...p} {...register('cidadeDistrito')} className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.bairro} erro={e.bairro?.message}>
              {(p) => <Input {...p} {...register('bairro')} className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.quarteirao} erro={e.quarteirao?.message}>
              {(p) => <Input {...p} {...register('quarteirao')} inputMode="numeric" className="alvo num" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.numeroCasa} erro={e.numeroCasa?.message}>
              {(p) => <Input {...p} {...register('numeroCasa')} className="alvo num" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.morada} erro={e.morada?.message} ajuda="Como chegar: perto de quê, rua, avenida.">
              {(p) => <Input {...p} {...register('morada')} className="alvo" />}
            </CampoFormulario>
          </div>
        </Cartao>

        <Cartao titulo={t.ficha.vida} descricao="Profissão, escolaridade e encarregado de educação" icone={Briefcase}>
          <div className={grade}>
            <CampoFormulario rotulo={t.ficha.profissao} erro={e.profissao?.message}>
              {(p) => <Input {...p} {...register('profissao')} className="alvo" />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.escolaridade} erro={e.escolaridade?.message}>
              {(p) => <Seleccao {...p} {...register('escolaridade')}><Opcoes mapa={rotulos.escolaridade} /></Seleccao>}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.encarregado} erro={e.encarregadoMembroId?.message}
              ajuda={anos != null && anos < 18 ? `${t.ficha.encarregadoAjuda} Este membro tem ${anos} anos.` : t.ficha.encarregadoAjuda}>
              {(p) => (
                <Seleccao {...p} {...register('encarregadoMembroId')} disabled={basicos.isPending}>
                  <option value="">{basicos.isPending ? 'A carregar…' : t.ficha.nenhum}</option>
                  {candidatosEncarregado.map((b) => <option key={b.id} value={b.id}>{b.nome} {b.apelido}</option>)}
                </Seleccao>
              )}
            </CampoFormulario>
          </div>
        </Cartao>

        <Cartao titulo={t.ficha.igreja} descricao="Como e quando entrou nesta igreja" icone={Church}>
          <div className={grade}>
            <CampoFormulario rotulo={t.ficha.dataEntrada} erro={e.dataEntrada?.message} ajuda="Data do voto de admissão nesta igreja.">
              {(p) => <Controller control={form.control} name="dataEntrada" render={({ field }) => <CampoData {...p} {...field} className="alvo" />} />}
            </CampoFormulario>
            <CampoFormulario rotulo={t.ficha.modoEntrada} erro={e.modoEntrada?.message}>
              {(p) => (
                <Seleccao {...p} {...register('modoEntrada')}>
                  <option value="">{t.ficha.escolher}</option>
                  {(['BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE', 'TRANSFERENCIA_ENTRADA'] as const).map((k) => <option key={k} value={k}>{rotulos.modoEntrada[k]}</option>)}
                </Seleccao>
              )}
            </CampoFormulario>
          </div>
        </Cartao>

        <div className="sticky bottom-0 -mx-4 flex justify-end gap-2 border-t bg-background/95 px-4 py-3 backdrop-blur sm:static sm:mx-0 sm:border-0 sm:bg-transparent sm:p-0 sm:backdrop-blur-none">
          <Button asChild variant="outline" className="alvo"><Link to={voltarPara}>{t.comum.cancelar}</Link></Button>
          <Button type="submit" disabled={isSubmitting} className="alvo min-w-32">{isSubmitting ? t.comum.aGravar : id ? t.comum.guardar : t.membros.registar}</Button>
        </div>
      </div>
    </form>
  )
}
