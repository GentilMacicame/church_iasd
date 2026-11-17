package mz.org.iasd.igreja.models.actividades;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Responsáveis de uma actividade, além do principal, e a função de cada um (V34).
 * <p>
 * Tabela {@code actividades.actividade_responsavel} · rota {@code /v1/actividades/responsaveis-actividade}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param actividadeId Referência a actividades.actividade — obrigatório ao criar
 * @param membroId Referência a secretaria.membro — obrigatório ao criar
 * @param funcao Ex.: coordenação, logística, programa, finanças
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "actividades", nome = "actividade_responsavel", prefixo = "acr", modulo = "actividades", recurso = "responsaveis-actividade")
public record ActividadeResponsavel(
        @ColunaBd(value = "acr_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "acr_act_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer actividadeId,
        @ColunaBd(value = "acr_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "acr_funcao", tipo = Tipo.TEXTO)
        String funcao,
        @ColunaBd(value = "acr_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "acr_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "acr_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "acr_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "acr_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "acr_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
