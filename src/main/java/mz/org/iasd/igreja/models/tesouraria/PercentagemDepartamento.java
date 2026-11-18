package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Parte de cada departamento no ano: reparte a doação distribuída (V50).
 * <p>
 * Tabela {@code tesouraria.percentagem_departamento} · rota {@code /v1/tesouraria/percentagens-departamento}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Copiado do departamento — obrigatório ao criar
 * @param departamentoIgrejaId Referência a organizacao.igreja_departamento — obrigatório ao criar
 * @param ano coluna {@code dpp_ano} — obrigatório ao criar
 * @param percentagem coluna {@code dpp_percentagem} — obrigatório ao criar
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "percentagem_departamento", prefixo = "dpp", modulo = "tesouraria", recurso = "percentagens-departamento", colunaIgreja = "dpp_igr_id")
public record PercentagemDepartamento(
        @ColunaBd(value = "dpp_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "dpp_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "dpp_ide_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer departamentoIgrejaId,
        @ColunaBd(value = "dpp_ano", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer ano,
        @ColunaBd(value = "dpp_percentagem", tipo = Tipo.DECIMAL, obrigatoria = true, naoNula = true)
        BigDecimal percentagem,
        @ColunaBd(value = "dpp_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "dpp_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "dpp_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "dpp_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "dpp_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "dpp_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
