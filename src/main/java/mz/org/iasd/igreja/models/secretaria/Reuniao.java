package mz.org.iasd.igreja.models.secretaria;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoReuniao;
import mz.org.iasd.igreja.models.tipos.TipoReuniao;

/**
 * Reuniões: junta directiva, reunião regular, assembleia administrativa, comissão de nomeações, conselho da ES.
 * <p>
 * Tabela {@code secretaria.reuniao} · rota {@code /v1/secretaria/reunioes}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param tipo coluna {@code reu_tipo} — obrigatório ao criar
 * @param data coluna {@code reu_data} — obrigatório ao criar
 * @param local coluna {@code reu_local}
 * @param presididaPorMembroId Referência a secretaria.membro
 * @param secretarioMembroId Referência a secretaria.membro
 * @param quorumPresentes coluna {@code reu_quorum_presentes}
 * @param actaUrl coluna {@code reu_acta_url}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "secretaria", nome = "reuniao", prefixo = "reu", modulo = "secretaria", recurso = "reunioes", colunaIgreja = "reu_igr_id")
public record Reuniao(
        @ColunaBd(value = "reu_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "reu_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "reu_tipo", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        TipoReuniao tipo,
        @ColunaBd(value = "reu_data", tipo = Tipo.DATA_HORA, obrigatoria = true, naoNula = true)
        OffsetDateTime data,
        @ColunaBd(value = "reu_local", tipo = Tipo.TEXTO)
        String local,
        @ColunaBd(value = "reu_presidida_por_mem_id", tipo = Tipo.INT)
        Integer presididaPorMembroId,
        @ColunaBd(value = "reu_secretario_mem_id", tipo = Tipo.INT)
        Integer secretarioMembroId,
        @ColunaBd(value = "reu_quorum_presentes", tipo = Tipo.INT)
        Integer quorumPresentes,
        @ColunaBd(value = "reu_acta_url", tipo = Tipo.TEXTO)
        String actaUrl,
        @ColunaBd(value = "reu_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoReuniao estado,
        @ColunaBd(value = "reu_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "reu_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "reu_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "reu_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "reu_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
