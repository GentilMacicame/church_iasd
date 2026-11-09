package mz.org.iasd.igreja.models.secretaria;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;
import mz.org.iasd.igreja.models.tipos.TipoContacto;

/**
 * Telefones, e-mails e WhatsApp de membros ou igrejas.
 * <p>
 * Tabela {@code secretaria.contacto} · rota {@code /v1/secretaria/contactos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param membroId Referência a secretaria.membro
 * @param igrejaId Referência a organizacao.igreja
 * @param tipo coluna {@code cto_tipo} — obrigatório ao criar
 * @param valor coluna {@code cto_valor} — obrigatório ao criar
 * @param principal coluna {@code cto_principal}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "secretaria", nome = "contacto", prefixo = "cto", modulo = "secretaria", recurso = "contactos")
public record Contacto(
        @ColunaBd(value = "cto_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "cto_mem_id", tipo = Tipo.INT)
        Integer membroId,
        @ColunaBd(value = "cto_igr_id", tipo = Tipo.INT)
        Integer igrejaId,
        @ColunaBd(value = "cto_tipo", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        TipoContacto tipo,
        @ColunaBd(value = "cto_valor", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String valor,
        @ColunaBd(value = "cto_principal", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean principal,
        @ColunaBd(value = "cto_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "cto_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "cto_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "cto_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "cto_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "cto_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
