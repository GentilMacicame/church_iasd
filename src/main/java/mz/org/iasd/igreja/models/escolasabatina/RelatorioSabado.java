package mz.org.iasd.igreja.models.escolasabatina;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRelatorio;

/**
 * Relatório de cada classe em cada sábado (linha da folha "Grupo N").
 * <p>
 * Tabela {@code escola_sabatina.relatorio_sabado} · rota {@code /v1/escola-sabatina/relatorios-sabado}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param classeTrimestreId Referência a escola_sabatina.classe_trimestre — obrigatório ao criar
 * @param sabadoId Referência a escola_sabatina.sabado — obrigatório ao criar
 * @param igrejaId Copiado da classe (segurança e desempenho) (preenchido pela base de dados)
 * @param membrosMatriculados M.M. (se vier vazio, é calculado pelas matrículas)
 * @param membrosPresentes M.P. (recalculado quando há chamada nominal) — obrigatório ao criar
 * @param estudoDiario E.D.
 * @param visitantes coluna {@code ers_visitantes}
 * @param filiais coluna {@code ers_filiais}
 * @param oferta Oferta missionária (vai toda para as missões) — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param oferta13Sabado coluna {@code ers_oferta_13_sabado} — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param ofertaDespesas Oferta para despesas da ES local (sempre separada da missionária) — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param transacaoId Lançamento das ofertas na tesouraria
 * @param observacoes coluna {@code ers_observacoes}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "escola_sabatina", nome = "relatorio_sabado", prefixo = "ers", modulo = "escola-sabatina", recurso = "relatorios-sabado", colunaIgreja = "ers_igr_id")
public record RelatorioSabado(
        @ColunaBd(value = "ers_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "ers_ect_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer classeTrimestreId,
        @ColunaBd(value = "ers_esa_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer sabadoId,
        @ColunaBd(value = "ers_igr_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "ers_membros_matriculados", tipo = Tipo.INT, naoNula = true)
        Integer membrosMatriculados,
        @ColunaBd(value = "ers_membros_presentes", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membrosPresentes,
        @ColunaBd(value = "ers_estudo_diario", tipo = Tipo.INT, naoNula = true)
        Integer estudoDiario,
        @ColunaBd(value = "ers_visitantes", tipo = Tipo.INT, naoNula = true)
        Integer visitantes,
        @ColunaBd(value = "ers_filiais", tipo = Tipo.INT, naoNula = true)
        Integer filiais,
        @ColunaBd(value = "ers_oferta", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal oferta,
        @ColunaBd(value = "ers_oferta_13_sabado", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal oferta13Sabado,
        @ColunaBd(value = "ers_oferta_despesas", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal ofertaDespesas,
        @ColunaBd(value = "ers_tra_id", tipo = Tipo.BIGINT)
        Long transacaoId,
        @ColunaBd(value = "ers_observacoes", tipo = Tipo.TEXTO)
        String observacoes,
        @ColunaBd(value = "ers_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRelatorio estado,
        @ColunaBd(value = "ers_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "ers_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "ers_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "ers_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "ers_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
