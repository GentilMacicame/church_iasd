package mz.org.iasd.igreja.models.organizacao;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Cargos da igreja (Ancião, Secretário, Tesoureiro, Director da ES, ...).
 * <p>
 * Tabela {@code organizacao.cargo} · rota {@code /v1/organizacao/cargos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param departamentoId NULL = cargo geral da igreja
 * @param nome coluna {@code car_nome} — obrigatório ao criar
 * @param mandatoAnos Duração habitual do mandato
 * @param exigeMembro Só membros em situação regular
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "organizacao", nome = "cargo", prefixo = "car", modulo = "organizacao", recurso = "cargos")
public record Cargo(
        @ColunaBd(value = "car_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "car_dep_id", tipo = Tipo.INT)
        Integer departamentoId,
        @ColunaBd(value = "car_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "car_mandato_anos", tipo = Tipo.INT, naoNula = true)
        Integer mandatoAnos,
        @ColunaBd(value = "car_exige_membro", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean exigeMembro,
        @ColunaBd(value = "car_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "car_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "car_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "car_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "car_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "car_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
