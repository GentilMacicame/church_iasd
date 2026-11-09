package mz.org.iasd.igreja.models.escolasabatina;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Pesos da pontuação (sem trimestre = pesos por defeito).
 * <p>
 * Tabela {@code escola_sabatina.pontuacao_config} · rota {@code /v1/escola-sabatina/pesos-pontuacao}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param trimestreId Referência a escola_sabatina.trimestre
 * @param pesoPresenca coluna {@code epc_peso_presenca}
 * @param pesoEstudo coluna {@code epc_peso_estudo}
 * @param pesoOfertas coluna {@code epc_peso_ofertas}
 * @param pesoVisitantes coluna {@code epc_peso_visitantes}
 * @param limiteOfertas coluna {@code epc_limite_ofertas}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "escola_sabatina", nome = "pontuacao_config", prefixo = "epc", modulo = "escola-sabatina", recurso = "pesos-pontuacao")
public record PontuacaoConfig(
        @ColunaBd(value = "epc_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "epc_etr_id", tipo = Tipo.INT)
        Integer trimestreId,
        @ColunaBd(value = "epc_peso_presenca", tipo = Tipo.DECIMAL, naoNula = true)
        BigDecimal pesoPresenca,
        @ColunaBd(value = "epc_peso_estudo", tipo = Tipo.DECIMAL, naoNula = true)
        BigDecimal pesoEstudo,
        @ColunaBd(value = "epc_peso_ofertas", tipo = Tipo.DECIMAL, naoNula = true)
        BigDecimal pesoOfertas,
        @ColunaBd(value = "epc_peso_visitantes", tipo = Tipo.DECIMAL, naoNula = true)
        BigDecimal pesoVisitantes,
        @ColunaBd(value = "epc_limite_ofertas", tipo = Tipo.DECIMAL, naoNula = true)
        BigDecimal limiteOfertas,
        @ColunaBd(value = "epc_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "epc_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "epc_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "epc_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "epc_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "epc_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
