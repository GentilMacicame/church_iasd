package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Dinheiro adiantado a um responsável do departamento, que presta contas depois (V50).
 * <p>
 * Tabela {@code tesouraria.adiantamento} · rota {@code /v1/tesouraria/adiantamentos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Copiado do departamento — obrigatório ao criar
 * @param departamentoIgrejaId Referência a organizacao.igreja_departamento — obrigatório ao criar
 * @param membroId Quem recebeu — obrigatório ao criar
 * @param data coluna {@code adt_data} — obrigatório ao criar
 * @param valor coluna {@code adt_valor} — obrigatório ao criar, dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param descricao coluna {@code adt_descricao} — obrigatório ao criar
 * @param dataPrestacao Quando prestou contas
 * @param valorDevolvido O que sobrou e voltou ao departamento — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "adiantamento", prefixo = "adt", modulo = "tesouraria", recurso = "adiantamentos", colunaIgreja = "adt_igr_id")
public record Adiantamento(
        @ColunaBd(value = "adt_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "adt_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "adt_ide_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer departamentoIgrejaId,
        @ColunaBd(value = "adt_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "adt_data", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "adt_valor", tipo = Tipo.DINHEIRO, obrigatoria = true, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valor,
        @ColunaBd(value = "adt_descricao", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String descricao,
        @ColunaBd(value = "adt_data_prestacao", tipo = Tipo.DATA)
        LocalDate dataPrestacao,
        @ColunaBd(value = "adt_valor_devolvido", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valorDevolvido,
        @ColunaBd(value = "adt_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "adt_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "adt_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "adt_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "adt_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "adt_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
