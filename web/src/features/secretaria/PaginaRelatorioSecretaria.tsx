/**
 * Relatório da secretaria (F-SEC-10): o que o secretário envia à Associação/Missão — entradas e saídas do livro de
 * membros mês a mês (baptismos, profissões de fé, transferências, falecimentos, remoções), o número de membros e o
 * que está pendente (menores sem encarregado ou consentimento, cartas por concluir, censuras). Imprime-se.
 */
import { useMemo } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { AlertTriangle, BarChart3, Printer, UserMinus, UserPlus, Users } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Cartao, Indicador, Pilula, Tabela, TituloPagina } from '@/components/comum/elementos'
import { Barra, EstadoErro } from '@/components/comum/estados'
import { Seleccao } from '@/components/comum/Seleccao'
import { CabecalhoDocumento } from '@/components/layout/Marca'
import { useIgreja, useSessao } from '@/auth/sessao'
import { rotulos } from '@/i18n/pt-MZ'
import { data, idade } from '@/lib/formatos'
import { cn } from '@/lib/utils'
import { useMembrosBasicos } from '@/features/membros/api'
import { useCensurasActivas, useMenoresPendentes, useRelatorioMensalSecretaria, useTransferencias, type LinhaRelatorioMensal } from './api'

const MESES = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro']
const COLUNAS: { campo: keyof LinhaRelatorioMensal; r: string; curto: string; entra?: boolean }[] = [
  { campo: 'baptismos', r: 'Baptismos', curto: 'Bapt.', entra: true },
  { campo: 'rebaptismos', r: 'Rebaptismos', curto: 'Rebapt.', entra: true },
  { campo: 'profissoesDeFe', r: 'Profissões de fé', curto: 'Prof. fé', entra: true },
  { campo: 'transferenciasEntrada', r: 'Transferências (entrada)', curto: 'Transf. ent.', entra: true },
  { campo: 'transferenciasSaida', r: 'Transferências (saída)', curto: 'Transf. saída' },
  { campo: 'falecimentos', r: 'Falecimentos', curto: 'Falec.' },
  { campo: 'remocoes', r: 'Remoções', curto: 'Remoç.' },
  { campo: 'desaparecidos', r: 'Desaparecidos', curto: 'Desap.' },
]

export default function PaginaRelatorioSecretaria() {
  const igreja = useIgreja()
  const { pode } = useSessao()
  const rel = useRelatorioMensalSecretaria()
  const membros = useMembrosBasicos()
  const menores = useMenoresPendentes()
  const censuras = useCensurasActivas()
  const transf = useTransferencias()
  const [params, setParams] = useSearchParams()
  const anoActual = new Date().getFullYear()
  const ano = Number(params.get('ano')) || anoActual
  const anos = useMemo(() => [...new Set([anoActual, ...(rel.data ?? []).map((l) => l.ano)])].sort((a, b) => b - a), [rel.data, anoActual])

  const doAno = new Map((rel.data ?? []).filter((l) => l.ano === ano).map((l) => [l.mes, l]))
  const total = (c: keyof LinhaRelatorioMensal) => [...doAno.values()].reduce((s, l) => s + Number(l[c] ?? 0), 0)
  const entradas = COLUNAS.filter((c) => c.entra).reduce((s, c) => s + total(c.campo), 0)
  const saidas = COLUNAS.filter((c) => !c.entra).reduce((s, c) => s + total(c.campo), 0)
  const lista = membros.data ?? []
  const activos = lista.filter((m) => m.estado === 'ACTIVO')
  // membros no início do ano = activos hoje − variação desde 1 de Janeiro desse ano (o estado só muda pelo livro)
  const variacaoDesde = (rel.data ?? []).filter((l) => l.ano >= ano).reduce((s, l) => s + Number(l.variacao), 0)
  const inicioAno = activos.length - variacaoDesde
  const fimAno = inicioAno + entradas - saidas
  const porEstado = Object.entries(lista.reduce<Record<string, number>>((a, m) => ({ ...a, [m.estado]: (a[m.estado] ?? 0) + 1 }), {}))
  const homens = activos.filter((m) => m.sexo === 'M').length, mulheres = activos.filter((m) => m.sexo === 'F').length
  const porConcluir = (transf.data ?? []).filter((x) => x.estado === 'PEDIDA' || x.estado === 'CARTA_EMITIDA')

  if (rel.isPending || membros.isPending) return <Barra className="h-96 w-full" />
  if (rel.isError) return <EstadoErro erro={rel.error} aoTentar={() => rel.refetch()} />

  return (
    <div className="documento-relatorio">
      <TituloPagina icone={BarChart3} titulo="Relatório da secretaria" descricao="Entradas e saídas do livro de membros, para a Associação/Missão"
        accoes={(
          <div className="flex items-center gap-2 print:hidden">
            <Seleccao aria-label="Ano" value={String(ano)} onChange={(e) => setParams({ ano: e.target.value })} className="w-28">
              {anos.map((a) => <option key={a} value={a}>{a}</option>)}
            </Seleccao>
            <Button variant="outline" className="alvo" onClick={() => window.print()}><Printer className="size-4" />Imprimir</Button>
          </div>
        )} />
      <CabecalhoDocumento titulo={`${igreja.nome} — Relatório da secretaria de ${ano}`} linha="Secretaria" className="mb-6 hidden print:flex" />

      <div className="grid gap-6">
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <Indicador rotulo={`Membros a 1 de Janeiro de ${ano}`} valor={String(inicioAno)} icone={Users} nota="calculado pelo livro de membros" />
          <Indicador rotulo="Entradas no ano" valor={entradas ? `+${entradas}` : '0'} icone={UserPlus} tom="success" nota="baptismos, profissões de fé, transferências" />
          <Indicador rotulo="Saídas no ano" valor={saidas ? `−${saidas}` : '0'} icone={UserMinus} tom="destructive" nota="transferências, falecimentos, remoções" />
          <Indicador rotulo={ano === anoActual ? 'Membros activos hoje' : `Membros no fim de ${ano}`} valor={String(ano === anoActual ? activos.length : fimAno)} icone={Users} tom="primary"
            nota={ano === anoActual ? `${homens} homens · ${mulheres} mulheres` : undefined} />
        </div>

        <Cartao titulo={`Movimento do livro de membros em ${ano}`} descricao="Por mês, a partir dos registos do livro" semMargem>
          <Tabela className="text-sm">
            <thead>
              <tr>
                <th className="sm:pl-6">Mês</th>
                {COLUNAS.map((c) => <th key={c.campo} className="num" title={c.r}><span className="hidden 2xl:inline">{c.r}</span><span className="2xl:hidden">{c.curto}</span></th>)}
                <th className="num sm:pr-6">Variação</th>
              </tr>
            </thead>
            <tbody>
              {MESES.map((nome, i) => {
                const l = doAno.get(i + 1)
                const futuro = ano === anoActual && i > new Date().getMonth()
                return (
                  <tr key={nome} className={cn(futuro && 'text-muted-foreground/60')}>
                    <td className="sm:pl-6">{nome}</td>
                    {COLUNAS.map((c) => <td key={c.campo} className="num">{l && Number(l[c.campo]) ? l[c.campo] : <span className="text-muted-foreground/50">·</span>}</td>)}
                    <td className={cn('num font-medium sm:pr-6', l && l.variacao > 0 && 'text-success-text', l && l.variacao < 0 && 'text-destructive-text')}>
                      {l ? (l.variacao > 0 ? `+${l.variacao}` : l.variacao) : <span className="text-muted-foreground/50">·</span>}
                    </td>
                  </tr>
                )
              })}
              <tr className="bg-muted/30 font-semibold">
                <td className="sm:pl-6">Total</td>
                {COLUNAS.map((c) => <td key={c.campo} className="num">{total(c.campo)}</td>)}
                <td className={cn('num sm:pr-6', entradas - saidas > 0 && 'text-success-text', entradas - saidas < 0 && 'text-destructive-text')}>{entradas - saidas > 0 ? '+' : ''}{entradas - saidas}</td>
              </tr>
            </tbody>
          </Tabela>
        </Cartao>

        <div className="grid items-start gap-6 lg:grid-cols-2">
          <Cartao titulo="Membros por estado" descricao="Todos os registos do livro desta igreja" icone={Users} semMargem>
            <Tabela>
              <tbody>
                {porEstado.sort((a, b) => b[1] - a[1]).map(([e, n]) => (
                  <tr key={e}><td className="sm:pl-6">{rotulos.estadoMembroPlural?.[e as never] ?? rotulos.estadoMembro[e as never] ?? e}</td><td className="num font-medium sm:pr-6">{n}</td></tr>
                ))}
              </tbody>
            </Tabela>
          </Cartao>
          <Cartao titulo="Pendentes" descricao="O que a secretaria tem de resolver" icone={AlertTriangle} semMargem>
            <ul className="divide-y text-sm">
              <li className="flex items-center justify-between gap-3 px-4 py-2.5 sm:px-6">
                <span>Transferências por concluir</span>
                {pode('secretaria.transferencia_membro.ler') ? <Link to="/transferencias" className="font-medium text-primary hover:underline">{porConcluir.length}</Link> : <span>—</span>}
              </li>
              <li className="flex items-center justify-between gap-3 px-4 py-2.5 sm:px-6">
                <span>Membros em censura</span>
                {pode('secretaria.disciplina.ler') ? <Link to="/disciplina" className="font-medium text-primary hover:underline">{censuras.data?.length ?? '…'}</Link> : <span>—</span>}
              </li>
              <li className="px-4 py-2.5 sm:px-6">
                <div className="flex items-center justify-between gap-3">
                  <span>Menores sem encarregado ou consentimento</span>
                  <span className="font-medium">{menores.data?.length ?? '…'}</span>
                </div>
                {!!menores.data?.length && (
                  <ul className="mt-2 grid gap-1">
                    {menores.data.slice(0, 8).map((m) => (
                      <li key={m.id} className="flex flex-wrap items-center justify-between gap-2">
                        <Link to={`/membros/${m.id}`} className="hover:underline">{m.nome} {m.apelido} <span className="text-xs text-muted-foreground">({idade(m.dataNascimento)} anos, {data(m.dataNascimento)})</span></Link>
                        <span className="flex gap-1">
                          {m.faltaEncarregado && <Pilula variante="warning">sem encarregado</Pilula>}
                          {m.faltaConsentimento && <Pilula variante="warning">sem consentimento</Pilula>}
                        </span>
                      </li>
                    ))}
                  </ul>
                )}
              </li>
            </ul>
          </Cartao>
        </div>
        <div className="mt-6 hidden grid-cols-2 gap-16 text-center text-sm print:grid">
          <div className="border-t border-black pt-1">O secretário da igreja</div>
          <div className="border-t border-black pt-1">O pastor</div>
        </div>
      </div>
    </div>
  )
}
