package mz.org.iasd.igreja.models.comunicacao;

import java.time.OffsetDateTime;

import mz.org.iasd.igreja.crud.ColunaBd;
import mz.org.iasd.igreja.crud.TabelaBd;
import mz.org.iasd.igreja.crud.Tipo;
import mz.org.iasd.igreja.models.tipos.CanalNotificacao;
import mz.org.iasd.igreja.models.tipos.EstadoNotificacao;

/**
 * Fila de SMS, WhatsApp e e-mail a enviar.
 * <p>
 * Tabela {@code comunicacao.notificacao} · rota {@code /v1/comunicacao/notificacoes}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param membroId Referência a secretaria.membro
 * @param canal coluna {@code ntf_canal} — obrigatório ao criar
 * @param destino coluna {@code ntf_destino} — obrigatório ao criar
 * @param assunto coluna {@code ntf_assunto}
 * @param mensagem coluna {@code ntf_mensagem} — obrigatório ao criar
 * @param agendadaPara coluna {@code ntf_agendada_para}
 * @param enviadaEm coluna {@code ntf_enviada_em}
 * @param tentativas coluna {@code ntf_tentativas}
 * @param erro coluna {@code ntf_erro}
 * @param origemTabela coluna {@code ntf_origem_tabela}
 * @param origemId coluna {@code ntf_origem_id}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "comunicacao", nome = "notificacao", prefixo = "ntf", modulo = "comunicacao", recurso = "notificacoes", colunaIgreja = "ntf_igr_id")
public record Notificacao(
        @ColunaBd(value = "ntf_id", tipo = Tipo.BIGINT, escrita = false, naoNula = true)
        Long id,
        @ColunaBd(value = "ntf_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "ntf_mem_id", tipo = Tipo.INT)
        Integer membroId,
        @ColunaBd(value = "ntf_canal", tipo = Tipo.ENUM, obrigatoria = true, naoNula = true)
        CanalNotificacao canal,
        @ColunaBd(value = "ntf_destino", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String destino,
        @ColunaBd(value = "ntf_assunto", tipo = Tipo.TEXTO)
        String assunto,
        @ColunaBd(value = "ntf_mensagem", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String mensagem,
        @ColunaBd(value = "ntf_agendada_para", tipo = Tipo.DATA_HORA, naoNula = true)
        OffsetDateTime agendadaPara,
        @ColunaBd(value = "ntf_enviada_em", tipo = Tipo.DATA_HORA)
        OffsetDateTime enviadaEm,
        @ColunaBd(value = "ntf_tentativas", tipo = Tipo.INT, naoNula = true)
        Integer tentativas,
        @ColunaBd(value = "ntf_erro", tipo = Tipo.TEXTO)
        String erro,
        @ColunaBd(value = "ntf_origem_tabela", tipo = Tipo.TEXTO)
        String origemTabela,
        @ColunaBd(value = "ntf_origem_id", tipo = Tipo.BIGINT)
        Long origemId,
        @ColunaBd(value = "ntf_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoNotificacao estado,
        @ColunaBd(value = "ntf_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "ntf_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "ntf_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "ntf_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "ntf_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
