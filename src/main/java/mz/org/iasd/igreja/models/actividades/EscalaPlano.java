package mz.org.iasd.igreja.models.actividades;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Escala de um período (ex.: escala de pregação do trimestre), assinada e publicada.
 * <p>
 * Tabela {@code actividades.escala_plano} · rota {@code /v1/actividades/planos-escala}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param titulo Ex.: Escala de Pregação — obrigatório ao criar
 * @param dataInicio coluna {@code epl_data_inicio} — obrigatório ao criar
 * @param dataFim coluna {@code epl_data_fim} — obrigatório ao criar
 * @param trimestreId Trimestre (opcional)
 * @param localEmissao Ex.: Matola
 * @param dataEmissao coluna {@code epl_data_emissao}
 * @param anciaoMembroId Ancião que assina
 * @param secretarioMembroId Secretário que assina
 * @param publicada Só as escalas publicadas são vistas pelos membros e geram lembretes
 * @param observacoes coluna {@code epl_observacoes}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "actividades", nome = "escala_plano", prefixo = "epl", modulo = "actividades", recurso = "planos-escala", colunaIgreja = "epl_igr_id")
public record EscalaPlano(
        @ColunaBd(value = "epl_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "epl_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "epl_titulo", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String titulo,
        @ColunaBd(value = "epl_data_inicio", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate dataInicio,
        @ColunaBd(value = "epl_data_fim", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate dataFim,
        @ColunaBd(value = "epl_etr_id", tipo = Tipo.INT)
        Integer trimestreId,
        @ColunaBd(value = "epl_local_emissao", tipo = Tipo.TEXTO)
        String localEmissao,
        @ColunaBd(value = "epl_data_emissao", tipo = Tipo.DATA)
        LocalDate dataEmissao,
        @ColunaBd(value = "epl_anciao_mem_id", tipo = Tipo.INT)
        Integer anciaoMembroId,
        @ColunaBd(value = "epl_secretario_mem_id", tipo = Tipo.INT)
        Integer secretarioMembroId,
        @ColunaBd(value = "epl_publicada", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean publicada,
        @ColunaBd(value = "epl_observacoes", tipo = Tipo.TEXTO)
        String observacoes,
        @ColunaBd(value = "epl_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "epl_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "epl_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "epl_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "epl_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "epl_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
