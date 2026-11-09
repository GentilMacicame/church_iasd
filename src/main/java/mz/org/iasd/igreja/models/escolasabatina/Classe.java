package mz.org.iasd.igreja.models.escolasabatina;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EsDivisao;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Classes / unidades de acção, por divisão da Escola Sabatina.
 * <p>
 * Tabela {@code escola_sabatina.classe} · rota {@code /v1/escola-sabatina/classes}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param nome coluna {@code ecl_nome} — obrigatório ao criar
 * @param divisao coluna {@code ecl_divisao}
 * @param localReuniao coluna {@code ecl_local_reuniao}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "escola_sabatina", nome = "classe", prefixo = "ecl", modulo = "escola-sabatina", recurso = "classes", colunaIgreja = "ecl_igr_id")
public record Classe(
        @ColunaBd(value = "ecl_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "ecl_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "ecl_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "ecl_divisao", tipo = Tipo.ENUM, naoNula = true)
        EsDivisao divisao,
        @ColunaBd(value = "ecl_local_reuniao", tipo = Tipo.TEXTO)
        String localReuniao,
        @ColunaBd(value = "ecl_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "ecl_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "ecl_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "ecl_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "ecl_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "ecl_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
