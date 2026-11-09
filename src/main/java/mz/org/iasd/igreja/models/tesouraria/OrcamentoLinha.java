package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Valor previsto por categoria.
 * <p>
 * Tabela {@code tesouraria.orcamento_linha} · rota {@code /v1/tesouraria/linhas-orcamento}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param orcamentoId Referência a tesouraria.orcamento — obrigatório ao criar
 * @param categoriaId Referência a tesouraria.categoria — obrigatório ao criar
 * @param valorPrevisto coluna {@code orl_valor_previsto} — obrigatório ao criar, dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "orcamento_linha", prefixo = "orl", modulo = "tesouraria", recurso = "linhas-orcamento")
public record OrcamentoLinha(
        @ColunaBd(value = "orl_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "orl_orc_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer orcamentoId,
        @ColunaBd(value = "orl_cat_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer categoriaId,
        @ColunaBd(value = "orl_valor_previsto", tipo = Tipo.DINHEIRO, obrigatoria = true, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valorPrevisto,
        @ColunaBd(value = "orl_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "orl_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "orl_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "orl_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "orl_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "orl_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
