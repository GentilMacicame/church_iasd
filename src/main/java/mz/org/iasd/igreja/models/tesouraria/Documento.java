package mz.org.iasd.igreja.models.tesouraria;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;
import mz.org.iasd.igreja.models.tipos.TipoDocumento;

/**
 * Comprovativos (facturas, talões, prints M-Pesa).
 * <p>
 * Tabela {@code tesouraria.documento} · rota {@code /v1/tesouraria/documentos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param transacaoId Referência a tesouraria.transacao
 * @param despesaId Referência a tesouraria.despesa
 * @param tipo coluna {@code doc_tipo} — obrigatório ao criar
 * @param nomeFicheiro coluna {@code doc_nome_ficheiro} — obrigatório ao criar
 * @param url coluna {@code doc_url} — obrigatório ao criar
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "documento", prefixo = "doc", modulo = "tesouraria", recurso = "documentos")
public record Documento(
        @ColunaBd(value = "doc_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "doc_tra_id", tipo = Tipo.BIGINT)
        Long transacaoId,
        @ColunaBd(value = "doc_des_id", tipo = Tipo.INT)
        Integer despesaId,
        @ColunaBd(value = "doc_tipo", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        TipoDocumento tipo,
        @ColunaBd(value = "doc_nome_ficheiro", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nomeFicheiro,
        @ColunaBd(value = "doc_url", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String url,
        @ColunaBd(value = "doc_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "doc_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "doc_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "doc_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "doc_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "doc_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
