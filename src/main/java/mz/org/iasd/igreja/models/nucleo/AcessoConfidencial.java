package mz.org.iasd.igreja.models.nucleo;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Consultas a dados confidenciais (ex.: o motivo de uma censura): quem, quando, que registo (V41).
 * <p>
 * Tabela {@code nucleo.acesso_confidencial} · rota {@code /v1/nucleo/acessos-confidenciais}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param usuarioId Referência a nucleo.usuario
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param tabela coluna {@code aco_tabela} — obrigatório ao criar
 * @param registoId coluna {@code aco_registo_id} — obrigatório ao criar
 * @param accao Ex.: LER_MOTIVO — obrigatório ao criar
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "nucleo", nome = "acesso_confidencial", prefixo = "aco", modulo = "nucleo", recurso = "acessos-confidenciais", soLeitura = true, colunaIgreja = "aco_igr_id")
public record AcessoConfidencial(
        @ColunaBd(value = "aco_id", tipo = Tipo.BIGINT, escrita = false, naoNula = true)
        Long id,
        @ColunaBd(value = "aco_usu_id", tipo = Tipo.INT)
        Integer usuarioId,
        @ColunaBd(value = "aco_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "aco_tabela", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String tabela,
        @ColunaBd(value = "aco_registo_id", tipo = Tipo.BIGINT, obrigatoria = true, naoNula = true)
        Long registoId,
        @ColunaBd(value = "aco_accao", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String accao,
        @ColunaBd(value = "aco_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "aco_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "aco_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "aco_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "aco_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "aco_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
