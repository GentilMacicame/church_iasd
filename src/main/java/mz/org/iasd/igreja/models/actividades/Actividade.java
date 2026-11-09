package mz.org.iasd.igreja.models.actividades;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoActividade;

/**
 * Actividades e eventos dos departamentos.
 * <p>
 * Tabela {@code actividades.actividade} · rota {@code /v1/actividades/actividades}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param departamentoIgrejaId Referência a organizacao.igreja_departamento — obrigatório ao criar
 * @param responsavelMembroId Referência a secretaria.membro
 * @param nome coluna {@code act_nome} — obrigatório ao criar
 * @param descricao coluna {@code act_descricao}
 * @param local coluna {@code act_local}
 * @param dataInicio coluna {@code act_data_inicio} — obrigatório ao criar
 * @param dataFim coluna {@code act_data_fim}
 * @param dataHoraLembrete coluna {@code act_data_hora_lembrete}
 * @param valorPrevisto coluna {@code act_valor_previsto} — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "actividades", nome = "actividade", prefixo = "act", modulo = "actividades", recurso = "actividades")
public record Actividade(
        @ColunaBd(value = "act_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "act_ide_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer departamentoIgrejaId,
        @ColunaBd(value = "act_responsavel_mem_id", tipo = Tipo.INT)
        Integer responsavelMembroId,
        @ColunaBd(value = "act_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "act_descricao", tipo = Tipo.TEXTO)
        String descricao,
        @ColunaBd(value = "act_local", tipo = Tipo.TEXTO)
        String local,
        @ColunaBd(value = "act_data_inicio", tipo = Tipo.DATA_HORA, obrigatoria = true, naoNula = true)
        OffsetDateTime dataInicio,
        @ColunaBd(value = "act_data_fim", tipo = Tipo.DATA_HORA)
        OffsetDateTime dataFim,
        @ColunaBd(value = "act_data_hora_lembrete", tipo = Tipo.DATA_HORA)
        OffsetDateTime dataHoraLembrete,
        @ColunaBd(value = "act_valor_previsto", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valorPrevisto,
        @ColunaBd(value = "act_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoActividade estado,
        @ColunaBd(value = "act_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "act_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "act_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "act_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "act_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
