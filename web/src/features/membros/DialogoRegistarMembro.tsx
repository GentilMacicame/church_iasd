/**
 * Registar membro · passo 0, numa janela: "Esta pessoa já está registada?" (F-SEC-01, 4.4; V43/V45)
 *
 * Escreve-se o nome, o apelido e a data de nascimento (obrigatórios) e, se houver, o local de nascimento, o BI e o
 * telemóvel. A procura corre sozinha enquanto se escreve, em todas as igrejas, e reconhece o mesmo nome escrito de
 * outra forma (sem acentos, com y/i, z/s, h mudo, letras dobradas) ou com o nome e o apelido trocados:
 *   - a mesma pessoa (mesmo documento, ou mesmo nome e data)  → "Já está registada": abre-se a ficha ou pede-se a
 *     transferência à igreja onde está; não se regista outra vez (a base de dados também o recusa);
 *   - provavelmente a mesma (nome parecido e mesma data, mesmo telemóvel…) → só continua quem confirmar que é outra;
 *   - só nomes parecidos → aviso; ninguém → segue para a ficha, já com o que se escreveu.
 */
import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ArrowRight, CircleAlert, CircleCheck, Fingerprint, Search, ShieldCheck, UserCheck, UserPlus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Avatar, Pilula } from '@/components/comum/elementos'
import { Barra } from '@/components/comum/estados'
import { CampoData } from '@/components/comum/CampoData'
import { mensagemDe } from '@/api/erros'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos, t } from '@/i18n/pt-MZ'
import { data as dataEcra, hojeIso, idade } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useParecidos, type MembroParecido } from './api'

interface Dados { nome: string; apelido: string; dataNascimento: string; naturalidade: string; numeroIdentificacao: string; telefone: string }
const VAZIO: Dados = { nome: '', apelido: '', dataNascimento: '', naturalidade: '', numeroIdentificacao: '', telefone: '' }
const ISO = /^\d{4}-\d{2}-\d{2}$/

/** A ficha nova, já com o que se escreveu. */
function caminhoDaFicha(d: Dados, confirmado: boolean) {
  const q = new URLSearchParams({ procurado: '1' })
  for (const [k, v] of Object.entries(d)) if (v.trim()) q.set(k, v.trim())
  if (confirmado) q.set('confirmado', '1')
  return `/membros/novo/ficha?${q}`
}

/** Espera que se pare de escrever. */
function useAtrasado<T>(valor: T, ms = 450) {
  const [v, setV] = useState(valor)
  useEffect(() => {
    const id = setTimeout(() => setV(valor), ms)
    return () => clearTimeout(id)
  }, [valor, ms])
  return v
}

export function DialogoRegistarMembro({ aberto, aoFechar }: { aberto: boolean; aoFechar: () => void }) {
  const igreja = useIgreja()
  const navigate = useNavigate()
  const [d, setD] = useState<Dados>(VAZIO)
  const [conferiu, setConferiu] = useState(false)
  const mudar = (k: keyof Dados, v: string) => { setD((x) => ({ ...x, [k]: v })); setConferiu(false) }
  useEffect(() => { if (!aberto) { setD(VAZIO); setConferiu(false) } }, [aberto])

  const faltaNome = d.nome.trim().length < 2
  const faltaApelido = d.apelido.trim().length < 2
  const dataValida = ISO.test(d.dataNascimento) && d.dataNascimento <= hojeIso()
  const pronto = !faltaNome && !faltaApelido && dataValida
  const pedido = useAtrasado(d)
  const emDia = JSON.stringify(pedido) === JSON.stringify(d)
  const q = useParecidos(pedido, pronto && ISO.test(pedido.dataNascimento))
  const lista = pronto && emDia && q.data && !q.isFetching ? q.data : null
  const aProcurar = pronto && (!emDia || q.isFetching)
  const existentes = (lista ?? []).filter((p) => p.existe)
  const provaveis = (lista ?? []).filter((p) => !p.existe && p.pontos >= 70)
  const parecidos = (lista ?? []).filter((p) => !p.existe && p.pontos < 70)
  const podeContinuar = !!lista && existentes.length === 0 && (provaveis.length === 0 || conferiu)

  const continuar = () => { navigate(caminhoDaFicha(d, provaveis.length > 0 && conferiu)); aoFechar() }

  return (
    <Dialog open={aberto} onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="max-h-[94dvh] gap-0 overflow-y-auto p-0 sm:max-w-4xl">
        <div className="grid md:grid-cols-[minmax(0,5fr)_minmax(0,6fr)]">
          {/* os dados da pessoa */}
          <form onSubmit={(e) => { e.preventDefault(); if (podeContinuar) continuar() }} noValidate className="grid content-start gap-4 border-b bg-muted/30 p-5 md:border-r md:border-b-0 sm:p-6">
            <DialogHeader className="text-left">
              <DialogTitle className="flex items-center gap-2"><UserPlus className="size-5 text-primary" />Registar membro</DialogTitle>
              <DialogDescription>Primeiro confirmamos que a pessoa ainda não está registada, em {igreja.nome} ou noutra igreja.</DialogDescription>
            </DialogHeader>
            <div className="grid grid-cols-2 gap-3">
              <Campo id="rm-nome" rotulo="Nome" obrigatorio>
                <Input id="rm-nome" value={d.nome} onChange={(e) => mudar('nome', e.target.value)} autoComplete="off" autoFocus className="alvo" placeholder="ex.: Ana Maria" />
              </Campo>
              <Campo id="rm-apelido" rotulo="Apelido" obrigatorio>
                <Input id="rm-apelido" value={d.apelido} onChange={(e) => mudar('apelido', e.target.value)} autoComplete="off" className="alvo" placeholder="ex.: Cossa" />
              </Campo>
              <Campo id="rm-nasc" rotulo="Data de nascimento" obrigatorio
                erro={d.dataNascimento && ISO.test(d.dataNascimento) && d.dataNascimento > hojeIso() ? 'A data não pode ser no futuro' : undefined}>
                <CampoData id="rm-nasc" value={d.dataNascimento} onChange={(v) => mudar('dataNascimento', v)} className="alvo" />
              </Campo>
              <Campo id="rm-local" rotulo="Local de nascimento">
                <Input id="rm-local" value={d.naturalidade} onChange={(e) => mudar('naturalidade', e.target.value)} className="alvo" placeholder="ex.: Xai-Xai" />
              </Campo>
              <Campo id="rm-doc" rotulo="N.º do BI ou outro documento">
                <Input id="rm-doc" value={d.numeroIdentificacao} onChange={(e) => mudar('numeroIdentificacao', e.target.value)} className="alvo num uppercase placeholder:normal-case" placeholder="ex.: 110100000000A" />
              </Campo>
              <Campo id="rm-tel" rotulo="Telemóvel">
                <Input id="rm-tel" inputMode="tel" value={d.telefone} onChange={(e) => mudar('telefone', e.target.value)} className="alvo num" placeholder="ex.: 84 123 4567" />
              </Campo>
            </div>
            <p className="flex gap-2 rounded-lg border bg-card px-3 py-2 text-xs text-muted-foreground">
              <Fingerprint className="mt-0.5 size-4 flex-none text-primary" />
              O BI e o telemóvel ajudam a reconhecer a mesma pessoa mesmo com o nome escrito de outra forma.
            </p>
          </form>

          {/* o resultado */}
          <div className="grid min-h-[22rem] content-between gap-4 p-5 sm:p-6">
            <div className="grid content-start gap-3" aria-live="polite">
              {!pronto ? (
                <div className="grid gap-3 py-2">
                  <p className="flex items-center gap-2 font-medium"><Search className="size-4 text-muted-foreground" />A procura começa sozinha quando tiver</p>
                  <ul className="grid gap-2 text-sm">
                    {[{ ok: !faltaNome, r: 'o nome' }, { ok: !faltaApelido, r: 'o apelido' }, { ok: dataValida, r: 'a data de nascimento' }].map((x) => (
                      <li key={x.r} className={cn('flex items-center gap-2', x.ok ? 'text-success-text' : 'text-muted-foreground')}>
                        {x.ok ? <CircleCheck className="size-4" /> : <span className="size-4 rounded-full border-2" />}{x.r}
                      </li>
                    ))}
                  </ul>
                  <p className="text-xs text-muted-foreground">Procura em todas as igrejas: pelo nome (também escrito de outra forma ou trocado), a data, o local, o documento e o telemóvel.</p>
                </div>
              ) : aProcurar ? (
                <div className="grid gap-2" aria-busy="true"><p className="text-sm text-muted-foreground">A procurar…</p>{[0, 1].map((i) => <Barra key={i} className="h-16 w-full" />)}</div>
              ) : q.isError ? (
                <p className="rounded-lg border border-destructive/40 bg-tint-destructive p-3 text-sm text-destructive-text">Não foi possível procurar: {mensagemDe(q.error)}</p>
              ) : lista && lista.length === 0 ? (
                <div className="grid justify-items-center gap-2 rounded-xl border border-success/30 bg-tint-success p-6 text-center">
                  <ShieldCheck className="size-8 text-success-text" />
                  <p className="font-semibold">Não há ninguém registado com estes dados</p>
                  <p className="text-sm text-muted-foreground">Pode registar {d.nome.trim()} {d.apelido.trim()}.</p>
                </div>
              ) : (
                <>
                  {existentes.length > 0 && (
                    <Bloco tom="destructive" icone={UserCheck} titulo="Esta pessoa já está registada" texto="Não se regista outra vez: use o registo existente (ou peça a transferência à igreja onde está).">
                      {existentes.map((p, i) => <Resultado key={p.membroId ?? `f${i}`} p={p} aoAbrir={aoFechar} />)}
                    </Bloco>
                  )}
                  {existentes.length === 0 && provaveis.length > 0 && (
                    <Bloco tom="warning" icone={CircleAlert} titulo="Pode ser alguém que já está registado" texto="Abra o registo e confira. Se for a mesma pessoa, use-o.">
                      {provaveis.map((p) => <Resultado key={p.membroId} p={p} aoAbrir={aoFechar} />)}
                      <label className="alvo mt-1 flex items-center gap-2 text-sm font-medium">
                        <input type="checkbox" checked={conferiu} onChange={(e) => setConferiu(e.target.checked)} className="size-4 accent-[var(--primary)]" />
                        Conferi: é outra pessoa
                      </label>
                    </Bloco>
                  )}
                  {existentes.length === 0 && parecidos.length > 0 && (
                    <Bloco tom="neutral" icone={Search} titulo="Nomes parecidos" texto="Não impedem o registo; confira se não é nenhum destes.">
                      {parecidos.map((p) => <Resultado key={p.membroId} p={p} aoAbrir={aoFechar} />)}
                    </Bloco>
                  )}
                </>
              )}
            </div>
            <div className="flex flex-wrap items-center justify-end gap-2 border-t pt-4">
              <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
              <Button type="button" className="alvo" disabled={!podeContinuar} onClick={continuar}>
                Continuar o registo<ArrowRight className="size-4" />
              </Button>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

function Campo({ id, rotulo, obrigatorio, erro, children }: { id: string; rotulo: string; obrigatorio?: boolean; erro?: string; children: React.ReactNode }) {
  return (
    <div className="grid content-start gap-1.5">
      <label htmlFor={id} className="text-sm font-medium">{rotulo}{obrigatorio && <span className="text-destructive-text"> *</span>}</label>
      {children}
      {erro && <p className="text-xs font-medium text-destructive-text">{erro}</p>}
    </div>
  )
}

function Bloco({ tom, icone: I, titulo, texto, children }: { tom: 'destructive' | 'warning' | 'neutral'; icone: typeof Search; titulo: string; texto: string; children: React.ReactNode }) {
  return (
    <section role={tom === 'neutral' ? 'status' : 'alert'}
      className={cn('grid gap-2 rounded-xl border p-3', tom === 'destructive' ? 'border-destructive/40 bg-tint-destructive' : tom === 'warning' ? 'border-warning/40 bg-tint-warning' : 'bg-muted/40')}>
      <div>
        <p className={cn('flex items-center gap-2 font-semibold', tom === 'destructive' ? 'text-destructive-text' : tom === 'warning' ? 'text-warning-text' : '')}><I className="size-4" />{titulo}</p>
        <p className="text-xs text-muted-foreground">{texto}</p>
      </div>
      <ul className="grid gap-2">{children}</ul>
    </section>
  )
}

/** Um registo encontrado: com a ficha (igreja que o utilizador vê) ou só o nome e a igreja (outra igreja). */
function Resultado({ p, aoAbrir }: { p: MembroParecido; aoAbrir: () => void }) {
  const { igrejas } = useSessao()
  const nomeIgreja = p.igreja ?? igrejas.find((i) => i.id === p.igrejaId)?.nome
  const anos = idade(p.dataNascimento)
  const [nome, ...resto] = p.nome.split(' ')
  return (
    <li className="flex gap-3 rounded-lg border bg-card p-3">
      <Avatar id={p.membroId ?? p.igrejaId} nome={nome} apelido={resto.at(-1)} tamanho={36} />
      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
          <p className="truncate font-medium">{p.nome}</p>
          {p.estado && <Pilula variante="secondary">{rotulos.estadoMembro[p.estado]}</Pilula>}
        </div>
        <p className="text-xs text-muted-foreground">
          {[p.dataNascimento && `${dataEcra(p.dataNascimento)}${anos != null ? ` (${anos} anos)` : ''}`, p.numeroIdentificacao, nomeIgreja].filter(Boolean).join(' · ')}
        </p>
        <div className="mt-1.5 flex flex-wrap gap-1">
          {p.motivos.map((m) => <Pilula key={m} variante={p.existe ? 'destructive' : p.pontos >= 70 ? 'warning' : 'secondary'}>{m}</Pilula>)}
        </div>
        {p.membroId == null && <p className="mt-1.5 text-xs text-muted-foreground">Registado(a) noutra igreja: para o(a) ter nesta, peça a transferência.</p>}
      </div>
      {p.membroId != null && (
        <Button asChild size="sm" variant="outline" className="self-start"><Link to={`/membros/${p.membroId}`} onClick={aoAbrir}>Abrir</Link></Button>
      )}
    </li>
  )
}
