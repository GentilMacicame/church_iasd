package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;
import mz.org.iasd.igreja.models.tipos.TipoConta;

/**
 * Contas onde o dinheiro está (M-Pesa, banco, caixa).
 * <p>
 * Tabela {@code tesouraria.conta_financeira} · rota {@code /v1/tesouraria/contas}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param tipo coluna {@code cfi_tipo} — obrigatório ao criar
 * @param nome coluna {@code cfi_nome} — obrigatório ao criar
 * @param numero coluna {@code cfi_numero}
 * @param titular coluna {@code cfi_titular}
 * @param banco coluna {@code cfi_banco}
 * @param moeda coluna {@code cfi_moeda}
 * @param saldoInicial coluna {@code cfi_saldo_inicial} — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param dataSaldoInicial Movimentos anteriores a esta data não entram no saldo — obrigatório ao criar
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "conta_financeira", prefixo = "cfi", modulo = "tesouraria", recurso = "contas", colunaIgreja = "cfi_igr_id")
public record ContaFinanceira(
        @ColunaBd(value = "cfi_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "cfi_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "cfi_tipo", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        TipoConta tipo,
        @ColunaBd(value = "cfi_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "cfi_numero", tipo = Tipo.TEXTO)
        String numero,
        @ColunaBd(value = "cfi_titular", tipo = Tipo.TEXTO)
        String titular,
        @ColunaBd(value = "cfi_banco", tipo = Tipo.TEXTO)
        String banco,
        @ColunaBd(value = "cfi_moeda", tipo = Tipo.TEXTO, naoNula = true)
        String moeda,
        @ColunaBd(value = "cfi_saldo_inicial", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal saldoInicial,
        @ColunaBd(value = "cfi_data_saldo_inicial", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate dataSaldoInicial,
        @ColunaBd(value = "cfi_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "cfi_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "cfi_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "cfi_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "cfi_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "cfi_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
