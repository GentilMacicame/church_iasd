package mz.org.iasd.igreja.models.nucleo;

import java.time.OffsetDateTime;

import jakarta.json.JsonValue;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Histórico de alterações (só os campos que mudaram); particionado por mês.
 * <p>
 * Tabela {@code nucleo.log_auditoria} · rota {@code /v1/nucleo/auditoria}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param usuarioId Referência a nucleo.usuario
 * @param tabela coluna {@code lau_tabela} — obrigatório ao criar
 * @param registoId coluna {@code lau_registo_id} — obrigatório ao criar
 * @param accao coluna {@code lau_accao} — obrigatório ao criar
 * @param dadosAntes coluna {@code lau_dados_antes}
 * @param dadosDepois coluna {@code lau_dados_depois}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "nucleo", nome = "log_auditoria", prefixo = "lau", modulo = "nucleo", recurso = "auditoria", soLeitura = true)
public record LogAuditoria(
        @ColunaBd(value = "lau_id", tipo = Tipo.BIGINT, escrita = false, naoNula = true)
        Long id,
        @ColunaBd(value = "lau_usu_id", tipo = Tipo.INT)
        Integer usuarioId,
        @ColunaBd(value = "lau_tabela", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String tabela,
        @ColunaBd(value = "lau_registo_id", tipo = Tipo.BIGINT, obrigatoria = true, naoNula = true)
        Long registoId,
        @ColunaBd(value = "lau_accao", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String accao,
        @ColunaBd(value = "lau_dados_antes", tipo = Tipo.JSON)
        JsonValue dadosAntes,
        @ColunaBd(value = "lau_dados_depois", tipo = Tipo.JSON)
        JsonValue dadosDepois,
        @ColunaBd(value = "lau_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "lau_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "lau_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "lau_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "lau_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "lau_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
