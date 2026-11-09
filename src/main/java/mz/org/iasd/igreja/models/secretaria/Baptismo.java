package mz.org.iasd.igreja.models.secretaria;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Baptismos e rebaptismos.
 * <p>
 * Tabela {@code secretaria.baptismo} · rota {@code /v1/secretaria/baptismos}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param membroId Referência a secretaria.membro — obrigatório ao criar
 * @param data coluna {@code bap_data} — obrigatório ao criar
 * @param local coluna {@code bap_local}
 * @param oficiante Pastor ordenado que baptizou
 * @param rebaptismo coluna {@code bap_rebaptismo}
 * @param classeTrimestreId Classe da ES que preparou o candidato
 * @param localIgrejaId Igreja onde foi baptizado, se estiver no sistema (senão: local)
 * @param oficianteUsuarioId Pastor que baptizou, se tiver conta no sistema (senão: oficiante)
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "secretaria", nome = "baptismo", prefixo = "bap", modulo = "secretaria", recurso = "baptismos")
public record Baptismo(
        @ColunaBd(value = "bap_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "bap_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "bap_data", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "bap_local", tipo = Tipo.TEXTO)
        String local,
        @ColunaBd(value = "bap_oficiante", tipo = Tipo.TEXTO)
        String oficiante,
        @ColunaBd(value = "bap_rebaptismo", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean rebaptismo,
        @ColunaBd(value = "bap_ect_id", tipo = Tipo.INT)
        Integer classeTrimestreId,
        @ColunaBd(value = "bap_local_igr_id", tipo = Tipo.INT)
        Integer localIgrejaId,
        @ColunaBd(value = "bap_oficiante_usu_id", tipo = Tipo.INT)
        Integer oficianteUsuarioId,
        @ColunaBd(value = "bap_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "bap_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "bap_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "bap_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "bap_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "bap_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
