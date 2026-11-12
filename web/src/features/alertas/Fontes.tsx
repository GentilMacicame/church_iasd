/**
 * Fontes dos alertas: uma por assunto, montada só para quem pode agir sobre ele (a mesma permissão do botão que
 * resolve o assunto). Usam as consultas dos módulos (mesmas chaves): o que se aprova num ecrã invalida a consulta
 * e o alerta desaparece sozinho. Quem decide é sempre a base de dados; isto só aponta o caminho.
 *
 *  Secretaria   registos de membros por aprovar · menores sem encarregado ou consentimento · cartas de
 *               transferência por emitir · membros a aceitar de outra igreja · mandatos a terminar
 *  Reuniões     actas por aprovar · reuniões já passadas por marcar como realizadas
 *  Tesouraria   saídas por aprovar (não as próprias) · movimentos por confirmar · despesas por decidir (não as
 *               próprias) e por pagar · contagens por conferir · depósito à Missão em falta · depósitos por
 *               confirmar (Associação) · orçamento por aprovar · mês anterior por fechar
 *  Escola Sab.  ofertas por lançar ou diferentes · relatórios prontos a fechar · relatórios em falta ·
 *               relatórios guardados no telemóvel por enviar (ou recusados / em conflito)
 *  Escalas      escalas em rascunho por publicar
 */
import { useEffect, useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  BookOpenCheck, Calculator, CalendarCheck, CalendarDays, ClipboardList, CloudUpload, Coins, FileSignature, Gavel, HandCoins, Landmark,
  Lock, Mail, ReceiptText, ShieldAlert, Target, UserCheck, Users,
} from 'lucide-react'
import { api, dados } from '@/api/cliente'
import { useIgreja, useSessao } from '@/auth/sessao'
import { centimos, data, deCentimos, dinheiro, hojeIso } from '@/lib/formatos'
import { useContagens, useDespesas, useFechos, useMovimentos, useOrcamentos, useRemessas, useRemessasDevidas } from '@/features/tesouraria/api'
import { useTransferencias } from '@/features/secretaria/api'
import { useReunioes } from '@/features/livro/api'
import { usePlanos } from '@/features/escalas/api'
import { rotulos } from '@/i18n/pt-MZ'
import { sabadoActual, trimestreActual, useSabados, useTrimestres } from '@/features/escola-sabatina/api'
import { usePorEnviar } from '@/features/escola-sabatina/offline'
import { limitar, publicar, registarFontes, type Alerta } from './loja'

const MESES = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro']
const nomeMes = (ano: number, mes: number) => `${MESES[mes - 1]} de ${ano}`
const mesAnterior = () => { const [a, m] = hojeIso().split('-').map(Number); return m === 1 ? { ano: a - 1, mes: 12 } : { ano: a, mes: m - 1 } }

/** Publica os alertas de uma fonte sempre que mudam. */
function usePublicar(fonte: string, itens: Alerta[], aCarregar: boolean) {
  const assinatura = itens.map((i) => `${i.chave}|${i.titulo}|${i.detalhe ?? ''}|${i.tom}`).join('\n')
  useEffect(() => {
    publicar(fonte, itens, aCarregar)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fonte, assinatura, aCarregar])
}

/** Vista de relatório da igreja (chave em "inicio": os módulos invalidam-na quando mudam). */
function useVista<T>(caminho: string) {
  const igreja = useIgreja()
  return useQuery({
    queryKey: ['inicio', igreja.id, caminho],
    queryFn: async () => (await dados(api.GET(caminho as '/v1/secretaria/membros-basico', { params: { query: { igrejaId: igreja.id } } }))) as unknown as T[],
  })
}

// ===================================================================== secretaria

function MembrosPorAprovar() {
  const igreja = useIgreja()
  const q = useQuery({
    queryKey: ['membros', igreja.id, 'por-aprovar'],
    queryFn: async () => (await dados(api.GET('/v1/secretaria/membros', { params: { query: { igrejaId: igreja.id, validacao: 'PENDENTE', limite: 50 } } }))).dados as
      { id: number; nome: string; apelido: string; criadoEm?: string }[],
  })
  const itens = limitar((q.data ?? []).map((m): Alerta => ({
    chave: `membro:${m.id}`, modulo: 'Secretaria', icone: UserCheck, tom: 'warning', data: m.criadoEm,
    titulo: `Aprovar o registo de ${m.nome} ${m.apelido}`, detalhe: 'Registo de membro à espera de validação', para: `/membros/${m.id}`,
  })), 8, (n) => ({ chave: 'membro:resto', modulo: 'Secretaria', icone: Users, tom: 'warning', titulo: `E mais ${n} registo(s) por aprovar`, para: '/membros?validacao=PENDENTE' }))
  usePublicar('membros', itens, q.isPending)
  return null
}

function Menores() {
  const q = useVista<{ id: number; nome: string; apelido: string; faltaEncarregado: boolean; faltaConsentimento: boolean }>('/v1/secretaria/menores-pendentes')
  const itens = limitar((q.data ?? []).map((m): Alerta => ({
    chave: `menor:${m.id}`, modulo: 'Secretaria', icone: ShieldAlert, tom: 'warning',
    titulo: `${m.nome} ${m.apelido}: menor sem ${m.faltaEncarregado ? 'encarregado de educação' : 'consentimento'}`,
    detalhe: m.faltaEncarregado && m.faltaConsentimento ? 'Falta o encarregado e o consentimento' : 'Complete a ficha do membro', para: `/membros/${m.id}`,
  })), 5, (n) => ({ chave: 'menor:resto', modulo: 'Secretaria', icone: ShieldAlert, tom: 'warning', titulo: `E mais ${n} menor(es) com a ficha incompleta`, para: '/secretaria/relatorio' }))
  usePublicar('menores', itens, q.isPending)
  return null
}

function Transferencias() {
  const igreja = useIgreja()
  const { pode } = useSessao()
  const q = useTransferencias()
  const itens: Alerta[] = []
  for (const x of q.data ?? []) {
    const daqui = x.origemIgrejaId === igreja.id
    if (daqui && x.estado === 'PEDIDA' && pode('secretaria.transferencia_membro.emitir_carta')) {
      itens.push({ chave: `carta:${x.id}`, modulo: 'Secretaria', icone: FileSignature, tom: 'warning', data: x.dataPedido ?? undefined,
        titulo: `Emitir a carta de transferência de ${x.membro}`, detalhe: `Para ${x.destino ?? x.destinoExterno ?? 'outra igreja'} · exige o voto em 2.ª leitura`,
        para: '/transferencias?aba=saidas' })
    }
    if (x.estado === 'CARTA_EMITIDA' && pode('secretaria.transferencia_membro.aceitar') && (x.destinoIgrejaId === igreja.id || (daqui && !x.destinoIgrejaId))) {
      itens.push({ chave: `aceitar:${x.id}`, modulo: 'Secretaria', icone: Mail, tom: x.expirada ? 'destructive' : 'warning', data: x.cartaEmitidaEm ?? undefined,
        titulo: daqui ? `Registar a aceitação de ${x.membro}` : `Aceitar ${x.membro}, vindo(a) de ${x.origem}`,
        detalhe: x.expirada ? 'A carta já expirou (válida 6 meses)' : `Carta válida até ${data(x.validaAte)}`,
        para: daqui ? '/transferencias?aba=saidas' : '/transferencias?aba=entradas' })
    }
  }
  usePublicar('transferencias', itens, q.isPending)
  return null
}

function Mandatos() {
  const q = useVista<{ id: number; cargo: string; membro: string; fimPrevisto: string }>('/v1/secretaria/mandatos-a-terminar')
  const l = [...(q.data ?? [])].sort((a, b) => a.fimPrevisto.localeCompare(b.fimPrevisto))
  const itens: Alerta[] = l.length ? [{
    chave: 'mandatos', modulo: 'Secretaria', icone: CalendarDays, tom: 'info',
    titulo: l.length === 1 ? `Mandato de ${l[0].membro} (${l[0].cargo}) a terminar` : `${l.length} mandatos a terminar nos próximos 60 dias`,
    detalhe: `O primeiro termina a ${data(l[0].fimPrevisto)} · prepare a eleição`, para: '/conselho',
  }] : []
  usePublicar('mandatos', itens, q.isPending)
  return null
}

// ===================================================================== reuniões

function Reunioes() {
  const q = useReunioes()
  const hoje = hojeIso()
  const itens: Alerta[] = []
  for (const r of q.data ?? []) {
    if (r.endDate) continue
    const quando = `${rotulos.tipoReuniao[r.tipo] ?? 'Reunião'} de ${data(r.data.slice(0, 10))}`
    if (r.estado === 'REALIZADA') {
      itens.push({ chave: `acta:${r.id}`, modulo: 'Reuniões', icone: Gavel, tom: 'warning', data: r.data, titulo: `Aprovar a acta da ${quando.toLowerCase()}`,
        detalhe: 'Depois de aprovada, a acta fecha o registo da reunião', para: `/reunioes/${r.id}` })
    } else if (r.estado === 'CONVOCADA' && r.data.slice(0, 10) < hoje) {
      itens.push({ chave: `realizada:${r.id}`, modulo: 'Reuniões', icone: Gavel, tom: 'info', data: r.data, titulo: `${quando}: marcar como realizada`,
        detalhe: 'A reunião já passou; registe as presenças e as deliberações', para: `/reunioes/${r.id}` })
    }
  }
  usePublicar('reunioes', limitar(itens, 6, (n) => ({ chave: 'reunioes:resto', modulo: 'Reuniões', icone: Gavel, tom: 'info', titulo: `E mais ${n} reunião(ões) por concluir`, para: '/reunioes' })), q.isPending)
  return null
}

// ===================================================================== tesouraria

function MovimentosPendentes() {
  const { pode, usuario } = useSessao()
  const q = useMovimentos({ estado: 'PENDENTE' })
  const itens: Alerta[] = []
  for (const tr of q.data ?? []) {
    if (tr.endDate || tr.estado !== 'PENDENTE') continue
    const saida = tr.tipo === 'SAIDA'
    const aprovada = !!tr.aprovadoPorUsuarioId
    const valor = dinheiro(tr.valorTotal)
    const sobre = tr.descricao ? ` · ${tr.descricao}` : ''
    if (saida && !aprovada && pode('tesouraria.transacao.aprovar') && tr.criadoPor !== usuario?.id) {
      itens.push({ chave: `aprovar:${tr.id}`, modulo: 'Tesouraria', icone: ReceiptText, tom: 'warning', data: tr.dataHora,
        titulo: `Aprovar a saída de ${valor}${sobre}`, detalhe: `Registada a ${data(tr.dataHora.slice(0, 10))} · quem regista não aprova`, para: `/tesouraria/movimentos/${tr.id}` })
    } else if ((!saida || aprovada) && pode('tesouraria.transacao.alterar')) {
      itens.push({ chave: `confirmar:${tr.id}`, modulo: 'Tesouraria', icone: ReceiptText, tom: 'info', data: tr.dataHora,
        titulo: `Confirmar ${saida ? 'a saída' : tr.tipo === 'ENTRADA' ? 'a entrada' : 'a transferência'} de ${valor}${sobre}`,
        detalhe: saida ? 'Já aprovada; confirme quando o dinheiro sair' : 'Confirme para entrar nos saldos', para: `/tesouraria/movimentos/${tr.id}` })
    }
  }
  usePublicar('movimentos', limitar(itens, 10, (n) => ({ chave: 'movimentos:resto', modulo: 'Tesouraria', icone: ReceiptText, tom: 'info', titulo: `E mais ${n} movimento(s) por confirmar ou aprovar`, para: '/tesouraria/movimentos?ver=pendentes' })), q.isPending)
  return null
}

function Despesas() {
  const { pode, usuario } = useSessao()
  const q = useDespesas()
  const itens: Alerta[] = []
  for (const d of q.data ?? []) {
    if (d.endDate) continue
    if (d.estado === 'SUBMETIDA' && pode('tesouraria.despesa.aprovar') && d.solicitadoPorUsuarioId !== usuario?.id) {
      itens.push({ chave: `despesa:${d.id}`, modulo: 'Tesouraria', icone: ClipboardList, tom: 'warning', data: d.criadoEm,
        titulo: `Decidir a despesa ${d.descricao}`, detalhe: `Pedido de ${dinheiro(d.valorSolicitado)} · aprovar, reduzir ou rejeitar`, para: `/tesouraria/despesas?despesa=${d.id}` })
    }
    if (d.estado === 'APROVADA' && pode('tesouraria.transacao.criar')) {
      itens.push({ chave: `pagar:${d.id}`, modulo: 'Tesouraria', icone: HandCoins, tom: 'info', data: d.aprovadoEm ?? d.criadoEm,
        titulo: `Pagar a despesa ${d.descricao}`, detalhe: `Aprovada: ${dinheiro(d.valorAprovado ?? d.valorSolicitado)}`, para: `/tesouraria/despesas?despesa=${d.id}` })
    }
  }
  usePublicar('despesas', limitar(itens, 8, (n) => ({ chave: 'despesas:resto', modulo: 'Tesouraria', icone: ClipboardList, tom: 'warning', titulo: `E mais ${n} despesa(s) por tratar`, para: '/tesouraria/despesas' })), q.isPending)
  return null
}

function Contagens() {
  const q = useContagens()
  const abertas = (q.data ?? []).filter((c) => !c.endDate && c.estado === 'ABERTA').sort((a, b) => a.data.localeCompare(b.data))
  const itens = limitar(abertas.map((c): Alerta => ({
    chave: `contagem:${c.id}`, modulo: 'Tesouraria', icone: Calculator, tom: 'warning', data: c.data,
    titulo: `Conferir a contagem de ${data(c.data)}`, detalhe: `Contado: ${dinheiro(c.totalContado)} · compare com o lançado`, para: '/tesouraria/contagens',
  })), 4, (n) => ({ chave: 'contagem:resto', modulo: 'Tesouraria', icone: Calculator, tom: 'warning', titulo: `E mais ${n} contagem(ns) por conferir`, para: '/tesouraria/contagens' }))
  usePublicar('contagens', itens, q.isPending)
  return null
}

function DepositoEmFalta() {
  const q = useRemessasDevidas()
  const ant = mesAnterior()
  const emFalta = (q.data ?? []).filter((d) => (d.ano < ant.ano || (d.ano === ant.ano && d.mes <= ant.mes)) && centimos(d.emFalta) > 0)
  const meses = [...new Set(emFalta.map((d) => `${d.ano}-${String(d.mes).padStart(2, '0')}`))].sort()
  const itens: Alerta[] = emFalta.length ? [{
    chave: `deposito:${meses.join(',')}`, modulo: 'Tesouraria', icone: Landmark, tom: 'destructive',
    titulo: `Depositar ${dinheiro(deCentimos(emFalta.reduce((s, d) => s + centimos(d.emFalta), 0)))} na conta da Missão`,
    detalhe: meses.length === 1 ? `Em falta de ${nomeMes(Number(meses[0].slice(0, 4)), Number(meses[0].slice(5)))}` : `Em falta de ${meses.length} meses`,
    para: '/tesouraria/remessas',
  }] : []
  usePublicar('deposito', itens, q.isPending)
  return null
}

function DepositosPorConfirmar() {
  const q = useRemessas()
  const itens = (q.data ?? []).filter((r) => !r.endDate && r.estado === 'ENVIADA').map((r): Alerta => ({
    chave: `remessa:${r.id}`, modulo: 'Tesouraria', icone: Landmark, tom: 'warning', data: `${r.ano}-${String(r.mes).padStart(2, '0')}`,
    titulo: `Confirmar a recepção do depósito de ${nomeMes(r.ano, r.mes)}`,
    detalhe: `${dinheiro(deCentimos(r.linhas.reduce((s, l) => s + centimos(l.valor), 0)))} depositados pela igreja`, para: '/tesouraria/remessas',
  }))
  usePublicar('remessas', itens, q.isPending)
  return null
}

function OrcamentoPorAprovar() {
  const q = useOrcamentos()
  const ano = Number(hojeIso().slice(0, 4))
  const itens = (q.data ?? []).filter((o) => !o.endDate && o.estado === 'RASCUNHO' && o.ano >= ano).map((o): Alerta => ({
    chave: `orcamento:${o.id}`, modulo: 'Tesouraria', icone: Target, tom: 'info', data: `${o.ano}`,
    titulo: `Aprovar o orçamento de ${o.ano}`, detalhe: 'Em rascunho · precisa do voto da igreja', para: `/tesouraria/orcamento?ano=${o.ano}`,
  }))
  usePublicar('orcamento', itens, q.isPending)
  return null
}

function MesPorFechar() {
  const q = useFechos()
  const ant = mesAnterior()
  const { desde, ate } = { desde: `${ant.ano}-${String(ant.mes).padStart(2, '0')}-01`, ate: `${ant.ano}-${String(ant.mes).padStart(2, '0')}-${new Date(Date.UTC(ant.ano, ant.mes, 0)).getUTCDate()}` }
  const movs = useMovimentos({ desde, ate })
  const fechado = (q.data ?? []).some((f) => !f.endDate && f.ano === ant.ano && f.mes === ant.mes)
  const teveMovimentos = (movs.data ?? []).some((x) => !x.endDate)
  const itens: Alerta[] = q.isSuccess && movs.isSuccess && !fechado && teveMovimentos ? [{
    chave: `fecho:${ant.ano}-${ant.mes}`, modulo: 'Tesouraria', icone: Lock, tom: 'info', data: desde,
    titulo: `Fechar o mês de ${nomeMes(ant.ano, ant.mes)}`, detalhe: 'Depois de fechado, ninguém lança nem confirma movimentos nesse mês', para: '/tesouraria/fechos',
  }] : []
  usePublicar('fecho', itens, q.isPending || movs.isPending)
  return null
}

// ===================================================================== Escola Sabatina

interface LinhaConferencia { id: number; classe: string; data: string; ofertaRelatorio: string; situacao: string }

function EsOfertas({ lancar, fechar }: { lancar: boolean; fechar: boolean }) {
  const igreja = useIgreja()
  const conf = useQuery({
    queryKey: ['es', igreja.id, 'vista', '/v1/escola-sabatina/conferencia-ofertas', 0],
    queryFn: async () => (await dados(api.GET('/v1/escola-sabatina/conferencia-ofertas', { params: { query: { igrejaId: igreja.id } } }))) as unknown as LinhaConferencia[],
  })
  const abertos = useQuery({
    enabled: fechar,
    queryKey: ['es', igreja.id, 'relatorios-abertos'],
    queryFn: async () => (await dados(api.GET('/v1/escola-sabatina/relatorios-sabado', { params: { query: { igrejaId: igreja.id, estado: 'ABERTO', limite: 200 } } }))).dados as { id: number }[],
  })
  const ids = useMemo(() => new Set((abertos.data ?? []).map((r) => r.id)), [abertos.data])
  const itens: Alerta[] = []
  for (const l of conf.data ?? []) {
    const onde = `${l.classe} · ${data(l.data)}`
    if (lancar && l.situacao === 'Por lançar') {
      itens.push({ chave: `es-lancar:${l.id}`, modulo: 'Escola Sabatina', icone: Coins, tom: 'warning', data: l.data,
        titulo: `Lançar as ofertas da Escola Sabatina (${dinheiro(l.ofertaRelatorio)})`, detalhe: onde, para: `/escola-sabatina/relatorios/${l.id}` })
    } else if (l.situacao === 'Valores diferentes' && (lancar || fechar)) {
      itens.push({ chave: `es-diferente:${l.id}`, modulo: 'Escola Sabatina', icone: Coins, tom: 'destructive', data: l.data,
        titulo: 'Ofertas do relatório diferentes do lançado na tesouraria', detalhe: onde, para: `/escola-sabatina/relatorios/${l.id}` })
    } else if (fechar && ids.has(l.id) && (l.situacao === 'Conferido' || l.situacao === 'Sem oferta')) {
      itens.push({ chave: `es-fechar:${l.id}`, modulo: 'Escola Sabatina', icone: BookOpenCheck, tom: 'info', data: l.data,
        titulo: 'Fechar o relatório do sábado', detalhe: `${onde} · ofertas conferidas`, para: `/escola-sabatina/relatorios/${l.id}` })
    }
  }
  usePublicar('es-ofertas', limitar(itens, 8, (n) => ({ chave: 'es-ofertas:resto', modulo: 'Escola Sabatina', icone: BookOpenCheck, tom: 'info', titulo: `E mais ${n} relatório(s) por tratar`, para: '/escola-sabatina' })),
    conf.isPending || (fechar && abertos.isPending))
  return null
}

function EsEmFalta() {
  const igreja = useIgreja()
  const trimestres = useTrimestres()
  const tr = trimestreActual(trimestres.data ?? [])
  const sabados = useSabados(tr?.id)
  const q = useQuery({
    queryKey: ['es', igreja.id, 'vista', '/v1/escola-sabatina/relatorios-em-falta', 0],
    queryFn: async () => (await dados(api.GET('/v1/escola-sabatina/relatorios-em-falta', { params: { query: { igrejaId: igreja.id } } }))) as unknown as { classe: string; sabado: number; data: string }[],
  })
  // só os do trimestre em curso, um alerta por sábado
  const porSabado = new Map<string, string[]>()
  for (const l of q.data ?? []) {
    if (!tr || l.data < tr.dataInicio || l.data > tr.dataFim) continue
    porSabado.set(l.data, [...(porSabado.get(l.data) ?? []), l.classe])
  }
  const ultimo = sabadoActual(sabados.data ?? [])
  const itens = [...porSabado.entries()].sort((a, b) => b[0].localeCompare(a[0])).slice(0, 4).map(([d, classes]): Alerta => {
    const sb = sabados.data?.find((s) => s.data === d)
    return {
      chave: `es-falta:${d}:${classes.length}`, modulo: 'Escola Sabatina', icone: BookOpenCheck, tom: ultimo?.data === d ? 'warning' : 'info', data: d,
      titulo: classes.length === 1 ? `Relatório do sábado em falta: ${classes[0]}` : `${classes.length} classes sem relatório do sábado`,
      detalhe: `${sb ? `${sb.numero}.º sábado · ` : ''}${data(d)}${classes.length > 1 ? ` · ${classes.slice(0, 3).join(', ')}${classes.length > 3 ? '…' : ''}` : ''}`,
      para: sb && tr ? `/escola-sabatina/sabado?trimestre=${tr.id}&sabado=${sb.id}` : '/escola-sabatina/sabado',
    }
  })
  usePublicar('es-falta', itens, q.isPending)
  return null
}

function EsPorEnviar() {
  const fila = usePorEnviar()
  const itens = fila.map((r): Alerta => ({
    chave: `es-enviar:${r.chave}:${r.erro ? 'e' : ''}${r.conflito ? 'c' : ''}`, modulo: 'Escola Sabatina', icone: CloudUpload,
    tom: r.conflito || r.erro ? 'destructive' : 'warning', data: r.sabadoData,
    titulo: r.conflito ? `Conflito no relatório de ${r.classeNome}` : r.erro ? `Relatório de ${r.classeNome} recusado` : `Relatório de ${r.classeNome} por enviar`,
    detalhe: r.conflito || r.erro ? `${data(r.sabadoData)} · ${r.erro ?? 'outra pessoa alterou-o'}` : `${data(r.sabadoData)} · guardado neste telemóvel; é enviado quando houver rede`,
    para: `/escola-sabatina/sabado/${r.classeTrimestreId}/${r.sabadoId}`,
  }))
  usePublicar('es-enviar', itens, false)
  return null
}

// ===================================================================== escalas

function EscalasPorPublicar() {
  const q = usePlanos()
  const hoje = hojeIso()
  const itens = (q.data ?? []).filter((p) => !p.endDate && !p.publicada && p.dataFim >= hoje).map((p): Alerta => ({
    chave: `escala:${p.id}`, modulo: 'Escalas', icone: CalendarCheck, tom: p.dataInicio <= hoje ? 'warning' : 'info', data: p.dataInicio,
    titulo: `Publicar a escala ${p.titulo}`, detalhe: `${data(p.dataInicio)} – ${data(p.dataFim)} · só publicada é vista e gera os lembretes por SMS`, para: `/escalas/${p.id}`,
  }))
  usePublicar('escalas', itens, q.isPending)
  return null
}

// ===================================================================== todas

/** Monta as fontes que o utilizador pode resolver na igreja escolhida. */
export function Fontes() {
  const { pode } = useSessao()
  const igreja = useIgreja()
  const lista: [string, boolean][] = [
    ['membros', pode('secretaria.membro.validar')],
    ['menores', pode('secretaria.membro.alterar')],
    ['transferencias', pode('secretaria.transferencia_membro.ler') && (pode('secretaria.transferencia_membro.emitir_carta') || pode('secretaria.transferencia_membro.aceitar'))],
    ['mandatos', pode('secretaria.oficial.ler') && pode('secretaria.oficial.criar')],
    ['reunioes', pode('secretaria.reuniao.alterar')],
    ['movimentos', pode('tesouraria.transacao.ler') && (pode('tesouraria.transacao.aprovar') || pode('tesouraria.transacao.alterar'))],
    ['despesas', pode('tesouraria.despesa.ler') && (pode('tesouraria.despesa.aprovar') || pode('tesouraria.transacao.criar'))],
    ['contagens', pode('tesouraria.contagem_numerario.alterar')],
    ['deposito', pode('tesouraria.remessa.criar')],
    ['remessas', pode('tesouraria.remessa.confirmar')],
    ['orcamento', pode('tesouraria.orcamento.aprovar')],
    ['fecho', pode('tesouraria.fecho_periodo.criar') && pode('tesouraria.transacao.ler')],
    ['es-ofertas', pode('escola_sabatina.relatorio_sabado.ler') && (pode('tesouraria.transacao.criar') || pode('escola_sabatina.relatorio_sabado.fechar'))],
    ['es-falta', pode('escola_sabatina.relatorio_sabado.criar')],
    ['es-enviar', pode('escola_sabatina.relatorio_sabado.criar') || pode('escola_sabatina.relatorio_sabado.alterar')],
    ['escalas', pode('actividades.escala_plano.alterar')],
  ]
  const activas = lista.filter(([, v]) => v).map(([n]) => n)
  const chave = `${igreja.id}:${activas.join(',')}`
  useEffect(() => { registarFontes(activas) }, [chave]) // eslint-disable-line react-hooks/exhaustive-deps
  const tem = (n: string) => activas.includes(n)
  return (
    <>
      {tem('membros') && <MembrosPorAprovar />}
      {tem('menores') && <Menores />}
      {tem('transferencias') && <Transferencias />}
      {tem('mandatos') && <Mandatos />}
      {tem('reunioes') && <Reunioes />}
      {tem('movimentos') && <MovimentosPendentes />}
      {tem('despesas') && <Despesas />}
      {tem('contagens') && <Contagens />}
      {tem('deposito') && <DepositoEmFalta />}
      {tem('remessas') && <DepositosPorConfirmar />}
      {tem('orcamento') && <OrcamentoPorAprovar />}
      {tem('fecho') && <MesPorFechar />}
      {tem('es-ofertas') && <EsOfertas lancar={pode('tesouraria.transacao.criar')} fechar={pode('escola_sabatina.relatorio_sabado.fechar')} />}
      {tem('es-falta') && <EsEmFalta />}
      {tem('es-enviar') && <EsPorEnviar />}
      {tem('escalas') && <EscalasPorPublicar />}
    </>
  )
}
