package mz.org.iasd.igreja.models.actividades;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Material necessário para uma actividade.
 * <p>
 * Tabela {@code actividades.material} · rota {@code /v1/actividades/materiais}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param actividadeId Referência a actividades.actividade — obrigatório ao criar
 * @param descricao coluna {@code mat_descricao} — obrigatório ao criar
 * @param quantidade coluna {@code mat_quantidade}
 * @param precoUnitario coluna {@code mat_preco_unitario} — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "actividades", nome = "material", prefixo = "mat", modulo = "actividades", recurso = "materiais")
public record Material(
        @ColunaBd(value = "mat_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "mat_act_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer actividadeId,
        @ColunaBd(value = "mat_descricao", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String descricao,
        @ColunaBd(value = "mat_quantidade", tipo = Tipo.DECIMAL, naoNula = true)
        BigDecimal quantidade,
        @ColunaBd(value = "mat_preco_unitario", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal precoUnitario,
        @ColunaBd(value = "mat_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "mat_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "mat_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "mat_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "mat_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "mat_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
