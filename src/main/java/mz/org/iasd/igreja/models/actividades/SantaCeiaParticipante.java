package mz.org.iasd.igreja.models.actividades;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Membro que participou na Santa Ceia, pelo nome, para o relatório de participação (V52).
 * <p>
 * Tabela {@code actividades.santa_ceia_participante} · rota {@code /v1/actividades/participantes-santa-ceia}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param santaCeiaId Referência a actividades.santa_ceia — obrigatório ao criar
 * @param igrejaId Copiado da Santa Ceia — obrigatório ao criar
 * @param membroId Referência a secretaria.membro — obrigatório ao criar
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "actividades", nome = "santa_ceia_participante", prefixo = "scp", modulo = "actividades", recurso = "participantes-santa-ceia", colunaIgreja = "scp_igr_id")
public record SantaCeiaParticipante(
        @ColunaBd(value = "scp_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "scp_stc_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer santaCeiaId,
        @ColunaBd(value = "scp_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "scp_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "scp_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "scp_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "scp_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "scp_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "scp_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "scp_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
