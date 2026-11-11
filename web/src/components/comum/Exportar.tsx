/** Botão "Exportar" de um relatório da API: PDF (para enviar ou arquivar) ou CSV (para abrir no Excel). */
import { useState } from 'react'
import { Download, FileSpreadsheet, FileText } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { mensagemDe } from '@/api/erros'
import { descarregarRelatorio } from '@/lib/documentos'

export function Exportar({ caminho, query, nome, rotulo = 'Exportar' }: { caminho: string; query: Record<string, string | number | undefined>; nome: string; rotulo?: string }) {
  const [aCorrer, setACorrer] = useState(false)
  const baixar = async (formato: 'pdf' | 'csv') => {
    setACorrer(true)
    try { await descarregarRelatorio(caminho, query, formato, nome) } catch (e) { toast.error(mensagemDe(e)) } finally { setACorrer(false) }
  }
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="outline" className="alvo print:hidden" disabled={aCorrer}><Download className="size-4" />{aCorrer ? 'A preparar…' : rotulo}</Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onSelect={() => baixar('pdf')}><FileText className="size-4" />PDF</DropdownMenuItem>
        <DropdownMenuItem onSelect={() => baixar('csv')}><FileSpreadsheet className="size-4" />CSV (Excel)</DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
