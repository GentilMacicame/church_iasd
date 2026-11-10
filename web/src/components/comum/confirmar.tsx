/** Confirmação de operações críticas: diz o objecto e a consequência, e o botão diz a acção. */
import type { ReactNode } from 'react'
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription,
  AlertDialogFooter, AlertDialogHeader, AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { t } from '@/i18n/pt-MZ'

export function DialogoConfirmar({ aberto, aoMudar, titulo, texto, accao, perigo, aoConfirmar, aCorrer }: {
  aberto: boolean
  aoMudar: (v: boolean) => void
  titulo: string
  texto: ReactNode
  accao: string
  perigo?: boolean
  aCorrer?: boolean
  aoConfirmar: () => void
}) {
  return (
    <AlertDialog open={aberto} onOpenChange={aoMudar}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>{titulo}</AlertDialogTitle>
          <AlertDialogDescription className="leading-6">{texto}</AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={aCorrer}>{t.comum.cancelar}</AlertDialogCancel>
          <AlertDialogAction
            disabled={aCorrer}
            onClick={(e) => {
              e.preventDefault()
              aoConfirmar()
            }}
            className={perigo ? 'bg-destructive text-white hover:bg-destructive/90' : undefined}
          >
            {aCorrer ? t.comum.aGravar : accao}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}
