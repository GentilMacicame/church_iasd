/**
 * Registar membro · passo 0, numa janela: procurar antes de registar (F-SEC-01, 4.4; V43/V45).
 * Nome, apelido e data de nascimento (obrigatórios), o telemóvel e, se houver, o BI e o local de nascimento. A procura
 * corre sozinha em todas as igrejas (nome como se ouve e trocado, data, documento, telemóvel):
 *   - a mesma pessoa (mesmo documento, ou mesmo nome e data) → não se regista outra vez (a base de dados também recusa);
 *   - provavelmente a mesma → só continua quem confirmar que é outra; nomes parecidos → aviso; ninguém → segue.
 */
import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ArrowRight, CircleAlert, CircleCheck, Loader2, Plus, UserCheck } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { CampoData } from '@/components/comum/CampoData'
import { mensagemDe } from '@/api/erros'
import { useSessao } from '@/auth/sessao'
import { t } from '@/i18n/pt-MZ'
import { data as dataEcra, hojeIso } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useParecidos, type MembroParecido } from './api'

interface Dados { nome: string; apelido: string; dataNascimento: string; naturalidade: string; numeroIdentificacao: string; telefone: string }
const VAZIO: Dados = { nome: '', apelido: '', dataNascimento: '', naturalidade: '', numeroIdentificacao: '', telefone: '' }
const ISO = /^\d{4}-\d{2}-\d{2}$/

function caminhoDaFicha(d: Dados, confirmado: boolean) {
  const q = new URLSearchParams({ procurado: '1' })
  for (const [k, v] of Object.entries(d)) if (v.trim()) q.set(k, v.trim())
  if (confirmado) q.set('confirmado', '1')
  return `/membros/novo/ficha?${q}`
}

function useAtrasado<T>(valor: T, ms = 450) {
  const [v, setV] = useState(valor)
  useEffect(() => {
    const id = setTimeout(() => setV(valor), ms)
    return () => clearTimeout(id)
  }, [valor, ms])
  return v
}

export function DialogoRegistarMembro({ aberto, aoFechar }: { aberto: boolean; aoFechar: () => void }) {
  const navigate = useNavigate()
  const [d, setD] = useState<Dados>(VAZIO)
  const [mais, setMais] = useState(false)
  const [conferiu, setConferiu] = useState(false)
  const mudar = (k: keyof Dados, v: string) => { setD((x) => ({ ...x, [k]: v })); setConferiu(false) }
  useEffect(() => { if (!aberto) { setD(VAZIO); setMais(false); setConferiu(false) } }, [aberto])

  const futura = ISO.test(d.dataNascimento) && d.dataNascimento > hojeIso()
  const pronto = d.nome.trim().length >= 2 && d.apelido.trim().length >= 2 && ISO.test(d.dataNascimento) && !futura
  const pedido = useAtrasado(d)
  const emDia = JSON.stringify(pedido) === JSON.stringify(d)
  const q = useParecidos(pedido, pronto && ISO.test(pedido.dataNascimento))
  const lista = pronto && emDia && q.data && !q.isFetching ? q.data : null
  const existentes = (lista ?? []).filter((p) => p.existe)
  const provaveis = (lista ?? []).filter((p) => !p.existe && p.pontos >= 70)
  const parecidos = (lista ?? []).filter((p) => !p.existe && p.pontos < 70)
  const podeContinuar = !!lista && existentes.length === 0 && (provaveis.length === 0 || conferiu)
  // sem aoFechar(): fechar mexe no endereço da lista e desfazia a navegação para a ficha
  const continuar = () => navigate(caminhoDaFicha(d, provaveis.length > 0 && conferiu))

  return (
    <Dialog open={aberto} onOpenChange={(v) => !v && aoFechar()}>
      <DialogContent className="max-h-[94dvh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Registar membro</DialogTitle>
          <DialogDescription>Procure primeiro, para não registar a mesma pessoa duas vezes.</DialogDescription>
        </DialogHeader>

        <form onSubmit={(e) => { e.preventDefault(); if (podeContinuar) continuar() }} noValidate className="grid grid-cols-2 gap-3">
          <Campo id="rm-nome" rotulo="Nome" obrigatorio>
            <Input id="rm-nome" value={d.nome} onChange={(e) => mudar('nome', e.target.value)} autoComplete="off" autoFocus className="alvo" />
          </Campo>
          <Campo id="rm-apelido" rotulo="Apelido" obrigatorio>
            <Input id="rm-apelido" value={d.apelido} onChange={(e) => mudar('apelido', e.target.value)} autoComplete="off" className="alvo" />
          </Campo>
          <Campo id="rm-nasc" rotulo="Data de nascimento" obrigatorio erro={futura ? 'Não pode ser no futuro' : undefined}>
            <CampoData id="rm-nasc" value={d.dataNascimento} onChange={(v) => mudar('dataNascimento', v)} className="alvo" />
          </Campo>
          <Campo id="rm-tel" rotulo="Telemóvel">
            <Input id="rm-tel" inputMode="tel" value={d.telefone} onChange={(e) => mudar('telefone', e.target.value)} className="alvo num" placeholder="84 123 4567" />
          </Campo>
          {mais ? (
            <>
              <Campo id="rm-doc" rotulo="BI ou outro documento">
                <Input id="rm-doc" value={d.numeroIdentificacao} onChange={(e) => mudar('numeroIdentificacao', e.target.value)} className="alvo num uppercase" />
              </Campo>
              <Campo id="rm-local" rotulo="Local de nascimento">
                <Input id="rm-local" value={d.naturalidade} onChange={(e) => mudar('naturalidade', e.target.value)} className="alvo" />
              </Campo>
            </>
          ) : (
            <button type="button" onClick={() => setMais(true)} className="alvo col-span-2 inline-flex items-center gap-1.5 justify-self-start text-sm font-medium text-primary hover:underline">
              <Plus className="size-4" />BI e local de nascimento
            </button>
          )}
        </form>

        {/* o resultado da procura */}
        <div aria-live="polite" className="min-h-10 border-t pt-3 text-sm">
          {!pronto ? <p className="text-muted-foreground">Escreva o nome, o apelido e a data de nascimento.</p>
            : !lista && !q.isError ? <p className="flex items-center gap-2 text-muted-foreground"><Loader2 className="size-4 animate-spin" />A procurar…</p>
            : q.isError ? <p className="text-destructive-text">Não foi possível procurar: {mensagemDe(q.error)}</p>
            : lista!.length === 0 ? <p className="flex items-center gap-2 font-medium text-success-text"><CircleCheck className="size-4" />Ninguém registado com estes dados.</p>
            : (
              <div className="grid gap-3">
                {existentes.length > 0 && <Grupo tom="destructive" titulo="Já está registado(a)" lista={existentes} aoAbrir={aoFechar} />}
                {existentes.length === 0 && provaveis.length > 0 && (
                  <>
                    <Grupo tom="warning" titulo="Pode já estar registado(a)" lista={provaveis} aoAbrir={aoFechar} />
                    <label className="alvo flex items-center gap-2 font-medium">
                      <input type="checkbox" checked={conferiu} onChange={(e) => setConferiu(e.target.checked)} className="size-4 accent-[var(--primary)]" />
                      Conferi: é outra pessoa
                    </label>
                  </>
                )}
                {existentes.length === 0 && parecidos.length > 0 && <Grupo tom="neutral" titulo="Nomes parecidos" lista={parecidos} aoAbrir={aoFechar} />}
              </div>
            )}
        </div>

        <DialogFooter>
          <Button type="button" variant="outline" className="alvo" onClick={aoFechar}>{t.comum.cancelar}</Button>
          <Button type="button" className="alvo" disabled={!podeContinuar} onClick={continuar}>Continuar<ArrowRight className="size-4" /></Button>
        </DialogFooter>
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

/** Os registos encontrados, numa lista compacta: nome, nascimento, igreja, o motivo principal e "Abrir". */
function Grupo({ tom, titulo, lista, aoAbrir }: { tom: 'destructive' | 'warning' | 'neutral'; titulo: string; lista: MembroParecido[]; aoAbrir: () => void }) {
  const { igrejas } = useSessao()
  const I = tom === 'neutral' ? CircleAlert : UserCheck
  return (
    <section className={cn('rounded-lg border', tom === 'destructive' ? 'border-destructive/40 bg-tint-destructive' : tom === 'warning' ? 'border-warning/40 bg-tint-warning' : 'bg-muted/40')}>
      <p className={cn('flex items-center gap-2 px-3 pt-2 font-semibold', tom === 'destructive' ? 'text-destructive-text' : tom === 'warning' ? 'text-warning-text' : 'text-muted-foreground')}>
        <I className="size-4" />{titulo}
      </p>
      <ul className="divide-y divide-black/5 px-3 pb-1">
        {lista.map((p, i) => (
          <li key={p.membroId ?? `f${i}`} className="flex items-center gap-3 py-2">
            <div className="min-w-0 flex-1">
              <p className="truncate font-medium">{p.nome}</p>
              <p className="truncate text-xs text-muted-foreground">
                {[p.dataNascimento && dataEcra(p.dataNascimento), p.igreja ?? igrejas.find((x) => x.id === p.igrejaId)?.nome, p.motivos[0]].filter(Boolean).join(' · ')}
              </p>
            </div>
            {p.membroId != null
              ? <Button asChild size="sm" variant="outline"><Link to={`/membros/${p.membroId}`} onClick={aoAbrir}>Abrir</Link></Button>
              : <span className="text-xs text-muted-foreground">noutra igreja</span>}
          </li>
        ))}
      </ul>
    </section>
  )
}
