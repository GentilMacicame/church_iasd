/**
 * Escolher o voto da igreja que autoriza um acto (carta de transferência, censura, orçamento, ...), com pesquisa.
 * Mostra só os votos aprovados nas reuniões que servem (e da 2.ª leitura, quando o acto o exige); é uma ajuda: quem
 * decide se o voto serve é a base de dados (secretaria.fn_voto_valido), que explica o motivo se o recusar.
 */
import { Link } from 'react-router-dom'
import { CampoEscolha } from '@/components/comum/CampoEscolha'
import { Barra } from '@/components/comum/estados'
import { rotulos } from '@/i18n/pt-MZ'
import { data } from '@/lib/formatos'
import { useReunioes, useVotos, type TipoReuniao, type TipoVoto } from './api'

export function CampoVoto({ id, valor, aoMudar, reunioes, segundaLeitura, preferir, igrejaId }: {
  id?: string
  valor: string
  aoMudar: (v: string) => void
  /** tipos de reunião em que o voto tem de ter sido tomado */
  reunioes: TipoReuniao[]
  /** só votos da 2.ª leitura (transferências) */
  segundaLeitura?: boolean
  /** tipo de voto a mostrar primeiro */
  preferir?: TipoVoto
  /** só votos de reuniões desta igreja (por defeito, todas as visíveis) */
  igrejaId?: number
}) {
  const votos = useVotos()
  const reus = useReunioes()
  if (votos.isPending || reus.isPending) return <Barra className="h-9 w-full" />
  const porId = new Map((reus.data ?? []).map((r) => [r.id, r]))
  const servem = (votos.data ?? [])
    .map((v) => ({ v, r: porId.get(v.reuniaoId) }))
    .filter((x) => x.r && !x.v.endDate && x.v.estado === 'APROVADO' && reunioes.includes(x.r.tipo)
      && (!segundaLeitura || x.v.leitura === 2) && (igrejaId == null || x.r.igrejaId === igrejaId))
    .sort((a, b) => Number(b.v.tipo === preferir) - Number(a.v.tipo === preferir) || b.r!.data.localeCompare(a.r!.data))
  if (!servem.length) {
    return (
      <p className="rounded-md border border-dashed px-3 py-2 text-sm text-muted-foreground">
        Não há votos aprovados que sirvam{segundaLeitura ? ' (2.ª leitura)' : ''} em {reunioes.map((r) => rotulos.tipoReuniao[r].toLowerCase()).join(' ou ')}.
        {' '}Registe primeiro o voto em <Link to="/reunioes" className="font-medium text-primary underline">Reuniões</Link>.
      </p>
    )
  }
  return (
    <CampoEscolha id={id} valor={valor} aoMudar={aoMudar} vazio="Escolher o voto…" pesquisar="Pesquisar pelo n.º ou assunto…"
      opcoes={servem.map(({ v, r }) => ({
        valor: String(v.id),
        rotulo: `n.º ${v.numero} · ${v.assunto}`,
        detalhe: `${rotulos.tipoReuniao[r!.tipo]} de ${data(r!.data)}${v.leitura === 2 ? ' · 2.ª leitura' : ''}`,
      }))} />
  )
}
