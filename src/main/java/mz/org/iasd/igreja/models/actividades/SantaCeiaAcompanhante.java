package mz.org.iasd.igreja.models.actividades;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Quem acompanha o oficiante na Santa Ceia: os diáconos e as diaconisas (V51).
 * <p>
 * Tabela {@code actividades.santa_ceia_acompanhante} · rota {@code /v1/actividades/acompanhantes-santa-ceia}. Os nomes dos campos são os do
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
@TabelaBd(schema = "actividades", nome = "santa_ceia_acompanhante", prefixo = "sca", modulo = "actividades", recurso = "acompanhantes-santa-ceia", colunaIgreja = "sca_igr_id")
public record SantaCeiaAcompanhante(
        @ColunaBd(value = "sca_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "sca_stc_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer santaCeiaId,
        @ColunaBd(value = "sca_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "sca_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "sca_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "sca_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "sca_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "sca_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "sca_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "sca_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
