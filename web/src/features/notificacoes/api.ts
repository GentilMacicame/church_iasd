/**
 * Notificações (SMS, WhatsApp, e-mail) · a fila nucleo.notificacao: o recibo da contribuição (V42), os lembretes de
 * escala, os comunicados… A tarefa da API envia as pendentes e tenta 5 vezes; à 5.ª falha fica FALHADA.
 * Reenviar = voltar a pô-la PENDENTE, com as tentativas a zero (a chave impede outra mensagem igual).
 */
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, dados, type Esquema } from '@/api/cliente'
import { useIgreja } from '@/auth/sessao'

export type Notificacao = Esquema<'Notificacao'> & { id: number; canal: 'SMS' | 'WHATSAPP' | 'EMAIL'; estado: EstadoNotificacao; mensagem: string; destino: string }
export type EstadoNotificacao = 'PENDENTE' | 'ENVIADA' | 'FALHADA' | 'CANCELADA'

export const ROTULO_ESTADO: Record<EstadoNotificacao, { r: string; v: 'warning' | 'success' | 'destructive' | 'secondary' }> = {
  PENDENTE: { r: 'Por enviar', v: 'warning' }, ENVIADA: { r: 'Enviada', v: 'success' }, FALHADA: { r: 'Falhou', v: 'destructive' }, CANCELADA: { r: 'Cancelada', v: 'secondary' },
}
export const ROTULO_CANAL: Record<string, string> = { SMS: 'SMS', WHATSAPP: 'WhatsApp', EMAIL: 'E-mail' }
/** De onde veio a mensagem (a tabela de origem). */
export const ROTULO_ORIGEM: Record<string, string> = {
  'tesouraria.recibo': 'Recibo da contribuição', 'actividades.escala_dia': 'Lembrete de escala', 'nucleo.comunicado': 'Comunicado',
}

const chave = (igreja: number) => ['notificacoes', igreja] as const

/** As notificações mais recentes da igreja (até 200), com o filtro do estado e do canal. */
export function useNotificacoes(f: { estado?: EstadoNotificacao; canal?: string }) {
  const igreja = useIgreja()
  return useQuery({
    queryKey: [...chave(igreja.id), f],
    queryFn: async () => {
      const r = await dados(api.GET('/v1/nucleo/notificacoes', {
        params: { query: { igrejaId: igreja.id, limite: 200, ordem: '-criadoEm', estado: f.estado, canal: f.canal as never } },
      }))
      return r.dados as Notificacao[]
    },
  })
}

export function useReenviar() {
  const qc = useQueryClient()
  const igreja = useIgreja()
  return useMutation({
    mutationFn: (id: number) => dados(api.PATCH('/v1/nucleo/notificacoes/{id}', {
      params: { path: { id } },
      body: { estado: 'PENDENTE', tentativas: 0, agendadaPara: new Date().toISOString() } as never,
    })),
    onSuccess: () => qc.invalidateQueries({ queryKey: chave(igreja.id) }),
  })
}
