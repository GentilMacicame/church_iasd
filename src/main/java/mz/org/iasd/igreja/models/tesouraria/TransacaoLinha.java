package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Divisão do valor por fundo e categoria (soma = valor_total).
 * <p>
 * Tabela {@code tesouraria.transacao_linha} · rota {@code /v1/tesouraria/linhas-transacao}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param transacaoId Referência a tesouraria.transacao — obrigatório ao criar
 * @param igrejaId Copiado da transacção (segurança e desempenho) (preenchido pela base de dados)
 * @param fundoId Referência a tesouraria.fundo — obrigatório ao criar
 * @param categoriaId Referência a tesouraria.categoria — obrigatório ao criar
 * @param departamentoIgrejaId Referência a organizacao.igreja_departamento
 * @param actividadeId Referência a actividades.actividade
 * @param valor coluna {@code tli_valor} — obrigatório ao criar, dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param descricao coluna {@code tli_descricao}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "transacao_linha", prefixo = "tli", modulo = "tesouraria", recurso = "linhas-transacao", colunaIgreja = "tli_igr_id")
public record TransacaoLinha(
        @ColunaBd(value = "tli_id", tipo = Tipo.BIGINT, escrita = false, naoNula = true)
        Long id,
        @ColunaBd(value = "tli_tra_id", tipo = Tipo.BIGINT, obrigatoria = true, naoNula = true)
        Long transacaoId,
        @ColunaBd(value = "tli_igr_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "tli_fun_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer fundoId,
        @ColunaBd(value = "tli_cat_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer categoriaId,
        @ColunaBd(value = "tli_ide_id", tipo = Tipo.INT)
        Integer departamentoIgrejaId,
        @ColunaBd(value = "tli_act_id", tipo = Tipo.INT)
        Integer actividadeId,
        @ColunaBd(value = "tli_valor", tipo = Tipo.DINHEIRO, obrigatoria = true, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valor,
        @ColunaBd(value = "tli_descricao", tipo = Tipo.TEXTO)
        String descricao,
        @ColunaBd(value = "tli_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "tli_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "tli_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "tli_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "tli_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "tli_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
