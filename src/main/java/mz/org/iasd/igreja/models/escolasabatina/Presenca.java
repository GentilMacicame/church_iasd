package mz.org.iasd.igreja.models.escolasabatina;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Chamada nominal (opcional); actualiza M.P. e E.D. do relatório.
 * <p>
 * Tabela {@code escola_sabatina.presenca} · rota {@code /v1/escola-sabatina/presencas}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param relatorioId Referência a escola_sabatina.relatorio_sabado — obrigatório ao criar
 * @param membroId Referência a secretaria.membro — obrigatório ao criar
 * @param igrejaId Copiado do relatório (segurança e desempenho) (preenchido pela base de dados)
 * @param presente coluna {@code epr_presente} — obrigatório ao criar
 * @param estudouLicao coluna {@code epr_estudou_licao}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "escola_sabatina", nome = "presenca", prefixo = "epr", modulo = "escola-sabatina", recurso = "presencas", colunaIgreja = "epr_igr_id")
public record Presenca(
        @ColunaBd(value = "epr_id", tipo = Tipo.BIGINT, escrita = false, naoNula = true)
        Long id,
        @ColunaBd(value = "epr_ers_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer relatorioId,
        @ColunaBd(value = "epr_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "epr_igr_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "epr_presente", tipo = Tipo.BOOLEANO, obrigatoria = true, naoNula = true)
        Boolean presente,
        @ColunaBd(value = "epr_estudou_licao", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean estudouLicao,
        @ColunaBd(value = "epr_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "epr_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "epr_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "epr_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "epr_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "epr_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
