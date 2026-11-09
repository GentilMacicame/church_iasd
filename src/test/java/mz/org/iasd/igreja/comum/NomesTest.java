package mz.org.iasd.igreja.comum;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.api.Test;

/** Os nomes têm de coincidir com os do openapi.yaml (gerador gen_openapi.py). */
class NomesTest {

    @ParameterizedTest
    @CsvSource({
            "mem_data_nascimento, dataNascimento",
            "mem_igr_id, igrejaId",
            "ect_professor_mem_id, professorMembroId",
            "tra_aprovado_por_usu_id, aprovadoPorUsuarioId",
            "igr_mae_igr_id, maeIgrejaId",
            "act_ide_id, departamentoIgrejaId",
            "ers_tra_id, transacaoId",
            "tra_cnu_id, contagemId",
            "igr_id, id",
            "igr_codigo_acms, codigoAcms",
            "usu_end_date, endDate"
    })
    void colunaParaCampo(String coluna, String campo) {
        assertEquals(campo, Nomes.campo(coluna));
    }

    @Test
    void colunaVazia() {
        assertNull(Nomes.campo(null));
        assertNull(Nomes.campo(" "));
    }
}
