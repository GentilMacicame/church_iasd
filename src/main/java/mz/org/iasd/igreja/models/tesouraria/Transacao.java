package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoTransacao;
import mz.org.iasd.igreja.models.tipos.MetodoPagamento;
import mz.org.iasd.igreja.models.tipos.TipoTransacao;

/**
 * Movimentos: entradas, saídas e transferências (cabeçalho).
 * <p>
 * Tabela {@code tesouraria.transacao} · rota {@code /v1/tesouraria/transacoes}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Preenchido automaticamente a partir da conta (preenchido pela base de dados)
 * @param tipo coluna {@code tra_tipo} — obrigatório ao criar
 * @param metodo coluna {@code tra_metodo} — obrigatório ao criar
 * @param valorTotal coluna {@code tra_valor_total} — obrigatório ao criar, dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param contaId Referência a tesouraria.conta_financeira — obrigatório ao criar
 * @param destinoContaId Só transferências
 * @param membroId Quem entregou
 * @param familiaId Entrega em nome da família
 * @param anonimo coluna {@code tra_anonimo}
 * @param contagemId Referência a tesouraria.contagem_numerario
 * @param despesaId Referência a tesouraria.despesa
 * @param estornoTransacaoId Referência a tesouraria.transacao
 * @param beneficiario coluna {@code tra_beneficiario}
 * @param descricao coluna {@code tra_descricao}
 * @param referencia coluna {@code tra_referencia}
 * @param dataHora coluna {@code tra_data_hora}
 * @param aprovadoPorUsuarioId Referência a nucleo.usuario
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "transacao", prefixo = "tra", modulo = "tesouraria", recurso = "transacoes", colunaIgreja = "tra_igr_id")
public record Transacao(
        @ColunaBd(value = "tra_id", tipo = Tipo.BIGINT, escrita = false, naoNula = true)
        Long id,
        @ColunaBd(value = "tra_igr_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "tra_tipo", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        TipoTransacao tipo,
        @ColunaBd(value = "tra_metodo", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        MetodoPagamento metodo,
        @ColunaBd(value = "tra_valor_total", tipo = Tipo.DINHEIRO, obrigatoria = true, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valorTotal,
        @ColunaBd(value = "tra_cfi_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer contaId,
        @ColunaBd(value = "tra_destino_cfi_id", tipo = Tipo.INT)
        Integer destinoContaId,
        @ColunaBd(value = "tra_mem_id", tipo = Tipo.INT)
        Integer membroId,
        @ColunaBd(value = "tra_fam_id", tipo = Tipo.INT)
        Integer familiaId,
        @ColunaBd(value = "tra_anonimo", tipo = Tipo.BOOLEANO, naoNula = true)
        Boolean anonimo,
        @ColunaBd(value = "tra_cnu_id", tipo = Tipo.INT)
        Integer contagemId,
        @ColunaBd(value = "tra_des_id", tipo = Tipo.INT)
        Integer despesaId,
        @ColunaBd(value = "tra_estorno_tra_id", tipo = Tipo.BIGINT)
        Long estornoTransacaoId,
        @ColunaBd(value = "tra_beneficiario", tipo = Tipo.TEXTO)
        String beneficiario,
        @ColunaBd(value = "tra_descricao", tipo = Tipo.TEXTO)
        String descricao,
        @ColunaBd(value = "tra_referencia", tipo = Tipo.TEXTO)
        String referencia,
        @ColunaBd(value = "tra_data_hora", tipo = Tipo.DATA_HORA, naoNula = true)
        OffsetDateTime dataHora,
        @ColunaBd(value = "tra_aprovado_por_usu_id", tipo = Tipo.INT)
        Integer aprovadoPorUsuarioId,
        @ColunaBd(value = "tra_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoTransacao estado,
        @ColunaBd(value = "tra_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "tra_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "tra_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "tra_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "tra_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
