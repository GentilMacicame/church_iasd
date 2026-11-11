/**
 * Acta da reunião, para ver, imprimir e guardar em PDF (A4 ao alto). Estrutura formal: identificação da igreja,
 * número, data/hora/local, presidente e secretário(a), presentes e ausentes, ordem de trabalhos, deliberações e
 * votações, votos formais, encerramento e assinaturas. Enquanto a acta não for aprovada leva a marca RASCUNHO.
 * O PDF faz-se pela impressão do navegador ("Guardar como PDF"); a geração no servidor é da Fase 4.
 */
import { quemMeditou } from './Devocional'
import { Marca } from '@/components/layout/Marca'
import { Link, useParams } from 'react-router-dom'
import { ArrowLeft, Printer } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Barra, EstadoErro } from '@/components/comum/estados'
import { useIgreja } from '@/auth/sessao'
import { rotulos } from '@/i18n/pt-MZ'
import { useMembrosBasicos } from '@/features/membros/api'
import { useConselho, useIgrejaDados } from '@/features/conselho/api'
import { useEntidades } from '@/features/tesouraria/api'
import { usePontos, usePresencas, useReuniao, useVotos, type EstadoPonto } from './api'

/** "11 de novembro de 2026" e "quarta-feira", no fuso de Maputo (uma acta leva sempre o ano). */
const dataLonga = (iso: string) => new Date(iso).toLocaleDateString('pt-PT', { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'Africa/Maputo' })
const diaSemana = (iso: string) => new Date(iso).toLocaleDateString('pt-PT', { weekday: 'long', timeZone: 'Africa/Maputo' })
const hora = (iso?: string | null) => (iso ? new Date(iso).toLocaleTimeString('pt-PT', { hour: '2-digit', minute: '2-digit', timeZone: 'Africa/Maputo' }) : '')
const RESULTADO: Record<EstadoPonto, string> = { PENDENTE: 'Pendente', APROVADO: 'Aprovado', REJEITADO: 'Rejeitado', ADIADO: 'Adiado', INFORMATIVO: 'Para informação' }
const ARTIGO: Record<string, string> = {
  JUNTA_DIRECTIVA: 'a Junta Directiva (conselho da igreja)', REUNIAO_REGULAR: 'a Igreja em reunião regular de negócios',
  ASSEMBLEIA_ADMINISTRATIVA: 'a Igreja em assembleia administrativa',
}

export default function PaginaActa() {
  const id = Number(useParams().id)
  const igreja = useIgreja()
  const q = useReuniao(id)
  const presencas = usePresencas(id)
  const pontos = usePontos(id)
  const votos = useVotos()
  const basicos = useMembrosBasicos()
  const conselho = useConselho()
  const igrejaDados = useIgrejaDados()
  const entidades = useEntidades()

  const voltar = <Link to={`/reunioes/${id}`} className="alvo inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" /> Voltar à reunião</Link>
  if (q.isPending || presencas.isPending || pontos.isPending) return <>{voltar}<Barra className="mt-4 h-96 w-full" /></>
  if (q.isError) return <>{voltar}<EstadoErro erro={q.error} aoTentar={() => q.refetch()} className="mt-4" /></>

  const r = q.data
  const nome = (mid?: number | null) => { const m = mid ? basicos.data?.find((x) => x.id === mid) : null; return m ? `${m.nome} ${m.apelido}` : '' }
  const cargoDe = (mid?: number | null) => (conselho.data ?? []).filter((o) => o.membroId === mid && o.estadoMandato !== 'TERMINADO').map((o) => o.cargo).join(', ')
  const activas = (presencas.data ?? []).filter((p) => !p.endDate)
  const presentes = activas.filter((p) => p.presente).sort((a, b) => nome(a.membroId).localeCompare(nome(b.membroId), 'pt'))
  const ausentes = activas.filter((p) => !p.presente).sort((a, b) => nome(a.membroId).localeCompare(nome(b.membroId), 'pt'))
  const listaPontos = (pontos.data ?? []).filter((p) => !p.endDate)
  const daReuniao = (votos.data ?? []).filter((v) => v.reuniaoId === r.id).sort((a, b) => a.numero.localeCompare(b.numero))
  const entidade = entidades.data?.find((e) => e.id === igrejaDados.data?.entidadeId)?.nome
  const aprovada = r.estado === 'ACTA_APROVADA'
  const presidente = nome(r.presididaPorMembroId)
  const secretario = nome(r.secretarioMembroId)
  const nPresentes = presentes.length || r.quorumPresentes || 0
  // V28: abertura com oração, hino e meditação ("A reunião abriu com oração por X, entoou-se o hino ... e Y fez a meditação.")
  const partesAbertura = [
    nome(r.oracaoInicialMembroId) && `com oração por ${nome(r.oracaoInicialMembroId)}`,
    r.hino && `entoou-se o hino «${r.hino}»`,
    quemMeditou(r, nome) && `a meditação foi feita por ${quemMeditou(r, nome)}`,
  ].filter(Boolean) as string[]
  const abertura = partesAbertura.length
    ? `A reunião abriu ${partesAbertura.length > 1 ? partesAbertura.slice(0, -1).join(', ') + ' e ' + partesAbertura[partesAbertura.length - 1] : partesAbertura[0]}.`
    : ''

  return (
    <div className="grid gap-4">
      <div className="flex flex-wrap items-center justify-between gap-3 print:hidden">
        {voltar}
        <div className="flex items-center gap-2">
          <span className="text-sm text-muted-foreground">{aprovada ? 'Acta aprovada' : 'Rascunho: aprove a acta na reunião para a versão final'}</span>
          <Button className="alvo" onClick={() => window.print()}><Printer className="size-4" />Imprimir / guardar PDF</Button>
        </div>
      </div>

      {/* o documento: folha A4 no ecrã e na impressão */}
      <article className="documento-a4 relative mx-auto w-full max-w-[210mm] bg-white px-[16mm] py-[18mm] font-serif text-[11.5pt] leading-relaxed text-neutral-900 shadow-card ring-1 ring-black/5 print:max-w-none print:p-0 print:shadow-none print:ring-0">
        {!aprovada && (
          <span aria-hidden className="pointer-events-none absolute inset-0 flex items-center justify-center overflow-hidden">
            <span className="-rotate-30 text-[90pt] font-bold tracking-widest text-neutral-900/[0.05]">RASCUNHO</span>
          </span>
        )}
        <header className="border-b-2 border-neutral-900 pb-3 text-center">
          <Marca className="mx-auto mb-2 size-16" />
          <p className="text-[10pt] tracking-[0.2em] uppercase">Igreja Adventista do Sétimo Dia</p>
          {entidade && <p className="text-[10pt]">{entidade}</p>}
          <p className="mt-1 text-[15pt] font-bold">{igreja.nome}</p>
        </header>

        <h1 className="mt-6 text-center text-[14pt] font-bold tracking-wide uppercase">Acta{r.numero ? ` n.º ${r.numero}` : ''}</h1>
        <p className="text-center text-[11pt]">{rotulos.tipoReuniao[r.tipo]} · {diaSemana(r.data).replace(/^./, (c) => c.toUpperCase())}, {dataLonga(r.data)}</p>

        <p className="mt-6 text-justify indent-8">
          Aos {dataLonga(r.data)}, pelas {hora(r.data)}, {r.local ? `no ${r.local}, ` : ''}reuniu-se {ARTIGO[r.tipo] ?? rotulos.tipoReuniao[r.tipo].toLowerCase()} da {igreja.nome},
          {presidente ? ` sob a presidência de ${presidente}${cargoDe(r.presididaPorMembroId) ? ` (${cargoDe(r.presididaPorMembroId)})` : ''}` : ''}
          {secretario ? `, servindo de secretário(a) ${secretario}` : ''}, com a presença de {nPresentes} {nPresentes === 1 ? 'membro' : 'membros'}.
        </p>
        {abertura && <p className="mt-3 text-justify indent-8">{abertura}</p>}

        <Seccao titulo="Participantes">
          <div className="grid gap-x-8 gap-y-3 sm:grid-cols-2 print:grid-cols-2">
            <div>
              <p className="font-semibold">Presentes ({presentes.length})</p>
              {presentes.length ? <ol className="mt-1 list-decimal pl-5">{presentes.map((p) => <li key={p.id}>{nome(p.membroId)}{p.funcao ? <span className="text-neutral-600"> — {p.funcao}</span> : null}</li>)}</ol>
                : <p className="text-neutral-600">Não registados.</p>}
            </div>
            <div>
              <p className="font-semibold">Ausentes ({ausentes.length})</p>
              {ausentes.length ? <ol className="mt-1 list-decimal pl-5">{ausentes.map((p) => <li key={p.id}>{nome(p.membroId)}{p.justificacao ? <span className="text-neutral-600"> — {p.justificacao}</span> : <span className="text-neutral-600"> — sem justificação</span>}</li>)}</ol>
                : <p className="text-neutral-600">Nenhum.</p>}
            </div>
          </div>
        </Seccao>

        <Seccao titulo="Ordem de trabalhos">
          {listaPontos.length ? <ol className="list-decimal pl-5">{listaPontos.map((p) => <li key={p.id}>{p.assunto}</li>)}</ol> : <p className="text-neutral-600">Sem pontos registados.</p>}
        </Seccao>

        {listaPontos.length > 0 && (
          <Seccao titulo="Assuntos tratados e deliberações">
            <div className="grid gap-4">
              {listaPontos.map((p, i) => (
                <div key={p.id} className="break-inside-avoid">
                  <p className="font-semibold">Ponto {i + 1}. {p.assunto}</p>
                  {p.detalhes && <p className="mt-1 text-justify whitespace-pre-line">{p.detalhes}</p>}
                  {!p.discutido && p.estado !== 'APROVADO' && p.estado !== 'REJEITADO' && <p className="mt-1 italic text-neutral-600">Não chegou a ser discutido.</p>}
                  {p.votado && (
                    <p className="mt-1">Submetido à votação: <strong>{p.aFavor ?? 0}</strong> a favor, <strong>{p.contra ?? 0}</strong> contra e <strong>{p.abstencoes ?? 0}</strong> {p.abstencoes === 1 ? 'abstenção' : 'abstenções'}.</p>
                  )}
                  {p.deliberacao && <p className="mt-1 text-justify"><span className="font-semibold">Deliberação:</span> {p.deliberacao}</p>}
                  <p className="mt-1 text-[10pt] tracking-wide uppercase">Resultado: {RESULTADO[p.estado]}</p>
                </div>
              ))}
            </div>
          </Seccao>
        )}

        {daReuniao.length > 0 && (
          <Seccao titulo="Votos registados">
            <table className="w-full border-collapse text-[10.5pt]">
              <thead><tr className="border-b border-neutral-900 text-left"><th className="py-1 pr-2">N.º</th><th className="py-1 pr-2">Assunto</th><th className="py-1 pr-2 text-right">Votação</th><th className="py-1">Resultado</th></tr></thead>
              <tbody>
                {daReuniao.map((v) => (
                  <tr key={v.id} className="border-b border-neutral-300">
                    <td className="py-1 pr-2 align-top tabular-nums">{v.numero}</td>
                    <td className="py-1 pr-2 align-top">{v.assunto}{v.leitura === 2 ? ' (2.ª leitura)' : ''}</td>
                    <td className="py-1 pr-2 text-right align-top tabular-nums whitespace-nowrap">{v.aFavor ?? '—'} / {v.contra ?? '—'} / {v.abstencoes ?? '—'}</td>
                    <td className="py-1 align-top">{rotulos.resultadoVoto[v.estado as keyof typeof rotulos.resultadoVoto] ?? v.estado}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Seccao>
        )}

        <Seccao titulo="Encerramento">
          <p className="text-justify indent-8">
            Nada mais havendo a tratar, a reunião foi encerrada{r.encerradaEm ? ` pelas ${hora(r.encerradaEm)}` : ''}{nome(r.oracaoFinalMembroId) ? `, com oração por ${nome(r.oracaoFinalMembroId)}` : ''}.{r.encerramento ? ` ${r.encerramento}` : ''} Para constar, lavrou-se a presente acta que,
            depois de lida e aprovada, vai ser assinada pelo Presidente e pelo(a) Secretário(a).
          </p>
        </Seccao>

        <div className="mt-16 grid grid-cols-2 gap-12 break-inside-avoid">
          {[{ papel: 'O Presidente', quem: presidente, cargo: cargoDe(r.presididaPorMembroId) }, { papel: 'O(A) Secretário(a)', quem: secretario, cargo: cargoDe(r.secretarioMembroId) }].map((a) => (
            <div key={a.papel} className="text-center">
              <p className="text-[10pt] tracking-wide uppercase">{a.papel}</p>
              <div className="mt-14 border-t border-neutral-900" />
              <p className="mt-1 font-semibold">{a.quem || ' '}</p>
              <p className="text-[10pt] text-neutral-600">{a.cargo || ' '}</p>
            </div>
          ))}
        </div>

        <footer className="mt-12 border-t border-neutral-300 pt-2 text-center text-[8.5pt] text-neutral-500">
          {igreja.nome} · Acta{r.numero ? ` n.º ${r.numero}` : ''} · {aprovada ? 'Aprovada' : 'Rascunho'}
        </footer>
      </article>
    </div>
  )
}

function Seccao({ titulo, children }: { titulo: string; children: React.ReactNode }) {
  return (
    <section className="mt-6">
      <h2 className="mb-2 border-b border-neutral-300 pb-1 text-[11pt] font-bold tracking-wide uppercase">{titulo}</h2>
      {children}
    </section>
  )
}
