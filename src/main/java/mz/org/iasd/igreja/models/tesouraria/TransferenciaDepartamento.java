package mz.org.iasd.igreja.models.tesouraria;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

import jakarta.json.bind.annotation.JsonbNumberFormat;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Transferência de saldo entre departamentos da igreja (V50).
 * <p>
 * Tabela {@code tesouraria.transferencia_departamento} · rota {@code /v1/tesouraria/transferencias-departamento}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Copiado do departamento de origem — obrigatório ao criar
 * @param origemDepartamentoIgrejaId Referência a organizacao.igreja_departamento — obrigatório ao criar
 * @param destinoDepartamentoIgrejaId Referência a organizacao.igreja_departamento — obrigatório ao criar
 * @param data coluna {@code tdp_data} — obrigatório ao criar
 * @param valor coluna {@code tdp_valor} — obrigatório ao criar, dinheiro: no JSON é texto com 2 casas, ex. "650.00"
 * @param descricao coluna {@code tdp_descricao}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "tesouraria", nome = "transferencia_departamento", prefixo = "tdp", modulo = "tesouraria", recurso = "transferencias-departamento", colunaIgreja = "tdp_igr_id")
public record TransferenciaDepartamento(
        @ColunaBd(value = "tdp_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "tdp_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "tdp_origem_ide_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer origemDepartamentoIgrejaId,
        @ColunaBd(value = "tdp_destino_ide_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer destinoDepartamentoIgrejaId,
        @ColunaBd(value = "tdp_data", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "tdp_valor", tipo = Tipo.DINHEIRO, obrigatoria = true, naoNula = true)
        @JsonbNumberFormat(value = "0.00", locale = "en") BigDecimal valor,
        @ColunaBd(value = "tdp_descricao", tipo = Tipo.TEXTO)
        String descricao,
        @ColunaBd(value = "tdp_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "tdp_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "tdp_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "tdp_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "tdp_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "tdp_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
