package mz.org.iasd.igreja.models.escolasabatina;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Classe num trimestre: professor e alvos (ACTIVO/INACTIVO = Activo/Desactivado da planilha).
 * <p>
 * Tabela {@code escola_sabatina.classe_trimestre} · rota {@code /v1/escola-sabatina/classes-trimestre}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param classeId Referência a escola_sabatina.classe — obrigatório ao criar
 * @param trimestreId Referência a escola_sabatina.trimestre — obrigatório ao criar
 * @param igrejaId Copiado da classe (segurança e desempenho) (preenchido pela base de dados)
 * @param professorMembroId Referência a secretaria.membro
 * @param auxiliarMembroId Referência a secretaria.membro
 * @param secretarioMembroId Referência a secretaria.membro
 * @param alvoMembros coluna {@code ect_alvo_membros}
 * @param alvoEstudoDiario coluna {@code ect_alvo_estudo_diario}
 * @param alvoFiliais coluna {@code ect_alvo_filiais}
 * @param alvoOfertaSabado Alvo da oferta missionária por sábado — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param alvoBaptismos coluna {@code ect_alvo_baptismos}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "escola_sabatina", nome = "classe_trimestre", prefixo = "ect", modulo = "escola-sabatina", recurso = "classes-trimestre", colunaIgreja = "ect_igr_id")
public record ClasseTrimestre(
        @ColunaBd(value = "ect_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "ect_ecl_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer classeId,
        @ColunaBd(value = "ect_etr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer trimestreId,
        @ColunaBd(value = "ect_igr_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "ect_professor_mem_id", tipo = Tipo.INT)
        Integer professorMembroId,
        @ColunaBd(value = "ect_auxiliar_mem_id", tipo = Tipo.INT)
        Integer auxiliarMembroId,
        @ColunaBd(value = "ect_secretario_mem_id", tipo = Tipo.INT)
        Integer secretarioMembroId,
        @ColunaBd(value = "ect_alvo_membros", tipo = Tipo.INT, naoNula = true)
        Integer alvoMembros,
        @ColunaBd(value = "ect_alvo_estudo_diario", tipo = Tipo.DECIMAL, naoNula = true)
        BigDecimal alvoEstudoDiario,
        @ColunaBd(value = "ect_alvo_filiais", tipo = Tipo.INT, naoNula = true)
        Integer alvoFiliais,
        @ColunaBd(value = "ect_alvo_oferta_sabado", tipo = Tipo.DINHEIRO, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal alvoOfertaSabado,
        @ColunaBd(value = "ect_alvo_baptismos", tipo = Tipo.INT, naoNula = true)
        Integer alvoBaptismos,
        @ColunaBd(value = "ect_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "ect_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "ect_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "ect_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "ect_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "ect_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
