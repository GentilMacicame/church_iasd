package mz.org.iasd.igreja.models.escolasabatina;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Meta de oferta missionária de cada aluno da classe no trimestre; a da classe é a soma (V47).
 * <p>
 * Tabela {@code escola_sabatina.meta_individual} · rota {@code /v1/escola-sabatina/metas-individuais}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param classeTrimestreId Referência a escola_sabatina.classe_trimestre — obrigatório ao criar
 * @param membroId Referência a secretaria.membro — obrigatório ao criar
 * @param igrejaId Copiado da classe (segurança e desempenho) — obrigatório ao criar
 * @param alvoOferta Meta do aluno para o trimestre — obrigatório ao criar, dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "escola_sabatina", nome = "meta_individual", prefixo = "emt", modulo = "escola-sabatina", recurso = "metas-individuais", colunaIgreja = "emt_igr_id")
public record MetaIndividual(
        @ColunaBd(value = "emt_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "emt_ect_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer classeTrimestreId,
        @ColunaBd(value = "emt_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "emt_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "emt_alvo_oferta", tipo = Tipo.DINHEIRO, obrigatoria = true, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal alvoOferta,
        @ColunaBd(value = "emt_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "emt_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "emt_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "emt_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "emt_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "emt_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
