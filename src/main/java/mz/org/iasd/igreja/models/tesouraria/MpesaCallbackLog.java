package mz.org.iasd.igreja.models.tesouraria;

import java.time.OffsetDateTime;

import jakarta.json.JsonValue;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Tudo o que a API M-Pesa envia, em bruto (callbacks repetidos são ignorados).
 * <p>
 * Tabela {@code tesouraria.mpesa_callback_log} · rota {@code /v1/tesouraria/mpesa-callbacks}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param pagamentoMpesaId Referência a tesouraria.pagamento_mpesa
 * @param tipo coluna {@code mcl_tipo} — obrigatório ao criar
 * @param chaveIdempotencia coluna {@code mcl_chave_idempotencia} — obrigatório ao criar
 * @param payload coluna {@code mcl_payload} — obrigatório ao criar
 * @param processado coluna {@code mcl_processado}
 * @param erro coluna {@code mcl_erro}
 * @param recebidoEm coluna {@code mcl_recebido_em}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "mpesa_callback_log", prefixo = "mcl", modulo = "tesouraria", recurso = "mpesa-callbacks")
public record MpesaCallbackLog(
        @ColunaBd(value = "mcl_id", tipo = Tipo.BIGINT, escrita = false, naoNula = true)
        Long id,
        @ColunaBd(value = "mcl_pmp_id", tipo = Tipo.BIGINT)
        Long pagamentoMpesaId,
        @ColunaBd(value = "mcl_tipo", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String tipo,
        @ColunaBd(value = "mcl_chave_idempotencia", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String chaveIdempotencia,
        @ColunaBd(value = "mcl_payload", tipo = Tipo.JSON, obrigatoria = true, naoNula = true)
        JsonValue payload,
        @ColunaBd(value = "mcl_processado", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean processado,
        @ColunaBd(value = "mcl_erro", tipo = Tipo.TEXTO)
        String erro,
        @ColunaBd(value = "mcl_recebido_em", tipo = Tipo.DATA_HORA, naoNula = true)
        OffsetDateTime recebidoEm,
        @ColunaBd(value = "mcl_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "mcl_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "mcl_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "mcl_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "mcl_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "mcl_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
