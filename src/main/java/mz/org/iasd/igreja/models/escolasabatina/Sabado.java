package mz.org.iasd.igreja.models.escolasabatina;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Sábados de cada trimestre.
 * <p>
 * Tabela {@code escola_sabatina.sabado} · rota {@code /v1/escola-sabatina/sabados}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param trimestreId Referência a escola_sabatina.trimestre — obrigatório ao criar
 * @param numero coluna {@code esa_numero} — obrigatório ao criar
 * @param data coluna {@code esa_data} — obrigatório ao criar
 * @param decimoTerceiro coluna {@code esa_decimo_terceiro}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "escola_sabatina", nome = "sabado", prefixo = "esa", modulo = "escola-sabatina", recurso = "sabados")
public record Sabado(
        @ColunaBd(value = "esa_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "esa_etr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer trimestreId,
        @ColunaBd(value = "esa_numero", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer numero,
        @ColunaBd(value = "esa_data", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "esa_decimo_terceiro", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean decimoTerceiro,
        @ColunaBd(value = "esa_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "esa_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "esa_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "esa_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "esa_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "esa_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
