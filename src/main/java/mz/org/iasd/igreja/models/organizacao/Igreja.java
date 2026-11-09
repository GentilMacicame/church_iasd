package mz.org.iasd.igreja.models.organizacao;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;
import mz.org.iasd.igreja.models.tipos.TipoIgreja;

/**
 * Igrejas organizadas, grupos organizados e grupos/filiais.
 * <p>
 * Tabela {@code organizacao.igreja} · rota {@code /v1/organizacao/igrejas}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param entidadeId Associação/Missão a que pertence — obrigatório ao criar
 * @param distritoId Referência a organizacao.distrito
 * @param tipo coluna {@code igr_tipo}
 * @param maeIgrejaId Igreja-mãe de um grupo ou filial
 * @param nome coluna {@code igr_nome} — obrigatório ao criar
 * @param codigoAcms Código no sistema da Associação (ACMS/eAdventist)
 * @param dataOrganizacao coluna {@code igr_data_organizacao}
 * @param endereco coluna {@code igr_endereco}
 * @param latitude coluna {@code igr_latitude}
 * @param longitude coluna {@code igr_longitude}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "organizacao", nome = "igreja", prefixo = "igr", modulo = "organizacao", recurso = "igrejas", colunaIgreja = "igr_id")
public record Igreja(
        @ColunaBd(value = "igr_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "igr_ent_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer entidadeId,
        @ColunaBd(value = "igr_dst_id", tipo = Tipo.INT)
        Integer distritoId,
        @ColunaBd(value = "igr_tipo", tipo = Tipo.ENUM, naoNula = true)
        TipoIgreja tipo,
        @ColunaBd(value = "igr_mae_igr_id", tipo = Tipo.INT)
        Integer maeIgrejaId,
        @ColunaBd(value = "igr_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "igr_codigo_acms", tipo = Tipo.TEXTO)
        String codigoAcms,
        @ColunaBd(value = "igr_data_organizacao", tipo = Tipo.DATA)
        LocalDate dataOrganizacao,
        @ColunaBd(value = "igr_endereco", tipo = Tipo.TEXTO)
        String endereco,
        @ColunaBd(value = "igr_latitude", tipo = Tipo.DECIMAL)
        BigDecimal latitude,
        @ColunaBd(value = "igr_longitude", tipo = Tipo.DECIMAL)
        BigDecimal longitude,
        @ColunaBd(value = "igr_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "igr_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "igr_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "igr_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "igr_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "igr_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
