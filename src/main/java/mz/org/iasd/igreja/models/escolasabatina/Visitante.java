package mz.org.iasd.igreja.models.escolasabatina;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Visitantes com contacto para seguimento.
 * <p>
 * Tabela {@code escola_sabatina.visitante} · rota {@code /v1/escola-sabatina/visitantes}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param relatorioId Referência a escola_sabatina.relatorio_sabado — obrigatório ao criar
 * @param nome coluna {@code evi_nome} — obrigatório ao criar
 * @param telefone coluna {@code evi_telefone}
 * @param convidadoPorMembroId Referência a secretaria.membro
 * @param tornouSeMembroId Referência a secretaria.membro
 * @param anonimizadoEm Dados apagados por fim do prazo de retenção
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "escola_sabatina", nome = "visitante", prefixo = "evi", modulo = "escola-sabatina", recurso = "visitantes")
public record Visitante(
        @ColunaBd(value = "evi_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "evi_ers_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer relatorioId,
        @ColunaBd(value = "evi_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "evi_telefone", tipo = Tipo.TEXTO)
        String telefone,
        @ColunaBd(value = "evi_convidado_por_mem_id", tipo = Tipo.INT)
        Integer convidadoPorMembroId,
        @ColunaBd(value = "evi_tornou_se_mem_id", tipo = Tipo.INT)
        Integer tornouSeMembroId,
        @ColunaBd(value = "evi_anonimizado_em", tipo = Tipo.DATA_HORA)
        OffsetDateTime anonimizadoEm,
        @ColunaBd(value = "evi_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "evi_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "evi_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "evi_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "evi_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "evi_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
