package mz.org.iasd.igreja.models.secretaria;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Censuras (1 a 12 meses): sem cargos nem carta de transferência durante a censura.
 * <p>
 * Tabela {@code secretaria.disciplina} · rota {@code /v1/secretaria/disciplinas}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param membroId Referência a secretaria.membro — obrigatório ao criar
 * @param votoId Referência a secretaria.voto — obrigatório ao criar
 * @param dataInicio coluna {@code dsc_data_inicio} — obrigatório ao criar
 * @param dataFim coluna {@code dsc_data_fim} — obrigatório ao criar
 * @param encarregadoNotificado Obrigatório para menores
 * @param motivo Dado sensível: só secretário, pastor e anciãos
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "secretaria", nome = "disciplina", prefixo = "dsc", modulo = "secretaria", recurso = "disciplinas")
public record Disciplina(
        @ColunaBd(value = "dsc_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "dsc_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "dsc_vot_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer votoId,
        @ColunaBd(value = "dsc_data_inicio", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate dataInicio,
        @ColunaBd(value = "dsc_data_fim", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate dataFim,
        @ColunaBd(value = "dsc_encarregado_notificado", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean encarregadoNotificado,
        @ColunaBd(value = "dsc_motivo", tipo = Tipo.TEXTO)
        String motivo,
        @ColunaBd(value = "dsc_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "dsc_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "dsc_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "dsc_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "dsc_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "dsc_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
