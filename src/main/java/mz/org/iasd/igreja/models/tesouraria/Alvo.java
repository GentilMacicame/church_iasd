package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Alvos de arrecadação por fundo.
 * <p>
 * Tabela {@code tesouraria.alvo} · rota {@code /v1/tesouraria/alvos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param fundoId Referência a tesouraria.fundo — obrigatório ao criar
 * @param descricao coluna {@code alv_descricao}
 * @param valorAlvo coluna {@code alv_valor_alvo} — obrigatório ao criar, dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param dataInicio coluna {@code alv_data_inicio} — obrigatório ao criar
 * @param dataFim coluna {@code alv_data_fim} — obrigatório ao criar
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "alvo", prefixo = "alv", modulo = "tesouraria", recurso = "alvos", colunaIgreja = "alv_igr_id")
public record Alvo(
        @ColunaBd(value = "alv_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "alv_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "alv_fun_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer fundoId,
        @ColunaBd(value = "alv_descricao", tipo = Tipo.TEXTO)
        String descricao,
        @ColunaBd(value = "alv_valor_alvo", tipo = Tipo.DINHEIRO, obrigatoria = true, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valorAlvo,
        @ColunaBd(value = "alv_data_inicio", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate dataInicio,
        @ColunaBd(value = "alv_data_fim", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate dataFim,
        @ColunaBd(value = "alv_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "alv_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "alv_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "alv_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "alv_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "alv_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
