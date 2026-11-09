package mz.org.iasd.igreja.models.nucleo;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Perfil de um utilizador numa Associação/Missão inteira (vale para todas as igrejas abaixo dela).
 * <p>
 * Tabela {@code nucleo.usuario_entidade} · rota {@code /v1/nucleo/usuarios-entidade}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param usuarioId Referência a nucleo.usuario — obrigatório ao criar
 * @param entidadeId Referência a organizacao.entidade — obrigatório ao criar
 * @param perfilId Referência a nucleo.perfil — obrigatório ao criar
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "nucleo", nome = "usuario_entidade", prefixo = "uen", modulo = "nucleo", recurso = "usuarios-entidade")
public record UsuarioEntidade(
        @ColunaBd(value = "uen_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "uen_usu_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer usuarioId,
        @ColunaBd(value = "uen_ent_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer entidadeId,
        @ColunaBd(value = "uen_per_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer perfilId,
        @ColunaBd(value = "uen_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "uen_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "uen_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "uen_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "uen_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "uen_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
