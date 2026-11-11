package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoContagem;

/**
 * Contagem do dinheiro de um culto (tesoureiro e diácono: dois contadores).
 * <p>
 * Tabela {@code tesouraria.contagem_numerario} · rota {@code /v1/tesouraria/contagens}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param contaId Referência a tesouraria.conta_financeira — obrigatório ao criar
 * @param data coluna {@code cnu_data} — obrigatório ao criar
 * @param ocasiao coluna {@code cnu_ocasiao}
 * @param contador1MembroId Referência a secretaria.membro — obrigatório ao criar
 * @param contador2MembroId Referência a secretaria.membro — obrigatório ao criar
 * @param totalContado coluna {@code cnu_total_contado} — obrigatório ao criar, dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param conferidoPorUsuarioId Referência a nucleo.usuario
 * @param dizimos Parte do contado: dízimos (V23) — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param ofertas Parte do contado: ofertas (oferta combinada, missionárias) — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param escolaSabatina Parte do contado: ofertas da Escola Sabatina — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param outras Parte do contado: outras ofertas (especiais, projectos da igreja) — dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "contagem_numerario", prefixo = "cnu", modulo = "tesouraria", recurso = "contagens", colunaIgreja = "cnu_igr_id")
public record ContagemNumerario(
        @ColunaBd(value = "cnu_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "cnu_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "cnu_cfi_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer contaId,
        @ColunaBd(value = "cnu_data", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "cnu_ocasiao", tipo = Tipo.TEXTO, naoNula = true)
        String ocasiao,
        @ColunaBd(value = "cnu_contador1_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer contador1MembroId,
        @ColunaBd(value = "cnu_contador2_mem_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer contador2MembroId,
        @ColunaBd(value = "cnu_total_contado", tipo = Tipo.DINHEIRO, obrigatoria = true, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal totalContado,
        @ColunaBd(value = "cnu_conferido_por_usu_id", tipo = Tipo.INT)
        Integer conferidoPorUsuarioId,
        @ColunaBd(value = "cnu_dizimos", tipo = Tipo.DINHEIRO)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal dizimos,
        @ColunaBd(value = "cnu_ofertas", tipo = Tipo.DINHEIRO)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal ofertas,
        @ColunaBd(value = "cnu_escola_sabatina", tipo = Tipo.DINHEIRO)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal escolaSabatina,
        @ColunaBd(value = "cnu_outras", tipo = Tipo.DINHEIRO)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal outras,
        @ColunaBd(value = "cnu_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoContagem estado,
        @ColunaBd(value = "cnu_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "cnu_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "cnu_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "cnu_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "cnu_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
