package mz.org.iasd.igreja.models.actividades;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoSantaCeia;

/**
 * Santa Ceia: agendamento (data, hora, local, responsável) e participantes depois de realizada (V39).
 * <p>
 * Tabela {@code actividades.santa_ceia} · rota {@code /v1/actividades/santas-ceias}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param data coluna {@code stc_data} — obrigatório ao criar
 * @param hora Hora (hh:mm)
 * @param local coluna {@code stc_local}
 * @param responsavelMembroId Quem oficia (pastor ou ancião)
 * @param observacoes coluna {@code stc_observacoes}
 * @param homens Participantes: homens (depois de realizada)
 * @param mulheres Participantes: mulheres
 * @param visitantes Participantes: visitantes
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "actividades", nome = "santa_ceia", prefixo = "stc", modulo = "actividades", recurso = "santas-ceias", colunaIgreja = "stc_igr_id")
public record SantaCeia(
        @ColunaBd(value = "stc_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "stc_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "stc_data", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "stc_hora", tipo = Tipo.TEXTO)
        String hora,
        @ColunaBd(value = "stc_local", tipo = Tipo.TEXTO)
        String local,
        @ColunaBd(value = "stc_responsavel_mem_id", tipo = Tipo.INT)
        Integer responsavelMembroId,
        @ColunaBd(value = "stc_observacoes", tipo = Tipo.TEXTO)
        String observacoes,
        @ColunaBd(value = "stc_homens", tipo = Tipo.INT)
        Integer homens,
        @ColunaBd(value = "stc_mulheres", tipo = Tipo.INT)
        Integer mulheres,
        @ColunaBd(value = "stc_visitantes", tipo = Tipo.INT)
        Integer visitantes,
        @ColunaBd(value = "stc_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoSantaCeia estado,
        @ColunaBd(value = "stc_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "stc_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "stc_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "stc_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "stc_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
