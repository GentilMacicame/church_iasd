package mz.org.iasd.igreja.models.secretaria;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.Escolaridade;
import mz.org.iasd.igreja.models.tipos.EstadoCivil;
import mz.org.iasd.igreja.models.tipos.EstadoMembro;
import mz.org.iasd.igreja.models.tipos.EstadoValidacao;
import mz.org.iasd.igreja.models.tipos.Sexo;
import mz.org.iasd.igreja.models.tipos.TipoIdentificacao;
import mz.org.iasd.igreja.models.tipos.TipoMovimento;

/**
 * Membros, interessados e visitantes regulares (estado muda só por movimento).
 * <p>
 * Tabela {@code secretaria.membro} · rota {@code /v1/secretaria/membros}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param igrejaId Referência a organizacao.igreja — obrigatório ao criar
 * @param familiaId Referência a secretaria.familia
 * @param nome coluna {@code mem_nome} — obrigatório ao criar
 * @param apelido coluna {@code mem_apelido} — obrigatório ao criar
 * @param dataNascimento coluna {@code mem_data_nascimento}
 * @param sexo coluna {@code mem_sexo}
 * @param estadoCivil coluna {@code mem_estado_civil}
 * @param morada coluna {@code mem_morada}
 * @param dataEntrada Data do voto de admissão nesta igreja
 * @param modoEntrada coluna {@code mem_modo_entrada}
 * @param encarregadoMembroId Encarregado de educação (menores)
 * @param validacao coluna {@code mem_validacao}
 * @param validadoPorUsuarioId Referência a nucleo.usuario (preenchido pela base de dados)
 * @param dataValidacao (preenchido pela base de dados)
 * @param naturalidade Onde nasceu (cidade/distrito, país)
 * @param nacionalidade coluna {@code mem_nacionalidade}
 * @param tipoIdentificacao coluna {@code mem_tipo_identificacao}
 * @param numeroIdentificacao Número do BI, passaporte, DIRE ou cédula
 * @param profissao coluna {@code mem_profissao}
 * @param escolaridade coluna {@code mem_escolaridade}
 * @param nomePai coluna {@code mem_nome_pai}
 * @param nomeMae coluna {@code mem_nome_mae}
 * @param provincia coluna {@code mem_provincia}
 * @param cidadeDistrito Cidade ou distrito
 * @param bairro coluna {@code mem_bairro}
 * @param quarteirao coluna {@code mem_quarteirao}
 * @param numeroCasa Número da casa ou do talhão
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "secretaria", nome = "membro", prefixo = "mem", modulo = "secretaria", recurso = "membros", colunaIgreja = "mem_igr_id")
public record Membro(
        @ColunaBd(value = "mem_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "mem_igr_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer igrejaId,
        @ColunaBd(value = "mem_fam_id", tipo = Tipo.INT)
        Integer familiaId,
        @ColunaBd(value = "mem_nome", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String nome,
        @ColunaBd(value = "mem_apelido", tipo = Tipo.TEXTO, obrigatoria = true, naoNula = true)
        String apelido,
        @ColunaBd(value = "mem_data_nascimento", tipo = Tipo.DATA)
        LocalDate dataNascimento,
        @ColunaBd(value = "mem_sexo", tipo = Tipo.ENUM)
        Sexo sexo,
        @ColunaBd(value = "mem_estado_civil", tipo = Tipo.ENUM)
        EstadoCivil estadoCivil,
        @ColunaBd(value = "mem_morada", tipo = Tipo.TEXTO)
        String morada,
        @ColunaBd(value = "mem_data_entrada", tipo = Tipo.DATA)
        LocalDate dataEntrada,
        @ColunaBd(value = "mem_modo_entrada", tipo = Tipo.ENUM)
        TipoMovimento modoEntrada,
        @ColunaBd(value = "mem_encarregado_mem_id", tipo = Tipo.INT)
        Integer encarregadoMembroId,
        @ColunaBd(value = "mem_validacao", tipo = Tipo.ENUM, naoNula = true)
        EstadoValidacao validacao,
        @ColunaBd(value = "mem_validado_por_usu_id", tipo = Tipo.INT, escrita = false)
        Integer validadoPorUsuarioId,
        @ColunaBd(value = "mem_data_validacao", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime dataValidacao,
        @ColunaBd(value = "mem_naturalidade", tipo = Tipo.TEXTO)
        String naturalidade,
        @ColunaBd(value = "mem_nacionalidade", tipo = Tipo.TEXTO)
        String nacionalidade,
        @ColunaBd(value = "mem_tipo_identificacao", tipo = Tipo.ENUM)
        TipoIdentificacao tipoIdentificacao,
        @ColunaBd(value = "mem_numero_identificacao", tipo = Tipo.TEXTO)
        String numeroIdentificacao,
        @ColunaBd(value = "mem_profissao", tipo = Tipo.TEXTO)
        String profissao,
        @ColunaBd(value = "mem_escolaridade", tipo = Tipo.ENUM)
        Escolaridade escolaridade,
        @ColunaBd(value = "mem_nome_pai", tipo = Tipo.TEXTO)
        String nomePai,
        @ColunaBd(value = "mem_nome_mae", tipo = Tipo.TEXTO)
        String nomeMae,
        @ColunaBd(value = "mem_provincia", tipo = Tipo.TEXTO)
        String provincia,
        @ColunaBd(value = "mem_cidade_distrito", tipo = Tipo.TEXTO)
        String cidadeDistrito,
        @ColunaBd(value = "mem_bairro", tipo = Tipo.TEXTO)
        String bairro,
        @ColunaBd(value = "mem_quarteirao", tipo = Tipo.TEXTO)
        String quarteirao,
        @ColunaBd(value = "mem_numero_casa", tipo = Tipo.TEXTO)
        String numeroCasa,
        @ColunaBd(value = "mem_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoMembro estado,
        @ColunaBd(value = "mem_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "mem_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "mem_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "mem_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "mem_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
