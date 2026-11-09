package mz.org.iasd.igreja.models.escolasabatina;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Inscrição nas classes (histórico); membros e não membros.
 * <p>
 * Tabela {@code escola_sabatina.matricula} · rota {@code /v1/escola-sabatina/matriculas}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param classeId Referência a escola_sabatina.classe — obrigatório ao criar
 * @param membroId Referência a secretaria.membro — obrigatório ao criar
 * @param dataEntrada coluna {@code ema_data_entrada}
 * @param dataSaida coluna {@code ema_data_saida}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "escola_sabatina", nome = "matricula", prefixo = "ema", modulo = "escola-sabatina", recurso = "matriculas")
public record Matricula(
        @ColunaBd(value = "ema_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "ema_ecl_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer classeId,
        @ColunaBd(value = "ema_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "ema_data_entrada", tipo = Tipo.DATA, naoNula = true)
        LocalDate dataEntrada,
        @ColunaBd(value = "ema_data_saida", tipo = Tipo.DATA)
        LocalDate dataSaida,
        @ColunaBd(value = "ema_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "ema_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "ema_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "ema_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "ema_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "ema_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
