package mz.org.iasd.igreja.models.secretaria;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoTransferencia;

/**
 * Cartas de transferência (válidas 6 meses; o membro só sai quando o destino aceita).
 * <p>
 * Tabela {@code secretaria.transferencia_membro} · rota {@code /v1/secretaria/transferencias}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param membroId Referência a secretaria.membro — obrigatório ao criar
 * @param origemIgrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param destinoIgrejaId Referência a organizacao.igreja
 * @param destinoExterno Igreja fora do sistema
 * @param dataPedido coluna {@code tme_data_pedido}
 * @param origemVotoId Voto da igreja de origem que concede a carta
 * @param cartaEmitidaEm coluna {@code tme_carta_emitida_em}
 * @param destinoVotoId Voto da igreja de destino que aceita o membro
 * @param aceiteEm coluna {@code tme_aceite_em}
 * @param observacoes coluna {@code tme_observacoes}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "secretaria", nome = "transferencia_membro", prefixo = "tme", modulo = "secretaria", recurso = "transferencias")
public record TransferenciaMembro(
        @ColunaBd(value = "tme_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "tme_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer membroId,
        @ColunaBd(value = "tme_origem_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer origemIgrejaId,
        @ColunaBd(value = "tme_destino_igr_id", tipo = Tipo.INT)
        Integer destinoIgrejaId,
        @ColunaBd(value = "tme_destino_externo", tipo = Tipo.TEXTO)
        String destinoExterno,
        @ColunaBd(value = "tme_data_pedido", tipo = Tipo.DATA, naoNula = true)
        LocalDate dataPedido,
        @ColunaBd(value = "tme_origem_vot_id", tipo = Tipo.INT)
        Integer origemVotoId,
        @ColunaBd(value = "tme_carta_emitida_em", tipo = Tipo.DATA)
        LocalDate cartaEmitidaEm,
        @ColunaBd(value = "tme_destino_vot_id", tipo = Tipo.INT)
        Integer destinoVotoId,
        @ColunaBd(value = "tme_aceite_em", tipo = Tipo.DATA)
        LocalDate aceiteEm,
        @ColunaBd(value = "tme_observacoes", tipo = Tipo.TEXTO)
        String observacoes,
        @ColunaBd(value = "tme_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoTransferencia estado,
        @ColunaBd(value = "tme_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "tme_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "tme_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "tme_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "tme_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
