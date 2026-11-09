package mz.org.iasd.igreja.models.actividades;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import mz.org.iasd.igreja.models.catalogo.ColunaBd;
import mz.org.iasd.igreja.models.catalogo.TabelaBd;
import mz.org.iasd.igreja.models.catalogo.Tipo;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;

/**
 * Um dia (culto) da escala: grupo coral, departamento ou evento especial.
 * <p>
 * Tabela {@code actividades.escala_dia} · rota {@code /v1/actividades/dias-escala}. Os nomes dos campos são os do
 * JSON (iguais a {@code api/openapi.yaml}); {@link ColunaBd} diz a coluna correspondente.
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO: alterar
 * defs.py (e criar a migração nova) e voltar a gerar.
 *
 * @param id Identificador
 * @param escalaPlanoId Referência a actividades.escala_plano — obrigatório ao criar
 * @param data coluna {@code eds_data} — obrigatório ao criar
 * @param evento Dia especial que substitui a escala (ex.: Simpósio, 13.º sábado)
 * @param grupoCoral coluna {@code eds_grupo_coral}
 * @param departamentoIgrejaId Departamento responsável
 * @param observacoes coluna {@code eds_observacoes}
 * @param estado Estado do registo
 * @param criadoEm Data de criação (preenchido pela base de dados)
 * @param modificadoEm Data da última alteração (preenchido pela base de dados)
 * @param endDate Data em que foi terminado (null = activo) (preenchido pela base de dados)
 * @param criadoPor Utilizador que criou (preenchido pela base de dados)
 * @param modificadoPor Utilizador que alterou por último (preenchido pela base de dados)
 */
@TabelaBd(schema = "actividades", nome = "escala_dia", prefixo = "eds", modulo = "actividades", recurso = "dias-escala")
public record EscalaDia(
        @ColunaBd(value = "eds_id", tipo = Tipo.INT, escrita = false, naoNula = true)
        Integer id,
        @ColunaBd(value = "eds_epl_id", tipo = Tipo.INT, obrigatoria = true, naoNula = true)
        Integer escalaPlanoId,
        @ColunaBd(value = "eds_data", tipo = Tipo.DATA, obrigatoria = true, naoNula = true)
        LocalDate data,
        @ColunaBd(value = "eds_evento", tipo = Tipo.TEXTO)
        String evento,
        @ColunaBd(value = "eds_grupo_coral", tipo = Tipo.TEXTO)
        String grupoCoral,
        @ColunaBd(value = "eds_ide_id", tipo = Tipo.INT)
        Integer departamentoIgrejaId,
        @ColunaBd(value = "eds_observacoes", tipo = Tipo.TEXTO)
        String observacoes,
        @ColunaBd(value = "eds_estado", tipo = Tipo.ENUM, naoNula = true)
        EstadoRegisto estado,
        @ColunaBd(value = "eds_criado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime criadoEm,
        @ColunaBd(value = "eds_modificado_em", tipo = Tipo.DATA_HORA, escrita = false, naoNula = true)
        OffsetDateTime modificadoEm,
        @ColunaBd(value = "eds_end_date", tipo = Tipo.DATA_HORA, escrita = false)
        OffsetDateTime endDate,
        @ColunaBd(value = "eds_criado_por", tipo = Tipo.INT, escrita = false)
        Integer criadoPor,
        @ColunaBd(value = "eds_modificado_por", tipo = Tipo.INT, escrita = false)
        Integer modificadoPor) {
}
