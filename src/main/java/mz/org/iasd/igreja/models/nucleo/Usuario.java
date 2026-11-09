package mz.org.iasd.igreja.models.nucleo;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Contas de acesso ao sistema.
 * <p>
 * Tabela {@code nucleo.usuario} · rota {@code /v1/nucleo/usuarios}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param membroId Referência a secretaria.membro
 * @param nome coluna {@code usu_nome}
 * @param email coluna {@code usu_email}
 * @param telefone coluna {@code usu_telefone}
 * @param superAdmin Vê todas as igrejas
 * @param ultimoLogin (preenchido pela base de dados)
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "nucleo", nome = "usuario", prefixo = "usu", modulo = "nucleo", recurso = "usuarios")
public record Usuario(
        @ColunaBd(value = "usu_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "usu_mem_id", tipo = Tipo.INT)
        Integer membroId,
        @ColunaBd(value = "usu_nome", tipo = Tipo.TEXTO)
        String nome,
        @ColunaBd(value = "usu_email", tipo = Tipo.TEXTO)
        String email,
        @ColunaBd(value = "usu_telefone", tipo = Tipo.TEXTO)
        String telefone,
        @ColunaBd(value = "usu_super_admin", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean superAdmin,
        @ColunaBd(value = "usu_ultimo_login", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime ultimoLogin,
        @ColunaBd(value = "usu_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "usu_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "usu_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "usu_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "usu_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "usu_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
