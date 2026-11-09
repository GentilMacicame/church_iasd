package mz.org.iasd.igreja.models.pagamentos;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Detalhe de pagamentos por banco.
 * <p>
 * Tabela {@code pagamentos.pagamento_bancario} · rota {@code /v1/pagamentos/bancarios}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param transacaoId Referência a tesouraria.transacao — obrigatório ao criar
 * @param banco coluna {@code pba_banco}
 * @param nib coluna {@code pba_nib} — obrigatório ao criar
 * @param titular coluna {@code pba_titular} — obrigatório ao criar
 * @param referenciaBancaria coluna {@code pba_referencia_bancaria}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "pagamentos", nome = "pagamento_bancario", prefixo = "pba", modulo = "pagamentos", recurso = "bancarios")
public record PagamentoBancario(
        @ColunaBd(value = "pba_id", tipo = Tipo.BIGINT, escrita = false, naoNula = true)
        Long id,
        @ColunaBd(value = "pba_tra_id", tipo = Tipo.BIGINT, obrigatoria = true, naoNula = true)
        Long transacaoId,
        @ColunaBd(value = "pba_banco", tipo = Tipo.TEXTO)
        String banco,
        @ColunaBd(value = "pba_nib", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nib,
        @ColunaBd(value = "pba_titular", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String titular,
        @ColunaBd(value = "pba_referencia_bancaria", tipo = Tipo.TEXTO)
        String referenciaBancaria,
        @ColunaBd(value = "pba_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "pba_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "pba_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "pba_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "pba_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "pba_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
