package mz.org.iasd.igreja.models.nucleo;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Que permissões cada perfil tem.
 * <p>
 * Tabela {@code nucleo.perfil_permissao} · rota {@code /v1/nucleo/perfis-permissoes}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param perfilId Referência a nucleo.perfil — obrigatório ao criar
 * @param permissaoId Referência a nucleo.permissao — obrigatório ao criar
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "nucleo", nome = "perfil_permissao", prefixo = "ppe", modulo = "nucleo", recurso = "perfis-permissoes")
public record PerfilPermissao(
        @ColunaBd(value = "ppe_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "ppe_per_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer perfilId,
        @ColunaBd(value = "ppe_prm_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer permissaoId,
        @ColunaBd(value = "ppe_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "ppe_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "ppe_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "ppe_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "ppe_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "ppe_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
